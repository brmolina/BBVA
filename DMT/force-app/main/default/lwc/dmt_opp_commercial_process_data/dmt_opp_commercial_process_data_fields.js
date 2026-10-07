export const clientNeedFields = [
    {    
        id: 'DES_Countries__c',
        label: 'BBVA Countries Participants',
        apiName: 'DES_Countries__c',
        value: '', 
        size: '1-of-2',
        type: 'multipicklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: true,
        options: [
            { label: 'Abu Dhabi',       value: 'AB' },
            { label: 'Arab Emirates',   value: 'AE' },
            { label: 'Argentina',       value: 'AR' },
            { label: 'Belgium',         value: 'BE' },
            { label: 'Brazil',          value: 'BR' },
            { label: 'Chile',           value: 'CL' },
            { label: 'China',           value: 'CN' },
            { label: 'Colombia',        value: 'CO' },
            { label: 'France',          value: 'FR' },
            { label: 'Germany',         value: 'DE' },
            { label: 'Hong Kong',       value: 'HK' },
            { label: 'India',           value: 'IN' },
            { label: 'Indonesia',       value: 'ID' },
            { label: 'Italy',           value: 'IT' },
            { label: 'Japan',           value: 'JP' },
            { label: 'Mexico',          value: 'MX' },
            { label: 'Paraguay',        value: 'PY' },
            { label: 'Peru',            value: 'PE' },
            { label: 'Portugal',        value: 'PT' },
            { label: 'Puerto Rico',     value: 'PR' },
            { label: 'Russia',          value: 'RU' },
            { label: 'Singapore',       value: 'SG' },
            { label: 'South Korea',     value: 'KR' },
            { label: 'Spain',           value: 'ES' },
            { label: 'Taiwan',          value: 'TW' },
            { label: 'Turkey',          value: 'TR' },
            { label: 'United Kingdom',  value: 'GB' },
            { label: 'Uruguay',         value: 'UY' },
            { label: 'USA',             value: 'US' },
            { label: 'USA (BBVA USA)',  value: 'Compass' },
            { label: 'USA (NY Branch)', value: 'NY' },
            { label: 'Venezuela',       value: 'VE' }
        ]
    },
    {
        id: 'gf_comm_offer_moppy_ind_type__c',
        label: 'Anchor Opportunity',
        apiName: 'gf_comm_offer_moppy_ind_type__c',
        value: false,
        size: '1-of-2',
        type: 'checkbox',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'DES_Description_rich__c',
        label: "Client Need's Description",
        apiName: 'DES_Description_rich__c',
        value: '',
        size: '1-of-1',
        type: 'textarea',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        maxLength: 500,
        showCharacterCounter: true
    }
];

export const clientSolutionFields = [
    {
        id: 'DES_Expected_Probability__c',
        label: '% Expected Probability',
        apiName: 'DES_Expected_Probability__c',
        value: '',
        size: '1-of-2',
        type: 'number',
        isReadOnly: false,
        isHidden: false,
        isRequired: true
    },
    {
        id: 'DES_Cross_border__c',
        label: 'Cross-Border',
        apiName: 'DES_Cross_border__c',
        value: false,
        size: '1-of-2',
        type: 'checkbox',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'DMT_Credentials__c',
        label: 'Credentials',
        apiName: 'DMT_Credentials__c',
        value: false,
        size: '1-of-2',
        type: 'checkbox',
        isReadOnly: false,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'DES_Comments__c',
        label: 'Additional Comments',
        apiName: 'DES_Comments__c',
        value: '',
        size: '1-of-1',
        type: 'textarea',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        maxLength: 500,
        showCharacterCounter: true

    }
];