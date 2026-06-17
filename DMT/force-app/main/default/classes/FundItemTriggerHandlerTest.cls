@IsTest
private class FundItemTriggerHandlerTest {

    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    private static ONB_Onboarding__c createOnboarding(Id accountId) {
        ONB_Onboarding__c onboarding = new ONB_Onboarding__c(
            Name = 'Test Onboarding',
            Client__c = accountId
        );
        insert onboarding;
        return onboarding;
    }

    // ============================================================
    // afterInsert tests
    // ============================================================

    @IsTest
    static void testAfterInsert_createsDefaultSettlementLinesForNewFund() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);

        Test.startTest();
        ONB_Fund_Item__c fund = new ONB_Fund_Item__c(
            ONB_FundName__c = 'Fund A',
            ONB_Fund_Type__c = 'Pension funds',
            OnboardingId__c = onboarding.Id
        );
        insert fund;
        Test.stopTest();

        List<ONB_Line__c> lines = [
            SELECT Id, Line_Type__c, ONB_Line_Subtype__c, ONB_Settlement_line_limit__c, IsAutomatic__c
            FROM ONB_Line__c
            WHERE FundItemId__c = :fund.Id
            ORDER BY ONB_Line_Subtype__c ASC
        ];

        System.assertEquals(2, lines.size(), 'Should create DVP and Free Delivery lines by default');
        System.assertEquals('LC_DVP', lines[0].Line_Type__c);
        System.assertEquals('DVP', lines[0].ONB_Line_Subtype__c);
        System.assertEquals(500000, lines[0].ONB_Settlement_line_limit__c);
        System.assertEquals(false, lines[0].IsAutomatic__c);

        System.assertEquals('LC_DVP', lines[1].Line_Type__c);
        System.assertEquals('Free Delivery', lines[1].ONB_Line_Subtype__c);
        System.assertEquals(500000, lines[1].ONB_Settlement_line_limit__c);
        System.assertEquals(true, lines[1].IsAutomatic__c);
    }

    @IsTest
    static void testAfterInsert_doesNotDuplicateDefaultLinesIfAlreadyExist() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);

        // Insert fund (trigger fires and creates the DVP line)
        ONB_Fund_Item__c fund = new ONB_Fund_Item__c(
            ONB_FundName__c = 'Fund B',
            ONB_Fund_Type__c = 'Pension funds',
            OnboardingId__c = onboarding.Id
        );
        insert fund;

        // Call afterInsert again manually simulating a second insert scenario
        Test.startTest();
        FundItemTriggerHandler.afterInsert(new List<ONB_Fund_Item__c>{ fund });
        Test.stopTest();

        List<ONB_Line__c> lines = [
            SELECT Id, ONB_Line_Subtype__c
            FROM ONB_Line__c
            WHERE FundItemId__c = :fund.Id
            AND ONB_Line_Subtype__c IN ('DVP', 'Free Delivery')
        ];

        Integer dvpCount = 0;
        Integer freeDeliveryCount = 0;
        for (ONB_Line__c line : lines) {
            if (line.ONB_Line_Subtype__c == 'DVP') dvpCount++;
            if (line.ONB_Line_Subtype__c == 'Free Delivery') freeDeliveryCount++;
        }

        System.assertEquals(1, dvpCount, 'Should not create duplicate DVP line');
        System.assertEquals(1, freeDeliveryCount, 'Should not create duplicate Free Delivery line');
    }

    @IsTest
    static void testAfterInsert_bulkCreatesDefaultLinesForMultipleFunds() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);

        List<ONB_Fund_Item__c> funds = new List<ONB_Fund_Item__c>();
        for (Integer i = 0; i < 5; i++) {
            funds.add(new ONB_Fund_Item__c(
                ONB_FundName__c = 'Fund ' + i,
                ONB_Fund_Type__c = 'Pension funds',
                OnboardingId__c = onboarding.Id
            ));
        }

        Test.startTest();
        insert funds;
        Test.stopTest();

        List<ONB_Line__c> lines = [
            SELECT Id, FundItemId__c, ONB_Line_Subtype__c
            FROM ONB_Line__c
            WHERE FundItemId__c IN :new Map<Id, ONB_Fund_Item__c>(funds).keySet()
            AND ONB_Line_Subtype__c IN ('DVP', 'Free Delivery')
        ];

        Integer dvpCount = 0;
        Integer freeDeliveryCount = 0;
        for (ONB_Line__c line : lines) {
            if (line.ONB_Line_Subtype__c == 'DVP') dvpCount++;
            if (line.ONB_Line_Subtype__c == 'Free Delivery') freeDeliveryCount++;
        }

        System.assertEquals(10, lines.size(), 'Each fund should have two default settlement lines');
        System.assertEquals(5, dvpCount, 'Each fund should have one DVP line');
        System.assertEquals(5, freeDeliveryCount, 'Each fund should have one Free Delivery line');
    }

    @IsTest
    static void testAfterInsert_withNullList_doesNotThrow() {
        Test.startTest();
        FundItemTriggerHandler.afterInsert(null);
        Test.stopTest();
        System.assert(true, 'No exception should be thrown for null input');
    }

    @IsTest
    static void testAfterInsert_withEmptyList_doesNotThrow() {
        Test.startTest();
        FundItemTriggerHandler.afterInsert(new List<ONB_Fund_Item__c>());
        Test.stopTest();
        System.assert(true, 'No exception should be thrown for empty list');
    }

    // ============================================================
    // beforeDelete tests
    // ============================================================

    @IsTest
    static void testBeforeDelete_deletesRelatedLinesOnFundDeletion() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);

        ONB_Fund_Item__c fund = new ONB_Fund_Item__c(
            ONB_FundName__c = 'Fund C',
            ONB_Fund_Type__c = 'Pension funds',
            OnboardingId__c = onboarding.Id
        );
        insert fund;

        // Add extra lines beyond the two auto-created default lines
        insert new ONB_Line__c(
            FundItemId__c = fund.Id,
            Line_Type__c = 'LC_CRED',
            Amount__c = 100000,
            ONB_Currency__c = 'EUR',
            Maturity_Derivatives__c = '6M'
        );

        List<ONB_Line__c> linesBefore = [SELECT Id FROM ONB_Line__c WHERE FundItemId__c = :fund.Id];
        System.assertEquals(3, linesBefore.size(), 'Fund should have 3 lines before deletion');

        Test.startTest();
        delete fund;
        Test.stopTest();

        List<ONB_Line__c> linesAfter = [SELECT Id FROM ONB_Line__c WHERE FundItemId__c = :fund.Id];
        System.assertEquals(0, linesAfter.size(), 'All lines should be deleted when fund is deleted');
    }

    @IsTest
    static void testBeforeDelete_onlyDeletesLinesOfDeletedFund() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);

        ONB_Fund_Item__c fundToDelete = new ONB_Fund_Item__c(
            ONB_FundName__c = 'Fund D',
            ONB_Fund_Type__c = 'Pension funds',
            OnboardingId__c = onboarding.Id
        );
        ONB_Fund_Item__c fundToKeep = new ONB_Fund_Item__c(
            ONB_FundName__c = 'Fund E',
            ONB_Fund_Type__c = 'Pension funds',
            OnboardingId__c = onboarding.Id
        );
        insert new List<ONB_Fund_Item__c>{ fundToDelete, fundToKeep };

        List<ONB_Line__c> keepLines = [SELECT Id FROM ONB_Line__c WHERE FundItemId__c = :fundToKeep.Id];
        Integer keepCount = keepLines.size();

        Test.startTest();
        delete fundToDelete;
        Test.stopTest();

        List<ONB_Line__c> deletedFundLines = [SELECT Id FROM ONB_Line__c WHERE FundItemId__c = :fundToDelete.Id];
        List<ONB_Line__c> keptFundLines = [SELECT Id FROM ONB_Line__c WHERE FundItemId__c = :fundToKeep.Id];

        System.assertEquals(0, deletedFundLines.size(), 'Lines of deleted fund should be removed');
        System.assertEquals(keepCount, keptFundLines.size(), 'Lines of kept fund should be untouched');
    }

    @IsTest
    static void testBeforeDelete_withNullList_doesNotThrow() {
        Test.startTest();
        FundItemTriggerHandler.beforeDelete(null);
        Test.stopTest();
        System.assert(true, 'No exception should be thrown for null input');
    }

    @IsTest
    static void testBeforeDelete_withEmptyList_doesNotThrow() {
        Test.startTest();
        FundItemTriggerHandler.beforeDelete(new List<ONB_Fund_Item__c>());
        Test.stopTest();
        System.assert(true, 'No exception should be thrown for empty list');
    }

    @IsTest
    static void testBeforeDelete_fundWithNoLines_doesNotThrow() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);

        ONB_Fund_Item__c fund = new ONB_Fund_Item__c(
            ONB_FundName__c = 'Fund F',
            ONB_Fund_Type__c = 'Pension funds',
            OnboardingId__c = onboarding.Id
        );
        insert fund;

        // Delete auto-created DVP line to simulate fund with no lines
        delete [SELECT Id FROM ONB_Line__c WHERE FundItemId__c = :fund.Id];

        Test.startTest();
        delete fund;
        Test.stopTest();

        System.assert(true, 'Deleting a fund with no lines should not throw');
    }
}