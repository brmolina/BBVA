@isTest(seeAllData=false)
public class DMT_ViewController_Test {

    @TestSetup
    static void makeData(){
		DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
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
        DMT_Items__c testItem9 = new DMT_Items__c(DMT_Component_Item__c = 'Approval Process', DMT_order_display__c = 9, DMT_View__c = testView.Id);
        DMT_Items__c testItem10 = new DMT_Items__c(DMT_Component_Item__c = 'Validation Process', DMT_order_display__c = 10, DMT_View__c = testView.Id);
        insert new List<DMT_Items__c>{testItem1, testItem2, testItem3, testItem4, testItem5, testItem6, testItem7, testItem8};

        // Create Account
        Account testAccount = new Account(Name = 'Test Account');
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
        insert testTreasuryLine;

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
            gf_customer_group_id__c = 'ESCD25LIN00000978ES'
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
            Alpha_Code_Client__c = 'ES0000000000001'

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

        DMT_Opportunity_Tenor__c tenor = DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
        DMT_Opportunity_Mitigant__c mitigant = DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
        DMT_X_Sell__c xSell = DMT_Test_DataFactory.generatexSell(opp);
        DMT_Opportunity_Client__c oppClient = DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
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
        Passport__c retrievedPassport = [SELECT Id, DMT_Passport_Save__c, DMT_Line__c FROM Passport__c WHERE DMT_Line__c = :testLine.Id];

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
    static void testGeneratePDFContentDocument() {
        TriggerBypass.setBypass();
        Group testGroup;

        // ---------------------------------------------------------
        // 1. CREATE QUEUE & QueueSobject INSIDE runAs() → Avoid MIXED DML
        // ---------------------------------------------------------
        System.runAs(new User(Id = UserInfo.getUserId())) {

            // Create Queue
            testGroup = new Group( Name = 'UnitTestQueue', DeveloperName = 'UnitTestQueue', Type = 'Queue');
            insert testGroup;

            // Support Task
            insert new QueueSobject(QueueId = testGroup.Id, SobjectType = 'Task');

            // Support Case (optional but safe)
            insert new QueueSobject(QueueId = testGroup.Id, SobjectType = 'Case');
        }

        // MUST re-query after runAs (different execution context)
        testGroup = [SELECT Id, Name, DeveloperName, Type FROM Group WHERE DeveloperName = 'UnitTestQueue'LIMIT 1];

        System.debug('Queue created: ' + testGroup);
        // ---------------------------------------------------------
        // 2. NORMAL DML (NO MIXED DML ANYMORE)
        // ---------------------------------------------------------
        Case testCase = [SELECT Id, OwnerId FROM Case WHERE Subject = 'Test Case'LIMIT 1];
        testCase.OwnerId = testGroup.Id;
        update testCase;

        DMT_ApproversView__c testApproversView = [SELECT Id, Name, DMT_DeveloperName__c, DMT_Type__c FROM DMT_ApproversView__c LIMIT 1];
        DMT_Approver__c testApprover = [SELECT Id, DMT_Group__c,Approvers_View__c,Approvers_View_Treasury__c,Approvers_View_Opportunity__c
                                        FROM DMT_Approver__c WHERE DMT_Approver_Code__c = '123' LIMIT 1];

        testApprover.Approvers_View_Treasury__c = testApproversView.Id;
        testApprover.DMT_Group__c = testGroup.DeveloperName;
        update testApprover;

        Task testTask1 = [SELECT Id, OwnerId FROM Task WHERE WhatId = :testCase.Id AND Subject = 'Test Task 1'LIMIT 1];

        // Now valid because QueueSobject(Task) exists
        testTask1.OwnerId = testGroup.Id;
        update testTask1;
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'img64Mock'LIMIT 1];
        String img64 = sr.Body.toString();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        String createDocHtml = '';

        DMT_ViewController.generateContentDocumentForView(testCase.Id, testTask1.Id,'JSON','');

        Test.startTest();

        try {
            createDocHtml = DMT_ViewController.generateContentDocumentForView(testCase.Id, testTask1.Id,'HTML',img64);
        } catch (System.VisualforceException e) {
            System.debug('Handled VisualforceException: ' + e.getMessage());
        } catch (DmlException e) {
            System.debug('DmlException during ContentVersion insert: ' + e.getMessage());
        }

        Test.stopTest();

        Assert.areEqual('Success document creation', createDocHtml);

        String typeHTML = DMT_ViewController.fileTypeDocument(testTask1.Id);
        Assert.areEqual('HTML', typeHTML);

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testLoadHtmlFromSelectedItems_treasury() {
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
        DMT_ViewController controller = new DMT_ViewController();
        String TreasuryLineId = testTreasuryLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line_Treasury';
        String recordTypeDeveloperName = 'TreasurySettlement';
        String htmlContent = DMT_ViewController.loadComponentsForView(TreasuryLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(TreasuryLineId, type, items);
        String jsonDataFeatureLine2 = DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id);
        String jsonDataFeatureLine = DMT_ViewController.getFeaturesForJsonPdf(TreasuryLineId, '');
        String jsonDataFeatureLine3 = DMT_ViewController.getFeaturesForJsonPdf('', '');

        testCase.DMT_Line__c = null;
        update testCase;
        String jsonDataFeatureLine4 = DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id);
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');

        TriggerBypass.removeBypass();
    }

   @isTest
    static void testLoadHtmlFromSelectedItemsOpportunity_treasury() {
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
        String recordTypeDeveloperName = 'TreasurySettlement';
        String htmlContent = DMT_ViewController.loadComponentsForView(TreasuryOppId, type, items, '', itemsImg);
        String jsonDataFeatureOpp = DMT_ViewController.getFeaturesForJsonPdf(TreasuryOppId, testCaseOpp.Id);
        String jsonDataFeatureOpp1 = DMT_ViewController.getFeaturesForJsonPdf(TreasuryOppId, '');

        delete [SELECT Id FROM Passport__c WHERE Opportunity__c = :testOpp.Id];
        String jsonDataFeatureOpp2 = DMT_ViewController.getFeaturesForJsonPdf(TreasuryOppId, testCaseOpp.Id);
        insert new Passport__c(
            Opportunity__c = testOpp.Id,
            DMT_Passport_Save__c = '{"data":{"features":[{"validations":[{"message":"Opportunity Internal Rating is consistent with Client Internal Rating.","name":"Rating is consistent","state":"GREEN"},{"message":"Opportunity Client Type is not consistent with Client Type.","name":"Client Type is inconsistent","state":"RED"},{"message":"All Cross SELL records have a Year within 5 years from the Opportunity Initial Date.","name":"Cross SELL Year is consistent","state":"GREEN"},{"message":"Consistent Payment Date detected in Tenors for product type User-Defined","name":"Tenors Payment Date is consistent","state":"GREEN"},{"message":"Opportunity Maturity Date is consistent with Opportunity Products Maturity Dates","name":"Maturity Date consistency","state":"GREEN"},{"message":"Opportunity Initial Date is consistent with Opportunity Products Initial Dates","name":"Initial Date consistency","state":"GREEN"},{"message":"Opportunity Notional Amount is consistent with Opportunity Products Notional Amounts Sum","name":"Notional Amount consistency","state":"GREEN"}],"stateName":"RED","motorDesc":"Salesforce","active":"Y","passportSanction":"passport","name":"General Validations","id":"200"},{"tasks":[{"approvers":[{"documentManagerEnable":"Y","branch":"HO","entific":"HO","name":"GRM C&IB - FI - Insurance & CCPs","id":"15"}],"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - Local","id":"6"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - Local","id":"6"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - local and global","id":"8"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - on behalf of the geography committee","id":"9"}],"stateName":"WHITE","orderNumber":199,"active":"Y","passportSanction":"readytoclose","name":"OP14 - Business Approval (Test Opp)","id":"921"},{"tasks":[{"approvers":[{"documentManagerEnable":"Y","branch":"HO","entific":"HO","name":"GRM C&IB - FI - Insurance & CCPs","id":"15"}],"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - Local","id":"6"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - Local","id":"6"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - local and global","id":"8"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Dismissed","yesFlag":"Approved","name":"Risk Approval - on behalf of the geography committee","id":"9"}],"stateName":"WHITE","orderNumber":201,"active":"Y","passportSanction":"approval","name":"OP14 - OPTIONAL  (Test Opp)","id":"981"},{"profitability":{"results":[{"feesFbPbs":0.0,"feesFb":0.0,"feesDbPbs":0.0,"feesDb":0.0,"feesOtherPbs":0.0,"feesOther":0.0,"totalYears":[{"raroecYearly":0.6503158976014631,"rorcYearly":0.42137377415204125,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2025},{"raroecYearly":15.391796323909647,"rorcYearly":9.957474131727261,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2026},{"raroecYearly":0.6974261835141751,"rorcYearly":0.45255035112554143,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2027}],"rorcProspected":0.0,"rorcNoxsell":0.0,"rorc":0.45255035112554143,"raroecProspected":0.0,"raroecNoxsell":1.4633159024753015,"raroec":0.6974261835141751,"prospectedRegulatoryCapital":0.0,"prospectedEconomicCapital":0.0,"prospectedBdi":0.0,"regulatoryCapital":2164.519610144561,"economicCapital":1404.527292986458,"regulatoryApr":2.1595664581674945,"economicApr":1.8788152752907068,"allInFb":0.0,"allInDb":0.0,"bdi":979.554109589041,"periodicFeesPbs":0.0,"feesUpFrontPbs":0.0,"expectedLossPbs":0.0,"countryRiskProvisionFbPbs":0.0,"countryRiskProvisionDbPbs":0.0,"bonificationFunding":0.0,"fundingDbPbs":11.602739726027393,"fundingFbPbs":2.1095890410958904,"spreadFbPbs":34.80821917808218,"spreadDbPbs":104.42465753424656,"averageLife":1.0547945205479454,"regulatoryEad":180000.0,"economicEad":200000.0,"taxRate":30.0,"regulatoryLgd":40.0,"economicLgd":40.0,"regulatoryCcf":40.0,"economicCcf":50.0,"productId":"00kKG0000037yjjYAA"},{"feesFbPbs":0.0,"feesFb":0.0,"feesDbPbs":0.0,"feesDb":0.0,"feesOtherPbs":0.0,"feesOther":0.0,"totalYears":[{"raroecYearly":0.6503158976014631,"rorcYearly":0.42137377415204125,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2025},{"raroecYearly":15.391796323909647,"rorcYearly":9.957474131727261,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2026},{"raroecYearly":0.6974261835141751,"rorcYearly":0.45255035112554143,"eadRegYearly":180000.0,"eadEcoYearly":180000.0,"year":2027}],"rorcProspected":0.0,"rorcNoxsell":0.0,"rorc":0.45255035112554143,"raroecProspected":0.0,"raroecNoxsell":1.4633159024753015,"raroec":0.6974261835141751,"prospectedRegulatoryCapital":0.0,"prospectedEconomicCapital":0.0,"prospectedBdi":0.0,"regulatoryCapital":2164.519610144561,"economicCapital":1404.527292986458,"regulatoryApr":2.1595664581674945,"economicApr":1.8788152752907068,"allInFb":0.0,"allInDb":0.0,"bdi":979.554109589041,"periodicFeesPbs":0.0,"feesUpFrontPbs":0.0,"expectedLossPbs":0.0,"countryRiskProvisionFbPbs":0.0,"countryRiskProvisionDbPbs":0.0,"bonificationFunding":0.0,"fundingDbPbs":11.602739726027393,"fundingFbPbs":2.1095890410958904,"spreadFbPbs":34.80821917808218,"spreadDbPbs":104.42465753424656,"averageLife":1.0547945205479454,"regulatoryEad":180000.0,"economicEad":200000.0,"taxRate":30.0,"regulatoryLgd":40.0,"economicLgd":40.0,"regulatoryCcf":40.0,"economicCcf":50.0}],"audit":{"isError":false,"engineVersion":"0.7"}},"stateName":"GREEN","orderNumber":401,"motorDesc":"Profitability Engine","active":"Y","passportSanction":"passport","name":"Profitability Engine","id":"441"},{"stateName":"GRAY","motorDesc":"Limit Engine","active":"Y","passportSanction":"passport","name":"OPP03 -  Limit Test (Group Level)","id":"881"},{"tasks":[{"approvers":[{"documentManagerEnable":"Y","branch":"HO","entific":"HO","name":"GRM C&IB - FI - Insurance & CCPs","id":"15"}],"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Not in accordance","yesFlag":"In accordance","name":"Risk Analyst Advisory","id":"2"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Not in accordance","yesFlag":"In accordance","name":"Risk Analyst Advisory","id":"2"}],"stateName":"GRAY","motorDesc":"Limit Engine","active":"Y","passportSanction":"passport","name":"OPPM02 - Mitigant Limit Test (Client Level)","id":"901"},{"tasks":[{"approvers":[{"documentManagerEnable":"Y","branch":"HO","entific":"HO","name":"GRM C&IB - FI - Insurance & CCPs","id":"15"}],"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Not in accordance","yesFlag":"In accordance","name":"Risk Analyst Advisory","id":"2"},{"status":"OPEN","nextTask":"1","naFlag":"N/A","noFlag":"Not in accordance","yesFlag":"In accordance","name":"Risk Analyst Advisory","id":"2"}],"stateName":"GRAY","motorDesc":"Limit Engine","active":"Y","passportSanction":"passport","name":"OPPM03 - Mitigant Limit Test (Group Level)","id":"961"},{"validations":[{"message":"products.funding.fundingTerm, products.amortization.payments.feesPeriodic","name":"capabilityMandatoryParametersMissing","state":"RED"}],"active":"Y","passportSanction":"passport","name":"PRUEBASGAV0901","id":"721"}],"currencyCode":"EUR"}}'
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
    static void testLoadHtmlFromSelectedItems_treasury_colombia() {
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
        String TreasuryLineId = testTreasuryLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line_Treasury';
        String recordTypeDeveloperName = 'TreasurySettlement';
        String htmlContent = DMT_ViewController.loadComponentsForView(TreasuryLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(TreasuryLineId, type, items);
        String jsonDataFeatureLine2 = DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id );
        String jsonDataFeatureLine = DMT_ViewController.getFeaturesForJsonPdf(TreasuryLineId, '');
        String jsonDataFeatureLine3 = DMT_ViewController.getFeaturesForJsonPdf('', '');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');

        TriggerBypass.removeBypass();
    }
    @isTest
    static void testLoadHtmlFromSelectedItems_treasury_PE() {
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
        String TreasuryLineId = testTreasuryLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line_Treasury';
        String recordTypeDeveloperName = 'TreasurySettlement';
        String htmlContent = DMT_ViewController.loadComponentsForView(TreasuryLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(TreasuryLineId, type, items);
        String jsonDataFeatureLine2 = DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id );
        String jsonDataFeatureLine = DMT_ViewController.getFeaturesForJsonPdf(TreasuryLineId, '');
        String jsonDataFeatureLine3 = DMT_ViewController.getFeaturesForJsonPdf('', '');
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testLoadHtmlFromSelectedItems_other() {
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
        String OtherLineId = testOtherLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line';
        String recordTypeDeveloperName = 'OtherProducts';

        String htmlContent = DMT_ViewController.loadComponentsForView(OtherLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(OtherLineId, type, items);
        String jsonDataFeatureLine = DMT_ViewController.getFeaturesForJsonPdf(OtherLineId, '');
        String jsonDataFeatureLine2 = DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id);
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testLoadHtmlFromSelectedItems_other_multiholder() {

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
        String OtherLineId = testOtherLine.Id;
        String items = JSON.serialize(selectedItems);
        String itemsImg = img64;
        String type = 'Line';
        String recordTypeDeveloperName = 'OtherProducts';

        String htmlContent = DMT_ViewController.loadComponentsForView(OtherLineId, type, items, '', itemsImg);
        String pdfJsonContentApex = DMT_ViewController.loadJSONFromSelectedItems(OtherLineId, type, items);
        String jsonDataFeatureLine = DMT_ViewController.getFeaturesForJsonPdf(OtherLineId, '');
        String jsonDataFeatureLine2 = DMT_ViewController.getFeaturesForJsonPdf('', testCase.Id);
        Test.stopTest();

        // Validaciones
        Assert.isNotNull(htmlContent, 'El HTML generado no debe ser nulo.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testLoadComponentsForView_nullData() {

        // Prepare selected items
        List<DMT_ViewController.ItemWrapper> selectedItems = prepareItemWrapper();

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // Simulación del controlador
        Test.startTest();
        DMT_ViewController controller = new DMT_ViewController();
        String items = JSON.serialize(selectedItems);
        String type = 'Opportunity';
        String recordTypeDeveloperName = 'DMT_Opportunity';

        String response = DMT_ViewController.loadComponentsForView('', type, items, '', '');
        Test.stopTest();

        // Validaciones
        Assert.isTrue(response.contains('Error'), 'response should contain Error.');
    }

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
    static void testGetItemsToDisplayNoRecordId(){
        String itemsToDisplay;
        try{
            itemsToDisplay = DMT_ViewController.getItemsToDisplay('', 'Case');
        } catch (Exception e){
            Assert.isTrue(true, 'An exception should have been thrown for no recordId');
        }
        Assert.isNull(itemsToDisplay, 'itemsToDisplay should be null');
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
    static void testNullDataToDelegators_DMT_ApprovalProcessDataRenderer(){
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
    static void testInvalidRecordId_DMT_ApprovalProcessDataRenderer_renderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ApprovalProcessDataRenderer renderer = new DMT_ApprovalProcessDataRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }
    @isTest
    static void testInvalidRecordId_DMT_ApprovalProcessDataRenderer_renderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ApprovalProcessDataRenderer renderer = new DMT_ApprovalProcessDataRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegators_DMT_ClientRenderer(){
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
    static void testInvalidRecordId_DMT_ClientRenderer_renderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ClientRenderer renderer = new DMT_ClientRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordId_DMT_ClientRenderer_renderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ClientRenderer renderer = new DMT_ClientRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegators_DMT_ParticipantRenderer(){
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
    static void testInvalidRecordId_DMT_ParticipantRenderer_renderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ParticipantRenderer renderer = new DMT_ParticipantRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordId_DMT_ParticipantRenderer_renderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ParticipantRenderer renderer = new DMT_ParticipantRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegators_DMT_PassportRenderer(){
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
    static void testInvalidRecordId_DMT_PassportRenderer_renderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_PassportRenderer renderer = new DMT_PassportRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordId_DMT_PassportRenderer_renderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_PassportRenderer renderer = new DMT_PassportRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegators_DMT_LimitVisualRenderer(){
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
    static void testInvalidRecordId_DMT_LimitVisualRenderer_renderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_LimitVisualRenderer renderer = new DMT_LimitVisualRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordId_DMT_LimitVisualRenderer_renderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_LimitVisualRenderer renderer = new DMT_LimitVisualRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegators_DMT_InfoRenderer(){
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
    static void testInvalidRecordId_DMT_InfoRenderer_renderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_InfoRenderer renderer = new DMT_InfoRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordId_DMT_InfoRenderer_renderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_InfoRenderer renderer = new DMT_InfoRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegators_DMT_LimitRenderer(){
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
    static void testInvalidRecordId_DMT_LimitRenderer_renderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_LimitRenderer renderer = new DMT_LimitRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordId_DMT_LimitRenderer_renderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_LimitRenderer renderer = new DMT_LimitRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testNullDataToDelegators_DMT_CommercialProcessDataRenderer(){
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
    static void testInvalidRecordId_DMT_CommercialProcessDataRenderer_renderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_CommercialProcessDataRenderer renderer = new DMT_CommercialProcessDataRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordId_DMT_CommercialProcessDataRenderer_renderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_CommercialProcessDataRenderer renderer = new DMT_CommercialProcessDataRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testInvalidRecordId_DMT_PassportProcessFlowRenderer_renderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_PassportProcessFlowRenderer renderer = new DMT_PassportProcessFlowRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordId_DMT_PassportProcessFlowRendere_renderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_PassportProcessFlowRenderer renderer = new DMT_PassportProcessFlowRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }

    @isTest
    static void testInvalidRecordId_DMT_ApprovalProcessFlowRendere_renderHtml(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ApprovalProcessFlowRenderer renderer = new DMT_ApprovalProcessFlowRenderer();
        String result = renderer.renderHtml(data);
        Test.stopTest();
        Assert.isTrue(result.contains('Error'), 'response should contain Error.');
    }

    @isTest
    static void testInvalidRecordId_DMT_ApprovalProcessFlowRendere_renderPdfJson(){
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        Test.startTest();
        DMT_ApprovalProcessFlowRenderer renderer = new DMT_ApprovalProcessFlowRenderer();
        Map<String, Object> result = renderer.renderPdfJson(data);
        Test.stopTest();
        Assert.isTrue(result.isEmpty(), 'response should be an empty Map.');
    }
    public static List<DMT_ViewController.ItemWrapper> prepareItemWrapper(){

        return new List<DMT_ViewController.ItemWrapper>{
            new DMT_ViewController.ItemWrapper('Component', 'Line Info',  1, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Client',  2, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Products',  3, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Participants',  4, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Approval Process Data',  5, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Passport',  6, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Limit',  7, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Limit Visual',  8, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Approval Process',  14, ''),
            new DMT_ViewController.ItemWrapper('Component', 'Validation Process',  15, ''),
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
}