@isTest
/*
 *  Global Desktop
 *
 */
public class Batch_Visit_InvolvedProductsTest {

    @isTest
    /*
    *  Global Desktop
    *
    */
    public static void batchVisitInvolvedProductsTest1() {
        // Datos necesarios
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final String profileTest = utilTestClass.createProfile();
        final User userTest = utilTestClass.createUser(profileTest);
        insert userTest;
        final Account acc = utilTestClass.createClient();
        insert acc;
        final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
        final DES_BBVA_Management_team__c bbvaMngmntTeam1 = utilTestClass.createBBVAManagementTeamMember(userTest, acc);
        bbvaMngmntTeam1.DES_Local_Banker_Country__c = 'ES';
        bbvaMngmntTeam1.DES_Member_Role__c = Label.DES_ROLE_INDUSTRY_HEAD;
        listaBBVAMT.add(bbvaMngmntTeam1);
        insert listaBBVAMT;
        final dwp_kitv__Visit__c visit1 = utilTestClass.createVisit(acc, null);
        insert visit1;

        final dwp_kitv__Visit_Management_Team__c visitTM = utilTestClass.createVisitTM(userTest, visit1);
        insert visitTM;

        Test.startTest();
        final Id batchInstanceId = Database.executeBatch(new Batch_Visit_InvolvedProducts(), 8);
        Test.stopTest();
        System.assertNotEquals(batchInstanceId, null);

    }
}