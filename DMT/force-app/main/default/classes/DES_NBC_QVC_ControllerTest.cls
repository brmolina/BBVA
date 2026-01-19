/**
*
* @author Global Desktop
*/
@isTest
public class DES_NBC_QVC_ControllerTest {
    /**
     * Test method for DES_MigrateOwnerOppToTeamMember_Batch
     */
    @isTest
    public static void testOpportunityJson() {
        DES_UtilTestClass utils;
        utils = new DES_UtilTestClass();
        User usr;
        usr = utils.createUser(utils.createProfile());
        insert usr;
        Account acc;
        acc = utils.createGroupClient('Account Name', null, usr.id);
        upsert acc;
        NBC__c nbc;
        nbc = utils.createNBC();
        nbc.Committee_Start_Date__c = Date.today();
        upsert nbc;
        Opportunity opp;
        opp = utils.createOpportunity(acc);
        opp.Template_approved_type__c = true;
        opp.Committee_id__c = nbc.id;
        upsert opp;
        final String json = DES_NBC_QVC_Controller.opportunityJson(nbc.id);


        System.assertNotEquals(null, json);
    }
}