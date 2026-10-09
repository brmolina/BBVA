export const generalInfoFields = [
    {
        id: "DMT_TXT_ProductNameOLI__c",
        label: "Name",
        apiName: "DMT_TXT_ProductNameOLI__c",
        value: "",
        size: "1-of-2",
        type: "text",
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        maxLength: 50
    },
    {
        id: "DMT_Line_Oneoffdeal__c",
        label: "Line / One Off Deal",
        apiName: "DMT_Line_Oneoffdeal__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: true,
        isHidden: false,
        isRequired: false,
        options: []
    },
    {
        id: "gf_initial_date__c",
        label: "Product Start Date",
        apiName: "gf_initial_date__c",
        value: "",
        size: "1-of-2",
        type: "date",
        isReadOnly: false,
        isHidden: false,
        isRequired: true
    },
    {
        id: "gf_maturity_date__c",
        label: "Product Maturity Date",
        apiName: "gf_maturity_date__c",
        value: "",
        size: "1-of-2",
        type: "date",
        isReadOnly: false,
        isHidden: false,
        isRequired: true
    },
    {
        id: "DMT_Risk_Type__c",
        label: "Risk Type",
        apiName: "DMT_Risk_Type__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        options: []
    },
    {
        id: "loan_purpose_desc__c",
        label: "Use of Proceeds",
        apiName: "loan_purpose_desc__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: [
            { label: "General corporate purposes", value: "GCP" },
            { label: "Financing acquisition", value: "Acquisition Finance" },
            { label: "Working capital purposes", value: "Working Capital" },
            { label: "Capital expenditure purposes", value: "Capex" },
            { label: "Backup Facility", value: "Backup" },
            { label: "Refinancing existing indebtedness", value: "Refinancing existing indebtedness" },
            { label: "Financing the Project", value: "Financing the Project" },
            { label: "Issuing Letters of Credit / Guarantees", value: "Issuing Letters of Credit / Guarantees" },
            { label: "Payment of fees and expenses", value: "Payment of fees and expenses" },
            { label: "Trade finance purposes", value: "Trade finance purposes" },
            { label: "Dividend recap", value: "Dividend recap" },
            { label: "LBO (Leveraged BuyOut)", value: "LBO" },
            { label: "Aval ICO (Aval del Instituto de Crédito Oficial)", value: "Aval ICO" },
            { label: "Bridge", value: "Bridge" }
        ]
    },
    {
        id: "DMT_TXT_Comentarios__c",
        label: "Comments",
        apiName: "DMT_TXT_Comentarios__c",
        value: "",
        size: "1-of-2",
        type: "textarea",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        maxLength: "500",
        showCharacterCounter: true
    }
    
];