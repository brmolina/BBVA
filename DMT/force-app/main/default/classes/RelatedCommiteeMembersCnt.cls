/**
   Name:            RelatedCommiteeMembersCnt
   Description:     Controller for the component RelatedCommiteeMembers of NBC Virtual
 */
public with sharing class RelatedCommiteeMembersCnt {

  /**
   * SINGLETON PATTERN
   */
  private static RelatedCommiteeMembersCnt instance;

  /**
   * getInstance
   */
  public static RelatedCommiteeMembersCnt gtInstance() {//NOSONAR
    if (instance == null) {
      instance = new RelatedCommiteeMembersCnt();
    }
    return instance;
  }

  /*
  * Private constructor
  */
  private RelatedCommiteeMembersCnt() {

  }

  /*
   * Method to get commitee members
   */
  @AuraEnabled
  public static String gtMembers() {
    try {
      final Set<Id> membersIds = new Set <Id>();
      final List <GroupMember> members = new List <GroupMember>([SELECT id, UserOrGroupId from GroupMember where Group.DeveloperName = 'Virtual_NBC_Commitee_Team']);
      for(GroupMember memb : members) {
        membersIds.add(memb.UserOrGroupId);
      }
      final List <User> users = new List <User>([SELECT Id, Name, Email, Phone, dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c from User where Id IN: membersIds]);
      return JSON.serialize(users);
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }
}