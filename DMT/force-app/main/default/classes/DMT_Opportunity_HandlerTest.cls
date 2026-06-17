@isTest
public with sharing class DMT_Opportunity_HandlerTest {

     @TestSetup
    static void loadTestData()
    {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem opplinteitem = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        DMT_Test_DataFactory.generateOpportunityMitigant(opplinteitem);
    }

    @isTest
    static void testCallGetCustomerHPGS() {
        Opportunity newOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>{ 'recordId' => newOpportunity.Id },
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Object result = (new DMT_Opportunity_Handler()).call('getCustomerHPGS', args);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.debug('resultMap: ' + resultMap);
         System.assert(resultMap.containsKey('serviceError'), 'Debe dar error el Servicio');
    }

    @isTest
    static void testCallGetMinAndMaxDates() {
        Opportunity newOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>{ 'recordId' => newOpportunity.Id },
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Object result = (new DMT_Opportunity_Handler()).call('getMinAndMaxDates', args);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assert(resultMap.containsKey('maxMaturityDate'), 'Debe contener maxMaturityDate');
        System.assert(resultMap.containsKey('minInitialDate'), 'Debe contener minInitialDate');
    }
     @isTest
    static void testCallValidateRealGuaratorsFromRaw() {
        Opportunity newOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        DMT_Opportunity_Mitigant__c mitigant = [SELECT Id,Commercial_Percentage__c ,Political_Percentage__c, CurrencyIsoCode FROM DMT_Opportunity_Mitigant__c LIMIT 1];

        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>{ 'myRealGuarantees' => JSON.deserializeUntyped(JSON.serialize(mitigant)) },
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Object result = (new DMT_Opportunity_Handler()).call('validateRealGuaratorsFromRaw', args);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assert(resultMap.containsKey('validationPassed'),true);
    }

    @isTest
    static void testCallMethodNotDefined() {
        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>(),
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Object result = (new DMT_Opportunity_Handler()).call('noExiste', args);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>)result;
        System.assertEquals(true, resultMap.get('error'), 'Debe devolver error=true');
    }

    @isTest
    static void tenorsValidationTest() {
        Date init = Date.today();
        Date mid = init.addDays(2);
        Date mat = init.addDays(10);

        List<Object> myTenors = new List<Object>{
            new Map<String,Object>{
                'gf_tenor_date__c' => String.valueOf(init),
                'gj_nominal_amount_db__c' => 100, 'gf_nominal_amount_fb__c' => 0,
                // flags INIT
                'lockDate'=>true, 'deleteDisabled'=>true, 'aviableItem'=>false, 'notEditable'=>false
            },
            new Map<String,Object>{
                'gf_tenor_date__c' => String.valueOf(mid),
                'gj_nominal_amount_db__c' => 0, 'gf_nominal_amount_fb__c' => 100
            },
            new Map<String,Object>{
                'gf_tenor_date__c' => String.valueOf(mat),
                'gj_nominal_amount_db__c' => 0, 'gf_nominal_amount_fb__c' => 100,
                // flags END
                'notEditable'=>true, 'aviableItem'=>true, 'editDisabled'=>true, 'deleteDisabled'=>true
            }
        };

        Map<String,Object> input = new Map<String,Object>{
            'myTenors' => myTenors,
            'gf_initial_date__c' => String.valueOf(init),
            'gf_maturity_date__c' => String.valueOf(mat)
        };

        Map<String,Object> args = new Map<String,Object>{
            'input' => input, 'output' => new Map<String,Object>(), 'options' => new Map<String,Object>()
        };

        Test.startTest();
        Object result = (new DMT_Opportunity_Handler()).call('tenorsValidation', args);
        Test.stopTest();

        Map<String,Object> out = (Map<String,Object>)result;
        System.assertEquals(true, out.get('validationPassed'), 'It should validate correctly with valid dates and amounts.');
    }

    @isTest
    static void testGetWebLinkUrl_ValidRecord() {
        String testRecordName = 'Demo';

        Test.startTest();
        String resultUrl = DMT_Opportunity_Handler.getWebLinkUrl(testRecordName);
        Test.stopTest();

        System.assertNotEquals(null, resultUrl, 'A valid Custom Metadata record should return a URL string.');
    }

    @isTest
    static void testGetWebLinkUrl_InvalidRecord() {
        String fakeRecordName = 'BOGUS_RECORD_NAME_9999';

        Test.startTest();
        String resultUrl = DMT_Opportunity_Handler.getWebLinkUrl(fakeRecordName);
        Test.stopTest();

        System.assertEquals(null, resultUrl, 'An invalid metadata record name should gracefully return null.');
    }


    @isTest
    static void testGetAssociatedSanctionLine_BlankExternalId() {
        Test.startTest();
        DMT_Opportunity_Handler.AssociatedLineInfo result = DMT_Opportunity_Handler.getAssociatedSanctionLine(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Debe devolver null cuando el external id esta vacio');
    }

    @isTest
    static void testGetAssociatedSanctionLine_WithoutSanction() {
        Test.startTest();
        DMT_Opportunity_Handler.AssociatedLineInfo result = DMT_Opportunity_Handler.getAssociatedSanctionLine('00001');
        Test.stopTest();

        System.assertEquals(null, result, 'Debe devolver null cuando la oportunidad no tiene sancion asociada');
    }

    @isTest
    static void testGetAssociatedSanctionLine_WithSanction() {
        Opportunity opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();

        opp.DMT_Sanction__c = line.Id;
        update opp;

        Test.startTest();
        DMT_Opportunity_Handler.AssociatedLineInfo result = DMT_Opportunity_Handler.getAssociatedSanctionLine('00001');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe devolver datos cuando existe sancion asociada');
        System.assertEquals(line.Id, result.lineId, 'Debe devolver el id de la linea asociada');
        System.assertEquals(line.Name, result.lineLabel, 'Debe devolver el nombre de la linea asociada');
    }

}