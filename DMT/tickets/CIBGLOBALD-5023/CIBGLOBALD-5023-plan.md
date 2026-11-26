# CIBGLOBALD-5023 - Always reopen approval tasks of flagged components

Production bugfix. Builds on CIBGLOBALD-4117 (restart gate) and CIBGLOBALD-4811 (warning preview): read tickets/CIBGLOBALD-4117/CIBGLOBALD-4117-memory.md first.

## Rule (user 2026-11-25)
Always means always. At every checkpoint the triggers already run (Draft -> Proposal resubmission, Proposal -> Approval, Ready to close edit), for the Cases the trigger already passes, a restartable task whose snapshot froze a component with DMT_Always_Reopen__c = true is reopened without comparing fields. The triggers, the Case lists, the task filter and DMT_TrackedComponents__c stay as they are.

## Steps
0. Branch 5023 from the current tree (4924 state, user OK). Fresh retrieve of the manifest into DMT/tickets/CIBGLOBALD-5023/CIBGLOBALD-5023-org-original/. Edit on top of the org copies (the org Helper was changed by Javier on 11-24).
1. Field DMT_Configurator_View_Items__mdt.DMT_Always_Reopen__c (Checkbox, default false, label Always reopen approval).
2. Records set to true (Opportunity view type): every NBC and GTB Local NBC record, Client_NBC, Opportunity_Info_NBC, Profitability_Opportunity, Profitability_Summaries_Opportunity.
3. DMT_ApprovalChangeStep_Helper only:
   - alwaysReopenComponents(snapshotSectionKey): DMT_Component_Item__c of the flagged records, scoped by DMT_Type__c to the object (opportunity -> Opportunity; line -> Line, Line_Treasury, Line_Sanction). getAll(), no SOQL. @TestVisible override for tests.
   - isTaskStale, first check: a component of the task's DMT_TrackedComponents__c is flagged -> stale. When changes are collected (the 4811 preview), the component name is added so the toast and dialog say why. The trigger and the preview share isTaskStale, so neither DMT_OpportunityTriggerHandler, DMT_Line_Helper nor DMT_ApprovalChangeStep_Handler changes.
4. Profitability reaches the snapshot: the delegators DMT_ProfitabilityRenderer and DMT_ProfitabilitySummariesRenderer implement DMT_TrackedComponent (isComponentTracked true) and DMT_FieldTrackableRenderer (getTrackedFields returns an empty list: the name is frozen, no field is compared). DMT_OppProfitabilityRenderer and DMT_OppProfitabilitySummariesRenderer are not touched.
5. Tests (DMT_ApprovalChangeStep_HelperTest, DMT_OpportunityTriggerHandler_Test, DMT_ProfitabilityRendererTest): flagged component and no field change -> restart at each of the three checkpoints; not flagged -> compares as before; preview lists the component; both delegators listed by DMT_RendererFactory.getTrackedComponentNames().

## Deploy
Field -> records -> delegators -> Helper alone NoTestRun (others edit it) -> tests with sf apex run test. LastModified check as its own step before each deploy. DMT_TCM_DEV only.
