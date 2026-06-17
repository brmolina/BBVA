/**********************************************************************************
* @author       Accenture
* @date
* @description  Batch para el borrado de JerarquíaClientes (AMH_GBL_Account_Relationship__c)
* @Revision
                03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
                15/10/2021 No borrar Registros con Clientes hijos que su recordtype sea igual a NIF Client
                20/04/2026 Refactorización: Se unifica el borrado de relaciones estándar y contrapartidas en una sola ejecución.
**********************************************************************************/
public without sharing class DES_Batch_Delete_AccRel implements Database.Batchable<Sobject>, Database.Stateful{

  //------------------------------ PRIVATE ATTRIBUTES -------------------------
  private Integer recordsProcessed = 0;
  private String jobMode;
  /*Variable global*/
  final static private String counterpartyType = '04 - Contrapartida';
  final static private String recordTypeNameNIF = System.Label.DES_STR_TYPE_NIF;
  /*QUERY*/
  final static private String query = 'SELECT Id FROM AMH_GBL_Account_Relationship__c WHERE ';

  //------------------------------ CONSTRUCTOR METHODS -------------------------
  public DES_Batch_Delete_AccRel() {
    this.jobMode = 'Standard';
    system.debug('Mode: ' + this.jobMode);
  }

  public DES_Batch_Delete_AccRel(String mode) {
    this.jobMode = mode;
    system.debug('Mode: ' + this.jobMode);
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String queryWhere = '';
    if (this.jobMode == 'COUNTERPARTIES') {
        queryWhere = query + 'AMH_Type__c = :counterpartyType AND AMH_Child_Account__r.gf_cust_orig_prospect_ind_type__c = false AND AMH_Parent_Account__r.gf_cust_orig_prospect_ind_type__c = false';
    } else {
        queryWhere = query + 'AMH_Type__c != :counterpartyType AND AMH_Child_Account__r.RecordType.Name != :recordTypeNameNIF AND AMH_Child_Account__r.gf_cust_orig_prospect_ind_type__c = false AND AMH_Parent_Account__r.gf_cust_orig_prospect_ind_type__c = false';
    }
    system.debug('>>>>> Query: ' + queryWhere);
    return Database.getQueryLocator(queryWhere);
  }

  public void execute(Database.BatchableContext bc, List<AMH_GBL_Account_Relationship__c> listAccRel) {
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