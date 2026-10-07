// TODO: Add actual field API names from Salesforce once confirmed
export const dealRiskFields = [
  
  {
    id: "DMT_Asset_Allocation_limit__c",
    label: "Asset Allocation Limit",
    apiName: "DMT_Asset_Allocation_limit__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "picklist",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    options: []
  },
  {
    id: "DMT_Financial_Program_limit__c",
    label: "Financial Program Limit",
    apiName: "DMT_Financial_Program_limit__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "picklist",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    options: []
  },
  {
    id: "DMT_Top_3_Active_Facilities__c",
    label: "Top 3 Active Facilities (included in PF limits)",
    apiName: "DMT_Top_3_Active_Facilities__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "2-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    maxLength: "500",
    showCharacterCounter: true
  }
];