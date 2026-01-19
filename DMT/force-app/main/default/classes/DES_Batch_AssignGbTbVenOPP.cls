/**
* @author       Global Desktop
* @date         26/05/2020
* @description  Batch para Asignar manual sharing a GB y TB en las oportunidades existentes.
*
* Version   Date            Author          Summary of changes
*
* ----------------------------------------------------------------------------------
*/
public without sharing class DES_Batch_AssignGbTbVenOPP implements Database.Batchable<Sobject>, Database.Stateful {

  /*Variables globales*/
  final static String VEN = 'VE';

  /*Variable Query a realizar para ejecucion de batch*/
  final static private String QUERY = 'Select Id, AccountId from Opportunity where Account.DES_Country_Client__c = :VEN';

  /*Util methods*/
  final Desktop_Utils handlerDsktpUtls = Desktop_Utils.getInstance();

  /*Constructor method*/
  public DES_Batch_AssignGbTbVenOPP() {
    system.debug('>>>>> Query: ' + QUERY);
  }

  /*Start method*/
  public Database.QueryLocator start(Database.BatchableContext bContext) {
    return Database.getQueryLocator(QUERY);
  }

  /*Execute method*/
  public void execute(Database.BatchableContext bContext, List<Opportunity> oppList) {
  final List<String> literals = new List<String>{'VE', Label.DES_ROLE_GLOBAL_BANKER ,Label.DES_Role_Transactional_Banker}; //NOSONAR
  Map<Id, Id> mapClientsGroups;
  mapClientsGroups = new Map<Id, Id>();
  Set<Id> setAllAccounts;
  setAllAccounts = new Set<Id>();
  Map<Id, String> mapAccAndMmbrs;
  mapAccAndMmbrs = new Map<Id, String>();
  Map<Id, List<DES_BBVA_Management_team__c>> mapAccMminfo;
  mapAccMminfo = new Map<Id, List<DES_BBVA_Management_team__c>>();
  List<OpportunityShare> lstMnlShrOpps;
  lstMnlShrOpps = new List<OpportunityShare>();
  Set<Id> setIdDirectClient;
  setIdDirectClient = new Set<Id>();

  for (Opportunity auxOpp : oppList) {
    setIdDirectClient.add(auxOpp.AccountId);
  }

mapClientsGroups = handlerDsktpUtls.getMapClientGroup(setIdDirectClient);
  system.debug('>>>>> mapClientsGroups : ' + mapClientsGroups);

  setAllAccounts.addAll(mapClientsGroups.values());
  system.debug('>>>>> setAllAccounts : ' + setAllAccounts);

  mapAccAndMmbrs = handlerDsktpUtls.getMapAccountAndMembers(setAllAccounts);
  system.debug('>>>>> mapAccAndMmbrs : ' + mapAccAndMmbrs);

  mapAccMminfo = handlerDsktpUtls.getMapAccountAndMembersInfo(setAllAccounts);
  system.debug('>>>>> mapAccMminfo : ' + mapAccMminfo);

  for(Opportunity opp : oppList) {
    System.debug('>>>>> la validacion es ------> ' + mapAccMminfo.get(mapClientsGroups.get(opp.AccountId)));
    if(mapAccMminfo.get(mapClientsGroups.get(opp.AccountId)) != null) {
      for(DES_BBVA_Management_team__c team : mapAccMminfo.get(mapClientsGroups.get(opp.AccountId))) {
        if(team.DES_Local_Banker_Country__c == literals[0] && team.DES_Member_Role__c == literals[2]) {
          System.debug('>>>>> Se agrego el TB');
          lstMnlShrOpps.add(handlerDsktpUtls.newManualSharingOpportunity(opp.Id, team.DES_User__c, 'Edit'));
        } else if(team.DES_Member_Role__c == literals[1]) {
          System.debug('>>>>> Se agrego el GB');
          lstMnlShrOpps.add(handlerDsktpUtls.newManualSharingOpportunity(opp.Id, team.DES_User__c, 'Edit'));
        }
      }
    }
  }

  system.debug('>>>>> lstMnlShrOpps : ' + lstMnlShrOpps);
  final List<Database.SaveResult> listSR = Database.insert(lstMnlShrOpps,false);
  system.debug('>>>>> Result insert Databse: ' + listSR);

  }

  /*Finish method*/
  public void finish(Database.BatchableContext bContext) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, CompletedDate, CreatedDate, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bContext.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
    System.debug('>>>>>   Was processed between: ' + job.CreatedDate.format('MM/dd/yyyy HH:mm:ss') + ' And ' + job.CompletedDate.format('MM/dd/yyyy HH:mm:ss'));
  }
}