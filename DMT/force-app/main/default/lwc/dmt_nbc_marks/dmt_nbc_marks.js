import NBC_GLOBAL_MARK from '@salesforce/label/c.DMT_NBC_Global_Mark_Text';
import NBC_LOCAL_MARK from '@salesforce/label/c.DMT_NBC_Local_Mark_Text';

/**
 * Shared helper for the "NBC Local"/"NBC Global" field marks (CIBGLOBALD-3807).
 *
 * A field is marked by adding `nbcScope: 'Global'` (or 'Local', once business
 * confirms Local fields) directly to its entry in the relevant *_fields.js
 * descriptor file — right next to label/isRequired/etc. No other file needs
 * to know which fields are marked; the classification lives with the field.
 */

/**
 * Resolves the mark text for a given nbcScope, given the current GTB context.
 * Single source of truth for "what text, under what condition" — used both by
 * applyNbcMarks (field-descriptor arrays) and by any bespoke, non-field-descriptor
 * UI (e.g. the Business Plan Data table) that can't carry an nbcScope property.
 */
export function resolveNbcMarkText(scope, isGtb) {
    if (scope === 'Global') {
        return isGtb ? NBC_GLOBAL_MARK : '';
    }
    if (scope === 'Local') {
        return isGtb ? NBC_LOCAL_MARK : '';
    }
    return '';
}

/**
 * Returns a new fields array where every field carrying an `nbcScope` property
 * gets its nbcMark resolved via resolveNbcMarkText. Fields without nbcScope are
 * returned unchanged (same reference, no unnecessary re-render).
 */
export function applyNbcMarks(fields, isGtb) {
    return fields.map(f => {
        if (!f.nbcScope) return f;
        const nbcMark = resolveNbcMarkText(f.nbcScope, isGtb);
        return f.nbcMark === nbcMark ? f : { ...f, nbcMark };
    });
}