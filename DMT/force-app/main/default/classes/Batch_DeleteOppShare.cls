/**********************************************************************************
* @author
* @date
* @description  Batch borrar las OppSh de usruarios de Aco
* @Revision
**********************************************************************************/
public without sharing class Batch_DeleteOppShare implements Database.Batchable<Sobject>, Database.Stateful {//NOSONAR

  /*
  * String query
  */
  /* method */
  final Desktop_Utils hndlrDeskUtils = Desktop_Utils.getInstance();
  private Set<Id> setRecordIds;//NOSONAR
  private String soqlQuery;//NOSONAR
  private Set<Id> accNames;//NOSONAR
  private Map<Id, List<Id>> mapUserAcc;//NOSONAR
    /*
    *Met0d0 que lanza el batch de borrado de opportunidades
    */
    public static void runJobForParticularRecords( Map<Id, List<String>> mapAccUserId ) {
    String soqlQueryString = '';
    final List<Batches_Process_Parameters__mdt> batchParams = new List<Batches_Process_Parameters__mdt>([SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = 'DES_BatchSize_DelOppSH' LIMIT 1]);
    final Integer batchSize = (Test.isRunningTest() || batchParams.isEmpty() ? 1 : batchParams.get(0).Batch_Size__c.intValue()); //NOSONAR
    Final Set<Id> setIds = new Set<Id>(mapAccUserId.keySet());
    if( setIds.size() > 0 ) {//NOSONAR
        soqlQueryString =   'SELECT id FROM Account WHERE Id IN :setRecordIds';
    }

    final Batch_DeleteOppShare cls = new Batch_DeleteOppShare();
    cls.setRecordIds = setIds;
    cls.soqlQuery = soqlQueryString;
    cls.mapUserAcc = mapAccUserId;
    Database.executeBatch(cls, batchSize);
  }

  //Method to get the data to be proceesed
  public Database.QueryLocator start(Database.BatchableContext BC) {//NOSONAR
    return Database.getQueryLocator(soqlQuery);
  }

  /*
  * @author Global Desktop
  * @Description Actualiza el campo country de las visitas al del cliente.
  */
  public void execute(Database.BatchableContext bch, List<Account> scope) {

    //Iteramos los clientes para pasarle la logica de borrado a cada uno
    for (Account key : scope) {
       ckUserLogic(key);
     }
  }
   /*
  * @author Global Desktop
  * @Description Se revisa la comparticion manual de los usuarios borrados
  * llamando a los met0d0s corerspondientes para su funcionamiento
  */
  private void ckUserLogic(Account key) {
	Set<Id> setOppsDeleteId;
    setOppsDeleteId = new Set<Id>();
    Set<Id> setUser;
    setUser = new Set<Id>();
    Set<Id> setAccount;
    setAccount = new Set<Id>();
    final Map<Id, String> mapClientGroup = new Map<Id, String>();
    final Map<Id, List<Id>> mapAccountUser = new Map<Id, List<Id>>();
    Set<Id> setRecordIds2 ;
    setRecordIds2 = new Set<Id>();
    for(String userid :mapUserAcc.get(key.id)) {
      mapAccountUser.put(key.id,mapUserAcc.get(key.id));
      setUser.add(userid);
    }
    setAccount.add(key.id);
    //buscamos los clientes de la jerarquia de matrx
    for(DES_Subsidiary_Group_Relation__c gsm : [SELECT participant_child_id__c, participant_parent_id__c FROM DES_Subsidiary_Group_Relation__c WHERE (participant_parent_id__c = :key.id OR participant_child_id__c = :key.id) AND main_subsidiary_ind_type__c = true]) {
      matrixAccountCk(gsm,setRecordIds2,mapClientGroup);
    }

    final Map<Id, Opportunity> mapOpps = new Map<Id, Opportunity>([SELECT Id, AccountId //NOSONAR
																	FROM Opportunity
																	WHERE AccountId IN :setRecordIds2 AND StageName != :Label.DES_Draft
																	AND disclosure_info_type__c != :Label.DES_OP_Inside
      ]);
    final Map<Id, String> mapAccountOpps = new Map<Id, String>();
    //Contruyo el mapa de Cliente-Oportunidad
    auxDeleteOppSh1(mapOpps, mapAccountOpps, setOppsDeleteId);
    final Map<Id, String> mapAccAndMemb = hndlrDeskUtils.getMapAccountAndMembers(setRecordIds2);
    final Map<Id, OpportunityShare> listShareToDelete = new Map<Id, OpportunityShare>([
      SELECT Id, OpportunityId, Opportunity.AccountId,UserOrGroupId
      FROM OpportunityShare
      WHERE OpportunityId IN :setOppsDeleteId
      AND UserOrGroupId IN:setUser
      AND RowCause = 'Manual'
      ]);
    //Se itera el mapa de OppSh para revisar si el usuario es directo o pertenece al grupo
    for(OpportunityShare opp : listShareToDelete.values()) {
      if(mapAccountUser.get(opp.Opportunity.AccountId) !=null) {
        //Se revisa si el usuario del oopSh pertenece a algun grupo
        auxDeleteOppSh(opp, mapClientGroup, mapAccountOpps, mapAccAndMemb, listShareToDelete,  mapAccountUser.get(opp.Opportunity.AccountId),mapAccountUser) ;
      }
      //Se revisa si el usuario del oopSh pertenece al cliente directo
      checkUserInOppSh(mapAccountUser,opp,listShareToDelete,mapAccAndMemb);
    }
    //Borramos los usuarios que han sobrevivido a la criba
    delete listShareToDelete.values();
    setAccount.remove(key.id);
  }
  /*
  * @author Global Desktop
  * @Description Compruebo si el usuario que se borra forma parte del equipo directo
  */
  private static void checkUserInOppSh(Map<Id, List<String>> mapAccUser,OpportunityShare opp,Map<Id, OpportunityShare> listShareToDelete,Map<Id, String> mapAccAndMemb ) {
   if(mapAccUser.containsKey(opp.Opportunity.AccountId)) {
    	if(mapAccUser.get(opp.Opportunity.AccountId).contains(opp.UserOrGroupId)) {
        if(mapAccAndMemb.containsKey(opp.Opportunity.AccountId)) {//NOSONAR
          finalDirectUserCK(mapAccAndMemb,opp,listShareToDelete);
        }
      }
    } else {
      if(mapAccAndMemb.get(opp.Opportunity.AccountId) != null) {
        finalDirectUserCK(mapAccAndMemb,opp,listShareToDelete);
      }
    }
  }

  /*
  * @author Global Desktop
  * @Description comprueba el usuario de AccountTeamMember,
  * con el usuario del OppSh
  */
  private static void finalDirectUserCK(Map<Id, String> mapAccAndMemb, OpportunityShare opp,Map<Id, OpportunityShare> listShareToDelete) {
    if(mapAccAndMemb.get(opp.Opportunity.AccountId).contains(';')) {
      for(string key2 :mapAccAndMemb.get(opp.Opportunity.AccountId).split(';') ) {
        if(key2 ==opp.UserOrGroupId) {
          listShareToDelete.remove(opp.id);
        }
      }
    } else {
      if(mapAccAndMemb.get(opp.Opportunity.AccountId) == opp.UserOrGroupId) {
        listShareToDelete.remove(opp.id);
      }
    }
  }
  /*
  * @author Global Desktop
  * @Description Met0d0 que construlle un mapa cliente-Oportunidad
  */
  private static void auxDeleteOppSh1(Map<Id, Opportunity> mapOpps, Map<Id, String> mapAccountOpps, Set<Id> setOppsDeleteId) {
    for(Opportunity opp : mapOpps.values()) {
      if(mapAccountOpps.get(opp.AccountId) == null) {
        mapAccountOpps.put(opp.AccountId, opp.Id);
      } else {
        mapAccountOpps.put(opp.AccountId, mapAccountOpps.get(opp.AccountId) + ';' + opp.Id);
      }
      if(!setOppsDeleteId.contains(opp.Id)) {
        setOppsDeleteId.add(opp.Id);
      }
    }
  }
/*
  * @author Global Desktop
  * @Description comprueba la matriz de clientes y contruye el mapa cliente-grupo
  */
  private static void matrixAccountCk(DES_Subsidiary_Group_Relation__c gsm,Set<Id> setRecordIds2,Map<Id, String> mapClientGroup) {
    if(!setRecordIds2.contains(gsm.participant_child_id__c)) {
      setRecordIds2.add(gsm.participant_child_id__c);
    }
    if(!setRecordIds2.contains(gsm.participant_parent_id__c)) {
      setRecordIds2.add(gsm.participant_parent_id__c);
    }
    mapClientGroup.put(gsm.participant_child_id__c, gsm.participant_parent_id__c);
  }

  /*
  * @author Global Desktop
  * @Description comprobacion final del usuario para los grupos
  */
  private static void auxDeleteOppSh(OpportunityShare opp, Map<Id, String> mapClientGroup, Map<Id, String> mapAccountOpps,
    Map<Id, String> mapAccAndMemb,Map<Id, OpportunityShare> listShareToDelete, List<String> user,Map<Id, List<String>> mapAccUser) {
    for (string key : user) {
      if(mapClientGroup.get(opp.Opportunity.AccountId) != null && mapAccountOpps.get(opp.Opportunity.AccountId) != null) {
        if(mapAccUser.get(opp.Opportunity.AccountId).contains(opp.UserOrGroupId)) {
          finalGroupUserCK(mapAccAndMemb,opp,mapClientGroup,listShareToDelete,key);
        } else {
          listShareToDelete.remove(opp.id);
        }
      }
    }
  }
  /*
  * Method Aux for delete OppShare
  */
  private static void finalGroupUserCK(Map<Id, String> mapAccAndMemb,OpportunityShare opp, Map<Id, String> mapClientGroup,Map<Id, OpportunityShare> listShareToDelete, string singelUser) {
    if(mapAccAndMemb.get(mapClientGroup.get(opp.Opportunity.AccountId)) != null ) {
      for(string aki :mapAccAndMemb.get(mapClientGroup.get(opp.Opportunity.AccountId)).split(';')) {
        if(mapAccAndMemb.containsKey(mapClientGroup.get(opp.Opportunity.AccountId)) && aki == singelUser && aki ==opp.UserOrGroupId) {
          listShareToDelete.remove(opp.id);
        }
      }
    }
  }
  /*
  * @author Global Desktop
  * @Description Finish
  */
  public void finish(Database.BatchableContext bch) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
    System.debug('memberMap--------------->'+mapUserAcc);
    BATCH_DeleteVisitShare.runJobForParticularRecords(mapUserAcc);
  }

}