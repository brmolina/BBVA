export const scheduleFields = [
    {
        id: 'gf_amortization_type__c',
        label: 'Amortization Type',
        apiName: 'gf_amortization_type__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        options: [
            { label: 'Bullet', value: 'Bullet' },
            { label: 'Amortizing', value: 'Linear' },
            { label: 'User-Defined', value: 'User-Defined' }
        ]
    },
    {
        id: 'gf_payment_frequency__c',
        label: 'Interest Rate Period',
        apiName: 'gf_payment_frequency__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: [
            { label: 'Monthly', value: 'Monthly' },
            { label: 'Quarterly', value: 'Quarterly' },
            { label: 'Semiannual', value: 'Semiannual' },
            { label: 'Annual', value: 'Annual' }
        ]
    },
    {
        id: 'DMT_RateType__c',
        label: 'Margin Rate Type',
        apiName: 'DMT_RateType__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: [
            { label: 'Fixed', value: 'Fixed' },
            { label: 'Variable', value: 'Variable' }
        ]
    },
    {
        id: 'g_currency_id__c',
        label: 'Currency',
        apiName: 'g_currency_id__c',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        options: []
    },
    {
        id: 'gf_accrual_fees_bp__c',
        label: 'Accrual Fees',
        apiName: 'gf_accrual_fees_bp__c',
        value: 0,
        size: '1-of-2',
        type: 'number',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        step: 0.01,
        min: 0,
        max: 99999999999999.99
    }
];