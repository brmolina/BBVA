public without sharing class GBL_DenormalizeOpportunitiesDelete implements Database.Batchable<Sobject>, Database.Stateful {
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsDeleted = 0;
  private String pQuery = 'SELECT Id FROM AMH_Denorm_Account_Opportunity__c';
  private Boolean pCreateRecords = false;

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public GBL_DenormalizeOpportunitiesDelete(){
  }

  public GBL_DenormalizeOpportunitiesDelete(Boolean createRecords){
    //Delete all relationships. If createRecords=True, launches the Recreation Batchable class
    pCreateRecords = createRecords;
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc){
    return Database.getQueryLocator(pQuery);
  }

  public  void execute(Database.BatchableContext bc,List<SObject> scope){
    recordsDeleted = recordsDeleted + scope.size();
    delete scope;
  }

  public void finish(Database.BatchableContext bc){
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('SUMMARY: ');
    System.debug('  Records Deleted: ' + recordsDeleted);
    System.debug('  Batches Created: ' + job.JobItemsProcessed);
    System.debug('  Number of Errors: ' + job.NumberOfErrors);
    System.debug('  Status: ' + job.Status);

    //Execute the Batchable process for Denormalize Opportunities
    if (pCreateRecords) {
      Integer executeBatchSize = getExecuteBatchSize();
      system.debug('executeBatchSize: ' + executeBatchSize);
      if (executeBatchSize > 0) {
        Database.executeBatch (new GBL_DenormalizeOpportunitiesExecute(), executeBatchSize);
      }
    }
  }

  private Integer getExecuteBatchSize(){
    List<AMH_GBL_Account_Multi_Hierarchy_denorm__mdt> lmdt = [SELECT Label, NamespacePrefix, DeveloperName, AMH_Delete_Batch_Size__c, AMH_Execute_Batch_Size__c, AMH_Lead_Lookup_Field_To_Account__c, AMH_Opportunity_Filter__c, AMH_Opportunity_Lookup_Field_To_Lead__c, AMH_Active__c FROM AMH_GBL_Account_Multi_Hierarchy_denorm__mdt WHERE AMH_Active__c=true LIMIT 1];
    Integer result=-1;

    if (lmdt.size() > 0)
      result = Integer.valueOf(lmdt[0].AMH_Execute_Batch_Size__c);
    system.debug('getExecuteBatchSize(): ' + result);
    return result;
  }
}