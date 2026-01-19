/*
* @author Global Desktop
* @description  Clase Helper para el trigger de User
*/
public with sharing class User_Helper {

  /*
  * Private constructor
  */
  private User_Helper() {
  }

  /*
  * Singleton pattern
  */
  private static User_Helper instance;

  /*
  * MAP AMBIT METADATA
  */
  public final static Map<String, Arce_ambit_hierarchy__mdt> MAPAMBIT = gtAmbitMetadata();

  /*
  * Public constructor
  */
  public static User_Helper gtInstance() {
      if (instance == null) {
        instance = new User_Helper();
      }
      return instance;
  }

  /*
	* Variable Public Group Mexico
	*/
	static final String PBMEXICO = 'cTMMexico';
	
	/*
	* Variable Public Group Type
	*/
	static final String PBTYPEREGULAR = 'Regular';
	
	/*
	* @author Global Desktop (DEPRECATED La asignación de PermissionSets ahora se realiza por SAML)
	*/
  /* public void ambitPermissionCall(List<User> newList, Map<Id,User> mapOld, Boolean isInsert) {
    if(isInsert) {
      ambitAssignPermission(JSON.serialize(newList),null, JSON.serialize(MAPAMBIT));
    } else {
      ambitAssignPermission(JSON.serialize(newList),JSON.serialize(mapOld), JSON.serialize(MAPAMBIT));
    }
  } */

  public void completeLogicValidate(List<User> newList) {
    for(User usr : newList) {
      usr.DES_ARCE_Can_Propose__c = MAPAMBIT.get(usr.gf_user_operation_ambit_name__c) == null ? false : MAPAMBIT.get(usr.gf_user_operation_ambit_name__c).canPropose__c;
      usr.DES_ARCE_Can_Validate__c = MAPAMBIT.get(usr.gf_user_operation_ambit_name__c) == null ? false : MAPAMBIT.get(usr.gf_user_operation_ambit_name__c).canValidate__c;
      usr.DES_ARCE_Can_Edit__c = MAPAMBIT.get(usr.gf_user_operation_ambit_name__c) == null ? false : MAPAMBIT.get(usr.gf_user_operation_ambit_name__c).canEdit__c;
    }
  }

  /*
	* @author Global Desktop (DEPRECATED La asignación de PermissionSets ahora se realiza por SAML)
	*/
  /* @future
  public static void ambitAssignPermission(String newListText, String mapOldText, String mapAmbitMetadataText) {
    List<User> newList = (List<User>) JSON.deserialize(newListText, List<User>.class);
    Map<String, Arce_ambit_hierarchy__mdt> mapAmbitMetadata = (Map<String, Arce_ambit_hierarchy__mdt>) JSON.deserialize(mapAmbitMetadataText, Map<String, Arce_ambit_hierarchy__mdt>.class);

    final List <PermissionSet> psList = new List<PermissionSet>([
      SELECT Id, Name
      FROM PermissionSet
      WHERE name like '%Arc_Gen_Creation%' or name = 'Arce_Corporate_Admin' order by name
    ]);
    system.debug('*** mapAmbitMetadata -> ' + JSON.serialize(mapAmbitMetadata));
    system.debug('*** mapAmbitMetadata size -> ' + mapAmbitMetadata.size());

    final String idMod = psList.get(0).Name.contains('Modification') ? psList.get(0).Id : psList.get(1).Id;
    final String idRead = psList.get(0).Name.contains('Modification') ? psList.get(1).Id : psList.get(0).Id;
    final String idCorpo = psList.get(2).Id;
    final List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
    final List<PermissionSetAssignment> listToDelete = new List<PermissionSetAssignment>();

    //Insert
    if(mapOldText == null) {
      system.debug('*** Insertttttt -> ');
      for(User usr : newList) {
        if(mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c) != null && mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c).canRead__c) {
          permissionSetList.add(new PermissionSetAssignment(PermissionSetId = idRead, AssigneeId = usr.Id));
          //permissionSetList.add(new PermissionSetAssignment(PermissionSetId = idCorpo, AssigneeId = usr.Id));
        }
        if(mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c) != null && mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c).canEdit__c) {
          permissionSetList.add(new PermissionSetAssignment(PermissionSetId = idMod, AssigneeId = usr.Id));
          //permissionSetList.add(new PermissionSetAssignment(PermissionSetId = idCorpo, AssigneeId = usr.Id));
        }
        permissionSetList.add(new PermissionSetAssignment(PermissionSetId = idCorpo, AssigneeId = usr.Id));
      }
    } else {
      system.debug('*** Updateee -> ');
      Map<Id,User> mapOld = (Map<Id,User>) JSON.deserialize(mapOldText, Map<Id,User>.class);
      final Map<String, PermissionSetAssignment> mapPSet = gtCurrentAssignment(idMod, idRead, idCorpo, mapOld);
      system.debug('*** mapPSet -> ' + JSON.serialize(mapPSet));
      for(User usr : newList) {
        if(usr.IsActive && usr.gf_user_operation_ambit_name__c == 'NA') {
          listToDelete.add(mapPSet.get(usr.Id + '-' + idRead));
          listToDelete.add(mapPSet.get(usr.Id + '-' + idMod));
          listToDelete.add(mapPSet.get(usr.Id + '-' + idCorpo));
        } else {
          if(usr.IsActive && mapPSet.get(usr.Id + '-' + idRead) == null && mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c) != null && mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c).canRead__c) {
            system.debug('*** lectura -> ');
            permissionSetList.add(new PermissionSetAssignment(PermissionSetId = idRead, AssigneeId = usr.Id));
          } else if(mapPSet.get(usr.Id + '-' + idRead) != null && (mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c) == null || (mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c) != null && !mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c).canRead__c))) {
            listToDelete.add(mapPSet.get(usr.Id + '-' + idRead));
          }
          if(usr.IsActive && mapPSet.get(usr.Id + '-' + idMod) == null && mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c) != null && mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c).canEdit__c) {
            system.debug('*** modif -> ');
            permissionSetList.add(new PermissionSetAssignment(PermissionSetId = idMod, AssigneeId = usr.Id));
          } else if(mapPSet.get(usr.Id + '-' + idMod) != null && (mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c) == null || (mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c) != null && !mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c).canEdit__c))) {
            listToDelete.add(mapPSet.get(usr.Id + '-' + idMod));
          }
          if(usr.IsActive && mapPSet.get(usr.Id + '-' + idCorpo) == null && mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c) != null) {
            system.debug('*** modif -> ');
            permissionSetList.add(new PermissionSetAssignment(PermissionSetId = idCorpo, AssigneeId = usr.Id));
          } else if(mapPSet.get(usr.Id + '-' + idCorpo) != null && (mapAmbitMetadata.get(usr.gf_user_operation_ambit_name__c) == null )) {
            listToDelete.add(mapPSet.get(usr.Id + '-' + idCorpo));
          }
        }
      }
    }

    system.debug('*** listToDelete -> ' + JSON.serialize(listToDelete));
    if(!listToDelete.isEmpty()) {
      delete listToDelete;
    }

    system.debug('*** permissionSetList -> ' + JSON.serialize(permissionSetList));
    if(!permissionSetList.isEmpty()) {
      insert permissionSetList;
    }
  }*/


  /*
	* @author Global Desktop (DEPRECATED La asignación de PermissionSets ahora se realiza por SAML)
	*/
  /*public void pricewisePermissionCall(List<User> newList, Map<Id,User> mapOld, Boolean isInsert) {
    if(isInsert) {
      pricewisePermission(JSON.serialize(newList),null);
    } else {
      pricewisePermission(JSON.serialize(newList),JSON.serialize(mapOld));
    }
  }*/

  /*
	* @author Global Desktop (DEPRECATED La asignación de PermissionSets ahora se realiza por SAML)
	*/
  /*@future
  public static void pricewisePermission(String newListText, String mapOldText) {
    final List<User> newList = (List<User>) JSON.deserialize(newListText, List<User>.class);
    final List <PermissionSet> psList = new List<PermissionSet>([
      SELECT Id, Name
      FROM PermissionSet
      WHERE name = 'Pricewise_Available'
    ]);
    system.debug('*** psList -> ' + psList);

    final List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
    final List<PermissionSetAssignment> listToDelete = new List<PermissionSetAssignment>();

    if(mapOldText == null) {
      system.debug('*** Insert Pricewise -> ');
      for(User usr : newList) {
        if(usr.gf_pricing_gtb_type__c == true) {
          permissionSetList.add(new PermissionSetAssignment(PermissionSetId = psList.get(0).Id, AssigneeId = usr.Id));
        }
      }
    } else {
      system.debug('*** Update Pricewise -> ');
      final Map<String, PermissionSetAssignment> usersAssigned = gtAssignment(psList.get(0).Id, newList);
      for(User usr : newList) {
        if(usr.gf_pricing_gtb_type__c == true && !usersAssigned.keySet().contains(usr.Id)) {
          permissionSetList.add(new PermissionSetAssignment(PermissionSetId = psList.get(0).Id, AssigneeId = usr.Id));
        } else if(usr.gf_pricing_gtb_type__c == false && usersAssigned.keySet().contains(usr.Id)) {
          listToDelete.add(usersAssigned.get(usr.Id));
        }
      }
    }

    system.debug('*** listToDelete Pricewise -> ' + JSON.serialize(listToDelete));
    checkInsertDelete(listToDelete, false);

    system.debug('*** permissionSetList Pricewise -> ' + JSON.serialize(permissionSetList));
    checkInsertDelete(permissionSetList, true);

  }*/

  /*
	* @author Global Desktop
	*/
  private static Map<String, Arce_ambit_hierarchy__mdt> gtAmbitMetadata() {
    final List<Arce_ambit_hierarchy__mdt> ambitMetadatas = new List<Arce_ambit_hierarchy__mdt>([
      SELECT Id, DeveloperName, Action__c, Ambit__c, Description__c, Level__c, Region__c, Selectables__c, canRead__c, canEdit__c, canPropose__c, canValidate__c
      FROM Arce_ambit_hierarchy__mdt
    ]);
    final Map<String, Arce_ambit_hierarchy__mdt> mapAmbitMetadata = new Map<String, Arce_ambit_hierarchy__mdt>();
    for(Arce_ambit_hierarchy__mdt ambit : ambitMetadatas) {
      final String key = ambit.Region__c + ' - ' + ambit.Level__c + (ambit.Description__c == null || ambit.Description__c == '' ? ' -' : ' - ' + ambit.Description__c);
      if(!mapAmbitMetadata.containsKey(key)) {
        mapAmbitMetadata.put(key, ambit);
      }
    }
    return mapAmbitMetadata;
  }

  /*
	* @author Global Desktop (DEPRECATED La asignación de PermissionSets ahora se realiza por SAML)
	*/
  /*private static Map<String, PermissionSetAssignment> gtCurrentAssignment(String idMod, String idRead, String idCorpo, Map<Id, User> mapOld) {
    final List<PermissionSetAssignment> currentAssignments = new List <PermissionSetAssignment>([
      SELECT Id, PermissionSetId, AssigneeId
      FROM PermissionSetAssignment
      WHERE (PermissionSetId = :idMod OR PermissionSetId = :idRead OR PermissionSetId = :idCorpo) AND AssigneeId IN :mapOld.keySet()
    ]);
    final Map<String, PermissionSetAssignment> mapPSet = new Map<String, PermissionSetAssignment>();
    for(PermissionSetAssignment current : currentAssignments) {
      if(current.PermissionSetId == idMod && !mapPSet.containsKey(current.AssigneeId + '-' + idMod)) {
        mapPSet.put(current.AssigneeId + '-' + idMod, current);
      } else if(current.PermissionSetId == idRead && !mapPSet.containsKey(current.AssigneeId + '-' + idRead)) {
        mapPSet.put(current.AssigneeId + '-' + idRead, current);
      } else if(current.PermissionSetId == idCorpo && !mapPSet.containsKey(current.AssigneeId + '-' + idCorpo)) {
        mapPSet.put(current.AssigneeId + '-' + idCorpo, current);
      }
    }
    return mapPSet;
  }*/

  /*
  * @author Global Hub
  * @Description Method to add or delete elements (DEPRECATED La asignación de PermissionSets ahora se realiza por SAML)
  */
  /*private static void checkInsertDelete(List<PermissionSetAssignment> psAssignment, Boolean isInsert) {
    if(!psAssignment.isEmpty() && isInsert == true) {
      insert psAssignment;
    } else if(!psAssignment.isEmpty() && isInsert == false) {
      delete psAssignment;
    }
  }*/

  /*
  * @author Global Hub
  * @Description Method to get Map with curren assignment (DEPRECATED La asignación de PermissionSets ahora se realiza por SAML)
  */
  /*private static Map<String, PermissionSetAssignment> gtAssignment(String psSetId, List<User> newList) {
    final List<PermissionSetAssignment> currentAssign = new List <PermissionSetAssignment>([
      SELECT Id, PermissionSetId, AssigneeId
      FROM PermissionSetAssignment
      WHERE PermissionSetId = :psSetId AND AssigneeId IN :newList
    ]);
    final Map<String, PermissionSetAssignment> usersAssigned = new Map<String, PermissionSetAssignment>();
    for(PermissionSetAssignment current : currentAssign) {
      usersAssigned.put(current.AssigneeId, current);
    }
    return usersAssigned;
  }*/

   /*********************************************************************************************************
   * @name            validateMexUser
   * @author          Capgemini
   * @created         27/11/2024
   * @description     Metodo futuro que añade o elimina usuarios del PublicGroup que permite ver clientes de Mexico
   * @param           Set<Id> usersIds
   * @param           Boolean toCreateMember
   * @return          N/A
   **********************************************************************************************************/

  @future
  public static void validateMexUserFuture(Set<Id> usersIds, Boolean toCreateMember){
      validateMexUser(usersIds, toCreateMember);
  }

   /*********************************************************************************************************
   * @name            validateMexUser
   * @author          Capgemini
   * @created         27/11/2024
   * @description     Metodo que añade o elimina usuarios del PublicGroup que permite ver clientes de Mexico
   * @param           Set<Id> usersIds
   * @param           Boolean toCreateMember
   * @return          N/A
   **********************************************************************************************************/

  public static void validateMexUser(Set<Id> usersIds, Boolean toCreateMember){
    Group ctmMex = new Group();
    ctmMex = [SELECT Id, Type, DeveloperName FROM Group WHERE Type =: PBTYPEREGULAR AND DeveloperName =: PBMEXICO];
    if(toCreateMember){
      List<groupMember> groupMembersToInsert = new List<groupMember>();
      for(Id userId : usersIds){
        groupMember groupMemberToInsert = new groupMember();
        groupMemberToInsert.groupId = ctmMex.Id;
        groupMemberToInsert.UserOrGroupId = userId;
        groupMembersToInsert.add(groupMemberToInsert);
      }
      if(!groupMembersToInsert.isEmpty()){
        insert groupMembersToInsert;
      }
    }
    else{
      List<groupMember> groupMembersToDelete = new List<groupMember>();
      groupMembersToDelete = [SELECT Id, UserOrGroupId FROM groupMember WHERE GroupId =: ctmMex.Id AND UserOrGroupId IN: usersIds];
      if(!groupMembersToDelete.isEmpty()){
        delete groupMembersToDelete;
      }
    }
  }

  /**
  * @description this method create Appprovers members for user if already exist Approver members added with the same uos that user have.
  * This method call queueable classes to dml actions over GM and ApproverMembers
  * @author BBVA DMT | 24-01-2025 
  * @param newList 
  * @param mapOldUsers 
  **/
  public void assignUserUosToDmtApprover(Map<Id,User> oldUserMap, Map<Id,User> newUsersMap) {
    DES_UOS_Utils uosUtilClass = new DES_UOS_Utils();
    List<GroupMember> groupMemberToDelete = new List<GroupMember> ();

    List<DMT_Approver_Member__c> newApproversMember = new List<DMT_Approver_Member__c>();
    List<GroupMember> newGroupMemberList = new List<GroupMember>();
    Map<String, Set<Id>> mapApproverByUosCode = new Map<String,Set<Id>>();                                //Map for get Approver Ids by Uos code, One Uos code can be associate with more than one Approver
    Map<Id, DMT_Approver_Member__c> mapApproverMemberByApproverId = new Map<Id, DMT_Approver_Member__c>();//Map for get ApproverMember info by Approver Id
    Set<String> approversGroupNames = new Set<String>();                                                  //Set for find all queues names for approvers
    Map<String,Group> queuesApproverByDeveloperName = new Map<String,Group>();                            //Map for get queues info by DeveloperName
    Map<Id, Set<Id>> approverToUserIds = new Map<Id, Set<Id>>();                                          //Map for get userIds by approverId, used to check if user is already approver member of approver
    Set<Id> usersToProcess = new Set<Id>();
    Map<Id, String> filteredMapUosUser = new Map<Id, String>();

    Map<Id,String> mapUosUser = uosUtilClass.indentifyUserUos(newUsersMap.values());

    if(oldUserMap == null || oldUserMap.isEmpty()){
        usersToProcess.addAll(mapUosUser.keySet());
    } else {
        // get old UOS map once
        Map<Id,String> mapUosUserOld = uosUtilClass.indentifyUserUos(oldUserMap.values());
        for(Id uid : mapUosUser.keySet()){
            String newUos = mapUosUser.get(uid);
            String oldUos = mapUosUserOld.get(uid);
            if(newUos == null && oldUos == null){ continue; }
            if((newUos != null || oldUos != null) && !newUos.equals(oldUos)){
                usersToProcess.add(uid);
                filteredMapUosUser.put(uid, mapUosUser.get(uid));
            }
        }
        if(usersToProcess.isEmpty()){
            System.debug('No users with UOS changes to process.');
        }
    }

    if(oldUserMap != null && !oldUserMap.isEmpty()){
      System.debug('**** Es un update de user ****');
      groupMemberToDelete = uosDeleteApproveMember(oldUserMap,mapUosUser);
    }

    if(usersToProcess.isEmpty()){
      return;
    }

    // Load approver members by UOS using the filtered map
    List<DMT_Approver_Member__c> approverMemberUos = loadApproverMembersByUos(filteredMapUosUser.values());
    buildApproverMaps(approverMemberUos, mapApproverByUosCode, mapApproverMemberByApproverId, approverToUserIds, approversGroupNames);
    
    //Generate map of queues by developer name for assign group members
    queuesApproverByDeveloperName = loadQueuesByDeveloperName(approversGroupNames);
      System.debug('** Usuarios a procesar: '+usersToProcess);
      for(Id userId : usersToProcess ){
        Set<Id> approversIdsSet = mapApproverByUosCode.get(mapUosUser.get(userId));
        if(approversIdsSet != null ){
          for (Id approverId : approversIdsSet) {
            //check user is allready approver member from approver for prevent create it
            if(approverToUserIds.containsKey(approverId) && approverToUserIds.get(approverId).contains(userId)){
              System.debug('**** El usuario '+userId+' ya es approver member del approver '+approverId+' , no se crea de nuevo');
            }else{
              System.debug('**** El usuario '+userId+' NO es approver member del approver '+approverId+' , se crea uno nuevo');
              DMT_Approver_Member__c newApproverMember = new DMT_Approver_Member__c();
              newApproverMember.Name = newUsersMap.get(userId).FirstName + ' ' +newUsersMap.get(userId).LastName ;
              newApproverMember.DMT_Approver__c = approverId;
              newApproverMember.DMT_User__c = userId;
              newApproverMember.DMT_Access_Level__c = mapApproverMemberByApproverId.get(approverId).DMT_Access_Level__c;
              newApproverMember.DMT_Is_Active__c = false;
              newApproverMember.DMT_FieldsHistoryView__c = mapApproverMemberByApproverId.get(approverId).DMT_FieldsHistoryView__c;
              newApproverMember.DMT_ApproverByUOs__c = mapUosUser.get(userId);

              newApproversMember.add(newApproverMember);
            }
              if(queuesApproverByDeveloperName?.get(mapApproverMemberByApproverId.get(approverId).DMT_Approver__r.DMT_Group__c) != null){
                GroupMember groupMember = new GroupMember();
                groupMember.UserOrGroupId = userId;
                groupMember.GroupId =queuesApproverByDeveloperName.get(mapApproverMemberByApproverId.get(approverId).DMT_Approver__r.DMT_Group__c).Id;
                newGroupMemberList.add(groupMember);
              }
          }
        }
      }

      System.debug('Se crearian estos approver '+newApproversMember);
      System.debug('Se crearian estos GroupMembers '+newGroupMemberList);

      // delete duplicates between insert and delete lists
      clearGroupMembersAgainstDeletes(newGroupMemberList, groupMemberToDelete);

       // enqueue actions DML (Queueables)
      enqueueApproverAndGroupMemberJobs(newApproversMember, newGroupMemberList, groupMemberToDelete);
    
  }

  /**
  * @description this method load ApproverMembers by Uos codes
  * @author BBVA DMT | 03-12-2025 
  * @param uosCodes 
  * @return List<DMT_Approver_Member__c> 
  **/
  private static List<DMT_Approver_Member__c> loadApproverMembersByUos(List<String> uosCodes){
    if(uosCodes == null || uosCodes.isEmpty()){
      return new List<DMT_Approver_Member__c>();
    } 
    Set<String> uosCodesSet = new Set<String>(uosCodes);
    if (!Schema.sObjectType.DMT_Approver_Member__c.isAccessible()) {
        throw new System.SecurityException('Insufficient permissions to access DMT_Approver_Member__c object.');
    }
    return [SELECT Id,createdDate,Name,DMT_Approver__c,DMT_Access_Level__c,DMT_FieldsHistoryView__c,DMT_ApproverByUOs__c,DMT_User__c,DMT_Approver__r.DMT_Group__c
            FROM DMT_Approver_Member__c 
            WHERE DMT_ApproverByUOs__c IN :uosCodesSet];
  }

  /**
  * @description this method clear duplicates between inserts and deletes GroupMembers lists
  * @author BBVA DMT | 03-12-2025 
  * @param inserts 
  * @param deletes 
  **/
  private static void clearGroupMembersAgainstDeletes(List<GroupMember> inserts, List<GroupMember> deletes){
    if(inserts == null || deletes == null){
      return;
    }
    List<GroupMember> toRemoveFromInserts = new List<GroupMember>();
    List<GroupMember> toRemoveFromDeletes = new List<GroupMember>();

    for(GroupMember membInsert : inserts){
      for(GroupMember membDelete : deletes){
        if(membInsert.GroupId == membDelete.GroupId && membInsert.UserOrGroupId == membDelete.UserOrGroupId){
          toRemoveFromInserts.add(membInsert);
          toRemoveFromDeletes.add(membDelete);
          break;
        }
      }
    }
    for(GroupMember g : toRemoveFromInserts){
      inserts.remove(inserts.indexOf(g));
    }
    for(GroupMember g : toRemoveFromDeletes){
      deletes.remove(deletes.indexOf(g));
    } 
  }

  /**
  * @description  this method build maps for approvers members processing
  * @author BBVA DMT | 03-12-2025 
  * @param approverMemberUos 
  * @param mapApproverByUosCode 
  * @param mapApproverMemberByApproverId 
  * @param approverToUserIds 
  * @param approversGroupNames 
  **/
  private static void buildApproverMaps(List<DMT_Approver_Member__c> approverMemberUos,Map<String, Set<Id>> mapApproverByUosCode,Map<Id, DMT_Approver_Member__c> mapApproverMemberByApproverId,Map<Id, Set<Id>> approverToUserIds,Set<String> approversGroupNames) {
    if(approverMemberUos == null){
      return;
    } 
    for(DMT_Approver_Member__c apm : approverMemberUos){
      approversGroupNames.add(apm.DMT_Approver__r.DMT_Group__c);
      if(mapApproverByUosCode.containsKey(apm.DMT_ApproverByUOs__c)){
        mapApproverByUosCode.get(apm.DMT_ApproverByUOs__c).add(apm.DMT_Approver__c);
      } else {
        mapApproverByUosCode.put(apm.DMT_ApproverByUOs__c, new Set<Id>{apm.DMT_Approver__c});
      }
      mapApproverMemberByApproverId.put(apm.DMT_Approver__c, apm);

      if(apm.DMT_Approver__c != null){
        if(!approverToUserIds.containsKey(apm.DMT_Approver__c)){
          approverToUserIds.put(apm.DMT_Approver__c, new Set<Id>{apm.DMT_User__c});
        } else if(apm.DMT_User__c != null){
          approverToUserIds.get(apm.DMT_Approver__c).add(apm.DMT_User__c);
        }
      }
    }
  }

  private static Map<String, Group> loadQueuesByDeveloperName(Set<String> devNames){
    if(devNames == null || devNames.isEmpty()){
       return new Map<String,Group>();
    }
    if (!Schema.sObjectType.Group.isAccessible()) {
        throw new System.SecurityException('Insufficient permissions to access Group object.');
    }
    Map<Id,Group> queuesApproverById = new Map<Id,Group>([SELECT DeveloperName, Id, Name, RelatedId, Type FROM Group WHERE DeveloperName IN :devNames ]);
    Map<String,Group> result = new Map<String,Group>();
    for(Group g : queuesApproverById.values()){
      result.put(g.DeveloperName, g);
    }
    return result;
  }

  private static void enqueueApproverAndGroupMemberJobs(List<DMT_Approver_Member__c> newApproversMember,List<GroupMember> newGroupMemberList,List<GroupMember> groupMemberToDelete){
    if(newApproversMember != null && !newApproversMember.isEmpty()){
      System.enqueueJob(new DMT_ApproverMemberQueueableHelper(newApproversMember,'INSERT'));
    }
    if(newGroupMemberList != null && !newGroupMemberList.isEmpty()){
      System.enqueueJob(new DMT_GroupMemberQueueableHelper(newGroupMemberList,'INSERT'));
    }
    if(groupMemberToDelete != null && !groupMemberToDelete.isEmpty()){
      System.enqueueJob(new DMT_GroupMemberQueueableHelper(groupMemberToDelete,'DELETE'));
    }
  }

  /**
  * @description this method  delete ApproverMember y GroupMember cuando un usuario 
  * @author BBVA DMT | 29-01-2025 
  * @param oldUserMap 
  * @param mapUosUser 
  **/
  public static List<GroupMember> uosDeleteApproveMember(Map<Id,User> oldUserMap, Map<Id,String> mapUosUser) {
    DES_UOS_Utils uosUtilClass = new DES_UOS_Utils();
    Set<Id> usersToDeleteApprover = new Set<Id>();
    List<GroupMember> groupMembersToDelete = new List<GroupMember>();

    Set<Id> setIdUsersToDeleteGM = new Set<Id>();
    Set<String> setDeveloperNamesGroups = new Set<String>();

    Map<Id,String> mapUosUserOld = uosUtilClass.indentifyUserUos(oldUserMap.values());

      for(Id userId : mapUosUser.keySet() ){

          if(mapUosUser.get(userId)!= null && mapUosUser.get(userId) != mapUosUserOld.get(userId)){
            usersToDeleteApprover.add(userId);
          }
        }

        List<DMT_Approver_Member__c> approverMemberUosToDelete = [SELECT Id,createdDate,Name,DMT_Approver__c,DMT_Access_Level__c,DMT_FieldsHistoryView__c,DMT_ApproverByUOs__c,DMT_User__c,DMT_Approver__r.DMT_Group__c
            FROM DMT_Approver_Member__c 
            WHERE DMT_ApproverByUOs__c IN :mapUosUserOld.values() AND  DMT_User__c IN :usersToDeleteApprover];

            for(DMT_Approver_Member__c approverMember :approverMemberUosToDelete){
                setIdUsersToDeleteGM.add(approverMember.DMT_User__c);
                setDeveloperNamesGroups.add(approverMember.DMT_Approver__r.DMT_Group__c);      
            }

            if(!setIdUsersToDeleteGM.isEmpty()){
              if (Schema.sObjectType.GroupMember.isAccessible()) {
                  groupMembersToDelete = [SELECT Group.DeveloperName, Group.Name, Id, UserOrGroup.Username FROM GroupMember WHERE UserOrGroupId IN :setIdUsersToDeleteGM AND Group.DeveloperName IN :setDeveloperNamesGroups];
              } else {
                  throw new System.SecurityException('Insufficient permissions to access GroupMember object.');
              }
            }

          if(approverMemberUosToDelete!= null && !approverMemberUosToDelete.isEmpty()){
              System.enqueueJob(new DMT_ApproverMemberQueueableHelper(approverMemberUosToDelete,'DELETE'));
          }
      
          return groupMembersToDelete;

  }
  
  public static void fillUserRoleByProject(User user,  UserUuaaInfoExtended.wrapper wrapper) {

     UserUuaaInfoExtended.wrapper wrapperAux = wrapper;

      //get all fields from User Object
      if(Test.isRunningTest()){
        String response = '{"success":true,"errorMessage":"","data":{"roles":[{"userCode":"1","surname":"test","secondSurname":"test","workCountry":"ES","email":"TEST","organizationalUnit":"test","name":"DMT_Proyecto", "resources":[{"name":"DMT_LineView", "value":"DMT_LineView"},{"name":"DMT_Commercial_Activity_Approval_Require", "value":"DMT_Commercial_Activity_Approval_Require"}]}]}}';
        Object obj = System.JSON.deserialize(response, UserUuaaInfoExtended.Wrapper.class);
        wrapperAux = (UserUuaaInfoExtended.Wrapper)obj;
      }
      List<DES_User_Roles__mdt> desUserRole = [SELECT Id, DES_Role_Developer_Name__c , DES_User_Field_Map__c  FROM DES_User_Roles__mdt];
      
      if(wrapperAux.data.roles != null && !wrapperAux.data.roles.isEmpty()){   
        Boolean roleFound = false;
        String allRoles;
        for(UserUuaaInfoExtended.Role role :wrapperAux.data.roles){
          for(DES_User_Roles__mdt mtdRole : desUserRole){
            if(mtdRole.DES_Role_Developer_Name__c == role.name ){
              allRoles = allRoles == null ? role.name : (allRoles.contains(role.name) ? allRoles : allRoles + ';' + role.name);
              user.put(mtdRole.DES_User_Field_Map__c, allRoles);
              roleFound = true;
            }
          }
        }

      } 
    
  }

}