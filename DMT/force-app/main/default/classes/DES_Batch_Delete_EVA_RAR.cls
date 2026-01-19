/**********************************************************************************
* @author       Accenture
* @date         
* @description  Manejador del Batch para el borrado de RAR EVA RORC (DES_Historic_RAR_EVA_RORC__c)
* @Revision     
                03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
**********************************************************************************/
public without sharing class DES_Batch_Delete_EVA_RAR implements Database.Batchable<Sobject>, Database.Stateful{
  
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  //private Integer relationshipsCreated = 0;
  private String query = 'SELECT Id FROM DES_Historic_RAR_EVA_RORC__c';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Batch_Delete_EVA_RAR() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<DES_Historic_RAR_EVA_RORC__c> listEVARAR) {
    system.debug('>>>>> BATCH listEVARAR: ' + listEVARAR);
    DES_Batch_Delete_EVA_RARHandler.borrarEVARAR(listEVARAR);
    recordsProcessed += listEVARAR.size();
  }

  public void finish(Database.BatchableContext bc) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Records Processed: ' + recordsProcessed);
    //System.debug('>>>>>   Relationships Created: ' + relationshipsCreated);
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }
}