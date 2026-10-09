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

    private static final List<String> TRACKED_FIELDS = new List<String>{ 'Alpha_Code_Client__c', 'DMT_ClientRating__c' };

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
        Id approvalStepRTId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
        Task source = new Task(
            RecordTypeId = approvalStepRTId,
            Status = 'Completed',
            Subject = 'Original subject'
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

        Case approvalCase = new Case(Status = 'Pending', RecordTypeId = caseRTId, Subject = 'Test');
        insert approvalCase;

        Task olderTask = new Task(WhatId = approvalCase.Id, RecordTypeId = taskRTId, Status = 'Completed', Subject = 'Older');
        Task newerTask = new Task(WhatId = approvalCase.Id, RecordTypeId = taskRTId, Status = 'Completed', Subject = 'Newer');
        insert new List<Task>{ olderTask, newerTask };
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

    // CIBGLOBALD-4117: trackedComponentsForSnapshot scopes the restart watch gate's field comparison
    // to the components a task's own approver view actually had, instead of blindly checking every
    // renderer-tracked component - see the method's own header comment for the Treasury/Approval
    // Process Data bug this fixes. Pure function over an in-memory record, no DML needed.
    @IsTest
    static void testTrackedComponentsForSnapshotBlankFallsBackToFullList() {
        DMT_TaskStatusWhenCompleted__c snapshot = new DMT_TaskStatusWhenCompleted__c();
        Assert.areEqual(
            DMT_RendererFactory.getTrackedComponentNames(),
            DMT_ApprovalChangeStep_Helper.trackedComponentsForSnapshot(snapshot),
            'A snapshot frozen before this field existed must fall back to the unscoped full list, so already-open tasks keep today\'s behavior until they get a fresh freeze.'
        );
    }

    @IsTest
    static void testTrackedComponentsForSnapshotScopesToConfiguredComponents() {
        DMT_TaskStatusWhenCompleted__c snapshot = new DMT_TaskStatusWhenCompleted__c(
            DMT_TrackedComponents__c = 'Line Info;Client'
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
        DMT_TaskStatusWhenCompleted__c snapshot = new DMT_TaskStatusWhenCompleted__c(
            DMT_TrackedComponents__c = 'Line Info;Limit'
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
        DMT_TaskStatusWhenCompleted__c snapshot = new DMT_TaskStatusWhenCompleted__c(
            DMT_TrackedComponents__c = 'Line Info;Client'
        );
        List<String> scoped = DMT_ApprovalChangeStep_Helper.trackedComponentsForSnapshot(snapshot);
        Assert.isFalse(scoped.contains('Approval Process Data'), 'A renderer-tracked component absent from this view\'s own tracked-components list must not be checked for this snapshot.');
    }
}