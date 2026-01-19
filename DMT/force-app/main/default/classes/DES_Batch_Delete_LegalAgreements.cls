/**********************************************************************************
* @author       IBM
* @date         
* @description  Batch para el borrado de Contratos Marco (Contrato_Marco__c)
**********************************************************************************/
public without sharing class DES_Batch_Delete_LegalAgreements implements Database.Batchable<Sobject>, Database.Stateful {
   
  /* Private attributes */
  private Integer recordsProcessed = 0;
  /* Batch query */
  private final String query = 'SELECT Id, participant_id__c, gf_deal_signing_date__c, master_agreement_type__c, gf_agree_annex_typo_desc__c  FROM Contrato_Marco__c';

  /* Constructor */
  public DES_Batch_Delete_LegalAgreements() {
    system.debug('>>>>> Query: ' + query);
  }

  /* Batchable methods */
  public Database.QueryLocator start(Database.BatchableContext batchContext) {
    return Database.getQueryLocator(query);
  }
  
  /*
  * @author Global Desktop
  * @description Valida que el objeto Contrato_Marco__c esté vacío y sino es así lo borra
  */
  public void execute(Database.BatchableContext batchContext, List<Contrato_Marco__c> listLegalAgreements) {
    system.debug('>>>>> BATCH listLegalAgreements: ' + listLegalAgreements);
        
    if(!listLegalAgreements.isEmpty()) {
          delete listLegalAgreements;
          Database.emptyRecycleBin(listLegalAgreements);             
    }
    recordsProcessed += listLegalAgreements.size();    
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