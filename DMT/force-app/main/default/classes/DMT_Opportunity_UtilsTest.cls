@IsTest
public with sharing class DMT_Opportunity_UtilsTest {
    @TestSetup
    static void loadTestData() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product, pricebookEntry, opp);
        DMT_Opportunity_Mitigant__c mitigant = DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);

    }

     @IsTest
    static void testConvertCurrency() {
        // Preparar la entrada simulada desde el Flow
        DMT_Opportunity_Utils.InputWrapper input = new DMT_Opportunity_Utils.InputWrapper();
        input.amount = 100;
        input.fromCurrency = 'EUR';
        input.toCurrency = 'USD';

        List<DMT_Opportunity_Utils.InputWrapper> inputList = new List<DMT_Opportunity_Utils.InputWrapper>{ input };

        Test.startTest();
        List<DMT_Opportunity_Utils.OutputWrapper> results = DMT_Opportunity_Utils.convertCurrency(inputList);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Debe haber un resultado');
    }

    @isTest
    static void testCopyInputToOutput_Indirect() {
        // Forzar error con recordId inválido (no es un Id real)
        Map<String, Object> input = new Map<String, Object>{
            'recordId' => 'NOT_A_VALID_ID',
            'customKey1' => 'value1',
            'customKey2' => 'value2'
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> result = DMT_Opportunity_Utils.getOpportunityProductsMinAndMaxDates(input, outMap, options);

        // copyInputToOutput debe copiar las claves excepto 'recordId' y 'action'
        System.assertEquals('value1', result.get('customKey1'));
        System.assertEquals('value2', result.get('customKey2'));
        System.assert(!result.containsKey('recordId'), 'recordId no debería estar en el output');
    }

    @isTest
    static void validTenorsTest() {
        Map<String, Object> tenorMap1 = new Map<String, Object>{
            'gf_nominal_amount_fb__c' => 100,
            'gj_nominal_amount_db__c' => 0,
            'gf_tenor_date__c' => String.valueOf(Date.today())
        };

        Map<String, Object> tenorMap2 = new Map<String, Object>{
            'gf_nominal_amount_fb__c' => 0,
            'gj_nominal_amount_db__c' => 200,
            'gf_tenor_date__c' => String.valueOf(Date.today().addDays(30))
        };

        List<Object> rawTenors = new List<Object>{ tenorMap1, tenorMap2 };

        Test.startTest();
        Map<String, Object> result = DMT_Opportunity_Utils.validateTenorsFromRaw(rawTenors);
        Test.stopTest();

        System.assertEquals(true, result.get('validationPassed'),
            'Validation should pass because there are more than 2 rows, amounts > 0 and payment dates are different');
    }

    @isTest
    static void invalidTenorsTest() {
        Map<String, Object> tenorMap = new Map<String, Object>{
            'gf_nominal_amount_fb__c' => 0,
            'gj_nominal_amount_db__c' => 0,
            'gf_tenor_date__c'        => String.valueOf(Date.today())
        };
        List<Object> rawTenors = new List<Object>{ tenorMap };

        Test.startTest();
        Map<String, Object> result = DMT_Opportunity_Utils.validateTenorsFromRaw(rawTenors);
        Test.stopTest();

        System.assertEquals(false, result.get('validationPassed'),
            'The validation should fail because amounts sum == 0');
        System.assertEquals(Label.dmt_cl_DrawnOrUndrawnAmountRequired_Text, (String)result.get('errorMessage'));
    }

    @isTest
    static void tenorsExceptionTest() {
        List<Object> rawTenors = new List<Object>{ 'invalid_type' };

        Test.startTest();
        Map<String, Object> result = DMT_Opportunity_Utils.validateTenorsFromRaw(rawTenors);
        Test.stopTest();

        System.assertEquals(true, result.containsKey('exceptionList'),
            'An exceptionList was expected for invalid input row');
    }

    @isTest
    static void tenorsMissingDateFails() {
        List<Object> rows = new List<Object>{
            new Map<String,Object>{
                'gj_nominal_amount_db__c' => 100,
                'gf_nominal_amount_fb__c' => 0
            }
        };

        Map<String,Object> result = new Map<String,Object> ();

        Test.startTest();
        result = DMT_Opportunity_Utils.validateTenorsFromRaw(rows);
        Test.stopTest();

        System.assertEquals(Label.dmt_cl_PaymentDateRequired_Text, (String)result.get('errorMessage'), 'An error message is expected');
    }

    @isTest
    static void tenorsDuplicateDatesFails() {
        String paymentDate = String.valueOf(Date.today());
        List<Object> rows = new List<Object>{
            new Map<String,Object>{ 'gj_nominal_amount_db__c'=>100, 'gf_nominal_amount_fb__c'=>0, 'gf_tenor_date__c'=> paymentDate },
            new Map<String,Object>{ 'gj_nominal_amount_db__c'=>0, 'gf_nominal_amount_fb__c'=>100, 'gf_tenor_date__c'=> paymentDate }
        };
        
        Map<String,Object> result = new Map<String,Object> ();

        Test.startTest();
        result = DMT_Opportunity_Utils.validateTenorsFromRaw(rows);
        Test.stopTest();
        
        System.assertEquals(false, result.get('validationPassed'), 'Validation should fail because dates are duplicated');
    }


    @isTest
    static void tenorsIntermediateBeforeInitialFails() {
        Date init = Date.today();
        Date mid = init.addDays(-2);
        Date mat = init.addDays(10);
        List<Object> rows = new List<Object>{
            new Map<String,Object>{ 'gj_nominal_amount_db__c'=>100, 'gf_nominal_amount_fb__c'=>0, 'gf_tenor_date__c'=> String.valueOf(init),
                // flags INIT
                'lockDate'=>true, 'deleteDisabled'=>true, 'aviableItem'=>false, 'notEditable'=>false
            },
            new Map<String,Object>{ 'gj_nominal_amount_db__c'=>100, 'gf_nominal_amount_fb__c'=>0, 'gf_tenor_date__c'=> String.valueOf(mid) },
            new Map<String,Object>{ 'gj_nominal_amount_db__c'=>0, 'gf_nominal_amount_fb__c'=>100, 'gf_tenor_date__c'=> String.valueOf(mat),
                // flags END
                'notEditable'=>true, 'aviableItem'=>true, 'editDisabled'=>true, 'deleteDisabled'=>true
            }
        };
        
        Map<String,Object> result = new Map<String,Object> ();

        Test.startTest();
        result = DMT_Opportunity_Utils.validateTenorsFromRaw(rows);
        Test.stopTest();

        System.assertEquals(false, result.get('validationPassed'), 'Validation should fail because intermediate is before initial');
    }

    @isTest
    static void tenorsIntermediateAfterMaturityFails() {
        Date init = Date.today();
        Date mid = init.addDays(15);
        Date mat = init.addDays(10);
        List<Object> rows = new List<Object>{
            new Map<String,Object>{ 'gj_nominal_amount_db__c'=>1, 'gf_nominal_amount_fb__c'=>0, 'gf_tenor_date__c'=> String.valueOf(init),
                'lockDate'=>true, 'deleteDisabled'=>true, 'aviableItem'=>false, 'notEditable'=>false
            },
            new Map<String,Object>{ 'gj_nominal_amount_db__c'=>1, 'gf_nominal_amount_fb__c'=>0, 'gf_tenor_date__c'=> String.valueOf(mid) },
            new Map<String,Object>{ 'gj_nominal_amount_db__c'=>0, 'gf_nominal_amount_fb__c'=>1, 'gf_tenor_date__c'=> String.valueOf(mat),
                'notEditable'=>true, 'aviableItem'=>true, 'editDisabled'=>true, 'deleteDisabled'=>true
            }
        };
        
        Map<String,Object> result = new Map<String,Object> ();

        Test.startTest();
        result = DMT_Opportunity_Utils.validateTenorsFromRaw(rows);
        Test.stopTest();

        System.assertEquals(false, result.get('validationPassed'), 'Validation should fail because intermediate is after maturity');
    }

    @isTest
    static void normalizeToDateExceptionTest() {
        Map<String, Object> tenorMap = new Map<String, Object>{
            'gf_nominal_amount_fb__c' => 100,
            'gj_nominal_amount_db__c' => 0,
            'gf_tenor_date__c' => 'not_a_valid_date'
        };

        List<Object> rawTenors = new List<Object>{ tenorMap };

        Test.startTest();
        Map<String, Object> result = DMT_Opportunity_Utils.validateTenorsFromRaw(rawTenors);
        Test.stopTest();

        System.assertEquals(false, result.get('validationPassed'), 'Validation should fail because there is an invalid date and normalizeToDate() returns null');
    }

    @IsTest
    static void parseDecimalExceptionTest() {
        String errorMessage = '';
        Decimal result;

        Test.startTest();
        try {
            Object invalidValue = 'test';

            result = DMT_Opportunity_Utils.parseDecimal(invalidValue);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertEquals(0, result, 'The method should return 0');
    }

    @isTest
    static void getOpportunityProductsMinAndMaxDatesTest() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        OpportunityLineItem oli = [SELECT Id, gf_initial_date__c, gf_maturity_date__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];

        Map<String, Object> inputMap = new Map<String, Object>{ 'recordId' => opp.Id };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Opportunity_Utils.getOpportunityProductsMinAndMaxDates(inputMap, outMap, options);
        Test.stopTest();

        System.assertNotEquals(null, result, 'A result was expected');
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
    @IsTest
    static void testCreateProductsOpportunity_False() {
        Product2 prod1 = [SELECT Id FROM Product2 LIMIT 1];

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        List<Object> products = new List<Object>{ prod1.Id };
        Object oppId = opp.Id;

        Test.startTest();
        Map<String, Object> result = DMT_Opportunity_Utils.createProductsOpportunity(products, oppId);
        Test.stopTest();

        System.assertEquals(false, result.get('created'), 'Debería devolver created = true');

        
    }


}