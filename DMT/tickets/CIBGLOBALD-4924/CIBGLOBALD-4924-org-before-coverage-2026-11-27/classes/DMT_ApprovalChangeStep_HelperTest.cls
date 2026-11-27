/**
 * @description CIBGLOBALD-4117: direct unit coverage for DMT_ApprovalChangeStep_Helper's shared
 * comparison rule. Before this class the helper had no dedicated tests at all - rowsDiffer,
 * createResetTask and createResetCase were only exercised transitively through the two trigger
 * handlers' end-to-end tests, which means a regression in the row-matching rule itself would have
 * surfaced as a confusing trigger-level failure rather than a precise one.
 * rowsDiffer is a pure function over JSON-primitive-shaped maps, so these need no DML and no
 * trigger setup - they pin the exact rule the whole framework depends on.
 **/
@IsTest
public with sharing class DMT_ApprovalChangeStep_HelperTest {

    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();
    private static final List<String> TRACKED_FIELDS = new List<String>{ 'Alpha_Code_Client__c', 'DMT_ClientRating__c' };
    private static Id queueId;

    private static Id getQueueId() {
        if (queueId == null) {
            queueId = [SELECT Id FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1].Id;
        }
        return queueId;
    }

      @TestSetup
    static void setupTestData() {
        DMT_UTIL.createCaseRecord(
            new Map<Schema.SObjectField, Object>{
                Case.OwnerId => UserInfo.getUserId(),
                Case.DMT_Passport_Sanction__c => 'approval'
            }
        );
    }


    // CIBGLOBALD-4117 - found live 2026-09-25: DMT_NBC_AssessmentRenderer declared
    // 'DMT_equator_Principles_Category__c' while DMT_OppApprovalProcessDataRenderer independently
    // declared 'DMT_Equator_Principles_Category__c' for the same DMT_Opportunity_Client__c field.
    // DMT_SnapshotChildComparator unions every component's fields per object key into a Set<String>,
    // which is case-sensitive even though SOQL field names are not - so both spellings survived the
    // union, and the resulting dynamic SELECT threw 'duplicate field selected'. The outer try/catch
    // in DMT_ApprovalChangeStep_Helper.restartStaleApprovalTasks swallowed it silently, so every
    // Opportunity restart check quietly stopped working - no error surfaced anywhere except the
    // async exception log. This test unions every registered tracked component's
    // getTrackedFieldsByObject() output per object key, the same way the real comparator does, and
    // fails loudly the moment two components spell the same field differently.
    @IsTest
    static void testNoCaseOnlyDuplicateFieldNamesAcrossSharedChildSections() {
        SObject shell = new Opportunity();
        Map<String, Map<String, String>> canonicalCasingByObjectThenLowerField = new Map<String, Map<String, String>>();

        for (String componentName : DMT_RendererFactory.getTrackedComponentNames()) {
            Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject(componentName, shell);
            for (String objectApiName : fieldsByObject.keySet()) {
                if (!canonicalCasingByObjectThenLowerField.containsKey(objectApiName)) {
                    canonicalCasingByObjectThenLowerField.put(objectApiName, new Map<String, String>());
                }
                Map<String, String> canonicalCasingByLowerField = canonicalCasingByObjectThenLowerField.get(objectApiName);
                for (String fieldName : fieldsByObject.get(objectApiName)) {
                    String lowerField = fieldName.toLowerCase();
                    String canonicalCasing = canonicalCasingByLowerField.get(lowerField);
                    Assert.isTrue(
                        canonicalCasing == null || canonicalCasing == fieldName,
                        'Case-only duplicate for ' + objectApiName + '.' + fieldName + ': component "'
                            + componentName + '" spells it "' + fieldName + '" but another component already '
                            + 'declared it as "' + canonicalCasing + '" - these must match exactly or the '
                            + 'dynamic SOQL built from their union throws "duplicate field selected".'
                    );
                    canonicalCasingByLowerField.put(lowerField, fieldName);
                }
            }
        }
    }

    // Shaped exactly like a deserialized snapshot section: row Id -> field map.
    private static Map<String, Object> buildRows(String recordId, String alphaCode, String rating) {
        return new Map<String, Object>{
            recordId => new Map<String, Object>{
                'Alpha_Code_Client__c' => alphaCode,
                'DMT_ClientRating__c' => rating
            }
        };
    }

    @IsTest
    static void testIdenticalRowsDoNotDiffer() {
        Map<String, Object> frozen = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        Map<String, Object> live = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        Assert.isFalse(
            DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, live, TRACKED_FIELDS),
            'Identical rows must not be reported as different.'
        );
    }

    // CIBGLOBALD-4811 - a multi-select picklist (Opportunity.DES_Countries__c) is a set: another order is not a
    // change, another selection is; on a text field the order still counts.
    @IsTest
    static void testMultiPicklistOrderDoesNotDiffer() {
        List<String> fields = new List<String>{ 'DES_Countries__c', 'Name' };
        Map<String, Object> frozen = new Map<String, Object>{ '006000000000001' => new Map<String, Object>{ 'DES_Countries__c' => 'ES;PT', 'Name' => 'A;B' } };
        Map<String, Object> reordered = new Map<String, Object>{ '006000000000001' => new Map<String, Object>{ 'DES_Countries__c' => 'PT;ES', 'Name' => 'A;B' } };
        Map<String, Object> reselected = new Map<String, Object>{ '006000000000001' => new Map<String, Object>{ 'DES_Countries__c' => 'ES', 'Name' => 'A;B' } };
        Map<String, Object> textReordered = new Map<String, Object>{ '006000000000001' => new Map<String, Object>{ 'DES_Countries__c' => 'ES;PT', 'Name' => 'B;A' } };

        Assert.isFalse(DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, reordered, fields, Opportunity.SObjectType), 'The same countries in another order are not a change');
        Assert.isTrue(DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, reselected, fields, Opportunity.SObjectType), 'A removed country is a change');
        Assert.isTrue(DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, textReordered, fields, Opportunity.SObjectType), 'On a text field the order is part of the value');
        Assert.isTrue(DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, reordered, fields), 'Without the row object the value is compared as text');
    }

    @IsTest
    static void testChangedTrackedFieldDiffers() {
        Map<String, Object> frozen = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        Map<String, Object> live = buildRows('a0A000000000001', 'ES0182000170441', 'BBB');
        Assert.isTrue(
            DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, live, TRACKED_FIELDS),
            'A changed tracked field must be reported as different.'
        );
    }

    @IsTest
    static void testChangedUntrackedFieldDoesNotDiffer() {
        Map<String, Object> frozen = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        Map<String, Object> live = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        ((Map<String, Object>) live.get('a0A000000000001')).put('DMT_Amount__c', 999);
        Assert.isFalse(
            DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, live, TRACKED_FIELDS),
            'Only the tracked fields may be compared - an untracked field changing must not trigger a restart.'
        );
    }

    @IsTest
    static void testAddedRowDiffers() {
        Map<String, Object> frozen = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        Map<String, Object> live = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        live.putAll(buildRows('a0A000000000002', 'ES0182000170442', 'AA'));
        Assert.isTrue(
            DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, live, TRACKED_FIELDS),
            'A row added since the snapshot must be reported as different, via the size/Id-set mismatch branch.'
        );
    }

    @IsTest
    static void testRemovedRowDiffers() {
        Map<String, Object> frozen = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        frozen.putAll(buildRows('a0A000000000002', 'ES0182000170442', 'AA'));
        Map<String, Object> live = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        Assert.isTrue(
            DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, live, TRACKED_FIELDS),
            'A row removed since the snapshot must be reported as different, via the size/Id-set mismatch branch.'
        );
    }

    @IsTest
    static void testSwappedRowIdsOfSameCountDiffer() {
        // Same number of rows and identical field values, but a different row entirely - the Id-set
        // check is what catches this; a size-only check would miss it.
        Map<String, Object> frozen = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        Map<String, Object> live = buildRows('a0A000000000002', 'ES0182000170441', 'AA');
        Assert.isTrue(
            DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, live, TRACKED_FIELDS),
            'A replaced row of the same count must be reported as different.'
        );
    }

    @IsTest
    static void testNullLiveRowsAgainstPopulatedSnapshotDiffers() {
        Map<String, Object> frozen = buildRows('a0A000000000001', 'ES0182000170441', 'AA');
        Assert.isTrue(
            DMT_ApprovalChangeStep_Helper.rowsDiffer(frozen, null, TRACKED_FIELDS),
            'Null live rows against a populated snapshot means every row was removed - different.'
        );
    }

    @IsTest
    static void testNullLiveRowsAgainstEmptySnapshotDoesNotDiffer() {
        Assert.isFalse(
            DMT_ApprovalChangeStep_Helper.rowsDiffer(new Map<String, Object>(), null, TRACKED_FIELDS),
            'No rows on either side is not a difference, and must not throw on the null.'
        );
    }

    @IsTest
    static void testCreateResetTaskPreservesRecordTypeAndResetsStatus() {
         Case c = [SELECT Id FROM Case LIMIT 1];
        Id approvalStepRTId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
        Task source = DMT_UTIL.buildTask(getQueueId(), c.id,
            new Map<Schema.SObjectField, Object>{
                Task.RecordTypeId => approvalStepRTId,
                Task.Status => 'Completed',
                Task.Subject => 'Original subject'
            }
        );

        Task reset = DMT_ApprovalChangeStep_Helper.createResetTask(source);

        // CIBGLOBALD-4117: guards the live-testing bug where the replacement task silently took a
        // default record type, making it invisible to DMT_Case_Steps_Controller's
        // RecordType-filtered queries and so breaking the passport traffic light.
        Assert.areEqual(approvalStepRTId, reset.RecordTypeId, 'Replacement task must keep the source DMT_Step_Approval record type.');
        Assert.areEqual(DMT_Constants.NOTSTARTED, reset.Status, 'Replacement task must start Not Started.');
        Assert.isNull(reset.DMT_ViewStatusAtClose__c, 'Replacement task must not carry the old snapshot link.');
    }

    @IsTest
    static void testCreateResetCaseReopensCase() {
        Id caseId = '500000000000001AAA';
        Id ownerId = UserInfo.getUserId();

        Case reset = DMT_ApprovalChangeStep_Helper.createResetCase(caseId, ownerId);

        Assert.areEqual(caseId, reset.Id, 'Reset case must target the same Case.');
        Assert.areEqual(ownerId, reset.OwnerId, 'Reset case must be handed back to the approver.');
        Assert.areEqual(DMT_Constants.PENDING, reset.Status, 'Reset case must go back to Pending.');
        Assert.isFalse(reset.DMT_IsInRevision__c, 'Reset case must clear the in-revision flag.');
    }

    // CIBGLOBALD-4117 - found live 2026-09-29: a Case with several of its tasks independently found
    // stale at once got one replacement Task created PER cancelled task instead of a single
    // replacement for the whole Case, flooding it with duplicate Not Started tasks. Confirms every
    // stale task passed in is cancelled, but only the Case's oldest stale task gets cloned.
    @IsTest
    static void testRestartTasksForRecordCreatesOnlyOneReplacementPerCase() {
        Id caseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
        Id taskRTId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();

        Case approvalCase = DMT_UTIL.createCaseRecord(
            new Map<Schema.SObjectField, Object>{
                Case.OwnerId => getQueueId(),
                Case.RecordTypeId => caseRTId,
                Case.Status => 'Pending',
                Case.Subject => 'Test'
            }
        );

        List<Task> createdTasks = new List<Task>{
            DMT_UTIL.createTaskRecord(getQueueId(), approvalCase.Id,
                new Map<Schema.SObjectField, Object>{
                    Task.RecordTypeId => taskRTId,
                    Task.Status => 'Completed',
                    Task.Subject => 'Older'
                }
            ),
            DMT_UTIL.createTaskRecord(getQueueId(), approvalCase.Id,
                new Map<Schema.SObjectField, Object>{
                    Task.RecordTypeId => taskRTId,
                    Task.Status => 'Completed',
                    Task.Subject => 'Newer'
                }
            )
        };
        Task olderTask = createdTasks[0];
        Task newerTask = createdTasks[1];
        Test.setCreatedDate(olderTask.Id, DateTime.now().addDays(-2));
        Test.setCreatedDate(newerTask.Id, DateTime.now().addDays(-1));

        List<Task> tasksToRestart = [
            SELECT Id, WhatId, OwnerId, RecordTypeId, DMT_Task_Type__c, CreatedDate
            FROM Task WHERE Id IN (:olderTask.Id, :newerTask.Id)
        ];

        Test.startTest();
        DMT_ApprovalChangeStep_Helper.restartTasksForRecord(approvalCase.Id, tasksToRestart);
        Test.stopTest();

        List<Task> allTasksNow = [SELECT Id, Status, Subject FROM Task WHERE WhatId = :approvalCase.Id];
        Integer cancelledCount = 0;
        List<Task> replacementTasks = new List<Task>();
        for (Task t : allTasksNow) {
            if (t.Status == DMT_Constants.CANCELLED) {
                cancelledCount++;
            } else if (t.Status == DMT_Constants.NOTSTARTED) {
                replacementTasks.add(t);
            }
        }
        Assert.areEqual(2, cancelledCount, 'Every stale task for the Case must be cancelled.');
        Assert.areEqual(1, replacementTasks.size(), 'Exactly one replacement task must be created for the Case, not one per cancelled task.');
        Assert.areEqual('Task', replacementTasks[0].Subject, 'The single replacement must come from createResetTask, cloned from the oldest stale task.');
    }

    /**
     * CIBGLOBALD-4924 - a multi-step workflow restarted with two stale tasks of different approver queues: the
     * replacement is cloned from the oldest (step 1) task and the Case must be handed to that same queue, not
     * to the queue of the later step it was parked on.
     */
    @IsTest
    static void testRestartTasksForRecordSetsCaseOwnerToReplacementOwner() {
        Id caseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
        Id taskRTId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
        Id stepOneQueueId = getQueueId();
        Id stepTwoQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'DMT_Approvers2' LIMIT 1].Id;

        Case approvalCase = DMT_UTIL.createCaseRecord(
            new Map<Schema.SObjectField, Object>{
                Case.OwnerId => stepTwoQueueId,
                Case.RecordTypeId => caseRTId,
                Case.Status => 'Pending',
                Case.Subject => 'Test'
            }
        );

        List<Task> tasksToInsert = new List<Task>{
            DMT_UTIL.buildTask(stepOneQueueId, approvalCase.Id,
                new Map<Schema.SObjectField, Object>{
                    Task.RecordTypeId => taskRTId,
                    Task.Status => 'Completed',
                    Task.Subject => 'Step 1'
                }
            ),
            DMT_UTIL.buildTask(stepTwoQueueId, approvalCase.Id,
                new Map<Schema.SObjectField, Object>{
                    Task.RecordTypeId => taskRTId,
                    Task.Status => 'Completed',
                    Task.Subject => 'Step 2'
                }
            )
        };
        insert tasksToInsert;
        Test.setCreatedDate(tasksToInsert[0].Id, DateTime.now().addDays(-2));
        Test.setCreatedDate(tasksToInsert[1].Id, DateTime.now().addDays(-1));

        List<Task> tasksToRestart = [
            SELECT Id, WhatId, OwnerId, RecordTypeId, DMT_Task_Type__c, CreatedDate
            FROM Task WHERE Id IN (:tasksToInsert[0].Id, :tasksToInsert[1].Id)
        ];

        Test.startTest();
        DMT_ApprovalChangeStep_Helper.restartTasksForRecord(approvalCase.Id, tasksToRestart);
        Test.stopTest();

        List<Task> replacementTasks = [SELECT OwnerId FROM Task WHERE WhatId = :approvalCase.Id AND Status = :DMT_Constants.NOTSTARTED];
        Case reopenedCase = [SELECT OwnerId, Status FROM Case WHERE Id = :approvalCase.Id];
        Assert.areEqual(1, replacementTasks.size(), 'Exactly one replacement task must be created for the Case.');
        Assert.areEqual(stepOneQueueId, replacementTasks[0].OwnerId, 'The replacement must be cloned from the step 1 task.');
        Assert.areEqual(replacementTasks[0].OwnerId, reopenedCase.OwnerId, 'The reopened Case must have the same approver as its open replacement task.');
        Assert.areEqual(DMT_Constants.PENDING, reopenedCase.Status, 'The reopened Case must be Pending.');
    }

    // CIBGLOBALD-4800 - the same task list restarted twice (an async restart queued twice before the first
    // run) must leave exactly one replacement: the second run finds the tasks already cancelled.
    @IsTest
    static void testRestartTasksForRecordTwiceCreatesOneReplacement() {
        Id caseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
        Id taskRTId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();

        Case approvalCase = DMT_UTIL.createCaseRecord(
            new Map<Schema.SObjectField, Object>{
                Case.OwnerId => getQueueId(),
                Case.RecordTypeId => caseRTId,
                Case.Status => 'Pending',
                Case.Subject => 'Test'
            }
        );
        Task staleTask = DMT_UTIL.createTaskRecord(getQueueId(), approvalCase.Id,
            new Map<Schema.SObjectField, Object>{
                Task.RecordTypeId => taskRTId,
                Task.Status => 'Completed',
                Task.Subject => 'Stale'
            }
        );
        List<Task> tasksToRestart = [
            SELECT Id, WhatId, OwnerId, RecordTypeId, DMT_Task_Type__c, CreatedDate
            FROM Task WHERE Id = :staleTask.Id
        ];

        Test.startTest();
        DMT_ApprovalChangeStep_Helper.restartTasksForRecord(approvalCase.Id, tasksToRestart);
        DMT_ApprovalChangeStep_Helper.restartTasksForRecord(approvalCase.Id, tasksToRestart);
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE WhatId = :approvalCase.Id AND Status = :DMT_Constants.NOTSTARTED],
            'Restarting the same tasks twice must leave exactly one replacement task.');
        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE WhatId = :approvalCase.Id AND Status = :DMT_Constants.CANCELLED],
            'The stale task must be cancelled once.');
    }

    // CIBGLOBALD-4800 - two records (the async path, at or above SYNC_RESTART_RECORD_LIMIT) dispatched twice in
    // one transaction, like two saves while parked in Ready to close: each Case still gets one replacement.
    @IsTest
    static void testDispatchRestartsTwiceCreatesOneReplacementPerCase() {
        Id caseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
        Id taskRTId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
        Map<Schema.SObjectField, Object> caseOverrides = new Map<Schema.SObjectField, Object>{
            Case.RecordTypeId => caseRTId,
            Case.Status => 'Pending',
            Case.Subject => 'Test'
        };

        Map<Schema.SObjectField, Object> firstCaseOverrides = new Map<Schema.SObjectField, Object>(caseOverrides);
        firstCaseOverrides.put(Case.OwnerId, getQueueId());
        Map<Schema.SObjectField, Object> secondCaseOverrides = new Map<Schema.SObjectField, Object>(caseOverrides);
        secondCaseOverrides.put(Case.OwnerId, getQueueId());

        List<Case> approvalCases = new List<Case>{
            DMT_UTIL.createCaseRecord(firstCaseOverrides),
            DMT_UTIL.createCaseRecord(secondCaseOverrides)
        };

        Map<Schema.SObjectField, Object> taskOverrides = new Map<Schema.SObjectField, Object>{
            Task.RecordTypeId => taskRTId,
            Task.Status => 'Completed',
            Task.Subject => 'Stale'
        };
        List<Task> staleTasks = new List<Task>{
            DMT_UTIL.createTaskRecord(getQueueId(), approvalCases[0].Id, taskOverrides),
            DMT_UTIL.createTaskRecord(getQueueId(), approvalCases[1].Id, taskOverrides)
        };

        // recordId only keys the payload; restartTasksForRecord works from the tasks themselves.
        Map<Id, List<Task>> tasksByRecordId = new Map<Id, List<Task>>();
        for (Task t : [SELECT Id, WhatId, OwnerId, RecordTypeId, DMT_Task_Type__c, CreatedDate FROM Task WHERE Id IN :staleTasks]) {
            tasksByRecordId.put(t.WhatId, new List<Task>{ t });
        }

        Test.startTest();
        DMT_ApprovalChangeStep_Helper.dispatchRestarts(tasksByRecordId);
        DMT_ApprovalChangeStep_Helper.dispatchRestarts(tasksByRecordId);
        DMT_AsyncOrchestrator.flush();
        Test.stopTest();

        Map<Id, Integer> replacementsByCaseId = new Map<Id, Integer>();
        for (Task replacement : [SELECT WhatId FROM Task WHERE WhatId IN :approvalCases AND Status = :DMT_Constants.NOTSTARTED]) {
            Integer count = replacementsByCaseId.get(replacement.WhatId);
            replacementsByCaseId.put(replacement.WhatId, count == null ? 1 : count + 1);
        }
        for (Case approvalCase : approvalCases) {
            Assert.areEqual(1, replacementsByCaseId.get(approvalCase.Id), 'Each Case must get exactly one replacement task.');
        }
    }

    // CIBGLOBALD-4117: trackedComponentsForSnapshot scopes the restart watch gate's field comparison
    // to the components a task's own approver view actually had, instead of blindly checking every
    // renderer-tracked component - see the method's own header comment for the Treasury/Approval
    // Process Data bug this fixes. Pure function over an in-memory record, no DML needed.
    @IsTest
    static void testTrackedComponentsForSnapshotBlankFallsBackToFullList() {
        DMT_TaskStatusWhenCompleted__c snapshot = DMT_UTIL.buildTaskStatusWhenCompleted();
        Assert.areEqual(
            DMT_RendererFactory.getTrackedComponentNames(),
            DMT_ApprovalChangeStep_Helper.trackedComponentsForSnapshot(snapshot),
            'A snapshot frozen before this field existed must fall back to the unscoped full list, so already-open tasks keep today\'s behavior until they get a fresh freeze.'
        );
    }

    @IsTest
    static void testTrackedComponentsForSnapshotScopesToConfiguredComponents() {
        DMT_TaskStatusWhenCompleted__c snapshot = DMT_UTIL.buildTaskStatusWhenCompleted(
            new Map<Schema.SObjectField, Object>{
                DMT_TaskStatusWhenCompleted__c.DMT_TrackedComponents__c => 'Line Info;Client'
            }
        );
        Assert.areEqual(
            new List<String>{ 'Line Info', 'Client' },
            DMT_ApprovalChangeStep_Helper.trackedComponentsForSnapshot(snapshot),
            'Must return exactly the components this view actually had - not the full renderer-tracked list.'
        );
    }

    @IsTest
    static void testTrackedComponentsForSnapshotExcludesComponentsNotYetMigrated() {
        // 'Limit' is the standing example of a component no renderer tracks elsewhere in this
        // ticket's tests (DMT_RendererFactoryTest, DMT_ViewController_Test) - Products was the
        // original example here, but it is now tracked (Treasury/Opportunity).
        DMT_TaskStatusWhenCompleted__c snapshot = DMT_UTIL.buildTaskStatusWhenCompleted(
            new Map<Schema.SObjectField, Object>{
                DMT_TaskStatusWhenCompleted__c.DMT_TrackedComponents__c => 'Line Info;Limit'
            }
        );
        Assert.areEqual(
            new List<String>{ 'Line Info' },
            DMT_ApprovalChangeStep_Helper.trackedComponentsForSnapshot(snapshot),
            'A component present on the view but not tracked by any renderer (e.g. Limit) must be dropped - DMT_RendererFactory has nothing to return for it anyway.'
        );
    }

    @IsTest
    static void testTrackedComponentsForSnapshotExcludesComponentNotOnThisView() {
        // Mirrors the real Treasury Line scenario: Approval Process Data is a renderer-tracked
        // component, but a Treasury view's DMT_Items__c list never included it, so it must never be
        // checked for a task frozen against that view - regardless of it being in DMT_RendererFactory.getTrackedComponentNames().
        DMT_TaskStatusWhenCompleted__c snapshot = DMT_UTIL.buildTaskStatusWhenCompleted(
            new Map<Schema.SObjectField, Object>{
                DMT_TaskStatusWhenCompleted__c.DMT_TrackedComponents__c => 'Line Info;Client'
            }
        );
        List<String> scoped = DMT_ApprovalChangeStep_Helper.trackedComponentsForSnapshot(snapshot);
        Assert.isFalse(scoped.contains('Approval Process Data'), 'A renderer-tracked component absent from this view\'s own tracked-components list must not be checked for this snapshot.');
    }

    // CIBGLOBALD-5023 - Opportunity, approval Case and a completed task whose snapshot froze the given components
    // with an empty opportunity section. Returns the task; its Case maps to the Opportunity.
    private static Task createFrozenOpportunityTask(String trackedComponents, String snapshotJson) {
        return createFrozenOpportunityTask(trackedComponents, snapshotJson, 'approval'); // CIBGLOBALD-5023 - always reopen applies to approval Cases
    }

    // CIBGLOBALD-5023 - same fixture for a given Case type (Case.DMT_Passport_Sanction__c).
    private static Task createFrozenOpportunityTask(String trackedComponents, String snapshotJson, String caseType) {
        Opportunity opp = DMT_UTIL.createOpportunityForAccount(null);
        TriggerBypass.setBypass();
        Case approvalCase = DMT_UTIL.createCaseRecord(
            new Map<Schema.SObjectField, Object>{
                Case.OwnerId => getQueueId(),
                Case.opportunity_id__c => opp.Id,
                Case.DMT_Passport_Sanction__c => caseType,
                Case.RecordTypeId => Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId(),
                Case.Status => 'Pending',
                Case.Subject => 'Test'
            }
        );
        DMT_TaskStatusWhenCompleted__c snapshot = DMT_UTIL.createTaskStatusWhenCompletedRecord(
            new Map<Schema.SObjectField, Object>{
                DMT_TaskStatusWhenCompleted__c.Case__c => approvalCase.Id,
                DMT_TaskStatusWhenCompleted__c.DMT_ViewFieldStatusAtClose__c => snapshotJson,
                DMT_TaskStatusWhenCompleted__c.DMT_TrackedComponents__c => trackedComponents
            }
        );
        Task frozenTask = DMT_UTIL.createTaskRecord(getQueueId(), approvalCase.Id,
            new Map<Schema.SObjectField, Object>{
                Task.RecordTypeId => Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId(),
                Task.Status => 'Completed',
                Task.Subject => 'Frozen',
                Task.DMT_ViewStatusAtClose__c => snapshot.Id
            }
        );
        TriggerBypass.removeBypass();
        return frozenTask;
    }

    // CIBGLOBALD-5023 - Case Id -> Opportunity Id of the task's Case, as the trigger passes it.
    private static Map<Id, Id> caseToOpportunity(Task frozenTask) {
        Case approvalCase = [SELECT Id, opportunity_id__c FROM Case WHERE Id = :frozenTask.WhatId];
        return new Map<Id, Id>{ approvalCase.Id => approvalCase.opportunity_id__c };
    }

    // CIBGLOBALD-5023 - a frozen component with DMT_Always_Reopen__c makes the task stale with no field compared;
    // the preview (4811) gets the always-reopen marker as the reason, not the component names.
    @IsTest
    static void testAlwaysReopenComponentFrozen_PreviewGetsAlwaysReopenReason() {
        DMT_ApprovalChangeStep_Helper.alwaysReopenComponentsBySection = new Map<String, Set<String>>{
            'opportunity' => new Set<String>{ 'NBC Client' }
        };
        Task frozenTask = createFrozenOpportunityTask('Limit;NBC Client', '{"opportunity":{}}');
        Map<Id, Id> caseIdToOppId = caseToOpportunity(frozenTask);

        Test.startTest();
        Map<Id, List<String>> changesByTaskId = DMT_ApprovalChangeStep_Helper.findTasksToRestart(
            caseIdToOppId.values()[0], caseIdToOppId, 'opportunity', null, null
        );
        Test.stopTest();

        Assert.isTrue(changesByTaskId.containsKey(frozenTask.Id), 'A task that froze an always-reopen component must be reopened.');
        Assert.areEqual(new List<String>{ DMT_ApprovalChangeStep_Helper.ALWAYS_REOPEN_REASON }, changesByTaskId.get(frozenTask.Id), 'The reason must be the always-reopen marker, not the component names.');
    }

    // CIBGLOBALD-5023 - the path toast data (DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase): the feature is
    // flagged alwaysReopen and lists no field, so the toast does not show the components as changed fields.
    @IsTest
    static void testAlwaysReopenComponentFrozen_ToastFeatureFlaggedWithoutFields() {
        DMT_ApprovalChangeStep_Helper.alwaysReopenComponentsBySection = new Map<String, Set<String>>{
            'opportunity' => new Set<String>{ 'NBC Client' }
        };
        Task frozenTask = createFrozenOpportunityTask('Limit;NBC Client', '{"opportunity":{}}');
        Id oppId = caseToOpportunity(frozenTask).values()[0];

        Test.startTest();
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> features =
            DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase(oppId, 'approval'); // CIBGLOBALD-5023 - approval Case
        Test.stopTest();

        Assert.areEqual(1, features.size(), 'The always-reopen feature must be listed.');
        Assert.isTrue(features[0].alwaysReopen, 'The feature must be flagged as always reopened.');
        Assert.isTrue(features[0].changedFields.isEmpty(), 'No component may be shown as a changed field.');
    }

    // CIBGLOBALD-5023 - without an always-reopen component the task is compared as before (Limit tracks no field).
    @IsTest
    static void testNoAlwaysReopenComponentFrozen_ComparesAsBefore() {
        DMT_ApprovalChangeStep_Helper.alwaysReopenComponentsBySection = new Map<String, Set<String>>{
            'opportunity' => new Set<String>{ 'NBC Client' }
        };
        Task frozenTask = createFrozenOpportunityTask('Limit', '{"opportunity":{}}');
        Map<Id, Id> caseIdToOppId = caseToOpportunity(frozenTask);

        Test.startTest();
        Map<Id, List<String>> changesByTaskId = DMT_ApprovalChangeStep_Helper.findTasksToRestart(
            caseIdToOppId.values()[0], caseIdToOppId, 'opportunity', null, null
        );
        Test.stopTest();

        Assert.isFalse(changesByTaskId.containsKey(frozenTask.Id), 'With no always-reopen component and nothing changed, the task must stay as it is.');
    }

    // CIBGLOBALD-5023 - a snapshot without DMT_TrackedComponents__c never reopens through the flag.
    @IsTest
    static void testBlankTrackedComponents_NotForcedByFlag() {
        DMT_ApprovalChangeStep_Helper.alwaysReopenComponentsBySection = new Map<String, Set<String>>{
            'opportunity' => new Set<String>{ 'NBC Client' }
        };
        Task frozenTask = createFrozenOpportunityTask(null, '{}');
        Map<Id, Id> caseIdToOppId = caseToOpportunity(frozenTask);

        Test.startTest();
        Map<Id, List<String>> changesByTaskId = DMT_ApprovalChangeStep_Helper.findTasksToRestart(
            caseIdToOppId.values()[0], caseIdToOppId, 'opportunity', null, null
        );
        Test.stopTest();

        Assert.isFalse(changesByTaskId.containsKey(frozenTask.Id), 'The flag only applies to components listed in DMT_TrackedComponents__c.');
    }

    // CIBGLOBALD-5023 - the gate the triggers call restarts the task: cancelled, one replacement, Case Pending.
    @IsTest
    static void testAlwaysReopenComponentFrozen_GateRestartsTask() {
        DMT_ApprovalChangeStep_Helper.alwaysReopenComponentsBySection = new Map<String, Set<String>>{
            'opportunity' => new Set<String>{ 'Profitability' }
        };
        Task frozenTask = createFrozenOpportunityTask('Profitability', '{"opportunity":{}}');
        Map<Id, Id> caseIdToOppId = caseToOpportunity(frozenTask);
        // Every field, as Trigger.new carries it: the renderers read any field to decide what is tracked.
        Set<Id> oppIds = new Set<Id>(caseIdToOppId.values());
        List<Opportunity> opps = Database.query(
            'SELECT ' + String.join(new List<String>(Schema.SObjectType.Opportunity.fields.getMap().keySet()), ', ')
            + ' FROM Opportunity WHERE Id IN :oppIds'
        );

        Test.startTest();
        DMT_ApprovalChangeStep_Helper.restartStaleApprovalTasks(caseIdToOppId, opps, 'opportunity', null, 'DMT_ApprovalChangeStep_HelperTest');
        Test.stopTest();

        Assert.areEqual(DMT_Constants.CANCELLED, [SELECT Status FROM Task WHERE Id = :frozenTask.Id].Status, 'The frozen task must be cancelled.');
        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE WhatId = :frozenTask.WhatId AND Status = :DMT_Constants.NOTSTARTED], 'Exactly one replacement task must be created.');
    }

    // CIBGLOBALD-5023 - the flagged records are read per object: Opportunity view types for the opportunity section only.
    @IsTest
    static void testAlwaysReopenComponents_ReadFromViewItemsPerObject() {
        Set<String> expectedOpportunity = new Set<String>();
        Set<String> expectedLine = new Set<String>();
        for (DMT_Configurator_View_Items__mdt item : DMT_Configurator_View_Items__mdt.getAll().values()) {
            if (!item.DMT_Always_Reopen__c) {
                continue;
            }
            if (item.DMT_Type__c == 'Opportunity') {
                expectedOpportunity.add(item.DMT_Component_Item__c);
            } else if (item.DMT_Type__c != null && item.DMT_Type__c.startsWith('Line')) {
                expectedLine.add(item.DMT_Component_Item__c);
            }
        }
        Assert.areEqual(expectedOpportunity, DMT_ApprovalChangeStep_Helper.alwaysReopenComponents('opportunity'), 'Opportunity section must hold the flagged Opportunity view items.');
        Assert.areEqual(expectedLine, DMT_ApprovalChangeStep_Helper.alwaysReopenComponents('line'), 'Line section must hold only the flagged Line view items.');
    }

    // CIBGLOBALD-5023 - snapshot JSON with one Opportunity whose Description (long text area) is the given text.
    private static String opportunitySnapshotJson(Id oppId, String description) {
        return JSON.serialize(new Map<String, Object>{
            'opportunity' => new Map<String, Object>{ 'Id' => oppId, 'Name' => 'Snapshot test', 'Description' => description }
        });
    }

    // CIBGLOBALD-5023 - long text values over 255 characters are stored as a fixed-length fingerprint; short values stay.
    @IsTest
    static void testLimitSnapshotSize_FingerprintsLongTextOnly() {
        Id oppId = DMT_UTIL.createOpportunityForAccount(null).Id;
        String longText = 'x'.repeat(5000);

        Map<String, Object> stored = (Map<String, Object>) JSON.deserializeUntyped(
            DMT_TaskSnapshotService.limitSnapshotSize(opportunitySnapshotJson(oppId, longText)));
        String storedDescription = (String) ((Map<String, Object>) stored.get('opportunity')).get('Description');

        Assert.isTrue(DMT_TaskSnapshotService.isFingerprint(storedDescription), 'A long text over 255 characters must be stored as a fingerprint.');
        Assert.isTrue(storedDescription.length() < 100, 'The fingerprint must be short whatever the text length.');
        Assert.areEqual('Snapshot test', ((Map<String, Object>) stored.get('opportunity')).get('Name'), 'Other fields are stored as they are.');

        String shortJson = opportunitySnapshotJson(oppId, 'short text');
        Assert.areEqual(shortJson, DMT_TaskSnapshotService.limitSnapshotSize(shortJson), 'A snapshot with nothing to fingerprint must be stored exactly as built.');
    }

    // CIBGLOBALD-5023 - a fingerprinted value compares with the live text: same text no change, an edit at the end is a change.
    @IsTest
    static void testFingerprintComparison_DetectsEditAtTheEnd() {
        String longText = 'x'.repeat(5000);
        Map<String, Object> frozenRows = new Map<String, Object>{
            'row1' => new Map<String, Object>{ 'Description' => DMT_TaskSnapshotService.fingerprint(longText) }
        };
        List<String> tracked = new List<String>{ 'Description' };

        Assert.isFalse(DMT_ApprovalChangeStep_Helper.rowsDiffer(frozenRows,
            new Map<String, Object>{ 'row1' => new Map<String, Object>{ 'Description' => longText } }, tracked, Opportunity.SObjectType),
            'The same long text must not reopen.');
        Assert.isTrue(DMT_ApprovalChangeStep_Helper.rowsDiffer(frozenRows,
            new Map<String, Object>{ 'row1' => new Map<String, Object>{ 'Description' => longText + 'y' } }, tracked, Opportunity.SObjectType),
            'An edit at the end of a long text must reopen.');
        Assert.isTrue(DMT_ApprovalChangeStep_Helper.rowsDiffer(frozenRows,
            new Map<String, Object>{ 'row1' => new Map<String, Object>{ 'Description' => null } }, tracked, Opportunity.SObjectType),
            'Clearing a long text must reopen.');
        Assert.isFalse(DMT_ApprovalChangeStep_Helper.rowsDiffer(
            new Map<String, Object>{ 'row1' => new Map<String, Object>{ 'Description' => longText } },
            new Map<String, Object>{ 'row1' => new Map<String, Object>{ 'Description' => longText } }, tracked, Opportunity.SObjectType),
            'A snapshot frozen before the fingerprint (full text) still compares as before.');
    }

    // CIBGLOBALD-5023 - a snapshot that still does not fit leaves the largest sections out and lists them.
    @IsTest
    static void testLimitSnapshotSize_OverflowLeavesLargestSectionOut() {
        Id oppId = DMT_UTIL.createOpportunityForAccount(null).Id;
        Map<String, Object> snapshot = new Map<String, Object>{
            'opportunity' => new Map<String, Object>{ 'Id' => oppId, 'Name' => 'Snapshot test' },
            'opportunityBusinessPlan' => new Map<String, Object>{ 'row1' => new Map<String, Object>{ 'Name' => 'y'.repeat(2000) } }
        };
        DMT_TaskSnapshotService.maxSnapshotLength = 500;

        Map<String, Object> stored = (Map<String, Object>) JSON.deserializeUntyped(
            DMT_TaskSnapshotService.limitSnapshotSize(JSON.serialize(snapshot)));

        Assert.isFalse(stored.containsKey('opportunityBusinessPlan'), 'The largest section must be left out.');
        Assert.isTrue(stored.containsKey('opportunity'), 'The sections that fit are kept.');
        Assert.areEqual(new List<Object>{ 'opportunityBusinessPlan' }, stored.get(DMT_TaskSnapshotService.OVERFLOW_SECTIONS_KEY), 'The left-out section must be listed.');
    }

    // CIBGLOBALD-5023 - a task whose snapshot overflowed reopens at the next checkpoint, with the always-reopen reason.
    @IsTest
    static void testOverflowSnapshot_TaskReopens() {
        DMT_ApprovalChangeStep_Helper.alwaysReopenComponentsBySection = new Map<String, Set<String>>{ 'opportunity' => new Set<String>() };
        Task frozenTask = createFrozenOpportunityTask('Limit',
            '{"opportunity":{},"' + DMT_TaskSnapshotService.OVERFLOW_SECTIONS_KEY + '":["opportunityBusinessPlan"]}');
        Map<Id, Id> caseIdToOppId = caseToOpportunity(frozenTask);

        Test.startTest();
        Map<Id, List<String>> changesByTaskId = DMT_ApprovalChangeStep_Helper.findTasksToRestart(
            caseIdToOppId.values()[0], caseIdToOppId, 'opportunity', null, null
        );
        Test.stopTest();

        Assert.areEqual(new List<String>{ DMT_ApprovalChangeStep_Helper.ALWAYS_REOPEN_REASON }, changesByTaskId.get(frozenTask.Id),
            'A snapshot with sections left out cannot be compared, so the task must reopen.');
    }

    // CIBGLOBALD-5023 - DMT_Always_Reopen__c applies to approval Cases only: a readytoclose or passport Case with a flagged
    // component is compared as before, never reopened for the flag.
    @IsTest
    static void testAlwaysReopenComponentFrozen_OnlyApprovalCases() {
        DMT_ApprovalChangeStep_Helper.alwaysReopenComponentsBySection = new Map<String, Set<String>>{
            'opportunity' => new Set<String>{ 'NBC Client' }
        };
        Task readyToCloseTask = createFrozenOpportunityTask('Limit;NBC Client', '{"opportunity":{}}', 'readytoclose');
        Task passportTask = createFrozenOpportunityTask('Limit;NBC Client', '{"opportunity":{}}', 'passport');
        Map<Id, Id> readyToCloseCase = caseToOpportunity(readyToCloseTask);
        Map<Id, Id> passportCase = caseToOpportunity(passportTask);

        Test.startTest();
        Map<Id, List<String>> readyToCloseChanges = DMT_ApprovalChangeStep_Helper.findTasksToRestart(
            readyToCloseCase.values()[0], readyToCloseCase, 'opportunity', null, null);
        Map<Id, List<String>> passportChanges = DMT_ApprovalChangeStep_Helper.findTasksToRestart(
            passportCase.values()[0], passportCase, 'opportunity', null, null);
        Test.stopTest();

        // The fixture snapshot is empty, so the normal comparison may list changed fields; never the always-reopen reason.
        Assert.isFalse(readyToCloseChanges.containsKey(readyToCloseTask.Id)
            && readyToCloseChanges.get(readyToCloseTask.Id).contains(DMT_ApprovalChangeStep_Helper.ALWAYS_REOPEN_REASON),
            'A readytoclose Case must not be reopened by the always-reopen flag.');
        Assert.isFalse(passportChanges.containsKey(passportTask.Id)
            && passportChanges.get(passportTask.Id).contains(DMT_ApprovalChangeStep_Helper.ALWAYS_REOPEN_REASON),
            'A passport Case must not be reopened by the always-reopen flag.');
    }
}