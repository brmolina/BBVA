/**********************************************************************************
* @author       IBM
* @date         
* @description  Batch para el borrado de RCF Expiration (RCF_Expiration__c)
**********************************************************************************/
public without sharing class DES_Batch_Delete_RCFExpiration implements Database.Batchable<Sobject>, Database.Stateful {
   
  /* Private attributes */
  private Integer recordsProcessed = 0;
  /* Batch query */
  private final String query = 'SELECT Id, participant_id__c, current_expiry_date__c, deal_total_amount__c, bbva_prtcp_tranche_amount__c  FROM RCF_Expiration__c';

  /* Constructor */
  public DES_Batch_Delete_RCFExpiration() {
    system.debug('>>>>> Query: ' + query);
  }

  /* Batchable methods */
  public Database.QueryLocator start(Database.BatchableContext batchContext) {
    return Database.getQueryLocator(query);
  }
  
  /*
  * @author Global Desktop
  * @description Valida que el objeto RCF_Expiration__c esté vacío y sino es así lo borra
  */
  public void execute(Database.BatchableContext batchContext, List<RCF_Expiration__c> listRCF) {
    system.debug('>>>>> BATCH listRCF: ' + listRCF);
        
    if(!listRCF.isEmpty()) {
          delete listRCF;
          Database.emptyRecycleBin(listRCF);             
    }
    recordsProcessed += listRCF.size();    
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