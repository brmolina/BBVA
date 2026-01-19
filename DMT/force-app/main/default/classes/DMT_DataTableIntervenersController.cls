public with sharing class DMT_DataTableIntervenersController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getApproverMemberFields() {
        List<Map<String, String>> result = new List<Map<String, String>>();
       
        // Get the approver member fields
        for (DMT_ApproverMemberFields__mdt appMemberField : [SELECT Label, DMT_FieldApiName__c, DMT_ObjectLookup__c FROM DMT_ApproverMemberFields__mdt ORDER BY DMT_ObjectLookup__c, Label ASC]) {

            result.add(new Map<String, String>{
                'label' => appMemberField.Label,
                'value' => appMemberField.DMT_ObjectLookup__c + '.' + appMemberField.DMT_FieldApiName__c
            });
        }
       
        return result;
    }
}