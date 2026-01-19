/**
────────────────────────────────────────────────────────────────────
KPI_MainTableController
Controller class for KPI_MainTable Aura Component
────────────────────────────────────────────────────────────────────
@author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
@modifiedBy
@version     1.0
@created     2023-02-24
@modified
@systemLayer
────────────────────────────────────────────────────────────────────
@changes
────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods, PMD.ExcessiveParameterList, sf:NPathComplexity, PMD.ApexCRUDViolation, PMD.NcssTypeCount, PMD.EmptyStatementBlock, PMD.NcssMethodCount, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.ApexSOQLInjection, PMD.FormalParameterNamingConventions, PMD.ExcessiveClassLength , PMD.ExcessivePublicCount, PMD.AvoidGlobalModifier, PMD.UnusedLocalVariable, PMD.ApexAssertionsShouldIncludeMessage, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
public with sharing class KPI_MainTableController {
    /**
    @description Method that returns obligations
    @param jsonString Json to send in the call
    @return Map<String, Object> {success}
    */
    @AuraEnabled
    public static Map<String, Object> putFinantialCustomer(String updateRequest) {
        Map<String, Object> res = new Map<string, Object>{ 'suc' => true };
        if (updateRequest != null) {
            final String payload = updateRequest.replaceAll('(\\d{4})-(\\d{2})-(\\d{2})(T[0-9:\\.]*Z)?', '$1-$2-$3');
            final Map<String, Object> request = new Map<String, Object>{ 'payload' => updateRequest };
            res = KPI_FinantialCustomers.putFinantialCustomer(request);
        }
        return res;
    }

    public static String getgroupCode(String groupId) {
        return 'client.group.id=' + [SELECT cstk__account_id__r.DES_Group_Code__c FROM cstk__Toolkit__c WHERE Id = :groupId][0].cstk__account_id__r.DES_Group_Code__c + '&';
    }
}