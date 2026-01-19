/**********************************************************************************
* @author
* @date
* @description  Batch para la eliminación de opp share
* @Revision
**********************************************************************************/
public without sharing class Batch_deleteVisitSharing implements Database.Batchable<Sobject>, Database.Stateful {

    /* Query attribute */
    final private String pQuery;

    /* Constructor */
    public Batch_deleteVisitSharing() {
      pQuery = 'SELECT Id, UserOrGroupId, UserOrGroup.name, Parent.name, Parent.dwp_kitv__account_id__c, Parent.disclosure_info_type__c, AccessLevel, RowCause from dwp_kitv__Visit__Share WHERE RowCause = \'Manual\' and UserOrGroupId not in (select id from Group where Type = \'Territory\') '+(Test.isRunningTest() ? ' LIMIT 1' : '');
    }

    /* Start method */
    public Database.QueryLocator start(Database.BatchableContext bctx) {
      return Database.getQueryLocator(pQuery);
    }

    /* Exexute method */
    public void execute(Database.BatchableContext bctx,List<dwp_kitv__Visit__Share> scope) {
      final Set<Id> setAccVisIds = new Set<Id>();
      final Set<Id> setVisitIds = new Set<Id>();
      final Map<Id,Id> mapClientGroup = new Map<Id,Id>();
      final List<dwp_kitv__Visit__Share> listToDelete = new List<dwp_kitv__Visit__Share>();

      for(dwp_kitv__Visit__Share visitsh : scope) {
        setAccVisIds.add(visitsh.Parent.dwp_kitv__account_id__c);
        setVisitIds.add(visitsh.Parent.Id);
      }

      final List<DES_Subsidiary_Group_Relation__c> matrixRelation = new List<DES_Subsidiary_Group_Relation__c> ([
        SELECT Id, participant_parent_id__c, participant_child_id__c FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c IN: setAccVisIds AND main_subsidiary_ind_type__c = true
      ]);

      for(DES_Subsidiary_Group_Relation__c matrix : matrixRelation) {
        if(mapClientGroup.get(matrix.participant_child_id__c) == null) {
          mapClientGroup.put(matrix.participant_child_id__c, matrix.participant_parent_id__c);
        }
      }

      final Map<Id,List<Id>> mapAccMembers = fillMembers(setAccVisIds, mapClientGroup);
      final Map<Id,List<Id>> mapVisitMembers = fillVisitMembers(setVisitIds);

      for(dwp_kitv__Visit__Share visitsh : scope) {
        if((chkNotMembers(mapAccMembers, mapClientGroup, visitsh) || chkBothMembers(mapAccMembers, mapClientGroup, visitsh) || chkFilialMember(mapAccMembers, mapClientGroup, visitsh) || chkGroupMember(mapAccMembers, mapClientGroup, visitsh)) && chkVisitMember(mapVisitMembers,visitsh)) {
          listToDelete.add(visitsh);
        }
      }

      if(!listToDelete.isEmpty()) {
        delete listToDelete;
      }

    }

    /* Private method to fill members map */
    private Map<Id,List<Id>> fillMembers(Set<Id> setAccVisIds, Map<Id,Id> mapClientGroup) {
      final Map<Id,List<Id>> mapAccMembers = new Map<Id,List<Id>>();

      final List<DES_BBVA_Management_Team__c> listBBVATM = new List<DES_BBVA_Management_Team__c>([
        SELECT Id, DES_Client__c, DES_User__c FROM DES_BBVA_Management_Team__c
        WHERE (DES_Client__c IN :setAccVisIds OR DES_Client__c IN :mapClientGroup.values())
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
    private Boolean chkNotMembers(Map<Id,List<Id>> mapAccMembers, Map<Id,Id> mapClientGroup, dwp_kitv__Visit__Share visitsh) {
      Boolean notMembers = false;
      if(mapAccMembers.get(visitsh.Parent.dwp_kitv__account_id__c) == null && mapAccMembers.get(mapClientGroup.get(visitsh.Parent.dwp_kitv__account_id__c)) == null) {
        notMembers = true;
      }
      system.debug('>>>>>>>>>>> cliente' + mapAccMembers.get(visitsh.Parent.dwp_kitv__account_id__c));
      system.debug('>>>>>>>>>>> grupo' + mapAccMembers.get(mapClientGroup.get(visitsh.Parent.dwp_kitv__account_id__c)));
      system.debug('notMembers' + notMembers);
      return notMembers;
    }

    /* Method to check if filial and group have team members but not contains the user*/
    private Boolean chkBothMembers(Map<Id,List<Id>> mapAccMembers, Map<Id,Id> mapClientGroup, dwp_kitv__Visit__Share visitsh) {
      Boolean bothMembers = false;
      if(mapAccMembers.get(visitsh.Parent.dwp_kitv__account_id__c) != null && !mapAccMembers.get(visitsh.Parent.dwp_kitv__account_id__c).contains(visitsh.UserOrGroupId) &&
        mapAccMembers.get(mapClientGroup.get(visitsh.Parent.dwp_kitv__account_id__c)) != null && !mapAccMembers.get(mapClientGroup.get(visitsh.Parent.dwp_kitv__account_id__c)).contains(visitsh.UserOrGroupId)) {
          bothMembers = true;
      }
        system.debug('bothMembers ' + visitsh.UserOrGroup.Name + ' ' + bothMembers);
      return bothMembers;
    }

    /* Method to check if filial has team members but not contains the user and group doesn't have team members */
    private Boolean chkFilialMember(Map<Id,List<Id>> mapAccMembers, Map<Id,Id> mapClientGroup, dwp_kitv__Visit__Share visitsh) {
      Boolean filialMember = false;
      if(mapAccMembers.get(visitsh.Parent.dwp_kitv__account_id__c) != null && !mapAccMembers.get(visitsh.Parent.dwp_kitv__account_id__c).contains(visitsh.UserOrGroupId) && mapAccMembers.get(mapClientGroup.get(visitsh.Parent.dwp_kitv__account_id__c)) == null) {
        filialMember = true;
      }
        system.debug('mapAccMembers ' + visitsh.UserOrGroupId + ' ' + mapAccMembers.get(visitsh.Parent.dwp_kitv__account_id__c));
        system.debug('mapAccMembersgrupo ' + visitsh.UserOrGroupId + ' ' + mapAccMembers.get(mapClientGroup.get(visitsh.Parent.dwp_kitv__account_id__c)));
        system.debug('filialMember ' + visitsh.UserOrGroup.Name + ' ' + filialMember);
      return filialMember;
    }

    /* Method to check if group has team members but not contains the user and filial doesn't have team members */
    private Boolean chkGroupMember(Map<Id,List<Id>> mapAccMembers, Map<Id,Id> mapClientGroup, dwp_kitv__Visit__Share visitsh) {
      Boolean groupMember = false;
      if(mapAccMembers.get(visitsh.Parent.dwp_kitv__account_id__c) == null && mapAccMembers.get(mapClientGroup.get(visitsh.Parent.dwp_kitv__account_id__c)) != null && !mapAccMembers.get(mapClientGroup.get(visitsh.Parent.dwp_kitv__account_id__c)).contains(visitsh.UserOrGroupId)) {
        groupMember = true;
      }
        system.debug('groupMember ' + visitsh.UserOrGroup.Name + ' ' + groupMember);
      return groupMember;
    }

     /* Method to check if is visit member */
    private Boolean chkVisitMember(Map<Id,List<Id>> mapVisitMembers, dwp_kitv__Visit__Share visitsh) {
      Boolean groupMember = false;
      if(mapVisitMembers.get(visitsh.Parent.Id) == null || !mapVisitMembers.get(visitsh.Parent.Id).contains(visitsh.UserOrGroupId)) {
        groupMember = true;
      }
        system.debug('visitmember ' + visitsh.UserOrGroup.Name + ' ' + groupMember);
      return groupMember;
    }
    
        /* Private method to fill visit members map */
    private Map<Id,List<Id>> fillVisitMembers(Set<Id> setVistIds) {
      final Map<Id,List<Id>> mapVisitMembers = new Map<Id,List<Id>>();

      final List<dwp_kitv__Visit_Management_Team__c> listVisitTeam = new List<dwp_kitv__Visit_Management_Team__c>([
       	SELECT Id, dwp_kitv__visit_id__c, dwp_kitv__user_id__c FROM dwp_kitv__Visit_Management_Team__c where dwp_kitv__user_id__c  != null
          and dwp_kitv__visit_id__c in :setVistIds
      ]);

      for(dwp_kitv__Visit_Management_Team__c visitTM : listVisitTeam) {
        if(mapVisitMembers.get(visitTM.dwp_kitv__visit_id__c) == null) {
          mapVisitMembers.put(visitTM.dwp_kitv__visit_id__c, new List<Id> {visitTM.dwp_kitv__user_id__c});
        } else {
          final List<Id> listAux = mapVisitMembers.get(visitTM.dwp_kitv__visit_id__c);
          listAux.add(visitTM.dwp_kitv__user_id__c);
          mapVisitMembers.put(visitTM.dwp_kitv__visit_id__c, listAux);
        }
      }
      return mapVisitMembers;
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