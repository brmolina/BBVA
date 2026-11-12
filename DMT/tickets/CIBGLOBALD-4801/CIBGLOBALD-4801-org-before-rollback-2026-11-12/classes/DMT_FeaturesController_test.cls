@isTest
public with sharing class DMT_FeaturesController_test {
    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass(); // CIBGLOBALD-4801
    static Id testLineId;

    @TestSetup
    static void setupTestData() {

        // Account needed to avoid a NullPointerException in the Opportunity trigger
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        DMT_Line__c line = new DMT_Line__c(
            Name = 'Test line',
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

        Assert.areNotEqual(null, result, 'The result must not be null');
        Assert.isTrue(result.size() > 0, 'At least one feature must be returned');
        Assert.isTrue(result[0].containsKey('isSelected'), 'It must contain the isSelected field');
    }

    @isTest
    static void testGetPassportIdFromLineOrOpportunity() {
        
        Passport__c passport = [SELECT Id, DMT_Line__c FROM Passport__c WHERE DMT_Line__c != null LIMIT 1];
        Id lineId = passport.DMT_Line__c;

        Test.startTest();
        Id passportId = DMT_FeaturesController.getPassportIdFromLineOrOpportunity(lineId);
        Test.stopTest();

        Assert.areNotEqual(null, passportId, 'It must return a Passport Id');
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

    // --- Reusable helpers for the Passport traffic light rules ---

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
        // CIBGLOBALD-4801 - Opportunity from DMT_Test_DataFactory instead of an inline insert
        return DMT_Test_DataFactory.generateOpportunity(new Map<Schema.SObjectField, Object>{
            Opportunity.Name => name,
            Opportunity.DMT_Opp_Id__c => extId
        });
    }

    private static Passport__c createTestPassport(Id opportunityId, List<Map<String, Object>> features) {
        // CIBGLOBALD-4801 - Passport from DMT_Test_DataFactory (reuses the one the Opportunity automation may create)
        return DMT_Test_DataFactory.generatePassport(opportunityId, buildPassportJson(features));
    }

    // CIBGLOBALD-4801 - Approval Case (record type Approval, as every feature Case) of an Opportunity or a DMT Line with one
    // step Task, from DMT_Test_DataFactory instead of inline inserts
    private static Task createWorkflowCaseAndTask(Id recordId, String featureId, String caseStatus, String stepResult) {
        Schema.SObjectField contextField = recordId.getSObjectType() == Opportunity.SObjectType ? Case.opportunity_id__c : Case.DMT_Line__c;
        Case workflowCase = DMT_Test_DataFactory.generateCase(UserInfo.getUserId(), new Map<Schema.SObjectField, Object>{
            Case.Subject => 'Workflow Case ' + featureId,
            Case.Status => caseStatus,
            Case.DMT_Feature_Id__c => featureId,
            contextField => recordId
        });
        Id stepTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(DMT_Constants.TASK_RT_APPROVAL_STEP).getRecordTypeId();
        return DMT_Test_DataFactory.generateTasksWithOwner(UserInfo.getUserId(), stepTaskRecordTypeId, workflowCase.Id, 1, new Map<Schema.SObjectField, Object>{
            Task.Status => 'Completed',
            Task.DMT_Step_Result__c => stepResult
        })[0];
    }

    @isTest
    static void testValidateSemaphore_ClosedLost_EarlyReturn() {
        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateSemaphoreRulesForStageChange('irrelevantId', 'Closed Lost');
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('isValid'), 'Closed Lost must always return isValid = true');
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

        Assert.isFalse((Boolean) result.get('isValid'), 'Capability RED does not meet the required GRE, it must block with AND');
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
        createWorkflowCaseAndTask(opp.Id, 'F1', 'Finished', 'No');

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateSemaphoreRulesForStageChange(opp.Id, 'Closed Won');
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('isValid'), 'Case finished with No result and workflow RED should be valid');
    }

    @isTest
    static void testResolveWorkflowColor_FinishedYes_ReturnsGre() {
        Assert.areEqual('GRE', DMT_Semaphore_Logic.resolveWorkflowColor('Finished', 'Yes')); // CIBGLOBALD-4801
    }

    @isTest
    static void testResolveWorkflowColor_PendingOrInProgress_ReturnsYellow() {
        Assert.areEqual('YEL', DMT_Semaphore_Logic.resolveWorkflowColor('Pending', null)); // CIBGLOBALD-4801
        Assert.areEqual('YEL', DMT_Semaphore_Logic.resolveWorkflowColor('In Progress', null)); // CIBGLOBALD-4801
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
        Assert.isTrue(DMT_Semaphore_Logic.evaluate(r, 'GRE', null));   // capability only

        r.requiredColorCapability = null; r.requiredColorWorkflow = 'GRE';
        Assert.isTrue(DMT_Semaphore_Logic.evaluate(r, null, 'GRE'));   // workflow only

        r.requiredColorCapability = null; r.requiredColorWorkflow = null;
        Assert.isFalse(DMT_Semaphore_Logic.evaluate(r, 'GRE', 'GRE')); // none configured
    }

    // CIBGLOBALD-4801 - coverage of validateStageAdvanceRequirements (same class): Closed Lost never blocks
    @isTest
    static void testValidateStageAdvanceRequirements_ClosedLost_IsValid() {
        Map<String, Object> result = DMT_FeaturesController.validateStageAdvanceRequirements(null, 'Approval', 'Closed Lost');
        Assert.isTrue((Boolean) result.get('isValid'), 'Closed Lost must always be valid');
    }

    // CIBGLOBALD-4801 - coverage of validateStageAdvanceRequirements: Proposal -> Approval without Description of the deal is blocked
    @isTest
    static void testValidateStageAdvanceRequirements_ApprovalWithoutDescription_IsInvalid() {
        Opportunity opp = createTestOpportunity('Opp StageAdvance', 'EXT-STAGEADVANCE-001');
        createTestPassport(opp.Id, new List<Map<String, Object>>{
            buildFeature('F1', 'Any feature', 'GREEN', 'N', null, null, null, null, null)
        });

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateStageAdvanceRequirements(opp.Id, 'Proposal', 'Approval');
        Test.stopTest();

        Assert.isFalse((Boolean) result.get('isValid'), 'Approval needs the Description of the deal');
        Assert.isTrue(String.valueOf(result.get('errorMessage')).contains('Description of the deal'), 'The message names the missing field');
    }

    // CIBGLOBALD-4801 - Finished Case without step result is grey, as in the Passport cards; Finished + No is red
    @isTest
    static void testResolveWorkflowColor_FinishedWithoutResult_ReturnsGrey() {
        Assert.areEqual('GRA', DMT_Semaphore_Logic.resolveWorkflowColor('Finished', null), 'Finished without result is grey');
        Assert.areEqual('RED', DMT_Semaphore_Logic.resolveWorkflowColor('Finished', 'No'), 'Finished with No is red');
        Assert.isNull(DMT_Semaphore_Logic.resolveWorkflowColor(null, null), 'No Case status gives no color');
    }

    // CIBGLOBALD-4801 - Line moving to Ready to close: a passport-sanction feature required for READY TO CLOSE whose
    // workflow is not green (tasks, no Case yet = YEL) blocks, even when it is not an approval feature
    @isTest
    static void testValidateSemaphore_LineReadyToClose_RequiredPassportFeatureNotGreen_Blocks() {
        DMT_Line__c line = createLineWithPassport(new List<Map<String, Object>>{
            buildRequiredFeature('226', 'Asset Allocation Validation', 'passport', 'Y', 'READY TO CLOSE')
        });

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateSemaphoreRulesForStageChange(line.Id, DMT_Constants.READYTOCLOSE);
        Test.stopTest();

        Assert.isFalse((Boolean) result.get('isValid'), 'A required feature without a green workflow must block Ready to close');
        Assert.areEqual(new List<String>{ 'Asset Allocation Validation' }, (List<String>) result.get('incompleteFeatures'), 'The blocking feature name is returned');
    }

    // CIBGLOBALD-4801 - same feature approved (Case Finished, latest step Yes) lets the Line move
    @isTest
    static void testValidateSemaphore_LineReadyToClose_RequiredFeatureApproved_IsValid() {
        DMT_Line__c line = createLineWithPassport(new List<Map<String, Object>>{
            buildRequiredFeature('226', 'Asset Allocation Validation', 'passport', 'Y', 'READY TO CLOSE')
        });
        createWorkflowCaseAndTask(line.Id, '226', DMT_Constants.FINISHED, 'Yes');

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateSemaphoreRulesForStageChange(line.Id, DMT_Constants.READYTOCLOSE);
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('isValid'), 'A green required feature must not block Ready to close');
    }

    // CIBGLOBALD-4801 - features not required for the target status never block: requiredType N, or required for another status
    @isTest
    static void testValidateSemaphore_FeatureNotRequiredForTargetStatus_IsValid() {
        Opportunity opp = createTestOpportunity('Opp NotRequired', 'EXT-NOTREQUIRED-001');
        createTestPassport(opp.Id, new List<Map<String, Object>>{
            buildRequiredFeature('F1', 'Not required feature', 'passport', 'N', 'READY TO CLOSE'),
            buildRequiredFeature('F2', 'Required for Closed Won', 'readytoclose', 'Y', 'CLOSED WON')
        });

        Test.startTest();
        Map<String, Object> result = DMT_FeaturesController.validateSemaphoreRulesForStageChange(opp.Id, DMT_Constants.READYTOCLOSE);
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('isValid'), 'Features not required for Ready to close must not block it');
    }

    // CIBGLOBALD-4801 - a check that cannot run blocks the move (the path shows the error)
    @isTest
    static void testValidateSemaphore_InvalidRecordId_Throws() {
        Boolean thrown = false;
        Test.startTest();
        try {
            DMT_FeaturesController.validateSemaphoreRulesForStageChange('not-an-id', DMT_Constants.READYTOCLOSE);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

        Assert.isTrue(thrown, 'A failing check must throw so the stage change is blocked');
    }

    // CIBGLOBALD-4801 - Passport feature with tasks and a workflow rule (GRE) for the given required type and status
    private static Map<String, Object> buildRequiredFeature(String id, String name, String passportSanction, String requiredType, String requiredStatus) {
        List<Object> tasks = new List<Object>{ new Map<String, Object>{ 'id' => 'T' + id } };
        Map<String, Object> feature = buildFeature(id, name, 'WHITE', requiredType, null, 'GRE', null, requiredStatus, tasks);
        feature.put('passportSanction', passportSanction);
        return feature;
    }

    // CIBGLOBALD-4801 - DMT Line in Approval with a Passport holding the given features
    private static DMT_Line__c createLineWithPassport(List<Map<String, Object>> features) {
        DMT_Line__c line = DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Line_Id__c => 'L4801',
            DMT_Line__c.Status__c => DMT_Constants.APPROVAL
        });
        DMT_UTIL.createPassportRecord(new Map<Schema.SObjectField, Object>{
            Passport__c.DMT_Line__c => line.Id,
            Passport__c.DMT_Passport_Save__c => buildPassportJson(features)
        });
        return line;
    }
}