/**
*
* @author Global Desktop
*/
@isTest
public class DES_IpOppController_test2 {
/*
   * Test method for isVisible function
  */
    @isTest
    public static void isVisible() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;

        system.runAs(user1) {
            final Opportunity opp = utilClass.createOpportunity(acc);
            insert opp;
            final DES_Opportunity_Management_member__c oppMember = utilClass.createOppManagementMember(user1, opp);
            insert oppMember;
            final boolean isVisible = DES_IpOppController.isVisible(opp.Id);
            system.assert(isVisible, 'true');
        }
    }

    /*
   * Test method for oppMembers function
  */
    @isTest
    public static void oppMembers() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        final DES_Opportunity_Management_member__c oppMember = utilClass.createOppManagementMember(user1, opp);
        insert oppMember;
        final String members = DES_IpOppController.oppMembers(opp.Id);
        system.assertNotEquals(null, members, 'not null');
        }

    /*
   * Test method for delRecord function
   */
    @isTest
    public static void delRecord() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        final DES_Opportunity_Management_member__c oppMember = utilClass.createOppManagementMember(user1, opp);
        insert oppMember;
        final Inside_information_form__c form = new Inside_information_form__c();
        form.opportunity_id__c = opp.Id;
        insert form;
        final Compliance_form_contact__c formContact = new Compliance_form_contact__c();
        formContact.Formulario__c = form.Id;
        formContact.user_id__c = user1.Id;
        insert formContact;
        try {
            DES_IpOppController.delRecord(oppMember.Id, opp.Id);
        } catch(Exception e) {
			System.debug(e.getLineNumber() + ': ' + e.getMessage());
        }
        final List <DES_Opportunity_Management_member__c> oppMembers = new List<DES_Opportunity_Management_member__c>([
            SELECT id
            FROM DES_Opportunity_Management_member__c
            WHERE id = : oppMember.Id
        ]);
        final boolean empty = oppMembers.isEmpty();
        system.assert(empty, 'delete');
    }

    /*
    * @author Global Desktop
    * @Description checkDeletePermissionTest
    */
    @isTest
    public static void checkDeletePermissionTest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final Account acc = utilTestClass.createClient();
        insert acc;
        final Opportunity opp1 = utilTestClass.createOpportunity(acc);
        opp1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_Inside_opp).getRecordTypeId();
        opp1.disclosure_info_type__c = Label.DES_OP_Inside;
        insert opp1;
        try {
            delete opp1;
        } catch (Exception e) {
            system.assertNotEquals(null, opp1.Id, 'Not deleted');
        }
    }

    /*
    * @author Global Desktop
    * @Description sessionIdTest
    */
    @isTest
    public static void sessionIdTest() {
        final String session = DES_IpOppController.sessionId();
        system.assertNotEquals(null, session, 'session');
    }

    /*
   * Test method for oppTopics function
  */
    @isTest
    public static void oppTopics() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, opp);
        insert visit;
        final dwp_kitv__Visit_Topic__c topic = utilClass.createVisitTopic(visit, opp);
        insert topic;
        final String topics = DES_IpOppController.oppTopics(opp.Id);
        system.assertNotEquals(null, topics, 'not null topics');
        }

     /*
   * Test method for isClosed function
  */
    @isTest
    public static void isClosed() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        final Boolean isclose = DES_IpOppController.isOppClosed(opp.Id);
        DES_IpOppController.urlIpServices();
        system.assertEquals(false, isclose, 'not closed');
     }

    /**
     * Test method for oppForms functions
     */
     @isTest
    public static void oppForms() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        final Opportunity opp = utilClass.createOpportunity(acc);
        insert opp;
        final DES_Opportunity_Management_member__c oppMember = utilClass.createOppManagementMember(user1, opp);
        insert oppMember;
        final Inside_information_form__c form = new Inside_information_form__c();
        form.opportunity_id__c = opp.Id;
        insert form;

        final String oppForms = DES_IpOppController.oppForms(opp.Id);
        String oppForms2 = DES_IpOppController.oppForms2(opp.Id,true); //NOSONAR
        oppForms2 = DES_IpOppController.oppForms2(opp.Id,false); //NOSONAR

        system.assertNotEquals(null, oppForms);
     }

    /**
    * Test method for OppMember functions
    */
    @isTest
    public static void validateOppMemberDeletion() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        final Opportunity opp = utilClass.createOpportunity(acc);
        opp.disclosure_info_type__c = Label.DES_OP_Inside;
        insert opp;
        final DES_Opportunity_Management_member__c oppMember = utilClass.createOppManagementMember(user1, opp);
        insert oppMember;
        final Inside_information_form__c form = new Inside_information_form__c();
        form.opportunity_id__c = opp.Id;
        insert form;

        // Compliance_form_contact__c cFContact = new Compliance_form_contact__c();
        // cFContact.user_id__c = user1.Id;
        // cFContact.Formulario__c = form.Id;
        // cFContact.operation_user_assign_date__c = '2019-08-02T12:59:48.000+0000';
        // insert cFContact;

        Global_Desktop_Settings__c gdSettings = new Global_Desktop_Settings__c();
        gdSettings.URL_Lightning__c = 'testURL';
        insert gdSettings;
        //creo event tracker para ese usuario
        etrk__EventTracker_Event__c evnTracker = new etrk__EventTracker_Event__c();
        evnTracker.etrk__User__c = user1.Id;
        evnTracker.etrk__Event_Name__c = 'Opportunity_Open';
        evnTracker.etrk__Location__c = gdSettings.URL_Lightning__c + 'lightning/r/Opportunity/' + opp.Id + '/view';
        evnTracker.etrk__Type__c = 'LocationChange';
        insert evnTracker;

        Boolean retrnEventT = DES_IpOppController.checkEventTracker(opp.Id, oppMember.Id);

        system.assertNotEquals(null, evnTracker.Id);
    }

}