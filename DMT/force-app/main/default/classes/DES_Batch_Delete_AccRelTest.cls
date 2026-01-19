@isTest
private class DES_Batch_Delete_AccRelTest{
       
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
        	dwp_acmh__GBL_Account_Relationship__c accRel = testClass.createAccRelationship(padre, hijo);
        	insert accRel;
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_AccRel(), 10000);
        }
    }

}