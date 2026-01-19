/**********************************************************************************
* @author       IBM
* @date         
* @description  Batch para el borrado de TopWonDeals (DES_TopWonDeals__c)
**********************************************************************************/
public without sharing class DES_Batch_Delete_TopWonDeals implements Database.Batchable<Sobject>, Database.Stateful {
   
  /* Private attributes */
  private Integer recordsProcessed = 0;
  /* Batch query */
  private final String query = 'SELECT Id, participant_id__c, year_month_day_date__c, franch_oper_rslt_amount__c, solution_category_id__c  FROM DES_TopWonDeals__c';

  /* Constructor */
  public DES_Batch_Delete_TopWonDeals() {
    system.debug('>>>>> Query: ' + query);
  }

  /* Batchable methods */
  public Database.QueryLocator start(Database.BatchableContext batchContext) {
    return Database.getQueryLocator(query);
  }
  
  /*
  * @author Global Desktop
  * @description Valida que el objeto DES_TopWonDeals__c esté vacío y sino es así lo borra
  */
  public void execute(Database.BatchableContext batchContext, List<DES_TopWonDeals__c> listTopWonDeals) {
    system.debug('>>>>> BATCH listTopWonDeals: ' + listTopWonDeals);
        
    if(!listTopWonDeals.isEmpty()) {
          delete listTopWonDeals;
          Database.emptyRecycleBin(listTopWonDeals);             
    }
    recordsProcessed += listTopWonDeals.size();    
  }

  /*
  * @author Global Desktop
  * @description Finaliza el Batch
  */
  public void finish(Database.BatchableContext batchContext) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchContext.getJobId()];

    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Records Processed: ' + recordsProcessed);
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }
}