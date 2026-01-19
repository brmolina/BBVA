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
            Boolean startCase = DMT_Passport_Handler.startCase(line.Line_Id__c, null, '1', taskList, '1', 'Test limit feature','', 'APPROVAL');
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }


        Assert.areNotEqual(null, errorMessage);
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

        opp = [SELECT Id, DMT_Sanction__c, DMT_Sanction__r.Id, DMT_Sanction__r.Line_Id__c, (SELECT Id, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        List<DMT_PassportOpportunity_Wrapper.OpportunitySanctions> result = DMT_Passport_Helper.buildOpportunitySanctions(opp);
        Test.stopTest();
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
}