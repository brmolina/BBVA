@isTest
private class DES_Batch_Delete_TopWonDealsTest{
       
    @isTest
    static void testTrigger(){
        
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Account accFilial = testClass.createClient();
            insert accFilial;
            
            Account accGroup = testClass.createClient();
            insert accGroup;
            
        	List<DES_TopWonDeals__c> listTopWonDeals = new List<DES_TopWonDeals__c>();
            //Funcion createAggregatedTopWonDeals(Account accFilial, Account accGroup)
            DES_TopWonDeals__c top1 = testClass.createAggregatedTopWonDeals(accFilial, accGroup);
            listTopWonDeals.add(top1);
            DES_TopWonDeals__c top2 = testClass.createAggregatedTopWonDeals(accFilial, accGroup);
            listTopWonDeals.add(top2);
            DES_TopWonDeals__c top3 = testClass.createAggregatedTopWonDeals(accFilial, accGroup);
            listTopWonDeals.add(top3);
            insert listTopWonDeals;
            
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_TopWonDeals(), 1000);
            system.assertNotEquals(batchInstanceId, null, 'ERROR');
        }
    }

}