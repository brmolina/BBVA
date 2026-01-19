@isTest
public class DES_Delete_Counterparty_SchedulableTest {
    
    @isTest
    public static void DES_Delete_Counterparty_SchedulableTest(){
    	DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
        Account acc = testClass.createClient();
        insert acc;
        Account acc2 = testClass.createClient();
        insert acc2;
        dwp_acmh__GBL_Account_Relationship__c accRel = testClass.createAccRelationship(acc, acc2);
        accRel.dwp_acmh__Type__c = '04 - Contrapartida';
        insert accRel;
		Test.startTest();
		String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Delete_Counterparties_Schedulable()); 
		Test.stopTest();
    }
    
}