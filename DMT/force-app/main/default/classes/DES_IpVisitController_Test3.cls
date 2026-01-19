/**
*
* @author Global Desktop
*/
@isTest
public class DES_IpVisitController_Test3 {
    /*
   * Test method for delRecordTeamMember function
   */
    @isTest
    public static void isOwner() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        Boolean isOwner;
        System.runAs(user1) {
            final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
            insert visit;
            isOwner = DES_IpVisitController.isOwner(visit.Id);
        }

        System.assert((false == isOwner), 'isOwner does not equal false');
    }

 	/*
   * Test method for delRecordTeamMember function
   */
    @isTest
    public static void delRecordTeamMember() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
        insert visit;
        final dwp_kitv__Visit_Management_Team__c visitMember = utilClass.createVisitManagementTeam(visit, user1);
        visitMember.dwp_kitv__user_id__c = user1.Id;
        insert visitMember;

        Test.startTest();

        final Inside_information_form__c form = new Inside_information_form__c();
        form.visit_id__c = visit.Id;
        insert form;
        final Compliance_form_contact__c formContact = new Compliance_form_contact__c();
        formContact.Formulario__c = form.Id;
        formContact.user_id__c = user1.Id;
        insert formContact;
        try {
            DES_IpVisitController.delRecord(visitMember.Id,visit.Id);
        } catch(Exception e) {
            System.debug(e.getLineNumber() + ': ' + e.getMessage());
        }
        final List <dwp_kitv__Visit_Management_Team__c> visitMembers = new List<dwp_kitv__Visit_Management_Team__c>([
            SELECT id
            FROM dwp_kitv__Visit_Management_Team__c
            WHERE id = : visitMember.Id
        ]);
        final boolean empty = visitMembers.isEmpty();
        system.assert((true == empty), 'empty does not equal false');
        Test.stopTest();
    }

     	/*
   * Test method for delVisitTopic function
   */
    @isTest
    public static void delVisitTopic() {
       final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
        insert visit;
        final dwp_kitv__Visit_Topic__c visitTopic = utilClass.createVisitTopic(visit, opp);
        insert visitTopic;
        DES_IpVisitController.delVisitTopic(visitTopic.Id);
        final List <dwp_kitv__Visit_Topic__c> visitTopics = new List<dwp_kitv__Visit_Topic__c>([
            SELECT id
            FROM dwp_kitv__Visit_Topic__c
            WHERE id = : visitTopic.Id
        ]);
        final boolean empty = visitTopics.isEmpty();
        system.assert(empty, 'delete');
    }



   /*
   * Test method for delRecordTeamMember function
   */
    @isTest
    public static void delContactRecord() {
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
        Test.startTest();
        DES_IpVisitController.delContactRecord(visitContact.Id);
        final List <dwp_kitv__Visit_Contact__c> visitContacts = new List<dwp_kitv__Visit_Contact__c>([
            SELECT id
            FROM dwp_kitv__Visit_Contact__c
            WHERE id = : visitContact.Id
        ]);
        Test.stopTest();
        final boolean empty = visitContacts.isEmpty();
        system.assert(empty, 'delete');
    }

    /*
    * @author Global Desktop
    * @Description sessionIdTest
    */
    @isTest
    public static void sessionIdTest() {
        final String session = DES_IpVisitController.sessionId();
        system.assertNotEquals(null, session, 'session');
    }

    /*
    * @author Global Desktop
    * @Description sessionIdTest
    */
    @isTest
    public static void isCloseTest() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final String session = DES_IpVisitController.urlIpServices(); //NOSONAR
        final Account acc = utilClass.createClient();
        insert acc;
        final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
        insert visit;
        final Boolean isClose = DES_IpVisitController.isVisitClosed(visit.Id);
        system.assert(!isClose, 'visit');
    }
}