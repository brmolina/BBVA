@isTest
public with sharing class DMT_FeaturesController_test {
    static Id testLineId;

    @TestSetup
    static void setupTestData() {

        // Account necesaria para evitar NullPointerException en el trigger de Opportunity
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        DMT_Line__c line = new DMT_Line__c(
            Name = 'Línea de prueba',
            Line_Id__c = '00002'
        );
        insert line;
        testLineId = line.Id;


        List<DMT_Feature__c> features = new List<DMT_Feature__c>{
            new DMT_Feature__c(
                gf_capability_engine_id_number__c = '123',
                gf_feature_name_desc__c = 'Feature Test A',
                gf_feature_deal_type__c = 'Type1',
                gf_global_feature_id_number__c = 'GF001',
                gf_approver_apply_ind_type__c = 'Test1',
                gf_user_audit_id__c = 'UserTest',
                gf_audit_date__c = Date.today(),
                gf_operation_type_name__c = 'ALL'
            ),
            new DMT_Feature__c(
                gf_capability_engine_id_number__c = '456',
                gf_feature_name_desc__c = 'Feature Test B',
                gf_feature_deal_type__c = 'Type2',
                gf_global_feature_id_number__c = 'GF002',
                gf_approver_apply_ind_type__c = 'Test2',
                gf_user_audit_id__c = 'UserTest',
                gf_audit_date__c = Date.today(),
                gf_operation_type_name__c = 'LIN'
            )
        };
        insert features;

        DMT_Selected_Features__c selected = new DMT_Selected_Features__c(
            Line__c = line.Id,
            Feature__c = features[0].Id
        );
        insert selected;

        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
            DMT_Is_Obsoleted_Passport_Save__c = false
        );
        insert passport;
    }

    @isTest
    static void testLoadFeatures() {
        Test.startTest();
        List<Map<String, Object>> result = DMT_FeaturesController.loadFeatures(testLineId, 'Type1');
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.size() > 0, 'Debe haber al menos una feature devuelta');
        System.assert(result[0].containsKey('isSelected'), 'Debe contener el campo isSelected');
    }

    @isTest
    static void testGetPassportIdFromLineOrOpportunity() {
        
        Passport__c passport = [SELECT Id, DMT_Line__c FROM Passport__c WHERE DMT_Line__c != null LIMIT 1];
        Id lineId = passport.DMT_Line__c;

        Test.startTest();
        Id passportId = DMT_FeaturesController.getPassportIdFromLineOrOpportunity(lineId);
        Test.stopTest();

        System.assertNotEquals(null, passportId, 'Debe devolver un Id de Passport');
    }

    @isTest
    static void testGetObligatoryFeatures() {
        DMT_Line__c testLine = new DMT_Line__c(Name = 'Test Line');
        insert testLine;

        String jsonData = '{"data":{"features":[{"id":"Test1","name":"Global validations","stateName":"RED"},{"id":"Test2","name":"Limit Feature test 1","stateName":"GREEN"}]}}';

        List<Passport__c> existingPassports = [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testLine.Id];
        delete existingPassports;

        Passport__c testPassport = new Passport__c(
            DMT_Line__c = testLine.Id,
            DMT_Passport_Save__c = jsonData
        );
        insert testPassport;

        Passport__c retrievedPassport = [SELECT Id, DMT_Passport_Save__c, DMT_Line__c FROM Passport__c WHERE DMT_Line__c = :testLine.Id];

        Test.startTest();
        List<Map<String, Object>> features = DMT_FeaturesController.getObligatoryFeatures(testLine.Id);
        Test.stopTest();

        System.debug('Features List: ' + features);

        Assert.isNotNull(features, 'Features list should not be null.');
        Assert.areEqual(2, features.size(), 'Features list should contain 2 items.');
        Assert.areEqual('Global validations', features[0].get('name'), 'First feature name should match.');
        Assert.areEqual('Limit Feature test 1', features[1].get('name'), 'Second feature name should match.');
        Assert.areEqual('RED', features[0].get('stateName'), 'First feature stateName should match.');
        Assert.areEqual('GREEN', features[1].get('stateName'), 'Second feature stateName should match.');
    }

    @isTest
    static void testGetObligatoryFeaturesClosedWon_WithRequiredFeatures() {
        DMT_Line__c testLine = new DMT_Line__c(Name = 'Test Line Closed Won');
        insert testLine;

        String jsonData = '{"data":{"features":[' +
            '{"id":"F1","name":"Feature Obligatorio Passport","stateName":"RED","requiredType":"Y","passportSanction":"passport"},' +
            '{"id":"F2","name":"Feature No Obligatorio","stateName":"GREEN","requiredType":"N","passportSanction":"passport"},' +
            '{"id":"F3","name":"Feature Obligatorio No Passport","stateName":"RED","requiredType":"Y","passportSanction":"other"}' +
            ']}}';

        List<Passport__c> existingPassports = [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testLine.Id];
        delete existingPassports;

        Passport__c testPassport = new Passport__c(
            DMT_Line__c = testLine.Id,
            DMT_Passport_Save__c = jsonData
        );
        insert testPassport;

        Test.startTest();
        List<Map<String, Object>> features = DMT_FeaturesController.getObligatoryFeaturesClosedWon(testLine.Id);
        Test.stopTest();

        Assert.isNotNull(features, 'Features list should not be null.');
        Assert.areEqual(2, features.size(), 'Should return all features with requiredType Y.');
        Assert.areEqual('Y', features[0].get('requiredType'), 'First feature should have requiredType Y.');
        Assert.areEqual('Y', features[1].get('requiredType'), 'Second feature should have requiredType Y.');
    }

    @isTest
    static void testGetObligatoryFeaturesClosedWon_NoFeatures() {
        DMT_Line__c testLine = new DMT_Line__c(Name = 'Test Line No Features');
        insert testLine;

        String jsonData = '{"data":{"features":[]}}';

        List<Passport__c> existingPassports = [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testLine.Id];
        delete existingPassports;

        Passport__c testPassport = new Passport__c(
            DMT_Line__c = testLine.Id,
            DMT_Passport_Save__c = jsonData
        );
        insert testPassport;

        Test.startTest();
        List<Map<String, Object>> features = DMT_FeaturesController.getObligatoryFeaturesClosedWon(testLine.Id);
        Test.stopTest();

        Assert.isNotNull(features, 'Features list should not be null.');
        Assert.areEqual(0, features.size(), 'Should return empty list when no features.');
    }

    @isTest
    static void testGetObligatoryFeaturesClosedWon_NullPassportSave() {
        DMT_Line__c testLine = new DMT_Line__c(Name = 'Test Line Null Save');
        insert testLine;

        List<Passport__c> existingPassports = [SELECT Id FROM Passport__c WHERE DMT_Line__c = :testLine.Id];
        delete existingPassports;

        Passport__c testPassport = new Passport__c(
            DMT_Line__c = testLine.Id,
            DMT_Passport_Save__c = null
        );
        insert testPassport;

        Test.startTest();
        List<Map<String, Object>> features = DMT_FeaturesController.getObligatoryFeaturesClosedWon(testLine.Id);
        Test.stopTest();

        Assert.isNotNull(features, 'Features list should not be null.');
        Assert.areEqual(0, features.size(), 'Should return empty list when DMT_Passport_Save__c is null.');
    }

    @isTest
    static void testValidateFeaturesForClosedWon_Valid() {
        // Recupera el Account del @TestSetup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test Opp Valid',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            DMT_Opp_Id__c = 'EXT-VALID-001',
            AccountId = testAccount.Id 
        );
        insert opp;

        String jsonData = '{"data":{"features":[' +
            '{"id":"F1","name":"Feature 1","stateName":"GREEN","requiredType":"Y","passportSanction":"passport"}' +
            ']}}';

        Passport__c testPassport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = jsonData
        );
        insert testPassport;

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateFeaturesForClosedWon(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null.');
        Assert.isTrue((Boolean) result.get('isValid'), 'Should be valid when no incomplete features exist.');
        Assert.areEqual(0, ((List<Map<String, String>>) result.get('incompleteFeatures')).size(), 'Should have no incomplete features.');
    }

    @isTest
    static void testValidateFeaturesForClosedWon_InvalidCapabilityRed() {
        // Recupera el Account del @TestSetup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test Opp Capability Red',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            DMT_Opp_Id__c = 'EXT-CAP-RED-001',
            AccountId = testAccount.Id 
        );
        insert opp;

        String jsonData = '{"data":{"features":[' +
            '{"id":"F1","name":"Critical Feature","stateName":"RED","requiredType":"Y","passportSanction":"passport"}' +
            ']}}';

        Passport__c testPassport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = jsonData
        );
        insert testPassport;

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateFeaturesForClosedWon(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null.');
        Assert.isFalse((Boolean) result.get('isValid'), 'Should be invalid when capability is RED.');
        List<Map<String, String>> incompleteFeatures = (List<Map<String, String>>) result.get('incompleteFeatures');
        Assert.areEqual(1, incompleteFeatures.size(), 'Should have 1 incomplete feature.');
        Assert.areEqual('Critical Feature', incompleteFeatures[0].get('name'), 'Feature name should match.');
        Assert.areEqual('RED', incompleteFeatures[0].get('stateName'), 'State should be RED.');
    }

    @isTest
    static void testValidateFeaturesForClosedWon_InvalidWorkflowRed() {
        // Recupera el Account del @TestSetup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test Opp Workflow Red',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            DMT_Opp_Id__c = 'EXT-WF-RED-001',
            AccountId = testAccount.Id  
        );
        insert opp;

        String jsonData = '{"data":{"features":[' +
            '{"id":"WF1","name":"Workflow Feature","stateName":"GREEN","requiredType":"Y","passportSanction":"passport","tasks":[{"id":"T1"}]}' +
            ']}}';

        Passport__c testPassport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = jsonData
        );
        insert testPassport;

        Case workflowCase = new Case(
            Subject = 'Workflow Test Case',
            Status = 'Finished'
        );
        workflowCase.put('Opportunity_Id__c', opp.Id);
        workflowCase.put('DMT_Feature_Id__c', 'WF1');
        insert workflowCase;

        RecordType stepApprovalRt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Task' AND DeveloperName = 'DMT_Step_Approval'
            LIMIT 1
        ];

        Task workflowTask = new Task(
            WhatId = workflowCase.Id,
            Subject = 'Workflow Approval Task',
            Status = 'Completed',
            RecordTypeId = stepApprovalRt.Id
        );
        workflowTask.put('DMT_Step_Result__c', 'No');
        insert workflowTask;

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateFeaturesForClosedWon(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null.');
        Assert.isFalse((Boolean) result.get('isValid'), 'Should be invalid when workflow is finished with No result.');
        List<Map<String, String>> incompleteFeatures = (List<Map<String, String>>) result.get('incompleteFeatures');
        Assert.areEqual(1, incompleteFeatures.size(), 'Should have 1 incomplete feature by workflow condition.');
        Assert.areEqual('Workflow Feature', incompleteFeatures[0].get('name'), 'Feature name should match.');
    }

    @isTest
    static void testValidateFeaturesForClosedWon_NoRequiredFeatures() {
        // Recupera el Account del @TestSetup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Test Opp No Required',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            DMT_Opp_Id__c = 'EXT-NOREQ-001',
            AccountId = testAccount.Id  
        );
        insert opp;

        String jsonData = '{"data":{"features":[' +
            '{"id":"F1","name":"Optional Feature","stateName":"RED","requiredType":"N","passportSanction":"passport"}' +
            ']}}';

        Passport__c testPassport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = jsonData
        );
        insert testPassport;

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateFeaturesForClosedWon(opp.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null.');
        Assert.isTrue((Boolean) result.get('isValid'), 'Should be valid when there are no required features.');
        Assert.areEqual(0, ((List<Map<String, String>>) result.get('incompleteFeatures')).size(), 'Should have no incomplete features.');
    }

    @isTest
    static void testValidateFeaturesForClosedWon_ExceptionPath() {
        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateFeaturesForClosedWon('INVALID_ID');
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null.');
        Assert.isTrue((Boolean) result.get('isValid'), 'Should return valid true when exception is handled.');
    }
}