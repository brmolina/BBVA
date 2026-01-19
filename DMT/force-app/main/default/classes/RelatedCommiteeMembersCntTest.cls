/**
   Name:            RelatedCommiteeMembersCntTest
   Test Class:      RelatedCommiteeMembersCnt
 */
@isTest
public class RelatedCommiteeMembersCntTest {
  /*
  * Test method
  */
  @isTest
  public static void gtMembersTest() {
    final List<Group> groups = new List<Group>([SELECT Id from Group Where DeveloperName = 'Virtual_NBC_Commitee_Team' LIMIT 1]);
    final GroupMember member = new GroupMember();
    member.GroupId = groups.get(0).Id;
    member.UserOrGroupId = UserInfo.getUserId();
    insert member;
    final RelatedCommiteeMembersCnt controller = RelatedCommiteeMembersCnt.gtInstance();
    system.debug('controller -> ' + controller);
    final String members = RelatedCommiteeMembersCnt.gtMembers();
    system.assert(members.contains(UserInfo.getUserId()), 'not0');
  }
}