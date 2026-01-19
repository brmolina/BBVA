/**
*
* @author Global Desktop
*/
@isTest
private class DES_Ip_HiddenFieldsControllerTest {

    @testSetup
    static void testSetup() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Account acc = utilClass.createClient();
        insert acc;
        final String profile = utilClass.createProfile();
        final User user1 = utilClass.createUser(profile);
        user1.FederationIdentifier = 'test1234';
        insert user1;

        system.runAs(user1) {
            final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, null);
            visit.visit_prvlg_participant_id__c = acc.Id;
            visit.visit_privileged_user_name__c = user1.Id;
            insert visit;
            final dwp_kitv__Visit_Management_Team__c visitMember = utilClass.createVisitManagementTeam(visit, user1);
            insert visitMember;
        }
    }

    @isTest
    static void testGetClientData() {
        final dwp_kitv__Visit__c visit = [SELECT Id FROM dwp_kitv__Visit__c LIMIT 1];
        final DES_Ip_HiddenFieldsController.ClientData cdata = DES_Ip_HiddenFieldsController.getClientData(visit.Id);
        
        System.assertNotEquals(null, cdata.ownerName);
    }

    @isTest
    static void testBBVAUserCode() {
        final User user1 = [SELECT Id,Name, Email FROM User WHERE Email = 'useremail@test.comm' LIMIT 1];
        String fedId;
        system.runAs(user1) {
            fedId = DES_Ip_HiddenFieldsController.bbvaUserCode();
        }

        System.assertNotEquals(null, fedId);
    }

    @isTest
    static void testUrlIpServices() {
        final User user1 = [SELECT Id,Name, Email FROM User WHERE Email = 'useremail@test.comm' LIMIT 1];
        String url;
        system.runAs(user1) {
            url = DES_Ip_HiddenFieldsController.urlIpServices();
        }

        System.assertNotEquals(null, user1);
    }
}