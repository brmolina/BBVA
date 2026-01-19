/**********************************************************************************
* @author       Accenture
* @date
* @description  Batch para el borrado de JerarquíaClientes (dwp_acmh__GBL_Account_Relationship__c)
* @Revision
                03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
                15/10/2021 No borrar Registros con Clientes hijos que su recordtype sea igual a NIF Client
**********************************************************************************/
public without sharing class DES_Batch_Delete_AccRel implements Database.Batchable<Sobject>, Database.Stateful{

  //------------------------------ PRIVATE ATTRIBUTES -------------------------
  private Integer recordsProcessed = 0;
  /*Variable global*/
  final static private String counterpartyType = '04 - Contrapartida';
  final static private String recordTypeNameNIF = System.Label.DES_STR_TYPE_NIF;
  /*QUERY*/
  final static private String query = 'SELECT Id FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Type__c != :counterpartyType AND dwp_acmh__Child_Account__r.RecordType.Name != :recordTypeNameNIF';

  //------------------------------ CONSTRUCTOR METHODS -------------------------
  public DES_Batch_Delete_AccRel() {
  	system.debug(counterpartyType);
    system.debug('>>>>> Query: ' + query);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<dwp_acmh__GBL_Account_Relationship__c> listAccRel) {
    system.debug('>>>>> BATCH listAccRel: ' + listAccRel);
    DES_Batch_Delete_AccRelHandler.borrarAccRel(listAccRel);
    recordsProcessed+=listAccRel.size();
  }

  public void finish(Database.BatchableContext bc) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Records Processed: ' + recordsProcessed);
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }

}