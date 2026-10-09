// TODO: Add actual field API names from Salesforce once confirmed
export const dealOtherAspectsFields = [
  {
    id: "DMT_Applicable_Jurisdiction__c",
    label: "Applicable jurisdiction",
    apiName: "DMT_Applicable_Jurisdiction__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    maxLength: "100",
    showCharacterCounter: true
  },
  {
    id: "DMT_Security_Package__c",
    label: "Security package",
    apiName: "DMT_Security_Package__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    maxLength: "382",
    showCharacterCounter: true
  },
  {
    id: "DMT_Other_Relevant_Issues__c",
    label: "Other relevant issues",
    apiName: "DMT_Other_Relevant_Issues__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    maxLength: "836",
    showCharacterCounter: true,
    nbcScope: 'Global', // Only for Global NBC — shown when Product Area is GTB
  }
];