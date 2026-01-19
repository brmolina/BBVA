@isTest
public with sharing class DMT_Opportunity_HandlerTest {

     @TestSetup
    static void loadTestData() 
    {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem opplinteitem = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        DMT_Opportunity_Mitigant__c mitigant = DMT_Test_DataFactory.generateOpportunityMitigant(opplinteitem);
        
    }

    @isTest
    static void testCall_getCustomerHPGS() {
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
    static void testCall_getMinAndMaxDates() {
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
    static void testCall_validateRealGuaratorsFromRaw() {
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
    static void testCall_MethodNotDefined() {
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

}