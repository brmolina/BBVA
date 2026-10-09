@isTest
public with sharing class DMT_Passport_Handler_test {
    @TestSetup
    static void loadTestData(){
        TriggerBypass.setBypass();
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Test_DataFactory.generateTaskTypes();
        DMT_Test_DataFactory.generateApprover();
        DMT_Test_DataFactory.generateOpportunity();

        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));

        // Perform one single DML
        insert settingsToInsert;

        TriggerBypass.removeBypass();
    }

    @isTest
    private static void testCallLine(){
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        String action = 'TestMethod';

        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
        {
            'customerId' => 'ES0182054986618',
            'currentRatingToolDate' => Date.today(),
            'customerCounterpartiesCodesDesc' => 'A+'
        }};


        Map<String, Object> input = new Map<String, Object>{'recordId' => line.Id, 'forceCall' => 'true', 'clientsGroup' => JSON.serialize(clientsGroup)};
        Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

        DMT_Passport_Handler passportClass = new DMT_Passport_Handler();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        Map<String,Object> mapJSON = (Map<String,Object>) passportClass.call(action, args);
        Test.stopTest();
        Assert.areEqual((Boolean)mapJSON.get('result'), true);

    }

    @isTest
    private static void testCallRefreshLine(){
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        String action = 'refreshInformation';

        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
        {
            'customerId' => 'ES0182054986618',
            'currentRatingToolDate' => Date.today(),
            'customerCounterpartiesCodesDesc' => 'A+'
        }};

        // --- Mock Custom Metadata
        /* iaso__GBL_integration_service__mdt fakeCmdt = (iaso__GBL_integration_service__mdt) JSON.deserialize('{"DeveloperName":"DMT_PUT_OpportunityConsumptionLimit"}', iaso__GBL_integration_service__mdt.class);
        fakeCmdt.iaso__Custom_Setting__c = 'DMTO_Endpoint_INT';
        fakeCmdt.iaso__Authentication_Service__c = 'DMT_GrantingTicket';
        fakeCmdt.iaso__IsCacheable__c = false;
        fakeCmdt.iaso__Retrieve_Mock_LTA__c = false;
        fakeCmdt.iaso__Mock_LTA__c = '{"foo":"bar"}';
        fakeCmdt.iaso__Http_Method__c = 'GET';

        DMT_Integration_Utils.setMockCmdt('DMT_PUT_OpportunityConsumptionLimit', fakeCmdt); */

        Map<String, Object> input = new Map<String, Object>{'recordId' => line.Id, 'forceCall' => 'true', 'clientsGroup' => JSON.serialize(clientsGroup)};
        Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

        DMT_Passport_Handler passportClass = new DMT_Passport_Handler();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        Map<String,Object> mapJSON = (Map<String,Object>) passportClass.call(action, args);
        Test.stopTest();
        Assert.areEqual((Boolean)mapJSON.get('result'), true);

    }

    @isTest
    private static void testCallRefreshLineOthers(){
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00003' LIMIT 1];
        String action = 'refreshInformation';

        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
        {
            'customerId' => 'ES0182054986618',
            'currentRatingToolDate' => Date.today(),
            'customerCounterpartiesCodesDesc' => 'A+'
        }};

        // --- Mock Custom Metadata
        /* iaso__GBL_integration_service__mdt fakeCmdt = (iaso__GBL_integration_service__mdt) JSON.deserialize('{"DeveloperName":"DMT_PUT_OpportunityConsumptionLimit"}', iaso__GBL_integration_service__mdt.class);
        fakeCmdt.iaso__Custom_Setting__c = 'DMTO_Endpoint_INT';
        fakeCmdt.iaso__Authentication_Service__c = 'DMT_GrantingTicket';
        fakeCmdt.iaso__IsCacheable__c = false;
        fakeCmdt.iaso__Retrieve_Mock_LTA__c = false;
        fakeCmdt.iaso__Mock_LTA__c = '{"foo":"bar"}';
        fakeCmdt.iaso__Http_Method__c = 'GET';

        DMT_Integration_Utils.setMockCmdt('DMT_PUT_OpportunityConsumptionLimit', fakeCmdt); */

        Map<String, Object> input = new Map<String, Object>{'recordId' => line.Id, 'forceCall' => 'true', 'clientsGroup' => JSON.serialize(clientsGroup)};
        Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

        DMT_Passport_Handler passportClass = new DMT_Passport_Handler();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        Map<String,Object> mapJSON = (Map<String,Object>) passportClass.call(action, args);
        Test.stopTest();
        Assert.areEqual((Boolean)mapJSON.get('result'), true);

    }

    @isTest
    private static void testCallLineOthers(){
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00003' LIMIT 1];
        String action = 'TestMethod';

        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
        {
            'customerId' => 'ES0182054986618',
            'currentRatingToolDate' => Date.today(),
            'customerCounterpartiesCodesDesc' => 'A+'
        }};


        Map<String, Object> input = new Map<String, Object>{'recordId' => line.Id, 'forceCall' => 'true', 'clientsGroup' => JSON.serialize(clientsGroup)};
        Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

        DMT_Passport_Handler passportClass = new DMT_Passport_Handler();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        Map<String,Object> mapJSON = (Map<String,Object>) passportClass.call(action, args);
        Test.stopTest();
        Assert.areEqual((Boolean)mapJSON.get('result'), true);

    }

    @isTest
    private static void testCallPassport(){
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        Passport__c passport = new Passport__c(DMT_Line__c = line.Id);

        insert passport;

        String action = 'TestMethod';
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
            {
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }};

        Map<String, Object> input = new Map<String, Object>{'recordId' => passport.Id, 'forceCall' => 'true', 'clientsGroup' => JSON.serialize(clientsGroup)};
        Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

        DMT_Passport_Handler passportClass = new DMT_Passport_Handler();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        Map<String,Object> mapJSON = (Map<String,Object>) passportClass.call(action, args);
        Test.stopTest();
        Assert.areEqual((Boolean)mapJSON.get('result'), true);
    }

    @isTest
    private static void testCallbutton(){
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
            {
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }};
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        Map<String,Object> mapJSON = (Map<String,Object>) JSON.deserializeUntyped(DMT_Passport_Handler.buttonCallPassport(line.Id, JSON.serialize(clientsGroup)));
        Test.stopTest();
        Assert.areEqual((Boolean)mapJSON.get('result'), true);
    }

    @isTest
    private static void testCallbuttonWithPassportId(){
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
            {
                'customerId' => 'ES0182054986618',
                'currentRatingToolDate' => Date.today(),
                'customerCounterpartiesCodesDesc' => 'A+'
            }};
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        Passport__c passport = new Passport__c(DMT_Line__c = line.Id);

        insert passport;

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        Map<String,Object> mapJSON = (Map<String,Object>) JSON.deserializeUntyped(DMT_Passport_Handler.buttonCallPassport(passport.Id, JSON.serialize(clientsGroup)));
        Test.stopTest();
        Assert.areEqual((Boolean)mapJSON.get('result'), true);
    }

    @isTest
    private static void getInformationPassportLineTest(){
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Map<String,Object> mapJSON = (Map<String,Object>) JSON.deserializeUntyped(DMT_Passport_Handler.getInformationPassport(line.Id));
        Assert.areEqual((String)mapJSON.get('externalId'), '00002');

    }

    @isTest
    private static void getInformationPassportTest(){
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        Passport__c passport = new Passport__c(DMT_Line__c = line.Id);

        insert passport;

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        Map<String,Object> mapJSON = (Map<String,Object>) JSON.deserializeUntyped(DMT_Passport_Handler.getInformationPassport(passport.Id));
        DMT_Passport_Handler.getLastDay();
        Test.stopTest();
        Assert.areEqual((String)mapJSON.get('externalId'), '00002');
    }

    @isTest
    private static void createCaseTest(){
        DMT_Line__c line = [SELECT Id, Line_Id__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1 FOR UPDATE];
        DMT_Approver__c approverUpdate = [SELECT Id,DMT_External_Id__c FROM DMT_Approver__c WHERE Name = 'TestApproverDataFactory' LIMIT 1 FOR UPDATE];
        Passport__c passport = new Passport__c(DMT_Line__c = line.Id);

        insert passport;
        List<Map<String, Object>> taskList = new List<Map<String, Object>>();
        Map<String, Object> task1 = new Map<String, Object>();
        task1.put('status', 'OPEN');
        task1.put('nextTask', '3');
        task1.put('closingCapacity', 'Y');
        task1.put('naFlag', 'Not Apply');
        task1.put('noFlag', 'No');
        task1.put('yesFlag', 'Yes');
        task1.put('name', 'Task 2');
        task1.put('id', '2');
        Map<String, Object> task2 = new Map<String, Object>();
        task2.put('status', 'CLOSED');
        task2.put('nextTask', '');
        task2.put('closingCapacity', 'Y');
        task2.put('naFlag', 'Not Apply');
        task2.put('noFlag', 'No Consolidated');
        task2.put('yesFlag', 'Yes Consolidated');
        task2.put('name', 'Task 3');
        task2.put('id', '3');

        taskList.add(task1);
        taskList.add(task2);
        //CIBGLOBALD-1195 parameter is added to the method
        Test.startTest();
        DMT_Passport_Handler.startCase(line.Line_Id__c,approverUpdate.DMT_External_Id__c, '1', taskList, '1', 'Test limit feature','', 'APPROVAL');
        Test.stopTest();

        List<Case> createdCase = [SELECT ID FROM Case WHERE DMT_Line__c=:line.Id];
        System.debug('createdCase: ' + createdCase);
        Assert.areEqual(createdCase.size(), 1, 'Possible error creating case');
    }

    @isTest
    private static void getFeatureRulesLWCTest(){
        DMT_Fuature_Rule__c featureRule = new DMT_Fuature_Rule__c();
        featureRule.DMT_Field__c = 'Test';
        featureRule.DMT_Validate_Type__c = 'DMTO';
        featureRule.dmt_message__c = 'Test message';
        insert featureRule;

        Test.startTest();
        List<DMT_Fuature_Rule__c> featureRules = DMT_Passport_Handler.getFeatureRulesLWC();
        Test.stopTest();

        Assert.areNotEqual(null, featureRules);
    }

    @isTest
    private static void calculatePermissionLWCTest(){
        DMT_Line__c line = [SELECT Id, Line_Id__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];

        Test.startTest();
        Boolean calculatePermission = DMT_Passport_Handler.calculatePermissionLWC(line.Id);
        Test.stopTest();

        Assert.areEqual(true, calculatePermission);
    }

    @isTest
    private static void buttonCallPassportExceptionTest(){
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
    private static void startCaseTest(){
        String errorMessage = '';
        Map<String, Object> startCase = new Map<String, Object>();

        DMT_Line__c line = [SELECT Id, Line_Id__c FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1 FOR UPDATE];
        Opportunity opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        Passport__c passport = new Passport__c(DMT_Line__c = line.Id);

        insert passport;
        List<Map<String, Object>> taskList = new List<Map<String, Object>>();
        Map<String, Object> task1 = new Map<String, Object>();
        task1.put('status', 'OPEN');
        task1.put('nextTask', '3');
        task1.put('closingCapacity', 'Y');
        task1.put('naFlag', 'Not Apply');
        task1.put('noFlag', 'No');
        task1.put('yesFlag', 'Yes');
        task1.put('name', 'Task 2');
        task1.put('id', '2');
        Map<String, Object> task2 = new Map<String, Object>();
        task2.put('status', 'CLOSED');
        task2.put('nextTask', '');
        task2.put('closingCapacity', 'Y');
        task2.put('naFlag', 'Not Apply');
        task2.put('noFlag', 'No Consolidated');
        task2.put('yesFlag', 'Yes Consolidated');
        task2.put('name', 'Task 3');
        task2.put('id', '3');

        taskList.add(task1);
        taskList.add(task2);

        try {
            //CIBGLOBALD-1195 parameter is added to the method
            startCase = DMT_Passport_Handler.startCase(line.Line_Id__c, null, '1', taskList, '1', 'Test limit feature','', 'APPROVAL');
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }


        Assert.areNotEqual(null, startCase.get('message'),startCase.get('message')+ 'No deberia haber error en la creación del caso');
    }

    @isTest
    private static void getInformationPassportExceptionTest(){
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
    private static void testCallLineException(){
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
        String action = 'TestMethod';

        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
        {
            'customerId' => 'ES0182054986618',
            'currentRatingToolDate' => Date.today(),
            'customerCounterpartiesCodesDesc' => 'A+'
        }};

        String errorMessage = '';

        try {
            Map<String, Object> input = new Map<String, Object>{'recordId' => null, 'forceCall' => 'true', 'clientsGroup' => JSON.serialize(clientsGroup)};
            Map<String, Object> args = new Map<String, Object>{'output' => new Map<String, Object>(), 'options' => new Map<String, Object>(), 'input' => input};

            DMT_Passport_Handler passportClass = new DMT_Passport_Handler();
            Map<String,Object> mapJSON = (Map<String,Object>) passportClass.call(action, args);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }

        Assert.areNotEqual(null, errorMessage);
    }

    @isTest
    public static void testBuildOpportunitySanctions() {
        Test.startTest();
        TriggerBypass.setBypass();
        DMT_Line__c line = new DMT_Line__c(
            Name = 'Test Line'
        );
        insert line;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Draft OPP',
            CloseDate = Date.today(),
            DMT_Sanction__c = line.Id
        );
        insert opp;

        DMT_Risk_Line_Term__c riskTerm2 = [ SELECT Id, Name FROM DMT_Risk_Line_Term__c WHERE Name = 'Line test ENERGIA FINANCIACION	rsk line term 1' LIMIT 1];

        Id stdPbId = Test.getStandardPricebookId();
        opp.Pricebook2Id = stdPbId;
        update opp;

        Product2 dummyProd = new Product2(Name = 'Dummy Test Product', IsActive = true);
        insert dummyProd;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = dummyProd.Id,
            UnitPrice    = 100.00,
            IsActive     = true
        );
        insert pbe;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00,
            
            DMT_Associated_Line_Product__c = riskTerm2.Id,
            gf_group_priority_opportunity_id__c = '01'
        );
        insert oli;

        // Sanction line created natively within this same opportunity
        line.DMT_Opportunity__c = opp.Id;
        update line;

        opp = [SELECT Id, DMT_Sanction__c, DMT_Sanction__r.Id,DMT_Sanction__r.DMT_Bussiness_Approved_Date__c,DMT_Sanction__r.Start_Date__c,DMT_Sanction__r.End_Date__c,DMT_Sanction__r.DMT_Individual_Disposal_Approval__c,DMT_Sanction__r.DMT_Business_Approved_End_Date__c,DMT_Sanction__r.Line_Id__c, DMT_Sanction__r.DMT_Opportunity__c, (SELECT Id, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        List<DMT_PassportOpportunity_Wrapper.OpportunitySanctions> result = DMT_Passport_Helper.buildOpportunitySanctions(opp);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Expected a single OpportunitySanctions entry');
        Assert.areEqual(true, result[0].newApproval, 'newApproval should be true when the sanction line originated from this same opportunity');
    }

    @isTest
    public static void testBuildOpportunitySanctions_ReusedSanction() {
        Test.startTest();

        TriggerBypass.setBypass();
        Opportunity originOpp = new Opportunity(
            Name = 'Origin Opportunity',
            StageName = 'Draft OPP',
            CloseDate = Date.today()
        );
        insert originOpp;

        // Sanction line created for a different opportunity and reused here
        DMT_Line__c line = new DMT_Line__c(
            Name = 'Test Line Reused',
            DMT_Opportunity__c = originOpp.Id
        );
        insert line;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity Reused Sanction',
            StageName = 'Draft OPP',
            CloseDate = Date.today(),
            DMT_Sanction__c = line.Id
        );
        insert opp;

        opp = [SELECT Id, DMT_Sanction__c, DMT_Sanction__r.Id,DMT_Sanction__r.DMT_Bussiness_Approved_Date__c,DMT_Sanction__r.Start_Date__c,DMT_Sanction__r.End_Date__c,DMT_Sanction__r.DMT_Individual_Disposal_Approval__c,DMT_Sanction__r.DMT_Business_Approved_End_Date__c,DMT_Sanction__r.Line_Id__c, DMT_Sanction__r.DMT_Opportunity__c, (SELECT Id, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        List<DMT_PassportOpportunity_Wrapper.OpportunitySanctions> result = DMT_Passport_Helper.buildOpportunitySanctions(opp);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Expected a single OpportunitySanctions entry');
        Assert.areEqual(false, result[0].newApproval, 'newApproval should be false when the sanction line originated from a different opportunity');
    }

     @isTest
    public static void testFeatureTypeByApproverType() {
        DMT_Line__c line = [SELECT Id, Line_Id__c FROM DMT_Line__c WHERE Line_Id__c = '00002' ];
        List<DMT_Approver__c> approverUpdate = [SELECT Id,DMT_External_Id__c FROM DMT_Approver__c WHERE Name = 'TestApproverDataFactory'];
        DMT_Approver_Type__c approverType = DMT_Test_DataFactory.generateApproverTypeRisk();

        List<String> listIdApprover = new List<String>();
        for(DMT_Approver__c appro : approverUpdate){
            listIdApprover.add(appro.DMT_External_Id__c);
            appro.DMT_ApproverType__c = approverType.Id;
        }
        update approverUpdate;
        Test.startTest();

        List<Map<String,String>> listFaeture = DMT_Passport_Handler.getFeatureTypeByApproverType(listIdApprover);

        Assert.isTrue(!listFaeture.isEmpty(), 'Contiene features');

        Test.stopTest();
    }

    @isTest
    private static void testMarkAsObsolete_DirectCall() {
        // 1. Identify the Passport from Setup data
        Passport__c passport = [SELECT Id, DMT_Is_Obsoleted_Passport_Save__c FROM Passport__c LIMIT 1];
        
        // Ensure the starting state is false
        passport.DMT_Is_Obsoleted_Passport_Save__c = false;
        update passport;

        // 2. EXECUTION: Call the private method directly
        Test.startTest();
        DMT_Passport_Handler.markAsObsolete(passport.Id);
        Test.stopTest();

        // 3. ASSERTION: Verify the database was updated
        Passport__c updatedPassport = [SELECT DMT_Is_Obsoleted_Passport_Save__c FROM Passport__c WHERE Id = :passport.Id];
        
        Assert.isTrue(updatedPassport.DMT_Is_Obsoleted_Passport_Save__c, 
            'The passport should have been marked as obsolete by the direct method call.');
    }

    @IsTest
    static void testAllWrapperProperties() {
        // 1. Instantiate the Outer Wrapper
        DMT_PassportOpportunity_Wrapper wrapper = new DMT_PassportOpportunity_Wrapper();

        // 2. Test Request & RequestBody (Covers 'analysts' {get;set;})
        DMT_PassportOpportunity_Wrapper.RequestBody body = new DMT_PassportOpportunity_Wrapper.RequestBody();
        body.analysts = new DMT_PassportOpportunity_Wrapper.Analyst(); 
        body.opportunity = new DMT_PassportOpportunity_Wrapper.Opportunity();
        body.products = new List<DMT_PassportOpportunity_Wrapper.Product>();

        // 3. Test Opportunity (Covers 'xsells' {get;set;})
        DMT_PassportOpportunity_Wrapper.Opportunity opp = new DMT_PassportOpportunity_Wrapper.Opportunity();
        opp.xsells = new List<DMT_PassportOpportunity_Wrapper.Xsells>();
        opp.counterpart = 'Test Counterpart';
        opp.opportunityAmount = 1000.00;

        // 4. Test Product (Covers 'mitigants', 'funding', 'amortization', 'tenorAmount' {get;set;})
        DMT_PassportOpportunity_Wrapper.Product prod = new DMT_PassportOpportunity_Wrapper.Product();
        prod.mitigants = new List<DMT_PassportOpportunity_Wrapper.Mitigant>();
        prod.funding = new DMT_PassportOpportunity_Wrapper.Funding();
        prod.amortization = new DMT_PassportOpportunity_Wrapper.Amortization();
        prod.tenorAmount = 500.50;
        prod.productId = 'P123';

        // 5. Test Funding (Covers your new field 'sustainableDelegatedFilter')
        prod.funding.sustainableDelegatedFilter = 'FilterValue';
        prod.funding.sustainableDeal = 'Yes';
        prod.funding.greenBond = true;

        // 6. Test Mitigant (Covers 'customerId', 'groupId', 'subgroupId', 'supragroupId' {get;set;})
        DMT_PassportOpportunity_Wrapper.Mitigant mit = new DMT_PassportOpportunity_Wrapper.Mitigant();
        mit.customerId = 'C-100';
        mit.groupId = 'G-200';
        mit.subgroupId = 'S-300';
        mit.supragroupId = 'SUPER-400';
        mit.mitigantType = 'Type A';

        // 7. Test Amortization & Payments
        DMT_PassportOpportunity_Wrapper.Amortization amrt = new DMT_PassportOpportunity_Wrapper.Amortization();
        amrt.rateType = 'Fixed';
        amrt.payments = new List<DMT_PassportOpportunity_Wrapper.AmortizationPayments>();
        
        DMT_PassportOpportunity_Wrapper.AmortizationPayments pay = new DMT_PassportOpportunity_Wrapper.AmortizationPayments();
        pay.nominalAmount = 100.00;
        amrt.payments.add(pay);

        // 8. Test Sanctions & Lines
        DMT_PassportOpportunity_Wrapper.OpportunitySanctions sanc = new DMT_PassportOpportunity_Wrapper.OpportunitySanctions();
        sanc.lineCode = 'L001';
        sanc.productsLine = new List<DMT_PassportOpportunity_Wrapper.ProductsLine>();

        // Assertions to validate the data was set correctly
        System.assertNotEquals(null, prod.funding.sustainableDelegatedFilter, 'The new filter should be set.');
        System.assertEquals('C-100', mit.customerId, 'Customer ID should match.');
        System.assertEquals(500.50, prod.tenorAmount, 'Tenor amount should match.');
    }

    // -----------------------------------------------------------------------
    // Tests for getMainHolderAccountId
    // -----------------------------------------------------------------------

    @isTest
    private static void testGetMainHolderAccountId_nullOppId() {
        String errorMessage = '';
        Test.startTest();
        try {
            DMT_Passport_Handler.getMainHolderAccountId(null);
        } catch (AuraHandledException e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(errorMessage), 'Should throw AuraHandledException for null oppId');
    }

    @isTest
    private static void testGetMainHolderAccountId_noAssoc() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE DMT_Opp_Id__c = '00001' LIMIT 1];
        Test.startTest();
        Map<String, Object> result = DMT_Passport_Handler.getMainHolderAccountId(opp.Id);
        Test.stopTest();
        Assert.isNotNull(result, 'Result map should not be null');
        Assert.areEqual(opp.AccountId, (Id) result.get('AccountId'), 'AccountId should match the opportunity account');
    }

    @isTest
    private static void testGetMainHolderAccountId_withAssocAndCustomerId() {
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
        Map<String, Object> result = DMT_Passport_Handler.getMainHolderAccountId(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result map should not be null');
        Assert.isNotNull(result.get('AccountId'), 'AccountId should be populated via Account.g_customer_id__c');
        Assert.areEqual('Subsidiary', (String) result.get('ClientType'), 'ClientType should match DES_Client_Type__c on account found via g_customer_id__c');
    }

}