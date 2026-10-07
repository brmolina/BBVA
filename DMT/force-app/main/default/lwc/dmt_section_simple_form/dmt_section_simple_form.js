import { LightningElement, api } from 'lwc';
// TODO: [DEAD_CODE] @track removed from fields - array is always fully reassigned so it's reactive without @track

export default class DmtSectionSimpleForm extends LightningElement {

    isEditMode = false;

    fields = [];

    _fieldsOriginal = [];
    _data;
    _groupData      = {};
    _options        = {};
    _snapshot       = null;
    _readOnlySnapshot = null;

    // --- Public API (properties) ------------------------------------------

    @api get fieldDefinitions() { return this._fieldsOriginal; }
    set fieldDefinitions(value) {
        this._fieldsOriginal = (value || []).map(f => ({ ...f }));
        this.fields = [...this._fieldsOriginal];
        this._recompute();
    }

    @api get data() { return this._data; }
    set data(value) {
        this._data = value;
        this._recompute();
    }

    @api get fieldOptions() { return this._options; }
    set fieldOptions(value) {
        if (!value) {
            this._options = {};
        } else if (value.catalogValues || value.picklistSfOptions) {
            const flatMap = { ...(value.picklistSfOptions || {}) };
            const catalogValues = value.catalogValues || {};
            for (const f of this._fieldsOriginal) {
                if (f.catalogCode && catalogValues[f.catalogCode]) {
                    flatMap[f.apiName] = catalogValues[f.catalogCode];
                }
            }
            this._options = flatMap;
        } else {
            this._options = value;
        }
        this._recompute();
    }

    @api get groupData() { return this._groupData; }
    set groupData(value) {
        this._groupData = value || {};
        this._recompute();
    }

    // --- Public API (methods) ---------------------------------------------

    @api enterEditMode() {
        this.isEditMode = true;
        this._snapshot  = new Map(this.fields.map(f => [f.id, f.value]));
    }

    @api restoreSnapshot() {
        if (!this._snapshot) return;
        this.fields = this.fields.map(f =>
            this._snapshot.has(f.id) ? { ...f, value: this._snapshot.get(f.id) } : f
        );
        this._snapshot = null;
        this._applyAllConditionalDeps();
    }

    @api commitEdit() {
        this.isEditMode = false;
        this._snapshot  = null;
    }

    @api setReadOnlyMode(readOnly) {
        if (readOnly) {
            if (!this._readOnlySnapshot) {
                this._readOnlySnapshot = this.fields.map(f => ({ id: f.id, isReadOnly: f.isReadOnly }));
            }
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        } else {
            if (!this._readOnlySnapshot) return;
            const roMap = new Map(this._readOnlySnapshot.map(f => [f.id, f.isReadOnly]));
            this.fields = this.fields.map(f => ({
                ...f,
                isReadOnly: roMap.has(f.id) ? roMap.get(f.id) : f.isReadOnly
            }));
            this._readOnlySnapshot = null;
        }
    }

    @api collectChanges() {
        if (!this._snapshot) return {};
        const changes = {};
        for (const f of this.fields) {
            if (this._isOriginallyReadOnly(f.apiName)) continue;
            const originalValue = this._snapshot.get(f.id);
            if (f.isHidden) {
                // If the field was hidden (value cleared), only save the null if it had a value before
                const originalWasEmpty = originalValue === null || originalValue === undefined || originalValue === '';
                if (!originalWasEmpty) changes[f.apiName] = null;
                continue;
            }
            const hasChanged = String(f.value ?? '') !== String(originalValue ?? '');
            if (!hasChanged) continue;
            changes[f.apiName] = (f.value === '' || f.value === undefined) ? null : f.value;
        }
        return changes;
    }

    @api getFieldLabel(apiName) {
        const f = this.fields.find(x => x.apiName === apiName);
        return f ? f.label : null;
    }

    @api collectChangesByObject() {
        const flat = this.collectChanges();
        const result = {};
        for (const [apiName, value] of Object.entries(flat)) {
            const fieldDef = this._fieldsOriginal.find(f => f.apiName === apiName);
            const obj = fieldDef?.objectType ?? 'DMT_Opportunity_Client__c';
            result[obj] ??= {};
            result[obj][apiName] = value;
        }
        return result;
    }

    @api getFieldObjectType(apiName) {
        const f = this._fieldsOriginal.find(f => f.apiName === apiName);
        return f ? (f.objectType ?? 'DMT_Opportunity_Client__c') : null;
    }

    @api validateRequired() {
        const renderer = this.template.querySelector('c-dmt_form_renderer');
        const result = renderer?.validate?.();
        if (!result) return { isValid: true, invalidFields: [] };
        if (typeof result === 'boolean') return { isValid: result, invalidFields: [] };
        return result;
    }

    // --- Event handlers ---------------------------------------------------

    handleEditModeChange(event) {
        this.dispatchEvent(new CustomEvent('editmodechange', { detail: event.detail }));
    }

    handleFieldChange(event) {
        const { fieldId, value } = event.detail;
        const idx = this.fields.findIndex(f => f.id === fieldId);
        if (idx === -1) return;
        const field   = this.fields[idx];
        const apiName = field.apiName;
        const newArr  = this.fields.slice();
        newArr[idx]   = { ...field, value };
        this.fields   = newArr;
        this._applyConditionalDeps(apiName);
        this.dispatchEvent(new CustomEvent('sectionchange', { detail: { apiName, value } }));
        this.dispatchEvent(new CustomEvent('fieldchange', { detail: event.detail }));
    }

    // --- Recompute --------------------------------------------------------

    _recompute() {
        if (!this._fieldsOriginal || this._fieldsOriginal.length === 0) return;
        let next = this._applyOptions(this._fieldsOriginal);
        if (this._data) {
            next = next.map(f => {
                const updated = { ...f, value: this._data[f.apiName] };
                if (f.overridable && this._groupData) {
                    updated.originalValue = this._groupData[f.apiName] ?? null;
                }
                return updated;
            });
        }
        this.fields = next;
        if (this._readOnlySnapshot) {
            this.fields = this.fields.map(f => ({ ...f, isReadOnly: true }));
        }
        this._applyAllConditionalDeps();
    }

    // --- Conditional field dependencies -----------------------------------

    _applyConditionalDeps(checkboxApiName) {
        const checkboxField = this.fields.find(f => f.apiName === checkboxApiName);
        if (!checkboxField) return;
        const isChecked = !!checkboxField.value;
        let hasChanges = false;
        const updatedFields = this.fields.map(f => {
            if (f.conditionalOn !== checkboxApiName) return f;
            const shouldBeHidden = !isChecked;
            if (f.isHidden === shouldBeHidden) return f;
            hasChanges = true;
            return shouldBeHidden ? { ...f, isHidden: true, value: null } : { ...f, isHidden: false };
        });
        if (hasChanges) this.fields = updatedFields;
    }

    _applyAllConditionalDeps() {
        const checkboxApiNames = new Set(
            this._fieldsOriginal
                .filter(f => f.conditionalOn)
                .map(f => f.conditionalOn)
        );
        for (const checkboxApiName of checkboxApiNames) {
            this._applyConditionalDeps(checkboxApiName);
        }
    }

    _applyOptions(originalArray) {
        const baseArr = originalArray.map(f => ({ ...f }));
        if (!this._options) return baseArr;
        return baseArr.map(f => {
            const options = this._options[f.apiName];
            if (!options) return f;
            const merged     = { ...f, options };
            const originalRO = this._isOriginallyReadOnly(f.apiName);
            if (f.type === 'picklist' && !originalRO) merged.isReadOnly = options.length === 0;
            return merged;
        });
    }

    _isOriginallyReadOnly(apiName) {
        return this._fieldsOriginal.find(o => o.apiName === apiName)?.isReadOnly === true;
    }
}