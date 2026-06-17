export const amortizationsFields = [
    {
        id: "gf_amortization_type__c",
        label: "Amortization Type",
        apiName: "gf_amortization_type__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        options: [
            { label: "Bullet", value: "Bullet" },
            { label: "Amortizing", value: "Linear" },
            { label: "User-Defined", value: "User-Defined" }
        ]
    },
    {
        id: "gf_payment_frequency__c",
        label: "Interest Payment Frequency",
        apiName: "gf_payment_frequency__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: [
            { label: "Monthly", value: "Monthly" },
            { label: "Quarterly", value: "Quarterly" },
            { label: "Semiannual", value: "Semiannual" },
            { label: "Annual", value: "Annual" }
        ]
    },
    {
        id: 'DMT_bullet_amortization_indicator__c',
        label: 'Bullet',
        apiName: 'DMT_bullet_amortization_indicator__c',
        value: false,
        size: '1-of-4',
        type: 'checkbox',
        isReadOnly: false,
        isHidden: true,
        isRequired: false
    },
    {
        id: 'DMT_balloon_amortization_indicator__c',
        label: 'Balloon',
        apiName: 'DMT_balloon_amortization_indicator__c',
        value: false,
        size: '1-of-4',
        type: 'checkbox',
        isReadOnly: false,
        isHidden: true,
        isRequired: false
    },
    {
        id: "DMT_RateType__c",
        label: "Margin Rate Type",
        apiName: "DMT_RateType__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: [
            { label: "Fixed", value: "Fixed" },
            { label: "Variable", value: "Variable" }
        ]
    },
    {
        id: "g_currency_id__c",
        label: "Product Currency",
        apiName: "g_currency_id__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        options: []
    },
    {
        id: "DMT_Deal_Amount_Tenors__c",
        label: "Final Take",
        apiName: "DMT_Deal_Amount_Tenors__c",
        value: "",
        size: "1-of-1",
        type: "number",
        isReadOnly: true,
        isHidden: false,
        isRequired: false,
        min: 0,
        max: 99999999999999.99
    },
    {
        id: 'gf_accrual_fees_bp__c',
        label: 'Accrual Fee (BPS)',
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
    },
    {
        id: 'DMT_Extension_Duration_Fees__c',
        label: 'Extension/Duration Fees (BPS)',
        apiName: 'DMT_Extension_Duration_Fees__c',
        value: 0,
        size: '1-of-2',
        type: 'number',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        step: 0.01,
        min: 0,
        max: 99999999999999.99
    },
    {
        id: 'DMT_NewMoney_BBVA__c',
        label: 'New Money for BBVA',
        apiName: 'DMT_NewMoney_BBVA__c',
        value: 0,
        size: '1-of-2',
        type: 'number',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        min: 0,
        max: 99999999999999.99
    },
    {
        id: 'DMT_OldMoney_BBVA__c',
        label: 'Old Money for BBVA',
        apiName: 'DMT_OldMoney_BBVA__c',
        value: 0,
        size: '1-of-2',
        type: 'number',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        min: 0,
        max: 99999999999999.99
    },
    {
        id: 'syndicated_loan_drawn_amount__c',
        label: 'Expected Final Take',
        apiName: 'syndicated_loan_drawn_amount__c',
        value: 0,
        size: '1-of-2',
        type: 'numberWithCurrency',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        currencyCode: '',
        step: 0.01,
        min: 0,
        max: 99999999999999.99
    },
    {
        id: "DMT_Expected_Drawn__c",
        label: "Lifetime Expected Drawn (%)",
        apiName: "DMT_Expected_Drawn__c",
        value: 0,
        size: "1-of-2",
        type: "number",
        min: 0,
        max: 999,
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    }
];

export const extrafieldsAmortizations = [
    {
        id: "DMT_PricingGrid_OR_StepUps__c",
        label: "Pricing Grid or Step-ups (if applicable)",
        apiName: "DMT_PricingGrid_OR_StepUps__c",
        value: "",
        size: "1-of-1",
        type: "textarea",
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    }
];