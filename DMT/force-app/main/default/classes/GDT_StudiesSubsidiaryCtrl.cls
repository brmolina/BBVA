/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-08-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class GDT_StudiesSubsidiaryCtrl {
    @AuraEnabled(cacheable=true)
    public static Id getLocalClientId(Id clientId) {
        if (clientId == null) return null;

        List<Local_Client__c> lcs = [
            SELECT Id
            FROM Local_Client__c
            WHERE Cib_Client__c = :clientId
            AND gf_prtcpt_act_status_ind_type__c = true
            LIMIT 1
        ];

        return lcs.isEmpty() ? null : lcs[0].Id;
    }
}