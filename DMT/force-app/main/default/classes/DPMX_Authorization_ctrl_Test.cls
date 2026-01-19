@isTest
public class DPMX_Authorization_ctrl_Test {
    @TestSetup
    static void createData() {
        User us = DPMX_Test_Utils.createUserPersonalized('XE0000', 'TestAuthorize1');
        insert us;
        
        Account acc = DPMX_Test_Utils.createAccount('AccountTest');
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
    }
    
    @isTest
    static void testgetInitialData() {
        List<PermissionSetAssignment> usersToAuthLst = DPMX_Utils.userSelectorPermisionSet('DPMX_DynamicPrincingAuthorize');
        Test.startTest();
        Map<String, Object> result = DPMX_Authorization_ctrl.getInitialData();
        List<String> permSetAssLst = (List<String>) result.get('usersToAuthNamesLst');
        System.assertEquals(permSetAssLst.contains(usersToAuthLst[0].Assignee.Name), true,'testgetInitialData');
        Test.stopTest();
    }

    @isTest
    static void testCreateAuthorization() {
        User us = [SELECT id FROM User LIMIT 1]; 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTest' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricingTest = [SELECT id, 
                                                      Name,
                                                      Product__c,
                                                      Client__c,
                                                      Company_Name__c,
                                                      familia__c,
                                                      familia_AcquiererCategories_Id__c,
                                                      OwnerId,
                                                      Client__r.Name
                                                      FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        
        Test.startTest();
        Map<Boolean, String> result = DPMX_Authorization_ctrl.createAuthorization(
            'Test Commentario',
            dynamicPricingTest,
            '1',
            '2',
            '3',
            '4',
            '5',
            'true',
            '1',
            '2',
            '3',
            '4',
            '5',
            '19',
            us.Id,
            'BREAK_EVEN'
        );
        System.assertEquals(result.get(false), 'La autorización se ha creado.','TestDPMX_Authorization_ctrl');
        Test.stopTest();
    }
    
    @isTest
    static void testAuthorizationExist() {
        User us = [SELECT id FROM User LIMIT 1]; 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTest' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricingTest = [SELECT id, 
                                                      Name,
                                                      Product__c,
                                                      Client__c,
                                                      Company_Name__c,
                                                      Company_Name__r.Name,
                                                      familia__c,
                                                      familia_AcquiererCategories_Id__c,
                                                      OwnerId,
                                                      Client__r.Name
                                                      FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        
        Test.startTest();
        Map<Boolean, String> result = DPMX_Authorization_ctrl.createAuthorization(
            'Test Commentario',
            dynamicPricingTest,
            '1',
            '2',
            '3',
            '4',
            '5',
            'true',
            '1',
            '2',
            '3',
            '4',
            '5',
            '19',
            us.Id,
            'BREAK_EVEN'
        );  
        
        Map<Boolean, String> result2 = DPMX_Authorization_ctrl.createAuthorization(
            'Test Commentario',
            dynamicPricingTest,
            '1',
            '2',
            '3',
            '4',
            '5',
            'true',
            '1',
            '2',
            '3',
            '4',
            '5',
            '19',
            us.Id,
            'BREAK_EVEN'
        );
        System.assertEquals(result2.get(true), 'La autorización con estos valores ya existe.','TestDPMX_Authorization_ctrl');
        Test.stopTest();
    }

}