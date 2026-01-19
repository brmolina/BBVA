@isTest
private class DES_Batch_Delete_RCFEvolutionTest{
       
    @isTest
    static void testTrigger(){ 
        
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){     
        	Account accGroup = testClass.createClient();
            insert accGroup;
        	
            List<RCF_Evolution__c> listRCF = new List<RCF_Evolution__c>();
            //Funcion createRCF(Account accGroup)
            RCF_Evolution__c rcf1 = testClass.createRCFEvolution(accGroup);
            listRCF.add(rcf1);
            RCF_Evolution__c rcf2 = testClass.createRCFEvolution(accGroup);
            listRCF.add(rcf2);
           
            
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_RCFEvolution(), 10000);
            system.assertNotEquals(batchInstanceId, null, 'ERROR');
        }
    }

}