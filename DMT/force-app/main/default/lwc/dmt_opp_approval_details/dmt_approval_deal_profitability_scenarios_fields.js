// Fields for Client Profitability section
// Fields with overridable: true show a comparison indicator when value differs from Account Group
export const dealProfitabilityScenariosFields = [
  {
    id: "DMT_Rating_Scenarios__c",
    label: "Rating scenarios",
    apiName: "DMT_Rating_Scenarios__c",
    objectType: 'DMT_Opportunity_Client__c',
    value: "",
    size: "1-of-2",
    type: "textarea",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    maxLength: "840",
    showCharacterCounter: true
  }
];