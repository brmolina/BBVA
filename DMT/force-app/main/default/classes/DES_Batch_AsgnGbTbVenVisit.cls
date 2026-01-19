/**
* @author       Global Desktop
* @date         26/05/2020
* @description  Batch para Asignar manual sharing a GB y TB en las Visitas existentes.
*
* Version   Date            Author          Summary of changes
*
* ----------------------------------------------------------------------------------
*/
public without sharing class DES_Batch_AsgnGbTbVenVisit implements Database.Batchable<Sobject>, Database.Stateful {

  /*Variable Set de Id clientes relacionado a la visita*/
  private static Set<Id> setIdClients = new Set<Id>();

  /*Variable MAP que relacionado visita al grupo*/
  private static Map<Id, Id> mapCltGrpVst = new Map<Id, Id>();

  /*Variable literal VE*/
  final static String VEN = 'VE';

  /*Variable Query*/
  final private static String QUERY = 'Select dwp_kitv__account_id__c, dwp_kitv__country_name__c from dwp_kitv__Visit__c  where dwp_kitv__account_id__r.DES_Country_Client__c = :VEN ';

  /*Util methods*/
  final Desktop_Utils utilsHandler = Desktop_Utils.getInstance();

  private static void fillClientVisits(dwp_kitv__Visit__c visit) {
    if(!setIdClients.contains(visit.dwp_kitv__account_id__c)) {
      setIdClients.add(visit.dwp_kitv__account_id__c);
    }
  }

  /*Util methods: Rellena la variable mapCltGrpVst*/
  public static void fillMapVisitIdGroup(List<dwp_kitv__Visit__c> newVisits, Set<Id> idClients) {
    final List <DES_Subsidiary_Group_Relation__c> clientRelations = [SELECT Id, participant_parent_id__c, participant_child_id__c from DES_Subsidiary_Group_Relation__c where participant_child_id__c IN :idClients];
    for(dwp_kitv__Visit__c currentVisit : newVisits) {
      for(DES_Subsidiary_Group_Relation__c currentRelation : clientRelations) {
        if(currentRelation.participant_child_id__c == currentVisit.dwp_kitv__account_id__c) {
          mapCltGrpVst.put(currentVisit.Id,currentRelation.participant_parent_id__c);
        }
      }
    }
  }

  /*Constructor method*/
  public DES_Batch_AsgnGbTbVenVisit() {
    system.debug('>>>>> Query: ' + QUERY);
  }

  /*Start method*/
  public Database.QueryLocator start(Database.BatchableContext bContext) {
    return Database.getQueryLocator(QUERY);
  }

  /*Execute method*/
  public void execute(Database.BatchableContext bContext, List<dwp_kitv__Visit__c> vstList) {

    final List<String> literals = new List<String>{'VE', Label.DES_ROLE_GLOBAL_BANKER, Label.DES_Role_Transactional_Banker};//NOSONAR
    Map<Id, List<DES_BBVA_Management_team__c>> mapAccMemInf;
    mapAccMemInf = new Map<Id, List<DES_BBVA_Management_team__c>>();
    List<dwp_kitv__Visit__Share> lstMnlShrVisits;
    lstMnlShrVisits = new List<dwp_kitv__Visit__Share>();

    for(dwp_kitv__Visit__c fillIds : vstList) {
      fillClientVisits(fillIds);
    }
    system.debug('>>>>>> setIdClients' + setIdClients);

    fillMapVisitIdGroup(vstList,setIdClients);
    system.debug('>>>>>> mapCltGrpVst' + mapCltGrpVst);

    final Set<Id> clntGrpVists = new Set<Id>(mapCltGrpVst.values());
    mapAccMemInf = utilsHandler.getMapAccountAndMembersInfo(clntGrpVists);
    system.debug('>>>>>> mapAccMemInf' + mapAccMemInf);

    for(dwp_kitv__Visit__c visit : vstList) {
      System.debug('>>>>> la validacion es ------> ' + mapAccMemInf.get(mapCltGrpVst.get(visit.Id)));
      if(mapAccMemInf.get(mapCltGrpVst.get(visit.Id)) != null) {
        for(DES_BBVA_Management_team__c team : mapAccMemInf.get(mapCltGrpVst.get(visit.Id))) {
          if(team.DES_Local_Banker_Country__c == literals[0] && team.DES_Member_Role__c == literals[2]) {
            System.debug('>>>>> Se agrego el TB');
            lstMnlShrVisits.add(utilsHandler.newManualSharingVisits(visit.Id, team.DES_User__c, 'Edit'));
          } else if(team.DES_Member_Role__c == literals[1]) {
            System.debug('>>>>> Se agrego el GB');
            lstMnlShrVisits.add(utilsHandler.newManualSharingVisits(visit.Id, team.DES_User__c, 'Edit'));
          }
        }
      }
    }

    system.debug('>>>>> lstMnlShrVisits: ' + lstMnlShrVisits);
    final List<Database.SaveResult> listSR = Database.insert(lstMnlShrVisits,false);
    system.debug('>>>>> Result insert Databse: ' + listSR);

  }

  /*Finish method*/
  public void finish(Database.BatchableContext bContext) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,CompletedDate, CreatedDate, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bContext.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
    System.debug('>>>>>   was processed between: ' + job.CreatedDate.format('MM/dd/yyyy HH:mm:ss') + ' And ' + job.CompletedDate.format('MM/dd/yyyy HH:mm:ss'));
  }
}