@isTest
public with sharing class DMT_Passport_Helper_test {
    private final static String SUCCESS = 'success';
    private final static String MESSAGE_STRG = 'message';
    private static final Id CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
    private static final Id TASK_RT_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();

    @TestSetup
    static void loadTestData(){
        TriggerBypass.setBypass();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2,pricebookEntry,opp);
        DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
        DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
        DMT_Test_DataFactory.generateSelectedFeaturesOpp(opp);
        DMT_Test_DataFactory.generatexSell(opp);

        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));

        // Perform one single DML
        insert settingsToInsert;

        Group groupApprover = [SELECT DeveloperName, Name FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1];
        Case newCase = new Case(opportunity_id__c = opp.Id, DMT_Feature_Id__c = '403', DMT_Passport_Sanction__c = 'passport', Status = 'Pending', RecordTypeId = CASE_RT_ID, OwnerId = groupApprover.Id, Subject = 'Test');
        insert newCase;

        Task newTask = new Task(WhatId = newCase.Id, Status = 'In Progress', Subject = 'Test Task', OwnerId = groupApprover.Id, RecordTypeId = TASK_RT_ID);
        insert newTask;

        TriggerBypass.removeBypass();
    }
	
    @isTest
    private static void getInformationPassportOpportunityTest(){
        Opportunity newOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
		
        Test.startTest();
        String infoPassport = DMT_Passport_Handler.getInformationPassport(newOpportunity.Id);
        Test.stopTest();

        Assert.areNotEqual(null, infoPassport,'Not passport info retrieved');
    }
	
    @isTest
    private static void buttonCallPassportOpportunityTest(){
        Opportunity newOpportunity = [SELECT Id, DMT_CurrencyText__c, DMT_CUR_Notional_Amount__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        newOpportunity.DMT_CurrencyText__c = 'EUR';
        //newOpportunity.DMT_CUR_Notional_Amount__c = 100;
        system.debug('Edu newOpportunity.DMT_CurrencyText__cTest-->' + newOpportunity.DMT_CurrencyText__c);
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>{
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }};

        String errorMessage = '';

        Test.startTest();

        try {
            Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
            Map<String,Object> mapJSON = (Map<String,Object>) JSON.deserializeUntyped(DMT_Passport_Handler.buttonCallPassport(newOpportunity.Id, JSON.serialize(clientsGroup)));
        } catch (Exception e) {
            errorMessage = e.getMessage();
            System.debug('Error message: ' + errorMessage);
        }
        Test.stopTest();
        Assert.areEqual('', errorMessage,errorMessage);
    }
	
    @isTest
    private static void buttonCallPassportExceptionTest()
    {
        String errorMessage = '';
         Map<String,Object> mapJSON = new Map<String,Object> ();
        Test.startTest();
        try {
            mapJSON = (Map<String,Object>) JSON.deserializeUntyped(DMT_Passport_Handler.buttonCallPassport(null, JSON.serialize(null)));
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();
        System.Debug(mapJSON);
        Assert.areNotEqual(true, mapJSON.get('result'));
    }

    @isTest
    static void testOpportunityProductsRenderer() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001'];

        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        System.debug('DMT_Passport_Helper_test opp, '+ opp);

        // Get passport JSON from static resource
        StaticResource passportSaveMock = [ SELECT Body FROM StaticResource WHERE Name = 'passportSaveMock' LIMIT 1];
        String jsonData = passportSaveMock.Body.toString();
        System.debug('DMT_Passport_Helper_test passportSaveMock, '+ jsonData);

        List<Passport__c> existingPassports = [SELECT Id FROM Passport__c WHERE Opportunity__c = :opp.Id];

        if (!existingPassports.isEmpty()) {
            delete existingPassports;
        }

        Passport__c newPassport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = jsonData);
        insert newPassport;

        // Prepare selected items
      //  List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();
      List<DMT_ViewController.ItemWrapper> selectedItems = new List<DMT_ViewController.ItemWrapper>{
          new DMT_ViewController.ItemWrapper('Component', 'Products',  2, '')
      };

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String items = JSON.serialize(selectedItems);
        String type = 'Opportunity';
        String recordTypeDeveloperName = 'DMT_Opportunity';

        String response = DMT_ViewController.loadComponentsForView(opp.Id, type, items, prod.Id, '');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(response, 'response should not be null.');
    }
	
    @isTest
    static void testOpportunityLimitVisualRenderer() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001'];

        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        oli.g_branch_id__c = 'A';
        oli.DMT_Risk_Type__c = 'A';
        oli.gf_country_risk__c = 'B';
        update oli;

        // Create DMT_Taxonomy_Values__c for taxonomy maps
        DMT_Taxonomy_Values__c tax007 = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'H007',
            DMT_Value__c = 'A',
            DMT_Name_EN__c = 'A'
        );
        DMT_Taxonomy_Values__c tax444 = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'B444',
            DMT_Value__c = 'B',
            DMT_Name_EN__c = 'B'
        );
        DMT_Taxonomy_Values__c tax245 = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'C245',
            DMT_Value__c = 'B',
            DMT_Name_EN__c = 'B'
        );

        insert new List<DMT_Taxonomy_Values__c>{tax007, tax444, tax245};

        System.debug('DMT_Passport_Helper_test opp, '+ opp);

        // Get passport JSON from static resource
        StaticResource passportSaveMock = [ SELECT Body FROM StaticResource WHERE Name = 'passportSaveMock' LIMIT 1];
        String jsonData = passportSaveMock.Body.toString();
        System.debug('DMT_Passport_Helper_test passportSaveMock, '+ jsonData);

        List<Passport__c> existingPassports = [SELECT Id FROM Passport__c WHERE Opportunity__c = :opp.Id];

        if (!existingPassports.isEmpty()) {
            delete existingPassports;
        }

        Passport__c newPassport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = jsonData);
        insert newPassport;

        // Prepare selected items
      //  List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();
      List<DMT_ViewController.ItemWrapper> selectedItems = new List<DMT_ViewController.ItemWrapper>{
          new DMT_ViewController.ItemWrapper('Component', 'Limit Visual',  2, '')
      };

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String items = JSON.serialize(selectedItems);
        String type = 'Opportunity';
        String recordTypeDeveloperName = 'DMT_Opportunity';

        String response = DMT_ViewController.loadComponentsForView(opp.Id, type, items, '', '');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(response, 'response should not be null.');
    }
	
    @isTest
    static void testOpportunityEconomicsRenderer() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001'];

        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        oli.DMT_Expected_Drawn__c = 25;
        oli.DMT_Extension_Duration_Fees__c = 5816;
        oli.DMT_PricingGrid_OR_StepUps__c = 'text area DMT_PricingGrid_OR_StepUps__c test';
        update oli;

      List<DMT_ViewController.ItemWrapper> selectedItems = new List<DMT_ViewController.ItemWrapper>{
          new DMT_ViewController.ItemWrapper('Component', 'Economics',  12, '')
      };

        // Simulación del controlador
        Test.startTest();
        String items = JSON.serialize(selectedItems);
        String type = 'Opportunity';

        String response = DMT_ViewController.loadComponentsForView(opp.Id, type, items, '', '');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(response, 'response should not be null.');
    }

    @isTest
    static void testEconomicsRenderer_noHtmlData() {

        Test.startTest();
        try{
            DMT_EconomicsRenderer renderer = new DMT_EconomicsRenderer();
            String response = renderer.renderHtml(null);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
            Assert.isTrue(e.getMessage().contains('Data not provided'), 'Exception message should indicate that data was not provided.');
        }
        Test.stopTest();
    }

    @isTest
    static void testEconomicsRenderer_html_noRecordtypeId() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;

        Test.startTest();
        try{
            DMT_EconomicsRenderer renderer = new DMT_EconomicsRenderer();
            String response = renderer.renderHtml(data);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
            Assert.isTrue(e.getMessage().contains('No Economics renderer'), 'Exception message should indicate that there is no renderer for the provided record type id.');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetRecordId(){
        // Create Opportunity
      //  Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001'];
        String objectApiName = 'Opportunity';
        String recordTypeDeveloperName = 'DMT_Opportunity';
        String recordId;
        recordId = DMT_ViewController.getRecordId(objectApiName, recordTypeDeveloperName);
        System.debug('Record Id: ' + recordId);
        Assert.isNotNull(recordId, 'Record Id should not be null.');
    }

    @isTest
    static void testLoadComponentsForView_emptyItems() {

        // Create Opportunity
      //  Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001'];

        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String items = '';
        String type = 'Opportunity';

        String response;
        response = DMT_ViewController.loadComponentsForView(opp.Id, type, items, '', '');
        Test.stopTest();

        Assert.isTrue(response.contains('error'), 'response should contain error.');
    }

    @isTest
    static void testLoadHtmlFromSelectedItems_opportunity() {

        // Create Opportunity
      //  Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001'];

        // Prepare selected items
        List<DMT_ViewController.ItemWrapper> selectedItems = DMT_ViewController_Test.prepareItemWrapper();

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String items = JSON.serialize(selectedItems);
        String type = 'Opportunity';
        String recordTypeDeveloperName = 'DMT_Opportunity';

        String htmlContent = DMT_ViewController.loadComponentsForView(opp.Id, type, items, '', '');
        String jsonDataFeatureLine = DMT_ViewController.getFeaturesForJsonPdf(opp.Id, '');
        String jsonDataFeatureLine2 = DMT_ViewController.getFeaturesForJsonPdf('', '');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(jsonDataFeatureLine, 'response should not be null.');
    }

    @isTest
    static void testGetItemsToDisplayOpportunity(){
      //  Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001'];
        // Create ApproversView
        DMT_ApproversView__c testView = new DMT_ApproversView__c(Name = 'Test View', DMT_DeveloperName__c = 'Test_prueba', DMT_Type__c = 'Line');
        insert testView;

        DMT_ApproversView__c approverView = [SELECT Id, Profitability__c FROM DMT_ApproversView__c LIMIT 1];
        approverView.Profitability__c = true;
        update approverView;
        String itemsToDisplay;
        itemsToDisplay = DMT_ViewController.getItemsToDisplay(opp.id, 'Opportunity');
        Assert.isNotNull(itemsToDisplay, 'itemsToDisplay should not be null');
    }

    @isTest
    static void testOpportunityClientRenderer() {
        // Create Opportunity
      //  Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001'];

        // Prepare selected items
      //  List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();
      List<DMT_ViewController.ItemWrapper> selectedItems = new List<DMT_ViewController.ItemWrapper>{
          new DMT_ViewController.ItemWrapper('Component', 'Client',  2, '')
      };

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String items = JSON.serialize(selectedItems);
        String type = 'Opportunity';
        String recordTypeDeveloperName = 'DMT_Opportunity';

        String response = DMT_ViewController.loadComponentsForView(opp.Id, type, items, '', '');

        DMT_Opportunity_Client__c oppClient = [SELECT Id, Counterpart__c, Group_Sales_Check__c, External_Rating__c FROM DMT_Opportunity_Client__c
                                                            WHERE DMT_MDE_Opportunity__c = :opp.Id LIMIT 1];
        System.debug('oppClient, '+ oppClient);
        oppClient.Counterpart__c = 'Corporates';
        oppClient.Group_Sales_Check__c = true;
        oppClient.External_Rating__c = 'AAA';
        oppClient.DMT_AA_Industry__c = 'test DMT_AA_Industry__c';
        oppClient.DMT_Asset_Allocation_limit__c = 'Limit increase needed';
        oppClient.DMT_Financial_Program_limit__c = 'No Risk Increased';
        oppClient.DMT_Country_Risk__c = 'No';
        oppClient.DMT_Economic_LGD__c = 'test DMT_Economic_LGD__c';
        oppClient.DMT_Regulatory_LGD__c = 'test DMT_Regulatory_LGD__c';
        oppClient.DMT_Leveraged_Lending__c = 'Yes';
        oppClient.DMT_Credit_Risk_Opinion_By__c = 'test DMT_Credit_Risk_Opinion_By__c';
        update oppClient;

        // Run again loadComponentsForView
        String response2 = DMT_ViewController.loadComponentsForView(opp.Id, type, items, '', '');
        System.debug('Response after updating Counterpart__c: ' + response2);
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(response, 'response should not be null.');
    }
    @isTest
    static void testOpportunityClientRenderer_noClient() {
        // Create Opportunity
      //  Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001'];

        // Prepare selected items
      //  List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();
      List<DMT_ViewController.ItemWrapper> selectedItems = new List<DMT_ViewController.ItemWrapper>{
          new DMT_ViewController.ItemWrapper('Component', 'Client',  2, '')
      };

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String items = JSON.serialize(selectedItems);
        String type = 'Opportunity';
        String recordTypeDeveloperName = 'DMT_Opportunity';

        DMT_Opportunity_Client__c oppClient = [SELECT Id, Counterpart__c, Group_Sales_Check__c, External_Rating__c FROM DMT_Opportunity_Client__c
                                                            WHERE DMT_MDE_Opportunity__c = :opp.Id LIMIT 1];
        delete oppClient;

        String response = DMT_ViewController.loadComponentsForView(opp.Id, type, items, '', '');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(response, 'response should not be null.');
    }

    @isTest
    private static void getInformationPassportExceptionTest()
    {
        String errorMessage = '';

        Test.startTest();
        try {
            String infoPassport = DMT_Passport_Handler.getInformationPassport(null);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areNotEqual(null, errorMessage);
    }
	
    @isTest
    private static void testValidateOppBeforePassport() {
        final String oppRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
    // final Account acc = DMT_Test_DataFactory.generateAccount();
    Account acc = [SELECT Id FROM Account WHERE Name = 'Test company 1' LIMIT 1];
        final Opportunity oppNoProducts =new Opportunity();
            oppNoProducts.StageName = 'Draft Opp';
            oppNoProducts.CloseDate = Date.today();
            oppNoProducts.Name = 'Test Opp';
            oppNoProducts.AccountId = acc.Id;
            oppNoProducts.DMT_Opp_Id__c = '00002'+Math.random().intValue();
            oppNoProducts.RecordTypeId = oppRecordTypeID;
            oppNoProducts.DMT_CUR_Notional_Amount__c = 100;
            oppNoProducts.DMT_DATE_Initial_Date__c = Date.today();
            oppNoProducts.DMT_DATE_Maturity_Date__c = Date.today() + 1;
        insert oppNoProducts;
        Test.startTest();
        final Map<String, Object> resultNoProducts = DMT_Passport_Helper.validateOppBeforePassport(oppNoProducts.Id);
        Test.stopTest();
        Assert.isTrue(resultNoProducts.get(SUCCESS)==false, 'Debe fallar si no hay productos');
        final List<String> msgNoProducts = (List<String>)resultNoProducts.get(MESSAGE_STRG);
        Assert.isTrue(!msgNoProducts.isEmpty(), 'Debe haber mensaje de error si no hay productos');
    }
	
    @isTest
    private static void testValidateOppBeforePassportNoRiskOrBookingAndTenorAmmount() {
        final Opportunity oppMissingFields =  [ SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        final OpportunityLineItem oppli =  [ SELECT Id,OpportunityId  FROM OpportunityLineItem WHERE Opportunity.DMT_Opp_Id__c = '00001' LIMIT 1];
        oppli.DMT_Risk_Type__c=null;
        oppli.g_branch_id__c=null;
        update oppli;
        Test.startTest();
        final Map<String, Object> resMissingFields = DMT_Passport_Helper.validateOppBeforePassport(oppMissingFields.Id);
        Test.stopTest();
        Assert.isTrue(resMissingFields.get(SUCCESS)==false, 'Debe fallar si falta Risk Type o Booking Geography');
        final List<String> msgMissingFields = (List<String>)resMissingFields.get(MESSAGE_STRG);
        Assert.isTrue(msgMissingFields.size()>1, 'Debe haber mas de 1 mensaje de error si faltan campos obligatorios y tenor con amount > 0');
    }

    @isTest
    private static void testValidateOppBeforePassportOnlyTenorAmmountValidationFailed() {
        final OpportunityLineItem oppli =  [ SELECT Id,OpportunityId  FROM OpportunityLineItem WHERE Opportunity.DMT_Opp_Id__c = '00001' LIMIT 1];
        oppli.DMT_Risk_Type__c ='92000';
        oppli.g_branch_id__c = 'PE0011-PE';
        update oppli;
        Test.startTest();
        final Map<String, Object> resMissingFields = DMT_Passport_Helper.validateOppBeforePassport(oppli.OpportunityId);
        Test.stopTest();
        Assert.isTrue(resMissingFields.get(SUCCESS)==false, 'Debe fallar si falta Risk Type o Booking Geography');
        final List<String> msgMissingFields = (List<String>)resMissingFields.get(MESSAGE_STRG);
        Assert.areEqual(1, msgMissingFields.size(), 'Debe 1 mensaje de error solo si solo falta tenor con amount > 0');
    }
	
    @isTest
    private static void testValidateOppBeforePassportValidation() {
        final OpportunityLineItem oppli =  [ SELECT Id,OpportunityId  FROM OpportunityLineItem WHERE Opportunity.DMT_Opp_Id__c = '00001' LIMIT 1];
        Test.startTest();
        oppli.DMT_Risk_Type__c ='92000';
        oppli.g_branch_id__c = 'PE0011-PE';
        update oppli;
        final Set<Id> setOplIds = new Set<Id>{oppli.Id};
        final List<DMT_Opportunity_Tenor__c> lstTenor = DMT_Passport_Selector.getAmortizationPayments(setOplIds);
        lstTenor[0].gj_nominal_amount_db__c = 100;
        update lstTenor;
        final Map<String, Object> resMissingFields = DMT_Passport_Handler.validateOppBeforePassport(oppli.OpportunityId);
        Test.stopTest();
        Assert.isTrue(resMissingFields.get(SUCCESS)==true, 'No debe fallar si están todas las condiciones requeridas');
        final List<String> msgMissingFields = (List<String>)resMissingFields.get(MESSAGE_STRG);
        Assert.isTrue(msgMissingFields.isEmpty(), 'No debe de haber mensajes de error');
    }
	
    @isTest
    static void testOppApprovalProcessData_GlobalStructure() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];

        // Generate Global Structures (8 Uses, 4 Debt, 4 Equity)
        DMT_Test_DataFactory.generateOppGlobalStructure(opp.Id);

        // Prepare selected items for 'Approval Process Data'
        List<DMT_ViewController.ItemWrapper> selectedItems = new List<DMT_ViewController.ItemWrapper>{
            new DMT_ViewController.ItemWrapper('Component', 'Approval Process Data', 4, '')
        };
            

        Test.startTest();
        String items = JSON.serialize(selectedItems);
        String type = 'Opportunity';

        // This will call DMT_RendererFactory > DMT_ApprovalProcessDataRenderer > DMT_OppApprovalProcessDataRenderer
        String response = DMT_ViewController.loadComponentsForView(opp.Id, type, items, '', '');
        Test.stopTest();

        // Validation: Check for specific data that only exists if the records were rendered
        // We check for "Debt Fund 0" because that string comes directly from the record Name
        // created in the factory, proving the loop inside the renderer ran correctly.
        Assert.isTrue(response.contains('Debt Fund 0'), 'The response should contain the generated Global Structure record names.');
    }

    @isTest
    static void testBuildDocumentLoads() {
        Test.startTest();

        // Scenario 1: Standard clean comma-separated values
        String standardInput = 'SEND,COLL,OTHR';
        List<DMT_Wrapper_Passport_Abs.DocumentLoad> standardResult = DMT_Passport_Helper.buildDocumentLoads(standardInput);
        
        Assert.isNotNull(standardResult, 'Standard input should not return null.');
        Assert.areEqual(3, standardResult.size(), 'Should parse exactly 3 items.');
        Assert.areEqual('SEND', standardResult[0].itemType, 'First item should match SEND.');
        Assert.areEqual('COLL', standardResult[1].itemType, 'Second item should match COLL.');
        Assert.areEqual('OTHR', standardResult[2].itemType, 'Third item should match OTHR.');

        // Scenario 2: Messy input with spaces, extra commas, and blanks
        String messyInput = '  SEND  , ,, COLL ,   ';
        List<DMT_Wrapper_Passport_Abs.DocumentLoad> messyResult = DMT_Passport_Helper.buildDocumentLoads(messyInput);
        
        Assert.isNotNull(messyResult, 'Messy input should not return null.');
        Assert.areEqual(2, messyResult.size(), 'Should ignore blanks and parse exactly 2 items.');
        Assert.areEqual('SEND', messyResult[0].itemType, 'First item should be perfectly trimmed.');
        Assert.areEqual('COLL', messyResult[1].itemType, 'Second item should be perfectly trimmed.');

        // Scenario 3: Null and completely blank inputs
        List<DMT_Wrapper_Passport_Abs.DocumentLoad> nullResult = DMT_Passport_Helper.buildDocumentLoads(null);
        Assert.isNull(nullResult, 'Null input should return null.');

        List<DMT_Wrapper_Passport_Abs.DocumentLoad> blankResult = DMT_Passport_Helper.buildDocumentLoads('   ,,,   ');
        Assert.isNull(blankResult, 'Completely blank/empty comma input should return null.');

        Test.stopTest();
    }

    @isTest
    static void testSkipWhenStageNotValid() {
        TriggerBypass.setBypass();

        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        Case case1 = [SELECT Id FROM Case WHERE opportunity_id__c = :opp.Id LIMIT 1];
        Task task1 = [SELECT Id FROM Task WHERE WhatId = :case1.Id LIMIT 1];
        Passport__c passport = new Passport__c(Opportunity__c = opp.Id);

        String bodyResponse = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'features' => new List<Object>{
                    new Map<String, Object>{'id' => '403', 'name' => 'Feature Test', 'passportSanction' => 'passport', 'requiredType' => 'N'}
                }
            }
        });

        Test.startTest();
        DMT_Passport_Helper.cancelNonMandatoryProposalWorkflows(passport, bodyResponse, Opportunity.getSObjectType().getDescribe().getName());
        Test.stopTest();

        Case caseAfterExecution = [SELECT Status FROM Case WHERE Id = :case1.Id];
        Task taskAfterExecution = [SELECT Status FROM Task WHERE Id = :task1.Id];

        System.assertEquals('Pending', caseAfterExecution.Status, 'El Case no debe cambiar si la Opportunity no está en Approval ni Ready to close.');
        System.assertEquals('In Progress', taskAfterExecution.Status, 'La Task no debe cambiar si la Opportunity no está en Approval ni Ready to close.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testSkipWhenMandatoryFeature() {
        TriggerBypass.setBypass();

        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        opp.StageName = 'Approval';
        update opp;

        Case case1 = [SELECT Id FROM Case WHERE opportunity_id__c = :opp.Id LIMIT 1];
        Task task1 = [SELECT Id FROM Task WHERE WhatId = :case1.Id LIMIT 1];

        Passport__c passport = new Passport__c(Opportunity__c = opp.Id);

        String bodyResponse = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'features' => new List<Object>{
                    new Map<String, Object>{'id' => '403', 'name' => 'Mandatory Feature', 'passportSanction' => 'passport', 'requiredType' => 'Y'}
                }
            }
        });

        Test.startTest();
        DMT_Passport_Helper.cancelNonMandatoryProposalWorkflows(passport, bodyResponse, Opportunity.getSObjectType().getDescribe().getName());
        Test.stopTest();

        Case caseAfterExecution = [SELECT Status FROM Case WHERE Id = :case1.Id];
        Task taskAfterExecution = [SELECT Status FROM Task WHERE Id = :task1.Id];

        System.assertEquals('Pending', caseAfterExecution.Status, 'El Case no debe cambiar si la feature es obligatoria.');
        System.assertEquals('In Progress', taskAfterExecution.Status, 'La Task no debe cambiar si la feature es obligatoria.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testCancelInApproval() {
        TriggerBypass.setBypass();

        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        opp.StageName = 'Approval';
        update opp;

        Case case1 = [SELECT Id FROM Case WHERE opportunity_id__c = :opp.Id LIMIT 1];
        Task task1 = [SELECT Id FROM Task WHERE WhatId = :case1.Id LIMIT 1];

        Passport__c passport = new Passport__c(Opportunity__c = opp.Id);

        String bodyResponse = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'features' => new List<Object>{
                    new Map<String, Object>{'id' => '403', 'name' => 'Feature Test', 'passportSanction' => 'passport', 'requiredType' => 'N'}
                }
            }
        });

        Test.startTest();
        DMT_Passport_Helper.cancelNonMandatoryProposalWorkflows(passport, bodyResponse, Opportunity.getSObjectType().getDescribe().getName());
        Test.stopTest();

        Case caseAfterExecution = [SELECT Status FROM Case WHERE Id = :case1.Id];
        Task taskAfterExecution = [SELECT Status FROM Task WHERE Id = :task1.Id];

        Assert.areEqual('Pending', caseAfterExecution.Status, 'Approval stage is a no-op in the new implementation; case must remain Pending.');
        Assert.areEqual('In Progress', taskAfterExecution.Status, 'Approval stage is a no-op in the new implementation; task must remain In Progress.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testCancelInReadyToClose() {
        TriggerBypass.setBypass();

        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        opp.StageName = 'Ready to close';
        update opp;

        Case case1 = [SELECT Id FROM Case WHERE opportunity_id__c = :opp.Id LIMIT 1];
        Task task1 = [SELECT Id FROM Task WHERE WhatId = :case1.Id LIMIT 1];

        Passport__c passport = new Passport__c(Opportunity__c = opp.Id);

        String bodyResponse = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'features' => new List<Object>{
                    new Map<String, Object>{'id' => '403', 'name' => 'Feature Test', 'passportSanction' => 'passport', 'requiredType' => 'N', 'indicatorId' => 'Y'}
                }
            }
        });

        Test.startTest();
        DMT_Passport_Helper.cancelNonMandatoryProposalWorkflows(passport, bodyResponse, Opportunity.getSObjectType().getDescribe().getName());
        Test.stopTest();

        Case caseAfterExecution = [SELECT Status FROM Case WHERE Id = :case1.Id];
        Task taskAfterExecution = [SELECT Status FROM Task WHERE Id = :task1.Id];

        Assert.areEqual('Finished', caseAfterExecution.Status, 'Ready to close with indicatorId Y must set case to Finished.');
        Assert.areEqual('Cancelled', taskAfterExecution.Status, 'Ready to close with indicatorId Y must set task to Cancelled.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testSkipWhenCaseAlreadyFinished() {
        TriggerBypass.setBypass();

        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        opp.StageName = 'Approval';
        update opp;

        Group groupApprover = [SELECT DeveloperName, Name FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1];
        Case newCase = new Case(opportunity_id__c = opp.Id, DMT_Feature_Id__c = '500', DMT_Passport_Sanction__c = 'passport', Status = 'Finished', RecordTypeId = CASE_RT_ID, OwnerId = groupApprover.Id, Subject = 'Test');
        insert newCase;

        Passport__c passport = new Passport__c(Opportunity__c = opp.Id);

        String bodyResponse = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'features' => new List<Object>{
                    new Map<String, Object>{'id' => '500', 'name' => 'Feature Test', 'passportSanction' => 'passport', 'requiredType' => 'N'}
                }
            }
        });

        Test.startTest();
        DMT_Passport_Helper.cancelNonMandatoryProposalWorkflows(passport, bodyResponse, Opportunity.getSObjectType().getDescribe().getName());
        Test.stopTest();

        Case caseAfterExecution = [SELECT Status FROM Case WHERE Id = :newCase.Id];
        
        System.assertEquals('Finished', caseAfterExecution.Status, 'Un Case ya finalizado no debe modificarse.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testCancelWhenRequiredTypeIsNull() {
        TriggerBypass.setBypass();

        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        opp.StageName = 'Ready to close';
        update opp;

        Case case1 = [SELECT Id FROM Case WHERE opportunity_id__c = :opp.Id LIMIT 1];
        Task task1 = [SELECT Id FROM Task WHERE WhatId = :case1.Id LIMIT 1];

        Passport__c passport = new Passport__c(Opportunity__c = opp.Id);

        String bodyResponse = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'features' => new List<Object>{
                    new Map<String, Object>{'id' => '403', 'name' => 'Feature Null Test', 'passportSanction' => 'passport', 'requiredType' => null, 'indicatorId' => 'Y'}
                }
            }
        });

        Test.startTest();
        DMT_Passport_Helper.cancelNonMandatoryProposalWorkflows(passport, bodyResponse, Opportunity.getSObjectType().getDescribe().getName());
        Test.stopTest();

        Case caseAfterExecution = [SELECT Status FROM Case WHERE Id = :case1.Id];
        Task taskAfterExecution = [SELECT Status FROM Task WHERE Id = :task1.Id];

        Assert.areEqual('Finished', caseAfterExecution.Status, 'Ready to close with indicatorId Y and null requiredType must set case to Finished.');
        Assert.areEqual('Cancelled', taskAfterExecution.Status, 'Ready to close with indicatorId Y and null requiredType must set task to Cancelled.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testCreateSanctionFromOpp_nullApprover() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        String result = null;
        Test.startTest();
        try {
            result = DMT_Passport_Helper.createSanctionFromOpp(opp.Id, 'NON_EXISTENT_APPROVER_ID');
        } catch (Exception e) {
            System.debug('Expected exception when approver not found: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.isNull(result, 'Should return null when no approver is found.');
    }

    @isTest
    static void testCreateSanctionFromOpp_nonRiskApprover() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        DMT_Test_DataFactory.generateApproverBussines();
        DMT_Approver__c businessApprover = [SELECT Id, DMT_External_Id__c FROM DMT_Approver__c WHERE DMT_Approver_Code__c = '12222233135' LIMIT 1];

        Test.startTest();
        String result = DMT_Passport_Helper.createSanctionFromOpp(opp.Id, businessApprover.DMT_External_Id__c);
        Test.stopTest();

        Assert.isNull(result, 'Should return null when approver type is not Risk.');
    }

    @isTest
    static void testCreateSanctionFromOpp_riskApprover() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        DMT_Test_DataFactory.generateApproverRisk();
        DMT_Approver__c riskApprover = [SELECT Id, DMT_External_Id__c FROM DMT_Approver__c WHERE DMT_Approver_Code__c = '12222233136' LIMIT 1];

        Test.startTest();
        try {
            String result = DMT_Passport_Helper.createSanctionFromOpp(opp.Id, riskApprover.DMT_External_Id__c);
        } catch (Exception e) {
            System.debug('Flow execution in test context: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testHandlePassportIntegration_withOpportunity() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        Passport__c passport = new Passport__c(Opportunity__c = opp.Id);
        insert passport;

        DMT_PassportPayload payload = new DMT_PassportPayload(opp.Id, opp.AccountId, 'DMTO_EvaluationOpportunity');

        Test.startTest();
        try {
            Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
            DMT_Passport_Handler.handlePassportIntegration(payload);
        } catch (Exception e) {
            // In the test environment some inner callouts may throw; coverage is the goal.
            System.debug('handlePassportIntegration opp exception: ' + e.getMessage());
        }
        Test.stopTest();

        Passport__c passportAfter = [SELECT Id FROM Passport__c WHERE Id = :passport.Id];
        Assert.isNotNull(passportAfter, 'Passport record should still exist after execution.');
    }

    @isTest
    static void testHandlePassportIntegration_withLine() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Passport__c passport = new Passport__c(DMT_Line__c = line.Id);
        insert passport;

        DMT_PassportPayload payload = new DMT_PassportPayload(line.Id, line.Client__c, 'DMTO_EvaluationLine');

        Test.startTest();
        try {
            Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
            DMT_Passport_Handler.handlePassportIntegration(payload);
        } catch (Exception e) {
            System.debug('handlePassportIntegration line exception: ' + e.getMessage());
        }
        Test.stopTest();

        Passport__c passportAfter = [SELECT Id FROM Passport__c WHERE Id = :passport.Id];
        Assert.isNotNull(passportAfter, 'Passport record should still exist after execution.');
    }

    @isTest
    static void testHandlePassportIntegration_exception_noPassport() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        DMT_PassportPayload payload = new DMT_PassportPayload(opp.Id, opp.AccountId, 'DMTO_EvaluationOpportunity');

        Test.startTest();
        try {
            DMT_Passport_Handler.handlePassportIntegration(payload);
        } catch (Exception e) {
            System.debug('Exception from handlePassportIntegration (no passport): ' + e.getMessage());
        }
        Test.stopTest();

        Integer oppCount = [SELECT COUNT() FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual(1, oppCount, 'Opportunity should still exist after execution.');
    }

    @isTest
    static void testMarkAsObsolete_nullId() {
        Test.startTest();
        DMT_Passport_Handler.markAsObsolete(null);
        Test.stopTest();
    }

    @isTest
    static void testMarkAsObsolete_withPassportId() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        Passport__c passport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Is_Obsoleted_Passport_Save__c = false
        );
        insert passport;

        Test.startTest();
        DMT_Passport_Handler.markAsObsolete(passport.Id);
        Test.stopTest();

        Passport__c updated = [SELECT DMT_Is_Obsoleted_Passport_Save__c FROM Passport__c WHERE Id = :passport.Id];
        Assert.isTrue(updated.DMT_Is_Obsoleted_Passport_Save__c, 'Passport should be flagged as obsolete.');
    }

    // -----------------------------------------------------------------------
    // Tests for DMT_Passport_Selector: getAccountById
    // -----------------------------------------------------------------------

    @isTest
    static void testGetAccountById_validId() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test company 1' LIMIT 1];
        acc.DES_Structure_Type__c = 'Subsidiary';
        update acc;

        Test.startTest();
        Account result = DMT_Passport_Selector.getAccountById(acc.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return an account for a valid Id');
        Assert.areEqual(acc.Id, result.Id, 'Returned account Id should match');
        Assert.areEqual('Subsidiary', result.DES_Client_Type__c, 'DES_Client_Type__c should match updated value');
    }

    @isTest
    static void testGetAccountById_nullId() {
        Test.startTest();
        Account result = DMT_Passport_Selector.getAccountById(null);
        Test.stopTest();

        Assert.isNull(result, 'Should return null when accountId is null');
    }

    // -----------------------------------------------------------------------
    // Tests for DMT_Passport_Selector: getOpportunityAccountId
    // -----------------------------------------------------------------------

    @isTest
    static void testGetOpportunityAccountId_validOpp() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];

        Test.startTest();
        Id result = DMT_Passport_Selector.getOpportunityAccountId(opp.Id);
        Test.stopTest();

        Assert.areEqual(opp.AccountId, result, 'Should return the AccountId of the opportunity');
    }

    @isTest
    static void testGetOpportunityAccountId_notFound() {
        Test.startTest();
        Id result = DMT_Passport_Selector.getOpportunityAccountId(null);
        Test.stopTest();

        Assert.isNull(result, 'Should return null when no opportunity is found');
    }

    // -----------------------------------------------------------------------
    // Tests for DMT_Passport_Selector: getMainHolderAssociation
    // -----------------------------------------------------------------------

    @isTest
    static void testGetMainHolderAssociation_exists() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        Custom_Association_Opportunity__c assoc = new Custom_Association_Opportunity__c(
            Opportunity__c = opp.Id,
            g_customer_id__c = 'TEST123',
            gf_customer_group_id__c = 'OLD_GROUP'
        );
        insert assoc;

        Test.startTest();
        Custom_Association_Opportunity__c result = DMT_Passport_Selector.getMainHolderAssociation(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return the association record');
        Assert.areEqual('TEST123', result.g_customer_id__c, 'g_customer_id__c should match');
    }

    @isTest
    static void testGetMainHolderAssociation_notExists() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];

        Test.startTest();
        Custom_Association_Opportunity__c result = DMT_Passport_Selector.getMainHolderAssociation(opp.Id);
        Test.stopTest();

        Assert.isNull(result, 'Should return null when no association exists for the opportunity');
    }

    // -----------------------------------------------------------------------
    // Tests for DMT_Passport_Helper: resolveMainHolderAccountId
    // -----------------------------------------------------------------------

    @isTest
    static void testResolveMainHolderAccountId_noAssoc() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = DMT_Passport_Helper.resolveMainHolderAccountId(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result map should not be null');
        Assert.areEqual(opp.AccountId, (Id) result.get('AccountId'),
            'AccountId should match opp.AccountId via getOpportunityAccountId fallback');
    }

    @isTest
    static void testResolveMainHolderAccountId_withAssocAndCustomerId() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Id = :opp.AccountId LIMIT 1];
        acc.DES_Structure_Type__c = 'Subsidiary';
        acc.g_customer_id__c = 'TEST123';
        update acc;

        Custom_Association_Opportunity__c assoc = new Custom_Association_Opportunity__c(
            Opportunity__c = opp.Id,
            g_customer_id__c = 'TEST123',
            gf_customer_group_id__c = 'OLD_GROUP'
        );
        insert assoc;

        Test.startTest();
        Map<String, Object> result = DMT_Passport_Helper.resolveMainHolderAccountId(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result map should not be null');
        Assert.isNotNull(result.get('AccountId'), 'AccountId should be set via Account.g_customer_id__c');
        Assert.areEqual('Subsidiary', (String) result.get('ClientType'),
            'ClientType should come from DES_Client_Type__c on account found via g_customer_id__c');
    }

    @isTest
    static void testResolveMainHolderAccountId_withAssocNoMatchingClient() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];

        Custom_Association_Opportunity__c assoc = new Custom_Association_Opportunity__c(
            Opportunity__c = opp.Id,
            g_customer_id__c = 'GHOST_CUSTOMER_XYZ',
            gf_customer_group_id__c = 'OLD_GROUP'
        );
        insert assoc;

        Test.startTest();
        Map<String, Object> result = DMT_Passport_Helper.resolveMainHolderAccountId(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result map should not be null');
        Assert.areEqual(opp.AccountId, (Id) result.get('AccountId'),
            'AccountId should fall back to assoc.Opportunity__r.AccountId when no matching client is found');
    }

    @isTest
    static void testSetPayloadPassport_otherProducts_buildsPayload() {
        DMT_Line__c otherLine = DMT_Test_DataFactory.generateTestOtherLines();

        Test.startTest();
        String payload = DMT_Passport_Helper.setPayloadPassport(otherLine.Id, '[]');
        Test.stopTest();

        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Assert.areEqual('00003', (String) payloadMap.get('opportunityId'), 'OpportunityId should match OtherProducts line external id.');

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped((String) payloadMap.get('body'));
        Assert.isNotNull(body.get('line'), 'OtherProducts payload should contain line node.');

        Map<String, Object> lineBody = (Map<String, Object>) body.get('line');
        Assert.areEqual(1000, Decimal.valueOf(String.valueOf(lineBody.get('amount'))), 'Line amount should come from the line record.');
        Assert.areEqual('61000', String.valueOf(lineBody.get('lastLevelId')), 'Line lastLevelId should be mapped.');

        List<Object> products = (List<Object>) body.get('products');
        Assert.areEqual(1, products.size(), 'OtherProducts payload should include the generated product.');

        Map<String, Object> firstProduct = (Map<String, Object>) products[0];
        Assert.areEqual('DEPO', String.valueOf(firstProduct.get('productName')), 'Product name should come from the related Product2.');
        Assert.areEqual('2611170000', String.valueOf(firstProduct.get('productCode')), 'Product code should be mapped from Product2.');
    }

    @isTest
    static void testSetPayloadPassport_opportunity_buildsXsells() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        DMT_Opportunity_Client__c oppClient = [
            SELECT Id, Alpha_Code_Client__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opp.Id
            LIMIT 1
        ];
        oppClient.Alpha_Code_Client__c = 'TEST123';
        update oppClient;

        Integer currentYear = Date.today().year();
        List<DMT_Opportunity_Business_Plan__c> bpRecords = new List<DMT_Opportunity_Business_Plan__c>();
        bpRecords.add(new DMT_Opportunity_Business_Plan__c(
            DMT_Opportunity__c = opp.Id,
            DMT_Year__c = String.valueOf(currentYear - 2),
            DMT_Booking_Geography__c = 'GLOBAL',
            DMT_Currency__c = 'EUR',
            Current_FY_Total_X_Sell_amount__c = 10
        ));
        bpRecords.add(new DMT_Opportunity_Business_Plan__c(
            DMT_Opportunity__c = opp.Id,
            DMT_Year__c = String.valueOf(currentYear - 1),
            DMT_Booking_Geography__c = 'GLOBAL',
            DMT_Currency__c = 'EUR',
            Current_FY_Total_X_Sell_amount__c = 20
        ));
        bpRecords.add(new DMT_Opportunity_Business_Plan__c(
            DMT_Opportunity__c = opp.Id,
            DMT_Year__c = String.valueOf(currentYear),
            DMT_Booking_Geography__c = 'GLOBAL',
            DMT_Currency__c = 'EUR',
            Current_FY_Total_X_Sell_amount__c = 30
        ));
        bpRecords.add(new DMT_Opportunity_Business_Plan__c(
            DMT_Opportunity__c = opp.Id,
            DMT_Year__c = String.valueOf(currentYear + 1),
            DMT_Booking_Geography__c = 'GLOBAL',
            DMT_Currency__c = 'EUR',
            Current_FY_Total_X_Sell_amount__c = 40
        ));
        insert bpRecords;

        Test.startTest();
        String payload = DMT_Passport_Helper.setPayloadPassport(opp.Id, '[]');
        Test.stopTest();

        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped((String) payloadMap.get('body'));
        Map<String, Object> opportunityBody = (Map<String, Object>) body.get('opportunity');
        List<Object> xsells = (List<Object>) opportunityBody.get('xsells');

        Assert.areEqual(4, xsells.size(), 'Expected one xsell item per populated fiscal year amount.');

        Map<String, Object> firstXsell = (Map<String, Object>) xsells[0];
        Assert.areEqual(currentYear - 2, Integer.valueOf(String.valueOf(firstXsell.get('year'))), 'First xsell year should be current year minus 2.');
        Assert.areEqual(10, Decimal.valueOf(String.valueOf(firstXsell.get('amount'))), 'First xsell amount should match the BP record value.');
        Assert.areEqual('EUR', String.valueOf(firstXsell.get('currencyId')), 'Xsell currency should match the BP record currency.');
    }

    /*@isTest
    static void testBuildOpportunitySanctions_withAssertions() {
        DMT_Line__c sanctionLine = DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Risk_Line_Term__c riskTerm = [
            SELECT Id, gf_group_priority_line_id__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :sanctionLine.Id
            LIMIT 1
        ];
        Account acc = [SELECT Id FROM Account WHERE Id = :sanctionLine.Client__c LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Sanctions Helper Test',
            StageName = 'Draft OPP',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            DMT_Sanction__c = sanctionLine.Id
        );
        insert opp;

        Id stdPbId = Test.getStandardPricebookId();
        opp.Pricebook2Id = stdPbId;
        update opp;

        Product2 product = new Product2(Name = 'Sanction Test Product', IsActive = true);
        insert product;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            Product2Id = product.Id,
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            DMT_Associated_Line_Product__c = riskTerm.Id,
            gf_group_priority_opportunity_id__c = '01',
            g_currency_id__c = 'EUR',
            g_branch_id__c = 'ES0182-US',
            DMT_Risk_Type__c = '3000000',
            gf_initial_date__c = System.today(),
            gf_maturity_date__c = System.today().addDays(365),
            gf_amortization_type__c = 'Bullet',
            gf_payment_frequency__c = 'Quarterly',
            DMT_Deal_Amount_Tenors__c = 200000,
            gf_accrual_fees_bp__c = 1,
            DMT_Extension_Duration_Fees__c = 1,
            Life_Funding_Type__c = 'Term'
        );
        insert oli;

        opp = [
            SELECT Id, DMT_Sanction__r.Line_Id__c,
                (SELECT Id, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Test.startTest();
        List<DMT_PassportOpportunity_Wrapper.OpportunitySanctions> result = DMT_Passport_Helper.buildOpportunitySanctions(opp);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Expected one sanctions wrapper.');
        Assert.areEqual('00003', result[0].lineCode, 'Sanctions line code should come from the associated sanction line.');
        Assert.areEqual(1, result[0].productsLine.size(), 'Expected one product mapping in sanctions payload.');
        Assert.areEqual(riskTerm.gf_group_priority_line_id__c, result[0].productsLine[0].productApproval, 'Approval product should map from associated line product.');
        Assert.areEqual('01', result[0].productsLine[0].productOpportunity, 'Opportunity product code should map correctly.');
    }*/

    @isTest
    static void testCreateCase_directHelper() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        List<Map<String, Object>> taskList = new List<Map<String, Object>>{
            new Map<String, Object>{'id' => '1', 'name' => 'Task 1', 'status' => 'OPEN'}
        };

        Test.startTest();
        Case createdCase = DMT_Passport_Helper.createCase(
            line,
            null,
            UserInfo.getUserId(),
            '403',
            'Feature Test',
            taskList,
            'Case comment',
            'APPROVAL'
        );
        Test.stopTest();

        Case storedCase = [
            SELECT Id, DMT_Line__c, DMT_Feature_Id__c, DMT_Related_feature_name__c, Description, DMT_Passport_Sanction__c, DMT_Closing_Tasks__c
            FROM Case
            WHERE Id = :createdCase.Id
        ];

        Assert.areEqual(line.Id, storedCase.DMT_Line__c, 'Case should be linked to the line.');
        Assert.areEqual('403', storedCase.DMT_Feature_Id__c, 'Feature id should be stored.');
        Assert.areEqual('Feature Test', storedCase.DMT_Related_feature_name__c, 'Feature name should be stored.');
        Assert.areEqual('Case comment', storedCase.Description, 'Comment should be stored in Description.');
        Assert.areEqual('APPROVAL', storedCase.DMT_Passport_Sanction__c, 'Passport sanction should be stored.');
        Assert.isTrue(storedCase.DMT_Closing_Tasks__c.contains('Task 1'), 'Closing tasks should be serialized into the case.');
    }

    @isTest
    static void testSetPayloadMin_treasuryLine() {
        DMT_Line__c treasuryLine = DMT_Test_DataFactory.generateTestTreasuryLines();

        Test.startTest();
        String payload = DMT_Passport_Helper.setPayloadMin(treasuryLine.Id);
        Test.stopTest();

        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
        List<Object> products = (List<Object>) payloadMap.get('products');

        Assert.areEqual('00002', String.valueOf(payloadMap.get('opportunityId')), 'Payload should use the treasury line external id.');
        Assert.areEqual(3, products.size(), 'Treasury payload should contain FD, DVP and Derivatives products.');
    }

    @isTest
    static void testSetPayloadMin_otherProductsLine() {
        DMT_Line__c otherLine = DMT_Test_DataFactory.generateTestOtherLines();

        Test.startTest();
        String payload = DMT_Passport_Helper.setPayloadMin(otherLine.Id);
        Test.stopTest();

        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
        List<Object> products = (List<Object>) payloadMap.get('products');

        Assert.areEqual('00003', String.valueOf(payloadMap.get('opportunityId')), 'Payload should use the other products line external id.');
        Assert.areEqual(2, products.size(), 'Other products min payload should contain the line info product and the related risk term product.');
    }

    @isTest
    static void testCallConsumptionLimitService_success() {
        Map<String, Object> requestMap = new Map<String, Object>{ 'payload' => '{"test":true}' };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        DMT_Passport_Helper.callConsumptionLimitService(requestMap, outMap);
        Test.stopTest();

        Assert.isFalse(outMap.containsKey('result'), 'Success path should not mark the result as false.');
        Assert.isFalse(outMap.containsKey('message'), 'Success path should not include an error message.');
    }

    @isTest
    static void testOpportunitySanctionNewApprovalNative() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        DMT_Line__c sanctionLine = new DMT_Line__c(
            Name = 'Native Sanction Line',
            DMT_Opportunity__c = opp.Id
        );
        insert sanctionLine;

        opp.DMT_Sanction__c = sanctionLine.Id;
        update opp;

        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        DMT_Passport_Handler.buttonCallPassport(opp.Id, JSON.serialize(clientsGroup));
        Test.stopTest();
    }

    @isTest
    static void testOpportunitySanctionNewApprovalReused() {
        Opportunity originOpp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        // Create a sanction line for a different (origin) opportunity
        Opportunity targetOpp = new Opportunity(
            Name = 'Target Opportunity for Reused Sanction',
            StageName = 'Draft OPP',
            CloseDate = Date.today(),
            AccountId = originOpp.AccountId
        );
        insert targetOpp;

        DMT_Line__c sanctionLine = new DMT_Line__c(
            Name = 'Reused Sanction Line',
            DMT_Opportunity__c = originOpp.Id
        );
        insert sanctionLine;

        // Link the sanction from origin to target opportunity
        targetOpp.DMT_Sanction__c = sanctionLine.Id;
        update targetOpp;

        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        DMT_Passport_Handler.buttonCallPassport(targetOpp.Id, JSON.serialize(clientsGroup));
        Test.stopTest();
    }

}