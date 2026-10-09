/**
 * @description LWC service module for exception logging and error normalization.
 *              Wraps DES_ExceptionLogController to provide a single, consistent
 *              entry point for error handling across HVSC LWC components.
 *
 * ─── Exported functions ───────────────────────────────────────────────────────
 *
 *   logError(input)       Fire-and-forget logging. Accepts a single entry object
 *                         OR an array of entries. Never throws back to the caller.
 *
 *   normalizeError(error) Extracts a readable message string from any error shape
 *                         (Apex, LDS, wire, native JS). Use for both logging and
 *                         user-facing toasts.
 *
 * ─── Usage: single error (catch block) ───────────────────────────────────────
 *
 *   import { logError, normalizeError } from 'c/des_exception_utils';
 *
 *   handleSave() {
 *       updateRecord({ fields })
 *           .catch(error => {
 *               logError({ componentName: 'des_myComp', methodName: 'handleSave', error });
 *               this.showToast('Error', normalizeError(error), 'error');
 *           });
 *   }
 *
 * ─── Usage: wire ({error}) handler ───────────────────────────────────────────
 *
 *   @wire(getRecord, { recordId: '$recordId', fields })
 *   wiredRecord({ error, data }) {
 *       if (data)  { this.record = data; }
 *       if (error) { logError({ componentName: 'des_myComp', methodName: 'wiredRecord', error }); }
 *   }
 *
 * ─── Usage: batch (flush multiple errors at once) ────────────────────────────
 *
 *   logError([
 *       { componentName: 'des_myComp', methodName: 'handleSave',    error: saveError },
 *       { componentName: 'des_myComp', methodName: 'handleRefresh', error: refreshError }
 *   ]);
 *
 * @author Borja Lorenzo Adajas
 * @date   2026-06-17
 */

import apexLogExceptions from '@salesforce/apex/DES_ExceptionLogController.logExceptions';

// ─── Defaults ────────────────────────────────────────────────────────────────

const DEFAULT_PROJECT_CODE = 'DES';

// ─── Public API ──────────────────────────────────────────────────────────────

/**
 * Logs one or more errors to the server via DES_ExceptionLogController.
 * Accepts a single entry object OR an array of entries.
 * Fire-and-forget: never throws back to the caller.
 *
 * Each entry must include:
 * @param {string}  input.componentName  LWC folder name, e.g. 'des_myComponent'.
 * @param {string}  input.methodName     JS function or handler where the error was caught.
 * @param {*}       input.error          Raw error object from the catch block or wire handler.
 *                                       Do NOT pre-format it — pass the original error as-is.
 * @param {string}  [input.projectCode]  Project code. Defaults to 'HVSC'.
 * @param {string}  [input.objectName]   SObject API name when the error is record-related, or ''.
 * @param {string}  [input.recordId]     Salesforce record id when the error is record-related, or ''.
 */
const logError = (input) => {
    const entries = (Array.isArray(input) ? input : [input])
        .filter(entry => entry && typeof entry === 'object')
        .map(({ componentName, methodName, error, projectCode = DEFAULT_PROJECT_CODE, objectName = '', recordId = '' }) => ({
            componentName,
            methodName,
            projectCode,
            objectName,
            recordId,
            message   : _extractMessage(error),
            stackTrace: _extractStackTrace(error)
        }))
        .filter(e => !!e.message);

    if (entries.length === 0) return;

    apexLogExceptions({ errorsJson: JSON.stringify(entries) })
        .catch(() => {});
};

// ─── Public helpers ───────────────────────────────────────────────────────────

/**
 * Normalizes errors from Apex calls, wire adapters or native JS into a readable
 * message string. Suitable for both server-side logging and user-facing toasts.
 * For Validation Rule errors the extracted message IS the VR message text.
 *
 * Shape resolution order:
 *   1. body[] array              (Apex multiple errors)
 *   2. body.output.errors        (LDS write errors — record level)
 *   3. body.output.fieldErrors   (LDS write errors — field level, incl. VR on field)
 *   4. body.pageErrors           (LDS write errors — page / record-level VR)
 *   5. body.fieldErrors          (Aura field errors)
 *   6. body.message              (generic AuraHandledException)
 *   7. error.message             (native JS Error)
 *   8. error.statusText
 *   9. Fallback string
 *
 * When multiple messages are found (e.g. several VR errors at once) they are
 * joined with ', ' into a single string.
 *
 * @param {*} error  Raw error object from a catch block or wire handler.
 * @returns {string} Error message — never empty.
 */
const normalizeError = (error) => {
    if (!error) return 'An unknown error occurred';

    if (Array.isArray(error.body)) {
        return error.body.map(e => e.message).join(', ');
    }

    if (error.body && typeof error.body === 'object') {
        const messages = [];

        if (error.body.output && Array.isArray(error.body.output.errors) && error.body.output.errors.length > 0) {
            messages.push(...error.body.output.errors.map(e => e.message));
        }

        if (error.body.output && error.body.output.fieldErrors && typeof error.body.output.fieldErrors === 'object') {
            Object.values(error.body.output.fieldErrors).forEach(fieldErrorsList => {
                if (Array.isArray(fieldErrorsList)) {
                    messages.push(...fieldErrorsList.map(e => e.message));
                }
            });
        }

        if (Array.isArray(error.body.pageErrors) && error.body.pageErrors.length > 0) {
            messages.push(...error.body.pageErrors.map(e => e.message));
        }

        if (error.body.fieldErrors && typeof error.body.fieldErrors === 'object') {
            Object.values(error.body.fieldErrors).forEach(fieldErrorsList => {
                if (Array.isArray(fieldErrorsList)) {
                    messages.push(...fieldErrorsList.map(e => e.message));
                }
            });
        }

        if (messages.length > 0) {
            return messages.filter(msg => !!msg).join(', ');
        }

        if (typeof error.body.message === 'string') {
            return error.body.message;
        }
    }

    if (typeof error.message === 'string') return error.message;
    if (typeof error.statusText === 'string') return error.statusText;

    return 'An unknown error occurred';
};

// ─── Private helpers ─────────────────────────────────────────────────────────

/**
 * Thin adapter used internally by logError to extract a message from each entry's
 * error object before sending to Apex.
 *
 * Unlike normalizeError (which always returns a non-empty fallback), this returns
 * an empty string when error is null/undefined so that the upstream filter
 * (.filter(e => !!e.message)) can drop entries with no actionable error.
 *
 * @param {*} error  Raw error object.
 * @returns {string} Message string, or '' if error is null/undefined.
 */
const _extractMessage = (error) => {
    if (!error) return '';
    return normalizeError(error);
};

/**
 * Extracts the most useful technical stack trace from native JS and Apex error shapes.
 *
 * @param {*} error  Raw error object.
 * @returns {string} Stack trace string, or '' when none is available.
 */
const _extractStackTrace = (error) => {
    if (!error) return '';
    if (typeof error.stack === 'string') return error.stack;
    if (typeof error.body?.stackTrace === 'string') return error.body.stackTrace;
    return '';
};

export { logError, normalizeError };