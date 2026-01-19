/*
* batch upadate subsidiary fields from group of matrix
*/
public without sharing class DES_Batch_updateSubsidiaryFields  implements Database.Batchable<Sobject>, Database.Stateful {
    private final String pQuery;
    /*
    * constructor method
    */
    public DES_Batch_updateSubsidiaryFields() {
        pQuery = 'Select Id, business_group_id__c, DES_Global_banker__c, DES_Country_of_Management__c, DES_Group_Code__c, DES_Structure_Type__c from Account WHERE DES_Structure_Type__c != null' + (Test.isRunningTest()?' LIMIT 1':'');
    }
    /*
    * start method
    */
    public Database.QueryLocator start(Database.BatchableContext bch) {
        return Database.getQueryLocator(pQuery);
    }
    /*
    * Execute method
    */
    public void execute(Database.BatchableContext bch, List<Account> scope) {
        final List<Account> accsUpdate = new List<Account>();
        final Set <Id> accsIds = new Set <Id>();
        for(Account acc : scope) {
            if(!accsIds.contains(acc.Id)) {
                accsIds.add(acc.Id);
            }
        }

        final Map<Id, DES_Subsidiary_Group_Relation__c > subsidiaryGroup = new Map <Id, DES_Subsidiary_Group_Relation__c >();

        for(DES_Subsidiary_Group_Relation__c matrix : [SELECT Id, participant_parent_id__c, participant_child_id__c , participant_parent_id__r.DES_Global_banker__c, participant_parent_id__r.DES_Group_Code__c, participant_parent_id__r.DES_Country_of_Management__c
        FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c  IN :accsIds AND main_subsidiary_ind_type__c = true]) {
            if(subsidiaryGroup.get(matrix.participant_child_id__c ) == null) {
                subsidiaryGroup.put(matrix.participant_child_id__c , matrix);
            }
        }

        for(Account acc : scope) {
            if(subsidiaryGroup.get(acc.Id) != null) {
                acc.business_group_id__c = subsidiaryGroup.get(acc.Id).participant_parent_id__c;
                acc.group_global_banker_user_id__c = subsidiaryGroup.get(acc.Id).participant_parent_id__r.DES_Global_banker__c;
                acc.group_management_country_id__c = subsidiaryGroup.get(acc.Id).participant_parent_id__r.DES_Country_of_Management__c;
                acc.DES_Subsidiary_Group_Code__c = subsidiaryGroup.get(acc.Id).participant_parent_id__r.DES_Group_Code__c;
            } else if(acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Supragroup
                || acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Group
                || acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Subgroup
                || acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Shared_Manag_Group) {
                    acc.business_group_id__c = null;
                    acc.group_global_banker_user_id__c = acc.DES_Global_banker__c;
                    acc.group_management_country_id__c = acc.DES_Country_of_Management__c;
                    acc.DES_Subsidiary_Group_Code__c = acc.DES_Group_Code__c;
            } else {
                acc.business_group_id__c = null;
                acc.group_global_banker_user_id__c = null;
                acc.group_management_country_id__c = null;
                acc.DES_Subsidiary_Group_Code__c = null;
            }
            accsUpdate.add(acc);
        }

        if(!accsUpdate.isEmpty()) {
            update accsUpdate;
        }
    }
    /*
    * Finish method
    */
    public void finish(Database.BatchableContext bch) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
        System.debug('>>>>> SUMMARY: ');
        System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
        System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
        System.debug('>>>>>   Status: ' + job.Status);
    }

}