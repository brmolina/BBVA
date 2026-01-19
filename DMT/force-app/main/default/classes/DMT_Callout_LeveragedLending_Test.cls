@IsTest
public class DMT_Callout_LeveragedLending_Test {

    // ----------------------------------------------------
    // TestSetup: settings mínimos
    // ----------------------------------------------------
    @TestSetup
    static void makeData() {
        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(
            DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT', 'https://service.ok', 'ServicesPartition', false)
        );

        settingsToInsert.add(
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket', 'https://validation.ok', 'ServicesPartition', false)
        );

        insert settingsToInsert;
    }

    // ----------------------------------------------------
    // OK – llamada directa al servicio
    // ----------------------------------------------------
    @IsTest
    static void test_DMT_LeveragedLending_OK() {

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
            Map<String, Object> outMap =DMT_Callout_LeveragedLending.callLeveragedLendingService('GROUP01', '2024-01-01', new Map<String, Object>());
        Test.stopTest();

        Assert.areEqual('Yes', outMap.get('leveragedLendingIndType'), 'leveragedLendingIndType should be Yes');
    }

    // ----------------------------------------------------
    // invokeMethod – catch block
    // ----------------------------------------------------
    @IsTest
    static void testInvokeMethodCatchBlock() {

        final Map<String, Object> input   = null;
        final Map<String, Object> output  = new Map<String, Object>();
        final Map<String, Object> options = new Map<String, Object>();

        final Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
            Object result = new DMT_Callout_LeveragedLending().call('getLeveragedLending', args);
        Test.stopTest();

        Assert.areEqual(true,
            output.get('error'),'Should be error equals true in the catch'
        );
    }

    // ----------------------------------------------------
    // call('getLeveragedLending') OK
    // ----------------------------------------------------
    @IsTest
    static void test_call_getLeveragedLending_ok() {

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        final Map<String, Object> input = new Map<String, Object>{
            'groupId'    => 'GROUP01',
            'searchDate' => '2024-01-01'
        };

        final Map<String, Object> output  = new Map<String, Object>();
        final Map<String, Object> options = new Map<String, Object>();

        final Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
            Object result = new DMT_Callout_LeveragedLending().call('getLeveragedLending', args);
        Test.stopTest();

        Map<String, Object> outMap = (Map<String, Object>) result;

        Assert.isTrue((Boolean) outMap.get('error') != true, 'Call to getLeveragedLending is not correct');

        Assert.areEqual('Yes', outMap.get('leveragedLendingIndType'), 'leveragedLendingIndType should be Yes');
    }

    // ----------------------------------------------------
    // call('getLeveragedLending') – missing inputs
    // ----------------------------------------------------
    @IsTest
    static void test_call_getLeveragedLending_missing_params() {

        final Map<String, Object> input   = new Map<String, Object>();
        final Map<String, Object> output  = new Map<String, Object>();
        final Map<String, Object> options = new Map<String, Object>();

        final Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
            Object result = new DMT_Callout_LeveragedLending().call('getLeveragedLending', args);
        Test.stopTest();

        Map<String, Object> outMap = (Map<String, Object>) result;

        Assert.isTrue((Boolean) outMap.get('error') == true, 'Should be an error');
    }
}