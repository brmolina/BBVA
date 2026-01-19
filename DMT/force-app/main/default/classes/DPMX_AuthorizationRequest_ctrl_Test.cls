@isTest
public class DPMX_AuthorizationRequest_ctrl_Test {
	@isTest
    static void testUpdateAuth() {
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
        
        Contact ctc = new Contact();
        ctc.AccountId = acc.id;
        ctc.lastName = 'lastName';
        ctc.email = '123123123@email.com';
        ctc.phone = '123123123';
        insert ctc;
        
        DPMX_authorization__c testAuthorization = new DPMX_authorization__c(
            Status__c = 'Pendiente',
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

        // Llama al método updateAuth de la clase controladora
        Test.startTest();
        Map<String, Object> result = DPMX_AuthorizationRequest_ctrl.updateAuth(
            testAuthorization.Id,
            'Test Comentario'
        );
        Test.stopTest();

        // Verifica que la autorización se haya actualizado correctamente
        DPMX_authorization__c updatedAuthorization = [SELECT Id, Status__c, commentAuthorizer__c, Date_AuthorizerDate__c
            FROM DPMX_authorization__c WHERE Id = :testAuthorization.Id];

        System.assertEquals('Aceptado', updatedAuthorization.Status__c);
        System.assertEquals('Test Comentario', updatedAuthorization.commentAuthorizer__c);
        System.assertEquals(Date.today(), updatedAuthorization.Date_AuthorizerDate__c);

        // Verifica el resultado del mapa
        Boolean toastStatus = (Boolean) result.get('statusAuth');
        System.assertEquals(true, toastStatus);
    }
}