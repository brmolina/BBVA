@isTest
private class DES_Batch_Delete_RCFExpirationTest{
       
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
        	
            List<RCF_Expiration__c> listRCF = new List<RCF_Expiration__c>();
            //Funcion createRCF(Account accGroup)
            RCF_Expiration__c rcf1 = testClass.createRCF(accGroup);
            listRCF.add(rcf1);
            RCF_Expiration__c rcf2 = testClass.createRCF(accGroup);
            listRCF.add(rcf2);
           
            
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_RCFExpiration(), 10000);
            system.assertNotEquals(batchInstanceId, null, 'ERROR');
        }
    }

}