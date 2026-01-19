@isTest
private class DES_Batch_Delete_LoansRepaymentTest{
       
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
        	
            List<Loans_Repayment__c> listLoansRepaymente = new List<Loans_Repayment__c>();
            //Funcion createLoansRepayment(Account accGroup)
            Loans_Repayment__c loans1 = testClass.createLoansRepayment(accGroup);
            listLoansRepaymente.add(loans1);
            Loans_Repayment__c loans2 = testClass.createLoansRepayment(accGroup);
            listLoansRepaymente.add(loans2);
           
            
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_LoansRepayment(), 10000);
            system.assertNotEquals(batchInstanceId, null, 'ERROR');
        }
    }

}