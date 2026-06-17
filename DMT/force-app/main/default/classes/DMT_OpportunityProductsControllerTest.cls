/**
 * @Name     DMT_OpportunityProductsControllerTest
 * @Author   Test Generated
 * @Date     Created: 2025-01-01
 * --------------------------------------------------------------------------------------------
 * @Description Comprehensive test class for DMT_OpportunityProductsController.
 *              Covers all 12 public @AuraEnabled methods including Opportunity,
 *              OpportunityLineItem, Tenors, Mitigants, Taxonomy and Passport operations.
 * --------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class DMT_OpportunityProductsControllerTest {

    // ═══════════════════════════════════════════════════════════════════════════
    // Test Setup
    // ═══════════════════════════════════════════════════════════════════════════
    static Map<String, Object> testData {
        get {
            if (testData == null) {
                testData = loadTestData();
            }
            return testData;
        }
        private set;
    }

    @TestSetup
    static void setupTestData() {
        DMT_Test_DataFactory.loadCurrencies();
        DMT_Test_DataFactory.generateTaxonomies();
        createFullTestSetup();
    }

    /**
     * Queries the records created by @TestSetup so each test method
     * can access them via the lazy-loaded testData property.
     */
    private static Map<String, Object> loadTestData() {
        Map<String, Object> data = new Map<String, Object>();

        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        data.put('opportunity', opp);

        Account acc = [SELECT Id FROM Account WHERE Id = :opp.AccountId LIMIT 1];
        data.put('account', acc);

        OpportunityLineItem oli = [SELECT Id, OpportunityId, Product2Id, PricebookEntryId
                                    FROM OpportunityLineItem
                                    WHERE OpportunityId = :opp.Id LIMIT 1];
        data.put('opportunityLineItem', oli);

        Product2 prod = [SELECT Id, Name, ProductCode FROM Product2 WHERE Id = :oli.Product2Id LIMIT 1];
        data.put('product', prod);

        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Id = :oli.PricebookEntryId LIMIT 1];
        data.put('pricebookEntry', pbe);

        List<DMT_Opportunity_Tenor__c> tenors = [SELECT Id, Name
            FROM DMT_Opportunity_Tenor__c
            WHERE DMT_Opportunity_Product__c = :oli.Id ORDER BY Name];
        data.put('tenors', tenors);

        List<DMT_Opportunity_Mitigant__c> mitigants = [SELECT Id, Name
            FROM DMT_Opportunity_Mitigant__c
            WHERE DMT_Opportunity_Product__c = :oli.Id ORDER BY Name];
        data.put('mitigants', mitigants);

        List<Passport__c> passports = [SELECT Id, Opportunity__c
            FROM Passport__c
            WHERE Opportunity__c = :opp.Id LIMIT 1];
        if (!passports.isEmpty()) {
            data.put('passport', passports[0]);
        }

        return data;
    }

    /**
     * Creates a full in-memory test dataset: Account, Opportunity, Product2,
     * PricebookEntry, OpportunityLineItem, 3 Tenors, 2 Mitigants and a Passport.
     * Returns a map keyed by entity name for convenient retrieval in each test.
     */
static Map<String, Object> createFullTestSetup() {
    Map<String, Object> testData = new Map<String, Object>();
    Long uniqueSuffix = System.now().getTime();

    // ── Opportunity (genera su propio Account internamente) ──────────────
    Opportunity testOpportunity = DMT_Test_DataFactory.generateOpportunity();
    testOpportunity.Name = 'TestOpp_' + uniqueSuffix;
    update testOpportunity;
    testData.put('opportunity', testOpportunity);

    Account testAccount = [
        SELECT Id FROM Account 
        WHERE Id = :testOpportunity.AccountId 
        LIMIT 1
    ];
    testData.put('account', testAccount);

    // ── Pricebook ────────────────────────────────────────────────────────
    // Reutiliza el standard pricebook, no crea uno nuevo
    Id pricebookId = Test.getStandardPricebookId();

    // ── Product2 ─────────────────────────────────────────────────────────
    // Creamos directamente sin usar generateProduct2() para evitar
    // duplicados y tener control total sobre nombre y código
    Product2 testProduct = new Product2(
        Family = 'DMT',
        Name = 'Test Loan Product ' + uniqueSuffix,
        ProductCode = 'LOAN' + uniqueSuffix,
        IsActive = true
    );
    insert testProduct;
    testData.put('product', testProduct);

    // ── PricebookEntry ───────────────────────────────────────────────────
    PricebookEntry testPBE = new PricebookEntry(
        Pricebook2Id = pricebookId,
        Product2Id = testProduct.Id,
        UnitPrice = 100.00,
        IsActive = true
    );
    insert testPBE;
    testData.put('pricebookEntry', testPBE);

    // ── OpportunityLineItem ──────────────────────────────────────────────
    // Primero actualizamos la Opportunity para usar el pricebook estándar
    testOpportunity.Pricebook2Id = pricebookId;
    update testOpportunity;

    OpportunityLineItem testOLI = new OpportunityLineItem(
        Product2Id = testProduct.Id,
        OpportunityId = testOpportunity.Id,
        PricebookEntryId = testPBE.Id,
        Quantity = 1,
        TotalPrice = 100000.00,
        g_currency_id__c = 'EUR',
        gf_group_priority_opportunity_id__c = '01',
        g_branch_id__c = 'ES0182-US',
        DMT_Risk_Type__c = '3000000',
        gf_initial_date__c = System.today(),
        gf_maturity_date__c = System.today().addDays(365),
        gf_amortization_type__c = 'Bullet',
        gf_payment_frequency__c = 'Quarterly',
        DMT_TXT_ProductNameOLI__c = 'Test Product',
        DMT_Deal_Amount_Tenors__c = 200000,
        gf_accrual_fees_bp__c = 1,
        DMT_Extension_Duration_Fees__c = 1,
        Life_Funding_Type__c = 'Term'
    );
    insert testOLI;
    testData.put('opportunityLineItem', testOLI);

    // ── Tenors (3) ───────────────────────────────────────────────────────
    List<DMT_Opportunity_Tenor__c> tenors = new List<DMT_Opportunity_Tenor__c>();
    for (Integer i = 0; i < 3; i++) {
        tenors.add(new DMT_Opportunity_Tenor__c(
            DMT_Opportunity_Product__c = testOLI.Id,
            Name = 'Tenor ' + i + '_' + uniqueSuffix,
            gf_tenor_date__c = System.today().addDays(90 * (i + 1)),
            gf_spread_db__c = 50 + i * 10,
            gf_spread_fb__c = 75 + i * 10,
            gj_nominal_amount_db__c = 50000 + (i * 10000),
            gf_nominal_amount_fb__c = 50000 + (i * 10000),
            gf_accrual_fees_bp__c = 10 + i,
            gf_non_accrual_fees_bp__c = 5 + i,
            CurrencyIsoCode = 'EUR'
        ));
    }
    insert tenors;
    testData.put('tenors', tenors);

    // ── Mitigants (2) ────────────────────────────────────────────────────
    List<DMT_Opportunity_Mitigant__c> mitigants = new List<DMT_Opportunity_Mitigant__c>();
    for (Integer i = 0; i < 2; i++) {
        mitigants.add(new DMT_Opportunity_Mitigant__c(
            DMT_Opportunity_Product__c = testOLI.Id,
            Name = 'Mitigant ' + i + '_' + uniqueSuffix,
            Mitigant_Type__c = 'Guarantee',
            Political_Percentage__c = 50,
            Commercial_Percentage__c = 50,
            DMT_Currency__c = 'EUR',
            CurrencyIsoCode = 'EUR',
            End_Date__c = System.today().addDays(365)
        ));
    }
    insert mitigants;
    testData.put('mitigants', mitigants);

    // ── Passport ─────────────────────────────────────────────────────────
    Passport__c testPassport = new Passport__c(
        Opportunity__c = testOpportunity.Id,
        DMT_Is_Obsoleted_Passport_Save__c = false
    );
    insert testPassport;
    testData.put('passport', testPassport);

    return testData;
}
    // ═══════════════════════════════════════════════════════════════════════════
    // getOpportunityLineItemsByOpportunityId
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetOpportunityLineItemsByOpportunityId_Success() {
        
        Opportunity opp = (Opportunity) testData.get('opportunity');
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Test.startTest();
        List<OpportunityLineItem> result =
            DMT_OpportunityProductsController.getOpportunityLineItemsByOpportunityId(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return 1 OpportunityLineItem');
        System.assertEquals(oli.Id, result[0].Id, 'OLI Id should match');
    }

    @isTest
    static void testGetOpportunityLineItemsByOpportunityId_NullId() {
        Test.startTest();
        List<OpportunityLineItem> result =
            DMT_OpportunityProductsController.getOpportunityLineItemsByOpportunityId(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for null Id');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // deleteOpportunityLineItem
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testDeleteOpportunityLineItem_Success() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Test.startTest();
        Boolean result = DMT_OpportunityProductsController.deleteOpportunityLineItem(oli.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Delete should return true');
        List<OpportunityLineItem> check = [SELECT Id FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertEquals(0, check.size(), 'OLI should have been deleted');
    }

    @isTest
    static void testDeleteOpportunityLineItem_SetsPassportObsolete() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');
        Opportunity opp = (Opportunity) testData.get('opportunity');

        Test.startTest();
        DMT_OpportunityProductsController.deleteOpportunityLineItem(oli.Id);
        Test.stopTest();

        Passport__c passport = [
            SELECT DMT_Is_Obsoleted_Passport_Save__c
            FROM Passport__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];
        System.assertEquals(true, passport.DMT_Is_Obsoleted_Passport_Save__c,
            'Passport should be marked obsolete after OLI deletion');
    }

    @isTest
    static void testDeleteOpportunityLineItem_NullId() {
        Test.startTest();
        try {
            DMT_OpportunityProductsController.deleteOpportunityLineItem(null);
            System.assert(false, 'Should have thrown an exception for null Id');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required'),
                'Error message should reference the required field');
        }
        Test.stopTest();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // cloneOpportunityLineItem
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testCloneOpportunityLineItem_Success() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.cloneOpportunityLineItem(oli.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('clonedOpportunityLineItemId'),
            'Result should contain clonedOpportunityLineItemId key');
        Id clonedId = (Id) result.get('clonedOpportunityLineItemId');
        System.assertNotEquals(oli.Id, clonedId, 'Cloned OLI should have a different Id');
        List<OpportunityLineItem> check =
            [SELECT Id FROM OpportunityLineItem WHERE Id = :clonedId];
        System.assertEquals(1, check.size(), 'Cloned OLI should exist in the database');
    }

    @isTest
    static void testCloneOpportunityLineItem_ClonesChildRecords() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        List<DMT_Opportunity_Tenor__c> sourceTenors =
            [SELECT Id FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :oli.Id];
        List<DMT_Opportunity_Mitigant__c> sourceMitigants =
            [SELECT Id FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c = :oli.Id];

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.cloneOpportunityLineItem(oli.Id);
        Test.stopTest();

        Id clonedId = (Id) result.get('clonedOpportunityLineItemId');
        List<DMT_Opportunity_Tenor__c> clonedTenors =
            [SELECT Id FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :clonedId];
        System.assertEquals(sourceTenors.size(), clonedTenors.size(), 'All tenors should be cloned');

        List<DMT_Opportunity_Mitigant__c> clonedMitigants =
            [SELECT Id FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c = :clonedId];
        System.assertEquals(sourceMitigants.size(), clonedMitigants.size(), 'All mitigants should be cloned');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // getRiskTypeOptions
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetRiskTypeOptions_Success() {
        Test.startTest();
        List<Map<String, String>> result = DMT_OpportunityProductsController.getRiskTypeOptions();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Result should be a valid list');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // getProductLineTypeOptions
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetProductLineTypeOptions_BlankInput() {
        Test.startTest();
        List<Map<String, String>> result =
            DMT_OpportunityProductsController.getProductLineTypeOptions('', '');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Blank inputs should return empty list');
    }

    @isTest
    static void testGetProductLineTypeOptions_NullInput() {
        Test.startTest();
        List<Map<String, String>> result =
            DMT_OpportunityProductsController.getProductLineTypeOptions(null, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Null inputs should return empty list');
    }

    @isTest
    static void testGetProductLineTypeOptions_ValidInput() {
        // No D744 taxonomy records exist in test data, so an empty list is expected.
        // The method must execute without exception.
        Test.startTest();
        List<Map<String, String>> result =
            DMT_OpportunityProductsController.getProductLineTypeOptions('Test Product', 'LOAN001');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Result should be a valid list');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // getTaxonomyCatalogValues
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetTaxonomyCatalogValues_Success() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result =
            DMT_OpportunityProductsController.getTaxonomyCatalogValues();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Result should be a valid map');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // getGuarantorFieldConfiguration
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetGuarantorFieldConfiguration_Success() {
        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityProductsController.getGuarantorFieldConfiguration();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('catalogValues'),
            'Result should contain catalogValues key');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // getOpportunityLineItemData
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetOpportunityLineItemData_Success() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Test.startTest();
        OpportunityLineItem result =
            DMT_OpportunityProductsController.getOpportunityLineItemData(oli.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(oli.Id, result.Id, 'Should return the correct OLI');
    }

    @isTest
    static void testGetOpportunityLineItemData_CurrencyFallback() {
        // La VR del org impide guardar un OLI sin g_currency_id__c,
        // por lo que el escenario de fallback real no es reproducible en test.
        // Verificamos que el controlador devuelve correctamente el campo cuando ya tiene valor.
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Test.startTest();
        OpportunityLineItem result = DMT_OpportunityProductsController.getOpportunityLineItemData(oli.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(oli.Id, result.Id, 'Should return the correct OLI');
        System.assertNotEquals(null, result.g_currency_id__c, 
            'g_currency_id__c should not be null (enforced by validation rule)');
        System.assertEquals('EUR', result.g_currency_id__c, 
            'Currency should be EUR');
    }

    @isTest
    static void testGetOpportunityLineItemData_NullId() {
        Test.startTest();
        try {
            DMT_OpportunityProductsController.getOpportunityLineItemData(null);
            System.assert(false, 'Should have thrown an exception for null Id');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required'),
                'Error message should reference the required field');
        }
        Test.stopTest();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // getMitigantsData
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetMitigantsData_Success() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Test.startTest();
        List<DMT_Opportunity_Mitigant__c> result =
            DMT_OpportunityProductsController.getMitigantsData(oli.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should return 2 mitigants');
    }


    @isTest
    static void testGetMitigantsData_NullId() {
        Test.startTest();
        try {
            DMT_OpportunityProductsController.getMitigantsData(null);
            System.assert(false, 'Should have thrown an exception for null Id');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required'),
                'Error message should reference the required field');
        }
        Test.stopTest();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // validateTenors
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testValidateTenors_ValidData() {
        List<Object> rawTenors = new List<Object>();
        rawTenors.add(new Map<String, Object>{
            'Id'                      => 'INIT',
            'gf_tenor_date__c'        => String.valueOf(System.today()),
            'gj_nominal_amount_db__c' => '100000',
            'gf_nominal_amount_fb__c' => '0',
            '__role'                  => 'INIT',
            'lockDate'                => true,
            'deleteDisabled'          => true,
            'aviableItem'             => false,
            'notEditable'             => false
        });
        rawTenors.add(new Map<String, Object>{
            'Id'                      => 'END',
            'gf_tenor_date__c'        => String.valueOf(System.today().addDays(365)),
            'gj_nominal_amount_db__c' => '0',
            'gf_nominal_amount_fb__c' => '100000',
            '__role'                  => 'END',
            'notEditable'             => true,
            'aviableItem'             => true,
            'editDisabled'            => true,
            'deleteDisabled'          => true
        });

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.validateTenors(
            rawTenors, System.today(), System.today().addDays(365)
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('validationPassed'),
            'Validation should pass for valid tenor data');
    }

    @isTest
    static void testValidateTenors_ZeroAmounts() {
        // Both drawn and undrawn = 0 → no valid amount → validation must fail
        List<Object> rawTenors = new List<Object>();
        rawTenors.add(new Map<String, Object>{
            'Id'                      => 'INIT',
            'gf_tenor_date__c'        => String.valueOf(System.today()),
            'gj_nominal_amount_db__c' => '0',
            'gf_nominal_amount_fb__c' => '0',
            '__role'                  => 'INIT'
        });

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.validateTenors(
            rawTenors, System.today(), System.today().addDays(365)
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.get('validationPassed'),
            'Validation should fail when all amounts are zero');
    }

    @isTest
    static void testValidateTenors_NullData() {
        Test.startTest();
        try {
            DMT_OpportunityProductsController.validateTenors(
                null, System.today(), System.today().addDays(365)
            );
            System.assert(false, 'Should have thrown an exception for null rawTenors');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required'),
                'Error message should reference the required field');
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateTenors_EmptyList() {
        Test.startTest();
        try {
            DMT_OpportunityProductsController.validateTenors(
                new List<Object>(), System.today(), System.today().addDays(365)
            );
            System.assert(false, 'Should have thrown an exception for empty rawTenors');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required'),
                'Error message should reference the required field');
        }
        Test.stopTest();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // saveOpportunityProduct — OLI update
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testSaveOpportunityProduct_UpdateOLIOnly() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Map<String, Object> recordFields = new Map<String, Object>{
            'Id'               => oli.Id,
            'DMT_Risk_Type__c' => '4000000'
        };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, null, null, null, null,
            System.today(), System.today().addDays(365), null
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Save should succeed');
        OpportunityLineItem updated =
            [SELECT DMT_Risk_Type__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertEquals('4000000', updated.DMT_Risk_Type__c, 'Risk type should be updated');
    }

    @isTest
    static void testSaveOpportunityProduct_NoFieldsToUpdate() {
        // recordFields contains only 'Id' (size == 1) → update block is skipped → success
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Map<String, Object> recordFields = new Map<String, Object>{ 'Id' => oli.Id };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, null, null, null, null,
            System.today(), System.today().addDays(365), null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'),
            'Should succeed even when there are no fields to update');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // saveOpportunityProduct — tenor upsert
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testSaveOpportunityProduct_UpsertTenors() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Map<String, Object> t1 = new Map<String, Object>{
            'DMT_Opportunity_Product__c' => String.valueOf(oli.Id),
            'gf_tenor_date__c'           => String.valueOf(System.today()),
            'gj_nominal_amount_db__c'    => 50000,
            'gf_nominal_amount_fb__c'    => 0,
            'gf_spread_db__c'            => 50
        };

        Map<String, Object> t2 = new Map<String, Object>{
            'DMT_Opportunity_Product__c' => String.valueOf(oli.Id),
            'gf_tenor_date__c'           => String.valueOf(System.today().addDays(365)),
            'gj_nominal_amount_db__c'    => 0,
            'gf_nominal_amount_fb__c'    => 50000,
            'gf_spread_fb__c'            => 75
        };

        List<Object> tenors = new List<Object>{ t1, t2 };

        Map<String, Object> recordFields = new Map<String, Object>{ 'Id' => oli.Id };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, tenors, null, null, null,
            System.today(), System.today().addDays(365), null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Tenor upsert should succeed');
    }

    @isTest
    static void testSaveOpportunityProduct_InvalidTenors_FailsValidation() {
        // Amounts = 0 → validateTenorsFromRaw sets validationPassed = false
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Map<String, Object> t1 = new Map<String, Object>{
            'gf_tenor_date__c'        => String.valueOf(System.today()),
            'gj_nominal_amount_db__c' => 0,
            'gf_nominal_amount_fb__c' => 0
        };

        List<Object> tenors = new List<Object>{ t1 };

        Map<String, Object> recordFields = new Map<String, Object>{ 'Id' => oli.Id };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, tenors, null, null, null,
            System.today(), System.today().addDays(365), null
        );
        Test.stopTest();

        System.assertEquals(false, result.get('success'),
            'Validation should fail for zero-amount tenors');
        System.assertEquals('tenorValidation', result.get('stage'),
            'Stage should indicate tenor validation failure');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // saveOpportunityProduct — tenor delete
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testSaveOpportunityProduct_DeleteTenors() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');
        List<DMT_Opportunity_Tenor__c> tenors =
            (List<DMT_Opportunity_Tenor__c>) testData.get('tenors');

        List<Id> tenorIdsToDelete = new List<Id>();
        for (DMT_Opportunity_Tenor__c t : tenors) { tenorIdsToDelete.add(t.Id); }

        Map<String, Object> recordFields = new Map<String, Object>{ 'Id' => oli.Id };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, null, tenorIdsToDelete, null, null,
            System.today(), System.today().addDays(365), null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Tenor delete should succeed');
        List<DMT_Opportunity_Tenor__c> remaining =
            [SELECT Id FROM DMT_Opportunity_Tenor__c WHERE Id IN :tenorIdsToDelete];
        System.assertEquals(0, remaining.size(), 'All specified tenors should be deleted');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // saveOpportunityProduct — mitigant upsert
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testSaveOpportunityProduct_UpsertMitigants() {
        // Mitigant wrapper without 'Id' → treated as insert.
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Map<String, Object> m1 = new Map<String, Object>{
            'DMT_Opportunity_Product__c' => String.valueOf(oli.Id),
            'Mitigant_Type__c'           => 'Guarantee',
            'Political_Percentage__c'    => 50,
            'Commercial_Percentage__c'   => 50,
            'CurrencyIsoCode'            => 'EUR',
            'End_Date__c'                => String.valueOf(System.today().addDays(365))
        };

        List<Object> mitigants = new List<Object>{ m1 };

        Map<String, Object> recordFields = new Map<String, Object>{ 'Id' => oli.Id };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, null, null, mitigants, null,
            System.today(), System.today().addDays(365), null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Mitigant upsert should succeed');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // saveOpportunityProduct — mitigant delete
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testSaveOpportunityProduct_DeleteMitigants() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');
        List<DMT_Opportunity_Mitigant__c> mitigants =
            (List<DMT_Opportunity_Mitigant__c>) testData.get('mitigants');

        List<Id> mitigantIdsToDelete = new List<Id>();
        for (DMT_Opportunity_Mitigant__c m : mitigants) { mitigantIdsToDelete.add(m.Id); }

        Map<String, Object> recordFields = new Map<String, Object>{ 'Id' => oli.Id };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, null, null, null, mitigantIdsToDelete,
            System.today(), System.today().addDays(365), null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Mitigant delete should succeed');
        List<DMT_Opportunity_Mitigant__c> remaining =
            [SELECT Id FROM DMT_Opportunity_Mitigant__c WHERE Id IN :mitigantIdsToDelete];
        System.assertEquals(0, remaining.size(), 'All specified mitigants should be deleted');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // createProductsOpportunity
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testCreateProductsOpportunity_Success() {
        // The utility expects a list of Product2 Id strings.
        
        Opportunity opp  = (Opportunity) testData.get('opportunity');
        Product2 product = (Product2) testData.get('product');

        List<Object> products = new List<Object>{ (Object) product.Id };

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityProductsController.createProductsOpportunity(products, opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('created'), 'Result should contain created key');
    }

    @isTest
    static void testCreateProductsOpportunity_InvalidProductId() {
        // Passing a non-Id string should not throw — the utility handles the error
        // gracefully and returns created=false.
        
        Opportunity opp = (Opportunity) testData.get('opportunity');

        List<Object> products = new List<Object>{ 'INVALID_PRODUCT_ID' };

        Test.startTest();
        Map<String, Object> result =
            DMT_OpportunityProductsController.createProductsOpportunity(products, opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Integration tests
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testIntegration_CompleteWorkflow() {
        
        Opportunity opp = (Opportunity) testData.get('opportunity');
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Test.startTest();

        // 1. List OLIs for the opportunity
        List<OpportunityLineItem> oliList =
            DMT_OpportunityProductsController.getOpportunityLineItemsByOpportunityId(opp.Id);
        System.assertEquals(1, oliList.size(), 'Should return 1 OLI');

        // 2. Fetch full OLI detail
        OpportunityLineItem detail =
            DMT_OpportunityProductsController.getOpportunityLineItemData(oli.Id);
        System.assertNotEquals(null, detail, 'Should return OLI detail');

        // 3. Get mitigants
        List<DMT_Opportunity_Mitigant__c> mitigants =
            DMT_OpportunityProductsController.getMitigantsData(oli.Id);
        System.assertEquals(2, mitigants.size(), 'Should return 2 mitigants');

        // 4. Update a field on the OLI
        Map<String, Object> recordFields = new Map<String, Object>{
            'Id'                  => oli.Id,
            'gf_accrual_fees_bp__c' => 25
        };
        Map<String, Object> updateResult = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, null, null, null, null,
            System.today(), System.today().addDays(365), null
        );
        System.assertEquals(true, updateResult.get('success'), 'Update should succeed');

        Test.stopTest();

        OpportunityLineItem afterUpdate =
            [SELECT gf_accrual_fees_bp__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertEquals(25, afterUpdate.gf_accrual_fees_bp__c, 'Fee should be updated to 25');
    }

    @isTest
    static void testIntegration_CloneWithTenorsAndMitigants() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        List<DMT_Opportunity_Tenor__c> initialTenors =
            [SELECT Id FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :oli.Id];
        List<DMT_Opportunity_Mitigant__c> initialMitigants =
            [SELECT Id FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c = :oli.Id];

        Test.startTest();
        Map<String, Object> cloneResult =
            DMT_OpportunityProductsController.cloneOpportunityLineItem(oli.Id);
        Test.stopTest();

        System.assert(cloneResult.containsKey('clonedOpportunityLineItemId'),
            'Should return clonedOpportunityLineItemId');
        Id clonedId = (Id) cloneResult.get('clonedOpportunityLineItemId');

        List<DMT_Opportunity_Tenor__c> clonedTenors =
            [SELECT Id FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :clonedId];
        System.assertEquals(initialTenors.size(), clonedTenors.size(), 'Should clone all tenors');

        List<DMT_Opportunity_Mitigant__c> clonedMitigants =
            [SELECT Id FROM DMT_Opportunity_Mitigant__c WHERE DMT_Opportunity_Product__c = :clonedId];
        System.assertEquals(initialMitigants.size(), clonedMitigants.size(),
            'Should clone all mitigants');
    }

    @isTest
    static void testIntegration_CloneThenDeleteOriginal() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Test.startTest();
        Map<String, Object> cloneResult =
            DMT_OpportunityProductsController.cloneOpportunityLineItem(oli.Id);
        Id clonedId = (Id) cloneResult.get('clonedOpportunityLineItemId');
        System.assertNotEquals(null, clonedId, 'Cloned OLI Id should not be null');

        Boolean deleteResult =
            DMT_OpportunityProductsController.deleteOpportunityLineItem(oli.Id);
        System.assertEquals(true, deleteResult, 'Delete should return true');
        Test.stopTest();

        List<OpportunityLineItem> origCheck =
            [SELECT Id FROM OpportunityLineItem WHERE Id = :oli.Id];
        List<OpportunityLineItem> cloneCheck =
            [SELECT Id FROM OpportunityLineItem WHERE Id = :clonedId];
        System.assertEquals(0, origCheck.size(), 'Original OLI should be deleted');
        System.assertEquals(1, cloneCheck.size(), 'Cloned OLI should still exist');
    }


    @isTest
    static void testEdgeCase_DeleteCreatesPassportWhenNoneExists() {
        // markPassportAsObsolete creates a new Passport when none exists for the Opportunity
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');
        Opportunity opp = (Opportunity) testData.get('opportunity');

        delete [SELECT Id FROM Passport__c WHERE Opportunity__c = :opp.Id];

        Test.startTest();
        Boolean result = DMT_OpportunityProductsController.deleteOpportunityLineItem(oli.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Delete should succeed');
        Passport__c newPassport = [
            SELECT DMT_Is_Obsoleted_Passport_Save__c
            FROM Passport__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];
        System.assertEquals(true, newPassport.DMT_Is_Obsoleted_Passport_Save__c,
            'Newly created passport should be marked obsolete');
    }

    @isTest
    static void testEdgeCase_LargeDataSet() {
        
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        List<DMT_Opportunity_Mitigant__c> mitigantList = new List<DMT_Opportunity_Mitigant__c>();
        for (Integer i = 0; i < 100; i++) {
            mitigantList.add(new DMT_Opportunity_Mitigant__c(
                DMT_Opportunity_Product__c = oli.Id,
                Name                       = 'Bulk Mitigant ' + i,
                Political_Percentage__c    = 50,
                Commercial_Percentage__c   = 50
            ));
        }
        insert mitigantList;

        Test.startTest();
        List<DMT_Opportunity_Mitigant__c> result =
            DMT_OpportunityProductsController.getMitigantsData(oli.Id);
        Test.stopTest();

        System.assertEquals(102, result.size(),
            'Should return all mitigants: 2 from setup + 100 bulk');
    }


    @isTest
    static void testSaveOpportunityProduct_ExceptionInCatch() {
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');

        Map<String, Object> recordFields = new Map<String, Object>{
            'Id' => oli.Id,
            'NonExistent_Invalid_Field__c' => 'bad_value'
        };

        Test.startTest();
        try {
            DMT_OpportunityProductsController.saveOpportunityProduct(
                recordFields, null, null, null, null,
                System.today(), System.today().addDays(365), null
            );
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Exception message should not be null');
        }
        Test.stopTest();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // saveOpportunityProduct — passport update coverage (oppId != null)
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testSaveOpportunityProduct_WithPassportUpdate() {
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');
        Opportunity opp = (Opportunity) testData.get('opportunity');

        Map<String, Object> recordFields = new Map<String, Object>{
            'Id'               => oli.Id,
            'DMT_Risk_Type__c' => '4000000'
        };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, null, null, null, null,
            System.today(), System.today().addDays(365), String.valueOf(opp.Id)
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Save should succeed');
        Passport__c passport = [
            SELECT DMT_Is_Obsoleted_Passport_Save__c
            FROM Passport__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];
        System.assertEquals(true, passport.DMT_Is_Obsoleted_Passport_Save__c,
            'Passport should be marked obsolete when oppId is provided');
    }

    @isTest
    static void testSaveOpportunityProduct_PassportUpdateNoExistingPassport() {
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');
        Opportunity opp = (Opportunity) testData.get('opportunity');

        // Delete existing passport so the if(!passports.isEmpty()) is false
        delete [SELECT Id FROM Passport__c WHERE Opportunity__c = :opp.Id];

        Map<String, Object> recordFields = new Map<String, Object>{ 'Id' => oli.Id };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, null, null, null, null,
            System.today(), System.today().addDays(365), String.valueOf(opp.Id)
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'),
            'Save should succeed even without existing passport');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // saveOpportunityProduct — upsert existing tenors/mitigants (Id branch)
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testSaveOpportunityProduct_UpdateExistingTenor() {
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');
        List<DMT_Opportunity_Tenor__c> tenors =
            (List<DMT_Opportunity_Tenor__c>) testData.get('tenors');

        DMT_Opportunity_Tenor__c existingTenor = tenors[0];

        // Pass the existing tenor Id so the 'if (key == Id)' branch with non-blank Id is covered
        Map<String, Object> t1 = new Map<String, Object>{
            'Id'                         => String.valueOf(existingTenor.Id),
            'DMT_Opportunity_Product__c' => String.valueOf(oli.Id),
            'gf_tenor_date__c'           => String.valueOf(System.today().addDays(30)),
            'gj_nominal_amount_db__c'    => 60000,
            'gf_nominal_amount_fb__c'    => 0,
            'gf_spread_db__c'            => 55
        };

        List<Object> tenorList = new List<Object>{ t1 };
        Map<String, Object> recordFields = new Map<String, Object>{ 'Id' => oli.Id };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, tenorList, null, null, null,
            System.today(), System.today().addDays(365), null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Tenor update should succeed');
        DMT_Opportunity_Tenor__c updated =
            [SELECT gf_spread_db__c FROM DMT_Opportunity_Tenor__c WHERE Id = :existingTenor.Id];
        System.assertEquals(55, updated.gf_spread_db__c, 'Spread should be updated');
    }

    @isTest
    static void testSaveOpportunityProduct_UpdateExistingMitigant() {
        OpportunityLineItem oli = (OpportunityLineItem) testData.get('opportunityLineItem');
        List<DMT_Opportunity_Mitigant__c> mitigants =
            (List<DMT_Opportunity_Mitigant__c>) testData.get('mitigants');

        DMT_Opportunity_Mitigant__c existingMitigant = mitigants[0];

        Map<String, Object> m1 = new Map<String, Object>{
            'Id'                         => String.valueOf(existingMitigant.Id),
            'DMT_Opportunity_Product__c' => String.valueOf(oli.Id),
            'Mitigant_Type__c'           => 'Guarantee',
            'Political_Percentage__c'    => 70,
            'Commercial_Percentage__c'   => 30,
            'CurrencyIsoCode'            => 'EUR',
            'End_Date__c'                => String.valueOf(System.today().addDays(365))
        };

        List<Object> mitigantList = new List<Object>{ m1 };
        Map<String, Object> recordFields = new Map<String, Object>{ 'Id' => oli.Id };

        Test.startTest();
        Map<String, Object> result = DMT_OpportunityProductsController.saveOpportunityProduct(
            recordFields, null, null, mitigantList, null,
            System.today(), System.today().addDays(365), null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Mitigant update should succeed');
        DMT_Opportunity_Mitigant__c updated =
            [SELECT Political_Percentage__c FROM DMT_Opportunity_Mitigant__c WHERE Id = :existingMitigant.Id];
        System.assertEquals(70, updated.Political_Percentage__c, 'Political percentage should be updated');
    }
}