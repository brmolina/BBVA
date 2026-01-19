@isTest
public class DES_Schedulable_Delete_BBVAMTTest {
    
    @isTest
    public static void DES_Schedulable_Delete_BBVAMTTest(){
    	DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
        Account acc = testClass.createClient();
        insert acc;
        DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
        insert bbvaMT;
		Test.startTest();
		String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_Delete_BBVATeamMembers()); 
		Test.stopTest();
    }
    
}