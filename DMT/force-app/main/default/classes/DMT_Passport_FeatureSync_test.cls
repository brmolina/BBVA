@isTest
public with sharing class DMT_Passport_FeatureSync_test {
    private static final Id CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
    private static final Id TASK_RT_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
    private static final String LINE_EXT_ID = 'L-4507';
    private static Id queueId;

    @TestSetup
    static void loadTestData() {
        TriggerBypass.setBypass();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Line__c line = new DMT_Line__c(Line_Id__c = LINE_EXT_ID, Status__c = DMT_Constants.APPROVAL);
        insert line;

        insert new List<Passport__c>{
            new Passport__c(DMT_Line__c = line.Id, DMT_Passport_Save__c = buildJson(new List<String>{'10', '11'})),
            new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = buildJson(new List<String>{'10', '11'}))
        };
        TriggerBypass.removeBypass();
    }

    private static String buildJson(List<String> featureIds) {
        List<Object> features = new List<Object>();
        for (String featureId : featureIds) {
            features.add(new Map<String, Object>{'id' => featureId, 'name' => 'Feature ' + featureId, 'passportSanction' => 'passport'});
        }
        return JSON.serialize(new Map<String, Object>{'data' => new Map<String, Object>{'features' => features}});
    }

    private static Passport__c getLinePassport() {
        return [SELECT Id, DMT_Line__c, Opportunity__c FROM Passport__c WHERE DMT_Line__r.Line_Id__c = :LINE_EXT_ID ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Passport__c getOppPassport() {
        return [SELECT Id, DMT_Line__c, Opportunity__c FROM Passport__c WHERE Opportunity__c != null ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Id getQueueId() {
        if (queueId == null) {
            queueId = [SELECT Id FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1].Id;
        }
        return queueId;
    }

    private static Case createCase(Id lineId, Id oppId, String featureId, String status) {
        Case newCase = new Case(RecordTypeId = CASE_RT_ID, DMT_Line__c = lineId, opportunity_id__c = oppId, DMT_Feature_Id__c = featureId,
                                DMT_Passport_Sanction__c = 'passport', Status = status, OwnerId = getQueueId(), Subject = 'Test 4507');
        insert newCase;
        return newCase;
    }

    private static Task createTask(Id caseId, String status) {
        Task newTask = new Task(WhatId = caseId, Status = status, Subject = 'Step 4507', OwnerId = getQueueId(), RecordTypeId = TASK_RT_ID);
        insert newTask;
        return newTask;
    }

    private static void runSync(Passport__c passport, String oldJson, String newJson) {
        Passport__c oldPassport = new Passport__c(Id = passport.Id, DMT_Line__c = passport.DMT_Line__c, Opportunity__c = passport.Opportunity__c, DMT_Passport_Save__c = oldJson);
        Passport__c newPassport = new Passport__c(Id = passport.Id, DMT_Line__c = passport.DMT_Line__c, Opportunity__c = passport.Opportunity__c, DMT_Passport_Save__c = newJson);
        DMT_Passport_FeatureSync.sync(new List<Passport__c>{newPassport}, new Map<Id, Passport__c>{passport.Id => oldPassport});
    }

    private static Case getCase(Id caseId) {
        return [SELECT Status, DMT_Closed_By_Passport__c FROM Case WHERE Id = :caseId];
    }

    @isTest
    static void testLineFeatureDisappears() {
        TriggerBypass.setBypass();
        Passport__c passport = getLinePassport();
        Case case1 = createCase(passport.DMT_Line__c, null, '10', DMT_Constants.PENDING);
        Task task1 = createTask(case1.Id, 'In Progress');

        Test.startTest();
        runSync(passport, buildJson(new List<String>{'10', '11'}), buildJson(new List<String>{'11'}));
        Test.stopTest();

        Case caseAfter = getCase(case1.Id);
        Assert.areEqual(DMT_Constants.FINISHED, caseAfter.Status, 'Case must be finished when its feature disappears.');
        Assert.isTrue(caseAfter.DMT_Closed_By_Passport__c, 'Case must be flagged as closed by Passport.');
        Assert.areEqual(DMT_Constants.CANCELLED, [SELECT Status FROM Task WHERE Id = :task1.Id].Status, 'Active task must be cancelled.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testOpportunityFeatureDisappears() {
        TriggerBypass.setBypass();
        Passport__c passport = getOppPassport();
        Case case1 = createCase(null, passport.Opportunity__c, '10', DMT_Constants.PENDING);
        Task task1 = createTask(case1.Id, 'In Progress');

        Test.startTest();
        runSync(passport, buildJson(new List<String>{'10', '11'}), buildJson(new List<String>{'11'}));
        Test.stopTest();

        Case caseAfter = getCase(case1.Id);
        Assert.areEqual(DMT_Constants.FINISHED, caseAfter.Status, 'Opportunity case must be finished when its feature disappears.');
        Assert.isTrue(caseAfter.DMT_Closed_By_Passport__c, 'Opportunity case must be flagged as closed by Passport.');
        Assert.areEqual(DMT_Constants.CANCELLED, [SELECT Status FROM Task WHERE Id = :task1.Id].Status, 'Active task must be cancelled.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testFeatureReappears() {
        TriggerBypass.setBypass();
        Passport__c passport = getLinePassport();
        Case case1 = createCase(passport.DMT_Line__c, null, '10', DMT_Constants.PENDING);
        Task task1 = createTask(case1.Id, 'In Progress');

        Test.startTest();
        runSync(passport, buildJson(new List<String>{'10', '11'}), buildJson(new List<String>{'11'}));
        runSync(passport, buildJson(new List<String>{'11'}), buildJson(new List<String>{'10', '11'}));
        Test.stopTest();

        Case caseAfter = getCase(case1.Id);
        Assert.areEqual(DMT_Constants.PENDING, caseAfter.Status, 'Same case must be reopened when the feature comes back.');
        Assert.isFalse(caseAfter.DMT_Closed_By_Passport__c, 'Flag must be cleared after reopening.');

        List<Task> newTasks = [SELECT OwnerId, Subject FROM Task WHERE WhatId = :case1.Id AND Status = :DMT_Constants.NOTSTARTED];
        Assert.areEqual(1, newTasks.size(), 'Last cancelled task must be recreated once as Not Started.');
        Assert.areEqual(getQueueId(), newTasks[0].OwnerId, 'Recreated task must keep the owner.');
        Assert.areEqual('Step 4507', newTasks[0].Subject, 'Recreated task must keep the subject.');
        Assert.areEqual(DMT_Constants.CANCELLED, [SELECT Status FROM Task WHERE Id = :task1.Id].Status, 'Original task must stay cancelled.');
        Assert.areEqual(1, [SELECT COUNT() FROM Case WHERE DMT_Line__c = :passport.DMT_Line__c AND DMT_Feature_Id__c = '10'], 'No duplicated case for the same feature.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testFeatureStaysNoChanges() {
        TriggerBypass.setBypass();
        Passport__c passport = getLinePassport();
        Case case1 = createCase(passport.DMT_Line__c, null, '10', DMT_Constants.PENDING);
        Task task1 = createTask(case1.Id, 'In Progress');
        String oldJson = buildJson(new List<String>{'10', '11'});
        String newJson = oldJson.replace('Feature ', 'Feature renamed ');

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        runSync(passport, oldJson, oldJson);
        Integer queriesSameJson = Limits.getQueries() - queriesBefore;

        queriesBefore = Limits.getQueries();
        runSync(passport, oldJson, newJson);
        Integer queriesSameFeatures = Limits.getQueries() - queriesBefore;

        queriesBefore = Limits.getQueries();
        runSync(passport, buildJson(new List<String>{'10', '11'}), buildJson(new List<String>{'10', '11', '12'}));
        Integer queriesNoAffectedCases = Limits.getQueries() - queriesBefore;
        Test.stopTest();

        Assert.areEqual(0, queriesSameJson, 'No SOQL expected when the passport JSON is not updated.');
        Assert.areEqual(1, queriesSameFeatures, 'Only the case query expected when the feature ids do not change.');
        Assert.areEqual(1, queriesNoAffectedCases, 'Only the case query expected when no case is affected.');
        Assert.areEqual(DMT_Constants.PENDING, getCase(case1.Id).Status, 'Case must not change while its feature keeps coming.');
        Assert.areEqual('In Progress', [SELECT Status FROM Task WHERE Id = :task1.Id].Status, 'Task must not change while its feature keeps coming.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testCaseOfMissingFeatureIsClosedOnNextResponse() {
        TriggerBypass.setBypass();
        Passport__c passport = getLinePassport();
        Case case1 = createCase(passport.DMT_Line__c, null, '10', DMT_Constants.PENDING);
        Task task1 = createTask(case1.Id, 'In Progress');
        String oldJson = buildJson(new List<String>{'11'});
        String newJson = oldJson.replace('Feature ', 'Feature renamed ');

        Test.startTest();
        runSync(passport, oldJson, newJson);
        Test.stopTest();

        Assert.areEqual(DMT_Constants.FINISHED, getCase(case1.Id).Status, 'A case whose feature was already missing must be finished on the next passport response.');
        Assert.areEqual(DMT_Constants.CANCELLED, [SELECT Status FROM Task WHERE Id = :task1.Id].Status, 'Its active task must be cancelled.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testSeveralFeaturesOnlyOneDisappears() {
        TriggerBypass.setBypass();
        Passport__c passport = getLinePassport();
        Case caseGone = createCase(passport.DMT_Line__c, null, '10', DMT_Constants.PENDING);
        Case caseKept = createCase(passport.DMT_Line__c, null, '11', DMT_Constants.PENDING);
        Task taskGone = createTask(caseGone.Id, 'In Progress');
        Task taskKept = createTask(caseKept.Id, 'In Progress');

        Test.startTest();
        runSync(passport, buildJson(new List<String>{'10', '11'}), buildJson(new List<String>{'11'}));
        Test.stopTest();

        Assert.areEqual(DMT_Constants.FINISHED, getCase(caseGone.Id).Status, 'Case of the missing feature must be finished.');
        Assert.areEqual(DMT_Constants.CANCELLED, [SELECT Status FROM Task WHERE Id = :taskGone.Id].Status, 'Task of the missing feature must be cancelled.');
        Assert.areEqual(DMT_Constants.PENDING, getCase(caseKept.Id).Status, 'Case of the remaining feature must not change.');
        Assert.areEqual('In Progress', [SELECT Status FROM Task WHERE Id = :taskKept.Id].Status, 'Task of the remaining feature must not change.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testBulkLinesAndOpportunity() {
        TriggerBypass.setBypass();
        List<DMT_Line__c> lines = new List<DMT_Line__c>();
        for (Integer i = 0; i < 5; i++) {
            lines.add(new DMT_Line__c(Line_Id__c = LINE_EXT_ID + '-B' + i, Status__c = DMT_Constants.APPROVAL));
        }
        insert lines;

        Passport__c oppPassport = getOppPassport();
        List<Passport__c> passports = new List<Passport__c>();
        List<Case> cases = new List<Case>{new Case(RecordTypeId = CASE_RT_ID, opportunity_id__c = oppPassport.Opportunity__c, DMT_Feature_Id__c = '10',
                                                   DMT_Passport_Sanction__c = 'passport', Status = DMT_Constants.PENDING, OwnerId = getQueueId(), Subject = 'Test 4507')};
        for (DMT_Line__c line : lines) {
            passports.add(new Passport__c(DMT_Line__c = line.Id));
            cases.add(new Case(RecordTypeId = CASE_RT_ID, DMT_Line__c = line.Id, DMT_Feature_Id__c = '10', DMT_Passport_Sanction__c = 'passport',
                               Status = DMT_Constants.PENDING, OwnerId = getQueueId(), Subject = 'Test 4507'));
        }
        insert passports;
        insert cases;
        passports.add(oppPassport);

        List<Task> tasks = new List<Task>();
        for (Case c : cases) {
            tasks.add(new Task(WhatId = c.Id, Status = 'In Progress', Subject = 'Step 4507', OwnerId = getQueueId(), RecordTypeId = TASK_RT_ID));
        }
        insert tasks;

        List<Passport__c> newPassports = new List<Passport__c>();
        Map<Id, Passport__c> oldMap = new Map<Id, Passport__c>();
        for (Passport__c p : passports) {
            oldMap.put(p.Id, new Passport__c(Id = p.Id, DMT_Line__c = p.DMT_Line__c, Opportunity__c = p.Opportunity__c, DMT_Passport_Save__c = buildJson(new List<String>{'10', '11'})));
            newPassports.add(new Passport__c(Id = p.Id, DMT_Line__c = p.DMT_Line__c, Opportunity__c = p.Opportunity__c, DMT_Passport_Save__c = buildJson(new List<String>{'11'})));
        }

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        DMT_Passport_FeatureSync.sync(newPassports, oldMap);
        System.debug('CIBGLOBALD-4507 queries used in bulk sync (including automations): ' + (Limits.getQueries() - queriesBefore));
        Test.stopTest();

        Assert.areEqual(6, [SELECT COUNT() FROM Case WHERE Id IN :cases AND Status = :DMT_Constants.FINISHED AND DMT_Closed_By_Passport__c = true], 'All cases must be finished in bulk.');
        Assert.areEqual(6, [SELECT COUNT() FROM Task WHERE Id IN :tasks AND Status = :DMT_Constants.CANCELLED], 'All tasks must be cancelled in bulk.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testCaseFinishedByOtherReasonIsNotTouched() {
        TriggerBypass.setBypass();
        Passport__c passport = getLinePassport();
        Case case1 = createCase(passport.DMT_Line__c, null, '10', DMT_Constants.FINISHED);
        Task task1 = createTask(case1.Id, DMT_Constants.CANCELLED);

        Test.startTest();
        runSync(passport, buildJson(new List<String>{'10', '11'}), buildJson(new List<String>{'11'}));
        Case caseAfterDisappear = getCase(case1.Id);
        runSync(passport, buildJson(new List<String>{'11'}), buildJson(new List<String>{'10', '11'}));
        Test.stopTest();

        Assert.isFalse(caseAfterDisappear.DMT_Closed_By_Passport__c, 'A case already finished must not be flagged.');
        Assert.areEqual(DMT_Constants.FINISHED, getCase(case1.Id).Status, 'A case finished for another reason must not be reopened.');
        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE WhatId = :case1.Id], 'No task must be recreated for a case not closed by this logic.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testOpportunityCaseIgnoredBySanctionLinePassport() {
        TriggerBypass.setBypass();
        Passport__c linePassport = getLinePassport();
        Passport__c oppPassport = getOppPassport();
        Case case1 = createCase(linePassport.DMT_Line__c, oppPassport.Opportunity__c, '10', DMT_Constants.PENDING);
        Task task1 = createTask(case1.Id, 'In Progress');

        Test.startTest();
        runSync(linePassport, buildJson(new List<String>{'98'}), buildJson(new List<String>{'99'}));
        Test.stopTest();

        Assert.areEqual(DMT_Constants.PENDING, getCase(case1.Id).Status, 'A case with opportunity must not be compared against the line passport.');
        Assert.areEqual('In Progress', [SELECT Status FROM Task WHERE Id = :task1.Id].Status, 'Task must not change.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testPassportWithoutFeaturesDoesNothing() {
        TriggerBypass.setBypass();
        Passport__c passport = getLinePassport();
        Case case1 = createCase(passport.DMT_Line__c, null, '10', DMT_Constants.PENDING);
        String oldJson = buildJson(new List<String>{'10', '11'});

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        runSync(passport, oldJson, '{"data":{"features":[]}}');
        runSync(passport, oldJson, '{"data":{}}');
        runSync(passport, oldJson, 'not a json');
        runSync(passport, oldJson, '');
        Integer queriesUsed = Limits.getQueries() - queriesBefore;
        Test.stopTest();

        Assert.areEqual(0, queriesUsed, 'No SOQL expected when the passport has no features.');
        Assert.areEqual(DMT_Constants.PENDING, getCase(case1.Id).Status, 'Case must not change when the passport has no features.');
        Assert.areEqual(new Set<String>{'10', '11'}, DMT_Passport_FeatureSync.extractFeatureIds('{"data":{"features":[{"id":10},{"id":"11"},{"name":"no id"}]}}'), 'Numeric and text ids must be read as text.');
        Assert.isTrue(DMT_Passport_FeatureSync.extractFeatureIds('[1,2]').isEmpty(), 'Unexpected JSON root must return no features.');
        TriggerBypass.removeBypass();
    }

    @isTest
    static void testSyncFromPassportTrigger() {
        TriggerBypass.setBypass();
        Passport__c passport = getLinePassport();
        Case case1 = createCase(passport.DMT_Line__c, null, '10', DMT_Constants.PENDING);
        Task task1 = createTask(case1.Id, 'In Progress');
        TriggerBypass.removeBypass();

        Test.startTest();
        passport = new Passport__c(DMT_Line__c = passport.DMT_Line__c, DMT_Passport_Save__c = buildJson(new List<String>{'10', '11'}));
        insert passport;
        passport.DMT_Passport_Save__c = buildJson(new List<String>{'11'});
        update passport;
        Test.stopTest();

        Assert.areEqual(DMT_Constants.FINISHED, getCase(case1.Id).Status, 'Passport update must finish the case of the missing feature.');
        Assert.areEqual(DMT_Constants.CANCELLED, [SELECT Status FROM Task WHERE Id = :task1.Id].Status, 'Passport update must cancel the active task.');
    }

    private static String buildApprovalJson(String featureId) {
        Map<String, Object> approver = new Map<String, Object>{'id' => 'TEST4507', 'name' => 'Approver 4507'};
        Map<String, Object> step = new Map<String, Object>{'id' => '6', 'name' => 'Approval step', 'approvers' => new List<Object>{approver}};
        Map<String, Object> feature = new Map<String, Object>{'id' => featureId, 'name' => 'Feature ' + featureId, 'passportSanction' => 'approval',
                                                              'orderNumber' => 1, 'tasks' => new List<Object>{step}};
        return JSON.serialize(new Map<String, Object>{'data' => new Map<String, Object>{'opportunityId' => 'TEST-4507', 'features' => new List<Object>{feature}}});
    }

    private static Case getCaseForNextApproval(Id caseId) {
        return [SELECT Id, Status, RecordTypeId, IsClosed, DMT_Closed_By_Passport__c, DMT_Passport_Sanction__c, DMT_Line__c, opportunity_id__c, DMT_LineOpportunity__c, DMT_Feature_Id__c
                FROM Case WHERE Id = :caseId];
    }

    @isTest
    static void testCaseClosedByPassportDoesNotStartNextApproval() {
        TriggerBypass.setBypass();
        Passport__c passport = getOppPassport();
        update new Opportunity(Id = passport.Opportunity__c, StageName = DMT_Constants.APPROVAL);
        update new Passport__c(Id = passport.Id, DMT_Passport_Save__c = buildApprovalJson('15'));

        Case case1 = new Case(RecordTypeId = CASE_RT_ID, opportunity_id__c = passport.Opportunity__c, DMT_Feature_Id__c = '15', DMT_Passport_Sanction__c = DMT_Constants.APPROVAL,
                              Status = DMT_Constants.PENDING, OwnerId = getQueueId(), Subject = 'Test 4507');
        insert case1;
        insert new Task(WhatId = case1.Id, Status = DMT_Constants.FINISHED, DMT_Step_Result__c = 'Yes', Subject = 'Step 4507', OwnerId = getQueueId(), RecordTypeId = TASK_RT_ID);
        Case oldCase = getCaseForNextApproval(case1.Id);

        Test.startTest();
        runSync(passport, buildApprovalJson('15'), buildApprovalJson('99'));
        Case newCase = getCaseForNextApproval(case1.Id);
        Integer queriesBefore = Limits.getQueries();
        DMT_Case_Steps_Controller.processStartNextCaseApproval(newCase, oldCase);
        Integer queriesUsed = Limits.getQueries() - queriesBefore;
        Test.stopTest();

        Assert.areEqual(DMT_Constants.FINISHED, newCase.Status, 'Case must be finished when its feature disappears.');
        Assert.isTrue(newCase.DMT_Closed_By_Passport__c, 'Case must be flagged as closed by Passport.');
        Assert.areEqual(1, queriesUsed, 'Only the task query is expected: the next approval must not be evaluated for a case closed by Passport.');
        Assert.areEqual(DMT_Constants.APPROVAL, [SELECT StageName FROM Opportunity WHERE Id = :passport.Opportunity__c].StageName,
                        'Opportunity must not move to Ready to close when the case was closed by Passport.');
        TriggerBypass.removeBypass();
    }
}