/*
* Handler del trigger Asset Group
*/
public without sharing class AssetGroupMemberTriggerHandler {

  /*
  * String para comprobar si el RT del NBC es del tipo Virtual
  */
  static final String ECOM = 'E-Commerce-';

  /** instance */
  private static AssetGroupMemberTriggerHandler instance;

  /*
  * getInstance
  */
  public static AssetGroupMemberTriggerHandler getInstance() { //NOSONAR
    if (instance == null) {
        instance = new AssetGroupMemberTriggerHandler();
      }
      return instance;
  }

  /*
  * Met0d0 para pasar sonar
  */
  private AssetGroupMemberTriggerHandler() {}

  /*
  * Insert member
  */
  public static void newGroupMember(Map<Id, Asset_Group_Member__c> mMembers) {
    newGroupMemberFuture(mMembers.keySet());
  }

  /*
  * Insert member
  */
  @future
  public static void newGroupMemberFuture(Set<Id> lIDMembers) {
    final List<Asset_Group_Member__c> lMembers = [SELECT id, E_Commerce_Group__c, E_Commerce_Group__r.Name, User__c FROM Asset_Group_Member__c WHERE id IN :lIDMembers];
    System.debug('lMembers ' + lMembers);
    final List<String> lGroupNames = getGroupsName(lMembers);
    System.debug('lGroupNames ' + lGroupNames);
    final Map<String, String> mGroup = getMapGroup(lGroupNames);
    System.debug('mGroup ' + mGroup);

    List<GroupMember> lgMember;
    lgMember = new List<GroupMember>();
    GroupMember gMember;

    for(Asset_Group_Member__c groupMember : lMembers) {
      gMember = new GroupMember();
      gMember.GroupId = mGroup.get(ECOM+groupMember.E_Commerce_Group__r.Name);
      gMember.UserOrGroupId = groupMember.User__c;
      lgMember.add(gMember);
    }

    insert lgMember;
  }

  /*
  * Delete member
  */
  public static void deleteGroupMember(List<Asset_Group_Member__c> lMembers) {
    List<String> lDelete;
    lDelete = new List<String>();
    for(Asset_Group_Member__c groupMember : lMembers) {
      lDelete.add(groupMember.E_Commerce_Group__c+'::'+groupMember.User__c);
    }
    deleteGroupMemberFuture(lDelete);
  }

  /*
  * Delete member
  */
  @future
  public static void deleteGroupMemberFuture(List<String> lMembers) {

    List<String> lGroupIDs;
    lGroupIDs = new List<String>();

    for(String groupMember : lMembers) {
      lGroupIDs.add(groupMember.split('::').get(0));
    }
    final Map<Id, Asset_Group__c> mGroupNames = new Map<Id, Asset_Group__c>([SELECT id, Name FROM Asset_Group__c WHERE ID IN :lGroupIDs]);


    List<String> lGroupNames;
    lGroupNames = new List<String>();
    List<String> lUserId;
    lUserId = new List<String>();
    List<String> lDelete;
    lDelete = new List<String>();
    for(String groupMember : lMembers) {
      lGroupNames.add(ECOM+mGroupNames.get(groupMember.split('::').get(0)).Name);
      lUserId.add(groupMember.split('::').get(1));
      lDelete.add(ECOM+mGroupNames.get(groupMember.split('::').get(0)).Name+'::'+groupMember.split('::').get(1));
    }

    System.debug('lDelete ' + lDelete);

    List<GroupMember> lMemberDelete;
    lMemberDelete = new List<GroupMember>();
    String sCompare;
    for(GroupMember gMember : [SELECT id, GroupId, Group.Name, UserOrGroupId FROM GroupMember WHERE Group.Name IN :lGroupNames AND UserOrGroupId IN :lUserId]) {
      sCompare = gMember.Group.Name+'::'+gMember.UserOrGroupId;
      System.debug('sCompare ' + sCompare);
      if(lDelete.contains(sCompare)) {
        lMemberDelete.add(gMember);
      }
    }

    System.debug('lMemberDelete ' + lMemberDelete);

    delete lMemberDelete;
  }


  private static Map<String, String> getMapGroup(List<String> lGroupNames) {
    Map<String, String> mGroup;
    mGroup = new Map<String, String> ();
    for(Group gName : [SELECT id,Name FROM Group WHERE Name IN :lGroupNames]) {
      mGroup.put(gName.Name, gName.id);
    }
    return mGroup;
  }

  private static List<String> getGroupsName(List<Asset_Group_Member__c> lMembers) {
    List<String> lGroupNames;
    lGroupNames = new List<String>();
    for(Asset_Group_Member__c assMember : lMembers) {
      lGroupNames.add(ECOM+assMember.E_Commerce_Group__r.Name);
    }
    return lGroupNames;
  }
}