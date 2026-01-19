/**
*
* @author Global Desktop
*/
@isTest
public class DES_IpVisitController_Test {

    /*
   * Test method for instance function
  */
    @isTest
    public static void testInstance() {
        final DES_IpVisitController instance = DES_IpVisitController.Instance();
        system.assertNotEquals(null, instance, 'msg');
    }

    /*
   * Test method for bbvaUserCode function
  */
    @isTest
    public static void testBBVAUserCode() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        String fedId;
        system.runAs(user1) {
            fedId = DES_IpVisitController.bbvaUserCode();
        }
        final User user2 = [SELECT FederationIdentifier FROM User WHERE Id=:user1.id Limit 1];
        system.assertEquals(user2.FederationIdentifier, fedId, 'bbvaCode');
    }


    /*
   * Test method for getObjectType function
  */
    @isTest
    public static void getObjectType() {
        String fields = '';
        fields = DES_IpVisitController.getObjectType('dwp_kitv__Visit__c');
        system.assertNotEquals('', fields,'fields');
    }

    /*
   * Test method for getObjectType function
  */
    @isTest
    public static void getObjectTypeError() {
        try {
            final String fields1 = DES_IpVisitController.getObjectType('Test');
            system.assertEquals(null, fields1, 'null');
        } catch(Exception e) {
            system.debug(e.getMessage());
        }
    }

    /*
   * Test method for getRecordTypeId function
  */
    @isTest
    public static void getRecordTypeId() {
        final String rtId = DES_IpVisitController.getRecordTypeId(Label.DES_RT_Inside_Visit);
        system.assertNotEquals(null, rtId, 'Not null');
    }

    /*
   * Test method for getRecordTypeId function
  */
    @isTest
    public static void getRecordTypeIdError() {
        try {
            final String rtId1 = DES_IpVisitController.getRecordTypeId('Test');
            system.assertEquals(null, rtId1, 'Null');
        } catch(Exception e) {
            system.debug(e.getMessage());
        }
    }

    /**
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
            final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
            insert visit;
            final dwp_kitv__Visit_Management_Team__c visitMember = utilClass.createVisitManagementTeam(visit, user1);
            insert visitMember;
            final boolean isVisible = DES_IpVisitController.isVisible(visit.Id);
            System.assert((false == isVisible), 'isVisible does not equal false');
        }
    }

    /**
    * Test method for OppMember functions
    */
    @isTest
    public static void validateFormMemberDeletion() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        insert user1;
        dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
    	visit.disclosure_info_type__c = Label.DES_OP_Inside;
    	insert visit;
        dwp_kitv__Visit_Management_Team__c visitMember = utilClass.createVisitTM(user1, visit);
        insert visitMember;

        Global_Desktop_Settings__c gdSettings = new Global_Desktop_Settings__c();
        gdSettings.URL_Lightning__c = 'testURL';
        insert gdSettings;
        //creo event tracker para ese usuario
        etrk__EventTracker_Event__c evnTracker = new etrk__EventTracker_Event__c();
        evnTracker.etrk__User__c = user1.Id;
        evnTracker.etrk__Event_Name__c = 'Inside_Information_Form_Open';
        evnTracker.etrk__Location__c = gdSettings.URL_Lightning__c + 'lightning/r/dwp_kitv__Visit__c/' + visit.Id + '/view';
        evnTracker.etrk__Type__c = 'LocationChange';
        insert evnTracker;

        Boolean retrnEventT = DES_IpFormContactController.checkEventTracker(visit.Id, visitMember.Id);

        system.assertNotEquals(null, evnTracker.Id);
    }

}