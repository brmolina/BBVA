/**
*
* @author Global Desktop
*/
@isTest
public class DES_IpVisitController_Test2 {
 /*
   * Test method for visitMembers function
  */
    @isTest
    public static void visitMembers() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
        insert visit;
        final dwp_kitv__Visit_Management_Team__c visitMember = utilClass.createVisitManagementTeam(visit, user1);
        insert visitMember;
        final String members = DES_IpVisitController.visitMembers(visit.Id);
        system.assertNotEquals(null, members, 'not null');
        }
 /*
   * Test method for visitTopics function
  */
    @isTest
    public static void visitTopics() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
        insert visit;
        final dwp_kitv__Visit_Topic__c visitTopic = utilClass.createVisitTopic(visit, opp);
        insert visitTopic;
        final String topics = DES_IpVisitController.visitTopics(visit.Id);
        system.assertNotEquals(null, topics, 'not null');
        }
 /*
   * Test method for visitContact function
  */
    @isTest
    public static void visitContact() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final Contact user1 = utilClass.createContact(acc);
        insert user1;
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
        insert visit;
        final dwp_kitv__Visit_Contact__c visitContact = utilClass.visitContact(user1, visit);
        insert visitContact;
        final String contacts = DES_IpVisitController.visitContact(visit.Id);
        system.assertNotEquals(null, contacts, 'not null');
        }

}