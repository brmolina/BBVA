/***************************************************************************
* @author       Global Desktop
* @date         04/05/2019
* @description  helper handler
***************************************************************************/
public with sharing class AccountNPSHandler {
    //CONSTRUCTOR
    private AccountNPSHandler() {
    }

    /*
    *Check subsiadiary
    */
    public static void checkNPSSubsidiary(Set<Id> accsId) {
        final Set <Id> subsidiaryIds = new Set <Id>();
        final Map <Id, Boolean> npsForSubsidiary = new Map <Id, Boolean>();

        for(DES_Group_Subsidiary_Matrix__c matrix : [SELECT Id, participant_name__c, participant_name__r.survey_nps_contact_type__c,
            company_costumer_id__c, senior_pos_type__c FROM DES_Group_Subsidiary_Matrix__c
            WHERE participant_name__c in :accsId
        ]) {
            if(!subsidiaryIds.contains(matrix.company_costumer_id__c)) {
                subsidiaryIds.add(matrix.company_costumer_id__c);
            }
            if(npsForSubsidiary.get(matrix.company_costumer_id__c) == null) {
                npsForSubsidiary.put(matrix.company_costumer_id__c, matrix.participant_name__r.survey_nps_contact_type__c);
            }
        }
        System.debug('subsidiaryIds ->' + subsidiaryIds);
        System.debug('npsForSubsidiary ->' + npsForSubsidiary);
        updateAccountNPS(subsidiaryIds, npsForSubsidiary);
    }

    /*
    *Check group
    */
    public static void checkNPSGroup(Set<Id> accsId) {
        final Set <Id> groupsIds = new Set <Id>();
        final Map <Id, Boolean> npsForGroups = new Map <Id, Boolean>();

        for(dwp_acmh__GBL_Account_Relationship__c relation : [SELECT Id, dwp_acmh__Child_Account__c, dwp_acmh__Child_Account__r.RecordTypeId, dwp_acmh__Parent_Account__r.survey_nps_contact_type__c
            FROM dwp_acmh__GBL_Account_Relationship__c
            WHERE dwp_acmh__Parent_Account__c IN :accsId AND dwp_acmh__Child_Account__r.RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Group).getRecordTypeId()]) {
            if(!groupsIds.contains(relation.dwp_acmh__Child_Account__c)) {
                groupsIds.add(relation.dwp_acmh__Child_Account__c);
            }
            if(npsForGroups.get(relation.dwp_acmh__Child_Account__c) == null) {
                npsForGroups.put(relation.dwp_acmh__Child_Account__c, relation.dwp_acmh__Parent_Account__r.survey_nps_contact_type__c);
            }
        }

        System.debug('groupsIds ->' + groupsIds);
        System.debug('npsForGroups ->' + npsForGroups);
        updateAccountNPS (groupsIds, npsForGroups);
    }

    private static void updateAccountNPS (Set<Id> accIds, Map<Id, Boolean> npsForAcc) {

        final List <Account> accsUpdate = new List <Account>();

        for(Account acc : [SELECT Id, survey_nps_contact_type__c FROM Account WHERE Id in :accIds]) {
            acc.survey_nps_contact_type__c = npsForAcc.get(acc.Id);
            accsUpdate.add(acc);
        }

        System.debug('accsUpdate ->' + accsUpdate);
        if(!accsUpdate.isEmpty()) {
            update accsUpdate;
        }
    }
}