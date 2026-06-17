export const clientFields = [
    {
        id: 'g_upd_lmscl_internal_ratg_type__c',
        label: 'Internal Rating',
        apiName: 'g_upd_lmscl_internal_ratg_type__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    },
    {
        // Only visible when isSubsidiary = true — hidden by default, shown via _applyVisibilityRules
        id: 'currentRatingToolDate',
        label: 'Current Rating Tool Date',
        apiName: 'ResponseHPG.CustomerHPG.currentRatingToolDate',
        value: '',
        size: '1-of-2',
        type: 'date',
        isReadOnly: true,
        isHidden: true,
        isRequired: false,
    },
    {
        id: 'DMT_Scoring__c',
        label: 'Scoring',
        apiName: 'DMT_Scoring__c',
        value: null,
        size: '1-of-2',
        type: 'number',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        step: 0.01,
        min: 0
    },
    {
        id: 'External_Rating__c',
        label: 'Unified External Rating',
        apiName: 'External_Rating__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    },
    {
        id: 'DMT_External_Rating_SP__c',
        label: 'S&P External Rating',
        apiName: 'DMT_External_Rating_SP__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    },
    {
        id: 'DMT_External_Rating_Moodys__c',
        label: "Moody's External Rating",
        apiName: 'DMT_External_Rating_Moodys__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    },
    {
        id: 'DMT_External_Rating_Fitch__c',
        label: 'Fitch External Rating',
        apiName: 'DMT_External_Rating_Fitch__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    },

    // ─── Client ───────────────────────────────────────────────────────────────
    {
        id: 'DMT_Threshold_Type__c',
        label: 'Client Threshold Type',
        apiName: 'DMT_Threshold_Type__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        helpText: "Here we will indicate whether the client is local or global in order to determine which Thresholds apply for assessing the profitability of the transaction. It will be 'Global' if the client's income comes from more than one geography.",
        options: [
            { label: 'Global', value: 'Global' },
            { label: 'Local',  value: 'Local'  }
        ]
    },
    {
        id: 'DMT_Industry__c',
        label: 'Industry',
        apiName: 'DMT_Industry__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: [
            { label: 'Industrials & Transportation', value: '1' },
            { label: 'Infra & Construction',         value: '2' },
            { label: 'Consumer & Retail',            value: '3' },
            { label: 'Energy',                       value: '4' },
            { label: 'TMT',                          value: '5' },
            { label: 'Other six',                    value: '6' }
        ]
    },
    {
        id: 'DMT_Leveraged_Lending__c',
        label: 'Leveraged Lending',
        apiName: 'DMT_Leveraged_Lending__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: [
            { label: 'Yes', value: 'Yes' },
            { label: 'No',  value: 'No'  },
            { label: 'N/A', value: 'N/A' }
        ]
    },
    {
        id: 'DMT_CAMN__c',
        label: 'CAMN',
        apiName: 'DMT_CAMN__c',
        value: '',
        size: '1-of-2',
        type: 'text',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        maxLength: 255
    },
    {
        id: 'Counterpart__c',
        label: 'Client Type',
        apiName: 'Counterpart__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    },
    {
        // Visible only when Counterpart__c is Fin Inst-B | Fin Inst-I | Fin Inst
        id: 'SCRA__c',
        label: 'Fixed SCRA (Simplified Credit Risk Approach)',
        apiName: 'SCRA__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: true,
        isRequired: false,
        options: []
    },
    {
        // Visible only when Counterpart__c is Fin Inst-B | Fin Inst-I | Fin Inst
        id: 'AVC_Check__c',
        label: 'Asset Value Correlation',
        apiName: 'AVC_Check__c',
        value: false,
        size: '1-of-4',
        type: 'checkbox',
        isReadOnly: false,
        isHidden: true,
        isRequired: false
    },
    {
        // Visible only when Counterpart__c is Fin Inst-B | Fin Inst-I | Fin Inst
        id: 'European_Bank_Check__c',
        label: 'European Bank',
        apiName: 'European_Bank_Check__c',
        value: false,
        size: '1-of-4',
        type: 'checkbox',
        isReadOnly: false,
        isHidden: true,
        isRequired: false
    },

    // ─── Sector ───────────────────────────────────────────────────────────────
    {
        id: 'DMT_Sector__c',
        label: 'Sector',
        apiName: 'DMT_Sector__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    },
    {
        // Visible only when DMT_Sector__c is not empty
        id: 'DMT_Subsector__c',
        label: 'Subsector',
        apiName: 'DMT_Subsector__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: true,
        isRequired: false,
        options: []
    },
    {
        // Visible only when DMT_Sector__c AND DMT_Subsector__c are both empty
        id: 'DMT_Activity__c',
        label: 'Activity',
        apiName: 'DMT_Activity__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: true,
        isRequired: false,
        options: []
    },
    {
        id: 'DMT_Sector_Head__c',
        label: 'Sector Head',
        apiName: 'DMT_Sector_Head__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    }
];