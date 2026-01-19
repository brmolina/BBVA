@isTest
public class DPMX_MostrarHistorialTasas_ctrl_Test {
    
    @TestSetup
    static void createData() {
        
        user userTest = DPMX_Test_Utils.createUser('XE0000');
        Insert userTest;
        
        user userTest1 = DPMX_Test_Utils.createUserPersonalized('XE0001', 'testEmailMostrarHistorial');
        Insert userTest1;
       
        Account accountTest = DPMX_Test_Utils.createAccount('accountTest');
        insert accountTest;
        
        DPMX_Dynamic_Pricing__c dynamicPricingTest = DPMX_Test_Utils.createDynamicPricing('TestDPMX',accountTest.Id);
        insert dynamicPricingTest;
        
        DPMX_Dynamic_Pricing__c dynamicPricingTestIsGs = DPMX_Test_Utils.createDynamicPricing('TestDPMXIsGs',accountTest.Id);
        dynamicPricingTestIsGs.familia__c = 'Grandes_Superficies';
        insert dynamicPricingTestIsGs;
        
        DPMX_Formalize__c formalizeTest = DPMX_Test_Utils.createFormalize(dynamicPricingTest,'XE0000');
        formalizeTest.deniedCheck__c = false;
        insert formalizeTest;
    }
    
    @isTest
    static void getInitialData() {
        user userTest = [SELECT id, Name, ID_User__c
                            FROM user
                            WHERE ID_User__c = 'XE0001'];
        System.debug(userTest.ID_User__c);
        DPMX_Dynamic_Pricing__c dpmxTest = [SELECT id FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        Test.startTest();
		Map<String, Object> retMap = DPMX_MostrarHistorialTasas_ctrl.getInitialData(dpmxTest.Id, userTest.ID_User__c, 'XE0000');
        string userReturnName = (String) retMap.get('businessAgent');
        System.assertEquals(userTest.Name, userReturnName,'getInitialData');
        Test.stopTest();
    }
    
    @isTest
    static void getInitialDataIsGs() {
        user userTest = [SELECT id, Name, ID_User__c
                            FROM user
                            WHERE ID_User__c = 'XE0001'];
        System.debug(userTest.ID_User__c);
        DPMX_Dynamic_Pricing__c dpmxTest = [SELECT id FROM DPMX_Dynamic_Pricing__c WHERE familia__c = 'Grandes_Superficies' LIMIT 1];
        Test.startTest();
		Map<String, Object> retMap = DPMX_MostrarHistorialTasas_ctrl.getInitialData(dpmxTest.Id, userTest.ID_User__c, 'XE0000');
        string userReturnName = (String) retMap.get('businessAgent');
        System.assertEquals(userTest.Name, userReturnName,'getInitialData');
        Test.stopTest();
    }

}