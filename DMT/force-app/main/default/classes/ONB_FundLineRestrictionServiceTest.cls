@IsTest
private class ONB_FundLineRestrictionServiceTest {

    private static final String PRODUCT_FX_SPOT = 'FX Spot';
    private static final String PRODUCT_BONDS = 'Bonds';
    private static final String PRODUCT_REPO = 'Repo/Reverse Repo';
    private static final String PRODUCT_OTHER = 'Other Product';

    private static final String LINE_TYPE_CREDIT = 'LC_CRED';
    private static final String LINE_TYPE_REPO_NOTIONAL = 'LC_REPOS';

    private static String getAnyLegalEntityType() {
        List<Schema.PicklistEntry> values = ONB_Onboarding__c.Legal_Entity_Type__c.getDescribe().getPicklistValues();
        return values.isEmpty() ? null : values[0].getValue();
    }

    @TestSetup
    static void setupData() {
        insert new List<Product2>{
            new Product2(Name = PRODUCT_FX_SPOT, IsActive = true),
            new Product2(Name = PRODUCT_BONDS, IsActive = true),
            new Product2(Name = PRODUCT_REPO, IsActive = true),
            new Product2(Name = PRODUCT_OTHER, IsActive = true)
        };

        ONB_Onboarding__c onb = new ONB_Onboarding__c(
            Step__c = 'AML_KYC',
            Prioritization__c = 'High',
            Branch__c = 'Branch',
            Segment__c = 'Segment',
            Legal_Entity_Type__c = getAnyLegalEntityType(),
            Is_Sales_Person__c = 'Yes',
            Operation_in_Platform__c = 'Yes',
            Any_Master_Agreement__c = 'No'
        );
        insert onb;
    }

    @IsTest
    static void testRecalculateForFunds_NullAndEmptyInput_DoNothing() {
        Test.startTest();
        ONB_FundLineRestrictionService.recalculateForFunds(null);
        ONB_FundLineRestrictionService.recalculateForFunds(new Set<Id>());
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testRecalculateForFunds_DeleteCreditLine_WhenFundHasFxSpot() {
        ONB_Fund_Item__c fund = createFund(getTestOnboardingId());

        insert new ONB_Onboarding_Line__c(
            FundItemId__c = fund.Id,
            OnboardingId__c = fund.OnboardingId__c,
            Product2Id__c = getProductIdByName(PRODUCT_FX_SPOT)
        );

        ONB_Line__c creditLine = new ONB_Line__c(
            FundItemId__c = fund.Id,
            Line_Type__c = LINE_TYPE_CREDIT
        );
        insert creditLine;

        Test.startTest();
        ONB_FundLineRestrictionService.recalculateForFunds(new Set<Id>{ fund.Id });
        Test.stopTest();

        Integer remaining = [
            SELECT COUNT()
            FROM ONB_Line__c
            WHERE Id = :creditLine.Id
        ];
        System.assertEquals(0, remaining);
    }

    @IsTest
    static void testRecalculateForFunds_DeleteCreditLine_WhenFundHasBonds() {
        ONB_Fund_Item__c fund = createFund(getTestOnboardingId());

        insert new ONB_Onboarding_Line__c(
            FundItemId__c = fund.Id,
            OnboardingId__c = fund.OnboardingId__c,
            Product2Id__c = getProductIdByName(PRODUCT_BONDS)
        );

        ONB_Line__c creditLine = new ONB_Line__c(
            FundItemId__c = fund.Id,
            Line_Type__c = LINE_TYPE_CREDIT
        );
        insert creditLine;

        Test.startTest();
        ONB_FundLineRestrictionService.recalculateForFunds(new Set<Id>{ fund.Id });
        Test.stopTest();

        Integer remaining = [
            SELECT COUNT()
            FROM ONB_Line__c
            WHERE Id = :creditLine.Id
        ];
        System.assertEquals(0, remaining);
    }

    @IsTest
    static void testRecalculateForFunds_DeleteRepoNotional_WhenFundHasNoRepoProduct() {
        ONB_Fund_Item__c fund = createFund(getTestOnboardingId());

        insert new ONB_Onboarding_Line__c(
            FundItemId__c = fund.Id,
            OnboardingId__c = fund.OnboardingId__c,
            Product2Id__c = getProductIdByName(PRODUCT_OTHER)
        );

        ONB_Line__c repoLine = new ONB_Line__c(
            FundItemId__c = fund.Id,
            Line_Type__c = LINE_TYPE_REPO_NOTIONAL
        );
        insert repoLine;

        Test.startTest();
        ONB_FundLineRestrictionService.recalculateForFunds(new Set<Id>{ fund.Id });
        Test.stopTest();

        Integer remaining = [
            SELECT COUNT()
            FROM ONB_Line__c
            WHERE Id = :repoLine.Id
        ];
        System.assertEquals(0, remaining);
    }

    @IsTest
    static void testRecalculateForFunds_KeepRepoNotional_WhenFundHasRepoProduct() {
        ONB_Fund_Item__c fund = createFund(getTestOnboardingId());

        insert new ONB_Onboarding_Line__c(
            FundItemId__c = fund.Id,
            OnboardingId__c = fund.OnboardingId__c,
            Product2Id__c = getProductIdByName(PRODUCT_REPO)
        );

        ONB_Line__c repoLine = new ONB_Line__c(
            FundItemId__c = fund.Id,
            Line_Type__c = LINE_TYPE_REPO_NOTIONAL
        );
        insert repoLine;

        Test.startTest();
        ONB_FundLineRestrictionService.recalculateForFunds(new Set<Id>{ fund.Id });
        Test.stopTest();

        Integer remaining = [
            SELECT COUNT()
            FROM ONB_Line__c
            WHERE Id = :repoLine.Id
        ];
        System.assertEquals(1, remaining);
    }

    @IsTest
    static void testRecalculateForFunds_KeepCreditLine_WhenFundHasNoFxSpotOrBonds() {
        ONB_Fund_Item__c fund = createFund(getTestOnboardingId());

        insert new ONB_Onboarding_Line__c(
            FundItemId__c = fund.Id,
            OnboardingId__c = fund.OnboardingId__c,
            Product2Id__c = getProductIdByName(PRODUCT_REPO)
        );

        ONB_Line__c creditLine = new ONB_Line__c(
            FundItemId__c = fund.Id,
            Line_Type__c = LINE_TYPE_CREDIT
        );
        insert creditLine;

        Test.startTest();
        ONB_FundLineRestrictionService.recalculateForFunds(new Set<Id>{ fund.Id });
        Test.stopTest();

        Integer remaining = [
            SELECT COUNT()
            FROM ONB_Line__c
            WHERE Id = :creditLine.Id
        ];
        System.assertEquals(1, remaining);
    }

    @IsTest
    static void testRecalculateForFunds_DeleteOnlyInvalidLines() {
        ONB_Fund_Item__c fund = createFund(getTestOnboardingId());

        insert new List<ONB_Onboarding_Line__c>{
            new ONB_Onboarding_Line__c(
                FundItemId__c = fund.Id,
                OnboardingId__c = fund.OnboardingId__c,
                Product2Id__c = getProductIdByName(PRODUCT_FX_SPOT)
            ),
            new ONB_Onboarding_Line__c(
                FundItemId__c = fund.Id,
                OnboardingId__c = fund.OnboardingId__c,
                Product2Id__c = getProductIdByName(PRODUCT_REPO)
            )
        };

        ONB_Line__c creditLine = new ONB_Line__c(
            FundItemId__c = fund.Id,
            Line_Type__c = LINE_TYPE_CREDIT
        );
        ONB_Line__c repoLine = new ONB_Line__c(
            FundItemId__c = fund.Id,
            Line_Type__c = LINE_TYPE_REPO_NOTIONAL
        );
        insert new List<ONB_Line__c>{ creditLine, repoLine };

        Test.startTest();
        ONB_FundLineRestrictionService.recalculateForFunds(new Set<Id>{ fund.Id });
        Test.stopTest();

        Integer creditRemaining = [
            SELECT COUNT()
            FROM ONB_Line__c
            WHERE Id = :creditLine.Id
        ];
        Integer repoRemaining = [
            SELECT COUNT()
            FROM ONB_Line__c
            WHERE Id = :repoLine.Id
        ];

        System.assertEquals(0, creditRemaining);
        System.assertEquals(1, repoRemaining);
    }

    @IsTest
    static void testRecalculateForFunds_OnlyAffectsFundsPassedAsParameter() {
        Id onboardingId = getTestOnboardingId();

        ONB_Fund_Item__c targetFund = createFund(onboardingId);
        ONB_Fund_Item__c otherFund = createFund(onboardingId);

        insert new ONB_Onboarding_Line__c(
            FundItemId__c = targetFund.Id,
            OnboardingId__c = targetFund.OnboardingId__c,
            Product2Id__c = getProductIdByName(PRODUCT_FX_SPOT)
        );

        ONB_Line__c targetCreditLine = new ONB_Line__c(
            FundItemId__c = targetFund.Id,
            Line_Type__c = LINE_TYPE_CREDIT
        );
        ONB_Line__c otherCreditLine = new ONB_Line__c(
            FundItemId__c = otherFund.Id,
            Line_Type__c = LINE_TYPE_CREDIT
        );
        insert new List<ONB_Line__c>{ targetCreditLine, otherCreditLine };

        Test.startTest();
        ONB_FundLineRestrictionService.recalculateForFunds(new Set<Id>{ targetFund.Id });
        Test.stopTest();

        Integer targetRemaining = [
            SELECT COUNT()
            FROM ONB_Line__c
            WHERE Id = :targetCreditLine.Id
        ];
        Integer otherRemaining = [
            SELECT COUNT()
            FROM ONB_Line__c
            WHERE Id = :otherCreditLine.Id
        ];

        System.assertEquals(0, targetRemaining);
        System.assertEquals(1, otherRemaining);
    }

    @IsTest
    static void testRecalculateForFunds_NoLinesToDelete() {
        ONB_Fund_Item__c fund = createFund(getTestOnboardingId());

        insert new ONB_Onboarding_Line__c(
            FundItemId__c = fund.Id,
            OnboardingId__c = fund.OnboardingId__c,
            Product2Id__c = getProductIdByName(PRODUCT_OTHER)
        );

        Test.startTest();
        ONB_FundLineRestrictionService.recalculateForFunds(new Set<Id>{ fund.Id });
        Test.stopTest();

        System.assert(true);
    }

    private static Id getProductIdByName(String productName) {
        return [
            SELECT Id
            FROM Product2
            WHERE Name = :productName
            LIMIT 1
        ].Id;
    }

    private static Id getTestOnboardingId() {
        return [
            SELECT Id
            FROM ONB_Onboarding__c
            LIMIT 1
        ].Id;
    }

    private static ONB_Fund_Item__c createFund(Id onboardingId) {
        ONB_Fund_Item__c fund = new ONB_Fund_Item__c(
            OnboardingId__c = onboardingId
        );
        insert fund;
        return fund;
    }
}