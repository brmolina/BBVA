/*
* batch upadate subsidiary fields from group of matrix
*/
public without sharing class DES_Batch_BBVAManualSharing implements Database.Batchable<Sobject>, Database.Stateful {
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String INTEGRATION_PROFILE = 'Desktop Integration';
    private final String pQuery;
    /*
    * constructor method
    */
    public DES_Batch_BBVAManualSharing() {
        pQuery = 'SELECT Id, DES_Client__c, DES_User__c, DES_Member_Role__c, DES_Clave_Externa__c, copy_record_approval_type__c ' +
                'FROM DES_BBVA_Management_team__c ' +
                'WHERE CreatedBy.Profile.Name IN (:ADMIN_PROFILE, :INTEGRATION_PROFILE) ' +
                'OR LastModifiedBy.Profile.Name IN (:ADMIN_PROFILE, :INTEGRATION_PROFILE)' +
                (Test.isRunningTest() ? ' LIMIT 1' : '');
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
    public void execute(Database.BatchableContext bch, List<DES_BBVA_Management_team__c> scope) {
        if (scope.isEmpty()) return;
        final DES_BBVAManagementTeamTriggerHandler handler = DES_BBVAManagementTeamTriggerHandler.getInstance();
        handler.createManualSharing(scope, true);
        DES_BBVAManagementTeamTriggerHandler.insertCommAlertManualSharing(scope);
        DES_BBVAManagementTeam_Helper.insAlertMember(scope);
    }
    /*
    * Finish method
    */
    public void finish(Database.BatchableContext bch) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, 
                          TotalJobItems, CreatedBy.Email 
                          FROM AsyncApexJob WHERE Id = :bch.getJobId()];
        
        System.debug(LoggingLevel.INFO, 'Resumen del proceso batch DES_Batch_BBVAManualSharing:');
        System.debug(LoggingLevel.INFO, 'Lotes procesados: ' + job.JobItemsProcessed);
        System.debug(LoggingLevel.INFO, 'Número de errores: ' + job.NumberOfErrors);
        System.debug(LoggingLevel.INFO, 'Estado final: ' + job.Status);
    }

}