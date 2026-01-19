public without sharing class DeleteSubsidiaryGroupRelation_Batch implements Database.Batchable<Sobject>, Database.Stateful{
    
    private Integer recordsProcessed = 0;
    private String query = 'SELECT Id FROM DES_Subsidiary_Group_Relation__c' + (Test.isRunningTest()?' LIMIT 1':'');
    
    public DeleteSubsidiaryGroupRelation_Batch() {
    	 system.debug('>>>>> Query: ' + query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<DES_Subsidiary_Group_Relation__c> listRelation) {
    	delete listRelation;
    }
    
    public void finish(Database.BatchableContext bc) {
    	AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
    	System.debug('>>>>> SUMMARY: ');
	    System.debug('>>>>>   Records Processed: ' + recordsProcessed);
	    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
	    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
	    System.debug('>>>>>   Status: ' + job.Status);
    }
    
}