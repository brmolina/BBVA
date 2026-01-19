/*
* Test Class
*/
@isTest
public class Batch_deleteBBVAMembers_Test {

    /*
    * Test method for DES_Batch_Update_ActiveContact
    */
    @isTest
    public static void testBatch() {

        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final User userint = testClass.createUser(userinfo.getProfileId());
        userint.LastName = 'User Integrator';
        insert userint;
        final User usr = [SELECT Id, Name from User where Name = 'User Integrator' LIMIT 1];
        system.runAs(usr) {
            final Account acc = testClass.createClient();
            insert acc;
            final User user = testClass.createUser(userinfo.getProfileId());
            insert user;
            final DES_BBVA_Management_team__c bbvamember =  testClass.createBBVAManagementTeamMember(user, acc);
            insert bbvamember;
        }
        final Id batchInstanceId = DES_WS_DeleteBBVAMembers.runDeleteMembersBatch();
        system.assertNotEquals(batchInstanceId, null, 'msg');
    }

    /*
    * Test method for testGtInstance
    */
    @isTest
    public static void testGtInstance() {
        final DES_WS_DeleteBBVAMembers wsv = DES_WS_DeleteBBVAMembers.gtInstance();
        system.assertNotEquals(wsv, null, 'msg1');
    }
}