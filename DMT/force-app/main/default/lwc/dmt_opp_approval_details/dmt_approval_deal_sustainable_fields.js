// Fields for Sustainable Finance section
// Fields with overridable: true show a comparison indicator when value differs from Account Group
export const dealSustainableFields = [
  {
    id: "DMT_Sustainable_Deal__c",
    label: "Sustainable Deal",
    apiName: "DMT_Sustainable_Deal__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "picklist",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    options: [
        { label: 'Yes',        value: 'Yes' },
        { label: 'No',         value: 'No' },
        { label: 'In process', value: 'In process' }
    ]
  },
  {
    id: "DMT_equator_Principles__c",
    label: "Equator principles scope",
    apiName: "DMT_equator_Principles__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "picklist",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    options: [
        { label: 'Not Applicable', value: 'Not Applicable' },
        { label: 'Project Finance - Energy', value: 'Project Finance - Energy' },
        { label: 'Project Finance - Infrastructure', value: 'Project Finance - Infrastructure' },
        { label: 'Project Finance - Real Estate', value: 'Project Finance - Real Estate' },
        { label: 'Project Finance - TMT', value: 'Project Finance - TMT' },
        { label: 'Project Finance - Other', value: 'Project Finance - Other' },
        { label: 'STF - Energy', value: 'STF - Energy' },
        { label: 'STF - Infrastructure', value: 'STF - Infrastructure' },
        { label: 'STF - TMT', value: 'STF - TMT' },
        { label: 'STF - Other', value: 'STF - Other' },
        { label: 'Corporate Loan - Energy', value: 'Corporate Loan - Energy' },
        { label: 'Corporate Loan - Infrastructure', value: 'Corporate Loan - Infrastructure' },
        { label: 'Corporate Loan - Real Estate', value: 'Corporate Loan - Real Estate' },
        { label: 'Corporate Loan - TMT', value: 'Corporate Loan - TMT' },
        { label: 'Corporate Loan - Other', value: 'Corporate Loan - Other' },
        { label: 'Bridge Loan - Energy', value: 'Bridge Loan - Energy' },
        { label: 'Bridge Loan - Infrastructure', value: 'Bridge Loan - Infrastructure' },
        { label: 'Bridge Loan - Real Estate', value: 'Bridge Loan - Real Estate' },
        { label: 'Bridge Loan - TMT', value: 'Bridge Loan - TMT' },
        { label: 'Bridge Loan - Other', value: 'Bridge Loan - Other' }
    ],
    overridable: true
  },
  {
    id: "DMT_Equator_Principles_Category__c",
    label: "Equator Principles Category",
    apiName: "DMT_Equator_Principles_Category__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "picklist",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    options: [
        { label: 'Not Applicable', value: 'Not Applicable' },
        { label: 'A', value: 'A' },
        { label: 'B+', value: 'B+' },
        { label: 'B', value: 'B' },
        { label: 'C', value: 'C' }
    ],
    overridable: true
  },
  {
    id: "DMT_Infrastructure_Supporting_Factor__c",
    label: "Infrastructure Supporting Factor",
    apiName: "DMT_Infrastructure_Supporting_Factor__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "picklist",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    options: [
        { label: 'Not Applicable', value: 'Not Applicable' },
        { label: 'Applicable', value: 'Applicable' },
        { label: 'None', value: 'None' }
    ],
    overridable: true
  },
  {
    id: "DMT_KPI_Margin_Adjustment__c",
    label: "KPI Margin Adjustment",
    apiName: "DMT_KPI_Margin_Adjustment__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    overridable: true,
    maxLength: "500",
    showCharacterCounter: true
  },
  {
    id: "DMT_comments__c",
    label: "Comments",
    apiName: "DMT_comments__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    overridable: true,
    maxLength: "3000",
    showCharacterCounter: true
  }
];