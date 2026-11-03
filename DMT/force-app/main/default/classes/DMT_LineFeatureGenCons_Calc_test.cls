@isTest
public with sharing class DMT_LineFeatureGenCons_Calc_test {
    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass(); // CIBGLOBALD-4613

    @TestSetup
    static void loadTestData(){

        TriggerBypass.setBypass();
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Test_DataFactory.generateTaskTypes();
        DMT_Test_DataFactory.generateApprover();


         Product2 p4 = new Product2(
            Name='Repo',
            ProductCode='1611190000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='03',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        insert p4;

        TriggerBypass.removeBypass();
    }

    @isTest
    private static void checkValidationsTest()
    {
        List<DMT_Line__c> lines = [SELECT Id FROM DMT_Line__c];
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
            {
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }};

        Assert.isNotNull(DMT_LineFeatureGenCons_Calc.checkValidations(lines[0].Id, JSON.serialize(clientsGroup)),'Response returned');
    }

    @isTest
    private static void checkValidationsCATest()
    {
        List<DMT_Line__c> lines = [SELECT Id, Client__c FROM DMT_Line__c];
        //DMT_Test_DataFactory.generateCustomAssociation(lines[0].Id, lines[0].Client__c);
        lines[0].FD_Amount__c = 0;
        lines[0].DvP_Amount__c = 0;
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
            {
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }};

        update lines;
        Custom_Association_Client__c testAssociation = new Custom_Association_Client__c(
            Name = 'Test Association',
            Custom_Association__c =  (DMT_Test_DataFactory.generateCustomAssociation(lines[0].Id, lines[0].Client__c)).Id,
            DMT_Amount__c = 1000,
            Alpha_Code_Client__c = 'ES0182054986618'
        );
        insert testAssociation;
        Assert.isNotNull(DMT_LineFeatureGenCons_Calc.checkValidations(lines[0].Id, JSON.serialize(clientsGroup)),'Response returned');
    }

    @isTest
    private static void checkValidationsCACompleteTest()
    {
        List<DMT_Line__c> lines = [SELECT Id, Client__c FROM DMT_Line__c];
        DMT_Test_DataFactory.generateCustomAssociation(lines[0].Id, lines[0].Client__c);
        lines[0].Status__c = 'Closed';
        lines[0].Closed__c = 'Won';
        lines[0].Start_Date__c = Date.today();
        lines[0].End_Date__c = Date.today().addMonths(1);
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
            {
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }};

        update lines;
        Assert.isNotNull(DMT_LineFeatureGenCons_Calc.checkValidations(lines[0].Id, JSON.serialize(clientsGroup)),'Response returned');
    }

    @isTest
    private static void checkValidationsCompleteTest()
    {
        List<DMT_Line__c> lines = [SELECT Id, Client__c FROM DMT_Line__c];
        lines[0].Status__c = 'Closed';
        lines[0].Closed__c = 'Won';
        lines[0].Start_Date__c = Date.today();
        lines[0].End_Date__c = Date.today().addMonths(1);
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
            {
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }};

        update lines;
        Assert.isNotNull(DMT_LineFeatureGenCons_Calc.checkValidations(lines[0].Id, JSON.serialize(clientsGroup)),'Response returned');
    }

    @isTest
    private static void checkvalidationRenovationTest() {

        List<DMT_Line__c> lineList = [SELECT Id, Name, DMT_Parent_Line__c FROM DMT_Line__c];
        System.debug('lineList.size, '+ lineList.size());
        System.debug('lineList, '+ lineList);

        lineList[1].DMT_Parent_Line__c = lineList[0].Id;
        update lineList[1];

    //    Id line = [SELECT Id FROM DMT_Line__c WHERE Name  = 'Line Test ENERGIA FINANCIACION' AND DMT_Parent_Line__c != null LIMIT 1].Id;
    //    Id lineList[1].Id = [SELECT Id FROM DMT_Line__c WHERE Name  = 'Line Test ENERGIA FINANCIACION' AND DMT_Parent_Line__c = null LIMIT 1].Id;

         Product2 p1 = new Product2(
            Name='DEPO',
            ProductCode='1611170000',
            DMT_Product_family__c='01',
            DMT_Product_Subfamily__c='02',
            DMT_Product_category__c='02',
            DMT_Product_Subcategory__c='01',
            DMT_Global_Product_Id__c='00',
            CurrencyIsoCode='EUR',
            family='DMT Lines');

        insert p1;

        DMT_Line_Product_Item__c pli1 = new DMT_Line_Product_Item__c(
            Name ='Product line item DEPO',
            CurrencyIsoCode ='EUR',
            Line__c =lineList[1].Id,
            Product__c =p1.Id,
            Max_Tenor_WC__c = '7',
            DMT_DerivativeRestriction__c = false,
            DMT_DVPRestriction__c = false,
            DMT_FDRestriction__c = false,
            Product_Code_Value__c = 'DEPO'
        );

        insert pli1;

        DMT_Line_Product_Item__c pli2 = new DMT_Line_Product_Item__c(
            Name ='Product line item DEPO',
            CurrencyIsoCode ='EUR',
            Line__c =lineList[0].Id,
            Product__c =p1.Id,
            Max_Tenor_WC__c = '7',
            DMT_DerivativeRestriction__c = false,
            DMT_DVPRestriction__c = false,
            DMT_FDRestriction__c = false,
            Product_Code_Value__c = 'DEPO'
        );

        insert pli2;

        DMT_Risk_Line_Term__c rsklt1 = new DMT_Risk_Line_Term__c();
        rsklt1.DMT_Line__c = lineList[1].Id;
        rsklt1.Name='Line test ENERGIA FINANCIACION	rsk line term 1';
        rsklt1.DMT_Init_Term__c='0';
        rsklt1.DMT_End_Term__c ='3';
        rsklt1.DMT_Amount__c   = 10;
        rsklt1.CurrencyIsoCode ='EUR';
        rsklt1.DMT_Risk_Type__c='Derivatives';

        List<DMT_Risk_Line_Term__c> listRsklt = new List<DMT_Risk_Line_Term__c>{rsklt1};
        insert listRsklt;
        Test.startTest();

        Assert.areEqual(DMT_LineFeatureGenCons_Calc.validationRenovation(lineList[0].Id, lineList[1].Id), false, 'testier is testier'); // CIBGLOBALD-4613

        pli2.DMT_DerivativeRestriction__c = true;
        update pli2;
        DMT_Passport_Selector.clearTransactionCache(); // CIBGLOBALD-4613 - product items changed in the same test transaction

        Assert.areEqual(DMT_LineFeatureGenCons_Calc.validationRenovation(lineList[0].Id, lineList[1].Id), true, 'testier is testier'); // CIBGLOBALD-4613

        Test.stoptest();

    }

    @isTest
    private static void checkValidationsOtherLinesTest()
    {
        String otherLineRecordTypeID = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();
        List<DMT_Line__c> lines = [SELECT Id, Client__c FROM DMT_Line__c WHERE RecordTypeId =: otherLineRecordTypeID];
        DMT_Test_DataFactory.generateCustomAssociation(lines[0].Id, lines[0].Client__c);
        lines[0].Status__c = 'Closed';
        lines[0].Closed__c = 'Won';
		lines[0].Start_Date__c = Date.today();
        lines[0].End_Date__c = Date.today().addMonths(1);
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
            {
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }};

        update lines;
        Assert.isNotNull(DMT_LineFeatureGenCons_Calc.checkValidations(lines[0].Id, JSON.serialize(clientsGroup)),'Response returned');
    }

    @isTest
    private static void testLineFeatureGenConsCalcValidationRenovation_Custom() {
        // Use existing test data from DataFactory
        DMT_Line__c parentLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        DMT_Line__c childLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00003' LIMIT 1];

        // Add product items to both lines
        DMT_Line_Product_Item__c parentItem = new DMT_Line_Product_Item__c(
            Line__c = parentLine.Id,
            Name = 'TestProduct',
            DMT_FDRestriction__c = false,
            DMT_DVPRestriction__c = false,
            Max_Tenor_WC__c = '12',
            DMT_DerivativeRestriction__c = false
        );
        insert parentItem;

        DMT_Line_Product_Item__c childItem = new DMT_Line_Product_Item__c(
            Line__c = childLine.Id,
            Name = 'TestProduct',
            DMT_FDRestriction__c = true,
            DMT_DVPRestriction__c = false,
            Max_Tenor_WC__c = '24',
            DMT_DerivativeRestriction__c = true
        );
        insert childItem;

        // Add risk lines to both
        DMT_Risk_Line_Term__c parentRisk = new DMT_Risk_Line_Term__c(
            DMT_Line__c = parentLine.Id,
            DMT_End_Term__c = '12',
            DMT_Amount__c = 1000
        );
        insert parentRisk;

        DMT_Risk_Line_Term__c childRisk = new DMT_Risk_Line_Term__c(
            DMT_Line__c = childLine.Id,
            DMT_End_Term__c = '24',
            DMT_Amount__c = 2000,
            DMT_LastLevelId__c = 'testLestevelId_-$'
        );
        insert childRisk;

        // Should return true (child has greater Max_Tenor_WC__c and DMT_DerivativeRestriction__c)
        Boolean result = DMT_LineFeatureGenCons_Calc.validationRenovation(childLine.Id, parentLine.Id);
        Assert.areEqual(true, result, 'validationRenovation should return true when child line has greater values');

        // Should return false if parent and child are the same
        Boolean result2 = DMT_LineFeatureGenCons_Calc.validationRenovation(parentLine.Id, parentLine.Id);
        Assert.areEqual(false, result2, 'validationRenovation should return false when parent and child are the same');
    }

    // Test for DMT_LineFeatureGenCons_Calc.validationRenovation
    @isTest
    private static void testLineFeatureGenConsCalcValidationRenovation() {
        // Setup: create parent and child lines with product items and risk lines
        DMT_Line__c parentLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        DMT_Line__c childLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00003' LIMIT 1];

        // Add product items to both lines
        DMT_Line_Product_Item__c parentItem = new DMT_Line_Product_Item__c(
            Line__c = parentLine.Id,
            Name = 'TestProduct',
            DMT_FDRestriction__c = false,
            DMT_DVPRestriction__c = false,
            Max_Tenor_WC__c = '12',
            DMT_DerivativeRestriction__c = false
        );
        insert parentItem;

        DMT_Line_Product_Item__c childItem = new DMT_Line_Product_Item__c(
            Line__c = childLine.Id,
            Name = 'TestProduct',
            DMT_FDRestriction__c = true,
            DMT_DVPRestriction__c = false,
            Max_Tenor_WC__c = '24',
            DMT_DerivativeRestriction__c = true
        );
        insert childItem;

        // Add risk lines to both
        DMT_Risk_Line_Term__c parentRisk = new DMT_Risk_Line_Term__c(
            DMT_Line__c = parentLine.Id,
            DMT_End_Term__c = '12',
            DMT_Amount__c = 1000
        );
        insert parentRisk;

        DMT_Risk_Line_Term__c childRisk = new DMT_Risk_Line_Term__c(
            DMT_Line__c = childLine.Id,
            DMT_End_Term__c = '24',
            DMT_Amount__c = 2000,
            DMT_LastLevelId__c = 'testLestLevelId_-$'
        );
        insert childRisk;

        // Should return true (child has greater Max_Tenor_WC__c and DMT_DerivativeRestriction__c)
        Boolean result = DMT_LineFeatureGenCons_Calc.validationRenovation(childLine.Id, parentLine.Id);
        Assert.areEqual(true, result, 'validationRenovation should return true when child line has greater values');

        // Should return false if parent and child are the same
        Boolean result2 = DMT_LineFeatureGenCons_Calc.validationRenovation(parentLine.Id, parentLine.Id);
        Assert.areEqual(false, result2, 'validationRenovation should return false when parent and child are the same');
    }

    // Test for DMT_LineFeatureGenCons_Calc.validationRenovationOtherLines
    @isTest
    private static void testValidationRenovationOtherLines() {

    // Use existing test data from DataFactory
        DMT_Line__c parentLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        DMT_Line__c childLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00003' LIMIT 1];

    // Add risk lines to both
        DMT_Risk_Line_Term__c parentRiskTerm1 = new DMT_Risk_Line_Term__c(
            DMT_Line__c = parentLine.Id,
            DMT_End_Term__c = '12',
            DMT_Amount__c = 5000
        );
        insert parentRiskTerm1;


        DMT_Risk_Line_Term__c childRiskTerm1 = new DMT_Risk_Line_Term__c(
            DMT_Line__c = childLine.Id,
            DMT_End_Term__c = '12',
            DMT_Amount__c = 6000,
            DMT_LastLevelId__c = 'testLestLevelId_-$'
        );
        insert childRiskTerm1;

        Test.startTest();
        // Should return true (child has greater Amount)
        Boolean result = DMT_LineFeatureGenCons_Calc.validationRenovationOtherLines(childLine.Id, parentLine.Id);
        Assert.areEqual(true, result, 'validationRenovationOtherLines should return true when child line has greater amount');

        // Should return true (child line has more risk terms than parent)
        DMT_Risk_Line_Term__c additionalChildRiskTerm = new DMT_Risk_Line_Term__c(
            DMT_Line__c = childLine.Id,
            DMT_End_Term__c = '36',
            DMT_Amount__c = 3000
        );
        insert additionalChildRiskTerm;

        DMT_Passport_Selector.clearTransactionCache(); // CIBGLOBALD-4613 - risk line term added in the same test transaction
        Boolean result2 = DMT_LineFeatureGenCons_Calc.validationRenovationOtherLines(childLine.Id, parentLine.Id);
        Assert.areEqual(true, result2, 'validationRenovationOtherLines should return true when child line has more risk terms than parent');
        Test.stopTest();
    }

    // Test for DMT_LineFeatureGenCons_Calc.isCurrentLine
    @isTest
    private static void testLineFeatureGenConsCalcIsCurrentLineGreen() {
        // Setup: create a line and a duplicate client line
        DMT_Line__c line = [SELECT Id, DMT_Parent_Line__c, Status__c, Custom_Association__c, Closed__c, DMT_Status_Completed__c, RecordTypeId, Client_Code__c, Start_Date__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1]; // CIBGLOBALD-4613

        Date startDate = line.Start_Date__c;

        Test.startTest();
        // Should return GREEN if no duplicate
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations result2 = DMT_LineFeatureGenCons_Calc.isCurrentLine(new List<String>{'NONEXISTENT'}, startDate, line);
        Assert.areEqual(DMT_Constants.FEATURE_GC_STATE_GREEN, result2.state, 'Should be GREEN when no duplicate client line exists');
        Test.stopTest();
    }
     // Test for DMT_LineFeatureGenCons_Calc.endDate
    @isTest
    private static void testLineFeatureGenConsValidationEndDate() {
        // Setup: create a line and a duplicate client line
        DMT_Line__c line = [SELECT Id, Status__c, End_Date__c, Custom_Association__c, Closed__c, DMT_Status_Completed__c, RecordTypeId, Client_Code__c, Start_Date__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];

        Date endDate = line.End_Date__c;

        Test.startTest();
        // Should return GREEN if no duplicate
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations result2 = DMT_LineFeatureGenCons_Calc.endDate(line);
        Assert.areEqual( DMT_Constants.FEATURE_GC_STATE_RED, result2.state, 'Should be RED when the End date is not the last day of the month');
        Test.stopTest();
    }
    // Test for DMT_LineFeatureGenCons_Calc.isCurrentLine
    @isTest
    private static void testLineFeatureGenConsCalcIsCurrentLineRed() {
        TriggerBypass.setBypass();
        Test.startTest();
        // Setup: create a line and a duplicate client line
        List<DMT_Line__c> lineList = [SELECT Id, DMT_Parent_Line__c, Status__c, Start_Date__c, Custom_Association__c, Closed__c, DMT_Status_Completed__c, RecordTypeId, Client_Code__c FROM DMT_Line__c WHERE Client_Code__c = 'ES0182054986618']; // CIBGLOBALD-4613
        System.debug('lineList, '+ lineList);

        for(DMT_Line__c line : lineList) {
            line.Start_Date__c = Date.today().addDays(-30);
            line.End_Date__c = Date.today().addDays(30);
            line.Status__c = DMT_Constants.CLOSED;
            line.Closed__c = 'Won';
        }

        update lineList;

        List<String> clientCodesList = new List<String>();
        clientCodesList.add(lineList[0].Client_Code__c);

        Date startDate = lineList[0].Start_Date__c;


        // Should return GREEN if no duplicate
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations result2 = DMT_LineFeatureGenCons_Calc.isCurrentLine(clientCodesList, startDate, lineList[0]);
        Assert.areEqual(DMT_Constants.FEATURE_GC_STATE_YELLOW, result2.state, 'Should be RED when duplicate client line exists');

        Test.stopTest();
    }

    @isTest
    private static void testCheckValidations_customAssociationClientValidation() {

        DMT_Line__c line = [SELECT Id, Status__c, Closed__c, DMT_DerivativesAmount__c, DMT_Status_Completed__c, RecordTypeId, Client_Code__c, Start_Date__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name='Test company 1' LIMIT 1];

        Custom_Association__c customAss = DMT_Test_DataFactory.generateCustomAssociation(line.Id, acc.Id);

        // Build clientsGroup with matching customerId and scaleLastUpdDate
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerId' => 'TESTCODE',
                'scaleLastUpdDate' => String.valueOf(Date.today()),
                'customerCounterpartiesCodesDesc' => 'A+',
                'operationMitigantDesc' => 'Mitigant',
                'ratingValidityStartDate' => String.valueOf(Date.today())
            }
        };

        Custom_Association_Client__c testAssociation = new Custom_Association_Client__c(
            Name = 'Test Association',
            Custom_Association__c = customAss.Id,
            DMT_Amount__c = 2000000000,
            Alpha_Code_Client__c = 'ES0182054986618'
        );
        insert testAssociation;

        Test.startTest();
        // Should return GREEN if no duplicate
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations result2 = DMT_LineFeatureGenCons_Calc.customAssociationClientValidation(line);
        Assert.areEqual( DMT_Constants.FEATURE_GC_STATE_RED, result2.state, 'Should be RED when the amount of the Custom association client is greather or equal than the line');
        Test.stopTest();

    }

    @isTest
    private static void testCheckValidations_CustomAssociationClientBlock() {

        DMT_Line__c line = [SELECT Id, Status__c, Closed__c, DMT_Status_Completed__c, RecordTypeId, Client_Code__c, Start_Date__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name='Test company 1' LIMIT 1];

        Custom_Association__c customAss = DMT_Test_DataFactory.generateCustomAssociation(line.Id, acc.Id);

        // Build clientsGroup with matching customerId and scaleLastUpdDate
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerId' => 'TESTCODE',
                'scaleLastUpdDate' => String.valueOf(Date.today()),
                'customerCounterpartiesCodesDesc' => 'A+',
                'operationMitigantDesc' => 'Mitigant',
                'ratingValidityStartDate' => String.valueOf(Date.today())
            }
        };

        Custom_Association_Client__c testAssociation = new Custom_Association_Client__c(
            Name = 'Test Association',
            Custom_Association__c = customAss.Id,
            DMT_Amount__c = 1000,
            Alpha_Code_Client__c = 'ES0182054986618'
        );
        insert testAssociation;

        Test.startTest();
        // Call the method
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> results =
        DMT_LineFeatureGenCons_Calc.checkValidations(line.Id, JSON.serialize(clientsGroup));

        System.debug('results.size: ' + results.size());
        Assert.isTrue(results.size() > 0, 'Expected results to contain at least one item');
        Test.stopTest();

    }

    @isTest
    private static void testCheckValidations_CustomAssociationClientBlock_ElseBranch() {
        DMT_Line__c line = [SELECT Id, Status__c, Closed__c, DMT_Status_Completed__c, RecordTypeId, Client_Code__c, Start_Date__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name='Test company 1' LIMIT 1];

        Custom_Association__c customAss = DMT_Test_DataFactory.generateCustomAssociation(line.Id, acc.Id);

        // Build clientsGroup with matching customerId and currentRatingToolDate (to hit the else if branch)
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => String.valueOf(Date.today()),
                'ffssRegulatoryRatingDate' => String.valueOf(Date.today()),
                'customerCounterpartiesCodesDesc' => 'A+',
                'operationMitigantDesc' => 'Mitigant'
            }
        };

        Custom_Association_Client__c testAssociation = new Custom_Association_Client__c(
            Name = 'Test Association Else',
            Custom_Association__c = customAss.Id,
            DMT_Amount__c = 1000,
            Alpha_Code_Client__c = 'ES0182054986618'
        );
        insert testAssociation;

        Test.startTest();
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> results =
            DMT_LineFeatureGenCons_Calc.checkValidations(line.Id, JSON.serialize(clientsGroup));

        System.debug('results.size (else): ' + results.size());
        Assert.isTrue(results.size() > 0, 'Expected results to contain at least one item (else branch)');

    }

    /**
     * CIBGLOBALD-4613 - MX restriction tables: in-memory DMT_OperationalRestrictionsTRSR__mdt rows (custom metadata
     * cannot be inserted) mapping FOEX to Derivatives, DELE to Depos and REAC to Repos, as the MX_2 records do.
     */
    private static Map<String, DMT_OperationalRestrictionsTRSR__mdt> buildMxRestrictions() {
        return new Map<String, DMT_OperationalRestrictionsTRSR__mdt>{
            'FOEX' => new DMT_OperationalRestrictionsTRSR__mdt(DMT_Operational_Restrictions_Name__c = 'FOEX', DMT_Derivatives_layout2__c = true, DMT_Depos_layout2__c = false, DMT_Repos_layout2__c = false),
            'DELE' => new DMT_OperationalRestrictionsTRSR__mdt(DMT_Operational_Restrictions_Name__c = 'DELE', DMT_Derivatives_layout2__c = false, DMT_Depos_layout2__c = true, DMT_Repos_layout2__c = false),
            'REAC' => new DMT_OperationalRestrictionsTRSR__mdt(DMT_Operational_Restrictions_Name__c = 'REAC', DMT_Derivatives_layout2__c = false, DMT_Depos_layout2__c = false, DMT_Repos_layout2__c = true)
        };
    }

    // CIBGLOBALD-4613 - In-memory line product item (no DML: the validations receive the lists)
    private static DMT_Line_Product_Item__c buildProduct(String productCode, Boolean lineEnabled, String maxTenor) {
        return DMT_UTIL.buildLineProductItem(new Map<Schema.SObjectField, Object>{
            DMT_Line_Product_Item__c.Name => productCode + ' product',
            DMT_Line_Product_Item__c.Product_Code_Value__c => productCode,
            DMT_Line_Product_Item__c.DMT_DerivativeRestriction__c => lineEnabled,
            DMT_Line_Product_Item__c.Max_Tenor_WC__c => maxTenor
        });
    }

    // CIBGLOBALD-4613 - In-memory risk line term of one line table
    private static DMT_Risk_Line_Term__c buildTerm(String riskType, String endTerm, Decimal amount) {
        return DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{
            DMT_Risk_Line_Term__c.DMT_Risk_Type__c => riskType,
            DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
            DMT_Risk_Line_Term__c.DMT_End_Term__c => endTerm,
            DMT_Risk_Line_Term__c.DMT_Amount__c => amount
        });
    }

    // CIBGLOBALD-4613 - MX: products enabled in the Depos and Repos tables without amount give one YELLOW entry
    @isTest
    private static void restrictionWithoutAmountMxYellowTest() {
        List<DMT_Line_Product_Item__c> products = new List<DMT_Line_Product_Item__c>{
            buildProduct('FOEX', true, null),
            buildProduct('DELE', true, null),
            buildProduct('REAC', true, null)
        };
        List<DMT_Risk_Line_Term__c> terms = new List<DMT_Risk_Line_Term__c>{
            buildTerm(DMT_Constants.RSK_DERIVATIVES, '1095', 1000),
            buildTerm(DMT_Constants.RSK_DEPOS, '30', 0)
        };

        Test.startTest();
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations result = DMT_LineFeatureGenCons_Calc.restrictionWithoutAmount(products, terms, buildMxRestrictions());
        Test.stopTest();

        Assert.areEqual(DMT_Constants.FEATURE_GC_STATE_YELLOW, result.state, 'Depos and Repos tables have no amount');
        Assert.areEqual(System.Label.dmt_cl_FeatureRestrictionAmountTitle, result.name, 'Validation title');
        Assert.isTrue(result.message.contains('DELE product (Depos)'), 'DELE is listed with its table: ' + result.message);
        Assert.isTrue(result.message.contains('REAC product (Repos)'), 'REAC is listed with its table: ' + result.message);
        Assert.isFalse(result.message.contains('FOEX'), 'FOEX has a Derivatives amount: ' + result.message);
    }

    // CIBGLOBALD-4613 - MX: every enabled product has an amount in its table, or the product is not enabled -> GREEN
    @isTest
    private static void restrictionWithoutAmountMxGreenTest() {
        List<DMT_Line_Product_Item__c> products = new List<DMT_Line_Product_Item__c>{
            buildProduct('FOEX', true, null),
            buildProduct('DELE', true, null),
            buildProduct('REAC', false, null)
        };
        List<DMT_Risk_Line_Term__c> terms = new List<DMT_Risk_Line_Term__c>{
            buildTerm(DMT_Constants.RSK_DERIVATIVES, '1095', 1000),
            buildTerm(DMT_Constants.RSK_DEPOS, '30', 500)
        };

        Test.startTest();
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations result = DMT_LineFeatureGenCons_Calc.restrictionWithoutAmount(products, terms, buildMxRestrictions());
        Test.stopTest();

        Assert.areEqual(DMT_Constants.FEATURE_GC_STATE_GREEN, result.state, 'Enabled tables have an amount');
        Assert.areEqual(System.Label.dmt_cl_FeatureRestrictionAmountGreen, result.message, 'Green message');
    }

    // CIBGLOBALD-4613 - Geographies without layout2 restriction records get no new validation
    @isTest
    private static void restrictionWithoutAmountOtherGeographyTest() {
        Map<String, DMT_OperationalRestrictionsTRSR__mdt> esRestrictions = new Map<String, DMT_OperationalRestrictionsTRSR__mdt>{
            'FOEX' => new DMT_OperationalRestrictionsTRSR__mdt(DMT_Operational_Restrictions_Name__c = 'FOEX', DMT_Derivatives_layout2__c = false, DMT_Depos_layout2__c = false, DMT_Repos_layout2__c = false)
        };

        Test.startTest();
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations result = DMT_LineFeatureGenCons_Calc.restrictionWithoutAmount(
            new List<DMT_Line_Product_Item__c>{ buildProduct('FOEX', true, null) }, new List<DMT_Risk_Line_Term__c>(), esRestrictions);
        Test.stopTest();

        Assert.isNull(result, 'No validation for geographies without layout2 restrictions');
    }

    // CIBGLOBALD-4613 - MX maturity term: Depos and Repos products are compared with their own table terms
    @isTest
    private static void restricGreaterTermPerTableTest() {
        List<DMT_Risk_Line_Term__c> terms = new List<DMT_Risk_Line_Term__c>{
            buildTerm(DMT_Constants.RSK_DERIVATIVES, '16425', 1000),
            buildTerm(DMT_Constants.RSK_DEPOS, '30', 500),
            buildTerm(DMT_Constants.RSK_REPOS, '10', 500)
        };

        Test.startTest();
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations green = DMT_LineFeatureGenCons_Calc.restricGreaterTerm(
            new List<DMT_Line_Product_Item__c>{ buildProduct('FOEX', true, '3650'), buildProduct('DELE', true, '30'), buildProduct('REAC', true, '10') },
            terms, buildMxRestrictions());
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations yellow = DMT_LineFeatureGenCons_Calc.restricGreaterTerm(
            new List<DMT_Line_Product_Item__c>{ buildProduct('FOEX', true, '3650'), buildProduct('DELE', true, '60'), buildProduct('REAC', true, '30') },
            terms, buildMxRestrictions());
        DMT_Wrapper_Passport_Abs.FeatureGenConsiderations derivativesOnly = DMT_LineFeatureGenCons_Calc.restricGreaterTerm(
            new List<DMT_Line_Product_Item__c>{ buildProduct('DELE', true, '60') },
            new List<DMT_Risk_Line_Term__c>{ terms[0] });
        Test.stopTest();

        Assert.areEqual(DMT_Constants.FEATURE_GC_STATE_GREEN, green.state, 'Each product within its table term: ' + green.message);
        Assert.areEqual(DMT_Constants.FEATURE_GC_STATE_YELLOW, yellow.state, 'DELE and REAC exceed their table term');
        Assert.isTrue(yellow.message.contains('DELE product') && yellow.message.contains('REAC product'), 'Products listed: ' + yellow.message);
        Assert.isFalse(yellow.message.contains('FOEX'), 'FOEX within the Derivatives term: ' + yellow.message);
        Assert.areEqual(DMT_Constants.FEATURE_GC_STATE_GREEN, derivativesOnly.state, 'Without restriction records every product is compared with the Derivatives terms');
    }

    // CIBGLOBALD-4613 - Enhancement to existing process: the risk line terms of a line are queried once per transaction and filtered by risk type in memory (DMT_Passport_Selector)
    @isTest
    private static void riskLineTermCacheTest() {
        DMT_Line__c childLine = [SELECT Id, DMT_Parent_Line__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        // The factory builds both lines in one insert, so the parent link is set here
        childLine.DMT_Parent_Line__c = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00001' LIMIT 1].Id;
        TriggerBypass.setBypass();
        update childLine;
        TriggerBypass.removeBypass();
        DMT_UTIL.createRiskLineTermRecord(new Map<Schema.SObjectField, Object>{
            DMT_Risk_Line_Term__c.DMT_Line__c => childLine.Id,
            DMT_Risk_Line_Term__c.DMT_Init_Term__c => '0',
            DMT_Risk_Line_Term__c.DMT_End_Term__c => '2',
            DMT_Risk_Line_Term__c.DMT_Amount__c => 500,
            DMT_Risk_Line_Term__c.DMT_Risk_Type__c => DMT_Constants.RSK_DEPOS
        });
        Set<String> derivatives = new Set<String>{ DMT_Constants.RSK_DERIVATIVES };
        DMT_Passport_Selector.clearTransactionCache();

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Map<Id, List<DMT_Risk_Line_Term__c>> byLine = DMT_Passport_Selector.getRiskLineTermsByLines(new Set<Id>{ childLine.Id, childLine.DMT_Parent_Line__c }, derivatives);
        List<DMT_Risk_Line_Term__c> childTables = DMT_Passport_Selector.getRiskLineTerm(childLine.Id, new Set<String>{ DMT_Constants.RSK_DERIVATIVES, DMT_Constants.RSK_DEPOS });
        List<DMT_Risk_Line_Term__c> parentDerivatives = DMT_Passport_Selector.getRiskLineTerm(childLine.DMT_Parent_Line__c);
        List<DMT_Risk_Line_Term__c> byExternalId = DMT_Passport_Selector.getRiskLineTerm('00001');
        Integer queriesWithCache = Limits.getQueries() - queriesBefore;
        DMT_Passport_Selector.clearTransactionCache();
        List<DMT_Risk_Line_Term__c> afterClear = DMT_Passport_Selector.getRiskLineTerm(childLine.Id);
        Integer queriesAfterClear = Limits.getQueries() - queriesBefore;
        Test.stopTest();

        Assert.areEqual(1, byLine.get(childLine.Id).size(), 'Child line has one Derivatives term');
        Assert.areEqual(0, byLine.get(childLine.DMT_Parent_Line__c).size(), 'Parent line has no Derivatives term');
        Assert.areEqual(2, childTables.size(), 'Derivatives and Depos terms of the child line from the cache');
        Assert.areEqual(0, parentDerivatives.size(), 'Parent line read from the cache');
        Assert.areEqual(0, byExternalId.size(), 'A value that is not a record Id returns no terms');
        Assert.areEqual(1, queriesWithCache, 'Line and parent line loaded in one query, later reads from the cache');
        Assert.areEqual(1, afterClear.size(), 'After clearing the cache the line is queried again');
        Assert.areEqual(2, queriesAfterClear, 'Clearing the cache runs a new query');
    }

    // CIBGLOBALD-4613 - Enhancement to existing process: product items of a line and its parent line come in one query and later reads use the transaction cache (DMT_Passport_Selector)
    @isTest
    private static void productLineItemCacheTest() {
        DMT_Line__c childLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        DMT_Line__c parentLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00001' LIMIT 1];
        Integer childItems = [SELECT COUNT() FROM DMT_Line_Product_Item__c WHERE Line__c = :childLine.Id];
        DMT_Passport_Selector.clearTransactionCache();

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Map<Id, List<DMT_Line_Product_Item__c>> byLine = DMT_Passport_Selector.getProductLineItemsByLines(new Set<Id>{ childLine.Id, parentLine.Id });
        List<DMT_Line_Product_Item__c> childAgain = DMT_Passport_Selector.getProductLineItems(childLine.Id);
        List<DMT_Line_Product_Item__c> byExternalId = DMT_Passport_Selector.getProductLineItems('00002');
        Integer queriesUsed = Limits.getQueries() - queriesBefore;
        Test.stopTest();

        Assert.areEqual(childItems, byLine.get(childLine.Id).size(), 'Child line product items');
        Assert.areEqual(childItems, childAgain.size(), 'Same product items from the cache');
        Assert.areEqual(0, byExternalId.size(), 'A value that is not a record Id returns no product items');
        Assert.areEqual(1, queriesUsed, 'Line and parent line product items loaded in one query');
    }

    // CIBGLOBALD-4613 - Enhancement to existing process: the OtherProducts renewal check with the line already queried gives the same result as with the Ids and does not query the lines inside the loop
    @isTest
    private static void validationRenovationOtherLinesWithLineTest() {
        DMT_Line__c parentLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        DMT_Line__c childLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00003' LIMIT 1];
        // The factory builds the lines without parent link, so it is set here
        childLine.DMT_Parent_Line__c = parentLine.Id;
        TriggerBypass.setBypass();
        update childLine;
        TriggerBypass.removeBypass();
        insert new List<DMT_Risk_Line_Term__c>{
            DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.DMT_Line__c => parentLine.Id,
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '12',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 5000
            }),
            DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.DMT_Line__c => childLine.Id,
                DMT_Risk_Line_Term__c.DMT_End_Term__c => '12',
                DMT_Risk_Line_Term__c.DMT_Amount__c => 6000
            })
        };
        DMT_Line__c payloadLine = DMT_Passport_Selector.getLine(childLine.Id);
        DMT_Passport_Selector.clearTransactionCache();

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Boolean withLine = DMT_LineFeatureGenCons_Calc.validationRenovationOtherLines(payloadLine);
        Integer queriesWithLine = Limits.getQueries() - queriesBefore;
        Boolean withIds = DMT_LineFeatureGenCons_Calc.validationRenovationOtherLines(childLine.Id, parentLine.Id);
        Test.stopTest();

        Assert.isTrue(withLine, 'Child risk amount greater than the parent one: renewal with changes');
        Assert.areEqual(withIds, withLine, 'Same result with the line and with the Ids');
        Assert.areEqual(1, queriesWithLine, 'Only the risk line terms of line and parent are queried');
    }
}
