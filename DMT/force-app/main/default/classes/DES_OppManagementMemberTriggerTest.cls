/**
*
* @author Global Desktop
*/
@isTest
public class DES_OppManagementMemberTriggerTest {
    /**
     * Test que elimina un registro de DES_Opportunity_Management_member__c
     */    
    @isTest
    public static void deleteOpportunityManagementMemberTest() {
        // Datos necesarios
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final String profileTest = utilTestClass.createProfile();
        final User userTest = utilTestClass.createUser(profileTest);   
        insert userTest;
        final Account acc = utilTestClass.createClient();
        insert acc;
        final Opportunity opportunityTest = utilTestClass.createOpportunity(acc);
        insert opportunityTest;
        final Product2 cLoans = utilTestClass.createProduct(Label.DES_Corporate_Loans);
        cLoans.Family = 'IBF';
        insert cLoans;
        final DES_Opportunity_Management_member__c oppMngmntMmbrTest = utilTestClass.createOppManagementMember(userTest, opportunityTest);
        oppMngmntMmbrTest.DES_Opportunity_member_role__c = Label.DES_ROLE_GLOBAL_BANKER;
        insert oppMngmntMmbrTest;
        final DES_Opportunity_Management_member__c oppMngmntMmbrTest2 = utilTestClass.createOppManagementMember(userTest, opportunityTest);
        oppMngmntMmbrTest2.DES_Opportunity_member_role__c = Label.DES_ROLE_GLOBAL_BANKER;
        try {
            insert oppMngmntMmbrTest2;
        } catch(Exception e) {
            oppMngmntMmbrTest.DES_Opportunity_member_role__c = Label.DES_ROLE_LOCAL_BANKER;
            oppMngmntMmbrTest.DES_Scope__c = 'FR';
            update oppMngmntMmbrTest;
            oppMngmntMmbrTest2.DES_Opportunity_member_role__c = Label.DES_ROLE_LOCAL_BANKER;
            oppMngmntMmbrTest2.DES_Scope__c = 'FR';
            try {
                insert oppMngmntMmbrTest2;
            } catch(Exception e2) {
                oppMngmntMmbrTest.DES_Opportunity_member_role__c = Label.DES_Role_Product_Specialist;
                oppMngmntMmbrTest.DES_Scope__c = 'FR';
                oppMngmntMmbrTest.DES_PS_Product__c = cLoans.Id;
                oppMngmntMmbrTest.DES_PS_Product_Family__c = 'IBF';
                update oppMngmntMmbrTest;
                oppMngmntMmbrTest2.DES_Opportunity_member_role__c = Label.DES_Role_Product_Specialist;
                oppMngmntMmbrTest2.DES_Scope__c = 'FR';
                oppMngmntMmbrTest2.DES_PS_Product__c = cLoans.Id;
                oppMngmntMmbrTest2.DES_PS_Product_Family__c = 'IBF';
                try {
                    insert oppMngmntMmbrTest2;
                } catch(Exception e3) {
					System.debug(e3.getLineNumber() + ': ' + e3.getMessage());
                }
            }
        }
        //Test
        Test.startTest();
            delete oppMngmntMmbrTest;
            final List<DES_Opportunity_Management_member__c> oppMMTAfter = [SELECT Id, IsDeleted FROM DES_Opportunity_Management_member__c WHERE Id = :oppMngmntMmbrTest.Id];
            System.assert(oppMMTAfter.isEmpty(), 'partAfter is not empty');
        Test.stopTest();
    }
}