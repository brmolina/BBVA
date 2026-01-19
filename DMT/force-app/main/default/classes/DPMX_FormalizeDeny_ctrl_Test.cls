@isTest
public class DPMX_FormalizeDeny_ctrl_Test {
	@TestSetup
    static void createData() {
       
        Account accountTest = DPMX_Test_Utils.createAccount('accountTest');
        insert accountTest;
        
        DPMX_Dynamic_Pricing__c dynamicPricingTest = DPMX_Test_Utils.createDynamicPricing('TestDPMX',accountTest.Id);
        insert dynamicPricingTest;
        
        DPMX_Formalize__c formalizeTest = DPMX_Test_Utils.createFormalize(dynamicPricingTest,'XE0000');
        formalizeTest.deniedCheck__c = false;
        insert formalizeTest;
    }
    
    @isTest
    static void testCreateAuthorization() {             
        DPMX_Formalize__c formalizeTest = [SELECT id, deniedCheck__c FROM DPMX_Formalize__c LIMIT 1];
        Test.startTest();
		Map<String, Object> retMap = DPMX_FormalizeDeny_ctrl.deniedFormalize(formalizeTest.Id,'Testmsg');
        DPMX_Formalize__c formalizeTestReturn = [SELECT id, deniedCheck__c FROM DPMX_Formalize__c LIMIT 1];
        System.debug(formalizeTest.deniedCheck__c);
        System.debug(formalizeTestReturn.deniedCheck__c);
        System.assertEquals(formalizeTest.deniedCheck__c, !formalizeTestReturn.deniedCheck__c,'testCreateAuthorization');
        Test.stopTest();
    }
}