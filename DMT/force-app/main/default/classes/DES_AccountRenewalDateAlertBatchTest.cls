@isTest
private class DES_AccountRenewalDateAlertBatchTest{
       
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
        	acc.DES_PF_RENEWAL_DATE__c = system.today().addDays(61);
        	insert acc;
        	DES_BBVA_Management_team__c bbvamt =  testClass.createBBVAManagementTeamMember(userTest, acc);
        	bbvamt.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
        	insert bbvamt;
        	acc.DES_Global_Banker_Ref__c = bbvamt.Id;
        	update acc;
        	system.debug('>>>>> acc: ' + acc);
        	Id batchInstanceId = Database.executeBatch(new DES_AccountRenewalDateAlertBatch(), 1);
        }
    }

}