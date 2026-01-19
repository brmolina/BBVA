/**********************************************************************************
* @author       IBM
* @date         
* @description  Batch para el borrado de Term Loans Repayment (Loans_Repayment__c)
**********************************************************************************/
public without sharing class DES_Batch_Delete_LoansRepayment implements Database.Batchable<Sobject>, Database.Stateful {
   
  /* Private attributes */
  private Integer recordsProcessed = 0;
  /* Batch query */
  private final String query = 'SELECT Id, participant_id__c, gf_settlement_date__c, synd_loan_amortization_amount__c, bbva_repayment_amount__c  FROM Loans_Repayment__c';

  /* Constructor */
  public DES_Batch_Delete_LoansRepayment() {
    system.debug('>>>>> Query: ' + query);
  }

  /* Batchable methods */
  public Database.QueryLocator start(Database.BatchableContext batchContext) {
    return Database.getQueryLocator(query);
  }
  
  /*
  * @author Global Desktop
  * @description Valida que el objeto Loans_Repayment__c esté vacío y sino es así lo borra
  */
  public void execute(Database.BatchableContext batchContext, List<Loans_Repayment__c> listLoans) {
    system.debug('>>>>> BATCH listLoans: ' + listLoans);
        
    if(!listLoans.isEmpty()) {
          delete listLoans;
          Database.emptyRecycleBin(listLoans);             
    }
    recordsProcessed += listLoans.size();    
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