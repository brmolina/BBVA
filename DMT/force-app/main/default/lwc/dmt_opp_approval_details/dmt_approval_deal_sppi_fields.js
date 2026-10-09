// Fields for SPPI Test section (Deal tab, Approval Process Data)
// These fields belong to the Opportunity object and are routed via OPPORTUNITY_FIELD_NAMES
export const dealSppiFields = [
    {
        id: 'DMT_SPPI_File_Uploaded__c',
        label: 'File Uploaded',
        apiName: 'DMT_SPPI_File_Uploaded__c',
        objectType: 'Opportunity',
        value: false,
        size: '1-of-2',
        type: 'checkbox',
        isReadOnly: true,
        isHidden: false,
        isRequired: false
    },
    {
        id: 'DMT_SPPI_Status__c',
        label: 'SPPI Test Status',
        apiName: 'DMT_SPPI_Status__c',
        objectType: 'Opportunity',
        value: '',
        size: '1-of-2',
        type: 'picklist',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        options: [
            { label: 'Passed',                   value: 'Passed' },
            { label: 'Not Passed - NPC required', value: 'Not Passed - NPC required' },
            { label: 'Pending',                  value: 'Pending' },
            { label: 'N/A',                      value: 'N/A' }
        ]
    },
    {
        id: 'DMT_SPPI_User__c',
        label: 'User',
        apiName: 'DMT_SPPI_User__c',
        objectType: 'Opportunity',
        value: '',
        size: '1-of-2',
        type: 'text',
        isReadOnly: false,
        isHidden: false,
        isRequired: false,
        maxLength: 250
    }
];