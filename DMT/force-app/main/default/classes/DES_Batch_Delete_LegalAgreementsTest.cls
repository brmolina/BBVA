@isTest
private class DES_Batch_Delete_LegalAgreementsTest{
       
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
            
        	List<Contrato_Marco__c> listLegalAgreement = new List<Contrato_Marco__c>();
            //Funcion createLegalAgreement(Account accFilial, Account accGroup)
            Contrato_Marco__c legal1 = testClass.createLegalAgreement(accFilial, accGroup);
            listLegalAgreement.add(legal1);
            Contrato_Marco__c legal2 = testClass.createLegalAgreement(accFilial, accGroup);
            listLegalAgreement.add(legal2);
            Contrato_Marco__c legal3 = testClass.createLegalAgreement(accFilial, accGroup);
            listLegalAgreement.add(legal3);
            insert listLegalAgreement;
            
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_LegalAgreements(), 1000);
            system.assertNotEquals(batchInstanceId, null, 'ERROR');
        }
    }

}