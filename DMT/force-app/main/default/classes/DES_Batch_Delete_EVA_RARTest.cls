@isTest
private class DES_Batch_Delete_EVA_RARTest{
       
    @isTest
    static void testTrigger(){
        
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Account acc = testClass.createClient();
            insert acc;
        	DES_Historic_RAR_EVA_RORC__c historic = new DES_Historic_RAR_EVA_RORC__c();
	        historic.DES_Client__c = acc.Id;
	        historic.DES_EVA_Amount__c = 80.08;
	        historic.DES_RAR_Amount__c = 32.93;
	        historic.DES_RORC_Amount__c = 27.31;
	        historic.DES_Year_Text__c = '2017';
	        insert historic;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_EVA_RAR(), 1);
        }
    }

}