@IsTest
private class ONB_LinesControllerTest {

    // -------------------------------------------------------
    // Shared test data
    // -------------------------------------------------------
    @TestSetup
    static void setupData() {
        ONB_Onboarding__c onb = new ONB_Onboarding__c(
            Name = 'Test Onboarding Lines'
        );
        insert onb;

        // Three lines of different types attached to the same onboarding
        List<ONB_Line__c> lines = new List<ONB_Line__c>{
            new ONB_Line__c(
                OnboardingId__c       = onb.Id,
                Line_Type__c          = 'LC_DVP',
                ONB_Line_Subtype__c   = 'DVP',
                ONB_Settlement_line_limit__c = 1000,
                CurrencyIsoCode       = 'EUR'
            ),
            new ONB_Line__c(
                OnboardingId__c       = onb.Id,
                Line_Type__c          = 'LC_CRED',
                ONB_Credit_line_limit__c = 2000,
                CurrencyIsoCode       = 'EUR'
            ),
            new ONB_Line__c(
                OnboardingId__c       = onb.Id,
                Line_Type__c          = 'LC_REPOS',
                ONB_Repos_line_limit__c = 3000,
                CurrencyIsoCode       = 'EUR'
            )
        };
        insert lines;

        // Product REPO + onboarding line → needed for hasRepoProduct
        Product2 repoProduct = new Product2(
            Name        = 'Repo/Reverse Repo',
            ProductCode = 'ONB_REPO_REVERSE_REPO',
            IsActive    = true
        );
        insert repoProduct;

        ONB_Onboarding_Line__c onbLine = new ONB_Onboarding_Line__c(
            OnboardingId__c = onb.Id,
            Product2Id__c   = repoProduct.Id
        );
        insert onbLine;
    }

    // -------------------------------------------------------
    // getLinesByOnboardingId
    // -------------------------------------------------------

    @IsTest
    static void test_getLines_nullIdReturnsEmptyList() {
        Test.startTest();
        List<ONB_Line__c> result = ONB_LinesController.getLinesByOnboardingId(null, null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Debe retornar lista vacía cuando onboardingId es null');
    }

    @IsTest
    static void test_getLines_returnsAllLinesForOnboarding() {
        Id onbId = [SELECT Id FROM ONB_Onboarding__c LIMIT 1].Id;

        Test.startTest();
        List<ONB_Line__c> result = ONB_LinesController.getLinesByOnboardingId(onbId, null);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Debe retornar las 3 líneas insertadas');
    }

    @IsTest
    static void test_getLines_returnsAllLineTypes() {
        Id onbId = [SELECT Id FROM ONB_Onboarding__c LIMIT 1].Id;

        Test.startTest();
        List<ONB_Line__c> result = ONB_LinesController.getLinesByOnboardingId(onbId, null);
        Test.stopTest();

        Set<String> lineTypes = new Set<String>();
        for (ONB_Line__c line : result) {
            lineTypes.add(line.Line_Type__c);
        }
        System.assert(lineTypes.contains('LC_DVP'),   'Debe contener línea LC_DVP');
        System.assert(lineTypes.contains('LC_CRED'),  'Debe contener línea LC_CRED');
        System.assert(lineTypes.contains('LC_REPOS'), 'Debe contener línea LC_REPOS');
    }

    @IsTest
    static void test_getLines_onboardingWithNoLinesReturnsEmpty() {
        ONB_Onboarding__c emptyOnb = new ONB_Onboarding__c(Name = 'Empty Onboarding');
        insert emptyOnb;

        Test.startTest();
        List<ONB_Line__c> result = ONB_LinesController.getLinesByOnboardingId(emptyOnb.Id, null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Debe retornar lista vacía si el onboarding no tiene líneas');
    }

    @IsTest
    static void test_getLines_doesNotReturnLinesFromOtherOnboardings() {
        ONB_Onboarding__c otherOnb = new ONB_Onboarding__c(Name = 'Other Onboarding');
        insert otherOnb;

        insert new ONB_Line__c(
            OnboardingId__c  = otherOnb.Id,
            Line_Type__c     = 'LC_DVP',
            CurrencyIsoCode  = 'EUR'
        );

        Id mainOnbId = [SELECT Id FROM ONB_Onboarding__c WHERE Name = 'Test Onboarding Lines' LIMIT 1].Id;

        Test.startTest();
        List<ONB_Line__c> result = ONB_LinesController.getLinesByOnboardingId(mainOnbId, null);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'No debe incluir líneas de otros onboardings');
    }

    // -------------------------------------------------------
    // hasRepoProduct
    // -------------------------------------------------------

    @IsTest
    static void test_hasRepoProduct_nullIdReturnsFalse() {
        Test.startTest();
        Boolean result = ONB_LinesController.hasRepoProduct(null);
        Test.stopTest();

        System.assertEquals(false, result, 'Debe retornar false cuando onboardingId es null');
    }

    @IsTest
    static void test_hasRepoProduct_trueWhenRepoProductLinked() {
        Id onbId = [SELECT Id FROM ONB_Onboarding__c WHERE Name = 'Test Onboarding Lines' LIMIT 1].Id;

        Test.startTest();
        Boolean result = ONB_LinesController.hasRepoProduct(onbId);
        Test.stopTest();

        System.assertEquals(true, result, 'Debe retornar true cuando el onboarding tiene producto REPO');
    }

    @IsTest
    static void test_hasRepoProduct_falseWhenNoRepoLinked() {
        ONB_Onboarding__c onbNoRepo = new ONB_Onboarding__c(Name = 'Onboarding Without Repo');
        insert onbNoRepo;

        Test.startTest();
        Boolean result = ONB_LinesController.hasRepoProduct(onbNoRepo.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Debe retornar false cuando el onboarding no tiene producto REPO');
    }

    @IsTest
    static void test_hasRepoProduct_falseWhenOnlyNonRepoProductLinked() {
        ONB_Onboarding__c onb = new ONB_Onboarding__c(Name = 'Onboarding Non-Repo Product');
        insert onb;

        Product2 otherProduct = new Product2(
            Name        = 'FX Spot',
            ProductCode = 'ONB_FX_SPOT',
            IsActive    = true
        );
        insert otherProduct;

        insert new ONB_Onboarding_Line__c(
            OnboardingId__c = onb.Id,
            Product2Id__c   = otherProduct.Id
        );

        Test.startTest();
        Boolean result = ONB_LinesController.hasRepoProduct(onb.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Debe retornar false cuando solo hay productos que no son REPO');
    }
}