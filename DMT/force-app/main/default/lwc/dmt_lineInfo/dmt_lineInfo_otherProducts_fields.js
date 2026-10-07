// CIBGLOBALD-3779: field config for dmt_lineInfo for every record type except Sanction (see
// FIELDS_BY_RECORD_TYPE in dmt_lineInfo.js). Order matches the UAT screenshot.
//
// Amount__c and DMT_LastLevelId__c ("Type of risk") are required by CompulsoryAmountLastLevel, a
// validation rule on DMT_Line__c. Type of risk is a searchable picklist bound to
// DMT_LastLevelId__c; its options are populated at runtime from
// DMT_LineController.getTypeOfRiskOptions() (catalog 'B444').
//
// Entific is a read-only display value, not a real DMT_Line__c field: it expands
// Booking_Geography__c's country code into "code - country name" (e.g. "ES - Spain"), resolved at
// runtime by DMT_LineController.getEntificDisplayValue().
//
// The two "Minimum percentage..." fields reuse the pre-existing gf_min_raroec_wo_fcg_per__c/
// gf_min_rorc_wo_fcg_per__c fields and their original Setup labels, matching the Sanction field
// set's wording (see dmt_lineInfo_sanction_fields.js).
export const otherProductsFields = [
    {
        // Editable per AvoidEditNotDraft, the validation rule that lists ISCHANGED(Name) among
        // its exceptions.
        id: 'Name',
        label: 'Name',
        apiName: 'Name',
        value: '',
        size: '1-of-2',
        type: 'text',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'Entific',
        label: 'Entific',
        apiName: 'Entific',
        value: '',
        size: '1-of-2',
        type: 'text',
        isReadOnly: true,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'Start_Date__c',
        label: 'Risk Approval Start Date',
        apiName: 'Start_Date__c',
        value: '',
        size: '1-of-2',
        type: 'date',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'End_Date__c',
        label: 'Risk Approval End Date',
        apiName: 'End_Date__c',
        value: '',
        size: '1-of-2',
        type: 'date',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'DMT_Risk_Approval_Term__c',
        label: 'Risk Approval Term',
        apiName: 'DMT_Risk_Approval_Term__c',
        value: '',
        size: '1-of-2',
        min: 0,
        type: 'numberWithSuffix',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        extraText: 'Month(s)',
        showCounterButtons: true
    },
    {
        // Options populated at runtime — see file header note.
        id: 'CurrencyIsoCode',
        label: 'Currency',
        apiName: 'CurrencyIsoCode',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        placeholder: 'Select a currency',
        options: []
    },
    {
        // placeholder is kept in sync with CurrencyIsoCode at runtime — see dmt_lineInfo.js.
        id: 'Amount__c',
        label: 'Amount',
        apiName: 'Amount__c',
        value: '',
        size: '1-of-2',
        step: '0.01',
        type: 'number',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        placeholder: ''
    },
    {
        // Options populated at runtime — see file header note.
        id: 'DMT_LastLevelId__c',
        label: 'Type of risk',
        apiName: 'DMT_LastLevelId__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        placeholder: 'Select a type of risk',
        options: []
    },
    {
        id: 'DMT_Oficina__c',
        label: 'Office',
        apiName: 'DMT_Oficina__c',
        value: '',
        size: '1-of-2',
        maxLength: 255,
        type: 'textarea',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'DMT_Individual_Disposal_Approval__c',
        label: 'Individual Disposal Approval',
        apiName: 'DMT_Individual_Disposal_Approval__c',
        value: false,
        size: '1-of-2',
        type: 'checkbox',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    },
    {
        // Options populated at runtime — see file header note. searchable: false shows a plain
        // dropdown-arrow picklist instead of the typeahead/search-icon style, matching UAT for
        // this short, fixed 3-option list.
        id: 'g_line_commitment_level_type__c',
        label: 'Committed / Uncommitted',
        apiName: 'g_line_commitment_level_type__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        placeholder: 'Select an option',
        searchable: false,
        options: []
    },
    {
        id: 'gf_min_raroec_wo_fcg_per__c',
        label: 'Minimum percentage RAROEC without financing',
        apiName: 'gf_min_raroec_wo_fcg_per__c',
        value: '',
        size: '1-of-2',
        step: '0.000001',
        type: 'number',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'gf_min_rorc_wo_fcg_per__c',
        label: 'Minimum percentage RORC without financing',
        apiName: 'gf_min_rorc_wo_fcg_per__c',
        value: '',
        size: '1-of-2',
        step: '0.000001',
        type: 'number',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    }
];