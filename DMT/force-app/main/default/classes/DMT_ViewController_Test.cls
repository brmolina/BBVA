@isTest(seeAllData=false)
public class DMT_ViewController_Test {

    @TestSetup
    static void makeData(){
        CIB_Bypass__c settings = CIB_Bypass__c.getOrgDefaults();
        settings.ExtensionsAllowed__c = 'png|jpeg|jpg|gif|svg|pdf|docx|xlsx|pptx|doc|xls|ppt|html|json';
        settings.skipFileExtensions__c = false;
        upsert settings;

		//DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        //utilTestClass.createCustomSettingByPass();
        TriggerBypass.setBypass();

        User testUser = new User();
        Group testGroup = new Group();
        QueueSObject testQueueSObject = new QueueSObject();

        System.runAs(new User(Id = UserInfo.getUserId())){
            // Create User
            testUser = TestFactory.createUser('TestUser', 'Standard User');
            // Create Group and Queue
            testGroup = new Group(Name = 'Test Group', DeveloperName = 'Test_prueba', Type = 'Queue');
            insert testGroup;
            testQueueSObject = new QueueSObject(QueueId = testGroup.Id, SObjectType = 'Case');
            insert testQueueSObject;
        }

        // Create ApproversView
        DMT_ApproversView__c testView = new DMT_ApproversView__c(Name = 'Test View', DMT_DeveloperName__c = 'Test_prueba', DMT_Type__c = 'Line');
        insert testView;

        // Create Approver
        DMT_Approver__c testApprover = new DMT_Approver__c(DMT_Group__c = testGroup.DeveloperName, Approvers_View__c = testView.Id, DMT_Approver_Code__c = '123', DMT_External_Id__c = '1234');
        insert testApprover;

        // Create Items for View
        DMT_Items__c testItem1 = new DMT_Items__c(DMT_Component_Item__c = 'Line Info', DMT_order_display__c = 1, DMT_View__c = testView.Id);
        DMT_Items__c testItem2 = new DMT_Items__c(DMT_Component_Item__c = 'Client', DMT_order_display__c = 2, DMT_View__c = testView.Id);
        DMT_Items__c testItem3 = new DMT_Items__c(DMT_Component_Item__c = 'Approval Process Data', DMT_order_display__c = 3, DMT_View__c = testView.Id);
        DMT_Items__c testItem4 = new DMT_Items__c(DMT_Component_Item__c = 'Participants', DMT_order_display__c = 4, DMT_View__c = testView.Id);
        DMT_Items__c testItem5 = new DMT_Items__c(DMT_Component_Item__c = 'Products', DMT_order_display__c = 5, DMT_View__c = testView.Id);
        DMT_Items__c testItem6 = new DMT_Items__c(DMT_Component_Item__c = 'Passport', DMT_order_display__c = 6, DMT_View__c = testView.Id);
        DMT_Items__c testItem7 = new DMT_Items__c(DMT_Component_Item__c = 'Limit', DMT_order_display__c = 7, DMT_View__c = testView.Id);
        DMT_Items__c testItem8 = new DMT_Items__c(DMT_Component_Item__c = 'Limit Visual', DMT_order_display__c = 8, DMT_View__c = testView.Id);
        //DMT_Items__c testItem9 = new DMT_Items__c(DMT_Component_Item__c = 'Approval Process', DMT_order_display__c = 9, DMT_View__c = testView.Id);
        //DMT_Items__c testItem10 = new DMT_Items__c(DMT_Component_Item__c = 'Validation Process', DMT_order_display__c = 10, DMT_View__c = testView.Id);
        DMT_Items__c testItem10 = new DMT_Items__c(DMT_Component_Item__c = 'Active Related Lines', DMT_order_display__c = 10, DMT_View__c = testView.Id);
        insert new List<DMT_Items__c>{testItem1, testItem2, testItem3, testItem4, testItem5, testItem6, testItem7, testItem8};

        // Create Account
        Account testAccount = new Account(Name = 'Test Account', g_customer_id__c = 'XXXXXXXXXXXXXXX');
      //  Account testAccount2 = new Account(Name = 'Client Test');
        insert new List<Account>{testAccount/* , testAccount2 */};

        // Create DMT_Line__c for TreasurySettlement
        RecordType treasuryRT = [SELECT Id FROM RecordType WHERE SObjectType = 'DMT_Line__c' AND DeveloperName = 'TreasurySettlement' LIMIT 1];
        DMT_Line__c testTreasuryLine = new DMT_Line__c(
            Name = 'Test Treasury Line',
            Line_Id__c = '12345',
            Client__c = testAccount.Id,
            CurrencyIsoCode = 'EUR',
            RecordTypeId = treasuryRT.Id,
            Booking_Geography__c = 'ES',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(10),
            DvP_Amount__c = 10000,
            FD_Amount__c = 5000,
            Waiver__c = true,
            DMT_Operation__c = 'Test Operation',
            DMT_RAROEC_RORC_Proposal__c = 'Proposal',
            DMT_Nominal__c = 'Nominal',
            DMT_Comments__c = 'Comments',
            DMT_Franchise_L12M__c = 'Franchise',
            DMT_Client_Use__c = 'Client Use',
            DMT_Additional_Restrictions__c = 'Restrictions',
            DMT_Client_Entific__c = 'Entific'
        );
        insert testTreasuryLine;

        DMT_Line__c testTreasuryLine2 = new DMT_Line__c(
            Name = 'Test Treasury Line 2',
            Line_Id__c = '123456',
            Client__c = testAccount.Id,
            CurrencyIsoCode = 'EUR',
            RecordTypeId = treasuryRT.Id,
            Booking_Geography__c = 'ES',
            Start_Date__c = Date.today().addMonths(-1),
            End_Date__c = Date.today().addMonths(12),
            DvP_Amount__c = 10000,
            FD_Amount__c = 5000,
            Waiver__c = true,
            DMT_Operation__c = 'Test Operation',
            DMT_RAROEC_RORC_Proposal__c = 'Proposal',
            DMT_Nominal__c = 'Nominal',
            DMT_Comments__c = 'Comments',
            DMT_Franchise_L12M__c = 'Franchise',
            DMT_Client_Use__c = 'Client Use',
            DMT_Additional_Restrictions__c = 'Restrictions',
            DMT_Client_Entific__c = 'Entific'
        );
        insert testTreasuryLine2;

        // Create DMT_Line__c for OtherProducts
        RecordType otherRT = [SELECT Id FROM RecordType WHERE SObjectType = 'DMT_Line__c' AND DeveloperName = 'OtherProducts' LIMIT 1];
        DMT_Line__c testOtherLine = new DMT_Line__c(
            Name = 'Test Other Line',
            Line_Id__c = '67890',
            Client__c = testAccount.Id,
            CurrencyIsoCode = 'EUR',
            RecordTypeId = otherRT.Id,
            Booking_Geography__c = 'ES',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(6),
            Amount__c = 20000,
            DMT_LastLevelId__c = 'Level1'
        );
        insert testOtherLine;

        // Create a minimal risk line term for testOtherLine so concatenatedValuesSet will contain a key
        // and set DMT_Product__c so DMT_Parent_Product_Name__c becomes available (via formula/trigger)
        DMT_Risk_Line_Term__c riskTerm = new DMT_Risk_Line_Term__c(
            Name = 'Test Risk Term',
            DMT_Line__c = testOtherLine.Id,
            gf_group_priority_line_id__c = '01'
        );
        insert riskTerm;

        Custom_Association__c testCustom = new Custom_Association__c(
            Name = 'Test custom',
            DMT_Line__c = testTreasuryLine.Id,
            gf_customer_group_id__c = 'ESCD25LIN00000978ES',
            g_customer_id__c = 'XXXXXXXXXXXXXXX'
        );
        Custom_Association__c testCustom2 = new Custom_Association__c(
            Name = 'Test custom 2',
            DMT_Line__c = testOtherLine.Id,
            gf_customer_group_id__c = 'ESCD35LIN00000978ES'
        );
         Custom_Association__c testCustom3 = new Custom_Association__c(
            Name = 'Test custom 3',
            DMT_Line__c = testOtherLine.Id,
            gf_customer_group_id__c = 'ESCD35LIN00000978ES_' + riskTerm.gf_group_priority_line_id__c
        );
        insert new List<Custom_Association__c>{testCustom, testCustom2, testCustom3};

        Custom_Association_Client__c testAssociation = new Custom_Association_Client__c(
            Name = 'Test Association',
            Custom_Association__c = testCustom.Id,
            DMT_Amount__c = 1000,
            Alpha_Code_Client__c = 'ES0000000000001',
            g_customer_id__c = 'XXXXXXXXXXXXXXX'

        );
        Custom_Association_Client__c testAssociation2 = new Custom_Association_Client__c(
            Name = 'Test Association 2',
            Custom_Association__c = testCustom2.Id,
            DMT_Amount__c = 1000,
            Alpha_Code_Client__c = 'ES0000000000002'
        );
        Custom_Association_Client__c testAssociation3 = new Custom_Association_Client__c(
            Name = 'Test Association 3',
            Custom_Association__c = testCustom3.Id,
            DMT_Amount__c = 1000,
            Alpha_Code_Client__c = 'ES0000000000002'
        );
        insert new List<Custom_Association_Client__c>{testAssociation, testAssociation2, testAssociation3};

        // Create DMT_TeamMember__c
        DMT_TeamMember__c testTeamMember = new DMT_TeamMember__c(
            Line__c = testTreasuryLine.Id,
            User__c = testUser.Id,
            AccessLevel__c = 'Read'
        );
        insert testTeamMember;

        // Create DMT_Risk_Line_Term__c for Treasury Derivatives
        DMT_Risk_Line_Term__c testRiskTreasuryDerivatives = new DMT_Risk_Line_Term__c(
            DMT_Line__c = testTreasuryLine.Id,
            Name = 'Test Risk Treasury',
            DMT_Init_Term__c = '0',
            DMT_End_Term__c = '365',
            DMT_Amount__c = 10000,
            DMT_Risk_Type__c = 'Derivatives',
            CurrencyIsoCode = 'EUR',
            g_limit_sinds_ast_sctr_id__c = 'A',
            g_limit_sinds_ast_subsec_id__c = 'B',
            gf_inscol_months_grace_number__c = 123,
            gf_revolvence_pd_days_number__c = 123
        );
        // Create DMT_Risk_Line_Term__c for Treasury Depos
        DMT_Risk_Line_Term__c testRiskTreasuryDepos = new DMT_Risk_Line_Term__c(
            DMT_Line__c = testTreasuryLine.Id,
            Name = 'Test Risk Depos',
            DMT_Init_Term__c = '0',
            DMT_End_Term__c = '182',
            DMT_Amount__c = 20000,
            DMT_Risk_Type__c = 'Depos',
            CurrencyIsoCode = 'EUR',
            DMT_LastLevelId__c = 'Level2',
            g_global_product_family_Id__c = 'Fam1',
            g_global_product_subfamily_Id__c = 'Subfam1',
            g_global_product_category_Id__c = 'Cat1',
            g_gbl_product_subcategory_Id__c = 'Subcat1',
            g_limit_sinds_ast_sctr_id__c = 'A',
            g_limit_sinds_ast_subsec_id__c = 'B',
            gf_inscol_months_grace_number__c = 123,
            gf_revolvence_pd_days_number__c = 123
        );

        // Create DMT_Risk_Line_Term__c for Equities
        DMT_Risk_Line_Term__c testRiskEquities = new DMT_Risk_Line_Term__c(
            DMT_Line__c = testOtherLine.Id,
            Name = 'Test Risk Equities',
            DMT_Init_Term__c = '0',
            DMT_End_Term__c = '182',
            DMT_Amount__c = 20000,
            DMT_Risk_Type__c = 'Equities',
            CurrencyIsoCode = 'EUR',
            DMT_LastLevelId__c = 'Level2',
            g_global_product_family_Id__c = 'Fam1',
            g_global_product_subfamily_Id__c = 'Subfam1',
            g_global_product_category_Id__c = 'Cat1',
            g_gbl_product_subcategory_Id__c = 'Subcat1',
            g_limit_sinds_ast_sctr_id__c = 'A',
            g_limit_sinds_ast_subsec_id__c = 'B',
            gf_inscol_months_grace_number__c = 123,
            gf_revolvence_pd_days_number__c = 123
        );
        // Create DMT_Risk_Line_Term__c for Depos
        DMT_Risk_Line_Term__c testRiskOther = new DMT_Risk_Line_Term__c(
            DMT_Line__c = testOtherLine.Id,
            Name = 'Test Risk Depos',
            DMT_Init_Term__c = '0',
            DMT_End_Term__c = '182',
            DMT_Amount__c = 20000,
            DMT_Risk_Type__c = 'Depos',
            CurrencyIsoCode = 'EUR',
            DMT_LastLevelId__c = 'Level2',
            g_global_product_family_Id__c = 'Fam1',
            g_global_product_subfamily_Id__c = 'Subfam1',
            g_global_product_category_Id__c = 'Cat1',
            g_gbl_product_subcategory_Id__c = 'Subcat1',
            g_limit_sinds_ast_sctr_id__c = 'A',
            g_limit_sinds_ast_subsec_id__c = 'B',
            gf_inscol_months_grace_number__c = 123,
            gf_revolvence_pd_days_number__c = 123
        );
      //  insert testRiskOther;
      insert new List<DMT_Risk_Line_Term__c>{testRiskTreasuryDerivatives, testRiskTreasuryDepos, testRiskEquities, testRiskOther};

        // Create DMT_Line_Product_Item__c
        DMT_Line_Product_Item__c testProductItem = new DMT_Line_Product_Item__c(
            Line__c = testTreasuryLine.Id,
            Name = 'Test Product',
            DMT_DerivativeRestriction__c = true,
            DMT_FDRestriction__c = false,
            DMT_DVPRestriction__c = true,
            Max_Tenor_WC__c = '365'
        );
        insert testProductItem;

        // Create Passport__c for features
        Passport__c testPassportTreasury = new Passport__c(
            DMT_Line__c = testTreasuryLine.Id,
            DMT_Passport_Save__c = '{"data":{"features":[{"id":"1","name":"General Validations","stateName":"GREEN","validations":[{"name":"Validation1","state":"GREEN","message":"OK"}]},{"id":"2","name":"Approval Process","stateName":"YELLOW"}]}}'
        );
        Passport__c testPassportOther = new Passport__c(
            DMT_Line__c = testOtherLine.Id,
            DMT_Passport_Save__c = '{"data":{"features":[{"id":"3","name":"Other Validation","stateName":"RED"}]}}'
        );
        insert new List<Passport__c>{testPassportTreasury, testPassportOther};

        // Create DMT_Currency_Provision__c
        DMT_Currency_Provision__c testProvision = new DMT_Currency_Provision__c(
            DMT_Risk_Line_Term__c = testRiskTreasuryDerivatives.Id,
            g_currency_id__c = 'USD'
        );
        insert testProvision;

        // Create DMT_Warranty__c
        DMT_Warranty__c testWarranty = new DMT_Warranty__c(
            DMT_Risk_Line_Term__c = testRiskTreasuryDerivatives.Id,
            Name = 'Test Warranty'
        );
        insert testWarranty;

        // Create DMT_Taxonomy_Values__c for taxonomy maps
        DMT_Taxonomy_Values__c tax162 = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'C162',
            DMT_Value__c = 'A',
            DMT_Name_EN__c = 'A'
        );
        DMT_Taxonomy_Values__c tax164 = new DMT_Taxonomy_Values__c(
            DMT_Catalog__c = 'C164',
            DMT_Value__c = 'B',
            DMT_Name_EN__c = 'B'
        );

        insert new List<DMT_Taxonomy_Values__c>{tax162, tax164};

        // Create Case for loadJSONFromCase
        Case testCase = new Case(Subject = 'Test Case', OwnerId = testGroup.Id, DMT_Line__c = testTreasuryLine.Id);
        insert testCase;

        // Create Task for generateContentDocumentForView
        List<Task> testTaskList = new List<Task>{
            new Task(WhatId = testCase.Id, Subject = 'Test Task 1', Status = 'Not Started'),
            new Task(WhatId = testCase.Id, Subject = 'Test Task 2', Status = 'Not Started'),
            new Task(WhatId = testCase.Id, Subject = 'Test Task 3', Status = 'Not Started')

        };
        insert testTaskList;

        DMT_Test_DataFactory.generatePricebook2();

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2, pricebookEntry, opp);

        opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opp.Id];
        opportunityLineItem = [SELECT Id, UnitPrice, TotalPrice FROM OpportunityLineItem WHERE Id = :opportunityLineItem.Id];
        opportunityLineItem.UnitPrice = 200;
        update opportunityLineItem;

        DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
        DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
        DMT_Test_DataFactory.generatexSell(opp);
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        DMT_TeamMember__c participants = new DMT_TeamMember__c(Opportunity__c = opp.Id, User__c = UserInfo.getUserId(), AccessLevel__c = 'Read');
        insert participants;
        Local_Client__c localClient = new Local_Client__c(Name = 'test local client', RecordTypeId = Schema.SObjectType.Local_Client__c.getRecordTypeInfosByName().get('Client').getRecordTypeId(), Cib_Client__c = opp.AccountId);
        insert localClient;

        Case testCaseOpp = new Case(Subject = 'Test Case Opp', OwnerId = testGroup.Id, opportunity_id__c = opp.Id);
        insert testCaseOpp;

        List<Product2> products = new List<Product2>{
            // Family
            new Product2(Name = 'Test Name 1', Family = 'DMT Lines', DMT_Product_family__c = '1800000000'),

            // Subfamily
            new Product2(Name = 'Test Name 2', Family = 'DMT Lines', DMT_Product_family__c = '1800000000', DMT_Product_Subfamily__c = '1800000001'),

            // Category
            new Product2(Name = 'Test Name 3', Family = 'DMT Lines', DMT_Product_family__c = '1800000000', DMT_Product_Subfamily__c = '1800000001', DMT_Product_category__c = '1800000002'),

            // Subcategory
            new Product2(Name = 'Test Name 4', Family = 'DMT Lines', DMT_Product_family__c = '1800000000', DMT_Product_Subfamily__c = '1800000001', DMT_Product_category__c = '1800000002', DMT_Product_Subcategory__c = '1800000003')
        };
        insert products;

        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT', 'https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket', 'https://validation.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint', 'https://group-position.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPG_CommonEndPoint', 'https://group-position.ok', 'ServicesPartition', false));

        // Perform one single DML
        insert settingsToInsert;

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testGetFeatures() {
        // Crear un registro de prueba para DMT_Line__c
        DMT_Line__c testLine = new DMT_Line__c(Name = 'Test Line');
        insert testLine;

        // Crear un registro de prueba para Passport__c con el JSON proporcionado
        String jsonData = '{"data":{"features":[{"id":"Test1","name":"Global validations","stateName":"RED"},{"id":"Test2","name":"Limit Feature test 1","stateName":"GREEN"}]}}';

        List<Passport__c> existingPassports = [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testLine.Id];
        delete existingPassports;

        Passport__c testPassport = new Passport__c(
            DMT_Line__c = testLine.Id,
            DMT_Passport_Save__c = jsonData
        );
        insert testPassport;

        // Recuperar el registro de Passport para verificar el JSON guardado
        //Passport__c retrievedPassport = [SELECT Id, DMT_Passport_Save__c, DMT_Line__c FROM Passport__c WHERE DMT_Line__c = :testLine.Id];

        // Ejecutar el método
        Test.startTest();
        List<Map<String, Object>> features = DMT_ViewController.getFeatures(testLine.Id);
        Test.stopTest();

        // Imprimir los resultados de features
        System.debug('Features List: ' + features);

        // Validar los resultados
        Assert.isNotNull(features, 'Features list should not be null.');
        Assert.areEqual(2, features.size(), 'Features list should contain 2 items.');
        Assert.areEqual('Global validations', features[0].get('name'), 'First feature name should match.');
        Assert.areEqual('Limit Feature test 1', features[1].get('name'), 'Second feature name should match.');
        Assert.areEqual('RED', features[0].get('stateName'), 'First feature stateName should match.');
        Assert.areEqual('GREEN', features[1].get('stateName'), 'Second feature stateName should match.');
    }

    @isTest
    static void testLoadHtmlFromSelectedItemsTreasury() {
        TriggerBypass.setBypass();
        // Get existing user created in makeData()
        User testUser = [SELECT Id FROM User WHERE Profile.Name ='Standard User' AND IsActive = true LIMIT 1];
        DMT_Line__c testTreasuryLine = [SELECT Id, RecordType.DeveloperName, Name, Client_Type__c FROM DMT_Line__c WHERE Line_Id__c = '12345' LIMIT 1];
        System.debug('testTreasuryLine, '+ testTreasuryLine);
        Custom_Association__c customAss = [SELECT Id, DMT_Line__c FROM Custom_Association__c WHERE DMT_Line__c = :testTreasuryLine.Id];
        System.debug('customAss, '+ customAss);
        testTreasuryLine.Custom_Association__c = customAss.Id;
        update testTreasuryLine;

        // Get passport JSON from static resource
        StaticResource passportSaveMock = [
            SELECT Body FROM StaticResource WHERE Name = 'passportSaveMock' LIMIT 1
        ];
        String jsonData = passportSaveMock.Body.toString();
        System.debug('passportSaveMock, '+ jsonData);

        // Remove any existing passports for this line
        delete [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testTreasuryLine.Id];

        // Insert new passport
        insert new Passport__c(
            DMT_Line__c = testTreasuryLine.Id,
            DMT_Passport_Save__c = jsonData
        );

        // Link existing user to line via team member
        insert new DMT_TeamMember__c(
            Line__c = testTreasuryLine.Id,
            User__c = testUser.Id,
            AccessLevel__c = 'Read'
        );

        // Prepare selected items
        List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();

        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'img64Mock' LIMIT 1];
        String img64 = sr.Body.toString();

        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case'];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // Simulación del controlador
        Test.startTest();
        //DMT_ViewController controller = new DMT_ViewController();
        String treasuryLineId = testTreasuryLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line_Treasury';
        //String recordTypeDeveloperName = 'TreasurySettlement';
        String htmlContent = DMT_ViewController.loadComponentsForView(treasuryLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(treasuryLineId, type, items);
        DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id);
        DMT_ViewController.getFeaturesForJsonPdf(treasuryLineId, '');
        DMT_ViewController.getFeaturesForJsonPdf('', '');

        testCase.DMT_Line__c = null;
        update testCase;
        DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id);
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');

        TriggerBypass.removeBypass();
    }

   @isTest
    static void testLoadHtmlFromSelectedItemsOpportunityTreasury() {
        TriggerBypass.setBypass();
        // Get existing user created in makeData()
        User testUser = [SELECT Id FROM User WHERE Profile.Name ='Standard User' AND IsActive = true LIMIT 1];
        Opportunity testOpp = [SELECT Id, RecordType.DeveloperName, Name FROM Opportunity LIMIT 1];
        String TreasuryOppId = testOpp.Id;
        Case testCaseOpp = [SELECT Id FROM Case WHERE Subject = 'Test Case Opp'];

        insert new DMT_TeamMember__c(
            Opportunity__c  = testOpp.Id,
            User__c = testUser.Id,
            AccessLevel__c = 'Read'
        );

        // Prepare selected items
        List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();

        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'img64Mock' LIMIT 1];
        String img64 = sr.Body.toString();

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line_Treasury';
        //String recordTypeDeveloperName = 'TreasurySettlement';
        String htmlContent = DMT_ViewController.loadComponentsForView(TreasuryOppId, type, items, '', itemsImg);
        String jsonDataFeatureOpp = DMT_ViewController.getFeaturesForJsonPdf(TreasuryOppId, testCaseOpp.Id);
        String jsonDataFeatureOpp1 = DMT_ViewController.getFeaturesForJsonPdf(TreasuryOppId, '');

        delete [SELECT Id FROM Passport__c WHERE Opportunity__c = :testOpp.Id];
        String jsonDataFeatureOpp2 = DMT_ViewController.getFeaturesForJsonPdf(TreasuryOppId, testCaseOpp.Id);
        insert new Passport__c(
            Opportunity__c = testOpp.Id,
            DMT_Passport_Save__c = '{"data":{"features":[{"validations":[{"message":"Opportunity Internal Rating is consistent with Client Internal Rating.","name":"Rating is consistent","state":"GREEN"},{"message":"Opportunity Client Type is not consistent with Client Type.","name":"Client Type is inconsistent","state":"RED"},{"message":"All Cross SELL records have a Year within 5 years from the Opportunity Initial Date.","name":"Cross SELL Year is consistent","state":"GREEN"},{"message":"Consistent Payment Date detected in Tenors for product type User-Defined","name":"Tenors Payment Date is consistent","state":"GREEN"},{"message":"Opportunity Maturity Date is consistent with Opportunity Products Maturity Dates","name":"Maturity Date consistency","state":"GREEN"},{"message":"Opportunity Initial Date is consistent with Opportunity Products Initial Dates","name":"Initial Date consistency","state":"GREEN"},{"message":"Opportunity Notional Amount is consistent with Opportunity Products Notional Amounts Sum","name":"Notional Amount consistency","state":"GREEN"}],"stateName":"RED","motorDesc":"Salesforce","active":"Y","passportSanction":"passport","name":"General Validations","id":"200"},{"tasks":[{"approvers":[{"documentManagerEnable":"Y","branch":"HO","entific":"HO","name":"GRM C&IB - FI - Insurance & CCPs","id":"15"}],"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - Local","id":"6"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - Local","id":"6"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - local and global","id":"8"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - on behalf of the geography committee","id":"9"}],"stateName":"WHITE","orderNumber":199,"active":"Y","passportSanction":"readytoclose","name":"OP14 - Business Approval (Test Opp)","id":"921"},{"tasks":[{"approvers":[{"documentManagerEnable":"Y","branch":"HO","entific":"HO","name":"GRM C&IB - FI - Insurance & CCPs","id":"15"}],"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - Local","id":"6"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - Local","id":"6"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - local and global","id":"8"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - on behalf of the geography committee","id":"9"}],"stateName":"WHITE","orderNumber":201,"active":"Y","passportSanction":"approval","name":"OP14 - OPTIONAL  (Test Opp)","id":"981"},{"profitability":{"results":[{"feesFbPbs":0.0,"feesFb":0.0,"feesDbPbs":0.0,"feesDb":0.0,"feesOtherPbs":0.0,"feesOther":0.0,"totalYears":[{"raroecYearly":0.6503158976014631,"rorcYearly":0.42137377415204125,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2025},{"raroecYearly":15.391796323909647,"rorcYearly":9.957474131727261,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2026},{"raroecYearly":0.6974261835141751,"rorcYearly":0.45255035112554143,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2027}],"rorcProspected":0.0,"clientRorc":0.0,"rorc":0.45255035112554143,"raroecProspected":0.0,"raroec":0.6974261835141751,"prospectedRegulatoryCapital":0.0,"prospectedEconomicCapital":0.0,"prospectedBdi":0.0,"regulatoryCapital":2164.519610144561,"economicCapital":1404.527292986458,"regulatoryApr":2.1595664581674945,"economicApr":1.8788152752907068,"allInFb":0.0,"allInDb":0.0,"bdi":979.554109589041,"periodicFeesPbs":0.0,"feesUpFrontPbs":0.0,"expectedLossPbs":0.0,"countryRiskProvisionFbPbs":0.0,"countryRiskProvisionDbPbs":0.0,"bonificationFunding":0.0,"fundingDbPbs":11.602739726027393,"fundingFbPbs":2.1095890410958904,"spreadFbPbs":34.80821917808218,"spreadDbPbs":104.42465753424656,"averageLife":1.0547945205479454,"regulatoryEad":180000.0,"economicEad":200000.0,"taxRate":30.0,"regulatoryLgd":40.0,"economicLgd":40.0,"regulatoryCcf":40.0,"economicCcf":50.0,"productId":"00kKG0000037yjjYAA"},{"feesFbPbs":0.0,"feesFb":0.0,"feesDbPbs":0.0,"feesDb":0.0,"feesOtherPbs":0.0,"feesOther":0.0,"totalYears":[{"raroecYearly":0.6503158976014631,"rorcYearly":0.42137377415204125,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2025},{"raroecYearly":15.391796323909647,"rorcYearly":9.957474131727261,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2026},{"raroecYearly":0.6974261835141751,"rorcYearly":0.45255035112554143,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2027}],"rorcProspected":0.0,"clientRorc":0.0,"rorc":0.45255035112554143,"raroecProspected":0.0,"raroec":0.6974261835141751,"prospectedRegulatoryCapital":0.0,"prospectedEconomicCapital":0.0,"prospectedBdi":0.0,"regulatoryCapital":2164.519610144561,"economicCapital":1404.527292986458,"regulatoryApr":2.1595664581674945,"economicApr":1.8788152752907068,"allInFb":0.0,"allInDb":0.0,"bdi":979.554109589041,"periodicFeesPbs":0.0,"feesUpFrontPbs":0.0,"expectedLossPbs":0.0,"countryRiskProvisionFbPbs":0.0,"countryRiskProvisionDbPbs":0.0,"bonificationFunding":0.0,"fundingDbPbs":11.602739726027393,"fundingFbPbs":2.1095890410958904,"spreadFbPbs":34.80821917808218,"spreadDbPbs":104.42465753424656,"averageLife":1.0547945205479454,"regulatoryEad":180000.0,"economicEad":200000.0,"taxRate":30.0,"regulatoryLgd":40.0,"economicLgd":40.0,"regulatoryCcf":40.0,"economicCcf":50.0}],"audit":{"isError":false,"engineVersion":"0.7"}},"stateName":"GREEN","orderNumber":401,"motorDesc":"Profitability Engine","active":"Y","passportSanction":"passport","name":"Profitability Engine","id":"441"},{"stateName":"GRAY","motorDesc":"Limit Engine","active":"Y","passportSanction":"passport","name":"OPP03 -  Limit Test (Group Level)","id":"881"},{"tasks":[{"approvers":[{"documentManagerEnable":"Y","branch":"HO","entific":"HO","name":"GRM C&IB - FI - Insurance & CCPs","id":"15"}],"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Not in accordance","yesFlag":"In accordance","name":"Risk Analyst Advisory","id":"2"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Not in accordance","yesFlag":"In accordance","name":"Risk Analyst Advisory","id":"2"}],"stateName":"GRAY","motorDesc":"Limit Engine","active":"Y","passportSanction":"passport","name":"OPPM02 - Mitigant Limit Test (Client Level)","id":"901"},{"tasks":[{"approvers":[{"documentManagerEnable":"Y","branch":"HO","entific":"HO","name":"GRM C&IB - FI - Insurance & CCPs","id":"15"}],"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Not in accordance","yesFlag":"In accordance","name":"Risk Analyst Advisory","id":"2"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Not in accordance","yesFlag":"In accordance","name":"Risk Analyst Advisory","id":"2"}],"stateName":"GRAY","motorDesc":"Limit Engine","active":"Y","passportSanction":"passport","name":"OPPM03 - Mitigant Limit Test (Group Level)","id":"961"},{"validations":[{"message":"products.funding.fundingTerm, products.amortization.payments.feesPeriodic","name":"capabilityMandatoryParametersMissing","state":"RED"}],"active":"Y","passportSanction":"passport","name":"PRUEBASGAV0901","id":"721"}],"currencyCode":"EUR"}}'
        );
        String jsonDataFeatureOpp3 = DMT_ViewController.getFeaturesForJsonPdf(TreasuryOppId, testCaseOpp.Id);

        testCaseOpp.opportunity_id__c = null;
        update testCaseOpp;
        String jsonDataFeatureOpp4 = DMT_ViewController.getFeaturesForJsonPdf(TreasuryOppId, testCaseOpp.Id);
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testLoadHtmlFromSelectedItemsTreasuryColombia() {
        TriggerBypass.setBypass();
        // Get existing user created in makeData()
        User testUser = [SELECT Id FROM User WHERE Profile.Name ='Standard User' AND IsActive = true LIMIT 1];
        DMT_Line__c testTreasuryLine = [SELECT Id, RecordType.DeveloperName, Name, Client_Type__c FROM DMT_Line__c WHERE Line_Id__c = '12345' LIMIT 1];
        System.debug('testTreasuryLine, '+ testTreasuryLine);
        Custom_Association__c customAss = [SELECT Id, DMT_Line__c FROM Custom_Association__c WHERE DMT_Line__c = :testTreasuryLine.Id];
        System.debug('customAss, '+ customAss);
        testTreasuryLine.Booking_Geography__c = 'CO';
        testTreasuryLine.Custom_Association__c = customAss.Id;
        update testTreasuryLine;


        // Get passport JSON from static resource
        StaticResource passportSaveMock = [
            SELECT Body FROM StaticResource WHERE Name = 'passportSaveMock' LIMIT 1
        ];
        String jsonData = passportSaveMock.Body.toString();

        // Remove any existing passports for this line
        delete [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testTreasuryLine.Id];

        // Insert new passport
        insert new Passport__c(
            DMT_Line__c = testTreasuryLine.Id,
            DMT_Passport_Save__c = jsonData
        );

        // Link existing user to line via team member
        insert new DMT_TeamMember__c(
            Line__c = testTreasuryLine.Id,
            User__c = testUser.Id,
            AccessLevel__c = 'Read'
        );

        // Prepare selected items
        List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();

        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'img64Mock' LIMIT 1];
        String img64 = sr.Body.toString();

        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case'];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String treasuryLineId = testTreasuryLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line_Treasury';
        //String recordTypeDeveloperName = 'TreasurySettlement';
        String htmlContent = DMT_ViewController.loadComponentsForView(treasuryLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(treasuryLineId, type, items);
        DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id );
        DMT_ViewController.getFeaturesForJsonPdf(treasuryLineId, '');
        DMT_ViewController.getFeaturesForJsonPdf('', '');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');

        TriggerBypass.removeBypass();
    }
    @isTest
    static void testLoadHtmlFromSelectedItemsTreasuryPE() {
        TriggerBypass.setBypass();
        // Get existing user created in makeData()
        User testUser = [SELECT Id FROM User WHERE Profile.Name ='Standard User' AND IsActive = true LIMIT 1];
        DMT_Line__c testTreasuryLine = [SELECT Id, RecordType.DeveloperName, Name, Client_Type__c FROM DMT_Line__c WHERE Line_Id__c = '12345' LIMIT 1];
        System.debug('testTreasuryLine, '+ testTreasuryLine);
        Custom_Association__c customAss = [SELECT Id, DMT_Line__c FROM Custom_Association__c WHERE DMT_Line__c = :testTreasuryLine.Id];
        System.debug('customAss, '+ customAss);
        testTreasuryLine.Booking_Geography__c = 'PE';
        testTreasuryLine.Custom_Association__c = customAss.Id;
        update testTreasuryLine;


        // Get passport JSON from static resource
        StaticResource passportSaveMock = [
            SELECT Body FROM StaticResource WHERE Name = 'passportSaveMock' LIMIT 1
        ];
        String jsonData = passportSaveMock.Body.toString();

        // Remove any existing passports for this line
        delete [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testTreasuryLine.Id];

        // Insert new passport
        insert new Passport__c(
            DMT_Line__c = testTreasuryLine.Id,
            DMT_Passport_Save__c = jsonData
        );

        // Link existing user to line via team member
        insert new DMT_TeamMember__c(
            Line__c = testTreasuryLine.Id,
            User__c = testUser.Id,
            AccessLevel__c = 'Read'
        );

        // Prepare selected items
        List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();

        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'img64Mock' LIMIT 1];
        String img64 = sr.Body.toString();

        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case'];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String treasuryLineId = testTreasuryLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line_Treasury';
        //String recordTypeDeveloperName = 'TreasurySettlement';
        String htmlContent = DMT_ViewController.loadComponentsForView(treasuryLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(treasuryLineId, type, items);
        String jsonDataFeatureLine2 = DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id );
        String jsonDataFeatureLine = DMT_ViewController.getFeaturesForJsonPdf(treasuryLineId, '');
        String jsonDataFeatureLine3 = DMT_ViewController.getFeaturesForJsonPdf('', '');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testLoadHtmlFromSelectedItemsOther() {
        TriggerBypass.setBypass();
        // Get existing user created in makeData()
        User testUser = [SELECT Id FROM User WHERE Profile.Name ='Standard User' AND IsActive = true LIMIT 1];
        DMT_Line__c testOtherLine = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '67890' LIMIT 1];
        System.debug('testOtherLine, '+ testOtherLine);
        Custom_Association__c customAss = [SELECT Id, DMT_Line__c FROM Custom_Association__c WHERE DMT_Line__c = :testOtherLine.Id AND gf_customer_group_id__c LIKE 'ESCD35LIN00000978ES' LIMIT 1];
        System.debug('customAss, '+ customAss);
        testOtherLine.Custom_Association__c = customAss.Id;
        update testOtherLine;

        // Get passport JSON from static resource
        StaticResource passportSaveMock = [
            SELECT Body FROM StaticResource WHERE Name = 'passportSaveMock' LIMIT 1
        ];
        String jsonData = passportSaveMock.Body.toString();

        // Remove any existing passports for this line
        delete [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testOtherLine.Id];

        // Insert new passport
        insert new Passport__c(
            DMT_Line__c = testOtherLine.Id,
            DMT_Passport_Save__c = jsonData
        );

        // Link existing user to line via team member
        insert new DMT_TeamMember__c(
            Line__c = testOtherLine.Id,
            User__c = testUser.Id,
            AccessLevel__c = 'Read'
        );

        // Prepare selected items
        List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();

        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'img64Mock' LIMIT 1];
        String img64 = sr.Body.toString();

        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case'];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String otherLineId = testOtherLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line';
        //String recordTypeDeveloperName = 'OtherProducts';

        String htmlContent = DMT_ViewController.loadComponentsForView(otherLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(otherLineId, type, items);
        String jsonDataFeatureLine = DMT_ViewController.getFeaturesForJsonPdf(otherLineId, '');
        String jsonDataFeatureLine2 = DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id);
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testLoadHtmlFromSelectedItemsOtherMultiholder() {

        TriggerBypass.setBypass();
        // Get existing user created in makeData()
        User testUser = [SELECT Id FROM User WHERE Profile.Name ='Standard User' AND IsActive = true LIMIT 1];
        DMT_Line__c testOtherLine = [SELECT Id,Line_Id__c  FROM DMT_Line__c WHERE Line_Id__c = '67890' LIMIT 1];
        System.debug('testOtherLine, '+ testOtherLine);
        // Ensure at least one risk line term exists and set its gf_group_priority_line_id__c
        DMT_Risk_Line_Term__c risk = [SELECT Id, gf_group_priority_line_id__c FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :testOtherLine.Id LIMIT 1];
        risk.gf_group_priority_line_id__c = '01';
        update risk;

        Custom_Association__c customAss = [SELECT Id, DMT_Line__c FROM Custom_Association__c WHERE DMT_Line__c = :testOtherLine.Id AND gf_customer_group_id__c LIKE 'ESCD35LIN00000978ES%' LIMIT 1];
        System.debug('customAss, '+ customAss);
        testOtherLine.Custom_Association__c = customAss.Id;
        update testOtherLine;

        // Build the gf key that the controller expects (LineId_priorityId)
        String gfKey = testOtherLine.Line_Id__c + '_' + risk.gf_group_priority_line_id__c;

        // Create a Custom_Association that matches the gf_customer_group_id__c used in the controller
        Custom_Association__c ca = new Custom_Association__c(
            DMT_Line__c = testOtherLine.Id,
            gf_customer_group_id__c = gfKey,
            Name = 'Test custom4'
        );
        insert ca;

        // Insert two Custom_Association_Client__c children so the controller has clients to process
        List<Custom_Association_Client__c> caClients = new List<Custom_Association_Client__c>{
            new Custom_Association_Client__c(Custom_Association__c = ca.Id, Name = 'Association 1', Alpha_Code_Client__c = 'ES0000000000004', DMT_ClientRating__c = 'BBB', DMT_Client_Rating_Date__c = Date.today()),
            new Custom_Association_Client__c(Custom_Association__c = ca.Id, Name = 'Association 2', Alpha_Code_Client__c = 'ES0000000000005', DMT_ClientRating__c = 'AA', DMT_Client_Rating_Date__c = Date.today())
        };
        insert caClients;

        // Get passport JSON from static resource
        StaticResource passportSaveMock = [
            SELECT Body FROM StaticResource WHERE Name = 'passportSaveMock' LIMIT 1
        ];
        String jsonData = passportSaveMock.Body.toString();

        // Remove any existing passports for this line
        delete [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testOtherLine.Id];

        // Insert new passport
        insert new Passport__c(
            DMT_Line__c = testOtherLine.Id,
            DMT_Passport_Save__c = jsonData
        );

        // Link existing user to line via team member
        insert new DMT_TeamMember__c(
            Line__c = testOtherLine.Id,
            User__c = testUser.Id,
            AccessLevel__c = 'Read'
        );

        // Prepare selected items
        List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();

        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'img64Mock' LIMIT 1];
        String img64 = sr.Body.toString();

        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case'];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String otherLineId = testOtherLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line';
        //String recordTypeDeveloperName = 'OtherProducts';

        String htmlContent = DMT_ViewController.loadComponentsForView(otherLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(otherLineId, type, items);
        String jsonDataFeatureLine = DMT_ViewController.getFeaturesForJsonPdf(otherLineId, '');
        String jsonDataFeatureLine2 = DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id);
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');
        TriggerBypass.removeBypass();
    }

    /*@isTest
    static void testLoadComponentsForViewNullData() {

        // Prepare selected items
        List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String items = JSON.serialize(selectedItems);
        String type = 'Opportunity';
        //String recordTypeDeveloperName = 'DMT_Opportunity';

        String response = DMT_ViewController.loadComponentsForView('', type, items, '', '');
        Test.stopTest();

        // Validaciones
        Assert.isTrue(response.contains('Error'), 'response should contain Error.');
    }*/

    @isTest
    static void testGetItemsToDisplay(){
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case'];

        Group testGroup = [SELECT Id, Name, DeveloperName, Type FROM Group WHERE Name = 'Test Group' LIMIT 1];
        System.debug('testGroup,  '+ testGroup);

        testCase.OwnerId = testGroup.id;
        update testCase;

        DMT_ApproversView__c testApproversView = [SELECT Name, DMT_DeveloperName__c, DMT_Type__c FROM DMT_ApproversView__c LIMIT 1];
        System.debug('testApproversView,  '+ testApproversView);

        DMT_Approver__c testApprover = [SELECT Id, DMT_Group__c, Approvers_View__c, Approvers_View_Treasury__c, Approvers_View_Opportunity__c FROM DMT_Approver__c WHERE DMT_Approver_Code__c = '123' LIMIT 1];
        System.debug('testApprover,  '+ testApprover);

        testApprover.Approvers_View_Treasury__c = testApproversView.Id;
        testApprover.DMT_Group__c = testGroup.DeveloperName;
        update testApprover;

        List<DMT_Items__c> dmtItemsToDelete = [SELECT Id FROM DMT_Items__c];
        delete dmtItemsToDelete;

        String itemsToDisplay;
        itemsToDisplay = DMT_ViewController.getItemsToDisplay(testCase.Id, 'Case');
        Assert.isNotNull(itemsToDisplay, 'there should be itemsToDisplay');
    }

    @isTest
    static void testGetConsumtionLimits() {
        // Crear un mapa simulado de `feature` con datos ficticios
        Map<String, Object> feature = new Map<String, Object>{
            'name' => 'Test Feature',
            'id' => 'Feature123',
            'consumptionLimits' => new List<Object>{
                new Map<String, Object>{
                    'limitDesc' => 'Limit 1',
                    'stateName' => 'Active',
                    'amount' => 1000
                },
                new Map<String, Object>{
                    'limitDesc' => 'Limit 2',
                    'stateName' => 'Inactive',
                    'amount' => 500
                }
            },
            'validations' => new List<Object>{
                new Map<String, Object>{
                    'limitDesc' => 'Limit 1',
                    'stateName' => 'Active',
                    'amount' => 1000
                },
                new Map<String, Object>{
                    'limitDesc' => 'Limit 2',
                    'stateName' => 'Inactive',
                    'amount' => 500
                }
            }
        };
        // Llamar al método bajo prueba
        Test.startTest();
        List<Map<String, Object>> result2 = DMT_FormattingUtils.getListMap(feature,'validations');
        List<Map<String, Object>> result = DMT_FormattingUtils.getListMap(feature,'consumptionLimits');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(result, 'El resultado no debe ser nulo.');
        Assert.areEqual(2, result.size(), 'Debe haber dos límites de consumo.');
        Assert.areEqual('Limit 1', result[0].get('limitDesc'), 'El primer límite debe tener la descripción "Limit 1".');
        Assert.areEqual('Active', result[0].get('stateName'), 'El primer límite debe estar en estado "Active".');
        Assert.areEqual(1000, result[0].get('amount'), 'El primer límite debe tener un monto de 1000.');
        Assert.areEqual('Limit 2', result[1].get('limitDesc'), 'El segundo límite debe tener la descripción "Limit 2".');
        Assert.areEqual('Inactive', result[1].get('stateName'), 'El segundo límite debe estar en estado "Inactive".');
        Assert.areEqual(500, result[1].get('amount'), 'El segundo límite debe tener un monto de 500.');
    }

    @isTest
    static void testTraductorDate() {
        // Caso 1: `fechaText` es null
        String result1 = DMT_FormattingUtils.traductorDate(null);
        Assert.areEqual(' ', result1, 'Debe devolver un espacio si fechaText es null.');

        // Caso 2: `fechaText` es una cadena vacía
        String result2 = DMT_FormattingUtils.traductorDate('');
        Assert.areEqual(' ', result2, 'Debe devolver un espacio si fechaText es una cadena vacía.');

        // Caso 3: `fechaText` es menor a 30
        String result3 = DMT_FormattingUtils.traductorDate('15');
        Assert.areEqual('15D', result3, 'Debe devolver "15D" cuando fechaText es menor a 30.');

        // Caso 4: `fechaText` es mayor o igual a 30 pero menor a 365
        String result4 = DMT_FormattingUtils.traductorDate('90');
        Assert.areEqual('3M', result4, 'Debe devolver "3M" cuando fechaText está entre 30 y 364.');

        // Caso 5: `fechaText` es mayor o igual a 365
        String result5 = DMT_FormattingUtils.traductorDate('730');
        Assert.areEqual('2Y', result5, 'Debe devolver "2Y" cuando fechaText es mayor o igual a 365.');
    }

    @isTest
    static void testNullDataToDelegatorsDMTApprovalProcessDataRenderer(){
        DMT_ApprovalProcessDataRenderer renderer = new DMT_ApprovalProcessDataRenderer();
        String resultHtml;
        Map<String, Object> resultPdfJson;
        Test.startTest();
        resultHtml = renderer.renderHtml(null);
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        resultPdfJson = renderer.renderPdfJson(null);
        Assert.isTrue(resultPdfJson.isEmpty(), 'response should be an empty Map.');
        Test.stopTest();
    }

    @isTest
    static void testInvalidRecordIdDMTApprovalProcessDataRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ApprovalProcessDataRenderer renderer = new DMT_ApprovalProcessDataRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }
    @isTest
    static void testInvalidRecordIdDMTApprovalProcessDataRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ApprovalProcessDataRenderer renderer = new DMT_ApprovalProcessDataRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegatorsDMTClientRenderer(){
        DMT_ClientRenderer renderer = new DMT_ClientRenderer();
        String resultHtml;
        Map<String, Object> resultPdfJson;
        Test.startTest();
        resultHtml = renderer.renderHtml(null);
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        resultPdfJson = renderer.renderPdfJson(null);
        Assert.isTrue(resultPdfJson.isEmpty(), 'response should be an empty Map.');
        Test.stopTest();
    }

    @isTest
    static void testInvalidRecordIdDMTClientRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ClientRenderer renderer = new DMT_ClientRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordIdDMTClientRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ClientRenderer renderer = new DMT_ClientRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }
    //Activity related component test
    @isTest
    static void testDMTActiveRelatedLinesRendererDelegatorGuards(){
        DMT_ActiveRelatedLinesRenderer renderer = new DMT_ActiveRelatedLinesRenderer();
        DMT_ViewController.LineDataWrapper invalidData = new DMT_ViewController.LineDataWrapper();
        invalidData.recordTypeId = null;

        Test.startTest();
        String nullHtml = renderer.renderHtml(null);
        Map<String, Object> nullPdf = renderer.renderPdfJson(null);
        String invalidHtml = renderer.renderHtml(invalidData);
        Map<String, Object> invalidPdf = renderer.renderPdfJson(invalidData);
        Test.stopTest();

        Assert.isTrue(nullHtml.contains('Error'), 'Null data should return Error in HTML renderer.');
        Assert.isTrue(nullPdf.isEmpty(), 'Null data should return empty PDF map.');
        Assert.isTrue(invalidHtml.contains('Error'), 'Invalid record type should return Error in HTML renderer.');
        Assert.isTrue(invalidPdf.isEmpty(), 'Invalid record type should return empty PDF map.');
    }

    @isTest
    static void testDefaultActiveRelatedLinesRendererNoLineData(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c();

        Test.startTest();
        DMT_DefaultActiveRelatedLinesRenderer renderer = new DMT_DefaultActiveRelatedLinesRenderer();
        String htmlResult = renderer.renderHtml(data);
        Map<String, Object> pdfResult = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isTrue(htmlResult.contains('Line data not provided'), 'Missing client should return line data not provided.');
        Assert.isTrue(pdfResult.isEmpty(), 'Missing client should return an empty PDF map.');
    }

    @isTest
    static void testDefaultActiveRelatedLinesRendererWithRelatedLines(){
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(
            Name = 'Main Line In Memory',
            Client__c = testAccount.Id,
            CurrencyIsoCode = 'EUR'
        );

        DMT_Line__c related1 = new DMT_Line__c(
            Name = 'Related InMemory 1',
            Client__c = testAccount.Id,
            CurrencyIsoCode = 'EUR',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(1),
            FD_Amount__c = 2000,
            DvP_Amount__c = 3000
        );
        related1.Client__r = new Account(Name = 'Client 1', g_customer_id__c = 'GCUST-1');

        DMT_Line__c related2 = new DMT_Line__c(
            Name = 'Related InMemory 2',
            Client__c = testAccount.Id,
            CurrencyIsoCode = 'EUR',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(2),
            FD_Amount__c = 2500,
            DvP_Amount__c = 3500
        );
        related2.Client__r = new Account(Name = 'Client 2', g_customer_id__c = 'GCUST-2');

        data.activeRelatedLines = new List<DMT_Line__c>{ related1, related2 };

        Test.startTest();
        DMT_DefaultActiveRelatedLinesRenderer renderer = new DMT_DefaultActiveRelatedLinesRenderer();
        String htmlResult = renderer.renderHtml(data);
        Map<String, Object> pdfResult = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isTrue(htmlResult.contains('Related InMemory 1'), 'HTML should render first related line.');
        Assert.isTrue(htmlResult.contains('Related InMemory 2'), 'HTML should render second related line.');
        Assert.isTrue(htmlResult.contains('Client 1'), 'HTML should render first client name.');
        Assert.isTrue(htmlResult.contains('Client 2'), 'HTML should render second client name.');

        Assert.isFalse(pdfResult.isEmpty(), 'PDF map should not be empty with related lines.');
        List<Object> content = (List<Object>)pdfResult.get('content');
        Map<String, Object> tableObj = (Map<String, Object>)content[4];
        List<List<String>> body = (List<List<String>>)tableObj.get('body');
        Assert.areEqual(2, body.size(), 'PDF body should include one row per related line.');
        Assert.areEqual('Related InMemory 1', body[0][0], 'First PDF row should come from first related line.');
        Assert.areEqual('Related InMemory 2', body[1][0], 'Second PDF row should come from second related line.');
    }

    @isTest
    static void testDMTActiveRelatedLinesRenderer(){
         
        TriggerBypass.setBypass();
        // Get existing user created in makeData()
        User testUser = [SELECT Id FROM User WHERE Profile.Name ='Standard User' AND IsActive = true LIMIT 1];
        DMT_Line__c testTreasuryLine = [SELECT Id, RecordType.DeveloperName, Name, Client_Type__c, Start_Date__c, End_Date__c, DMT_DerivativesAmount__c, FD_Amount__c, DvP_Amount__c, CurrencyIsoCode FROM DMT_Line__c WHERE Line_Id__c = '12345' LIMIT 1];
        System.debug('testTreasuryLine, '+ testTreasuryLine);
        Custom_Association__c customAss = [SELECT Id, DMT_Line__c, g_customer_id__c FROM Custom_Association__c WHERE DMT_Line__c = :testTreasuryLine.Id];
        System.debug('customAss, '+ customAss);
        testTreasuryLine.Booking_Geography__c = 'ES';
        testTreasuryLine.Custom_Association__c = customAss.Id;
        update testTreasuryLine;


        // Get passport JSON from static resource
        StaticResource passportSaveMock = [
            SELECT Body FROM StaticResource WHERE Name = 'passportSaveMock' LIMIT 1
        ];
        String jsonData = passportSaveMock.Body.toString();

        // Remove any existing passports for this line
        delete [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testTreasuryLine.Id];

        // Insert new passport
        insert new Passport__c(
            DMT_Line__c = testTreasuryLine.Id,
            DMT_Passport_Save__c = jsonData
        );

        // Link existing user to line via team member
        insert new DMT_TeamMember__c(
            Line__c = testTreasuryLine.Id,
            User__c = testUser.Id,
            AccessLevel__c = 'Read'
        );

        // Prepare selected items
        List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();

        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'img64Mock' LIMIT 1];
        String img64 = sr.Body.toString();

        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case'];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String treasuryLineId = testTreasuryLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line_Treasury';
        //String recordTypeDeveloperName = 'TreasurySettlement';
        String htmlContent = DMT_ViewController.loadComponentsForView(treasuryLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(treasuryLineId, type, items);
        String jsonDataFeatureLine2 = DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id );
        String jsonDataFeatureLine = DMT_ViewController.getFeaturesForJsonPdf(treasuryLineId, '');
        String jsonDataFeatureLine3 = DMT_ViewController.getFeaturesForJsonPdf('', '');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testNullDataToDelegatorsDMTParticipantRenderer(){
        DMT_ParticipantRenderer renderer = new DMT_ParticipantRenderer();
        String resultHtml;
        Map<String, Object> resultPdfJson;
        Test.startTest();
        resultHtml = renderer.renderHtml(null);
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        resultPdfJson = renderer.renderPdfJson(null);
        Assert.isTrue(resultPdfJson.isEmpty(), 'response should be an empty Map.');
        Test.stopTest();
    }

    @isTest
    static void testInvalidRecordIdDMTParticipantRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ParticipantRenderer renderer = new DMT_ParticipantRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordIdDMTParticipantRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ParticipantRenderer renderer = new DMT_ParticipantRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegatorsDMTPassportRenderer(){
        DMT_PassportRenderer renderer = new DMT_PassportRenderer();
        String resultHtml;
        Map<String, Object> resultPdfJson;
        Test.startTest();
        resultHtml = renderer.renderHtml(null);
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        resultPdfJson = renderer.renderPdfJson(null);
        Assert.isTrue(resultPdfJson.isEmpty(), 'response should be an empty Map.');
        Test.stopTest();
    }

    @isTest
    static void testInvalidRecordIdDMTPassportRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_PassportRenderer renderer = new DMT_PassportRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordIdDMTPassportRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_PassportRenderer renderer = new DMT_PassportRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegatorsDMTLimitVisualRenderer(){
        DMT_LimitVisualRenderer renderer = new DMT_LimitVisualRenderer();
        String resultHtml;
        Map<String, Object> resultPdfJson;
        Test.startTest();
        resultHtml = renderer.renderHtml(null);
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        resultPdfJson = renderer.renderPdfJson(null);
        Assert.isTrue(resultPdfJson.isEmpty(), 'response should be an empty Map.');
        Test.stopTest();
    }

    @isTest
    static void testInvalidRecordIdDMTLimitVisualRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_LimitVisualRenderer renderer = new DMT_LimitVisualRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordIdDMTLimitVisualRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_LimitVisualRenderer renderer = new DMT_LimitVisualRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegatorsDMTInfoRenderer(){
        DMT_InfoRenderer renderer = new DMT_InfoRenderer();
        String resultHtml;
        Map<String, Object> resultPdfJson;
        Test.startTest();
        resultHtml = renderer.renderHtml(null);
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        resultPdfJson = renderer.renderPdfJson(null);
        Assert.isTrue(resultPdfJson.isEmpty(), 'response should be an empty Map.');
        Test.stopTest();
    }

    @isTest
    static void testInvalidRecordIdDMTInfoRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_InfoRenderer renderer = new DMT_InfoRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordIdDMTInfoRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_InfoRenderer renderer = new DMT_InfoRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegatorsDMTLimitRenderer(){
        DMT_LimitRenderer renderer = new DMT_LimitRenderer();
        String resultHtml;
        Map<String, Object> resultPdfJson;
        Test.startTest();
        resultHtml = renderer.renderHtml(null);
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        resultPdfJson = renderer.renderPdfJson(null);
        Assert.isTrue(resultPdfJson.isEmpty(), 'response should be an empty Map.');
        Test.stopTest();
    }

    @isTest
    static void testInvalidRecordIdDMTLimitRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_LimitRenderer renderer = new DMT_LimitRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordIdDMTLimitRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_LimitRenderer renderer = new DMT_LimitRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegatorsDMTCommercialProcessDataRenderer(){
        DMT_CommercialProcessDataRenderer renderer = new DMT_CommercialProcessDataRenderer();
        String resultHtml;
        Map<String, Object> resultPdfJson;
        Test.startTest();
        resultHtml = renderer.renderHtml(null);
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        resultPdfJson = renderer.renderPdfJson(null);
        Assert.isTrue(resultPdfJson.isEmpty(), 'response should be an empty Map.');
        Test.stopTest();
    }

    @isTest
    static void testInvalidRecordIdDMTCommercialProcessDataRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_CommercialProcessDataRenderer renderer = new DMT_CommercialProcessDataRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordIdDMTCommercialProcessDataRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_CommercialProcessDataRenderer renderer = new DMT_CommercialProcessDataRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testInvalidRecordIdDMTPassportProcessFlowRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_PassportProcessFlowRenderer renderer = new DMT_PassportProcessFlowRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordIdDMTPassportProcessFlowRendereRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_PassportProcessFlowRenderer renderer = new DMT_PassportProcessFlowRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testInvalidRecordIdDMTApprovalProcessFlowRendereRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ApprovalProcessFlowRenderer renderer = new DMT_ApprovalProcessFlowRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordIdDMTApprovalProcessFlowRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ApprovalProcessFlowRenderer renderer = new DMT_ApprovalProcessFlowRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testSanctionRecordTypeDMTApprovalProcessFlowRendererDelegatesToOppRenderer(){
        Id sanctionRtId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('Sanction').getRecordTypeId();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = sanctionRtId;
        // Sanction Line view: Approval Process must come from the child Opportunity's steps, not the Line's own steps
        data.allsteps = new List<DMT_Case_Steps_Controller.WRAPPER_Step>();
        data.sanctionOppAllsteps = DMT_ProcessFlowRenderersTest.createSanctionOppTestDataWrapper(true, false, false).sanctionOppAllsteps;

        Test.startTest();
        DMT_ApprovalProcessFlowRenderer renderer = new DMT_ApprovalProcessFlowRenderer();
        String html = renderer.renderHtml(data);
        Map<String, Object> pdf = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isFalse(html.contains('Error'), 'Sanction record type should resolve to a renderer, not error out.');
        Assert.isTrue(html.containsIgnoreCase('Credit Approval'), 'HTML should be built from the child Opportunity steps (sanctionOppAllsteps).');
        Assert.isFalse(pdf.isEmpty(), 'PDF Map should be built from the child Opportunity steps (sanctionOppAllsteps).');
    }
    public static List<DMT_ViewController.ItemWrapper> prepareItemWrapper(){

        return new List<DMT_ViewController.ItemWrapper>{
            new DMT_ViewController.ItemWrapper('Component', 'Line Info',  1, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Client',  2, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Products',  3, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Participants',  4, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Approval Process Data',  5, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Business Plan Data',  18, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Passport',  6, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Limit',  7, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Limit Visual',  8, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Approval Process',  14, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Validation Process',  15, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Active Related Lines',  16, ''),
             new DMT_ViewController.ItemWrapper('Component', 'Approval Modifications',  17, ''),
            new DMT_ViewController.ItemWrapper('Break', 'Page Break',  9, ''),
            new DMT_ViewController.ItemWrapper('Break', 'Line Break',  10, ''),
            new DMT_ViewController.ItemWrapper('Text', 'Text 12px',  11, 'Test text'),
            new DMT_ViewController.ItemWrapper('Text', 'Text 14px',  12, 'Test text'),
            new DMT_ViewController.ItemWrapper('Text', 'Text 18px',  13, 'Test text')
        };
    }

    @isTest
    static void testCreateTable() {
        // Prepare simple head and body data
        List<List<String>> head = new List<List<String>>{ new List<String>{'Col1','Col2'} };
        List<List<String>> body = new List<List<String>>{
            new List<String>{'A1','B1'},
            new List<String>{'A2','B2'}
        };

        Test.startTest();
        Map<String, Object> table = DMT_Create_Pdf_Controller.createTable(head, body);
        Test.stopTest();

        // Basic assertion to cover createTable
        Assert.isNotNull(table, 'Table map should not be null');
    }

    @isTest
    static void testCreateStyledTableObj() {
        // Prepare head and body where body rows correspond to `values` entries
        List<List<Object>> head = new List<List<Object>>{ new List<Object>{'Header1','Header2'} };
        List<List<Object>> body = new List<List<Object>>{
            new List<Object>{'r1c1','r1c2'},
            new List<Object>{'r2c1','r2c2'}
        };

        // values map to each body row; mark the second row as a total
        List<String> values = new List<String>{'api_row_1','api_row_2'};
        List<String> totals = new List<String>{'api_row_2'};
        List<String> totalsDarker = new List<String>();

        Test.startTest();
        Map<String, Object> table = DMT_Create_Pdf_Controller.createStyledTableObj(head, body, values, totals, totalsDarker);
        Test.stopTest();

        Assert.isNotNull(table, 'Table should not be null');
    }

    @isTest
    static void testSaveNativeSnapshots() {
        TriggerBypass.setBypass();
        Task testTask = [SELECT Id FROM Task WHERE Subject = 'Test Task 1' LIMIT 1];

        Test.startTest();
        // Call the method to insert HTML, JSON and PDF snapshots
        Blob testPdfBlob = Blob.valueOf('fake pdf content');
        DMT_ViewController.saveNativeSnapshots(testTask.Id, '<html><body>Test HTML</body></html>', '{"test": "json data"}', testPdfBlob);
        Test.stopTest();

        // 1. Verify ContentVersions were created (HTML, JSON and PDF)
        List<ContentVersion> cvs = [SELECT Id, Title, PathOnClient, VersionData FROM ContentVersion WHERE Title IN ('Task completed HTML', 'Task completed JSON', 'Task completed PDF')];
        Assert.areEqual(3, cvs.size(), 'Three ContentVersion records (HTML, JSON and PDF) should have been inserted.');

        // 2. Verify they were linked to the Task
        List<ContentDocumentLink> cdls = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :testTask.Id];
        Assert.isTrue(cdls.size() >= 3, 'ContentDocumentLinks should have been created for the Task.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testSaveNativeSnapshotsOnlyHtml() {
        TriggerBypass.setBypass();
        Task testTask = [SELECT Id FROM Task WHERE Subject = 'Test Task 1' LIMIT 1];

        Test.startTest();
        // Call with only HTML — JSON and PDF are blank/null
        DMT_ViewController.saveNativeSnapshots(testTask.Id, '<html><body>Only HTML</body></html>', '', null);
        Test.stopTest();

        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion WHERE Title = 'Task completed HTML'];
        Assert.areEqual(1, cvs.size(), 'Only one ContentVersion (HTML) should have been inserted.');

        List<ContentDocumentLink> cdls = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testTask.Id];
        Assert.areEqual(1, cdls.size(), 'Only one ContentDocumentLink should have been created.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testSaveNativeSnapshotsAllBlank() {
        TriggerBypass.setBypass();
        Task testTask = [SELECT Id FROM Task WHERE Subject = 'Test Task 1' LIMIT 1];

        Test.startTest();
        // Call with all blank/null — nothing should be inserted
        DMT_ViewController.saveNativeSnapshots(testTask.Id, '', '', null);
        Test.stopTest();

        List<ContentDocumentLink> cdls = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testTask.Id];
        Assert.areEqual(0, cdls.size(), 'No ContentDocumentLinks should exist when all inputs are blank.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testGetModalFilesData() {
        TriggerBypass.setBypass();
        Task testTask = [SELECT Id FROM Task WHERE Subject = 'Test Task 1' LIMIT 1];

        // 1. Test empty state first
        Test.startTest();
        Map<String, Object> emptyResult = DMT_ViewController.getModalFilesData(testTask.Id);
        Assert.isFalse((Boolean)emptyResult.get('hasJSON'), 'hasJSON should be false when no files exist.');
        Assert.isNull(emptyResult.get('htmlData'), 'htmlData should be null when no files exist.');

        // 2. Create the data using our save method
        DMT_ViewController.saveNativeSnapshots(testTask.Id, '<html><body>Test HTML</body></html>', '{"test": "json data"}', null);

        // 3. Test retrieval state
        Map<String, Object> populatedResult = DMT_ViewController.getModalFilesData(testTask.Id);
        Test.stopTest();

        Assert.isTrue((Boolean)populatedResult.get('hasJSON'), 'hasJSON should be true after files are saved.');
        Assert.isNotNull(populatedResult.get('htmlData'), 'htmlData should not be null after files are saved.');
        Assert.isNotNull(populatedResult.get('jsonData'), 'jsonData should not be null after files are saved.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testDeleteNativeSnapshots() {
        // 1. Setup: Create a test Task
        Task testTask = new Task(
            Subject = 'Test PDF Deletion Task',
            Status = 'Open'
        );
        insert testTask;

        // 2. Setup: Create a ContentVersion (This automatically creates a ContentDocument)
        ContentVersion testSnapshot = new ContentVersion(
            Title = 'Test Snapshot',
            PathOnClient = 'TestSnapshot.html',
            VersionData = Blob.valueOf('<html><body>Test HTML Data</body></html>'),
            IsMajorVersion = true
        );
        insert testSnapshot;

        // Retrieve the generated ContentDocumentId
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testSnapshot.Id].ContentDocumentId;

        // 3. Setup: Link the Document to the Task (ContentDocumentLink)
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = testTask.Id,
            ContentDocumentId = contentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        // Verify the setup worked (File exists and is linked)
        List<ContentDocumentLink> beforeLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testTask.Id];
        Assert.areEqual(1, beforeLinks.size(), 'Should have 1 document linked to the task before deletion.');

        // 4. Execution: Run the method to test
        Test.startTest();
        DMT_ViewController.deleteNativeSnapshots(testTask.Id);
        Test.stopTest();

        // 5. Assertion: Verify the ContentDocument is completely deleted
        List<ContentDocument> remainingDocs = [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
        Assert.areEqual(0, remainingDocs.size(), 'The ContentDocument should have been completely deleted.');

        List<ContentDocumentLink> remainingLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testTask.Id];
        Assert.areEqual(0, remainingLinks.size(), 'The ContentDocumentLink should no longer exist.');
    }

    @isTest
    static void testNewOpportunityRenderers_ValidData() {
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        DMT_Opportunity_Mitigant__c mitigants = [SELECT Id, DMT_Opportunity_Product__c, Commercial_Percentage__c, Political_Percentage__c, End_Date__c, Internal_Rating__c,
        External_Rating__c, DMT_Currency__c, DMT_Country_Guarantor__c, Liquidation_Period__c 
        FROM DMT_Opportunity_Mitigant__c LIMIT 1];
        mitigants.Mitigant_Type__c = 'Real > Mortgage guarantee';
        update mitigants;
        
        // Build the Wrapper with IN-MEMORY data!
        // This prevents SOQL "unqueried field" exceptions when the renderers use dynamic SObject.get()
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        DMT_ViewController.OpportunityProduct oppProduct = new DMT_ViewController.OpportunityProduct();
        oppProduct.name = 'Test Sustainable Product';
        oppProduct.sustainableDealAssessment =  '6';
        oppProduct.sustainableDealSubtype =  'Social';
        oppProduct.sustainableDealValue =  'RBSO0105';
        oppProduct.greenActivityFilter = 'delegated';
        oppProduct.sustainableDealLabel = 'Test Label';
        oppProduct.sustainablePercentage = '1.12';
        oppProduct.sustainabilityBonusEligible = 'true';
        oppProduct.oppMitigants.add(mitigants);
        
        // 1. Setup Opportunity (Mocking OpportunityLineItems via JSON to pass Summaries empty check)
        data.opportunity = (Opportunity)JSON.deserialize(
            '{"attributes":{"type":"Opportunity"},"Name":"Test Opportunity","CurrencyIsoCode":"EUR","DMT_Opp_Id__c":"00001","DMT_CurrencyText__c":"EUR","OpportunityLineItems":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"OpportunityLineItem"},"Id":"00k000000000000"}]}}', 
            Opportunity.class
        );
        data.opportunity.RecordTypeId = oppRtId;

        // 2. Setup Account (Mocking formula field via JSON to bypass "Field is not writeable" error)
        data.opportunity.Account = (Account)JSON.deserialize(
            '{"attributes":{"type":"Account"},"Name":"Test Account","DES_Client_Type__c":"Subsidiary"}',
            Account.class
        );

        // 3. Setup Client (Added Counterpart fields to cover DMT_OppClientNBCRenderer logic)
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Commitment_Deadline__c = Date.today(),
            DMT_Exception_Pool__c = 'Test Pool',
            DMT_Tiering_Action__c = 'Uptier',
            DMT_Current__c = 10,
            DMT_Target__c = 11,
            Counterpart__c = 'Fin Inst',
            SCRA__c = 'SCRA Active',
            AVC_Check__c = true,
            European_Bank_Check__c = true
        );

        data.oppProducts.add(oppProduct);
        data.recordTypeId = oppRtId;
        data.currencyIsoCode = 'EUR';

        // 4. Setup Mock Sanction Data & X-Sell/Approval Data
        data.line = new DMT_Line__c(
            Name = 'Test Sanction',
            Amount__c = 50000,
            CurrencyIsoCode = 'EUR',
            DMT_Comments__c = 'Test Comment'
        );
        data.line.Client__r = new Account(Name = 'Test Client Name');
        data.line.DMT_LocalClient__r = new Local_Client__c(Name = 'Test Local Client');

        data.riskLineList = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(Name = 'Test Risk Product', DMT_Amount__c = 10000, CurrencyIsoCode = 'EUR')
        };

        // --- NEW: Populate Lists for Business Plan & Approval Process Data ---
        data.xSellOpp = new List<DMT_X_Sell__c>{
            new DMT_X_Sell__c(Booking_Geography__c = 'ES', XSELL_Value_PY__c = 100, XSELL_Value_CY__c = 200, XSELL_Value_NY__c = 300, XSELL_Value_NY1__c = 400),
            new DMT_X_Sell__c(Booking_Geography__c = 'UNKNOWN', XSELL_Value_PY__c = 10, XSELL_Value_CY__c = 20, XSELL_Value_NY__c = 30, XSELL_Value_NY1__c = 40)
        };
        data.taxonomyH007Map = new Map<String, String>{ 'ES' => 'Spain (ES)' };

        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>{
            new DMT_Banking_Pool_Structure__c(Name = 'Tier 1', DMT_Ticket__c = '100', DMT_Fees__c = '50', DMT_Margin__c = '20', DMT_N_Banks__c = '3')
        };

        // Populate standard featuresList with Profitability data to pass the Profitability renderer guards
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'profitability' => new Map<String, Object>{
                    'audit' => new Map<String, Object>{ 'rorcThreshold' => 0.20, 'raroecThreshold' => 0.15 },
                    'results' => new List<Object>{
                        new Map<String, Object>{
                            'productId' => '00k000000000000',
                            'rorc' => 10.5, 'raroec' => 15.2, 'rorcProspected' => 5.5, 'raroecProspected' => 7.5, 'clientRorc' => 12.0,
                            'averageLife' => 1.5, 'spreadDbPbs' => 10, 'spreadFbPbs' => 10, 'feesDbPbs' => 10, 'feesFbPbs' => 10,
                            'fundingDbPbs' => 10, 'fundingFbPbs' => 10, 'countryRiskProvisionDbPbs' => 10, 'countryRiskProvisionFbPbs' => 10,
                            'expectedLossPbs' => 10, 'taxRate' => 30, 'franchiseDeal' => 100, 'bdi' => 100,
                            'regulatoryEad' => 100, 'regulatoryCcf' => 100, 'regulatoryLgd' => 100, 'regulatoryApr' => 100, 'regulatoryCapital' => 100,
                            'economicEad' => 100, 'economicCcf' => 100, 'economicLgd' => 100, 'economicApr' => 100, 'economicCapital' => 100
                        },
                        new Map<String, Object>{
                            'rorc' => 10.5, 'raroec' => 15.2, 'rorcProspected' => 5.5, 'raroecProspected' => 7.5, 'clientRorc' => 12.0
                        }
                    }
                }
            }
        };

        data.sanctionFeaturesList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'Feature 0 - Ignored by Visual Limit',
                'stateName' => 'GREEN'
            },
            new Map<String, Object>{
                'name' => 'Approval Process',
                'stateName' => 'GREEN',
                'consumptionLimits' => new List<Object>{
                    new Map<String, Object>{
                        'limitDesc' => 'Test Limit',
                        'stateName' => 'GREEN',
                        'conditionDesc' => 'Condition',
                        'currencyId' => 'EUR',
                        'amount' => new Map<String, Object>{
                            'currentApprovedAmount' => 10000,
                            'cmtContDisposedAmount' => 1000,
                            'uncmtContDisposedAmount' => 500,
                            'cmtContNonDspsAmount' => 200,
                            'uncmtContNonDspsAmount' => 100,
                            'authorizedRiskAmount' => 300,
                            'notSignedTrConsumptionAmount' => 50,
                            'unavailableRiskAmount' => 20000
                        }
                    }
                },
                'validations' => new List<Object>{
                    new Map<String, Object>{'name' => 'Test Validation', 'state' => 'GREEN', 'message' => 'OK'}
                }
            }
        };

        // 5. Add ALL components including the new Sanction ones
        List<String> newComponents = new List<String>{
            'Basic Financials',
            'Client Information',
            'Business Plan Data',
            'Approval Process Data', // <-- Added to ensure this class gets full coverage
            'Client Tier',
            'Sustainable Finance',
            'Sustainability',
            'Main Characteristics of the Deal',
            'Other Aspect',
            'Risks',
            'Basic Requirement',
            'Intro Opportunity Deal',
            'Products',
            'Product Simple',
            // --- NEW SANCTION COMPONENTS ---
            'Sanction Approval Info',
            'Sanction Client',
            'Sanction Products',
            'Sanction Approval Process Data', 'Sanction Passport', 'Sanction Limit', 'Sanction Limit Visual',
            // --- NEW NBC AND PROFITABILITY COMPONENTS ---
            'Opportunity Info NBC', 'Client NBC', 'Profitability', 'Profitability Summaries', 'Profitability Visual',
            // --- STATUS COMPONENT ---
            'Status'
        };

        Test.startTest();
        for(String compName : newComponents) {
            DMT_ViewRenderer renderer = DMT_RendererFactory.getRenderer(compName);

            // PASS 1: Without Images (Covers the "else" block that builds the complex charts)
            data.isImg64 = false;
            data.itemImgBase64 = new List<DMT_ViewController.ItemImgB64>();
            
            String html = renderer.renderHtml(data);
            Map<String, Object> pdf = renderer.renderPdfJson(data);

            Assert.isNotNull(html, 'HTML output should not be null for component: ' + compName);
            Assert.isNotNull(pdf, 'PDF Map should not be null for component: ' + compName);
            Assert.isFalse(html.contains('Error:'), 'HTML should not contain an exception error for ' + compName);

            // PASS 2: With Images (Covers the "if" block that renders base64 images)
            data.isImg64 = true;
            DMT_ViewController.ItemImgB64 mockImg = new DMT_ViewController.ItemImgB64();
            mockImg.imgB64 = 'data:image/jpeg;base64,mockdata123';
            
            // Add a couple of items to satisfy the j >= 0 index math (size <= 3 logic)
            data.itemImgBase64 = new List<DMT_ViewController.ItemImgB64>{ mockImg, mockImg };
            
            String htmlWithImg = renderer.renderHtml(data);
            Map<String, Object> pdfWithImg = renderer.renderPdfJson(data);

            Assert.isNotNull(htmlWithImg, 'HTML output with images should not be null for component: ' + compName);
            Assert.isNotNull(pdfWithImg, 'PDF Map with images should not be null for component: ' + compName);
        }
        Test.stopTest();
    }

    @isTest
    static void testNewOpportunityRenderersNullData() {
        List<String> newComponents = new List<String>{
            'Basic Financials', 'Client Information', 'Business Plan Data', 'Approval Process Data', 'Client Tier',
            'Sustainable Finance', 'Main Characteristics of the Deal',
            'Other Aspect', 'Risks', 'Basic Requirement', 'Intro Opportunity Deal','Products', 'Product Simple',
            // --- NEW SANCTION COMPONENTS ---
            'Sanction Approval Info', 'Sanction Client', 'Sanction Products', 
            'Sanction Approval Process Data', 'Sanction Passport', 'Sanction Limit', 'Sanction Limit Visual',
            // --- NEW NBC AND PROFITABILITY COMPONENTS ---
            'Opportunity Info NBC', 'Client NBC', 'Profitability', 'Profitability Summaries', 'Profitability Visual',
            // --- STATUS COMPONENT ---
            'Status'
        };

        Test.startTest();
        for(String compName : newComponents) {
            DMT_ViewRenderer renderer = DMT_RendererFactory.getRenderer(compName);

            String html = renderer.renderHtml(null);
            Map<String, Object> pdf = renderer.renderPdfJson(null);

            Assert.isTrue(html.contains('not provided') || html.contains('Error'), 'HTML should gracefully handle null data for ' + compName);
            Assert.isTrue(pdf.isEmpty(), 'PDF Map should return empty for null data on ' + compName);
        }
        Test.stopTest();
    }

    @isTest
    static void testNewOpportunityRenderersInvalidRecordType() {
        // 1. Build a wrapper that is NOT null, but has a missing/invalid RecordType
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Dummy Opp'); // Prevents the first 'isEmpty' check from returning early
        data.oppClient = new DMT_Opportunity_Client__c();
        data.recordTypeId = null; // This forces the Delegator class to throw an exception

        List<String> newComponents = new List<String>{
            'Basic Financials', 'Client Information', 'Business Plan Data', 'Approval Process Data', 'Client Tier',
            'Sustainable Finance', 'Main Characteristics of the Deal',
            'Other Aspect', 'Risks', 'Basic Requirement', 'Intro Opportunity Deal','Products', 'Product Simple',
            // --- NEW SANCTION COMPONENTS ---
            'Sanction Approval Info', 'Sanction Client', 'Sanction Products', 
            'Sanction Approval Process Data', 'Sanction Passport', 'Sanction Limit', 'Sanction Limit Visual',
            // --- NEW NBC AND PROFITABILITY COMPONENTS ---
            'Opportunity Info NBC', 'Client NBC', 'Profitability', 'Profitability Summaries', 'Profitability Visual',
            // --- STATUS COMPONENT ---
            'Status'
        };

        Test.startTest();
        for(String compName : newComponents) {
            DMT_ViewRenderer renderer = DMT_RendererFactory.getRenderer(compName);

            String html = renderer.renderHtml(data);
            Map<String, Object> pdf = renderer.renderPdfJson(data);

            Assert.isTrue(html.contains('Error'), 'HTML should catch missing recordType error for ' + compName);
            Assert.isTrue(pdf.isEmpty(), 'PDF Map should catch error and return empty for ' + compName);
        }
        Test.stopTest();
    }

    @isTest
    static void testInvalidRecordIdDMT_ApprovalModificationsRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ApprovalModificationsRenderer renderer = new DMT_ApprovalModificationsRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }
    @isTest
    static void testInvalidRecordIdDMT_ApprovalModificationsRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ApprovalModificationsRenderer renderer = new DMT_ApprovalModificationsRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testDMTDefaultApprovalModificationsRenderer_ValidData() {
        // 1. Manually build the Wrapper and inject the target list
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.closedWonVersions = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => '1.0',
                'description' => 'Test Post-Approval Modification',
                'user' => 'Test User',
                'eventDate' => String.valueOf(Date.today())
            }
        };

        Test.startTest();
        DMT_DefaultApprovalModificationsRenderer renderer = new DMT_DefaultApprovalModificationsRenderer();
        String htmlResult = renderer.renderHtml(data);
        Map<String, Object> pdfResult = renderer.renderPdfJson(data);
        Test.stopTest();

        // 2. Assert HTML Loop Execution
        Assert.isNotNull(htmlResult);
        Assert.isTrue(htmlResult.contains('Change Audit Trail'), 'HTML should contain Change Audit Trail table');
        Assert.isTrue(htmlResult.contains('Test Post-Approval Modification'), 'HTML should render the description data loop');

        // 3. Assert PDF Loop Execution
        Assert.isNotNull(pdfResult);
        Assert.isFalse(pdfResult.isEmpty(), 'PDF Map should not be empty');
        Assert.areEqual('Post-Approval Management', (String) pdfResult.get('name'), 'PDF should set correct component name');
    }

    @isTest
    static void testDMTDefaultApprovalModificationsRenderer_EmptyData() {
        // Test the early exit guards
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.closedWonVersions = new List<Map<String, Object>>(); // Empty list

        Test.startTest();
        DMT_DefaultApprovalModificationsRenderer renderer = new DMT_DefaultApprovalModificationsRenderer();
        String htmlResult = renderer.renderHtml(data);
        Map<String, Object> pdfResult = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isTrue(htmlResult.contains('There are no versions with post-approval modifications.'), 'HTML should display empty message');
        Assert.isTrue(pdfResult.isEmpty(), 'PDF Map should be empty for no versions');
    }

        private static DMT_Line__c createTreasuryLine(
        Id accountId,
        String lineCode,
        Date startDate,
        Date endDate
    ) {
        DMT_Line__c line = new DMT_Line__c();
        line.Allowed__c = false;
        line.Booking_Geography__c = 'ES';
        line.Clearing__c = false;
        line.Client_Code__c = 'TEST-' + lineCode;
        line.CurrencyIsoCode = 'EUR';
        line.DMT_Client_Entific__c = 'ES';
        line.DMT_Comments__c = 'Test comments';
        line.DvP_Amount__c = 100;
        line.DvP_Currency__c = 'EUR';
        line.End_Date__c = endDate;
        line.FD_Amount__c = 100;
        line.FD_Currency__c = 'EUR';
        line.Line_Id__c = lineCode;
        line.Name = 'Test Treasury Line ' + lineCode;
        line.Start_Date__c = startDate;
        line.Status__c = 'Closed';
        line.Closed__c = 'Won';
        line.Treasury_Currency__c = 'EUR';
        line.Waiver__c = false;
        line.Repos_Limit_6M__c = 120000;
        line.Repos_Limit__c = 120000;
        line.Client__c = accountId;
        RecordType treasuryRT = [SELECT Id FROM RecordType WHERE SObjectType = 'DMT_Line__c' AND DeveloperName = 'TreasurySettlement' LIMIT 1];
        line.RecordTypeId = treasuryRT.Id;
        insert line;

        return line;
    }

    @IsTest
    static void testGetRelatedTRSRLinesByLineId_Customer() {
        Account sourceAcc = [SELECT Id, Name, DES_Group_Code__c, g_customer_id__c FROM Account WHERE DES_Group_Code__c = 'G20180109100427'LIMIT 1];
        sourceAcc.g_customer_id__c = 'CUST_001';
        update sourceAcc;

        Date startDate = Date.today();
        Date endDate = Date.today().addMonths(6);

        DMT_Line__c sourceLine = createTreasuryLine(
            sourceAcc.Id,
            'TL-001',
            startDate,
            endDate
        );

        DMT_Line__c relatedLine = createTreasuryLine(
            sourceAcc.Id,
            'TL-002',
            startDate.addDays(5),
            endDate.addDays(5)
        );

        Test.startTest();
        List<DMT_Line__c> result = DMT_View_Selector.getRelatedTRSRLinesByLineId(sourceLine.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assertEquals(1, result.size(), 'Debe devolver una única línea relacionada');
        System.assertEquals(relatedLine.Id, result[0].Id, 'Debe devolver la línea relacionada');
    }

    @IsTest
    static void testGetRelatedTRSRLinesByLineId_NoResults() {
        Account sourceAcc = [SELECT Id, Name, DES_Group_Code__c, g_customer_id__c FROM Account WHERE DES_Group_Code__c = 'G20180109100427'LIMIT 1];
        sourceAcc.g_customer_id__c = 'NO_MATCH_001';
        update sourceAcc;

        DMT_Line__c sourceLine = createTreasuryLine(
            sourceAcc.Id,
            'TL-005',
            Date.today(),
            Date.today().addMonths(3)
        );

        Test.startTest();
        List<DMT_Line__c> result = DMT_View_Selector.getRelatedTRSRLinesByLineId(sourceLine.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'No debe devolver líneas');
    }

    @isTest
    static void testNullDataToDelegatorsDMTSanctionParticipantsRenderer(){
        DMT_SanctionParticipantsRenderer renderer = new DMT_SanctionParticipantsRenderer();
        Test.startTest();
        String resultHtml = renderer.renderHtml(null);
        Map<String, Object> resultPdfJson = renderer.renderPdfJson(null);
        Test.stopTest();
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        Assert.isTrue(resultPdfJson.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testInvalidRecordIdDMTSanctionParticipantsRenderer(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_SanctionParticipantsRenderer renderer = new DMT_SanctionParticipantsRenderer();
        String resultHtml = renderer.renderHtml(data);
        Map<String, Object> resultPdf = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        Assert.isTrue(resultPdf.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testDMTOpportunityClientRendererRenderHtml_CatchBlock() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.oppClient = new DMT_Opportunity_Client__c(
            Counterpart__c = 'Fin Inst'
        );
        data.forceException = true;

        Test.startTest();
        DMT_OpportunityClientRenderer renderer = new DMT_OpportunityClientRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(result.contains('Error:'), 'Debe entrar en el catch y devolver Error');
    }

    @isTest
    static void testDMTOpportunityClientRendererRenderPdfJson_CatchBlock() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.oppClient = new DMT_Opportunity_Client__c(
            Counterpart__c = 'Fin Inst'
        );
        data.forceException = true;

        Test.startTest();
        DMT_OpportunityClientRenderer renderer = new DMT_OpportunityClientRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Debe entrar en el catch y devolver mapa vacío');
    }

    @isTest
    static void testDMTOpportunityInfoRendererRenderHtml() {
        Id oppRtId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = oppRtId;
        data.currencyIsoCode = 'EUR';
        data.oppEntific = 'Spain';
        data.oppEntity = 'BBVA Entity';
        data.xSellOpp = new List<DMT_X_Sell__c>();

        data.opportunity = new Opportunity(
            Name = 'Opp Test',
            RecordTypeId = oppRtId,
            DMT_Opp_Id__c = 'OPP-001',
            Entific__c = 'ES',
            DMT_Entity__c = '001',
            DMT_CUR_Notional_Amount__c = 1000,
            DMT_CurrencyText__c = 'EUR',
            DMT_Capital_Action__c = 'No',
            DMT_Product_Area__c = 'IB&F',
            DMT_ContingentCommitments__c = 'Yes'
        );

        Test.startTest();
        DMT_InfoRenderer renderer = new DMT_InfoRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.isTrue(result.contains('Opportunity Info'));
        Assert.isFalse(result.contains('Error'));
    }

    @isTest
    static void testDMTOpportunityInfoRendererRenderPdfJson() {
        Id oppRtId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = oppRtId;
        data.currencyIsoCode = 'EUR';
        data.oppEntific = 'Spain';
        data.oppEntity = 'BBVA Entity';
        data.xSellOpp = new List<DMT_X_Sell__c>();

        data.opportunity = new Opportunity(
            Name = 'Opp Test',
            RecordTypeId = oppRtId,
            DMT_Opp_Id__c = 'OPP-001',
            Entific__c = 'ES',
            DMT_Entity__c = '001',
            DMT_CUR_Notional_Amount__c = 1000,
            DMT_CurrencyText__c = 'EUR',
            DMT_Capital_Action__c = 'No',
            DMT_Product_Area__c = 'IB&F',
            DMT_ContingentCommitments__c = 'Yes'
        );

        Test.startTest();
        DMT_InfoRenderer renderer = new DMT_InfoRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.isFalse(result.isEmpty());
        Assert.areEqual('Opportunity Info', (String) result.get('name'));
    }

    @isTest
    static void testDMTOppSustainableFinanceRendererRenderHtmlIBF() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(
            Name = 'Sustainable Finance Test',
            DMT_Product_Area__c = 'IB&F'
        );
        data.oppClient = new DMT_Opportunity_Client__c();

        Test.startTest();
        DMT_OppSustainableFinanceRenderer renderer = new DMT_OppSustainableFinanceRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.isTrue(result.contains('SUSTAINABLE FINANCE'));
        Assert.isFalse(result.contains('Opportunity data not provided'));
        Assert.isFalse(result.contains('Error:'));
    }

    @isTest
    static void testDMTOppSustainableFinanceRendererRenderPdfJsonGTB() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(
            Name = 'Sustainable Finance Test',
            DMT_Product_Area__c = 'GTB'
        );
        data.oppClient = new DMT_Opportunity_Client__c();

        Test.startTest();
        DMT_OppSustainableFinanceRenderer renderer = new DMT_OppSustainableFinanceRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.isFalse(result.isEmpty());
        Assert.areEqual('Sustainable Finance', (String) result.get('name'));
    }

    @isTest
    static void testDMTOppSustainableFinanceRendererUnsupportedProductArea() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(
            Name = 'Sustainable Finance Test',
            DMT_Product_Area__c = ''
        );
        data.oppClient = new DMT_Opportunity_Client__c();

        Test.startTest();
        DMT_OppSustainableFinanceRenderer renderer = new DMT_OppSustainableFinanceRenderer();
        String htmlResult = renderer.renderHtml(data);
        Map<String, Object> pdfResult = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.areEqual('', htmlResult);
        Assert.isTrue(pdfResult.isEmpty());
    }

    @isTest
    static void testDMTOppClientTierRendererRenderHtml() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Test');
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Tiering_Action__c = 'Uptier',
            DMT_Current__c = 10,
            DMT_Target__c = 11
        );

        Test.startTest();
        DMT_OppClientTierRenderer renderer = new DMT_OppClientTierRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.isTrue(result.contains('CLIENT TIER'));
        Assert.isFalse(result.contains('Error:'));
    }

    @isTest
    static void testDMTOppClientTierRendererRenderPdfJson() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Test');
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Tiering_Action__c = 'Uptier',
            DMT_Current__c = 10,
            DMT_Target__c = 11
        );

        Test.startTest();
        DMT_OppClientTierRenderer renderer = new DMT_OppClientTierRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.isFalse(result.isEmpty());
        Assert.areEqual('Client Tier', (String) result.get('name'));
    }

    @isTest
    static void testDMTOppClientTierRendererNullData() {
        Test.startTest();
        DMT_OppClientTierRenderer renderer = new DMT_OppClientTierRenderer();
        String htmlResult = renderer.renderHtml(null);
        Map<String, Object> pdfResult = renderer.renderPdfJson(null);
        Test.stopTest();

        Assert.areEqual('<div>Opportunity data not provided</div>', htmlResult);
        Assert.isTrue(pdfResult.isEmpty());
    }

    @isTest
    static void testDMTOppBasicRequirementRendererRenderHtml() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Basic Requirement Opportunity');
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Clients_Global_RORC_CIB_Past_FY__c = 0.17,
            DMT_CDD_Clients_Global_Rorc_Last_FY__c = 0.28,
            DMT_Exception_Pool__c = 'YES',
            DMT_Other_Relevant_Issues__c = 'Other issues BR Test'
        );
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'profitability' => new Map<String, Object>{
                    'audit' => new Map<String, Object>{
                        'rorcThreshold' => 0.20,
                        'raroecThreshold' => 0.15
                    },
                    'results' => new List<Object>{
                        new Map<String, Object>{
                            'rorc' => 0.1234,
                            'raroec' => 0.2345,
                            'rorcProspected' => 0.3456,
                            'raroecProspected' => 0.4567,
                            'clientRorc' => 0.5678,
                            'incomes12months' => 1234.56
                        }
                    }
                }
            }
        };

        Test.startTest();
        DMT_OppBasicRequirementRenderer renderer = new DMT_OppBasicRequirementRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.isTrue(result.contains('Basic Profitability Metrics'));
        Assert.isTrue(result.contains('12.34 % < 20.00 %'));
        Assert.isTrue(result.contains('YES'));
        Assert.isTrue(result.contains('Other issues BR Test'));
        Assert.isFalse(result.contains('Error:'));
    }

    @isTest
    static void testDMTOppBasicRequirementRendererRenderPdfJson() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Basic Requirement Opportunity');
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Clients_Global_RORC_CIB_Past_FY__c = 0.17,
            DMT_CDD_Clients_Global_Rorc_Last_FY__c = 0.28,
            DMT_Exception_Pool__c = 'YES',
            DMT_Other_Relevant_Issues__c = 'Other issues BR Test'
        );
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'profitability' => new Map<String, Object>{
                    'audit' => new Map<String, Object>{
                        'rorcThreshold' => 0.20,
                        'raroecThreshold' => 0.15
                    },
                    'results' => new List<Object>{
                        new Map<String, Object>{
                            'rorc' => 0.1234,
                            'raroec' => 0.2345,
                            'rorcProspected' => 0.3456,
                            'raroecProspected' => 0.4567,
                            'clientRorc' => 0.5678,
                            'incomes12months' => 1234.56
                        }
                    }
                }
            }
        };

        Test.startTest();
        DMT_OppBasicRequirementRenderer renderer = new DMT_OppBasicRequirementRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        String pdfJson = JSON.serialize(result);

        Assert.isNotNull(result);
        Assert.isFalse(result.isEmpty());
        Assert.areEqual('Basic Profitability Metrics', (String) result.get('name'));
        Assert.isTrue(pdfJson.contains('1234,56'));
        Assert.isTrue(pdfJson.contains('YES'));
        Assert.isTrue(pdfJson.contains('Other issues BR Test'));
    }

    @isTest
    static void testDMTOpportunitySustainabilityRendererRenderHtml() {
        Id oppRtId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = oppRtId;

        DMT_ViewController.OpportunityProduct oppProduct = new DMT_ViewController.OpportunityProduct();
        oppProduct.name = 'Test Sustainable Product';
        oppProduct.sustainableDealAssessment = '6';
        oppProduct.sustainableDealSubtype = 'Social';
        oppProduct.greenActivityFilter = 'delegated';
        oppProduct.sustainableDealLabel = 'Test Label';
        oppProduct.sustainablePercentage = '1.12';
        oppProduct.sustainabilityBonusEligible = 'tue';

        data.oppProducts.add(oppProduct);

        Test.startTest();
        DMT_OpportunitySustainabilityRenderer renderer = new DMT_OpportunitySustainabilityRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isNotNull(result, 'El HTML no debe ser null.');
        Assert.isTrue(result.contains('Sustainability'), 'Debe pintar el título Sustainability.');
        Assert.isTrue(result.contains('Test Sustainable Product'), 'Debe pintar el nombre del producto.');
        Assert.isTrue(result.contains('Sustainable Deal Assessment'), 'Debe pintar Sustainable Deal Assessment.');
        Assert.isTrue(result.contains('Sustainable Deal Subcategory'), 'Debe pintar Sustainable Deal Subcategory.');
        Assert.isTrue(result.contains('Green Activity Filter'), 'Debe pintar Green Activity Filter.');
        Assert.isTrue(result.contains('Delegated Label'), 'Debe traducir delegated a Delegated Label.');
        Assert.isTrue(result.contains('Sustainable Deal Label'), 'Debe pintar Sustainable Deal Label.');
        Assert.isTrue(result.contains('Sustainability Percentage (%)'), 'Debe pintar Sustainability Percentage.');
        Assert.isTrue(result.contains('Sustainability bonus-eligible'), 'Debe pintar Sustainability bonus-eligible.');
        Assert.isFalse(result.contains('Error:'), 'No debe devolver error.');
    }

    @isTest
    static void testDMTOpportunitySustainabilityRendererRenderPdfJson() {
        Id oppRtId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = oppRtId;

        DMT_ViewController.OpportunityProduct oppProduct = new DMT_ViewController.OpportunityProduct();
        oppProduct.name = 'Test Sustainable Product';
        oppProduct.sustainableDealAssessment = '6';
        oppProduct.sustainableDealSubtype = 'Social';
        oppProduct.greenActivityFilter = 'other';
        oppProduct.sustainableDealLabel = 'Test Label';
        oppProduct.sustainablePercentage = '1.12';
        oppProduct.sustainabilityBonusEligible = 'true';

        data.oppProducts.add(oppProduct);

        Test.startTest();
        DMT_OpportunitySustainabilityRenderer renderer = new DMT_OpportunitySustainabilityRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isNotNull(result, 'El mapa PDF no debe ser null.');
        Assert.isFalse(result.isEmpty(), 'El mapa PDF no debe venir vacío.');
        Assert.areEqual('Sustainability', (String) result.get('name'), 'El nombre del componente debe ser Sustainability.');
        Assert.isTrue(result.containsKey('content'), 'Debe contener la clave content.');

        List<Object> content = (List<Object>) result.get('content');
        Assert.isTrue(content.size() > 0, 'La lista de content debe tener elementos.');
    }

    @isTest
    static void testDMTOpportunitySustainabilityRendererNoData() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        DMT_ViewController.OpportunityProduct oppProduct = new DMT_ViewController.OpportunityProduct();
        oppProduct.name = 'Product Without Sustainability Data';

        data.oppProducts.add(oppProduct);

        Test.startTest();
        DMT_OpportunitySustainabilityRenderer renderer = new DMT_OpportunitySustainabilityRenderer();
        String htmlResult = renderer.renderHtml(data);
        Map<String, Object> pdfResult = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.areEqual(
            '<div>Sustainability data not provided</div>',
            htmlResult,
            'Si no hay datos de sostenibilidad, debe devolver mensaje de no proporcionado.'
        );

        Assert.isTrue(
            pdfResult.isEmpty(),
            'Si no hay datos de sostenibilidad, el PDF JSON debe venir vacío.'
        );
    }

    @isTest
    static void testDMTSustainabilityRendererDelegatesToOpportunityRenderer() {
        Id oppRtId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = oppRtId;

        DMT_ViewController.OpportunityProduct oppProduct = new DMT_ViewController.OpportunityProduct();
        oppProduct.name = 'Delegated Sustainable Product';
        oppProduct.sustainableDealAssessment = '6';
        oppProduct.sustainableDealSubtype = 'Social';
        oppProduct.greenActivityFilter = 'delegated';
        oppProduct.sustainableDealLabel = 'Delegated Label Test';
        oppProduct.sustainablePercentage = '1.12';
        oppProduct.sustainabilityBonusEligible = 'true';

        data.oppProducts.add(oppProduct);

        Test.startTest();
        DMT_SustainabilityRenderer renderer = new DMT_SustainabilityRenderer();
        String htmlResult = renderer.renderHtml(data);
        Map<String, Object> pdfResult = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isNotNull(htmlResult, 'El HTML no debe ser null.');
        Assert.isTrue(htmlResult.contains('Sustainability'), 'Debe pintar Sustainability.');
        Assert.isTrue(htmlResult.contains('Delegated Sustainable Product'), 'Debe pintar el producto delegado.');

        Assert.isNotNull(pdfResult, 'El PDF JSON no debe ser null.');
        Assert.isFalse(pdfResult.isEmpty(), 'El PDF JSON no debe venir vacío.');
        Assert.areEqual('Sustainability', (String) pdfResult.get('name'));
    }

    @isTest
    static void testDMTSustainabilityRendererNullData() {
        DMT_SustainabilityRenderer renderer = new DMT_SustainabilityRenderer();

        Test.startTest();
        String htmlResult = renderer.renderHtml(null);
        Map<String, Object> pdfResult = renderer.renderPdfJson(null);
        Test.stopTest();

        Assert.areEqual(
            '<div>Error: Data not provided</div>',
            htmlResult,
            'HTML debe devolver error cuando data es null.'
        );

        Assert.isTrue(
            pdfResult.isEmpty(),
            'PDF debe devolver mapa vacío cuando data es null.'
        );
    }

    @isTest
    static void testDMTSustainabilityRendererInvalidRecordType() {
        DMT_SustainabilityRenderer renderer = new DMT_SustainabilityRenderer();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;

        Test.startTest();
        String htmlResult = renderer.renderHtml(data);
        Map<String, Object> pdfResult = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.isTrue(
            htmlResult.contains('No Sustainability renderer for record type Id'),
            'HTML debe devolver error cuando no existe renderer para el recordType.'
        );

        Assert.isTrue(
            pdfResult.isEmpty(),
            'PDF debe devolver mapa vacío cuando no existe renderer para el recordType.'
        );
    }

    @isTest
    static void testDMTOppCommercialProcessDataRendererNullAndEmptyOpportunity() {
        DMT_OppCommercialProcessDataRenderer renderer = new DMT_OppCommercialProcessDataRenderer();

        DMT_ViewController.LineDataWrapper emptyData = new DMT_ViewController.LineDataWrapper();
        emptyData.opportunity = new Opportunity();

        Test.startTest();
        String htmlNull = renderer.renderHtml(null);
        Map<String, Object> pdfNull = renderer.renderPdfJson(null);
        String htmlEmptyOpp = renderer.renderHtml(emptyData);
        Map<String, Object> pdfEmptyOpp = renderer.renderPdfJson(emptyData);
        Test.stopTest();

        Assert.areEqual('<div>Error: Opportunity data not provided</div>', htmlNull);
        Assert.isTrue(pdfNull.isEmpty(), 'Con data null debe devolver mapa vacío.');
        Assert.areEqual('<div>Error: Opportunity data not provided</div>', htmlEmptyOpp);
        Assert.isTrue(pdfEmptyOpp.isEmpty(), 'Con opportunity sin campos poblados debe devolver mapa vacío.');
    }

    @isTest
    static void testDMTOppCommercialProcessDataRendererValidOpportunity() {
        DMT_OppCommercialProcessDataRenderer renderer = new DMT_OppCommercialProcessDataRenderer();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Commercial Process Data Test');

        Test.startTest();
        String htmlResult = renderer.renderHtml(data);
        Map<String, Object> pdfResult = renderer.renderPdfJson(data);
        Test.stopTest();

        Assert.areEqual('', htmlResult, 'Para opportunity válida, el HTML esperado actual es string vacío.');
        Assert.isTrue(pdfResult.isEmpty(), 'Para opportunity válida, el JSON esperado actual es mapa vacío.');
    }

    @isTest
    static void testDMTOppCommercialProcessDataRendererRenderHtmlCatchBlock() {
        DMT_OppCommercialProcessDataRenderer renderer = new DMT_OppCommercialProcessDataRenderer();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Commercial Process Catch HTML');
        data.forceException = true;

        Test.startTest();
        String htmlResult = renderer.renderHtml(data);
        Test.stopTest();

        Assert.isTrue(htmlResult.contains('Error:'), 'Debe entrar en catch y devolver Error en HTML.');
    }

    @isTest
    static void testDMTOppCommercialProcessDataRendererRenderPdfJsonCatchBlock() {
        DMT_OppCommercialProcessDataRenderer renderer = new DMT_OppCommercialProcessDataRenderer();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Commercial Process Catch PDF');
        data.forceException = true;

        Integer queueableJobs;
        Map<String, Object> pdfResult;

        Test.startTest();
        pdfResult = renderer.renderPdfJson(data);
        queueableJobs = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.isTrue(pdfResult.isEmpty(), 'Debe entrar en catch y devolver mapa vacío en PDF.');
        Assert.areEqual(1, queueableJobs, 'Debe encolar un queueable al entrar en catch de PDF.');
    }

    // ==========================================
    // PROFITABILITY DELEGATOR TESTS
    // ==========================================

    @isTest
    static void testNullDataToDelegatorsDMTProfitabilityRenderers() {
        Test.startTest();
        
        DMT_ProfitabilityRenderer baseRenderer = new DMT_ProfitabilityRenderer();
        Assert.isTrue(baseRenderer.renderHtml(null).contains('Error'), 'Profitability HTML should return Error.');
        Assert.isTrue(baseRenderer.renderPdfJson(null).isEmpty(), 'Profitability PDF should be empty.');

        DMT_ProfitabilitySummariesRenderer sumRenderer = new DMT_ProfitabilitySummariesRenderer();
        Assert.isTrue(sumRenderer.renderHtml(null).contains('Error'), 'Summaries HTML should return Error.');
        Assert.isTrue(sumRenderer.renderPdfJson(null).isEmpty(), 'Summaries PDF should be empty.');

        DMT_ProfitabilityVisualRenderer visRenderer = new DMT_ProfitabilityVisualRenderer();
        Assert.isTrue(visRenderer.renderHtml(null).contains('Error'), 'Visual HTML should return Error.');
        Assert.isTrue(visRenderer.renderPdfJson(null).isEmpty(), 'Visual PDF should be empty.');
        
        Test.stopTest();
    }

    @isTest
    static void testInvalidRecordIdDMTProfitabilityRenderers() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = '012000000000000'; // Invalid ID

        Test.startTest();
        
        DMT_ProfitabilityRenderer baseRenderer = new DMT_ProfitabilityRenderer();
        Assert.isTrue(baseRenderer.renderHtml(data).contains('Error'), 'Profitability HTML should catch invalid recordType.');
        Assert.isTrue(baseRenderer.renderPdfJson(data).isEmpty(), 'Profitability PDF should catch invalid recordType.');

        DMT_ProfitabilitySummariesRenderer sumRenderer = new DMT_ProfitabilitySummariesRenderer();
        Assert.isTrue(sumRenderer.renderHtml(data).contains('Error'), 'Summaries HTML should catch invalid recordType.');
        Assert.isTrue(sumRenderer.renderPdfJson(data).isEmpty(), 'Summaries PDF should catch invalid recordType.');

        DMT_ProfitabilityVisualRenderer visRenderer = new DMT_ProfitabilityVisualRenderer();
        Assert.isTrue(visRenderer.renderHtml(data).contains('Error'), 'Visual HTML should catch invalid recordType.');
        Assert.isTrue(visRenderer.renderPdfJson(data).isEmpty(), 'Visual PDF should catch invalid recordType.');
        
        Test.stopTest();
    }

    @isTest
    static void testDMTOppProfitabilityVisualRendererGuardsAndExceptions() {
        DMT_OppProfitabilityLimitVisualRenderer renderer = new DMT_OppProfitabilityLimitVisualRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        Test.startTest();

        // 1. Guard: Features data not provided (null/empty)
        // Call static method via Class name, instance method via Instance
        String html1 = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Map<String, Object> pdf1 = renderer.renderPdfJson(data);
        Assert.isTrue(html1.contains('Features data not provided'), 'Guard 1 HTML failed.');
        Assert.isTrue(pdf1.isEmpty(), 'Guard 1 PDF failed.');

        // 2. Guard: Opportunity or OpportunityLineItems data not provided
        data.featuresList = new List<Map<String, Object>>{ new Map<String, Object>{ 'dummy' => 'value' } };
        data.opportunity = new Opportunity(); // Empty Opp
        
        String html2 = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Map<String, Object> pdf2 = renderer.renderPdfJson(data);
        Assert.isTrue(html2.contains('Opportunity or OpportunityLineItems data not provided'), 'Guard 2 HTML failed.');
        Assert.isTrue(pdf2.isEmpty(), 'Guard 2 PDF failed.');

        // 3. Guard: Profitability data not provided
        data.opportunity = (Opportunity)JSON.deserialize(
            '{"attributes":{"type":"Opportunity"},"Name":"Test Opp","OpportunityLineItems":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"OpportunityLineItem"},"Id":"00k000000000000"}]}}', 
            Opportunity.class
        );
        
        String html3 = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Map<String, Object> pdf3 = renderer.renderPdfJson(data);
        Assert.isTrue(html3.contains('Profitability data not provided'), 'Guard 3 HTML failed.');
        Assert.isTrue(pdf3.isEmpty(), 'Guard 3 PDF failed.');

        // 4. Guard: No Profitability results found
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'profitability' => new Map<String, Object>{
                    'results' => new List<Object>()
                }
            }
        };
        
        String html4 = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Map<String, Object> pdf4 = renderer.renderPdfJson(data);
        Assert.isTrue(html4.contains('no Profitability results found'), 'Guard 4 HTML failed.');
        Assert.isTrue(pdf4.isEmpty(), 'Guard 4 PDF failed.');

        // 5. Exception Catch Blocks
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'profitability' => new Map<String, Object>{
                    'results' => new List<Object>{ new Map<String, Object>{ 'productId' => '00k000000000000' } }
                }
            }
        };
        data.forceException = true;
        
        String htmlCatch = DMT_OppProfitabilityLimitVisualRenderer.renderHtml(data);
        Map<String, Object> pdfCatch = renderer.renderPdfJson(data);
        
        Assert.isTrue(htmlCatch.contains('Error:'), 'HTML Catch block failed.');
        Assert.isTrue(pdfCatch.isEmpty() || !pdfCatch.containsKey('content'), 'PDF Catch block failed.');

        Test.stopTest();
    }

    // ==========================================
    // STATUS DELEGATOR AND DEFAULT RENDERER TESTS
    // ==========================================

    @isTest
    static void testNullDataToDelegatorsDMTStatusOnlyRenderer(){
        DMT_StatusOnlyRenderer renderer = new DMT_StatusOnlyRenderer();
        Test.startTest();
        String resultHtml = renderer.renderHtml(null);
        Map<String, Object> resultPdfJson = renderer.renderPdfJson(null);
        Test.stopTest();
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        Assert.isTrue(resultPdfJson.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testInvalidRecordIdDMTStatusOnlyRenderer(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_StatusOnlyRenderer renderer = new DMT_StatusOnlyRenderer();
        String resultHtml = renderer.renderHtml(data);
        Map<String, Object> resultPdf = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(resultHtml.contains('Error'), 'response should contain Error.');
        Assert.isTrue(resultPdf.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testDefaultStatusOnlyRendererRenderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.statusLineOrOpp = 'Active';
        Test.startTest();
        DMT_DefaultStatusOnlyRenderer renderer = new DMT_DefaultStatusOnlyRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isNotNull(result);
        Assert.isTrue(result.contains('STATUS'), 'HTML should contain the STATUS title.');
        Assert.isTrue(result.contains('Active'), 'HTML should contain the status value.');
        Assert.isFalse(result.contains('Error'), 'HTML should not contain an error.');
    }

    @isTest
    static void testDefaultStatusOnlyRendererRenderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.statusLineOrOpp = 'Active';
        Test.startTest();
        DMT_DefaultStatusOnlyRenderer renderer = new DMT_DefaultStatusOnlyRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isNotNull(result);
        Assert.isFalse(result.isEmpty(), 'PDF Map should not be empty.');
        Assert.areEqual('STATUS', (String) result.get('name'), 'PDF should have STATUS as component name.');
    }

    @isTest
    static void testDefaultStatusOnlyRendererRenderHtml_CatchBlock(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.forceException = true;
        Test.startTest();
        DMT_DefaultStatusOnlyRenderer renderer = new DMT_DefaultStatusOnlyRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error:'), 'Should enter catch block and return Error in HTML.');
    }

    @isTest
    static void testDefaultStatusOnlyRendererRenderPdfJson_CatchBlock(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.forceException = true;
        Integer queueableJobs;
        Map<String, Object> result;
        Test.startTest();
        DMT_DefaultStatusOnlyRenderer renderer = new DMT_DefaultStatusOnlyRenderer();
        result = renderer.renderPdfJson(data);
        queueableJobs = Limits.getQueueableJobs();
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'Should enter catch block and return empty Map.');
        Assert.areEqual(1, queueableJobs, 'Should enqueue a queueable on catch.');
    }
}