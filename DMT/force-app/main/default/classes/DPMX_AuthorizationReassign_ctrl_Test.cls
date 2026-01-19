@isTest
public class DPMX_AuthorizationReassign_ctrl_Test {

    @testSetup
    static void setup() {
        User testUser1 = cuco.Test_Utils.createUser();
        testUser1.ID_User__c = 'UserTest';
        insert testUser1;

        User testUser2 = cuco.Test_Utils.createUser();
        testUser2.ID_User__c = 'UserTest2';
        testUser2.Username = 'testProfi2@example.com';
        testUser2.FederationIdentifier = '5678';
        insert testUser2;
        
        Account acc = new Account();
        acc.Name = 'AccountTest';
        insert acc;
        
        Local_Client__c locCli = new Local_Client__c();
        locCli.unique_id__c ='1111111';
        locCli.Name ='GRUPO AccountTest';
        locCli.Cib_Client__c = acc.Id;
        insert locCli;
        
        DPMX_Dynamic_Pricing__c dynamicPricingTest = new DPMX_Dynamic_Pricing__c();
        dynamicPricingTest.Name = 'Dynamic Pricing Test';
        dynamicPricingTest.Product__c = 'Acquirer';
        dynamicPricingTest.Client__c = acc.id;
        dynamicPricingTest.Company_Name__c = acc.Id;
        dynamicPricingTest.familia__c = 'Otro';
        dynamicPricingTest.familia_AcquiererCategories_Id__c = '13';
        String newDycPrgJSON = JSON.serialize(dynamicPricingTest);
        insert dynamicPricingTest;        

        DPMX_authorization__c testAuthorization = new DPMX_authorization__c(
            STR_AuthBai__c = 'Test Bai',
            STR_AuthCredit__c = 'Test Credit',
            STR_AuthDebit__c = 'Test Debit',
            STR_AuthInternational__c = 'Test International',
            STR_AuthProfitability__c = 'Test Profitability',
            STR_AuthResult__c = 'Test Result',
            Comentario__c = 'Test comentario',
            LKP_Dynamic_Pricing__c = dynamicPricingTest.Id,
            lkp_AssignedTo__c = testUser1.Id
        );
        insert testAuthorization;
    }
    
    @isTest
    static void testGetInitialData() {

        // Llama al método getInitialData de la clase controladora
        Test.startTest();
        Map<String, Object> result = DPMX_AuthorizationReassign_ctrl.getInitialData(null);
        Test.stopTest();
		System.debug(result);
        System.debug(result.get('userLst'));
        // Debido a un limite no se puede assignar permission sets a un usuario desde una classe test: TABSET_LIMIT_EXCEEDED
        System.assertEquals(result.get('success'), true);
    }

   @isTest
    static void testUpdateAuth() {
        list <User> us = [SELECT id FROM User LIMIT 2];
        DPMX_Dynamic_Pricing__c dynamicPricingTest= [SELECT  id FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        
        // Crea un registro de prueba de DPMX_authorization__c
        DPMX_authorization__c testAuthorization = new DPMX_authorization__c(
            STR_AuthBai__c = 'Test Bai',
            STR_AuthCredit__c = 'Test Credit',
            STR_AuthDebit__c = 'Test Debit',
            STR_AuthInternational__c = 'Test International',
            STR_AuthProfitability__c = 'Test Profitability',
            STR_AuthResult__c = 'Test Result',
            Comentario__c = 'Test comentario',
            LKP_Dynamic_Pricing__c = dynamicPricingTest.Id,
            lkp_AssignedTo__c = us[0].id
        );
        insert testAuthorization;

        // Llama al método updateAuth de la clase controladora
        Test.startTest();
        DPMX_AuthorizationReassign_ctrl.updateAuth(testAuthorization.Id, us[1].id); 
        Test.stopTest();

        // Verifica que la autorización se haya actualizado correctamente
        DPMX_authorization__c updatedAuthorization = [SELECT lkp_AssignedTo__c
            FROM DPMX_authorization__c WHERE Id = :testAuthorization.Id];

        System.assertEquals(us[1].id, updatedAuthorization.lkp_AssignedTo__c);
    }

}