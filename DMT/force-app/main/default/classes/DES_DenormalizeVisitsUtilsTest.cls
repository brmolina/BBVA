@isTest
public class DES_DenormalizeVisitsUtilsTest {
    @isTest static void test_DES_DenormalizeVisitsUtilsTest () {
        //Account[] accts = AMHI.GBL_TestMAHDataFactory.setupAccounts();
        DES_UtilTestClass testClass = new DES_UtilTestClass();

        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
        Account acc = testClass.createClient();
        insert acc;
        Opportunity opp = testClass.createOpportunity(acc);
        insert opp;
        dwp_kitv__Visit__c visit = testClass.createVisit(acc, opp);
        insert visit;

        Test.startTest();
        DES_DenormalizeVisitsUtils doUtil = new DES_DenormalizeVisitsUtils();
        doUtil.clear();

        doUtil.clear(visit.Id);
        doUtil.restore(visit.Id);

        doUtil.restore();
        test.stopTest();
    }

}