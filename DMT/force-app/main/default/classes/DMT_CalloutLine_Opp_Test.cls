@IsTest
public class DMT_CalloutLine_Opp_Test {
    @TestSetup
    static void setup() {

        List<iaso__GBL_Rest_Services_Url__c> settings = new List<iaso__GBL_Rest_Services_Url__c>();

        settings.add(DMT_Test_DataFactory.setIasoCustomSetting(
            'HPG_CommonEndPoint_INT', 'https://service.ok', 'ServicesPartition', false
        ));
        settings.add(DMT_Test_DataFactory.setIasoCustomSetting(
            'DMT_GrantingTicket', 'https://validation.ok', 'ServicesPartition', false
        ));

        insert settings;
        insert new DMT_Line__c(
            Name = 'Linea Test',
            Line_Id__c = 'L1'
        );
    }

    @IsTest
    static void test_call_getLines_ok() {

        DMT_Line__c lineRecord = new DMT_Line__c(
            Name = 'Linea Test',
            Line_Id__c = 'L1'
        );
        insert lineRecord;

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
            List<DMT_CalloutLine_Opp.Data> lines =
                DMT_CalloutLine_Opp.getLinesFromService('ES0182011799173');
        Test.stopTest();
    }

    @IsTest
    static void test_call_getProductsFromService_ok() {

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
            List<DMT_CalloutLine_Opp.ProductData> products =
                DMT_CalloutLine_Opp.getProductsFromService('L1');
        Test.stopTest();
    }

    @IsTest
    static void test_call_unsupportedMethod() {

        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>(),
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Test.startTest();
            Object result = new DMT_CalloutLine_Opp().call('UNKNOWN_METHOD', args);
        Test.stopTest();

        Map<String, Object> outMap = (Map<String, Object>) result;
        System.assertEquals(true, outMap.get('error'), 'Debe dar error por método no soportado');
    }

    @IsTest
    static void test_call_catchBlock() {

        Map<String, Object> args = new Map<String, Object>{
            'input' => null,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Test.startTest();
            Object res = new DMT_CalloutLine_Opp().call('getLines', args);
        Test.stopTest();

        Map<String, Object> outMap = (Map<String, Object>) res;

        System.assertEquals(true, outMap.get('error'), 'Debe devolver error en catch block');
    }

    @IsTest
    static void test_getRiskLineTerms_ok() {
        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'L1', Name = 'Linea Test');
        insert line;

        DMT_Risk_Line_Term__c term = new DMT_Risk_Line_Term__c(
            DMT_Line__c = line.Id,
            gf_group_priority_line_id__c = 'G1'
        );
        insert term;

        List<DMT_Risk_Line_Term__c> results = DMT_CalloutLine_Opp.getRiskLineTerms('L1');

        System.assertNotEquals(null, results);
        System.assertEquals(1, results.size());
        System.assertEquals(term.Id, results[0].Id);
    }

    @IsTest
    static void test_getLineSFId_ok() {
        DMT_Line__c line = new DMT_Line__c(Line_Id__c='L1', Name='Linea Test');
        insert line;

        Id resultId = DMT_CalloutLine_Opp.getLineSFId('L1');
    }
}