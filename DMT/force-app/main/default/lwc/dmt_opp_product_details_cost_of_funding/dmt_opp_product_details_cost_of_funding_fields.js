export const costOfFundingFields = [
    {
        id: "Funding_Curve__c",
        label: "Cost of Funding (CoF) Manual",
        apiName: "Funding_Curve__c",
        value: false,
        size: "1-of-2",
        type: "checkbox",
        isReadOnly: true,
        isHidden: false,
        isRequired: false
    },
    {
        id: "Life_Funding_Type__c",
        label: "Time of Cost of Funding",
        apiName: "Life_Funding_Type__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        options: [
            { label: "Term", value: "Term" },
            { label: "AvgLife", value: "AvgLife" }
        ]
    },
    {
        id: "gf_funding_cost_db__c",
        label: "Cost of Funding (CoF) Drawn (BPS)",
        apiName: "gf_funding_cost_db__c",
        value: 0,
        size: "1-of-2",
        type: "number",
        isReadOnly: false,
        isHidden: true,
        isRequired: true,
        min: 0,
        max: 99999999999999.99
    },
    {
        id: "gf_funding_cost_fb__c",
        label: "Cost of Funding (CoF) Undrawn (BPS)",
        apiName: "gf_funding_cost_fb__c",
        value: 0,
        size: "1-of-2",
        type: "number",
        isReadOnly: false,
        isHidden: true,
        isRequired: true,
        min: 0,
        max: 99999999999999.99
    }
];