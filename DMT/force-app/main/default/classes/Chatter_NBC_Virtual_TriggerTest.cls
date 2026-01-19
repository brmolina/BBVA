/**
*
* @author Global Desktop
*/
@isTest
public class Chatter_NBC_Virtual_TriggerTest {
    /**
    * Test que elimina un registro de DES_Opportunity_Management_member__c
    */
    @isTest
    public static void testShare() {
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
      cLoans.Family = 'GF';
      insert cLoans;

      Test.startTest();
        final Chatter_NBC_Virtual__c cNBCVirtual = utilTestClass.createChatterNBCVirtual(opportunityTest.Id, Label.Opportunity_Name);
        insert cNBCVirtual;
        final List<DES_Opportunity_Management_member__c> listOppMMs = new List<DES_Opportunity_Management_member__c>();
        final DES_Opportunity_Management_member__c oppMngmntMmbrTest = utilTestClass.createOppManagementMember(userTest, opportunityTest);
        oppMngmntMmbrTest.DES_Opportunity_member_role__c = Label.DES_ROLE_GLOBAL_BANKER;
        listOppMMs.add(oppMngmntMmbrTest);
        final DES_Opportunity_Management_member__c oppMMTest2 = utilTestClass.createOppManagementMember(userTest, opportunityTest);
        oppMMTest2.DES_Opportunity_member_role__c = Label.DES_ROLE_INDUSTRY_HEAD;
        listOppMMs.add(oppMMTest2);
        insert listOppMMs;
        delete listOppMMs;
      Test.stopTest();


      System.assertNotEquals(null, cNBCVirtual.Id);
    }
}