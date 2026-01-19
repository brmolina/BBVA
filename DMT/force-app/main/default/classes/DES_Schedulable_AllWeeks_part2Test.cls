@isTest
public class DES_Schedulable_AllWeeks_part2Test {
    
    @isTest
    public static void DES_Schedulable_AllWeeks_part2Test(){
    	DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
        
        Account acc = testClass.createClient();
        insert acc;
        
		Test.startTest();
		String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_AllWeeks_part2()); 
		Test.stopTest();
    }
    
}