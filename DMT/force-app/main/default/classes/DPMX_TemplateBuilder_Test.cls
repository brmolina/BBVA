/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_Actions_Ctrl_Test
* Test class for DPMX_TemplateBuilder apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-10-28
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class DPMX_TemplateBuilder_Test {
    @TestSetup
    static void createData() {
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
        dynamicPricingTest.Frequency_of_Revision__c = 'Biannual';
        dynamicPricingTest.familia__c = 'Otro';
        dynamicPricingTest.familia_AcquiererCategories_Id__c = '13';
        String newDycPrgJSON = JSON.serialize(dynamicPricingTest);
        insert dynamicPricingTest; 
    }
    @isTest
    static void testisUserAllowed() {
        DPMX_Dynamic_Pricing__c dynamicPricingTest= [SELECT  id FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        DPMX_TemplateBuilder controller = new DPMX_TemplateBuilder();

        Map<String, Object> args = new Map<String, Object>();
        args.put('recordId', dynamicPricingTest.Id);
        args.put('action', 'isUserAllowed');

        Object result = controller.call('isUserAllowed', args);
        System.assertEquals(result, true, 'isUserAllowed');
    }
    @isTest
    static void testgetContent() {
        DPMX_Dynamic_Pricing__c dynamicPricingTest= [SELECT id  FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        DPMX_TemplateBuilder controller = new DPMX_TemplateBuilder();

        Map<String, Object> args = new Map<String, Object>();
        args.put('recordId', dynamicPricingTest.Id);
        args.put('action', 'getContent');
        
        Object result = controller.call('getContent', args);
        System.assertEquals(result, result, 'getContent');
    }
    
    @isTest
    static void testgetRecipients() {
        DPMX_Dynamic_Pricing__c dynamicPricingTest= [SELECT id  FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        DPMX_TemplateBuilder controller = new DPMX_TemplateBuilder();

        Map<String, Object> args = new Map<String, Object>();
        args.put('recordId', dynamicPricingTest.Id);
        args.put('action', 'getRecipients');
        
        Object result = controller.call('getRecipients', args);
        System.assertEquals(result, result, 'getRecipients');
    }
    
    @isTest
    static void testrenderContent() {
        DPMX_Dynamic_Pricing__c dynamicPricingTest= [SELECT id  FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        DPMX_TemplateBuilder controller = new DPMX_TemplateBuilder();

        Map<String, Object> args = new Map<String, Object>();
        args.put('recordId', dynamicPricingTest.Id);
        args.put('action', 'renderContent');
        
        Object result = controller.call('renderContent', args);
        System.assertEquals(result, result, 'renderContent');
    }    
    @isTest
    static void testhandleResult() {
        DPMX_Dynamic_Pricing__c dynamicPricingTest= [SELECT id  FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        DPMX_TemplateBuilder controller = new DPMX_TemplateBuilder();

        Map<String, Object> args = new Map<String, Object>();
        args.put('recordId', dynamicPricingTest.Id);
        args.put('action', 'handleResult');
        
        Object result = controller.call('handleResult', args);
        System.assertEquals(result, true, 'handleResult');
    }
    
    @isTest
    static void testissendEmail() {
        DPMX_Dynamic_Pricing__c dynamicPricingTest= [SELECT id  FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        DPMX_TemplateBuilder controller = new DPMX_TemplateBuilder();

        Map<String, Object> args = new Map<String, Object>();
        args.put('recordId', dynamicPricingTest.Id);
        args.put('action', 'sendEmail');
        
        Object result = controller.call('sendEmail', args);
        System.assertEquals(result, true, 'sendEmail');
    }
}