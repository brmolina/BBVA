@isTest
private class DES_Batch_Delete_BBVATeamMemberTest{
       
    @isTest
    static void testTrigger(){
        
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	List<Account> listaAcc = new List<Account>();
        	Account padre = testClass.createClient();
        	listaAcc.add(padre);
        	Account hijo = testClass.createClient();
        	listaAcc.add(hijo);
        	insert listaAcc;
        	DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, padre);
        	insert bbvaMT;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_BBVATeamMember(), 10000);
        }
    }

}