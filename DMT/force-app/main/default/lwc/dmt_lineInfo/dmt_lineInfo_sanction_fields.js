// CIBGLOBALD-3779: field config for dmt_lineInfo when the line's RecordType.Name is 'Approval'
// (the Sanction record type's Name label — see SANCTION_RECORD_TYPES in dmt_lineInfo.js). No
// Amount/Currency/Type of risk/Office/Individual Disposal Approval/Committed-Uncommitted — those
// are OtherProducts/Treasury-only, see dmt_lineInfo_otherProducts_fields.js.
//
// Business Approval Start/End Date are formula fields (Opportunity date + DMT_Business_Approval_
// Term__c), always read-only — they recalculate server-side once Term is saved, same pattern as
// Risk Approval Term/dates but without client-side recalculation since these aren't editable.
export const sanctionFields = [
    {
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
        isReadOnly: true,
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
        isReadOnly: true,
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
        id: 'DMT_Bussiness_Approved_Date__c',
        label: 'Business Approval Start Date',
        apiName: 'DMT_Bussiness_Approved_Date__c',
        value: '',
        size: '1-of-2',
        type: 'date',
        isReadOnly: true,
        isHidden: false,
        isRequired: false
    },
    {
        // CIBGLOBALD-3779: now a plain Date field (was a formula) — editable, recalculated
        // client-side from DMT_Bussiness_Approved_Date__c + DMT_Business_Approval_Term_n__c, same
        // pattern as End_Date__c/DMT_Risk_Approval_Term__c. See dmt_lineInfo.js.
        id: 'DMT_Business_Approved_End_Date__c',
        label: 'Business Approval End Date',
        apiName: 'DMT_Business_Approved_End_Date__c',
        value: '',
        size: '1-of-2',
        type: 'date',
        isReadOnly: true,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'DMT_Business_Approval_Term_n__c',
        label: 'Business Approval Term',
        apiName: 'DMT_Business_Approval_Term_n__c',
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
    },
    {
        id: 'DMT_Comments__c',
        label: 'Approval comments',
        apiName: 'DMT_Comments__c',
        value: '',
        size: '1-of-1',
        maxLength: 500,
        type: 'textarea',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    }
];