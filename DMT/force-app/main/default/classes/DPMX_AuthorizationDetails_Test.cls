@isTest
public class DPMX_AuthorizationDetails_Test {

    @isTest
    static void testGetInitialData() {
        
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
            LKP_Dynamic_Pricing__c = dynamicPricingTest.Id,
            STR_AuthBai__c = 'Test Bai',
            STR_AuthCredit__c = 'Test Credit',
            STR_AuthDebit__c = 'Test Debit',
            STR_AuthInternational__c = 'Test International',
            STR_AuthProfitability__c = 'Test Profitability',
            STR_AuthResult__c = 'Test Result',
            Comentario__c = 'Test comentario'
        );
        insert testAuthorization;

        // Llama al método getInitialData de la clase controladora
        Test.startTest();
        Map<String, Object> result = DPMX_AuthorizationDetails_ctrl.getInitialData(testAuthorization.Id);
        Test.stopTest();

        // Verifica que los datos retornados sean correctos
        System.assertEquals('Test Bai', result.get('authBai'));
        System.assertEquals('Test Credit', result.get('authCredit'));
        System.assertEquals('Test Debit', result.get('authDebit'));
        System.assertEquals('Test International', result.get('authInternational'));
        System.assertEquals('Test Profitability', result.get('authProfitability'));
        System.assertEquals('Test Result', result.get('authResult'));
    }
}