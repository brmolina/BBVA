@isTest(seeAllData=false)
public class DMT_HasProspectRendererTest {
    
    @TestSetup
    static void makeData() {
        TriggerBypass.setBypass();
        
        Account testAccount = new Account(
            Name = 'Test Account',
            g_customer_id__c = 'TEST123456789'
        );
        insert testAccount;
        
        Map<String, Schema.RecordTypeInfo> rtInfos_Line = 
            Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName();
        
        DMT_Line__c treasuryLine = new DMT_Line__c(
            Name = 'Test Treasury Line',
            Line_Id__c = 'TL001',
            Client__c = testAccount.Id,
            CurrencyIsoCode = 'EUR',
            RecordTypeId = rtInfos_Line.get('TreasurySettlement').getRecordTypeId(),
            Booking_Geography__c = 'ES',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12)
        );
        insert treasuryLine;
    }
    
    @isTest
    static void testRenderHtml_Success() {
        DMT_Line__c treasuryLine = [SELECT Id, RecordTypeId FROM DMT_Line__c WHERE Line_Id__c = 'TL001' LIMIT 1];
        
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = treasuryLine.RecordTypeId;
        data.hasProspect = true;
        data.objectApiName = 'DMT_Line__c';
        
        Test.startTest();
        DMT_HasProspectRenderer renderer = new DMT_HasProspectRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('PROSPECT'), 'Should contain PROSPECT message');
    }
    
    @isTest
    static void testRenderHtml_NullData() {
        Test.startTest();
        DMT_HasProspectRenderer renderer = new DMT_HasProspectRenderer();
        String result = renderer.renderHtml(null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Error'), 'Should contain error message');
    }
    
    @isTest
    static void testRenderHtml_UnsupportedRecordType() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = '012000000000000AAA';
        data.hasProspect = true;
        data.objectApiName = 'DMT_Line__c';
        
        Test.startTest();
        DMT_HasProspectRenderer renderer = new DMT_HasProspectRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Error'), 'Should contain error message');
    }
}