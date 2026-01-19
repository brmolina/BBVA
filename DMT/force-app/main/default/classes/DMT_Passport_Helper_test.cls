@isTest
public with sharing class DMT_Passport_Helper_test {
    private final static String SUCCESS = 'success';
    private final static String MESSAGE_STRG = 'message';
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
        Opportunity newOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
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
    static void testOpportunityTransactionOverviewRenderer() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE DMT_Opp_Id__c = '00001'];

        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        oli.DMT_Deal_Amount_Tenors__c = 1010;
        oli.DMT_ExpectedFinal_Take__c = 1234;
        oli.DMT_ExpectedFinal_Take__c = 2345;
        oli.DMT_NewMoney_BBVA__c = 3456;
        oli.DMT_OldMoney_BBVA__c = 4567;
        oli.DES_Tenor_years__c = 1;
        update oli;

      List<DMT_ViewController.ItemWrapper> selectedItems = new List<DMT_ViewController.ItemWrapper>{
          new DMT_ViewController.ItemWrapper('Component', 'Transaction Overview',  11, '')
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
    static void testTransactionOverviewRenderer_noHtmlData() {

        Test.startTest();
        try{
            DMT_TransactionOverviewRenderer renderer = new DMT_TransactionOverviewRenderer();
            String response = renderer.renderHtml(null);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
            Assert.isTrue(e.getMessage().contains('Data not provided'), 'Exception message should indicate that data was not provided.');
        }
        Test.stopTest();
    }

    @isTest
    static void testTransactionOverviewRenderer_html_noRecordtypeId() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;

        Test.startTest();
        try{
            DMT_TransactionOverviewRenderer renderer = new DMT_TransactionOverviewRenderer();
            String response = renderer.renderHtml(data);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
            Assert.isTrue(e.getMessage().contains('No Transaction Overview renderer'), 'Exception message should indicate that there is no renderer for the provided record type id.');
        }
        Test.stopTest();
    }

    @isTest
    static void testOpportunityTransactionOverviewRenderer_noPdfData() {

        Test.startTest();
        Map<String, Object> pdfData = new Map<String, Object>();
        try{
            DMT_TransactionOverviewRenderer renderer = new DMT_TransactionOverviewRenderer();
            pdfData = renderer.renderPdfJson(null);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
            Assert.isTrue(pdfData.isEmpty(), 'No pdfData should be returned.');
        }
        Test.stopTest();
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
    static void testEconomicsRenderer_noPdfData() {

        Test.startTest();
        Map<String, Object> pdfData = new Map<String, Object>();
        try{
            DMT_EconomicsRenderer renderer = new DMT_EconomicsRenderer();
            pdfData = renderer.renderPdfJson(null);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
            Assert.isTrue(pdfData.isEmpty(), 'No pdfData should be returned.');
        }
        Test.stopTest();
    }

    @isTest
    static void testEconomicsRenderer_pdf_NoRecordtypeId() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;

        Test.startTest();
        Map<String, Object> pdfData = new Map<String, Object>();
        try{
            DMT_EconomicsRenderer renderer = new DMT_EconomicsRenderer();
            pdfData = renderer.renderPdfJson(data);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
            Assert.isTrue(pdfData.isEmpty(), 'No pdfData should be returned.');
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
}