trigger Opportunity_Local on dwp_cvad__Action_Audit__c (before insert,before update) {
   for(dwp_cvad__Action_Audit__c audt: Trigger.new){
       if(audt.Local_Opportunity__c != null){
           audt.dwp_cvad__action_audit_record_id__c = audt.Local_Opportunity__c;
       }                      
    }
}