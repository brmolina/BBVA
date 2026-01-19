/*
* @author       Global Desktop
* @date         23/07/2020
* @description  Batch to delete opps created in the last two last years and opened opps
*/
public without sharing class GBL_DenormalizeOppDeleteLocal implements Database.Batchable<Sobject>, Database.Stateful {

  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  /* recordsDeleted */
  private Integer recordsDeleted = 0;
  /* pCreateRecords */
  private Boolean pCreateRecords = false; //NOSONAR
  /* Two years Date */
  private Date twoYears = Date.newInstance(date.today().year()-1, 1, 1); //NOSONAR
  /* Query */
  private String pQuery = 'SELECT Id FROM dwp_acmh__Denorm_Account_Opportunity__c WHERE (dwp_acmh__OpportunityId__r.IsClosed = false OR (dwp_acmh__OpportunityId__r.IsClosed = true AND dwp_acmh__OpportunityId__r.CreatedDate >= :twoYears))'; //NOSONAR

  /*
  * Constructor
  */
  public GBL_DenormalizeOppDeleteLocal(Boolean createRecords) {
    //Delete all relationships. If createRecords=True, launches the Recreation Batchable class
    pCreateRecords = createRecords;
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    system.debug('twoYears: ' + twoYears);
    system.debug('Query: ' + pQuery);
    return Database.getQueryLocator(pQuery);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch,List<SObject> scope) {
    recordsDeleted = recordsDeleted + scope.size();
    delete scope;
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    final AsyncApexJob job1 = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
    system.debug('job1: ' + job1);

    //Execute the Batchable process for Denormalize Opportunities
    if (pCreateRecords) {
      final Integer executeBatchSize = gtExecuteBatchSize();
      system.debug('executeBatchSize: ' + executeBatchSize);
      if (executeBatchSize > 0) {
        Database.executeBatch(new GBL_DenormalizeOppExecuteLocal(), executeBatchSize);
      }
    }
  }

  /*
  * getExecuteBatchSize method
  */
  private Integer gtExecuteBatchSize() {
    final List<dwp_acmh__GBL_Account_Multi_Hierarchy_denorm__mdt> lmdt = [SELECT Label, NamespacePrefix, DeveloperName, dwp_acmh__Delete_Batch_Size__c, dwp_acmh__Execute_Batch_Size__c, dwp_acmh__Lead_Lookup_Field_To_Account__c, dwp_acmh__Opportunity_Filter__c, dwp_acmh__Opportunity_Lookup_Field_To_Lead__c, dwp_acmh__Active__c FROM dwp_acmh__GBL_Account_Multi_Hierarchy_denorm__mdt WHERE dwp_acmh__Active__c = true LIMIT 1];
    Integer result=-1;

    if (lmdt.size() > 0) {
      result = Integer.valueOf(lmdt[0].dwp_acmh__Execute_Batch_Size__c);
    }
    system.debug('getExecuteBatchSize(): ' + result);
    return result;
  }
}