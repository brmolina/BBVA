/**********************************************************************************
* @author       Accenture
* @date         
* @description  Manejador del Batch para el borrado de JerarquíaClientes_Counterparties (dwp_acmh__GBL_Account_Relationship__c)
* @Revision     
                03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
**********************************************************************************/
public without sharing class DES_Batch_Delete_AccRel_Counterparties implements Database.Batchable<Sobject>, Database.Stateful{
  
  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  private Integer recordsProcessed = 0;
  //private Integer relationshipsCreated = 0;
  private String query = 'SELECT Id FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Type__c = \'04 - Contrapartida\'';

  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public DES_Batch_Delete_AccRel_Counterparties() {
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<dwp_acmh__GBL_Account_Relationship__c> listAccRel) {
    system.debug('>>>>> BATCH listAccRel: ' + listAccRel);
    DES_Batch_Delete_AccRelHandler.borrarAccRel(listAccRel);
    recordsProcessed += listAccRel.size();
    
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