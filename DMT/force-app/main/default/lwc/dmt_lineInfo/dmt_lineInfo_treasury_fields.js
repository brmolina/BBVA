// Changes been made for CIBGLOBALD-4741
export const treasuryFields = [
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
        label: 'Start Date',
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
        label: 'End Date',
        apiName: 'End_Date__c',
        value: '',
        size: '1-of-2',
        type: 'date',
        minDate: '',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    },
    {
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
    }
];