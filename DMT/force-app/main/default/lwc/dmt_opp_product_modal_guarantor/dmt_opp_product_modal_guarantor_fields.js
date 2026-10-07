export const guarantorFields = [

    {
        id: "Mitigant_Type__c",
        label: "Mitigant Type",
        apiName: "Mitigant_Type__c",
        value: "",
        size: "1-of-1",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        options: [
            { label: 'Others > Guarantee in favour of Public Administration', value: 'Others > Guarantee in favour of Public Administration' },
            { label: 'Others > Shared maintenance clause', value: 'Others > Shared maintenance clause' },
            { label: 'Personal > Parent guarantee', value: 'Personal > Parent guarantee' },
            { label: 'Personal > Corporate', value: 'Personal > Corporate' },
            { label: 'Personal > Bank', value: 'Personal > Bank' }
        ]
    }, {
        id: "DMT_Guarantor_Account__c",
        apiName: "DMT_Guarantor_Account__c",
        type: 'customLookup',
        label: "Select Guarantor",
        value: '',
        size: "1-of-2",
        isReadOnly: false,
        isHidden: false,
        objectApiName: 'Account',
        searchFields: ['Name', 'g_customer_id__c', 'DES_Tax_Identification_Number__c'],
        primaryField: 'Name',
        secondaryFields: ['g_customer_id__c', 'DES_Tax_Identification_Number__c'],
        filters: {
            AND: [
                { field: 'g_customer_id__c', operator: 'LIKE', value: '' },
            ]
        },
        isRequired: true,
        iconName: 'standard:account'
    }, {
        id: "Counterpart__c",
        label: "Guarantor Type",
        apiName: "Counterpart__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        options: []
    },
    {
        id: "Commercial_Percentage__c",
        label: "Commercial Risk (%)",
        apiName: "Commercial_Percentage__c",
        value: 0,
        size: "1-of-2",
        type: "number",
        min: 0,
        max: 999,
        isReadOnly: false,
        isHidden: false,
        isRequired: true
    },
    {
        id: "Political_Percentage__c",
        label: "Political Risk (%)",
        apiName: "Political_Percentage__c",
        value: 0,
        size: "1-of-2",
        type: "number",
        min: 0,
        max: 999,
        isReadOnly: false,
        isHidden: false,
        isRequired: true
    },
    {
        id: "Internal_Rating__c",
        label: "Internal Rating",
        apiName: "Internal_Rating__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        min: 0,
        max: 999,
        isReadOnly: false,
        isHidden: false,
        isRequired: true
    },
    {
        id: "DMT_Scoring__c",
        label: "Scoring",
        apiName: "DMT_Scoring__c",
        value: "",
        size: "1-of-2",
        type: "number",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        step: 0.01,
        min: 0,
        max: 99999999999999.99
    }, {
        id: "External_Rating__c",
        label: "External Rating",
        apiName: "External_Rating__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: []
    }, {
        id: "DMT_Currency__c",
        label: "Curency",
        apiName: "DMT_Currency__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        options: []
    }, {
        id: "End_Date__c",
        label: "End Date",
        apiName: "End_Date__c",
        value: "",
        size: "1-of-2",
        type: "date",
        isReadOnly: false,
        isHidden: false,
        isRequired: true
    }, {
        id: "DMT_Country_Guarantor__c",
        label: "Country Guarantor",
        apiName: "DMT_Country_Guarantor__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: true,
        isRequired: false,
        options: []
    }, {
        id: "SCRA__c",
        label: "SCRA",
        apiName: "SCRA__c",
        value: "",
        size: "1-of-2",
        type: "picklist",
        isReadOnly: false,
        isHidden: true,
        isRequired: false,
        options: [
            { label: 'A+', value: 'A+' },
            { label: 'A', value: 'A' },
            { label: 'B', value: 'B' },
            { label: 'C', value: 'C' },
            { label: 'C', value: 'C' }
        ]
    }, {
        id: "European_Bank_Check__c",
        label: "European Bank",
        apiName: "European_Bank_Check__c",
        value: false,
        size: "1-of-2",
        type: "checkbox",
        isReadOnly: false,
        isHidden: true,
        isRequired: false
    }, {
        id: "AVC_Check__c",
        label: "Asset Value Correlation",
        apiName: "AVC_Check__c",
        value: false,
        size: "1-of-2",
        type: "checkbox",
        isReadOnly: false,
        isHidden: true,
        isRequired: false
    }
    /* Hidden fields for now as per new requirements, can be added back if needed in the future
    {
        id: "Garantor_European_ECA__c",
        label: "Guarantor European ECA",
        apiName: "Garantor_European_ECA__c",
        value: false,
        size: "1-of-2",
        type: "checkbox",
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    }, */

];