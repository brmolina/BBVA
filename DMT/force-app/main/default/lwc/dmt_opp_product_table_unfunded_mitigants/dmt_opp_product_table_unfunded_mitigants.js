import { LightningElement, api, track } from 'lwc';
import deleteRecordApex   from '@salesforce/apex/DMT_WithoutSharingDAO.deleteRecordById';
import { ShowToastEvent }  from 'lightning/platformShowToastEvent';
import LightningConfirm    from 'lightning/confirm';
import GuarantorModal      from 'c/dmt_opp_product_modal_guarantor';
import TITLETABLE          from '@salesforce/label/c.dmt_cl_Guarantors_Text';

const VALID_MITIGANT_TYPES = [
    'Others > Guarantee in favour of Public Administration',
    'Others > ECA Guarantor (Exporte Credit agency)',
    'Others > Shared maintenance clause',
    'Personal > Parent guarantee',
    'Personal > Corporate',
    'Personal > Bank'
];

const COLUMN_WIDTHS = {
    Mitigant_Type__c  : 270,
    Guarantor         : 270,
    EndDate           : 95,
    Internal_Rating__c: 100,
    Scoring           : 64,
    button            : 50
};

const isRealId = (id) => typeof id === 'string' && id !== '0' && id.length >= 15;

export default class DmtOppProductTableUnfundedMitigants extends LightningElement {

    label = { TITLETABLE };

    @api oppProduct;
    @api endDateProduct;
    @api recordData;

    _canEdit      = true;
    _data         = [];
    _catalogValues= {};

    // ─── Public API ───────────────────────────────────────────────────────────

    @api get canEditTable() { return this._canEdit; }
    set canEditTable(value) {
        this._canEdit = value !== false;
        this.columns  = this._buildColumns();
        this._refreshDerivedState();
    }

    @api get data() { return this._data; }
    set data(value) {
        this._data = this._normalizeIncoming(value);
        this._loadFromData();
    }

    @api get catalogValues() { return this._catalogValues; }
    set catalogValues(value) {
        if (!value || typeof value !== 'object') return;
        const seen = new Set();
        const d971 = (value['D971'] || []).filter(o => {
            if (seen.has(o.label)) return false;
            seen.add(o.label);
            return true;
        });
        this._catalogValues = { ...value, D971: d971 };
    }


    @api setReadOnlyMode(readOnly) {
        this._canEdit = !readOnly;
        this.columns  = this._buildColumns();
        this._refreshDerivedState();
    }

    @api enterEditMode() {
        // Unfunded mitigants uses modal pattern, no inline editing
    }

    @api restoreSnapshot() {
        // On cancel, reload from prop to sync with server state
        this._loadFromData();
    }

    @api commitEdit() {
        // Data already persisted via modal; just refresh UI to read-only mode
        this._refreshDerivedState();
    }

    // ─── Internal state ───────────────────────────────────────────────────────

    @track rows       = [];
    @track displayRows= [];
    @track columns    = [];
    @track isLoading  = false;

    connectedCallback() {
        this.columns = this._buildColumns();
    }

    // ─── Load ─────────────────────────────────────────────────────────────────

    _normalizeIncoming(value) {
        try {
            let items;
            if (typeof value === 'string') {
                const parsed = JSON.parse(value);
                if (Array.isArray(parsed)) items = parsed;
                else if (parsed && typeof parsed === 'object') items = [parsed];
                else items = [];
            } else if (Array.isArray(value)) {
                items = value.filter(item => typeof item === 'object' && item !== null);
            } else if (value && typeof value === 'object') {
                items = [value];
            } else {
                items = [];
            }
            // Compute guarantor display from cross-object fields.
            // Formula fields cannot read encrypted Account fields (Shield PE), so we build
            // the display string here using the SOQL cross-object result instead.
            return items.map(item => {
                const accR = item['DMT_Guarantor_Account__r'];
                if (accR) {
                    const gId  = accR.g_customer_id__c || '';
                    const name = accR.Name || '';
                    return { ...item, DMT_Guarantor_Display__c: `${gId} - ${name}` };
                }
                return item;
            });
        } catch (e) {
            return [];
        }
    }

    _loadFromData() {
        this.isLoading = true;
        this.rows      = this._data.filter(item => VALID_MITIGANT_TYPES.includes(item.Mitigant_Type__c));
        // Rebuild columns so the current _canEdit is reflected
        // regardless of the order in which parent props arrive
        this.columns   = this._buildColumns();
        this._refreshDerivedState();
        this.isLoading = false;
    }

    // ─── User actions ─────────────────────────────────────────────────────────

    handleRowAction(event) {
        const { action, row } = event.detail;
        switch (action.name) {
            case 'addRecord'   : this._openGuarantorModal(null); break;
            case 'edit'        : this._handleEdit(row);          break;
            case 'deleteRecord': this._requestDelete(row);       break;
            default: break;
        }
    }

    handleAddRowGlobal() {
        this._openGuarantorModal(null);
    }

    _handleEdit(row) {
        if (!this._canEdit) return;
        const found = this.rows.find(r => r.Id === row.Id);
        if (!found) return;
        this._openGuarantorModal(found);
    }

    async _openGuarantorModal(record) {
        if (!this._canEdit) return;
        this.isLoading = true;
        try {
            const result = await GuarantorModal.open({
                size         : 'small',
                record,
                oppProduct   : this.oppProduct,
                endDateProduct: this.endDateProduct,
                catalogValues: this._catalogValues,
                entity       : this.recordData?.Opportunity?.DMT_Entity__c
            });

            if (!result) return;
            this.data = result;
            this._toast('Success', 'Guarantor saved successfully.', 'success');
        } catch (error) {
            console.error('Error message:', error.body?.message || error.message);
            console.error('Full error:', JSON.parse(JSON.stringify(error)));
            this._toast('Unexpected Error', error.body?.message || error.message || 'Unknown error', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async _requestDelete(row) {
        if (!this._canEdit) return;
        if (!isRealId(row.Id)) {
            this._removeFromTable(row.Id);
            return;
        }
        const confirmed = await LightningConfirm.open({
            message: 'Are you sure you want to delete this guarantor? This action cannot be undone.',
            variant: 'header',
            label  : 'Confirm deletion',
            theme  : 'warning'
        });
        if (!confirmed) return;
        this.isLoading = true;
        deleteRecordApex({ recordId: row.Id })
            .then(() => {
                this._toast('Record deleted', 'The guarantor was successfully deleted.', 'success');
                this._removeFromTable(row.Id);
            })
            .catch(error => {
                const msg = error?.body?.message || error.message || 'It was not possible to delete the record.';
                console.error('Error message:', error.body?.message || error.message);
                console.error('Full error: ', JSON.stringify(error));
                this._toast('Error', msg, 'error');
            })
            .finally(() => { this.isLoading = false; });
    }

    _removeFromTable(id) {
        this.rows = this.rows.filter(r => r.Id !== id);
        this._refreshDerivedState();
    }

    // ─── Derived state ────────────────────────────────────────────────────────

    _refreshDerivedState() {
        const canInteract = this._canEdit;
        const lastIndex   = this.rows.length - 1;
        this.displayRows  = this.rows.map((row, index) => ({
            ...row,
            buttonDisabled: !(canInteract && index === lastIndex),
            editDisabled  : !canInteract,
            deleteDisabled: !(canInteract && this._isRowPopulated(row))
        }));
    }

    _isRowPopulated(row) {
        return isRealId(row?.Id) || !!(row && (
            row.Mitigant_Type__c         ||
            row.Commercial_Percentage__c ||
            row.Political_Percentage__c
        ));
    }

    get hasRows()          { return this.displayRows.length > 0; }
    get isReadOnly()       { return !this._canEdit; }
    get globalAddDisabled(){ return !this._canEdit; }

    // ─── Columns ──────────────────────────────────────────────────────────────

    _buildColumns() {
        const canEdit      = this._canEdit;
        const forceDisabled = !canEdit;

        return [
            {
                fieldName: 'Mitigant_Type__c', label: 'Mitigant Type', type: 'text',
                editable: false, initialWidth: COLUMN_WIDTHS.Mitigant_Type__c,
                hideDefaultActions: true,
                cellAttributes: { title: { fieldName: 'Mitigant_Type__c' }, alignment: 'left' }
            },
            {
                fieldName: 'DMT_Guarantor_Display__c', label: 'Guarantor (IDClient - Name)', type: 'text',
                editable: false, initialWidth: COLUMN_WIDTHS.Guarantor,
                hideDefaultActions: true,
                cellAttributes: { title: { fieldName: 'DMT_Guarantor_Display__c' }, alignment: 'left' }
            },
            {
                fieldName: 'Commercial_Percentage__c', label: 'Commercial Risk (%)', type: 'percent-fixed',
                editable: false, hideDefaultActions: true,
                cellAttributes: { title: { fieldName: 'Commercial_Percentage__c' }, alignment: 'center' },
                typeAttributes: { step: '0.001' }
            },
            {
                fieldName: 'Political_Percentage__c', label: 'Political Risk (%)', type: 'percent-fixed',
                editable: false, hideDefaultActions: true,
                cellAttributes: { title: { fieldName: 'Political_Percentage__c' }, alignment: 'center' },
                typeAttributes: { step: '0.001' }
            },
            {
                fieldName: 'End_Date__c', label: 'End Date', type: 'date',
                editable: false, initialWidth: COLUMN_WIDTHS.EndDate,
                hideDefaultActions: true,
                cellAttributes: { title: { fieldName: 'End_Date__c' }, alignment: 'left' }
            },
            {
                fieldName: 'Internal_Rating__c', label: 'Internal Rating', type: 'text',
                editable: false, initialWidth: COLUMN_WIDTHS.Internal_Rating__c,
                hideDefaultActions: true,
                cellAttributes: { title: { fieldName: 'Internal_Rating__c' }, alignment: 'center' }
            },
            {
                fieldName: 'DMT_Scoring__c', label: 'Scoring', type: 'text',
                editable: false, initialWidth: COLUMN_WIDTHS.Scoring,
                hideDefaultActions: true,
                cellAttributes: { title: { fieldName: 'DMT_Scoring__c' }, alignment: 'center' }
            },
            {
                fieldName: 'External_Rating__c', label: 'External Rating', type: 'text',
                editable: false, hideDefaultActions: true,
                cellAttributes: { title: { fieldName: 'External_Rating__c' }, alignment: 'center' }
            },
            {
                fieldName: 'DMT_Currency__c', label: 'Currency', type: 'text',
                editable: false, hideDefaultActions: true,
                cellAttributes: { title: { fieldName: 'DMT_Currency__c' }, alignment: 'center' }
            },
            {
                type: 'button-icon', hideDefaultActions: true, initialWidth: COLUMN_WIDTHS.button,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    iconName: 'utility:delete', variant: 'bare', label: ' ',
                    name: 'deleteRecord', title: '', iconPosition: 'center',
                    disabled: forceDisabled ? true : { fieldName: 'deleteDisabled' }
                }
            },
            {
                type: 'button-icon', hideDefaultActions: true, initialWidth: COLUMN_WIDTHS.button,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    iconName: 'utility:edit', variant: 'bare', label: ' ',
                    name: 'edit', title: '', iconPosition: 'center',
                    disabled: forceDisabled ? true : { fieldName: 'editDisabled' }
                }
            },
            {
                type: 'button-icon', hideDefaultActions: true, initialWidth: COLUMN_WIDTHS.button,
                cellAttributes: { alignment: 'center' },
                typeAttributes: {
                    iconName: 'utility:add', variant: 'bare', label: ' ',
                    name: 'addRecord', title: ' ', iconPosition: 'center',
                    disabled: forceDisabled ? true : { fieldName: 'buttonDisabled' }
                }
            }
        ];
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}