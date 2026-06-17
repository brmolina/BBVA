@IsTest
private class ONB_FundItemControllerTest {
    private static Product2 createProduct(String name) {
        Product2 product = new Product2(
            Name = name,
            IsActive = true
        );
        insert product;
        return product;
    }

    private static Account createAccount() {
        Account acc = new Account(
            Name = 'Test Account'
        );
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

    private static Contrato_Marco__c createContract(String name) {
        Contrato_Marco__c contract = new Contrato_Marco__c(
            Name = name
        );
        insert contract;
        return contract;
    }

    private static ONB_Fund_Item__c createFund(
        Id onboardingId,
        String name,
        String fundType,
        String lei,
        String cif,
        Boolean leiPending,
        Id contractId
    ) {
        ONB_Fund_Item__c fund = new ONB_Fund_Item__c(
            ONB_FundName__c = name,
            ONB_Fund_Type__c = fundType,
            lei_id__c = lei,
            ONB_CIF__c = cif,
            ONB_LEI_Pending_Create__c = leiPending,
            OnboardingId__c = onboardingId,
            ContractId__c = contractId
        );
        insert fund;

        List<ONB_Line__c> autoCreatedLines = [
            SELECT Id
            FROM ONB_Line__c
            WHERE FundItemId__c = :fund.Id
        ];
        if (!autoCreatedLines.isEmpty()) {
            delete autoCreatedLines;
        }

        return fund;
    }

    private static ONB_Line__c createLine(
        Id fundId,
        String lineType,
        String subtype,
        Decimal amount,
        String currency2,
        String maturity
    ) {
        ONB_Line__c line = new ONB_Line__c(
            FundItemId__c = fundId,
            Line_Type__c = lineType,
            ONB_Line_Subtype__c = subtype,
            Amount__c = amount,
            ONB_Currency__c = currency2,
            ONB_Maturity__c = maturity
        );
        insert line;
        return line;
    }

    @IsTest
    static void testGetFundItemsReturnsEmptyWhenOnboardingIdIsNull() {
        Test.startTest();
        List<ONB_FundItemController.FundItemRow> result = ONB_FundItemController.getFundItems(null);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testGetFundItemsReturnsFundsWithLineCount() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);
        Contrato_Marco__c contract = createContract('Fund Contract');
        Product2 product = createProduct('Fund Product');

        ONB_Fund_Item__c fund1 = createFund(
            onboarding.Id,
            'Fund 1',
            'Pension funds',
            'LEI12345678901234567',
            'CIF123456',
            false,
            contract.Id
        );

        ONB_Fund_Item__c fund2 = createFund(
            onboarding.Id,
            'Fund 2',
            'Managed Accounts',
            'LEI76543210987654321',
            'CIF654321',
            true,
            null
        );

        createLine(fund1.Id, 'LC_DVP', 'DVP', 100, 'EUR', '1M');
        createLine(fund1.Id, 'LC_REPOS', 'Flow', 200, 'USD', '3M');
        createLine(fund2.Id, 'LC_DVP', 'Free Delivery', 300, 'GBP', '6M');

        insert new ONB_Onboarding_Line__c(
            OnboardingId__c = onboarding.Id,
            Product2Id__c = product.Id
        );

        ONB_Onboarding_Line__c persistedProduct = [
            SELECT Id
            FROM ONB_Onboarding_Line__c
            WHERE OnboardingId__c = :onboarding.Id
            AND Product2Id__c = :product.Id
            LIMIT 1
        ];

        insert new ONB_Fund_Product_Relsh__c(
            FundItemId__c = fund1.Id,
            ProductId__c = persistedProduct.Id
        );

        Test.startTest();
        List<ONB_FundItemController.FundItemRow> result = ONB_FundItemController.getFundItems(onboarding.Id);
        Test.stopTest();

        Boolean validResult = result.size() == 2;
        Integer totalLines = 0;
        Set<Id> fundIds = new Set<Id>();

        for (ONB_FundItemController.FundItemRow row : result) {
            fundIds.add(row.fundId);
            totalLines += row.linesCount;

            if (row.fundId == fund1.Id) {
                validResult = validResult
                    && row.fundName == 'Fund 1'
                    && row.fundType == 'Pension funds'
                    && row.leiId == 'LEI12345678901234567'
                    && row.cif == 'CIF123456'
                    && row.leiPendingCreate == false
                    && row.onboardingId == onboarding.Id
                    && row.linesCount == 2
                    && row.hasLinkedContract == true
                    && row.hasLinkedProduct == true;
            }

            if (row.fundId == fund2.Id) {
                validResult = validResult
                    && row.fundName == 'Fund 2'
                    && row.fundType == 'Managed Accounts'
                    && row.leiId == 'LEI76543210987654321'
                    && row.cif == 'CIF654321'
                    && row.leiPendingCreate == true
                    && row.onboardingId == onboarding.Id
                    && row.linesCount == 1
                    && row.hasLinkedContract == false
                    && row.hasLinkedProduct == false;
            }
        }

        System.assertEquals(true, validResult && fundIds.contains(fund1.Id) && fundIds.contains(fund2.Id) && totalLines == 3);
    }

    @IsTest
    static void testGetLineItemsReturnsEmptyWhenFundIdIsNull() {
        Test.startTest();
        List<ONB_Line__c> result = ONB_FundItemController.getLineItems(null);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testGetLineItemsReturnsLines() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);
        ONB_Fund_Item__c fund = createFund(
            onboarding.Id,
            'Fund 1',
            'Pension funds',
            'LEI12345678901234567',
            'CIF123456',
            false,
            null
        );

        ONB_Line__c line1 = createLine(fund.Id, 'LC_DVP', 'DVP', 100, 'EUR', '1M');
        ONB_Line__c line2 = createLine(fund.Id, 'LC_REPOS', 'Flow', 200, 'USD', '3M');

        Test.startTest();
        List<ONB_Line__c> result = ONB_FundItemController.getLineItems(fund.Id);
        Test.stopTest();

        Boolean validResult = result.size() == 2
            && result[0].Id == line1.Id
            && result[1].Id == line2.Id
            && result[0].Line_Type__c == 'LC_DVP'
            && result[1].Line_Type__c == 'LC_REPOS';

        System.assertEquals(true, validResult);
    }

    @IsTest
    static void testGetFundItemsForContractReturnsEmptyWhenParamsAreNull() {
        Test.startTest();
        ONB_FundItemController.FundModalDTO dto = ONB_FundItemController.getFundItemsForContract(null, null);
        Test.stopTest();

        System.assertEquals(true, dto.funds.isEmpty() && dto.preselectedFundIds.isEmpty());
    }

    @IsTest
    static void testGetFundItemsForContractReturnsAvailableAndPreselectedFunds() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);
        Contrato_Marco__c contract1 = createContract('Contract 1');
        Contrato_Marco__c contract2 = createContract('Contract 2');

        ONB_Fund_Item__c freeFund = createFund(
            onboarding.Id,
            'Free Fund',
            'Pension funds',
            'LEI11111111111111111',
            'CIF111111',
            false,
            null
        );

        ONB_Fund_Item__c linkedFund = createFund(
            onboarding.Id,
            'Linked Fund',
            'Managed Accounts',
            'LEI22222222222222222',
            'CIF222222',
            false,
            contract1.Id
        );

        createFund(
            onboarding.Id,
            'Other Contract Fund',
            'Spezial funds',
            'LEI33333333333333333',
            'CIF333333',
            false,
            contract2.Id
        );

        Test.startTest();
        ONB_FundItemController.FundModalDTO dto = ONB_FundItemController.getFundItemsForContract(onboarding.Id, contract1.Id);
        Test.stopTest();

        Boolean validResult = dto.funds.size() == 2 && dto.preselectedFundIds.size() == 1;

        Set<Id> returnedIds = new Set<Id>();
        for (ONB_Fund_Item__c fund : dto.funds) {
            returnedIds.add(fund.Id);
        }

        validResult = validResult
            && returnedIds.contains(freeFund.Id)
            && returnedIds.contains(linkedFund.Id)
            && dto.preselectedFundIds.contains(linkedFund.Id);

        System.assertEquals(true, validResult);
    }

    @IsTest
    static void testSaveFundsForContractDoesNothingWhenContractIdIsNull() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);
        ONB_Fund_Item__c fund = createFund(
            onboarding.Id,
            'Fund 1',
            'Pension funds',
            'LEI12345678901234567',
            'CIF123456',
            false,
            null
        );

        Test.startTest();
        ONB_FundItemController.saveFundsForContract(null, new List<Id>{ fund.Id });
        Test.stopTest();

        ONB_Fund_Item__c refreshedFund = [
            SELECT Id, ContractId__c
            FROM ONB_Fund_Item__c
            WHERE Id = :fund.Id
        ];

        System.assertEquals(null, refreshedFund.ContractId__c);
    }

    @IsTest
    static void testSaveFundsForContractLinksAndUnlinksFunds() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);
        Contrato_Marco__c contract = createContract('Main Contract');

        ONB_Fund_Item__c fund1 = createFund(
            onboarding.Id,
            'Fund 1',
            'Pension funds',
            'LEI11111111111111111',
            'CIF111111',
            false,
            contract.Id
        );

        ONB_Fund_Item__c fund2 = createFund(
            onboarding.Id,
            'Fund 2',
            'Managed Accounts',
            'LEI22222222222222222',
            'CIF222222',
            false,
            null
        );

        Test.startTest();
        ONB_FundItemController.saveFundsForContract(contract.Id, new List<Id>{ fund2.Id });
        Test.stopTest();

        Map<Id, ONB_Fund_Item__c> fundsById = new Map<Id, ONB_Fund_Item__c>([
            SELECT Id, ContractId__c
            FROM ONB_Fund_Item__c
            WHERE Id IN :new Set<Id>{ fund1.Id, fund2.Id }
        ]);

        Boolean validResult = fundsById.get(fund1.Id).ContractId__c == null
            && fundsById.get(fund2.Id).ContractId__c == contract.Id;

        System.assertEquals(true, validResult);
    }

    @IsTest
    static void testSaveFundsForContractThrowsWhenFundAlreadyLinkedToAnotherContract() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);
        Contrato_Marco__c contract1 = createContract('Contract 1');
        Contrato_Marco__c contract2 = createContract('Contract 2');

        ONB_Fund_Item__c fund = createFund(
            onboarding.Id,
            'Fund 1',
            'Pension funds',
            'LEI12345678901234567',
            'CIF123456',
            false,
            contract2.Id
        );

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            ONB_FundItemController.saveFundsForContract(contract1.Id, new List<Id>{ fund.Id });
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    @IsTest
    static void testCloneFundWithLinesThrowsWhenFundIdIsNull() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            ONB_FundItemController.cloneFundWithLines(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    @IsTest
    static void testCloneFundWithLinesClonesFundAndLines() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);

        ONB_Fund_Item__c sourceFund = createFund(
            onboarding.Id,
            'Source Fund',
            'Pension funds',
            'LEI12345678901234567',
            'CIF123456',
            true,
            null
        );

        createLine(sourceFund.Id, 'LC_DVP', 'DVP', 100, 'EUR', '1M');
        createLine(sourceFund.Id, 'LC_REPOS', 'Flow', 200, 'USD', '3M');

        Test.startTest();
        ONB_FundItemController.CloneFundResult result = ONB_FundItemController.cloneFundWithLines(sourceFund.Id);
        Test.stopTest();

        ONB_Fund_Item__c clonedFund = [
            SELECT Id, ONB_FundName__c, ONB_Fund_Type__c, lei_id__c, ONB_CIF__c, ONB_LEI_Pending_Create__c, OnboardingId__c
            FROM ONB_Fund_Item__c
            WHERE Id = :result.newFundId
        ];

        List<ONB_Line__c> clonedLines = [
            SELECT Id, FundItemId__c, Line_Type__c, ONB_Line_Subtype__c, Amount__c, ONB_Currency__c, ONB_Maturity__c
            FROM ONB_Line__c
            WHERE FundItemId__c = :clonedFund.Id
            ORDER BY CreatedDate ASC
        ];

        Boolean validResult = result.newFundId != null
            && result.clonedLines == 2
            && clonedFund.Id != sourceFund.Id
            && clonedFund.ONB_FundName__c == 'Source Fund'
            && clonedFund.ONB_Fund_Type__c == 'Pension funds'
            && clonedFund.lei_id__c == 'LEI12345678901234567'
            && clonedFund.ONB_CIF__c == 'CIF123456'
            && clonedFund.ONB_LEI_Pending_Create__c == true
            && clonedFund.OnboardingId__c == onboarding.Id
            && clonedLines.size() == 2
            && clonedLines[0].Line_Type__c == 'LC_DVP'
            && clonedLines[0].ONB_Line_Subtype__c == 'DVP'
            && clonedLines[1].Line_Type__c == 'LC_REPOS'
            && clonedLines[1].ONB_Line_Subtype__c == 'Flow';

        System.assertEquals(true, validResult);
    }

    @IsTest
    static void testCloneFundWithLinesWhenSourceHasNoLines() {
        Account acc = createAccount();
        ONB_Onboarding__c onboarding = createOnboarding(acc.Id);

        ONB_Fund_Item__c sourceFund = createFund(
            onboarding.Id,
            'Empty Fund',
            'Managed Accounts',
            'LEI12345678901234567',
            'CIF123456',
            false,
            null
        );

        Test.startTest();
        ONB_FundItemController.CloneFundResult result = ONB_FundItemController.cloneFundWithLines(sourceFund.Id);
        Test.stopTest();

        List<ONB_Line__c> clonedLines = [
            SELECT Id
            FROM ONB_Line__c
            WHERE FundItemId__c = :result.newFundId
        ];

        System.assertEquals(true, result.newFundId != null && result.clonedLines == 0 && clonedLines.isEmpty());
    }
}