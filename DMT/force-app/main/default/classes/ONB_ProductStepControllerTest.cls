@IsTest
private class ONB_ProductStepControllerTest {

    private static final String PB_FX_ONLY = 'PB_ONB_FX_SPOT_ONLY';
    private static final String PB_US_MIX = 'PB_ONB_US_MIX';

    @TestSetup
    static void setupData() {
        // Onboardings
        ONB_Onboarding__c onb1 = new ONB_Onboarding__c(Name = 'Onboarding Product Test 1', Any_Master_Agreement__c = 'Yes');
        ONB_Onboarding__c onb2 = new ONB_Onboarding__c(Name = 'Onboarding Product Test 2');
        insert new List<ONB_Onboarding__c>{ onb1, onb2 };

        // Fund Items
        ONB_Fund_Item__c fund1 = new ONB_Fund_Item__c(
            Name = 'Fund 1',
            OnboardingId__c = onb1.Id
        );
        ONB_Fund_Item__c fund2 = new ONB_Fund_Item__c(
            Name = 'Fund 2',
            OnboardingId__c = onb1.Id
        );
        insert new List<ONB_Fund_Item__c>{ fund1, fund2 };

        // Products
        Product2 prodFxSpot = new Product2(
            Name = 'FX Spot',
            ProductCode = 'ONB_FX_SPOT',
            IsActive = true,
            ONB_Product_Category__c = 'FX'
        );
        Product2 prodFxOtc = new Product2(
            Name = 'FX OTC bilateral derivatives',
            ProductCode = 'ONB_FX_OTC_BILATERAL_DERIVATIVES',
            IsActive = true,
            ONB_Product_Category__c = 'FX'
        );
        Product2 prodBonds = new Product2(
            Name = 'Bonds',
            ProductCode = 'ONB_BONDS',
            IsActive = true,
            ONB_Product_Category__c = 'Fixed Income & Rates'
        );
        Product2 prodRepo = new Product2(
            Name = 'Repo/Reverse Repo',
            ProductCode = 'ONB_REPO_REVERSE_REPO',
            IsActive = true,
            ONB_Product_Category__c = 'Securities'
        );
        insert new List<Product2>{ prodFxSpot, prodFxOtc, prodBonds, prodRepo };

        // Standard Pricebook
        Id stdPbId = Test.getStandardPricebookId();

        insert new List<PricebookEntry>{
            new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = prodFxSpot.Id,
                UnitPrice = 1,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = prodFxOtc.Id,
                UnitPrice = 1,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = prodBonds.Id,
                UnitPrice = 1,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = stdPbId,
                Product2Id = prodRepo.Id,
                UnitPrice = 1,
                IsActive = true
            )
        };

        // Custom Pricebooks
        Pricebook2 pbFxOnly = new Pricebook2(Name = PB_FX_ONLY, IsActive = true);
        Pricebook2 pbUsMix = new Pricebook2(Name = PB_US_MIX, IsActive = true);
        insert new List<Pricebook2>{ pbFxOnly, pbUsMix };

        // Custom PricebookEntries
        insert new List<PricebookEntry>{
            // FX only
            new PricebookEntry(
                Pricebook2Id = pbFxOnly.Id,
                Product2Id = prodFxSpot.Id,
                UnitPrice = 1,
                IsActive = true
            ),

            // US Mix
            new PricebookEntry(
                Pricebook2Id = pbUsMix.Id,
                Product2Id = prodFxSpot.Id,
                UnitPrice = 1,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = pbUsMix.Id,
                Product2Id = prodFxOtc.Id,
                UnitPrice = 1,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = pbUsMix.Id,
                Product2Id = prodBonds.Id,
                UnitPrice = 1,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = pbUsMix.Id,
                Product2Id = prodRepo.Id,
                UnitPrice = 1,
                IsActive = true
            )
        };

        // Product lines for onboarding 1
        insert new List<ONB_Onboarding_Line__c>{
            new ONB_Onboarding_Line__c(
                Name = 'Line A',
                OnboardingId__c = onb1.Id,
                Product2Id__c = prodFxSpot.Id,
                Product_Category__c = 'FX',
                Booking_Entity__c = 'BBVA_SA_Italy',
                Selling_Location__c = 'BBVA SA - France',
                Branch_Code__c = '6440',
                Account_Officer__c = 'Officer A',
                Comments__c = 'First line'
            ),
            new ONB_Onboarding_Line__c(
                Name = 'Line B',
                OnboardingId__c = onb1.Id,
                Product2Id__c = prodFxOtc.Id,
                Product_Category__c = 'FX',
                Booking_Entity__c = 'BBVA_SA_Germany',
                Selling_Location__c = 'BBVA Peru',
                Branch_Code__c = '6450',
                Account_Officer__c = 'Officer B',
                Comments__c = 'Second line',
                FundItemId__c = fund1.Id
            ),
            new ONB_Onboarding_Line__c(
                Name = 'Line C',
                OnboardingId__c = onb1.Id,
                Product2Id__c = prodBonds.Id,
                Product_Category__c = 'Fixed Income & Rates',
                Booking_Entity__c = 'BBVA_SA_United_States_of_America',
                Selling_Location__c = 'BBVA SA - United States of America',
                Branch_Code__c = '6460',
                Account_Officer__c = 'Officer C',
                Comments__c = 'Third line'
            ),
            new ONB_Onboarding_Line__c(
                Name = 'Line D',
                OnboardingId__c = onb1.Id,
                Product2Id__c = prodRepo.Id,
                Product_Category__c = 'Securities',
                Booking_Entity__c = 'BBVA_SA_United_States_of_America',
                Selling_Location__c = 'BBVA SA - United States of America',
                Branch_Code__c = '6470',
                Account_Officer__c = 'Officer D',
                Comments__c = 'Fourth line',
                FundItemId__c = fund2.Id
            )
        };

        // Product line for onboarding 2
        insert new ONB_Onboarding_Line__c(
            Name = 'Line X',
            OnboardingId__c = onb2.Id,
            Product2Id__c = prodFxSpot.Id,
            Product_Category__c = 'FX',
            Booking_Entity__c = 'BBVA_SA_Italy',
            Selling_Location__c = 'BBVA SA - Singapore',
            Branch_Code__c = '6480',
            Account_Officer__c = 'Officer X',
            Comments__c = 'Other onboarding'
        );

        ONB_Onboarding_Line__c lineA = [
            SELECT Id
            FROM ONB_Onboarding_Line__c
            WHERE Name = 'Line A'
            LIMIT 1
        ];

        ONB_Onboarding_Line__c lineD = [
            SELECT Id
            FROM ONB_Onboarding_Line__c
            WHERE Name = 'Line D'
            LIMIT 1
        ];

        insert new List<ONB_Fund_Product_Relsh__c>{
            new ONB_Fund_Product_Relsh__c(
                FundItemId__c = fund1.Id,
                ProductId__c = lineA.Id
            ),
            new ONB_Fund_Product_Relsh__c(
                FundItemId__c = fund2.Id,
                ProductId__c = lineD.Id
            )
        };
    }

    @IsTest
    static void testGetProductItems_nullOnboardingId_returnsEmpty() {
        Test.startTest();
        List<ONB_Onboarding_Line__c> res =
            ONB_ProductStepController.getProductItemsByOnboarding(null);
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assertEquals(0, res.size());
    }

    @IsTest
    static void testGetProductItems_returnsOnlyOnb1_inOrder() {
        ONB_Onboarding__c onb1 = [
            SELECT Id
            FROM ONB_Onboarding__c
            WHERE Name = 'Onboarding Product Test 1'
            LIMIT 1
        ];

        Test.startTest();
        List<ONB_Onboarding_Line__c> res =
            ONB_ProductStepController.getProductItemsByOnboarding(onb1.Id);
        Test.stopTest();

        System.assertEquals(4, res.size(), 'Debe devolver 4 líneas para onb1.');

        for (ONB_Onboarding_Line__c l : res) {
            System.assertEquals(onb1.Id, l.OnboardingId__c);
        }

        System.assertEquals('Line A', res[0].Name);
        System.assertEquals('Line B', res[1].Name);

        System.assertEquals('FX', res[0].Product_Category__c);
        System.assertEquals('BBVA_SA_Italy', res[0].Booking_Entity__c);
        System.assertEquals('BBVA SA - France', res[0].Selling_Location__c);
        System.assertEquals('6440', res[0].Branch_Code__c);
        System.assertEquals('Officer A', res[0].Account_Officer__c);
        System.assertEquals('First line', res[0].Comments__c);
    }

    @IsTest
    static void testGetProductItems_onb2_returnsOnlyOnb2() {
        ONB_Onboarding__c onb2 = [
            SELECT Id
            FROM ONB_Onboarding__c
            WHERE Name = 'Onboarding Product Test 2'
            LIMIT 1
        ];

        Test.startTest();
        List<ONB_Onboarding_Line__c> res =
            ONB_ProductStepController.getProductItemsByOnboarding(onb2.Id);
        Test.stopTest();

        System.assertEquals(1, res.size(), 'Debe devolver 1 línea para onb2.');
        System.assertEquals('Line X', res[0].Name);
        System.assertEquals('BBVA_SA_Italy', res[0].Booking_Entity__c);
        System.assertEquals(onb2.Id, res[0].OnboardingId__c);
    }

    @IsTest
    static void testGetProductsByBookingEntityAndCategory_blankParams_returnsEmpty() {
        Id onb1 = [
            SELECT Id
            FROM ONB_Onboarding__c
            WHERE Name = 'Onboarding Product Test 1'
            LIMIT 1
        ].Id;
        
        Test.startTest();
        List<Product2> res1 = ONB_ProductStepController.getProductsByBookingEntityAndCategory(onb1, null, 'FX');
        List<Product2> res2 = ONB_ProductStepController.getProductsByBookingEntityAndCategory(onb1, 'BBVA_SA_Italy', null);
        List<Product2> res3 = ONB_ProductStepController.getProductsByBookingEntityAndCategory(onb1, '', '');
        Test.stopTest();

        System.assertEquals(0, res1.size());
        System.assertEquals(0, res2.size());
        System.assertEquals(0, res3.size());
    }

    @IsTest
    static void testGetProductsByBookingEntityAndCategory_unknownBookingEntity_returnsEmpty() {
        Id onb1 = [
            SELECT Id
            FROM ONB_Onboarding__c
            WHERE Name = 'Onboarding Product Test 1'
            LIMIT 1
        ].Id;
        
        Test.startTest();
        List<Product2> res = ONB_ProductStepController.getProductsByBookingEntityAndCategory(
            onb1,
            'UNKNOWN_ENTITY',
            'FX'
        );
        Test.stopTest();

        System.assertEquals(0, res.size());
    }

    @IsTest
    static void testGetProductsByBookingEntityAndCategory_fxOnlyPricebook() {
        Id onb1 = [
            SELECT Id
            FROM ONB_Onboarding__c
            WHERE Name = 'Onboarding Product Test 1'
            LIMIT 1
        ].Id;
        
        Test.startTest();
        List<Product2> res = ONB_ProductStepController.getProductsByBookingEntityAndCategory(
            onb1,
            'BBVA_SA_Belgium',
            'FX'
        );
        Test.stopTest();

        System.assertEquals(1, res.size(), 'Belgium + FX solo debe devolver 1 producto.');
        System.assertEquals('FX Spot', res[0].Name);
        System.assertEquals('FX', res[0].ONB_Product_Category__c);
    }

    @IsTest
    static void testGetProductsByBookingEntityAndCategory_usFixedIncome() {
        Id onb1 = [
            SELECT Id
            FROM ONB_Onboarding__c
            WHERE Name = 'Onboarding Product Test 1'
            LIMIT 1
        ].Id;
        
        Test.startTest();
        List<Product2> res = ONB_ProductStepController.getProductsByBookingEntityAndCategory(
            onb1,
            'BBVA_SA_United_States_of_America',
            'Fixed Income & Rates'
        );
        Test.stopTest();

        System.assertEquals(1, res.size(), 'US + Fixed Income & Rates debe devolver 1 producto en este setup.');
        System.assertEquals('Bonds', res[0].Name);
    }

    @IsTest
    static void testGetProductsByBookingEntityAndCategory_noMatchingCategory_returnsEmpty() {
        Id onb1 = [
            SELECT Id
            FROM ONB_Onboarding__c
            WHERE Name = 'Onboarding Product Test 1'
            LIMIT 1
        ].Id;
        
        Test.startTest();
        List<Product2> res = ONB_ProductStepController.getProductsByBookingEntityAndCategory(
            onb1,
            'BBVA_SA_Belgium',
            'Securities'
        );
        Test.stopTest();

        System.assertEquals(0, res.size());
    }

    @IsTest
    static void testGetProductItemsForFunds_nullParams_returnsEmptyDto() {
        Test.startTest();
        ONB_ProductStepController.ProductModalDTO dto1 =
            ONB_ProductStepController.getProductItemsForFunds(null, null);
        ONB_ProductStepController.ProductModalDTO dto2 =
            ONB_ProductStepController.getProductItemsForFunds(null, UserInfo.getUserId());
        Test.stopTest();

        System.assertNotEquals(null, dto1);
        System.assertEquals(0, dto1.products.size());
        System.assertEquals(0, dto1.preselectedProductIds.size());

        System.assertNotEquals(null, dto2);
        System.assertEquals(0, dto2.products.size());
        System.assertEquals(0, dto2.preselectedProductIds.size());
    }

    @IsTest
    static void testGetProductItemsForFunds_returnsRowsAndPreselected() {
        ONB_Onboarding__c onb1 = [
            SELECT Id
            FROM ONB_Onboarding__c
            WHERE Name = 'Onboarding Product Test 1'
            LIMIT 1
        ];
        ONB_Fund_Item__c fund1 = [
            SELECT Id
            FROM ONB_Fund_Item__c
            WHERE Name = 'Fund 1'
            LIMIT 1
        ];

        Test.startTest();
        ONB_ProductStepController.ProductModalDTO dto =
            ONB_ProductStepController.getProductItemsForFunds(onb1.Id, fund1.Id);
        Test.stopTest();

        System.assertNotEquals(null, dto);
        System.assertEquals(2, dto.products.size(),
            'Debe traer solo productos FX Spot y Bonds del onboarding indicado.');
        System.assertEquals(1, dto.preselectedProductIds.size(),
            'Debe marcar solo las líneas ya asociadas a fund1.');
    }

    @IsTest
    static void testSaveProductsForFund_nullFundId_doesNothing() {
        Test.startTest();
        ONB_ProductStepController.saveProductsForFund(null, new List<Id>());
        Test.stopTest();

        System.assert(true, 'No debe lanzar excepción.');
    }

    @IsTest
    static void testSaveProductsForFund_assignsAndUnassignsCorrectly() {
        ONB_Fund_Item__c fund1 = [
            SELECT Id
            FROM ONB_Fund_Item__c
            WHERE Name = 'Fund 1'
            LIMIT 1
        ];

        List<ONB_Onboarding_Line__c> lines = [
            SELECT Id, Name
            FROM ONB_Onboarding_Line__c
            WHERE Name IN ('Line A', 'Line C')
            ORDER BY Name
        ];

        Id lineAId;
        Id lineCId;
        for (ONB_Onboarding_Line__c l : lines) {
            if (l.Name == 'Line A') lineAId = l.Id; // ya asociado a fund1
            if (l.Name == 'Line C') lineCId = l.Id; // sin asociación
        }

        Test.startTest();
        ONB_ProductStepController.saveProductsForFund(fund1.Id, new List<Id>{ lineCId });
        Test.stopTest();

        List<ONB_Fund_Product_Relsh__c> refreshed = [
            SELECT FundItemId__c, ProductId__c
            FROM ONB_Fund_Product_Relsh__c
            WHERE FundItemId__c = :fund1.Id
        ];

        System.assertEquals(1, refreshed.size(), 'Fund 1 debe conservar solo una asociación.');
        System.assertEquals(lineCId, refreshed[0].ProductId__c,
            'Line C debe asociarse a fund1.');

        Integer oldRelationCount = [
            SELECT COUNT()
            FROM ONB_Fund_Product_Relsh__c
            WHERE FundItemId__c = :fund1.Id
              AND ProductId__c = :lineAId
        ];
        System.assertEquals(0, oldRelationCount,
            'Line A debe desasociarse al no venir seleccionada.');
    }

  @IsTest
    static void testSaveProductsForFund_allowsProductLinkedToAnotherFund() {
        ONB_Fund_Item__c fund1 = [
            SELECT Id
            FROM ONB_Fund_Item__c
            WHERE Name = 'Fund 1'
            LIMIT 1
        ];

        ONB_Onboarding_Line__c lineD = [
            SELECT Id
            FROM ONB_Onboarding_Line__c
            WHERE Name = 'Line D'
            LIMIT 1
        ];

        Test.startTest();
        ONB_ProductStepController.saveProductsForFund(fund1.Id, new List<Id>{ lineD.Id });
        Test.stopTest();

        Integer relCount = [
            SELECT COUNT()
            FROM ONB_Fund_Product_Relsh__c
            WHERE ProductId__c = :lineD.Id
        ];
        System.assertEquals(2, relCount, 'El mismo producto debe poder asociarse a dos fondos.');
    }

    @IsTest
    static void testSaveProductsForFund_withNullSelectedList_unlinksCurrent() {
        ONB_Fund_Item__c fund1 = [
            SELECT Id
            FROM ONB_Fund_Item__c
            WHERE Name = 'Fund 1'
            LIMIT 1
        ];

        Test.startTest();
        ONB_ProductStepController.saveProductsForFund(fund1.Id, null);
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT()
            FROM ONB_Fund_Product_Relsh__c
            WHERE FundItemId__c = :fund1.Id
        ];
        System.assertEquals(0, cnt, 'Todas las asociaciones del fund deben quedar desasociadas.');
    }
}