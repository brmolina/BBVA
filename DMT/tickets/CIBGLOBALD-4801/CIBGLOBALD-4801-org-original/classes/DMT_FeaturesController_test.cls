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

    // --- Helpers reutilizables: Para nueva lógica de semáforos en passport ---

    private static Map<String, Object> buildFeature(String id, String name, String stateName, String requiredType,
                                                      String reqColorCap, String reqColorWF, String operatorType,
                                                      String requiredStatus, List<Object> tasks) {
        Map<String, Object> f = new Map<String, Object>();
        f.put('id', id);
        f.put('name', name);
        f.put('stateName', stateName);
        f.put('requiredType', requiredType);
        f.put('requiredColorCapability', reqColorCap);
        f.put('requiredColorWorkflow', reqColorWF);
        f.put('colorLogicalOperatorType', operatorType);
        f.put('requiredStatus', requiredStatus);
        if (tasks != null) {
            f.put('tasks', tasks);
        }
        return f;
    }

    private static String buildPassportJson(List<Map<String, Object>> features) {
        Map<String, Object> dataMap = new Map<String, Object>{ 'features' => features };
        Map<String, Object> root = new Map<String, Object>{ 'data' => dataMap };
        return JSON.serialize(root);
    }

    private static Opportunity createTestOpportunity(String name, String extId) {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = name,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            DMT_Opp_Id__c = extId,
            AccountId = acc.Id
        );
        insert opp;
        return opp;
    }

    private static Passport__c createTestPassport(Id opportunityId, List<Map<String, Object>> features) {
        Passport__c passport = new Passport__c(
            Opportunity__c = opportunityId,
            DMT_Passport_Save__c = buildPassportJson(features)
        );
        insert passport;
        return passport;
    }

    // Reutiliza el mismo patrón que ya usaban los tests DEPRECATED (Case + Task con RecordType DMT_Step_Approval)
    private static Task createWorkflowCaseAndTask(Id opportunityId, String featureId, String caseStatus, String stepResult) {
        Case workflowCase = new Case(
            Subject = 'Workflow Case ' + featureId,
            Status = caseStatus
        );
        workflowCase.put('Opportunity_Id__c', opportunityId);
        workflowCase.put('DMT_Feature_Id__c', featureId);
        insert workflowCase;

        RecordType stepApprovalRt = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Task' AND DeveloperName = 'DMT_Step_Approval'
            LIMIT 1
        ];

        Task workflowTask = new Task(
            WhatId = workflowCase.Id,
            Subject = 'Workflow Task ' + featureId,
            Status = 'Completed',
            RecordTypeId = stepApprovalRt.Id
        );
        workflowTask.put('DMT_Step_Result__c', stepResult);
        insert workflowTask;
        return workflowTask;
    }

    @isTest
    static void testValidateSemaphore_ClosedLost_EarlyReturn() {
        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateSemaphoreRulesForStageChange('irrelevantId', 'Closed Lost');
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('isValid'), 'Closed Lost debe devolver siempre isValid = true');
        Assert.isTrue(((List<Object>) result.get('incompleteFeatures')).isEmpty());
    }

    @isTest
    static void testValidateSemaphore_ClosedWonOverride_ANDBlocking() {
        Opportunity opp = createTestOpportunity('Opp ClosedOverride', 'EXT-CLOSEDOVERRIDE-001');
        createTestPassport(opp.Id, new List<Map<String, Object>>{
            buildFeature('F1', 'Capability Blocking Feature', 'RED', 'Y', 'GRE', 'GRE', 'AND', 'Closed', null)
        });

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateSemaphoreRulesForStageChange(opp.Id, 'Closed Won');
        Test.stopTest();

        Assert.isFalse((Boolean) result.get('isValid'), 'Capability RED no cumple GRE requerido, debe bloquear con AND');
        List<Object> blocking = (List<Object>) result.get('incompleteFeatures');
        Assert.areEqual(1, blocking.size());
        Assert.areEqual('Capability Blocking Feature', (String) blocking[0]);
    }

    @isTest
    static void testValidateSemaphore_CaseFinishedNo_WorkflowRed() {
        Opportunity opp = createTestOpportunity('Opp CaseRed', 'EXT-CASERED-001');
        List<Object> tasks = new List<Object>{ new Map<String, Object>{ 'id' => 'T1' } };
        createTestPassport(opp.Id, new List<Map<String, Object>>{
            buildFeature('F1', 'Feature Case Red', 'YEL', 'Y', 'GRE', 'RED', 'OR', 'Closed Won', tasks)
        });
        createWorkflowCaseAndTask(opp.Id, 'F1', 'Finished', 'No'); // <- crea el Case + Task real

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateSemaphoreRulesForStageChange(opp.Id, 'Closed Won');
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('isValid'), 'Case finished with No result and workflow RED should be valid');
    }

    @isTest
    static void testResolveWorkflowColor_FinishedYes_ReturnsGre() {
        Assert.areEqual('GRE', DMT_FeaturesController.resolveWorkflowColor('Finished', 'Yes'));
    }

    @isTest
    static void testResolveWorkflowColor_PendingOrInProgress_ReturnsYellow() {
        Assert.areEqual('YEL', DMT_FeaturesController.resolveWorkflowColor('Pending', null));
        Assert.areEqual('YEL', DMT_FeaturesController.resolveWorkflowColor('In Progress', null));
    }

    @isTest
    static void testNormalizeToShortColor_Gray() {
        Assert.areEqual('GRA', DMT_Semaphore_Logic.normalizeToShortColor('GRAY'));
        Assert.areEqual('GRA', DMT_Semaphore_Logic.normalizeToShortColor('GRA'));
    }

    @isTest
    static void testEvaluate_NoOperator_AllBranches() {
        DMT_Semaphore_Logic.SemaphoreRule r = new DMT_Semaphore_Logic.SemaphoreRule();
        r.requiredColorCapability = 'GRE'; r.requiredColorWorkflow = null;
        Assert.isTrue(DMT_Semaphore_Logic.evaluate(r, 'GRE', null));   // solo capability

        r.requiredColorCapability = null; r.requiredColorWorkflow = 'GRE';
        Assert.isTrue(DMT_Semaphore_Logic.evaluate(r, null, 'GRE'));   // solo workflow

        r.requiredColorCapability = null; r.requiredColorWorkflow = null;
        Assert.isFalse(DMT_Semaphore_Logic.evaluate(r, 'GRE', 'GRE')); // ninguno configurado
    }
}