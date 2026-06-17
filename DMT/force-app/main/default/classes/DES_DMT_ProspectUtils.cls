/**
* ────────────────────────────────────────────────────────────────────
* Prospect Utils class.
* ────────────────────────────────────────────────────────────────────
* @author     
* @modifiedBy
* @version     1.0
* @created     2026-05-27
* @modified
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class DES_DMT_ProspectUtils {

    /**
     * ________________________________________________________________________________________
     * @description: After Insert — Prospect Groups only when their status different Identify.
     *      → POST DES_PostCreateProspect
     * ________________________________________________________________________________________
     */
    public static void callCreateProspect(List<Account> newAccounts) {
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();

        for (Account acc : newAccounts) {
            if (acc.RecordTypeId == groupRtId && acc.DES_Group_Code__c != null) {
                DMT_AsyncOrchestrator.enqueue(new DES_ProspectStructurePayload(acc, 'DES_PostCreateProspect'));
            }
        }
    }

    /**
     * __________________________________________________________________________________________________
     * @description: After Update — unified create/edit logic for Groups and Subsidiaries.
     *
     * If NOT yet in HPG (DES_HPG_Synced__c = false) AND status != Identify:
     *     → POST DES_PostCreateProspect
     * If already in HPG (DES_HPG_Synced__c = true) AND status != Identify AND relevant fields changed:
     *     → PUT DES_PutEditProspect
     * __________________________________________________________________________________________________
     */
    public static void callCreateEditProspect(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        for (Account acc : newAccounts) {
            Account oldAcc = oldAccounts.get(acc.Id);

            Boolean statusNotIdentify = acc.DES_Prospect_Status_Funnel__c != DES_Constants.PROSPECT_STATUS_FUNNEL_IDENTIFY;
            Boolean existsInHPG       = acc.DMT_Prospect_HPG_Sync__c == true;

            Boolean isProspectGroup      = acc.RecordTypeId == groupRtId      && acc.DES_Group_Code__c != null;
            Boolean isProspectSubsidiary = acc.RecordTypeId == subsidiaryRtId && acc.g_customer_id__c  != null;

            Boolean isProspectGroupEdit = isProspectGroup && (
                acc.Name                    != oldAcc.Name
            );
            Boolean isProspectSubsidiaryEdit = isProspectSubsidiary && (
                acc.Name                    != oldAcc.Name ||
                acc.DES_Country_Client__c   != oldAcc.DES_Country_Client__c ||
                acc.participant_id__c       != oldAcc.participant_id__c ||
                acc.g_golden_customer_id__c != oldAcc.g_golden_customer_id__c
            );

            // CREATE in HPG - record doesn't exist yet
            if (!existsInHPG && (isProspectGroup || (isProspectSubsidiary && statusNotIdentify))) {
                DMT_AsyncOrchestrator.enqueue(new DES_ProspectStructurePayload(acc, 'DES_PostCreateProspect'));
            }
            // UPDATE in HPG - record already exists
            else if (existsInHPG && (isProspectGroupEdit || (isProspectSubsidiaryEdit && statusNotIdentify))) {
                DMT_AsyncOrchestrator.enqueue(new DES_ProspectStructurePayload(acc, 'DES_PutEditProspect'));
            }
        }
    }

}