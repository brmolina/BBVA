/**********************************************************************************
* @author
* @date
* @description  Batch para la eliminación de opp share
* @Revision
**********************************************************************************/
public without sharing class Batch_deleteOppSharing implements Database.Batchable<Sobject>, Database.Stateful {

  /* Query attribute */
  final private String pQuery;

  /* Constructor */
  public Batch_deleteOppSharing() {
    pQuery = 'SELECT Id, UserOrGroupId, UserOrGroup.name, OpportunityId, Opportunity.name, Opportunity.AccountId, Opportunity.StageName, Opportunity.disclosure_info_type__c, OpportunityAccessLevel, RowCause FROM OpportunityShare WHERE RowCause = \'Manual\' and UserOrGroupId not in (select id from Group where Type = \'Territory\') '+(Test.isRunningTest() ? ' LIMIT 1' : '');
  }

  /* Start method */
  public Database.QueryLocator start(Database.BatchableContext bcontext) {
    return Database.getQueryLocator(pQuery);
  }

  /* Exexute method */
  public void execute(Database.BatchableContext bcontext,List<OpportunityShare> scope) {
    final Set<Id> setAccOpsIds = new Set<Id>();
    final Map<Id,Id> mapClientGroup = new Map<Id,Id>();
    final List<OpportunityShare> listToDelete = new List<OpportunityShare>();

    for(OpportunityShare oppsh : scope) {
      setAccOpsIds.add(oppsh.Opportunity.AccountId);
    }
    system.debug('setAccOpsIds ' + JSON.serialize(setAccOpsIds));


    final List<DES_Subsidiary_Group_Relation__c> matrixRelation = new List<DES_Subsidiary_Group_Relation__c> ([
      SELECT Id, participant_parent_id__c, participant_child_id__c FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c IN: setAccOpsIds AND main_subsidiary_ind_type__c = true
    ]);

    system.debug('matrixRelation ' + JSON.serialize(matrixRelation));

    for(DES_Subsidiary_Group_Relation__c matrix : matrixRelation) {
      if(mapClientGroup.get(matrix.participant_child_id__c) == null) {
        mapClientGroup.put(matrix.participant_child_id__c, matrix.participant_parent_id__c);
      }
    }

    system.debug('mapClientGroup ' + JSON.serialize(mapClientGroup));

    final Map<Id,List<Id>> mapAccMembers = fillMembers(setAccOpsIds, mapClientGroup);
    system.debug('mapAccMembers ' + JSON.serialize(mapAccMembers));

    for(OpportunityShare oppsh : scope) {
      if(chkNotMembers(mapAccMembers, mapClientGroup, oppsh) || chkBothMembers(mapAccMembers, mapClientGroup, oppsh) || chkFilialMember(mapAccMembers, mapClientGroup, oppsh) || chkGroupMember(mapAccMembers, mapClientGroup, oppsh)) {
        listToDelete.add(oppsh);
      }
    }
    system.debug('listToDelete ' + JSON.serialize(listToDelete));

    if(!listToDelete.isEmpty()) {
      delete listToDelete;
    }

  }

  /* Private method to fill members map */
  private Map<Id,List<Id>> fillMembers(Set<Id> setAccOpsIds, Map<Id,Id> mapClientGroup) {
    final Map<Id,List<Id>> mapAccMembers = new Map<Id,List<Id>>();

    final List<DES_BBVA_Management_Team__c> listBBVATM = new List<DES_BBVA_Management_Team__c>([
      SELECT Id, DES_Client__c, DES_User__c FROM DES_BBVA_Management_Team__c
      WHERE (DES_Client__c IN :setAccOpsIds OR DES_Client__c IN :mapClientGroup.values())
      AND copy_record_approval_type__c = false
    ]);

    for(DES_BBVA_Management_Team__c bbvaTM : listBBVATM) {
      if(mapAccMembers.get(bbvaTM.DES_Client__c) == null) {
        mapAccMembers.put(bbvaTM.DES_Client__c, new List<Id> {bbvaTM.DES_User__c});
      } else {
        final List<Id> listAux = mapAccMembers.get(bbvaTM.DES_Client__c);
        listAux.add(bbvaTM.DES_User__c);
        mapAccMembers.put(bbvaTM.DES_Client__c, listAux);
      }
    }
    return mapAccMembers;
  }

  /* Method to check if filial and group don't have team members */
  private Boolean chkNotMembers(Map<Id,List<Id>> mapAccMembers, Map<Id,Id> mapClientGroup, OpportunityShare oppsh) {
    Boolean notMembers = false;
    if(mapAccMembers.get(oppsh.Opportunity.AccountId) == null && mapAccMembers.get(mapClientGroup.get(oppsh.Opportunity.AccountId)) == null) {
      notMembers = true;
    }
    system.debug('notMembers ' + notMembers);
    return notMembers;
  }

  /* Method to check if filial and group have team members but not contains the user*/
  private Boolean chkBothMembers(Map<Id,List<Id>> mapAccMembers, Map<Id,Id> mapClientGroup, OpportunityShare oppsh) {
    Boolean bothMembers = false;
    if(mapAccMembers.get(oppsh.Opportunity.AccountId) != null && !mapAccMembers.get(oppsh.Opportunity.AccountId).contains(oppsh.UserOrGroupId) &&
      mapAccMembers.get(mapClientGroup.get(oppsh.Opportunity.AccountId)) != null && !mapAccMembers.get(mapClientGroup.get(oppsh.Opportunity.AccountId)).contains(oppsh.UserOrGroupId)) {
        bothMembers = true;
    }
    system.debug('bothMembers ' + bothMembers);
    return bothMembers;
  }

  /* Method to check if filial has team members but not contains the user and group doesn't have team members */
  private Boolean chkFilialMember(Map<Id,List<Id>> mapAccMembers, Map<Id,Id> mapClientGroup, OpportunityShare oppsh) {
    Boolean filialMember = false;
    if(mapAccMembers.get(oppsh.Opportunity.AccountId) != null && !mapAccMembers.get(oppsh.Opportunity.AccountId).contains(oppsh.UserOrGroupId) && mapAccMembers.get(mapClientGroup.get(oppsh.Opportunity.AccountId)) == null) {
      filialMember = true;
    }
    system.debug('filialMember ' + filialMember);
    return filialMember;
  }

  /* Method to check if group has team members but not contains the user and filial doesn't have team members */
  private Boolean chkGroupMember(Map<Id,List<Id>> mapAccMembers, Map<Id,Id> mapClientGroup, OpportunityShare oppsh) {
    Boolean groupMember = false;
    if(mapAccMembers.get(oppsh.Opportunity.AccountId) == null && mapAccMembers.get(mapClientGroup.get(oppsh.Opportunity.AccountId)) != null && !mapAccMembers.get(mapClientGroup.get(oppsh.Opportunity.AccountId)).contains(oppsh.UserOrGroupId)) {
      groupMember = true;
    }
    system.debug('groupMember ' + groupMember);
    return groupMember;
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }

}