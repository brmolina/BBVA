import { LightningElement, api } from 'lwc';

const FIELD_TYPES = {
    TEXT: 'text',
    TEXTAREA: 'textarea',
    NUMBER: 'number',
    CURRENCY: 'currency',
    NUMBER_WITH_CURRENCY: 'numberWithCurrency',
    DATE: 'date',
    DATETIME: 'datetime',
    EMAIL: 'email',
    PHONE: 'phone',
    URL: 'url',
    CHECKBOX: 'checkbox',
    PICKLIST: 'picklist',
    RECORD_PICKER: 'recordPicker',
    CUSTOM_LOOKUP: 'customLookup',
    BLANK: 'blank'
};

export default class dmt_form_renderer extends LightningElement {
    @api isEditMode = false;

    _rawFields = [];
    _enrichedFields = [];
    _fieldIndexById = new Map();         // O(1) lookup by id
    _expandedTextareas = new Set();
    _overflowingTextareas = new Set();
    _displayFieldsCache = null;          // Cached display fields
    _displayFieldsDirty = true;          // Invalidation flag
    _hasTextareas = false;               // Skip overflow checks if no textareas
    _resizeObserver;
    _checkOverflowFrame = null;          // rAF handle for debounce

    /**
     * Public property used by the parent to feed the field configuration.
     */
    @api
    get fields() {
        return this._enrichedFields;
    }
    set fields(value) {
        const source = value || [];
        this._rawFields = new Array(source.length);
        this._enrichedFields = new Array(source.length);
        this._fieldIndexById.clear();
        this._hasTextareas = false;

        for (let i = 0; i < source.length; i++) {
            const raw = { ...source[i] };
            this._rawFields[i] = raw;
            this._enrichedFields[i] = this._enrichField(raw);
            if (raw.id) {
                this._fieldIndexById.set(raw.id, i);
            }
            if (raw.type === FIELD_TYPES.TEXTAREA) {
                this._hasTextareas = true;
            }
        }

        this._displayFieldsDirty = true;
    }

    /**
     * Getter consumed by the template. Cached and only rebuilt when needed.
     * Avoids re-mapping the whole array on every render cycle.
     */
    get displayFields() {
        if (!this._displayFieldsDirty && this._displayFieldsCache) {
            return this._displayFieldsCache;
        }

        // No textareas -> the enriched array can be returned as-is.
        if (!this._hasTextareas) {
            this._displayFieldsCache = this._enrichedFields;
            this._displayFieldsDirty = false;
            return this._displayFieldsCache;
        }

        // Only decorate textareas with view-more state.
        const result = new Array(this._enrichedFields.length);
        for (let i = 0; i < this._enrichedFields.length; i++) {
            const f = this._enrichedFields[i];
            if (!f.isTextarea) {
                result[i] = f;
                continue;
            }
            const isExpanded = this._expandedTextareas.has(f.id);
            const isTruncatable = this._overflowingTextareas.has(f.id) || isExpanded;
            result[i] = {
                ...f,
                isExpanded,
                isTruncatable,
                textareaTextClass: isExpanded ? 'textarea-text is-expanded' : 'textarea-text',
                textareaToggleClass: isExpanded ? 'textarea-toggle is-block' : 'textarea-toggle',
                toggleLabel: isExpanded ? 'View Less' : 'View More'
            };
        }

        this._displayFieldsCache = result;
        this._displayFieldsDirty = false;
        return this._displayFieldsCache;
    }

    renderedCallback() {
        if (this._hasTextareas) {
            this._scheduleOverflowCheck();
            this._ensureResizeObserver();
        }
    }

    disconnectedCallback() {
        if (this._resizeObserver) {
            this._resizeObserver.disconnect();
            this._resizeObserver = null;
        }
        if (this._checkOverflowFrame) {
            cancelAnimationFrame(this._checkOverflowFrame);
            this._checkOverflowFrame = null;
        }
    }

    /**
     * Debounced overflow check using requestAnimationFrame.
     * Prevents multiple synchronous executions during a single render cycle.
     */
    _scheduleOverflowCheck() {
        if (this._checkOverflowFrame) return;
        this._checkOverflowFrame = requestAnimationFrame(() => {
            this._checkOverflowFrame = null;
            this._checkOverflow();
        });
    }

    _ensureResizeObserver() {
        if (this._resizeObserver || typeof ResizeObserver === 'undefined') return;
        this._resizeObserver = new ResizeObserver(() => this._scheduleOverflowCheck());
        const wraps = this.template.querySelectorAll('[data-textarea-wrap]');
        for (let i = 0; i < wraps.length; i++) {
            this._resizeObserver.observe(wraps[i]);
        }
    }

    _checkOverflow() {
        if (this.isEditMode || !this._hasTextareas) return;
        const elements = this.template.querySelectorAll('[data-textarea-text]');
        if (elements.length === 0) return;

        let changed = false;
        const overflowing = this._overflowingTextareas;
        const expanded = this._expandedTextareas;

        for (let i = 0; i < elements.length; i++) {
            const el = elements[i];
            const fieldId = el.dataset.textareaText;
            if (expanded.has(fieldId)) continue;

            const overflows = el.scrollWidth > el.clientWidth + 1;
            const was = overflowing.has(fieldId);

            if (overflows && !was) {
                overflowing.add(fieldId);
                changed = true;
            } else if (!overflows && was) {
                overflowing.delete(fieldId);
                changed = true;
            }
        }

        if (changed) {
            this._overflowingTextareas = new Set(overflowing);
            this._displayFieldsDirty = true;
        }
    }

    handleToggleMore(event) {
        const fieldId = event.currentTarget.dataset.id;
        if (this._expandedTextareas.has(fieldId)) {
            this._expandedTextareas.delete(fieldId);
        } else {
            this._expandedTextareas.add(fieldId);
        }
        this._expandedTextareas = new Set(this._expandedTextareas);
        this._displayFieldsDirty = true;
    }

    // =========================================================================
    // RECORD PICKER - helpers
    // =========================================================================

    /**
     * Normalizes any incoming value format to a canonical object { id, ...rest }
     * or null when there is no selection.
     *
     * Accepts:
     *   - null / undefined / ''   → null
     *   - '001ABC...'             → { id: '001ABC' }   (only Id, no extra keys)
     *   - { id, Name, ... }       → { id, Name, ... }  (used as-is)
     *   - { Id, Name, ... }       → { id, Name, ... }  (Id key → id)
     *
     * Extra field keys beyond id are preserved as-is so that when the parent
     * enriches the value (e.g. after getRecord) those fields are available for
     * read-mode label computation.
     */
    _normalizeRecordPickerValue(value) {
        if (value === null || value === undefined || value === '') {
            return null;
        }
        if (typeof value === 'string') {
            return { id: value };
        }
        if (typeof value === 'object') {
            const id = value.id ?? value.Id ?? null;
            // Spread all keys, then enforce lowercase 'id'
            const { Id: _dropped, ...rest } = value;    // drop uppercase Id if present
            return { ...rest, id };
        }
        return null;
    }

    /**
     * Builds the displayInfo object that lightning-record-picker expects.
     *
     * IMPORTANT — displayInfo uses plain strings (not {fieldPath} objects):
     *   displayInfo = { primaryField: 'Name', additionalFields: ['Phone', 'Email'] }
     *
     * fields[0] → primaryField (string)
     * fields[1..n] → additionalFields (string[])
     */
    _buildDisplayInfo(fieldNames) {
        if (!fieldNames || fieldNames.length === 0) {
            return { primaryField: 'Name' };
        }
        const [primary, ...rest] = fieldNames;
        const displayInfo = { primaryField: primary };          // string, NOT {fieldPath}
        if (rest.length > 0) {
            displayInfo.additionalFields = rest;                // string[], NOT [{fieldPath}]
        }
        return displayInfo;
    }

    /**
     * Builds the matchingInfo object so the typeahead searches across
     * all configured fields, not just Name.
     */
    _buildMatchingInfo(fieldNames) {
        if (!fieldNames || fieldNames.length === 0) {
            return { primaryField: { fieldPath: 'Name' } };
        }
        const [primary, ...rest] = fieldNames;
        const matchingInfo = { primaryField: { fieldPath: primary } };
        if (rest.length > 0) {
            matchingInfo.additionalFields = rest.map(f => ({ fieldPath: f }));
        }
        return matchingInfo;
    }

    /**
     * Computes the read-mode label from the normalised value.
     * Uses the first field in fieldNames that has a non-empty value.
     * Falls back to the id if nothing else is available.
     */
    _computeRecordPickerLabel(normalizedValue, fieldNames) {
        if (!normalizedValue) return '';
        const names = fieldNames && fieldNames.length > 0 ? fieldNames : ['Name'];
        for (const f of names) {
            if (normalizedValue[f]) return String(normalizedValue[f]);
        }
        return normalizedValue.id ?? '';
    }

    // =========================================================================
    // ENRICHMENT
    // =========================================================================

    /**
     * Adds derived flags and CSS classes to a raw field.
     */
    _enrichField(field) {
        const type = field.type;
        const isRecordPicker = type === FIELD_TYPES.RECORD_PICKER;

        // ----- recordPicker-specific enrichment -----
        const fieldNames = isRecordPicker ? (field.fields || ['Name']) : [];
        const normalizedRecordValue = isRecordPicker
            ? this._normalizeRecordPickerValue(field.value)
            : null;

        const recordPickerLabel = isRecordPicker
            ? this._computeRecordPickerLabel(normalizedRecordValue, fieldNames)
            : '';

        // The attribute value that lightning-record-picker expects: a plain Id string or null
        const recordPickerValue = normalizedRecordValue?.id ?? null;

        // displayInfo and matchingInfo built from configured fields
        const recordPickerDisplayInfo = isRecordPicker
            ? this._buildDisplayInfo(fieldNames)
            : null;

        const recordPickerMatchingInfo = isRecordPicker
            ? this._buildMatchingInfo(fieldNames)
            : null;

        // ----- overridable / override detection -----
        const isCustomLookup = type === FIELD_TYPES.CUSTOM_LOOKUP;
        const isOverridable = field.overridable === true;
        const originalValue = field.originalValue;

        // originalValue puede ser un valor plano o un objeto { label, value }.
        // - originalRawValue: el valor real usado para comparar y revertir.
        // - originalDisplayValue: el texto mostrado en el tooltip.
        const isOriginalStructured = originalValue !== null
            && originalValue !== undefined
            && typeof originalValue === 'object'
            && !Array.isArray(originalValue)
            && 'value' in originalValue
            && 'label' in originalValue;
        const originalRawValue   = isOriginalStructured ? originalValue.value : originalValue;
        const originalDisplayValue = isOriginalStructured ? originalValue.label : originalValue;

        let isOverridden = false;
        let overrideTooltip = '';

        if (isOverridable && originalRawValue !== undefined && originalRawValue !== null) {
            if (isRecordPicker) {
                const currentId = normalizedRecordValue?.id ?? null;
                const originalNorm = this._normalizeRecordPickerValue(originalRawValue);
                const originalId = originalNorm?.id ?? null;
                isOverridden = currentId !== originalId;
                if (isOverridden) {
                    const origLabel = isOriginalStructured
                        ? originalDisplayValue
                        : (this._computeRecordPickerLabel(originalNorm, fieldNames)
                            || originalId
                            || String(originalRawValue));
                    overrideTooltip = `Original value: ${origLabel}`;
                }
            } else if (isCustomLookup) {
                isOverridden = field.value !== originalRawValue;
                if (isOverridden) {
                    overrideTooltip = `Original value: ${originalDisplayValue ?? field.customLookupLabel ?? originalRawValue}`;
                }
            } else {
                isOverridden = String(field.value) !== String(originalRawValue);
                overrideTooltip = isOverridden ? `Original value: ${originalDisplayValue}` : '';
            }
        }

        // ----- standard value / hasValue -----
        // For recordPicker the internal value is always the normalised object (or null)
        const value = isRecordPicker ? normalizedRecordValue : field.value;
        const hasValue = isRecordPicker
            ? normalizedRecordValue !== null
            : isCustomLookup
                ? (field.value !== null && field.value !== undefined && field.value !== '' && (typeof field.value === 'object' ? !!field.value.id : true))
                : (value !== null && value !== undefined && value !== '');

        // ----- customLookup read-mode label -----
        // value is a plain Id string. The label is resolved inside dmt_custom_lookup
        // via _resolveById. In read mode we show whatever label the parent has stored
        // in field.customLookupLabel (updated by the parent after fieldchange).
        // If not yet resolved, fall back to the id itself.
        let customLookupLabel = '';
        if (isCustomLookup && field.value) {
            customLookupLabel = field.customLookupLabel || field.value;
        }

        // ----- picklist normalisation (unchanged) -----
        const isPicklist = type === FIELD_TYPES.PICKLIST;
        const normalizedValue = isPicklist && value !== null && value !== undefined
            ? String(value)
            : value;

        let picklistLabel = normalizedValue;
        if (isPicklist && Array.isArray(field.options)) {
            const opts = field.options;
            for (let i = 0; i < opts.length; i++) {
                if (String(opts[i].value) === normalizedValue) {
                    picklistLabel = opts[i].label;
                    break;
                }
            }
        }

        return {
            ...field,
            // Override value with the appropriate normalised version
            value: isPicklist ? normalizedValue : value,

            classField: this._computeClassField(field.size),
            classInner: this._computeClassInner(field.isHighlighted),
            controlClass: this._computeControlClass(hasValue),
            classEditHighlight: field.isHighlighted ? 'slds-is-edited' : '',

            isText: type === FIELD_TYPES.TEXT,
            isTextarea: type === FIELD_TYPES.TEXTAREA,
            isNumber: type === FIELD_TYPES.NUMBER,
            isCurrency: type === FIELD_TYPES.CURRENCY,
            isNumberWithCurrency: type === FIELD_TYPES.NUMBER_WITH_CURRENCY,
            isDate: type === FIELD_TYPES.DATE,
            isDatetime: type === FIELD_TYPES.DATETIME,
            isEmail: type === FIELD_TYPES.EMAIL,
            isPhone: type === FIELD_TYPES.PHONE,
            isUrl: type === FIELD_TYPES.URL,
            isCheckbox: type === FIELD_TYPES.CHECKBOX,
            isPicklist: isPicklist,
            isRecordPicker: isRecordPicker,
            isCustomLookup: isCustomLookup,
            isBlank: type === FIELD_TYPES.BLANK,

            hasValue,
            isOverridable,
            isOverridden,
            overrideTooltip,
            picklistLabel,

            // recordPicker-specific
            recordPickerValue,
            recordPickerLabel,
            recordPickerDisplayInfo,
            recordPickerMatchingInfo,

            // customLookup-specific
            customLookupLabel,              // string → read mode display (primaryField of selected option)
        };
    }

    // =========================================================================
    // HANDLERS
    // =========================================================================

    /**
     * Handles selection from dmt_custom_lookup.
     * event.detail.recordId — selected Id string or null
     * value stored as plain id — customLookupLabel resolved from _selectedRecord inside the child
     */
    handleCustomLookupChange(event) {
        const fieldId  = event.currentTarget.dataset.id;
        const recordId = event.detail.recordId;
        const newValue = recordId || null;

        // Derive validity for selection-based component
        const fieldIndex = this._fieldIndexById.get(fieldId);
        if (fieldIndex !== undefined) {
            const field = this._rawFields[fieldIndex];
            this._rawFields[fieldIndex].isFieldValid = !field.isRequired || !!newValue;
        }

        this._commitChange(fieldId, newValue);
    }

    handleEdit() {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: { isEditMode: true } }));
    }

    /**
     * Real-time validation handler (oninput).
     * Calls reportValidity() to show native browser errors while the user types.
     * Updates isFieldValid on the raw field so it is available on the next onchange.
     */
    handleFieldInput(event) {
        const el = event.target;
        const fieldId = el.dataset.id;
        if (!fieldId) return;

        const fieldIndex = this._fieldIndexById.get(fieldId);
        if (fieldIndex === undefined) return;

        const isValid = typeof el.reportValidity === 'function'
            ? el.reportValidity()
            : true;
        this._rawFields[fieldIndex].isFieldValid = isValid;
    }

    handleFieldChange(event) {
        const fieldId = event.target.dataset.id;
        const fieldType = event.target.dataset.type;
        if (fieldType === FIELD_TYPES.BLANK) return;

        const newValue = fieldType === FIELD_TYPES.CHECKBOX
            ? event.target.checked
            : event.target.value;

        // Salesforce grays out dates outside min/max but still allows selection.
        // Reject the value and restore the last valid one.
        if (fieldType === FIELD_TYPES.DATE && newValue) {
            const fieldIndex = this._fieldIndexById.get(fieldId);
            if (fieldIndex !== undefined) {
                const field = this._rawFields[fieldIndex];
                if ((field.minDate && newValue < field.minDate) ||
                    (field.maxDate && newValue > field.maxDate)) {
                    event.target.value = field.value ?? '';
                    return;
                }
            }
        }

        // Update validity state before committing
        const fieldIndex = this._fieldIndexById.get(fieldId);
        if (fieldIndex !== undefined && typeof event.target.reportValidity === 'function') {
            this._rawFields[fieldIndex].isFieldValid = event.target.reportValidity();
        }

        this._commitChange(fieldId, newValue);
    }

    /**
     * Handles selection changes on lightning-record-picker.
     *
     * The change event ONLY provides event.detail.recordId (string | null).
     * There is no event.detail.record — the component uses GraphQL internally
     * but does not expose the record fields through the event.
     *
     * Strategy: store { id } only. The parent receives fieldchange with
     * value: { id } and is responsible for calling getRecord if it needs
     * additional field values, then feeding the enriched object back via
     * the fields setter (which re-enriches and updates the label in read mode).
     */
    handleRecordPickerChange(event) {
        const fieldId = event.currentTarget.dataset.id;
        const recordId = event.detail.recordId;

        // null / undefined → user cleared the selection
        const newValue = recordId ? { id: recordId } : null;

        // Derive validity for selection-based component
        const fieldIndex = this._fieldIndexById.get(fieldId);
        if (fieldIndex !== undefined) {
            const field = this._rawFields[fieldIndex];
            this._rawFields[fieldIndex].isFieldValid = !field.isRequired || !!newValue;
        }

        this._commitChange(fieldId, newValue);
    }

    /**
     * Updates only the changed field. O(1) lookup + O(1) update.
     */
    _commitChange(fieldId, newValue, extra = {}) {
        const fieldIndex = this._fieldIndexById.get(fieldId);
        if (fieldIndex === undefined) return;

        const field = this._rawFields[fieldIndex];
        if (field.type === FIELD_TYPES.BLANK) return;

        const updatedRaw = { ...field, value: newValue };
        this._rawFields[fieldIndex] = updatedRaw;

        // New array reference so LWC detects the change, but only rebuild the single entry
        const newEnriched = this._enrichedFields.slice();
        newEnriched[fieldIndex] = this._enrichField(updatedRaw);
        this._enrichedFields = newEnriched;
        this._displayFieldsDirty = true;

        const wasHighlighted = field.isHighlighted;
        const isFieldValid = updatedRaw.isFieldValid !== undefined ? updatedRaw.isFieldValid : true;
        this.dispatchEvent(new CustomEvent('fieldchange', {
            detail: {
                fieldId,
                apiName: field.apiName || null,
                value: newValue,
                type: field.type,
                isFieldValid,
                ...(wasHighlighted && { isHighlighted: false }),
                ...extra
            }
        }));
    }

    /**
     * Returns a snapshot of all fields with their current values (excluding blanks).
     */
    @api
    getChanges() {
        const result = [];
        const raw = this._rawFields;
        for (let i = 0; i < raw.length; i++) {
            const f = raw[i];
            if (f.type === FIELD_TYPES.BLANK) continue;
            result.push({ ...f, isFieldValid: f.isFieldValid !== undefined ? f.isFieldValid : true });
        }
        return result;
    }

    handleRevert(event) {
        const fieldId = event.currentTarget.dataset.id;
        const fieldIndex = this._fieldIndexById.get(fieldId);
        if (fieldIndex === undefined) return;

        const field = this._rawFields[fieldIndex];
        if (field.type === FIELD_TYPES.BLANK) return;

        // Si originalValue tiene estructura { label, value }, revertimos con .value
        const originalValue = field.originalValue;
        const revertValue = (originalValue !== null
            && originalValue !== undefined
            && typeof originalValue === 'object'
            && !Array.isArray(originalValue)
            && 'value' in originalValue
            && 'label' in originalValue)
            ? originalValue.value
            : originalValue;

        this._commitChange(fieldId, revertValue, { isRevert: true });
    }

    // =========================================================================
    // CSS HELPERS
    // =========================================================================

    _computeClassField(size) {
        return `slds-col slds-size_${size} slds-p-horizontal_medium slds-p-top_xxx-small`;
    }

    _computeClassInner(isHighlighted) {
        const base = 'slds-form-element slds-hint-parent slds-form-element_edit slds-form-element_readonly is-stacked is-stacked-not-editing';
        return isHighlighted ? base + ' slds-is-edited' : base;
    }

    _computeControlClass(hasValue) {
        return hasValue ? 'slds-form-element__control' : 'slds-form-element__control control-min-height';
    }
}