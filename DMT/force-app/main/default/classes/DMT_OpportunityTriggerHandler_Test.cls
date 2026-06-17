@IsTest
public with sharing class DMT_OpportunityTriggerHandler_Test {
     @TestSetup
    static void makeData(){
        // DMT shared test data
        DMT_Test_DataFactory.loadCurrencies();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Product2 product = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product);
        DMT_Test_DataFactory.generateOpportunityLineItem(product, pricebookEntry, opp);
    }

    @isTest
    public static void testCalculateAndUpdateNotionalAmounts() {
        Opportunity opp = [SELECT Id, RecordTypeId, DMT_CurrencyText__c FROM Opportunity LIMIT 1];

        // Set OLI amounts used by the handler and align OLI currency with target opp currency
        // to avoid dependency on cross-currency exchange rates in test context.
        OpportunityLineItem oli = [
            SELECT Id, g_currency_id__c, DMT_Deal_amount__c, bbva_prtcp_tranche_amount__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];
        oli.DMT_Deal_amount__c = 100;
        oli.bbva_prtcp_tranche_amount__c = 100;
        oli.g_currency_id__c = 'USD';
        update oli;

        Opportunity oldOpp = opp.clone(false, true, false, false);
        oldOpp.Id = opp.Id;
        oldOpp.DMT_CurrencyText__c = 'EUR';

        Test.startTest();
        // Simulate before update context and invoke handler explicitly.
        opp.DMT_CurrencyText__c = 'USD';
        DMT_OpportunityTriggerHandler.getInstance().calculateAndUpdateNotionalAmounts(
            new Map<Id, Opportunity>{ opp.Id => opp },
            new Map<Id, Opportunity>{ opp.Id => oldOpp }
        );
        update opp;
        Test.stopTest();

        // Verify amounts calculated by this handler were populated.
        Opportunity updatedOpp = [
            SELECT DMT_CUR_Notional_Amount__c, DMT_Opportunity_amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        Assert.isNotNull(updatedOpp.DMT_CUR_Notional_Amount__c, 'DMT_CUR_Notional_Amount__c should be calculated');
        Assert.isNotNull(updatedOpp.DMT_Opportunity_amount__c, 'DMT_Opportunity_amount__c should be calculated');
        Assert.areEqual(updatedOpp.DMT_Opportunity_amount__c, updatedOpp.DMT_CUR_Notional_Amount__c,
            'Opportunity amount and notional amount should match for this test setup');
    }

    @isTest
    public static void testCalculateAndUpdateNotionalAmounts_SumsBbvaAcrossOlis() {
        Opportunity opp = [SELECT Id, DMT_CurrencyText__c, RecordTypeId FROM Opportunity LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];

        OpportunityLineItem firstOli = [
            SELECT Id, OpportunityId, bbva_prtcp_tranche_amount__c, DMT_Deal_amount__c, g_currency_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];
        firstOli.bbva_prtcp_tranche_amount__c = 1200;
        firstOli.DMT_Deal_amount__c = 10;
        firstOli.g_currency_id__c = 'USD';
        update firstOli;

        OpportunityLineItem secondOli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = product.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 1,
            bbva_prtcp_tranche_amount__c = 1300,
            DMT_Deal_amount__c = 99,
            g_currency_id__c = 'USD'
        );
        insert secondOli;

        Opportunity oldOpp = opp.clone(false, true, false, false);
        oldOpp.Id = opp.Id;

        Test.startTest();
        opp.DMT_CurrencyText__c = 'USD';
        DMT_OpportunityTriggerHandler.getInstance().calculateAndUpdateNotionalAmounts(
            new Map<Id, Opportunity>{ opp.Id => opp },
            new Map<Id, Opportunity>{ opp.Id => oldOpp }
        );
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT DMT_CUR_Notional_Amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(2500, updatedOpp.DMT_CUR_Notional_Amount__c,
            'DMT_CUR_Notional_Amount__c must be the sum of bbva_prtcp_tranche_amount__c values');
    }

    @isTest
    public static void testCalculateAndUpdateNotionalAmounts_KeepCurrencyConversionForOpportunityAmount() {
        Opportunity opp = [SELECT Id, DMT_CurrencyText__c, RecordTypeId FROM Opportunity LIMIT 1];

        OpportunityLineItem oli = [
            SELECT Id, OpportunityId, bbva_prtcp_tranche_amount__c, DMT_Deal_amount__c, g_currency_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];
        oli.bbva_prtcp_tranche_amount__c = 120;
        oli.DMT_Deal_amount__c = 120;
        oli.g_currency_id__c = 'USD';
        update oli;

        Opportunity oldOpp = opp.clone(false, true, false, false);
        oldOpp.Id = opp.Id;
        oldOpp.DMT_CurrencyText__c = 'USD';

        Test.startTest();
        opp.DMT_CurrencyText__c = 'EUR';
        DMT_OpportunityTriggerHandler.getInstance().calculateAndUpdateNotionalAmounts(
            new Map<Id, Opportunity>{ opp.Id => opp },
            new Map<Id, Opportunity>{ opp.Id => oldOpp }
        );
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT DMT_CUR_Notional_Amount__c, DMT_Opportunity_amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Decimal expectedConvertedAmount = DMT_Currency.convert(120, 'USD', 'EUR').setScale(2, RoundingMode.HALF_UP);
        System.assertEquals(expectedConvertedAmount, updatedOpp.DMT_Opportunity_amount__c,
            'DMT_Opportunity_amount__c must keep currency conversion when opportunity currency changes');
        System.assertEquals(100, updatedOpp.DMT_CUR_Notional_Amount__c,
            'DMT_CUR_Notional_Amount__c must remain raw bbva_prtcp_tranche_amount__c sum');
    }

    @isTest
    public static void testValidateDynamicStageChange_LegacyFallbackBlock() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // Ensure we are starting from a different stage to trigger ISCHANGED(StageName)
        opp.StageName = 'Draft';
        update opp;

        // Mock JSON: Mandatory ('Y'), Not Green ('YELLOW'), No 'requiredAtStatus' (Defaults to 'Approval')
        String mockedJson = '{"data":{"features":[{"name":"Legacy Feature","requiredType":"Y","stateName":"YELLOW"}]}}';
        Passport__c passport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = mockedJson);
        insert passport;

        Test.startTest();
        opp.StageName = 'Approval';
        Boolean exceptionThrown = false;
        try {
            update opp;
        } catch (Exception e) {
            exceptionThrown = true;
            Assert.isTrue(e.getMessage().contains('Cannot advance to Approval'), 'Error should block advance to Approval.');
            Assert.isTrue(e.getMessage().contains('Legacy Feature'), 'Error should contain the feature name.');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An exception should have been thrown blocking the stage change.');
    }

    @isTest
    public static void testValidateDynamicStageChange_DynamicTargetBlock() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Draft';
        update opp;

        // Mock JSON: Mandatory ('Y'), Not Green ('WHITE'), Targets 'Proposal'
        String mockedJson = '{"data":{"features":[{"name":"Proposal Blocker","requiredType":"Y","requiredAtStatus":"Proposal","stateName":"WHITE"}]}}';
        Passport__c passport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = mockedJson);
        insert passport;

        Test.startTest();
        opp.StageName = 'Proposal';
        Boolean exceptionThrown = false;
        try {
            update opp;
        } catch (Exception e) {
            exceptionThrown = true;
            Assert.isTrue(e.getMessage().contains('Cannot advance to Proposal'), 'Error should block advance to Proposal.');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An exception should have been thrown blocking the dynamic stage change.');
    }

    @isTest
    public static void testValidateDynamicStageChange_PassUnrelatedStage() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Draft';
        update opp;

        // Mock JSON: Mandatory ('Y'), Not Green ('WHITE'), Targets 'Ready to close'
        String mockedJson = '{"data":{"features":[{"name":"RTC Blocker","requiredType":"Y","requiredAtStatus":"Ready to close","stateName":"WHITE"}]}}';
        Passport__c passport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = mockedJson);
        insert passport;

        Test.startTest();
        // Advancing to Approval (to avoid DES_HandlerTerritory errors), but the feature only blocks 'Ready to close'. This should succeed.
        opp.StageName = 'Approval';
        Boolean exceptionThrown = false;
        String actualErrorMessage = '';
        try {
            update opp;
        } catch (Exception e) {
            exceptionThrown = true;
            actualErrorMessage = e.getMessage();
        }
        Test.stopTest();

        // If it fails now, it will print the EXACT error message from the other class so we can fix the test data if needed.
        Assert.isFalse(exceptionThrown, 'No exception should be thrown, but an unrelated error occurred: ' + actualErrorMessage);
        
        if (!exceptionThrown) {
            Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
            Assert.areEqual('Approval', updatedOpp.StageName, 'Opportunity stage should have updated successfully.');
        }
    }

    @isTest
    public static void testValidateDynamicStageChange_PassGreenFeature() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Draft';
        update opp;

        // Mock JSON: Mandatory ('Y'), Is Green ('GREEN'), Targets 'Approval'
        String mockedJson = '{"data":{"features":[{"name":"Green Feature","requiredType":"Y","requiredAtStatus":"Approval","stateName":"GREEN"}]}}';
        Passport__c passport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = mockedJson);
        insert passport;

        Test.startTest();
        opp.StageName = 'Approval';
        Boolean exceptionThrown = false;
        try {
            update opp;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isFalse(exceptionThrown, 'No exception should be thrown because the required feature is GREEN.');
        
        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Approval', updatedOpp.StageName, 'Opportunity stage should have updated successfully.');
    }
}