export const dealBankingPoolFields = [
  {
    id: "DMT_Tiering_Action__c",
    label: "Tiering Action",
    apiName: "DMT_Tiering_Action__c",
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
    id: "DMT_Current__c",
    label: "Current Tier",
    apiName: "DMT_Current__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "number",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    min:0,
    max:9999999999999999
  },
  {
    id: "DMT_Target__c",
    label: "Target Tier",
    apiName: "DMT_Target__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "number",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    min:0,
    max:9999999999999999
  }
  ];