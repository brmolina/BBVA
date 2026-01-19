/*
* Clase batch que relaciona las iniciativas con las cuentas.
*/
public without sharing class Batch_InsertInitiatives implements Database.Batchable<Sobject>, Database.Stateful {
  /*Variable privada*/
  private final String pQuery; //NOSONAR
  /*Variable privada*/
  private final Campaign campana;
  /*Variable privada*/
  private final List<intt__GBL_MappingInitiativeGroup__mdt> lstMapping;
  /*Variable privada*/
  private final Campaign objCampana;
  /*Variable privada*/
  private final List<Account> listAcc;

  /*Constructor*/
  public Batch_InsertInitiatives(List<Account> listAccPar, Campaign campanaPar, List<intt__GBL_MappingInitiativeGroup__mdt> lstMappingPar, Campaign objCampanaPar) {
      this.listAcc = listAccPar;
      this.campana = campanaPar;
      this.lstMapping = lstMappingPar;
      this.objCampana = objCampanaPar;
      this.pQuery = 'SELECT Id FROM Account WHERE Id IN :listAcc';
  }

  /*start met0d0*/
  public Database.QueryLocator start(Database.BatchableContext bch) {
      return Database.getQueryLocator(pQuery);
  }

  /*execute met0d0*/
  public void execute(Database.BatchableContext bch, List<Account> scope) {
    final Set<Id> setIdFilial = new Set<Id>();
    if(campana.country_name__c != null) {
      final List<AggregateResult> bookList = [SELECT COUNT(Id), DES_Client__c
                                              FROM DES_Booking__c
                                              WHERE DES_Client__c IN :scope
                                                AND DES_Country__c IN :campana.country_name__c.split(';')
                                              GROUP BY DES_Client__c];

      for (AggregateResult iAggResult : bookList) {
        final Id cliente = (Id) iAggResult.get('DES_Client__c');
        setIdFilial.add(cliente);
      }
    } else {
      for(Account iAccount : scope) {
        setIdFilial.add(iAccount.Id);
      }
    }

    List<cond__Account_Campaign__c> lstRelatedAccount = new List<cond__Account_Campaign__c>();
    for(Id idFilial : setIdFilial) {
    //for(Integer i = 0; i < lstAccount.size(); i++) {
      cond__Account_Campaign__c objRelatedAccount = new cond__Account_Campaign__c();

      objRelatedAccount.cond__campaign_id__c = campana.Id;
      objRelatedAccount.cond__participant_id__c = idFilial;
      objRelatedAccount.recordTypeid = Schema.SObjectType.cond__Account_Campaign__c.getRecordTypeInfosByName().get('Initiative').getRecordTypeId();
      objRelatedAccount.cond__Campaign_status_approval_type__c = 'Draft';

      //mapping
      objRelatedAccount.cond__priority_campaign_type__c = campana.cond__priority_campaign_type__c;
      objRelatedAccount.cond__campaign_desc__c = campana.description;
      objRelatedAccount.cond__campaign_start_date__c = campana.StartDate;
      objRelatedAccount.cond__campaign_end_date__c = campana.EndDate;

      for(intt__GBL_MappingInitiativeGroup__mdt mapInit : lstMapping) {
        objRelatedAccount.put(mapInit.intt__GroupField__c,objCampana.get(mapInit.intt__InitiativeField__c));
      }
      lstRelatedAccount.add(objRelatedAccount);
    }

    for(Integer i=0;i<lstRelatedAccount.size();i++) {
       if(lstRelatedAccount[i].cond__campaign_desc__c!=null&&lstRelatedAccount[i].cond__campaign_desc__c.length()>250) {

         lstRelatedAccount[i].cond__campaign_desc__c = lstRelatedAccount[i].cond__campaign_desc__c.substring(0, 250);
       }
    }

    if(lstRelatedAccount.size()>0) {
      insert lstRelatedAccount;
    }
  }

  /*finish met0d0*/
  public void finish(Database.BatchableContext bch) {
      system.debug('Finish');
  }
}