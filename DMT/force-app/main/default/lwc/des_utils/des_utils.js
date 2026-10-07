// Utility function to normalize errors from Apex calls or lightning functions, extracting meaningful messages for display in toasts or logs
export function normalizeError(error) {
    if (!error) {
        return 'An unknown error occurred';
    }

    // 1. Array of errors (often returned by Salesforce Apex or custom arrays)
    if (Array.isArray(error.body)) {
        return error.body.map(e => e.message).join(', ');
    }

    // 2. Complex Salesforce UI API (LDS) write errors with detailed validation/DML issues
    if (error.body && typeof error.body === 'object') {
        const messages = [];

        // Check for output errors (e.g., page level errors from standard operations)
        if (error.body.output && Array.isArray(error.body.output.errors) && error.body.output.errors.length > 0) {
            messages.push(...error.body.output.errors.map(e => e.message));
        }

        // Check for output field errors
        if (error.body.output && error.body.output.fieldErrors && typeof error.body.output.fieldErrors === 'object') {
            Object.values(error.body.output.fieldErrors).forEach(fieldErrorsList => {
                if (Array.isArray(fieldErrorsList)) {
                    messages.push(...fieldErrorsList.map(e => e.message));
                }
            });
        }

        // Check for pageErrors outside output
        if (Array.isArray(error.body.pageErrors) && error.body.pageErrors.length > 0) {
            messages.push(...error.body.pageErrors.map(e => e.message));
        }

        // Check for fieldErrors outside output
        if (error.body.fieldErrors && typeof error.body.fieldErrors === 'object') {
            Object.values(error.body.fieldErrors).forEach(fieldErrorsList => {
                if (Array.isArray(fieldErrorsList)) {
                    messages.push(...fieldErrorsList.map(e => e.message));
                }
            });
        }

        // If we found any specific error messages, join them and return
        if (messages.length > 0) {
            return messages.filter(msg => !!msg).join(', ');
        }

        // Fallback to top-level body.message
        if (typeof error.body.message === 'string') {
            return error.body.message;
        }
    }

    // 3. Fallback to top-level message (generic JS errors)
    if (typeof error.message === 'string') {
        return error.message;
    }

    // 4. Fallback to status text
    if (typeof error.statusText === 'string') {
        return error.statusText;
    }

    return 'An unknown error occurred';
}