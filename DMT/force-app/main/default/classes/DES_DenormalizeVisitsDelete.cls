/*
*Name:            DES_DenormalizeVisitsDelete
*Description:     Batch class with denorm visits delete
*Test Class:      -
*
*Version        Date            Author            Summary of changes
*--------------------------------------------------------------------------------------------------------------------------------
*0.1            08/05/2018      JSS               Class creation
*0.2            30/09/2019      JSS               Se añade en el metodo finish codigo para coger dinamicamente de custom meta data el batchSize
*/
public without sharing class DES_DenormalizeVisitsDelete implements Database.Batchable<Sobject>, Database.Stateful {
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  /* recordsDeleted */
  private Integer recordsDeleted = 0;
  /* Two years Date */
  private final Date twoYears = Date.newInstance(date.today().year()-1, 1, 1); //NOSONAR
  /* Query */
  private final String pQuery = 'SELECT Id, DES_Visit_new__r.CreatedDate FROM DES_Denorm_AccountVisits__c WHERE DES_Visit_new__r.CreatedDate > :twoYears'; //NOSONAR
  /* pCreateRecords */
  private Boolean pCreateRecords = false;

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_DenormalizeVisitsDelete() {
  }

  public DES_DenormalizeVisitsDelete(Boolean createRecords) {
    //Delete all relationships. If createRecords=True, launches the Recreation Batchable class
    pCreateRecords = createRecords;
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(pQuery);
  }

  public void execute(Database.BatchableContext bc,List<SObject> scope) {
    recordsDeleted = recordsDeleted + scope.size();
    delete scope;
  }

  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('SUMMARY: ');
    System.debug('  Records Deleted: ' + recordsDeleted);
    System.debug('  Batches Created: ' + job.JobItemsProcessed);
    System.debug('  Number of Errors: ' + job.NumberOfErrors);
    System.debug('  Status: ' + job.Status);

    //Execute the Batchable process for Denormalize Visits
    if (pCreateRecords) {
      final Batches_Process_Parameters__mdt batchParams = [SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c
                                                             FROM Batches_Process_Parameters__mdt
                                                             WHERE DeveloperName = 'Denorm_Visit' LIMIT 1];

      final Integer pBatchSize = (Test.isRunningTest() ? 200 : batchParams.Batch_Size__c.intValue());
      Database.executeBatch (new DES_DenormalizeVisitsExecute(),pBatchSize);
    }
  }
}