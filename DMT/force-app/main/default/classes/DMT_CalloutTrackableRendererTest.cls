/**
 * CIBGLOBALD-4117 - proves the callout-tracked framework end to end on DMT_OppClientNBCRenderer
 * ('Client NBC' / currentRatingToolDate, sourced from the HPG MonoHolder service and never persisted
 * to any Salesforce field).
 *
 * DMT_HPG_Utils.callService bypasses Test.setMock(HttpCalloutMock.class,...) entirely in test
 * context - it always returns the one fixed body configured on the matching
 * iaso__GBL_integration_service__mdt record, so a standard HttpCalloutMock cannot make two calls in
 * the same test return two different values. DMT_OppClientNBCRenderer.forceLiveDateForTest is the
 * test-only seam that simulates the external service's value changing between a freeze and a later
 * comparison instead.
 */
@IsTest
private class DMT_CalloutTrackableRendererTest {

    @IsTest
    static void testClientNBCIsRegisteredAsCalloutTrackable() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('Client NBC'),
            'Client NBC must be a tracked component now that it has callout-tracked data.'
        );
        Assert.isTrue(
            DMT_RendererFactory.isCalloutTrackable('Client NBC'),
            'Client NBC must report itself as callout-trackable.'
        );
        // 'Client' now also implements DMT_CalloutTrackableRenderer - use a component with neither.
        Assert.isNull(
            DMT_RendererFactory.getCalloutTrackableRenderer('Approval Process Data'),
            'A component with no DMT_CalloutTrackableRenderer implementation must return null, not throw.'
        );
    }

    @IsTest
    static void testDelegatorRoutesToOppClientNBCRendererForDmtOpportunityRecordType() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        DMT_OppClientNBCRenderer.forceLiveDateForTest = true;
        DMT_OppClientNBCRenderer.forcedLiveDateForTest = Date.newInstance(2026, 3, 1);

        DMT_CalloutTrackableRenderer renderer = DMT_RendererFactory.getCalloutTrackableRenderer('Client NBC');
        Map<String, Object> liveValues = renderer.fetchLiveTrackedValues(opp);

        Assert.areEqual(
            Date.newInstance(2026, 3, 1), liveValues.get('currentRatingToolDate'),
            'DMT_ClientNBCRenderer must delegate to DMT_OppClientNBCRenderer for a DMT_Opportunity record.'
        );
    }

    @IsTest
    static void testCheckCalloutTrackableComponentRestartsWhenLiveValueDiffersFromFrozen() {
        Id ownerId = UserInfo.getUserId();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Case c = DMT_Test_DataFactory.generateCase(null, opp.Id, ownerId);
        List<DMT_Task_Type__c> taskTypes = DMT_Test_DataFactory.generateTaskTypes();

        Task originalTask = buildTask(c.Id, ownerId, taskTypes[0].Id);
        insert originalTask;

        Date frozenDate = Date.newInstance(2026, 1, 15);
        DMT_TaskStatusWhenCompleted__c snapshot = new DMT_TaskStatusWhenCompleted__c(
            Case__c = c.Id,
            DMT_ViewFieldStatusAtClose__c = buildSnapshotJson('Client NBC', frozenDate)
        );
        insert snapshot;
        originalTask.DMT_ViewStatusAtClose__c = snapshot.Id;
        update originalTask;

        DMT_CalloutTrackableCheckPayload payload = new DMT_CalloutTrackableCheckPayload(opp.Id, originalTask.Id, 'Client NBC', new List<String>());

        // 1. Live value unchanged from the frozen baseline - must not restart.
        DMT_OppClientNBCRenderer.forceLiveDateForTest = true;
        DMT_OppClientNBCRenderer.forcedLiveDateForTest = frozenDate;
        DMT_ApprovalChangeStep_Helper.checkCalloutTrackableComponent(payload);

        Task unchangedTask = [SELECT Status FROM Task WHERE Id = :originalTask.Id];
        Assert.areEqual(DMT_Constants.NOTSTARTED, unchangedTask.Status, 'No restart expected when the live value matches the frozen baseline.');
        Assert.areEqual(0, [SELECT COUNT() FROM Task WHERE WhatId = :c.Id AND Id != :originalTask.Id], 'No replacement task expected when nothing changed.');

        // 2. Live value now differs from the frozen baseline - must restart.
        DMT_OppClientNBCRenderer.forcedLiveDateForTest = Date.newInstance(2026, 2, 20);
        DMT_ApprovalChangeStep_Helper.checkCalloutTrackableComponent(payload);

        Task cancelledTask = [SELECT Status FROM Task WHERE Id = :originalTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, cancelledTask.Status, 'The external value changed, so the original task must be cancelled.');
        List<Task> replacements = [SELECT Status, RecordTypeId, DMT_ViewStatusAtClose__c FROM Task WHERE WhatId = :c.Id AND Id != :originalTask.Id];
        Assert.areEqual(1, replacements.size(), 'Exactly one replacement task must be created.');
        Assert.areEqual(DMT_Constants.NOTSTARTED, replacements[0].Status, 'The replacement task must start Not Started.');
        Assert.areEqual(originalTask.RecordTypeId, replacements[0].RecordTypeId, 'The replacement task must keep the original record type.');
        Assert.isNull(replacements[0].DMT_ViewStatusAtClose__c, 'The replacement task must have no snapshot until it is re-frozen.');
    }

    @IsTest
    static void testCheckCalloutTrackableComponentNoRestartWhenSnapshotHasNoFrozenBaseline() {
        Id ownerId = UserInfo.getUserId();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Case c = DMT_Test_DataFactory.generateCase(null, opp.Id, ownerId);
        List<DMT_Task_Type__c> taskTypes = DMT_Test_DataFactory.generateTaskTypes();

        Task originalTask = buildTask(c.Id, ownerId, taskTypes[0].Id);
        insert originalTask;

        // Snapshot frozen before this POC existed (or by a freeze path that doesn't capture callout
        // data yet, e.g. DMT_Massive_Task_Closure_Service) - no 'calloutTrackedValues' key at all.
        DMT_TaskStatusWhenCompleted__c snapshot = new DMT_TaskStatusWhenCompleted__c(
            Case__c = c.Id,
            DMT_ViewFieldStatusAtClose__c = JSON.serialize(new Map<String, Object>{ 'opportunity' => new Map<String, Object>() })
        );
        insert snapshot;
        originalTask.DMT_ViewStatusAtClose__c = snapshot.Id;
        update originalTask;

        DMT_OppClientNBCRenderer.forceLiveDateForTest = true;
        DMT_OppClientNBCRenderer.forcedLiveDateForTest = Date.newInstance(2026, 5, 1);

        Test.startTest();
        DMT_ApprovalChangeStep_Helper.checkCalloutTrackableComponent(
            new DMT_CalloutTrackableCheckPayload(opp.Id, originalTask.Id, 'Client NBC', new List<String>())
        );
        Test.stopTest();

        Task unchangedTask = [SELECT Status FROM Task WHERE Id = :originalTask.Id];
        Assert.areEqual(DMT_Constants.NOTSTARTED, unchangedTask.Status, 'No frozen baseline for this component - never restart, same as isTaskStale with a missing snapshot key.');
    }

    @IsTest
    static void testCheckCalloutTrackableComponentChainsToNextComponentWhenNoDiffFound() {
        // CIBGLOBALD-4117 - proves the chain: 'Client' (no callout renderer) trivially continues to
        // 'Client NBC', which finds a diff and restarts.
        Id ownerId = UserInfo.getUserId();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Case c = DMT_Test_DataFactory.generateCase(null, opp.Id, ownerId);
        List<DMT_Task_Type__c> taskTypes = DMT_Test_DataFactory.generateTaskTypes();

        Task originalTask = buildTask(c.Id, ownerId, taskTypes[0].Id);
        insert originalTask;

        Date frozenDate = Date.newInstance(2026, 1, 15);
        DMT_TaskStatusWhenCompleted__c snapshot = new DMT_TaskStatusWhenCompleted__c(
            Case__c = c.Id,
            DMT_ViewFieldStatusAtClose__c = buildSnapshotJson('Client NBC', frozenDate)
        );
        insert snapshot;
        originalTask.DMT_ViewStatusAtClose__c = snapshot.Id;
        update originalTask;

        DMT_OppClientNBCRenderer.forceLiveDateForTest = true;
        DMT_OppClientNBCRenderer.forcedLiveDateForTest = Date.newInstance(2026, 2, 20);

        Test.startTest();
        // Chain starts on 'Client' (no renderer - continues immediately), 'Client NBC' is next.
        DMT_ApprovalChangeStep_Helper.checkCalloutTrackableComponent(
            new DMT_CalloutTrackableCheckPayload(opp.Id, originalTask.Id, 'Client', new List<String>{ 'Client NBC' })
        );
        Test.stopTest();

        Task cancelledTask = [SELECT Status FROM Task WHERE Id = :originalTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, cancelledTask.Status, 'The chain must reach Client NBC and restart once its live value differs from frozen.');
    }

    @IsTest
    static void testCheckCalloutTrackableComponentContinuesChainWhenOneComponentThrows() {
        // CIBGLOBALD-4117 - found live 2026-09-25 on the first 5-long callout chain: an exception in
        // one component's check must not strand every component listed after it. 'NBC Deal' is forced
        // to throw; the chain must still reach 'Client NBC' and restart on its genuine diff.
        Id ownerId = UserInfo.getUserId();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Case c = DMT_Test_DataFactory.generateCase(null, opp.Id, ownerId);
        List<DMT_Task_Type__c> taskTypes = DMT_Test_DataFactory.generateTaskTypes();

        Task originalTask = buildTask(c.Id, ownerId, taskTypes[0].Id);
        insert originalTask;

        Date frozenDate = Date.newInstance(2026, 1, 15);
        DMT_TaskStatusWhenCompleted__c snapshot = new DMT_TaskStatusWhenCompleted__c(
            Case__c = c.Id,
            DMT_ViewFieldStatusAtClose__c = buildSnapshotJson('Client NBC', frozenDate)
        );
        insert snapshot;
        originalTask.DMT_ViewStatusAtClose__c = snapshot.Id;
        update originalTask;

        DMT_OppClientNBCRenderer.forceLiveDateForTest = true;
        DMT_OppClientNBCRenderer.forcedLiveDateForTest = Date.newInstance(2026, 2, 20);
        DMT_ApprovalChangeStep_Helper.forceExceptionForComponentNameForTest = 'NBC Deal';

        Test.startTest();
        DMT_ApprovalChangeStep_Helper.checkCalloutTrackableComponent(
            new DMT_CalloutTrackableCheckPayload(opp.Id, originalTask.Id, 'NBC Deal', new List<String>{ 'Client NBC' })
        );
        Test.stopTest();

        Task cancelledTask = [SELECT Status FROM Task WHERE Id = :originalTask.Id];
        Assert.areEqual(
            DMT_Constants.CANCELLED, cancelledTask.Status,
            'An exception in NBC Deal must not strand the rest of the chain - Client NBC must still be reached and restart on its own genuine diff.'
        );
    }

    private static Task buildTask(Id caseId, Id ownerId, Id taskTypeId) {
        Task t = new Task();
        t.WhatId = caseId;
        t.OwnerId = ownerId;
        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
        t.Status = DMT_Constants.NOTSTARTED;
        t.Subject = 'Test Task';
        t.DMT_Task_Type__c = taskTypeId;
        return t;
    }

    private static String buildSnapshotJson(String componentName, Date currentRatingToolDate) {
        Map<String, Object> calloutTrackedValues = new Map<String, Object>{
            componentName => new Map<String, Object>{ 'currentRatingToolDate' => currentRatingToolDate }
        };
        return JSON.serialize(new Map<String, Object>{ 'calloutTrackedValues' => calloutTrackedValues });
    }
}