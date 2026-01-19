public without sharing class DES_Batch_UpdateOpportunities  implements Database.Batchable<Sobject>, Database.Stateful{
    
    public DES_Batch_UpdateOpportunities(){
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        return Database.getQueryLocator([SELECT Id FROM Opportunity]);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> listOpps) {
        update listOpps;
    }

    public void finish(Database.BatchableContext bc) {        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        System.debug('>>>>> SUMMARY: ');
        System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
        System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
        System.debug('>>>>>   Status: ' + job.Status);
    }

}