/**
 * @Description Batch para actualizar las oportunidades de Desktop 
 * @author Desktop
*/
public without sharing class DES_Batch_UpdateDesktopOpportunities implements Database.Batchable<Sobject>, Database.Stateful {
    
    /*Se define y ejecuta la query*/
    public Database.QueryLocator start(Database.BatchableContext bcc) {
        return Database.getQueryLocator([SELECT Id FROM Opportunity 
                                         WHERE RecordType.DeveloperName = 'Draft_Opportunity' 
                                         OR  RecordType.DeveloperName = 'Business_Opportunity' 
                                         OR RecordType.DeveloperName = 'Confidential_Opportunity']);
    }
    
    /*Se actualiza la lista de oportunidades*/
    public void execute(Database.BatchableContext bcc, List<Opportunity> listOpps) {
        update listOpps;
    }
	
    /*Se recuperan los logs de la ejecucion*/
    public void finish(Database.BatchableContext bcc) {        
        final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bcc.getJobId()];
        System.debug('>>>>> SUMMARY: ');
        System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
        System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
        System.debug('>>>>>   Status: ' + job.Status);
    }
    
}