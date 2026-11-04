@IsTest
public with sharing class DMT_Line_TriggerHandler_Test {
    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();

    // CIBGLOBALD-4117: DMT_Line_Helper.restartApprovalTasksOnLineResubmission had no automated
    // test coverage at all before this ticket - this class closes that pre-existing gap while
    // also covering the new Client/Custom_Association_Client__c logic added for this migration.
    // Mirrors DMT_OpportunityTriggerHandler_Test's setupApprovalTaskWithSnapshot/queryWithTrackedFields
    // pattern, driving the real DMT_Line__c after-update trigger via `update line` so the whole
    // chain (condition -> DMT_RendererFactory comparison -> DMT_ApprovalChangeStep_Helper.
    // restartTasksForRecord) is exercised end to end.
    @TestSetup
    static void makeData() {
        DMT_Test_DataFactory.generateTestTreasuryLines();
    }

    // generateTestTreasuryLines() creates two Lines; Line_Id__c '00002' identifies the specific
    // one this test suite uses throughout, so every test method re-queries the same record.
    private static final String TRACKED_FIELDS_QUERY = 'SELECT Id, RecordTypeId, Status__c, DMT_DateToProposal__c, ' +
        'Custom_Association__c, Client__c, Line_Id__c, Name, Booking_Geography__c, Start_Date__c, End_Date__c, ' +
        'CurrencyIsoCode, DMT_Oficina__c, DMT_LastLevelId__c, Line_Term__c, Client_Type__c, Client__r.Name, ' +
        'DMT_GlobalBanker__c, DMT_Client_Use__c, DMT_Approver__r.Name, DMT_ApproverGlobalBanker__r.Name, ' +
        'DMT_Booking_Unit_Risk_Analyst__r.Name, ' +
        // CIBGLOBALD-4117: Products (Treasury) added these DMT_Line__c fields to renderer-tracked fields -
        // this hand-maintained query needs every newly-tracked field added, same as CloseDate/
        // DMT_Confidential__c before it, or a NoChange_NoRestart-style test reads a real field as
        // falsely changed (missing from the frozen snapshot, present on the live record).
        'DvP_Amount__c, FD_Amount__c, Repos_Limit__c, Repos_Limit_6M__c, First_Breakclause__c, ' +
        'First_Breakclause_Date__c, Waiver__c, Breakclause_Frequency__c, ' +
        // CIBGLOBALD-4117: Line Info tracks these DMT_Line__c fields too (cfSummaryTreasury_Flexcard
        // fields, found via a field-drift audit) - same "keep this query in step with
        // getTrackedFields()" reasoning as the block above.
        'DMT_Business_Approval_Term__c, DMT_Bussiness_Approved_Date__c, DMT_Business_Approved_End_Date__c, ' +
        'gf_min_raroec_wo_fcg_per__c, gf_min_rorc_wo_fcg_per__c, ' +
        // CIBGLOBALD-4117: DMT_TreasuryProductsRenderer's LINE_FIELDS (Products component) also
        // reads these two - editable textarea fields on the PRODUCTS tab, found untracked via the
        // same field-drift audit.
        'DMT_Additional_Restrictions__c, DMT_Comments__c, ' +
        // CIBGLOBALD-4117: DMT_DefaultClientRenderer's getTrackedFields() also reads these two
        // relationship paths (Client component) - not displayed directly, but decide which CLIENT
        // layout branch renders.
        'Custom_Association__r.g_customer_id__c, Client__r.g_customer_id__c ' +
        'FROM DMT_Line__c WHERE Line_Id__c = \'00002\' LIMIT 1';

    private static DMT_Line__c queryLineWithTrackedFields() {
        return Database.query(TRACKED_FIELDS_QUERY);
    }

    private static List<Custom_Association_Client__c> queryCustomAssociationClients(Id customAssociationId) {
        return [
            SELECT Id, Name, DMT_ClientStarCode__c, Alpha_Code_Client__c, DMT_Amount__c, DMT_Term__c,
                   DMT_FDAmount__c, DMT_DVPAmount__c, DMT_ClientContracts__c, DMT_ClientRating__c
            FROM Custom_Association_Client__c
            WHERE Custom_Association__c = :customAssociationId
        ];
    }

    // frozenLine should be queried via queryLineWithTrackedFields() and passed in at the point
    // its field values (and its Custom_Association_Client__c child rows, if any) should be
    // frozen - i.e. right after the setup update that puts the Line into its pre-resubmission
    // state, before the test's own change under Test.startTest().
    private static Task setupApprovalTaskWithSnapshot(DMT_Line__c frozenLine) {
        return setupApprovalTaskWithSnapshot(frozenLine, 'passport');
    }

    // CIBGLOBALD-4117 - the restart checkpoints are scoped by Case.DMT_Passport_Sanction__c
    // ('passport' on Draft -> Proposal, 'approval' on Proposal -> Approval, 'readytoclose' while
    // parked in Ready to close), so each test says which sanction its Case carries. The factory's
    // buildCase sets no sanction by default.
    private static Task setupApprovalTaskWithSnapshot(DMT_Line__c frozenLine, String passportSanction) {
        Group groupApprover = [SELECT Id FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1];
        TriggerBypass.setBypass();
        Case approvalCase = DMT_UTIL.createCaseRecord(
            groupApprover.Id,
            new Map<Schema.SObjectField, Object>{
                Case.RecordTypeId => DMT_UtilTestClassConstants.DEFAULT_APPROVAL_CASE_RECORD_TYPE_ID,
                Case.DMT_Line__c => frozenLine.Id,
                Case.DMT_Passport_Sanction__c => passportSanction,
                Case.Status => 'Pending',
                Case.Subject => 'Test'
            }
        );

        Task openTask = DMT_UTIL.createTaskRecord(
            groupApprover.Id,
            approvalCase.Id,
            new Map<Schema.SObjectField, Object>{
                Task.RecordTypeId => DMT_UtilTestClassConstants.DEFAULT_TASK_STEP_RECORD_TYPE_ID,
                Task.Status => 'Not Started',
                Task.Subject => 'Test Task'
            }
        );

        String snapshotJson = '{"line":' + JSON.serialize(frozenLine);
        if (frozenLine.Custom_Association__c != null) {
            Map<Id, Custom_Association_Client__c> customAssociationClientsById = new Map<Id, Custom_Association_Client__c>(
                queryCustomAssociationClients(frozenLine.Custom_Association__c)
            );
            snapshotJson += ',"customAssociationClientList":' + JSON.serialize(customAssociationClientsById);
        }
        snapshotJson += '}';

        DMT_TaskStatusWhenCompleted__c snapshot = DMT_UTIL.createTaskStatusWhenCompletedRecord(new Map<Schema.SObjectField, Object>{
                DMT_TaskStatusWhenCompleted__c.Case__c => approvalCase.Id,
                DMT_TaskStatusWhenCompleted__c.DMT_ViewFieldStatusAtClose__c => snapshotJson
            });

        openTask.DMT_ViewStatusAtClose__c = snapshot.Id;
        update openTask;
        TriggerBypass.removeBypass();
        return openTask;
    }

    @isTest
    public static void testRestartApprovalTasksOnLineResubmission_LineInfoFieldChange_Restarts() {
        DMT_Line__c line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.DRAFT;
        line.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenLine);

        Test.startTest();
        line.Status__c = DMT_Constants.PROPOSAL;
        line.Name = 'Changed Name';
        update line;
        Test.stopTest();

        Task staleTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, staleTask.Status, 'Stale task should be cancelled after a Line Info tracked field change on resubmission - regression coverage for the already-deployed Line Info migration.');

        List<Task> replacementTasks = [SELECT Id FROM Task WHERE WhatId = :openTask.WhatId AND Id != :openTask.Id];
        Assert.areEqual(1, replacementTasks.size(), 'A replacement task should be created for the same Case');
    }

    @isTest
    public static void testRestartApprovalTasksOnLineResubmission_NoChange_NoRestart() {
        DMT_Line__c line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.DRAFT;
        line.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenLine);

        Test.startTest();
        line.Status__c = DMT_Constants.PROPOSAL;
        update line;
        Test.stopTest();

        Task unchangedTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual('Not Started', unchangedTask.Status, 'Task should not be restarted when no tracked field changed');
    }

    @isTest
    public static void testRestartApprovalTasksOnLineResubmission_SkipsFirstSubmission() {
        DMT_Line__c line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.DRAFT;
        line.DMT_DateToProposal__c = null;
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenLine);

        Test.startTest();
        // First-ever Draft->Proposal transition: DMT_DateToProposal__c is null going in, so this
        // is not a resubmission.
        line.Status__c = DMT_Constants.PROPOSAL;
        line.Name = 'Changed Name';
        update line;
        Test.stopTest();

        Task unchangedTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual('Not Started', unchangedTask.Status, 'A first-ever submission (no prior DMT_DateToProposal__c) should not restart tasks');
    }

    // CIBGLOBALD-4117 - checkpoint split, same as DMT_OpportunityTriggerHandler_Test: Draft -> Proposal
    // only restarts 'passport' Cases, Proposal -> Approval only 'approval' Cases.
    @isTest
    public static void testRestartApprovalTasksOnLineResubmission_DraftExit_SkipsApprovalSanctionCase() {
        DMT_Line__c line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.DRAFT;
        line.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenLine, 'approval');

        Test.startTest();
        line.Status__c = DMT_Constants.PROPOSAL;
        line.Name = 'Changed Name';
        update line;
        Test.stopTest();

        Task unchangedTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual('Not Started', unchangedTask.Status, 'An approval-sanction Case must not restart when the Line only moves Draft -> Proposal');
    }

    @isTest
    public static void testRestartApprovalTasksOnLineResubmission_ApprovalEntry_RestartsApprovalSanctionCase() {
        DMT_Line__c line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.PROPOSAL;
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenLine, 'approval');

        Test.startTest();
        line.Status__c = DMT_Constants.APPROVAL;
        line.Name = 'Changed Name';
        update line;
        Test.stopTest();

        Task staleTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, staleTask.Status, 'Stale task should be cancelled when a tracked field changed on Proposal -> Approval entry');
    }

    @isTest
    public static void testRestartApprovalTasksOnLineResubmission_ApprovalEntry_SkipsPassportSanctionCase() {
        DMT_Line__c line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.PROPOSAL;
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenLine, 'passport');

        Test.startTest();
        line.Status__c = DMT_Constants.APPROVAL;
        line.Name = 'Changed Name';
        update line;
        Test.stopTest();

        Task unchangedTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual('Not Started', unchangedTask.Status, 'A passport-sanction Case must not restart when the Line moves Proposal -> Approval');
    }

    @isTest
    public static void testRestartApprovalTasksOnLineResubmission_ReadyToCloseEdit_RestartsWhenTrackedFieldChanged() {
        DMT_Line__c line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.READYTOCLOSE;
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenLine, 'readytoclose');

        Test.startTest();
        line.Name = 'Changed Name';
        update line;
        Test.stopTest();

        Task staleTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, staleTask.Status, 'Stale task should be cancelled when a tracked field changes while parked in Ready to close');
    }

    // CIBGLOBALD-4117: there is deliberately NO test here for a Client change on a DMT_Line__c-level
    // field, because neither of the two the Client renderer tracks can actually drive this trigger
    // gate - a limitation found while validating, not an untested gap:
    //   - Client_Type__c is a FORMULA field (calculated, not updateable), so it cannot be set
    //     directly, and a trigger's Trigger.new holds whatever value was computed when the record
    //     was loaded rather than a freshly recalculated one;
    //   - Client__r.Name is a relationship traversal. The live side of the comparison is
    //     JSON.serialize(record) over Trigger.new, which contains no parent relationship, so the
    //     lookup returns null; the frozen snapshot nests it under a "Client__r" object rather than
    //     a "Client__r.Name" key, so that returns null too. Null == null, so it is silently never
    //     detected - it produces no false restarts, but no true ones either.
    // Client's real, working coverage on this path is the Custom_Association_Client__c child rows
    // exercised by the three tests below, which is also where the substantive client data lives.
    @isTest
    public static void testRestartApprovalTasksOnLineResubmission_CustomAssociationClientFieldChange_Restarts() {
        DMT_Line__c line = queryLineWithTrackedFields();
        Custom_Association__c ca = DMT_Test_DataFactory.generateCustomAssociation(line.Id, line.Client__c);
        Custom_Association_Client__c cac = DMT_Test_DataFactory.generateCustomAssociationClient(ca.Id);

        line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.DRAFT;
        line.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenLine);

        // Edit the child row's tracked field before resubmission - the Line itself is untouched.
        cac.DMT_ClientRating__c = 'AA';
        update cac;

        Test.startTest();
        line.Status__c = DMT_Constants.PROPOSAL;
        update line;
        Test.stopTest();

        Task staleTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, staleTask.Status, 'A Custom_Association_Client__c field change must restart tasks even though no Line field changed.');
    }

    @isTest
    public static void testRestartApprovalTasksOnLineResubmission_CustomAssociationClientRowAdded_Restarts() {
        DMT_Line__c line = queryLineWithTrackedFields();
        Custom_Association__c ca = DMT_Test_DataFactory.generateCustomAssociation(line.Id, line.Client__c);
        // No Custom_Association_Client__c rows yet at snapshot time.

        line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.DRAFT;
        line.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenLine);

        // A client row is added before resubmission - the Line itself is untouched.
        DMT_Test_DataFactory.generateCustomAssociationClient(ca.Id);

        Test.startTest();
        line.Status__c = DMT_Constants.PROPOSAL;
        update line;
        Test.stopTest();

        Task staleTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, staleTask.Status, 'Adding a Custom_Association_Client__c row must restart tasks (row-count mismatch).');
    }

    @isTest
    public static void testRestartApprovalTasksOnLineResubmission_CustomAssociationClientRowRemoved_Restarts() {
        DMT_Line__c line = queryLineWithTrackedFields();
        Custom_Association__c ca = DMT_Test_DataFactory.generateCustomAssociation(line.Id, line.Client__c);
        Custom_Association_Client__c cac = DMT_Test_DataFactory.generateCustomAssociationClient(ca.Id);

        line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.DRAFT;
        line.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenLine);

        // The client row is removed before resubmission - the Line itself is untouched.
        delete cac;

        Test.startTest();
        line.Status__c = DMT_Constants.PROPOSAL;
        update line;
        Test.stopTest();

        Task staleTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, staleTask.Status, 'Removing a Custom_Association_Client__c row must restart tasks (row-count mismatch).');
    }


    // CIBGLOBALD-4811
    @isTest
    public static void testPreviewCompareTasksFromCase_ChangedField_ListsFeature() {
        DMT_Line__c line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.DRAFT;
        line.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        update line;
        setupApprovalTaskWithSnapshot(queryLineWithTrackedFields());

        line.Name = 'Changed Name';
        update line;

        Test.startTest();
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> features =
            DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase(line.Id, 'passport');
        Test.stopTest();

        Assert.areEqual(1, features.size(), 'The Case has a stale task, so one feature is listed');
    }

    // CIBGLOBALD-4811
    @isTest
    public static void testPreviewCompareTasksFromCase_ChildRowChange_ListsFeature() {
        DMT_Line__c line = queryLineWithTrackedFields();
        Custom_Association__c ca = DMT_Test_DataFactory.generateCustomAssociation(line.Id, line.Client__c);
        Custom_Association_Client__c cac = DMT_Test_DataFactory.generateCustomAssociationClient(ca.Id);

        line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.DRAFT;
        line.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        update line;
        setupApprovalTaskWithSnapshot(queryLineWithTrackedFields());

        cac.DMT_ClientRating__c = 'AA';
        update cac;

        Test.startTest();
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> features =
            DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase(line.Id, 'passport');
        Test.stopTest();

        Assert.areEqual(1, features.size(), 'A saved child row change is found, as the trigger would find it');
    }

    // CIBGLOBALD-4811 - CIBGLOBALD-4098 case: a field null at the freeze has no key in the snapshot
    // JSON, and must still count as changed once it is populated.
    @isTest
    public static void testPreviewCompareTasksFromCase_FieldNullAtFreezeNowPopulated_ListsFeature() {
        DMT_Line__c line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.DRAFT;
        line.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        line.DMT_Comments__c = null;
        update line;
        setupApprovalTaskWithSnapshot(queryLineWithTrackedFields());

        line.DMT_Comments__c = 'Populated after the freeze';
        update line;

        Test.startTest();
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> features =
            DMT_ApprovalChangeStep_Handler.previewCompareTasksFromCase(line.Id, 'passport');
        Test.stopTest();

        Assert.areEqual(1, features.size(), 'A field missing from the snapshot JSON is compared from the tracked-field list');
    }

    // CIBGLOBALD-4811 - a Line in Ready to close whose readytoclose task was closed on the current data.
    private static DMT_Line__c setupReadyToCloseLine() {
        DMT_Line__c line = queryLineWithTrackedFields();
        line.Status__c = DMT_Constants.READYTOCLOSE;
        update line;
        DMT_Line__c frozenLine = queryLineWithTrackedFields();
        setupApprovalTaskWithSnapshot(frozenLine, 'readytoclose');
        return frozenLine;
    }

    // CIBGLOBALD-4811
    @isTest
    public static void testPreviewCompareUnsavedChanges_ChangedField_ListsFeatureAndSavesNothing() {
        DMT_Line__c line = setupReadyToCloseLine();

        Test.startTest();
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> features =
            DMT_ApprovalChangeStep_Handler.previewCompareUnsavedChanges(line.Id, 'readytoclose', new Map<String, Object>{
                'Name' => 'Unsaved Name',
                'End_Date__c' => '2030-01-15',
                'gf_min_rorc_wo_fcg_per__c' => 0.125
            }, null);
        Test.stopTest();

        Assert.areEqual(1, features.size(), 'The unsaved Name differs from the snapshot, so the feature is listed');
        Assert.areEqual(line.Name, [SELECT Name FROM DMT_Line__c WHERE Id = :line.Id].Name, 'The preview saves nothing');
    }

    // CIBGLOBALD-4811
    @isTest
    public static void testPreviewCompareUnsavedChanges_SameValue_ReturnsNothing() {
        DMT_Line__c line = setupReadyToCloseLine();

        Test.startTest();
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> features =
            DMT_ApprovalChangeStep_Handler.previewCompareUnsavedChanges(line.Id, 'readytoclose', new Map<String, Object>{ 'Name' => line.Name }, null);
        Test.stopTest();

        Assert.isTrue(features.isEmpty(), 'The value typed is the one frozen in the snapshot, so nothing reopens');
    }

    // CIBGLOBALD-4811 - Enhancement to existing process: taking the Line edit lock in Ready to close is not compared;
    // releasing it is.
    @isTest
    public static void testReadyToCloseEditLock_AcquireSkipsReleaseRestarts() {
        DMT_Line__c line = setupReadyToCloseLine();
        Task openTask = [SELECT Id FROM Task WHERE What.Type = 'Case' AND Status != :DMT_Constants.CANCELLED LIMIT 1];
        TriggerBypass.setBypass();
        update new DMT_Line__c(Id = line.Id, Name = 'Changed without the trigger');
        TriggerBypass.removeBypass();

        Test.startTest();
        update new DMT_Line__c(Id = line.Id, DMT_Line_Lock__c = UserInfo.getUserId());
        String statusAfterAcquire = [SELECT Status FROM Task WHERE Id = :openTask.Id].Status;
        update new DMT_Line__c(Id = line.Id, DMT_Line_Lock__c = null);
        Test.stopTest();

        Assert.areNotEqual(DMT_Constants.CANCELLED, statusAfterAcquire, 'Taking the lock alone does not run the restart check');
        Assert.areEqual(DMT_Constants.CANCELLED, [SELECT Status FROM Task WHERE Id = :openTask.Id].Status, 'Releasing the lock runs the check and reopens the stale task');
    }
}
