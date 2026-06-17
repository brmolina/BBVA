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

    @isTest
    static void testGetComparisonAccount_FoundParentGroup() {
        Account sourceAccount = new Account(
            Name = 'Source Subsidiary',
            DES_Structure_Type__c = 'Subsidiary'
        );
        insert sourceAccount;

        Account groupAccount = new Account(
            Name = 'Parent Group',
            DES_Structure_Type__c = 'Group',
            Geographical_Footprint_desc__c = 'Test footprint'
        );
        insert groupAccount;

        insert new AMH_GBL_Account_Relationship__c(
            AMH_Vision__c = 'Riesgos',
            AMH_Parent_Account__c = groupAccount.Id,
            AMH_Child_Account__c = sourceAccount.Id
        );

        Map<String, Object> inputMap = new Map<String, Object>{'oppAccountId' => sourceAccount.Id};
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Opportunity_Utils.getComparisonAccount(inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals(true, result.get('foundComparisonAccount'), 'Debe encontrar cuenta de comparación');
        System.assertEquals(groupAccount.Id, result.get('comparisonAccountId'), 'El Id de la cuenta de comparación no es correcto');
        System.assertEquals('Group', result.get('comparisonAccountType'), 'El tipo de cuenta de comparación debería ser Group');
        System.assertEquals(sourceAccount.Id, result.get('sourceAccountId'), 'El sourceAccountId no coincide');
        System.assertEquals('Subsidiary', result.get('sourceAccountType'), 'El tipo de cuenta origen debería ser Subsidiary');
    }

    @isTest
    static void testGetComparisonAccount_GroupUsesItself() {
        Account groupAccount = new Account(
            Name = 'Valid Group',
            DES_Structure_Type__c = 'Group',
            Industry_Overview_desc__c = 'Industry overview test'
        );
        insert groupAccount;

        Map<String, Object> inputMap = new Map<String, Object>{'oppAccountId' => groupAccount.Id};
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Opportunity_Utils.getComparisonAccount(inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals(true, result.get('foundComparisonAccount'), 'El grupo debería ser válido como cuenta de comparación');
        System.assertEquals(groupAccount.Id, result.get('comparisonAccountId'), 'El grupo debería compararse consigo mismo');
        System.assertEquals('Group', result.get('comparisonAccountType'), 'El tipo debería ser Group');
        System.assertEquals(groupAccount.Id, result.get('sourceAccountId'), 'El sourceAccountId debería ser el mismo grupo');
        System.assertEquals('Group', result.get('sourceAccountType'), 'El tipo origen debería ser Group');
    }

    @isTest
    static void testGetComparisonAccount_NotFound() {
        Account sourceAccount = new Account(
            Name = 'Subsidiary Without Valid Parent',
            DES_Structure_Type__c = 'Subsidiary'
        );
        insert sourceAccount;

        Account parentAccount = new Account(
            Name = 'Parent Without Data',
            DES_Structure_Type__c = 'Group'
        );
        insert parentAccount;

        insert new AMH_GBL_Account_Relationship__c(
            AMH_Vision__c = 'Riesgos',
            AMH_Parent_Account__c = parentAccount.Id,
            AMH_Child_Account__c = sourceAccount.Id
        );

        Map<String, Object> inputMap = new Map<String, Object>{'oppAccountId' => sourceAccount.Id};
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Opportunity_Utils.getComparisonAccount(inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals(false, result.get('foundComparisonAccount'), 'No debería encontrar cuenta de comparación');
        System.assertEquals(null, result.get('comparisonAccountId'), 'No debería haber Id de comparación');
        System.assertEquals(null, result.get('comparisonAccountType'), 'No debería haber tipo de comparación');
    }

    @isTest
    static void testGetComparisonAccount_MissingOppAccountId() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Opportunity_Utils.getComparisonAccount(inputMap, outMap, options);
        Test.stopTest();

        System.assertEquals(true, result.get('error'), 'Debe devolver error cuando falta oppAccountId');
        System.assert(result.containsKey('errorMessage'), 'Debe incluir errorMessage en la respuesta');
    }

    @isTest
    static void testHandleOppXSellGeneration_GroupSuccess() {
        TriggerBypass.setBypass();

        // 1. Setup Taxonomy Values & Relationships (H006 -> H007)
        DMT_Taxonomy_Values__c initialTax = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'H006', DMT_Value__c = 'ES0182', DMT_Active__c = true
        );
        insert initialTax;

        DMT_Taxonomy_Values__c finalTaxMatch = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'H007', DMT_Value__c = 'ES', DMT_Active__c = true
        );
        insert finalTaxMatch;

        // Use the factory and force the ID fields so the SOQL WHERE clause finds them
        DMT_Taxonomy_Relationship__c rel = DMT_Test_DataFactory.generateTaxonomyRelationship(initialTax, finalTaxMatch);
            rel.DMT_Id_Catalog_Initial__c = 'H006';
            rel.DMT_Id_Catalog_Final__c = 'H007';
            update rel;

        // 2. Setup Base Account with Comparison Data
        Account groupAccount = new Account(
            Name = 'Test Group Acc',
            DES_Structure_Type__c = 'Group',
            Industry_Overview_desc__c = 'Valid Data Presence'
        );
        insert groupAccount;

        // 3. Create Source X-Sell Records on Account (One matching Geo, one mismatching Geo)
        List<DMT_X_Sell__c> sourceXSells = new List<DMT_X_Sell__c>{
            new DMT_X_Sell__c(Account__c = groupAccount.Id, Booking_Geography__c = 'ES', XSELL_Value_CY__c = 500),
            new DMT_X_Sell__c(Account__c = groupAccount.Id, Booking_Geography__c = 'US', XSELL_Value_CY__c = 900)
        };
        insert sourceXSells;

        // 4. Create Opportunity linked to the Group Account
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = 'Test Group XSell Opp',
            AccountId = groupAccount.Id,
            RecordTypeId = oppRtId,
            StageName = 'Draft Opp',
            CloseDate = Date.today().addDays(30),
            DMT_Entity__c = 'ES0182',
            DMT_CUR_Notional_Amount__c = 100,
            DMT_CurrencyText__c = 'EUR',
            DMT_DATE_Initial_Date__c = Date.today(),
            DMT_DATE_Maturity_Date__c = Date.today().addDays(30)
        );
        insert opp;

        // 5. Fire Async handler explicitly to isolate execution boundaries
        DMT_OppXSellPayload payload = new DMT_OppXSellPayload(new Set<Id>{ opp.Id });
        
        Test.startTest();
        // Route through the dispatcher to ensure the new payload branch gets coverage
        DMT_AsyncDispatcher.dispatch(payload);
        Test.stopTest();

        // 6. Assertions
        List<DMT_X_Sell__c> generatedXSells = [SELECT Booking_Geography__c, XSELL_Value_CY__c, Account__c FROM DMT_X_Sell__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, generatedXSells.size(), 'Only the taxonomy-matched H007 record should be cloned');
        System.assertEquals('ES', generatedXSells[0].Booking_Geography__c, 'Cloned geography must match valid mapping');
        System.assertEquals(500, generatedXSells[0].XSELL_Value_CY__c, 'Financial metric values must map identically');
        System.assertEquals(null, generatedXSells[0].Account__c, 'Account lookup on cloned opportunity x-sells must be null');
    }

    @isTest
    static void testHandleOppXSellGeneration_SubsidiaryHierarchySuccess() {
        TriggerBypass.setBypass();

        // 1. Setup Taxonomy Records
        DMT_Taxonomy_Values__c initialTax = new DMT_Taxonomy_Values__c(DMT_Catalog__c = 'H006', DMT_Value__c = 'ES0182', DMT_Active__c = true);
        insert initialTax;
        DMT_Taxonomy_Values__c finalTax = new DMT_Taxonomy_Values__c(DMT_Catalog__c = 'H007', DMT_Value__c = 'ES', DMT_Active__c = true);
        insert finalTax;
        
        // Use the factory and force the ID fields so the SOQL WHERE clause finds them
        DMT_Taxonomy_Relationship__c rel = DMT_Test_DataFactory.generateTaxonomyRelationship(initialTax, finalTax);
            rel.DMT_Id_Catalog_Initial__c = 'H006';
            rel.DMT_Id_Catalog_Final__c = 'H007';
            update rel;

        // 2. Setup Hierarchy Accounts (Group with data -> Subsidiary placeholder)
        Account groupAccount = new Account(Name = 'Top Group', DES_Structure_Type__c = 'Group', Industry_Overview_desc__c = 'Valid Anchor Data');
        insert groupAccount;
        
        Account subAccount = new Account(Name = 'Child Subsidiary', DES_Structure_Type__c = 'Subsidiary');
        insert subAccount;

        insert new AMH_GBL_Account_Relationship__c(AMH_Vision__c = 'Riesgos', AMH_Parent_Account__c = groupAccount.Id, AMH_Child_Account__c = subAccount.Id);

        // 3. Seed parent X-Sell
        insert new DMT_X_Sell__c(Account__c = groupAccount.Id, Booking_Geography__c = 'ES', XSELL_Value_CY__c = 750);

        // 4. Target Opportunity explicitly linked to the Child Subsidiary
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = 'Test Child XSell Opp',
            AccountId = subAccount.Id,
            RecordTypeId = oppRtId,
            StageName = 'Draft Opp',
            CloseDate = Date.today().addDays(30),
            DMT_Entity__c = 'ES0182',
            DMT_CUR_Notional_Amount__c = 100,
            DMT_CurrencyText__c = 'EUR',
            DMT_DATE_Initial_Date__c = Date.today(),
            DMT_DATE_Maturity_Date__c = Date.today().addDays(30)
        );
        insert opp;

        DMT_OppXSellPayload payload = new DMT_OppXSellPayload(new Set<Id>{ opp.Id });
        
        Test.startTest();
        // Route through the dispatcher to ensure the new payload branch gets coverage
        DMT_AsyncDispatcher.dispatch(payload);
        Test.stopTest();

        // 5. Assertions proving 4-level ascent resolved successfully
        List<DMT_X_Sell__c> generatedXSells = [SELECT Booking_Geography__c, XSELL_Value_CY__c FROM DMT_X_Sell__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, generatedXSells.size(), 'Handler must walk hierarchy tree to extract parent source x-sells when child has no data');
        System.assertEquals(750, generatedXSells[0].XSELL_Value_CY__c, 'Financial tracking indicators must verify exactly');
    }
}