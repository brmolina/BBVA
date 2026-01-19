/**********************************************************************************
* @author
* @date
* @description  Batch para el creación de GBMatrix en Account
* @Revision
**********************************************************************************/
public without sharing class DES_Batch_createGBMatrix implements Database.Batchable<Sobject>, Database.Stateful {

  private String SubGroupRT = 'SubGroup';
  private String SubsidiaryRT = 'Subsidiary';
  private String SubsidiaryCommercialClientRT = 'DES_Subsidiary_Commercial_Client';
  private String subsidiaryGlobalRT = 'SER_Service_Account';
  private String pQuery;
  private Id idGroupAccount;
  private Id idGroupGB;
  private Boolean foundGroup = false;


  public DES_Batch_createGBMatrix() {
    pQuery = 'SELECT Id, Name, DES_Main_Parent__c, DES_Global_banker__c, RecordType.DeveloperName FROM Account Where (RecordType.DeveloperName =: SubGroupRT OR RecordType.DeveloperName =: SubsidiaryRT OR RecordType.DeveloperName = :subsidiaryGlobalRT OR RecordType.DeveloperName =: SubsidiaryCommercialClientRT) AND DES_Structure_Type__c != null'+(Test.isRunningTest() ? ' LIMIT 1' : '');
  }


  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(pQuery);
  }


  public void execute(Database.BatchableContext bc,List<Account> scope) {
    List<DES_Group_Subsidiary_Matrix__c> gsMatrixList = new List<DES_Group_Subsidiary_Matrix__c>();
    system.debug('>>>>> scope : ' + scope );
    for(Account a : scope) {
      foundGroup = false;
      idGroupAccount = null;
      idGroupGB = null;
      recursiveFxn(a.Id);
      //List<DES_BBVA_Management_team__c> ctMember = [SELECT Id, DES_User__c FROM DES_BBVA_Management_team__c WHERE DES_Member_Role__c = 'Global Banker' AND DES_Client__c =: idGroupAccount];
      //if(!ctMember.isEmpty()){
      system.debug('>>>>> a : ' + a );
      system.debug('>>>>> idGroupAccount : ' + idGroupAccount );
      system.debug('>>>>> idGroupGB : ' + idGroupGB );
      if(idGroupAccount != null
         && foundGroup == true) {
        DES_Group_Subsidiary_Matrix__c gsMatrix = new DES_Group_Subsidiary_Matrix__c();
        gsMatrix.company_costumer_id__c = a.Id;
        gsMatrix.participant_name__c = idGroupAccount;
        gsMatrix.senior_pos_type__c = idGroupGB;
        gsMatrixList.add(gsMatrix);
        system.debug('>>>>> gsMatrix : ' + gsMatrix );
      }

      //}
    }
    if(!gsMatrixList.isEmpty()) {
      insert gsMatrixList;
    }

  }

  public void recursiveFxn(String accId) {

    if (accId != null) {
      List<dwp_acmh__GBL_Account_Relationship__c> listAccRel = [SELECT ID, dwp_acmh__Parent_Account__c, dwp_acmh__Parent_Account__r.DES_Global_banker__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Child_Account__c =: accId];
      system.debug('>>>>> listAccRel : ' + listAccRel );
      if(!listAccRel.isEmpty()) {
        foundGroup = true;
      }
      for (dwp_acmh__GBL_Account_Relationship__c accRel : listAccRel) {
        system.debug('>>>>> accRel : ' + accRel );
        idGroupAccount = accRel.dwp_acmh__Parent_Account__c;
        idGroupGB = accRel.dwp_acmh__Parent_Account__r.DES_Global_banker__c;
        recursiveFxn(accRel.dwp_acmh__Parent_Account__c);

      }
    }

  }


  public void finish(Database.BatchableContext bc) {
      Id batchInstanceId = Database.executeBatch(new DES_Batch_updateSubsidiaryFields(), 1000);
  }

}