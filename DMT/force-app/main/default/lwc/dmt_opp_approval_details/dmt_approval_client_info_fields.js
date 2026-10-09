// Fields for Client Information section
// Fields with overridable: true show a comparison indicator when value differs from Account Group
export const clientInfoFields = [
  {
    id: "Geographical_Footprint_desc__c",
    label: "Geographical Footprint",
    apiName: "Geographical_Footprint_desc__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    overridable: true,
    maxLength: "598",
    showCharacterCounter: true
  },
  {
    id: "Relationship_Status_desc__c",
    label: "Relationship Status",
    apiName: "Relationship_Status_desc__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    overridable: true,
    maxLength: "598",
    showCharacterCounter: true,
    nbcScope: 'Global', // Only for Global NBC — shown when Product Area is GTB
  },
  {
    id: "Industry_Overview_desc__c",
    label: "Industry Overview",
    apiName: "Industry_Overview_desc__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    overridable: true,
    maxLength: "598",
    showCharacterCounter: true
  }
];

export const basicFinancialsFields = [
  {
    id: "Other_Relevant_Ratios_desc__c",
    label: "Other relevant ratios",
    apiName: "Other_Relevant_Ratios_desc__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    overridable: true,
    maxLength: "211",
    showCharacterCounter: true
  },
  {
    id: "cstk_sust_indicators_comments__c",
    label: "Basic financials comments",
    apiName: "cstk_sust_indicators_comments__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    overridable: true,maxLength: "618",
    showCharacterCounter: true
  }
];

export const basicFinancialsFieldsExtra = [
  {
    id: "DMT_Currency__c",
    label: "Currency",
    apiName: "DMT_Currency__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    value: '',
    type: 'picklist',
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    options: []
  }
];