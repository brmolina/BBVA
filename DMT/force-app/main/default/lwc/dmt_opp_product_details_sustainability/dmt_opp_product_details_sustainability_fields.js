export const sustainabilityFields = [
    {
        id: "DMT_sustainable_deal_assessment__c",
        label: "Sustainable Deal Assessment",
        apiName: "DMT_sustainable_deal_assessment__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    },
    {
        id: "DMT_Sustainable_Deal_Subtype__c",
        label: "Sustainable Deal Subtype",
        apiName: "DMT_Sustainable_Deal_Subtype__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    },
    {
        id: "DMT_Sustainability_deal_value_criteria__c",
        label: "Green Activity Filter",
        apiName: "DMT_Sustainability_deal_value_criteria__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: [
            { value: 'delegated', label: 'Delegated Label' },
            { value: 'other', label: 'Other Green Activity' }
        ]
    },
    {
        id: "DMT_sustainable_deal_value__c",
        label: "Sustainable Deal Value",
        apiName: "DMT_sustainable_deal_value__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    },
    {
        id: "DMT_PER_Sustainability_Percentage__c",
        label: "Sustainability Percentage (%)",
        apiName: "DMT_PER_Sustainability_Percentage__c",
        value: 0,
        size: "1-of-2",
        type: "number",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        min: 0,
        max: 100
    },
    {
        id: "DMT_Sustainability_bonus_eligible__c",
        label: "Sustainability Bonus–eligible",
        apiName: "DMT_Sustainability_bonus_eligible__c",
        value: false,
        size: "1-of-2",
        type: "checkbox",
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    }
];