// Fields for Treasury & Settlement Form section (cfRiskFormLine migration)
// Options for picklists are populated dynamically from the Integration Procedure
export const formFields = [
  {
    id: "DvP_Amount__c",
    label: "Delivery versus Payment (DvP) Amount",
    apiName: "DvP_Amount__c",
    objectType: "DMT_Line__c",
    value: "",
    size: "1-of-2",
    type: "currency",
    step: "0.01",
    isReadOnly: false,
    isHidden: false,
    isRequired: false
  },
  {
    id: "FD_Amount__c",
    label: "Free Delivery (FD) Amount",
    apiName: "FD_Amount__c",
    objectType: "DMT_Line__c",
    value: "",
    size: "1-of-2",
    type: "currency",
    step: "0.01",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    hiddenGeographies: ["AR"]
  },
  {
    id: "First_Breakclause__c",
    label: "First Breakclause",
    apiName: "First_Breakclause__c",
    objectType: "DMT_Line__c",
    value: "",
    size: "1-of-2",
    type: "picklist",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    options: [],
    hiddenGeographies: ["CO", "PE", "AR"]
  },
  {
    id: "Breakclause_Frequency__c",
    label: "Breakclause Frequency",
    apiName: "Breakclause_Frequency__c",
    objectType: "DMT_Line__c",
    value: "",
    size: "1-of-2",
    type: "picklist",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    options: [],
    hiddenGeographies: ["CO", "PE", "AR"]
  },
  {
    id: "Waiver__c",
    label: "Exception to the policy on the execution of mitigating agreements (ISDA/GMRA/GMSLA or similar)",
    apiName: "Waiver__c",
    objectType: "DMT_Line__c",
    value: false,
    size: "1-of-2",
    type: "checkbox",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    hiddenGeographies: ["CO", "PE", "AR", "MX"]
  },
  {
    id: "DMT_Mitigant_Agreement_comments__c",
    label: "Mitigant Agreement comments",
    apiName: "DMT_Mitigant_Agreement_comments__c",
    objectType: "DMT_Line__c",
    value: "",
    size: "1-of-2",
    type: "text",
    isReadOnly: false,
    isHidden: false,
    isRequired: false,
    maxLength: 100,
    hiddenGeographies: ["CO", "PE", "AR", "MX"]
  }
];