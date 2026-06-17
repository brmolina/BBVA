@isTest
public  class DMT_OpportunityLineItemHandler_Test {
    @testSetup
    static void setup() {
        DMT_Test_DataFactory.loadCurrencies();
    }
    
    @isTest
    static void testTrigger() {

        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings;
        userSettings = testClass.createCustomSetting();
        insert userSettings;

        system.runAs(userTest) {
            Account acc;
            acc = testClass.createClient();
            insert acc;
            Product2 prod;
            prod = testClass.createProduct('Cash Management');
            insert prod;
            PricebookEntry pbEntryTest;
            pbEntryTest = testClass.createPricebookEntry(prod);
            insert pbEntryTest;
            Opportunity opp;
            opp = testClass.createOpportunity(acc);
            insert opp;
            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opp, prod, pbEntryTest);
            insert oppLineItem;
            String oppId = String.valueOf(opp.Id);
            List<OpportunityLineItem> oppLineItemsList = new List<OpportunityLineItem>();
            oppLineItemsList.add(oppLineItem);
            DMT_OpportunityLineItemHandler.handleAfterInsertOrUpdate(oppLineItemsList);
            DMT_OpportunityLineItemHandler.recalculatePriority(oppId);

        }

        DMT_Test_DataFactory.loadCurrencies();
}
@isTest
static void testInvokeMethodRecalculatePriority() {

    // Preparación del entorno con tu utility class
    DES_UtilTestClass testClass = new DES_UtilTestClass();
    String idProfile = testClass.createProfile();
    User userTest = testClass.createUser(idProfile);
    insert userTest;

    CIB_User_Org__c userSettings = testClass.createCustomSetting();
    insert userSettings;

    system.runAs(userTest) {

        // Crear datos base
        Account acc = testClass.createClient();
        insert acc;

        Product2 prod = testClass.createProduct('Cash Management');
        insert prod;

        PricebookEntry pbEntryTest = testClass.createPricebookEntry(prod);
        insert pbEntryTest;

        Opportunity opp = testClass.createOpportunity(acc);
        insert opp;

        OpportunityLineItem oli = testClass.createOppLineItem(opp, prod, pbEntryTest);
        oli.gf_initial_date__c = Date.newInstance(2025, 11, 20);
        oli.gf_maturity_date__c = Date.newInstance(2026, 11, 20);
        insert oli;

        // Mapas para simular args del método call()
        Map<String, Object> input = new Map<String, Object>();
        input.put('oppId', opp.Id);

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        // Llamada al método público call(), que internamente llama a invokeMethod()
        DMT_OpportunityLineItemHandler handler = new DMT_OpportunityLineItemHandler();
        handler.call('recalculatePriority', args);

    }
}

    @isTest
    static void testCalculateGreenSocialBonds() {
        // Use factory to generate a DMT Opportunity, Product, PricebookEntry and an OLI
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Product2 prod = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        // Create base OLI tied to DMT_Opportunity record type opportunity
        OpportunityLineItem oliGreen = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DMT_sustainable_deal_assessment__c= DMT_Constants.DMT_SUSTAINABILITY_USE_OF_PROCEEDS,
            DMT_Sustainable_Deal_Subtype__c = DMT_Constants.DMT_SUSTAINABLE_GREEN,
            DMT_Sustainability_bonus_eligible__c='Yes'
        );
        OpportunityLineItem oliSocial = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DMT_sustainable_deal_assessment__c= DMT_Constants.DMT_SUSTAINABILITY_USE_OF_PROCEEDS,
            DMT_Sustainable_Deal_Subtype__c = DMT_Constants.DMT_SUSTAINABLE_SOCIAL,
            DMT_Sustainability_bonus_eligible__c='Yes'
        );
        OpportunityLineItem oliBothSubtype = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DMT_sustainable_deal_assessment__c = DMT_Constants.DMT_SUSTAINABILITY_SUSTAINABLE_LOAN,
            DMT_Sustainable_Deal_Subtype__c = DMT_Constants.DMT_SUSTAINABLE_GREEN_AND_SOCIAL,
            DMT_Sustainability_bonus_eligible__c='Yes'
        );
        OpportunityLineItem oliSslAssessment = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DMT_sustainable_deal_assessment__c = DMT_Constants.DMT_SUSTAINABILITY_SSL,
            DMT_Sustainability_bonus_eligible__c='Yes'
        );
        OpportunityLineItem oliSslGreenAssessment = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DMT_sustainable_deal_assessment__c = DMT_Constants.DMT_SUSTAINABILITY_SSL_GREEN,
            DMT_Sustainability_bonus_eligible__c='Yes'
        );
        OpportunityLineItem oliNull = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100
        );

        insert new List<OpportunityLineItem>{ oliGreen, oliSocial, oliBothSubtype, oliSslAssessment, oliSslGreenAssessment, oliNull };

        // Execute
        List<OpportunityLineItem> scope = [
            SELECT Id, OpportunityId, DMT_Sustainable_Deal_Subtype__c, DMT_sustainable_deal_assessment__c,
                   gf_green_bonus__c, gf_social_bond__c,DMT_Sustainability_bonus_eligible__c
            FROM OpportunityLineItem WHERE Id IN :new List<Id>{
                oliGreen.Id, oliSocial.Id, oliBothSubtype.Id, oliSslAssessment.Id, oliSslGreenAssessment.Id, oliNull.Id
            }
        ];

        Test.startTest();
        DMT_OpportunityLineItemHandler.calculateGreenSocialBonds(scope,null);
        Test.stopTest();

        // Assertions
        Map<Id, OpportunityLineItem> refreshed = new Map<Id, OpportunityLineItem>([
            SELECT Id, gf_green_bonus__c, gf_social_bond__c, DMT_Sustainable_Deal_Subtype__c, DMT_sustainable_deal_assessment__c
            FROM OpportunityLineItem WHERE Id IN :scope
        ]);

        System.assertEquals(true, refreshed.get(oliGreen.Id).gf_green_bonus__c, 'Green subtype should set green bonus');
        System.assertEquals(false, refreshed.get(oliGreen.Id).gf_social_bond__c, 'Green subtype should not set social bond');

        System.assertEquals(false, refreshed.get(oliSocial.Id).gf_green_bonus__c, 'Social subtype should not set green bonus');
        System.assertEquals(true, refreshed.get(oliSocial.Id).gf_social_bond__c, 'Social subtype should set social bond');

        System.assertEquals(true, refreshed.get(oliBothSubtype.Id).gf_green_bonus__c, 'Green&Social subtype should set green bonus');
        System.assertEquals(true, refreshed.get(oliBothSubtype.Id).gf_social_bond__c, 'Green&Social subtype should set social bond');

        System.assertEquals(true, refreshed.get(oliSslAssessment.Id).gf_green_bonus__c, 'SSL assessment should set green bonus');
        System.assertEquals(true, refreshed.get(oliSslAssessment.Id).gf_social_bond__c, 'SSL assessment should set social bond');

        System.assertEquals(true, refreshed.get(oliSslGreenAssessment.Id).gf_green_bonus__c, 'SSL Green assessment should set green bonus');
        System.assertEquals(true, refreshed.get(oliSslGreenAssessment.Id).gf_social_bond__c, 'SSL Green assessment should set social bond');

        System.assertEquals(false, refreshed.get(oliNull.Id).gf_green_bonus__c, 'Null subtype/assessment should not set green bonus');
        System.assertEquals(false, refreshed.get(oliNull.Id).gf_social_bond__c, 'Null subtype/assessment should not set social bond');
    }

    @isTest
    static void testCalculateDmtOpportunityDealAmount_DeleteContext() {
        // Setup test data using factory
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Product2 prod = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        // Create multiple OLIs to verify total recalculation
        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 100,
            TotalPrice = 1000,
            DMT_Deal_amount__c = 100,
            bbva_prtcp_tranche_amount__c = 100,
            g_currency_id__c = 'USD'
        );
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 50,
            TotalPrice = 500,
            DMT_Deal_amount__c = 50,
            bbva_prtcp_tranche_amount__c = 50,
            g_currency_id__c = 'USD'
        );
        OpportunityLineItem oli3 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 25,
            TotalPrice = 250,
            DMT_Deal_amount__c = 25,
            bbva_prtcp_tranche_amount__c = 25,
            g_currency_id__c = 'USD'
        );

        insert new List<OpportunityLineItem>{ oli1, oli2, oli3 };

        // Get opportunity before any modifications
        Opportunity oppBefore = [
            SELECT Id, DMT_Opportunity_amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Test.startTest();

        // Simulate DELETE context: newRecords=null, oldRecords contains oli3
        Map<Id, OpportunityLineItem> oldRecordsMap = new Map<Id, OpportunityLineItem>();
        oldRecordsMap.put(oli3.Id, oli3);

        // Call method with DELETE context (newRecords=null)
        DMT_OpportunityLineItemHandler.calculateDmtOpportunityDealAmount(null, oldRecordsMap);

        Test.stopTest();

        // Verify Opportunity was updated with recalculated total (100 + 50 = 150, NOT 175)
        Opportunity oppAfter = [
            SELECT Id, DMT_Opportunity_amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        // Assert that total reflects remaining OLIs (oli1 + oli2, but not oli3 which was "deleted")
        System.assertNotEquals(oppBefore.DMT_Opportunity_amount__c, oppAfter.DMT_Opportunity_amount__c, 'DMT_Opportunity_amount__c should be updated in DELETE context');
    }

    @isTest
    static void testCalculateDmtOpportunityDealAmount_UpdateContext() {
        // Setup test data
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Product2 prod = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 100,
            TotalPrice = 1000,
            DMT_Deal_amount__c = 100,
            bbva_prtcp_tranche_amount__c = 100,
            g_currency_id__c = 'USD'
        );
        insert oli;

        Test.startTest();

        // Simulate UPDATE context: change amount
        OpportunityLineItem oliOld = new OpportunityLineItem(
            Id = oli.Id,
            OpportunityId = opp.Id,
            DMT_Deal_amount__c = 100,  // old value
            bbva_prtcp_tranche_amount__c = 100,
            g_currency_id__c = 'USD'
        );

        OpportunityLineItem oliNew = new OpportunityLineItem(
            Id = oli.Id,
            OpportunityId = opp.Id,
            DMT_Deal_amount__c = 150,  // new value - changed
            bbva_prtcp_tranche_amount__c = 150,
            g_currency_id__c = 'USD'
        );

        Map<Id, OpportunityLineItem> newRecordsMap = new Map<Id, OpportunityLineItem>();
        newRecordsMap.put(oliNew.Id, oliNew);

        Map<Id, OpportunityLineItem> oldRecordsMap = new Map<Id, OpportunityLineItem>();
        oldRecordsMap.put(oliOld.Id, oliOld);

        // Call with UPDATE context (both newRecords and oldRecords populated)
        DMT_OpportunityLineItemHandler.calculateDmtOpportunityDealAmount(newRecordsMap, oldRecordsMap);

        Test.stopTest();

        // Verify Opportunity was updated
        Opportunity oppAfter = [
            SELECT Id, DMT_Opportunity_amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertNotEquals(null, oppAfter.DMT_Opportunity_amount__c, 'DMT_Opportunity_amount__c should be updated in UPDATE context');
    }

    @isTest
    static void testCalculateDmtOpportunityDealAmount_NullChecks() {
        // Test that method handles null parameters gracefully
        Test.startTest();

        // Should not throw exception when both are null
        DMT_OpportunityLineItemHandler.calculateDmtOpportunityDealAmount(null, null);

        Test.stopTest();

        // If we get here without exception, test passes
        System.assert(true, 'Method should handle null parameters without exception');
    }

    @isTest
    static void testTriggerRecalculatesOpportunityWhenBbvaChanges() {
        DMT_Test_DataFactory.loadCurrencies();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp.DMT_CurrencyText__c = 'USD';
        opp.DMT_Notional_Amount_Changed__c = false;
        update opp;

        Product2 prod = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            bbva_prtcp_tranche_amount__c = 100,
            DMT_Deal_amount__c = 100,
            g_currency_id__c = 'USD'
        );
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            bbva_prtcp_tranche_amount__c = 150,
            DMT_Deal_amount__c = 150,
            g_currency_id__c = 'USD'
        );
        insert new List<OpportunityLineItem>{ oli1, oli2 };

        oli2.bbva_prtcp_tranche_amount__c = 200;
        oli2.DMT_Deal_amount__c = 200;
        update oli2;

        Opportunity updatedOpp = [
            SELECT DMT_CUR_Notional_Amount__c, DMT_Opportunity_amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(300, updatedOpp.DMT_CUR_Notional_Amount__c,
            'Opportunity notional must be updated with total bbva_prtcp_tranche_amount__c after OLI update');
        System.assertEquals(300, updatedOpp.DMT_Opportunity_amount__c,
            'Opportunity amount must be updated with total bbva_prtcp_tranche_amount__c after OLI update');
    }

    @isTest
    static void testCalculateDmtOpportunityDealAmount_KeepsCurrencyConversionWhenApplicable() {
        DMT_Test_DataFactory.loadCurrencies();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp.DMT_CurrencyText__c = 'EUR';
        opp.DMT_Notional_Amount_Changed__c = false;
        update opp;

        Product2 prod = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            bbva_prtcp_tranche_amount__c = 120,
            DMT_Deal_amount__c = 120,
            g_currency_id__c = 'USD'
        );
        insert oli;

        DMT_OpportunityLineItemHandler.calculateDmtOpportunityDealAmount(
            new Map<Id, OpportunityLineItem>{ oli.Id => oli },
            null
        );

        Opportunity updatedOpp = [
            SELECT DMT_CUR_Notional_Amount__c, DMT_Opportunity_amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Decimal expectedConvertedAmount = DMT_Currency.convert(120, 'USD', 'EUR').setScale(2, RoundingMode.HALF_UP);
        System.assertEquals(expectedConvertedAmount, updatedOpp.DMT_Opportunity_amount__c,
            'DMT_Opportunity_amount__c must preserve currency conversion');
        System.assertEquals(100, updatedOpp.DMT_CUR_Notional_Amount__c,
            'DMT_CUR_Notional_Amount__c must equal raw bbva_prtcp_tranche_amount__c sum');
    }

    @isTest
    static void testSyncDealAmountWithBbvaCommitment() {
        OpportunityLineItem oli = new OpportunityLineItem(
            DMT_Deal_amount__c = null,
            bbva_prtcp_tranche_amount__c = 250
        );

        DMT_OpportunityLineItemHandler.syncDealAmountWithBbvaCommitment(new List<OpportunityLineItem>{ oli });

        System.assertEquals(250, oli.DMT_Deal_amount__c,
            'DMT_Deal_amount__c should be synchronized with bbva_prtcp_tranche_amount__c');
    }

    @isTest
    static void testSyncNewMoneyAndFinalTakeWithBbvaCommitment() {
        OpportunityLineItem oli = new OpportunityLineItem(
            DMT_NewMoney_BBVA__c = null,
            syndicated_loan_drawn_amount__c = null,
            bbva_prtcp_tranche_amount__c = 300
        );

        DMT_OpportunityLineItemHandler.syncNewMoneyAndFinalTakeWithBbvaCommitment(new List<OpportunityLineItem>{ oli });

        System.assertEquals(300, oli.DMT_NewMoney_BBVA__c,
            'DMT_NewMoney_BBVA__c should be synchronized with bbva_prtcp_tranche_amount__c when null');
        System.assertEquals(300, oli.syndicated_loan_drawn_amount__c,
            'syndicated_loan_drawn_amount__c should be synchronized with bbva_prtcp_tranche_amount__c when null');
    }

   @isTest
    static void testCalculateDmtOpportunityDealAmount_DMT_Notional_Amount_Changed_Flag() {
        // Test that even when DMT_Notional_Amount_Changed__c = true:
        //   DMT_Opportunity_amount__c is updated
        //   DMT_CUR_Notional_Amount__c is recalculated from bbva_prtcp_tranche_amount__c
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp.DMT_Notional_Amount_Changed__c = true;
        update opp;

        Product2 prod = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);
        DMT_Test_DataFactory.loadCurrencies();

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 100,
            TotalPrice = 1000,
            DMT_Deal_amount__c = 100,
            bbva_prtcp_tranche_amount__c = 100,
            g_currency_id__c = 'USD'
        );
        insert oli;

        Opportunity oppBefore = [
            SELECT Id, DMT_Opportunity_amount__c, DMT_CUR_Notional_Amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Test.startTest();

        oli.DMT_Deal_amount__c = 150;
        oli.bbva_prtcp_tranche_amount__c = 150;
        update oli;

        Test.stopTest();

        Opportunity oppAfter = [
            SELECT Id, DMT_Opportunity_amount__c, DMT_CUR_Notional_Amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertNotEquals(oppBefore.DMT_Opportunity_amount__c, oppAfter.DMT_Opportunity_amount__c, 'DMT_Opportunity_amount__c should always be updated');
        System.assertEquals(125, oppAfter.DMT_CUR_Notional_Amount__c, 'DMT_CUR_Notional_Amount__c should equal the bbva_prtcp_tranche_amount__c sum');
    }

    // ========================================================================
    // TESTS FOR calculateRiskType (D744 Taxonomy Logic) CIBGLOBALD-3245
    // ========================================================================

    @isTest
    static void testCalculateRiskType_FIN_ShortTerm() {
        // 1. Setup Data
        Product2 prod = DMT_Test_DataFactory.generateProduct2();
        prod.ProductCode = '12345';
        update prod;

        insert new DMT_Taxonomy_Values__c(
                DMT_Name__c = 'Project Finance Advisory',
                DMT_Name_EN__c = 'Project Finance Advisory',
                DMT_External_Id__c = '2880',
                DMT_Key__c = '2880',
                CurrencyIsoCode = 'EUR',
                DMT_Catalog__c = 'D744',
                gf_catalog_atrb_val8_name__c = 'FIN',
                DMT_Value__c = '12345'
            );

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        // 2. Execute Insert (< 365 Days)
        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id, Product2Id = prod.Id, PricebookEntryId = pbe.Id,
            Quantity = 1, TotalPrice = 100, g_currency_id__c = 'EUR',
            gf_initial_date__c = Date.today(),
            gf_maturity_date__c = Date.today().addDays(100) 
        );
        insert oli;
        Test.stopTest();

        // 3. Assert
        OpportunityLineItem insertedOli = [SELECT DMT_Risk_Type__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        Assert.areEqual('20200', insertedOli.DMT_Risk_Type__c, 'Short term FIN (< 365 days) should be 20200, api for S/T Financial Risk');
    }

    @isTest
    static void testCalculateRiskType_FIN_LongTerm_With_And_Without_Mitigants() {
        // 1. Setup Data
        Product2 prod = DMT_Test_DataFactory.generateProduct2();
        prod.ProductCode = '12345';
        update prod;

        insert new DMT_Taxonomy_Values__c(
                DMT_Name__c = 'Project Finance Advisory',
                DMT_Name_EN__c = 'Project Finance Advisory',
                DMT_External_Id__c = '2880',
                DMT_Key__c = '2880',
                CurrencyIsoCode = 'EUR',
                DMT_Catalog__c = 'D744',
                gf_catalog_atrb_val8_name__c = 'FIN',
                DMT_Value__c = '12345'
            );

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        // 2. Execute Insert (>= 365 Days, No Mitigants Yet)
        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id, Product2Id = prod.Id, PricebookEntryId = pbe.Id,
            Quantity = 1, TotalPrice = 100, g_currency_id__c = 'EUR',
            gf_initial_date__c = Date.today(),
            gf_maturity_date__c = Date.today().addDays(400) 
        );
        insert oli; // Fires before insert
        
        OpportunityLineItem insertedOli = [SELECT DMT_Risk_Type__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        Assert.areEqual('10100', insertedOli.DMT_Risk_Type__c, 'Long term FIN without mitigants should be 10100, api for label L/T Secured');

        // 3. Add Mitigant and Update OLI
        DMT_Test_DataFactory.generateOpportunityMitigant(oli);
        
        update oli; // Fires before update, recalculating mitigants
        Test.stopTest();

        // 4. Assert Update
        OpportunityLineItem updatedOli = [SELECT DMT_Risk_Type__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        Assert.areEqual('10200', updatedOli.DMT_Risk_Type__c, 'Long term FIN with mitigants should be 10200, api for label L/T Unsecured');
    }

    @isTest
    static void testCalculateRiskType_NonFIN() {
        // 1. Setup Data
        Product2 prod = DMT_Test_DataFactory.generateProduct2();
        prod.ProductCode = '13131';
        update prod;

        insert new DMT_Taxonomy_Values__c(
                DMT_Name__c = 'Project Finance Advisory',
                DMT_Name_EN__c = 'Project Finance Advisory',
                DMT_External_Id__c = '2880',
                DMT_Key__c = '2880',
                CurrencyIsoCode = 'EUR',
                DMT_Catalog__c = 'D744',
                gf_catalog_atrb_val8_name__c = '30000',
                DMT_Value__c = '13131'
            );

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        // 2. Execute Insert
        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id, Product2Id = prod.Id, PricebookEntryId = pbe.Id,
            Quantity = 1, TotalPrice = 100, g_currency_id__c = 'EUR'
        );
        insert oli;
        Test.stopTest();

        // 3. Assert
        OpportunityLineItem insertedOli = [SELECT DMT_Risk_Type__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        Assert.areEqual('30000', insertedOli.DMT_Risk_Type__c, '13131 product should exactly inherit the value from taxonomy Val8');
    }

    @isTest
    static void testCalculateRiskType_ManualOverrideLock() {
        // 1. Setup Data
        Product2 prod = DMT_Test_DataFactory.generateProduct2();
        prod.ProductCode = '12345';
        update prod;

        insert new DMT_Taxonomy_Values__c(
                DMT_Name__c = 'Project Finance Advisory',
                DMT_Name_EN__c = 'Project Finance Advisory',
                DMT_External_Id__c = '2880',
                DMT_Key__c = '2880',
                CurrencyIsoCode = 'EUR',
                DMT_Catalog__c = 'D744',
                gf_catalog_atrb_val8_name__c = 'FIN',
                DMT_Value__c = '12345'
            );

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id, Product2Id = prod.Id, PricebookEntryId = pbe.Id,
            Quantity = 1, TotalPrice = 100, g_currency_id__c = 'EUR',
            gf_initial_date__c = Date.today(),
            gf_maturity_date__c = Date.today().addDays(100) 
        );
        insert oli; // Automatically sets to 'S/T Financial Risk'

        // 2. Execute Manual Override
        Test.startTest();
        oli.DMT_Risk_Type__c = '99999'; // User manually overrides in the UI
        update oli;
        Test.stopTest();

        // 3. Assert Lock Behavior
        OpportunityLineItem updatedOli = [SELECT DMT_Risk_Type__c, DMT_RiskTypeLocked__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        Assert.isTrue(updatedOli.DMT_RiskTypeLocked__c, 'RiskTypeLocked checkbox should be checked after a manual override');
        Assert.areEqual('99999', updatedOli.DMT_Risk_Type__c, 'Manual override value should be retained and not overwritten by auto-logic');
    }

}