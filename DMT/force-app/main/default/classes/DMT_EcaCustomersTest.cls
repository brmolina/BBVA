@IsTest
public with sharing class DMT_EcaCustomersTest {

    // ----------------------------------------------------
    // TestSetup: settings mínimos
    // ----------------------------------------------------
    @TestSetup
    static void makeData(){
        final List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));
        
        insert settingsToInsert;
    }

    @IsTest
    static void test_DMT_EcaCustomers_EcaCustomerOk() {

        final String requestStr = JSON.serialize(new Map<String, Object> {
            'customerId' => 'ES0182011799173'
        });

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
            final Map<String, Object> outMap = DMT_EcaCustomers.DMT_EcaCustomers(requestStr, new Map<String, Object>());
        Test.stopTest();

        Assert.isTrue((Boolean) outMap.get('isEcaCustomer') == true, 'When return 200/201 with choosebleEcaIndType = Y, isEcaCustomer should be true');
    }

    @isTest
    static void testInvokeMethodCatchBlock() {
        final Map<String, Object> input   = null;
        final Map<String, Object> output  = new Map<String, Object>();
        final Map<String, Object> options = new Map<String, Object>();
        final Map<String, Object> args    = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
            final Object result = new DMT_EcaCustomers().call('getEcaCustomer', args);
        Test.stopTest();
        
        Assert.areEqual(true, output.get('error'), 'Should be error equals true in the catch');
    }

    @IsTest
    static void test_call_getEcaCustomer_ok() {
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        final Map<String, Object> input   = new Map<String, Object> { 
            'customerId' => 'ES0182011799173' 
        };
        final Map<String, Object> output  = new Map<String, Object>();
        final Map<String, Object> options = new Map<String, Object>();
        final Map<String, Object> args    = new Map<String, Object> {
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
            final Object result = new DMT_EcaCustomers().call('getEcaCustomer', args);
        Test.stopTest();

        final Map<String, Object> outMap = (Map<String, Object>) result;
        Assert.isTrue((Boolean) outMap.get('error') != true, 'Call to getEcaCustomer is not correct');
    }

    @IsTest
    static void test_call_getEcaCustomer_missing_customerId() {
        final Map<String, Object> input   = new Map<String, Object>();
        final Map<String, Object> output  = new Map<String, Object>();
        final Map<String, Object> options = new Map<String, Object>();
        final Map<String, Object> args    = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
            final Object result = new DMT_EcaCustomers().call('getEcaCustomer', args);
        Test.stopTest();

        final Map<String, Object> outMap = (Map<String, Object>) result;
        Assert.isTrue(((Boolean) outMap.get('error') == true), 'Should be an error');
    }
}