@IsTest
public with sharing class DMT_OpportunityTriggerHandler_Test {
    private static final Id CASE_RT_APPROVAL_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
    private static final Id TASK_RT_APPROVAL_STEP_ID = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();

     @TestSetup
    static void makeData(){
        // DMT shared test data
        DMT_Test_DataFactory.loadCurrencies();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Product2 product = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product);
        DMT_Test_DataFactory.generateOpportunityLineItem(product, pricebookEntry, opp);

        // Required by the DMT_OppValidationFieldsRequired flow's Opp_Client_Template decision,
        // which blocks any transition into 'Proposal' unless a DMT_Opportunity_Client__c exists
        // for the Opportunity with these 3 fields populated (the flow's getOppClient lookup
        // returns nothing at all otherwise, so every field on it reads null).
        insert new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id,
            g_upd_lmscl_internal_ratg_type__c = 'BBB',
            DMT_Sector__c = 'Financial',
            Counterpart__c = 'Corporates'
        );
    }

    @isTest
    public static void testCalculateAndUpdateNotionalAmounts() {
        Opportunity opp = [SELECT Id, RecordTypeId, DMT_CurrencyText__c FROM Opportunity LIMIT 1];

        // Set OLI amounts used by the handler and align OLI currency with target opp currency
        // to avoid dependency on cross-currency exchange rates in test context.
        OpportunityLineItem oli = [
            SELECT Id, g_currency_id__c, DMT_Deal_amount__c, bbva_prtcp_tranche_amount__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];
        oli.DMT_Deal_amount__c = 100;
        oli.bbva_prtcp_tranche_amount__c = 100;
        oli.g_currency_id__c = 'USD';
        update oli;

        Opportunity oldOpp = opp.clone(false, true, false, false);
        oldOpp.Id = opp.Id;
        oldOpp.DMT_CurrencyText__c = 'EUR';

        Test.startTest();
        // Simulate before update context and invoke handler explicitly.
        opp.DMT_CurrencyText__c = 'USD';
        DMT_OpportunityTriggerHandler.getInstance().calculateAndUpdateNotionalAmounts(
            new Map<Id, Opportunity>{ opp.Id => opp },
            new Map<Id, Opportunity>{ opp.Id => oldOpp }
        );
        update opp;
        Test.stopTest();

        // Verify amounts calculated by this handler were populated.
        Opportunity updatedOpp = [
            SELECT DMT_CUR_Notional_Amount__c, DMT_Opportunity_amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        Assert.isNotNull(updatedOpp.DMT_CUR_Notional_Amount__c, 'DMT_CUR_Notional_Amount__c should be calculated');
        Assert.isNotNull(updatedOpp.DMT_Opportunity_amount__c, 'DMT_Opportunity_amount__c should be calculated');
        Assert.areEqual(updatedOpp.DMT_Opportunity_amount__c, updatedOpp.DMT_CUR_Notional_Amount__c,
            'Opportunity amount and notional amount should match for this test setup');
    }

    @isTest
    public static void testCalculateAndUpdateNotionalAmounts_SumsBbvaAcrossOlis() {
        Opportunity opp = [SELECT Id, DMT_CurrencyText__c, RecordTypeId FROM Opportunity LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];

        OpportunityLineItem firstOli = [
            SELECT Id, OpportunityId, bbva_prtcp_tranche_amount__c, DMT_Deal_amount__c, g_currency_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];
        firstOli.bbva_prtcp_tranche_amount__c = 1200;
        firstOli.DMT_Deal_amount__c = 10;
        firstOli.g_currency_id__c = 'USD';
        update firstOli;

        OpportunityLineItem secondOli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Product2Id = product.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 1,
            bbva_prtcp_tranche_amount__c = 1300,
            DMT_Deal_amount__c = 99,
            g_currency_id__c = 'USD'
        );
        insert secondOli;

        Opportunity oldOpp = opp.clone(false, true, false, false);
        oldOpp.Id = opp.Id;

        Test.startTest();
        opp.DMT_CurrencyText__c = 'USD';
        DMT_OpportunityTriggerHandler.getInstance().calculateAndUpdateNotionalAmounts(
            new Map<Id, Opportunity>{ opp.Id => opp },
            new Map<Id, Opportunity>{ opp.Id => oldOpp }
        );
        update opp;

        Opportunity updatedOpp = [
            SELECT DMT_CUR_Notional_Amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        Test.stopTest();

        Assert.areEqual(2500, updatedOpp.DMT_CUR_Notional_Amount__c,
            'DMT_CUR_Notional_Amount__c must be the sum of bbva_prtcp_tranche_amount__c values');
    }

    
    @isTest
    public static void testBlockClosedWonWithProspectInMultiholder() {
        Id dmtOppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Id prospectGroupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        Id prospectSubsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        
        // Escenario 1: Account principal (Customer) - Debería pasar validación inicial
        Account mainAccount = new Account(
            Name = 'Main Client Account',
            g_customer_id__c = 'ES0000000000001',
            RecordTypeId = customerRtId
        );
        insert mainAccount;        
        // Escenario 2: Prospect_Subsidiary en multiholder - Este causará el bloqueo
        Account prospectSubsidiary = new Account(
            Name = 'Prospect Subsidiary in Multiholder',
            g_customer_id__c = 'ES0000000000002',
            DES_ID_Fiscal__c = 'x123',
            RecordTypeId = prospectSubsidiaryRtId
        );
        insert prospectSubsidiary;        
        // Escenario 3: Account regular en multiholder - NO causará bloqueo
        Account regularAccount = new Account(
            Name = 'Regular Account in Multiholder',
            g_customer_id__c = 'ES0000000000003',
            RecordTypeId = customerRtId
        );
        insert regularAccount;        
        // Escenario 4: Prospect_Subsidiary como Account principal - NO debería pasar validación inicial
        Account prospectMain = new Account(
            Name = 'Prospect Subsidiary Main',
            g_customer_id__c = 'ES0000000000004',
            DES_ID_Fiscal__c = 'x234',
            RecordTypeId = prospectSubsidiaryRtId
        );
        insert prospectMain;        
        // Escenario 5: Prospect_Group como Account principal - NO debería pasar validación inicial
        Account prospectGroupMain = new Account(
            Name = 'Prospect Group Main',
            g_customer_id__c = 'ES0000000000005',
            RecordTypeId = prospectGroupRtId
        );
        insert prospectGroupMain;        
        // Opportunity 1: Con main account Customer y Prospect_Subsidiary en multiholder - SE BLOQUEA
        Opportunity opp1 = new Opportunity(
            Name = 'Test DMT Opportunity 1 - Should Block',
            AccountId = mainAccount.Id,
            RecordTypeId = dmtOppRtId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );        
        // Opportunity 2: Con main account Customer y regular account en multiholder - NO SE BLOQUEA
        Opportunity opp2 = new Opportunity(
            Name = 'Test DMT Opportunity 2 - Should Pass',
            AccountId = mainAccount.Id,
            RecordTypeId = dmtOppRtId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );        
        // Opportunity 5: Sin multiholder - NO SE BLOQUEA (cubre early return cuando oppClients está vacío)
        Opportunity opp5 = new Opportunity(
            Name = 'Test DMT Opportunity 5 - No Multiholder',
            AccountId = mainAccount.Id,
            RecordTypeId = dmtOppRtId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );        
        insert new List<Opportunity>{opp1, opp2, opp5};        
        // Crear DMT_Custom_Association_Opportunity__c (main holder) para opp1 y opp2
        Custom_Association_Opportunity__c assocOpp1 = new Custom_Association_Opportunity__c(
            Opportunity__c = opp1.Id,
            g_customer_id__c = mainAccount.g_customer_id__c,
            gf_customer_group_id__c = opp1.Id
        );
        Custom_Association_Opportunity__c assocOpp2 = new Custom_Association_Opportunity__c(
            Opportunity__c = opp2.Id,
            g_customer_id__c = mainAccount.g_customer_id__c,
            gf_customer_group_id__c = opp2.Id
        );
        insert new List<Custom_Association_Opportunity__c>{assocOpp1, assocOpp2};
        // Crear DMT_Custom_Association_ClientOpportunity__c apuntando a Prospect_Subsidiary para opp1 (multiholder)
        DMT_Custom_Association_ClientOpportunity__c oppClient1 = new DMT_Custom_Association_ClientOpportunity__c(
            DMT_Custom_Association_Opportunity__c = assocOpp1.Id,
            DMT_g_customer_id__c = prospectSubsidiary.g_customer_id__c
        );        
        // Crear DMT_Custom_Association_ClientOpportunity__c apuntando a regular account para opp2
        DMT_Custom_Association_ClientOpportunity__c oppClient2 = new DMT_Custom_Association_ClientOpportunity__c(
            DMT_Custom_Association_Opportunity__c = assocOpp2.Id,
            DMT_g_customer_id__c = regularAccount.g_customer_id__c
        );        
        insert new List<DMT_Custom_Association_ClientOpportunity__c>{oppClient1, oppClient2};        
        Test.startTest();        
        // Intentar cerrar opp1 - DEBE BLOQUEARSE
        opp1.StageName = 'Closed Won';
        Boolean opp1Blocked = false;
        String opp1ErrorMessage = '';
        try {
            update opp1;
        } catch (DmlException e) {
            opp1Blocked = true;
            opp1ErrorMessage = e.getMessage();
        }        
        // Intentar cerrar opp2 - NO DEBE BLOQUEARSE
        opp2.StageName = 'Closed Won';
        Boolean opp2Blocked = false;
        try {
            update opp2;
        } catch (DmlException e) {
            opp2Blocked = true;
        }        
        // Intentar cerrar opp5 - NO DEBE BLOQUEARSE (no tiene multiholder)
        opp5.StageName = 'Closed Won';
        Boolean opp5Blocked = false;
        try {
            update opp5;
        } catch (DmlException e) {
            opp5Blocked = true;
        }        
        Test.stopTest();
        Assert.isTrue(opp1Blocked, 'Opp1 should be blocked - has Prospect_Subsidiary in multiholder');       
        Assert.isFalse(opp2Blocked, 'Opp2 should NOT be blocked - has regular account in multiholder');
        Assert.isFalse(opp5Blocked, 'Opp5 should NOT be blocked - has no multiholder');
            
    }
    

    @isTest
    public static void testCalculateAndUpdateNotionalAmounts_KeepCurrencyConversionForOpportunityAmount() {
        Opportunity opp = [SELECT Id, DMT_CurrencyText__c, RecordTypeId FROM Opportunity LIMIT 1];

        OpportunityLineItem oli = [
            SELECT Id, OpportunityId, bbva_prtcp_tranche_amount__c, DMT_Deal_amount__c, g_currency_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
            LIMIT 1
        ];
        oli.bbva_prtcp_tranche_amount__c = 120;
        oli.DMT_Deal_amount__c = 120;
        oli.g_currency_id__c = 'USD';
        update oli;

        Opportunity oldOpp = opp.clone(false, true, false, false);
        oldOpp.Id = opp.Id;
        oldOpp.DMT_CurrencyText__c = 'USD';

        Test.startTest();
        opp.DMT_CurrencyText__c = 'EUR';
        DMT_OpportunityTriggerHandler.getInstance().calculateAndUpdateNotionalAmounts(
            new Map<Id, Opportunity>{ opp.Id => opp },
            new Map<Id, Opportunity>{ opp.Id => oldOpp }
        );
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT DMT_CUR_Notional_Amount__c, DMT_Opportunity_amount__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Decimal expectedConvertedAmount = DMT_Currency.convert(120, 'USD', 'EUR').setScale(2, RoundingMode.HALF_UP);
        Assert.areEqual(expectedConvertedAmount, updatedOpp.DMT_Opportunity_amount__c,
            'DMT_Opportunity_amount__c must keep currency conversion when opportunity currency changes');
        Assert.areEqual(100, updatedOpp.DMT_CUR_Notional_Amount__c,
            'DMT_CUR_Notional_Amount__c must remain raw bbva_prtcp_tranche_amount__c sum');
    }

    @isTest
    public static void testValidateDynamicStageChange_PassUnrelatedStage() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Draft';
        update opp;

        // Mock JSON: Mandatory ('Y'), Not Green ('WHITE'), Targets 'Ready to close'
        String mockedJson = '{"data":{"features":[{"name":"RTC Blocker","requiredType":"Y","requiredAtStatus":"Ready to close","stateName":"WHITE"}]}}';
        Passport__c passport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = mockedJson);
        insert passport;

        Test.startTest();
        // Advancing to Approval (to avoid DES_HandlerTerritory errors), but the feature only blocks 'Ready to close'. This should succeed.
        opp.StageName = 'Approval';
        Boolean exceptionThrown = false;
        String actualErrorMessage = '';
        try {
            update opp;
        } catch (Exception e) {
            exceptionThrown = true;
            actualErrorMessage = e.getMessage();
        }
        Test.stopTest();

        // If it fails now, it will print the EXACT error message from the other class so we can fix the test data if needed.
        Assert.isFalse(exceptionThrown, 'No exception should be thrown, but an unrelated error occurred: ' + actualErrorMessage);
        
        if (!exceptionThrown) {
            Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
            Assert.areEqual('Approval', updatedOpp.StageName, 'Opportunity stage should have updated successfully.');
        }
    }

    @isTest
    public static void testValidateDynamicStageChange_PassGreenFeature() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Draft';
        update opp;

        // Mock JSON: Mandatory ('Y'), Is Green ('GREEN'), Targets 'Approval'
        String mockedJson = '{"data":{"features":[{"name":"Green Feature","requiredType":"Y","requiredAtStatus":"Approval","stateName":"GREEN"}]}}';
        Passport__c passport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = mockedJson);
        insert passport;

        Test.startTest();
        opp.StageName = 'Approval';
        Boolean exceptionThrown = false;
        try {
            update opp;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isFalse(exceptionThrown, 'No exception should be thrown because the required feature is GREEN.');
        
        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Approval', updatedOpp.StageName, 'Opportunity stage should have updated successfully.');
    }

    @isTest
    public static void testValidateDynamicStageChange_PassApprovedByWorkflow() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = 'Draft';
        update opp;

        // Mock JSON: Mandatory ('Y'), Not Green ('WHITE'), Targets 'Ready to close' -- the external
        // Passport engine has not reconciled stateName yet, but our internal Case/Task workflow has.
        String mockedJson = '{"data":{"features":[{"id":"700","name":"Workflow Approved Feature","requiredType":"Y","requiredAtStatus":"Ready to close","stateName":"WHITE"}]}}';
        Passport__c passport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c = mockedJson);
        insert passport;

        Group groupApprover = [SELECT Id FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1];
        TriggerBypass.setBypass();
        Case workflowCase = new Case(
            opportunity_id__c = opp.Id,
            DMT_Feature_Id__c = '700',
            DMT_Passport_Sanction__c = 'passport',
            Status = 'Finished',
            RecordTypeId = CASE_RT_APPROVAL_ID,
            OwnerId = groupApprover.Id,
            Subject = 'Test'
        );
        insert workflowCase;

        Task approvalTask = new Task(
            WhatId = workflowCase.Id,
            RecordTypeId = TASK_RT_APPROVAL_STEP_ID,
            Status = 'Completed',
            Subject = 'Test Task',
            OwnerId = groupApprover.Id,
            DMT_Step_Result__c = 'Yes'
        );
        insert approvalTask;
        TriggerBypass.removeBypass();

        Test.startTest();
        opp.StageName = 'Ready to close';
        Boolean exceptionThrown = false;
        try {
            update opp;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isFalse(exceptionThrown, 'No exception should be thrown: the internal Case/Task workflow already approved this feature.');

        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Ready to close', updatedOpp.StageName, 'Opportunity stage should have updated successfully.');
    }

    // CIBGLOBALD-4117: coverage for restartApprovalTasksOnOpportunityResubmission's 3 checkpoints.
    // Sets up one open approval Task, snapshotted via DMT_TaskStatusWhenCompleted__c the same way
    // updateTaskWithStatus does, then drives the real Opportunity trigger via `update opp` so the
    // whole chain (condition -> DMT_RendererFactory comparison -> DMT_ApprovalChangeStep_Helper.
    // restartTasksForRecord) is exercised end to end, not just the handler method in isolation.

    // Every field DMT_OpportunityInfoRenderer.getTrackedFields() can return. Queried explicitly
    // (rather than SELECT Id, RecordTypeId) so the frozen snapshot built from this same record in
    // setupApprovalTaskWithSnapshot covers every tracked field - snapshotting only a subset would
    // leave the others absent from the frozen JSON, which the live comparison reads identically to
    // "null", making even a genuinely untouched field look changed against a populated live value.
    private static final String TRACKED_FIELDS_QUERY = 'SELECT Id, RecordTypeId, Name, DMT_Opp_Id__c, ' +
        'Entific__c, DMT_Entity__c, DMT_branch_id_c__c, DMT_Booking_EFAN__c, DMT_Tenor__c, ' +
        'DMT_CUR_Notional_Amount__c, DMT_CurrencyText__c, DMT_Capital_Action__c, DMT_Product_Area__c, ' +
        'DMT_Opportunity_amount__c, DMT_ContingentCommitments__c, DMT_Structured_GTB__c, ' +
        // CIBGLOBALD-4117: added when these two were added to DMT_OpportunityInfoRenderer. Omitting
        // a tracked field here makes the NoRestartWhenFieldUnchanged test fail for the reason the
        // comment above describes - the frozen snapshot lacks the key while the live record has a
        // value, which reads as a change. Keep this query in step with getTrackedFields().
        'CloseDate, DMT_Confidential__c, ' +
        // DMT_Threshold_Type__c is Opportunity-native but is tracked via the "Client" component
        // (DMT_OpportunityClientRenderer), not "Opportunity Info" - the tracked set is the union
        // across every migrated component, so this query has to follow suit.
        'DMT_Threshold_Type__c, ' +
        // CIBGLOBALD-4117 - the SPPI TEST section fields plus DMT_Financial_Sponsors__c, tracked via
        // "Approval Process Data" (DMT_OppApprovalProcessDataRenderer). Missing here the same way
        // DMT_Threshold_Type__c was: this test's blank DMT_TrackedComponents__c falls back to the
        // full cross-component tracked-field union, not just Opportunity Info's own fields.
        'DMT_SPPI_Status__c, DMT_SPPI_User__c, DMT_SPPI_File_Uploaded__c, DMT_Financial_Sponsors__c, ' +
        // CIBGLOBALD-4117 - tracked via "NBC Client" (DMT_NBC_ClientRenderer), added 2026-09-25.
        // Missing here the same way DMT_Threshold_Type__c/the SPPI fields were - this test's blank
        // DMT_TrackedComponents__c falls back to the full cross-component union, so any component's
        // new tracked field has to be added here too or NoRestartWhenFieldUnchanged false-restarts.
        'DMT_NewClient__c, DMT_GlobalBanker__c, DMT_Under_X_Selling_Monitoring__c ' +
        'FROM Opportunity LIMIT 1';

    private static Opportunity queryOppWithTrackedFields() {
        return Database.query(TRACKED_FIELDS_QUERY);
    }

    // frozenOpp should be queried via queryOppWithTrackedFields() and passed in at the point its
    // field values should be frozen - i.e. right after the setup update that puts the Opportunity
    // into its pre-resubmission state, before the test's own change under Test.startTest().
    private static Task setupApprovalTaskWithSnapshot(Opportunity frozenOpp, String passportSanctionFilter) {
        Group groupApprover = [SELECT Id FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1];
        TriggerBypass.setBypass();
        Case approvalCase = new Case(
            opportunity_id__c = frozenOpp.Id,
            DMT_Passport_Sanction__c = passportSanctionFilter,
            Status = 'Pending',
            RecordTypeId = CASE_RT_APPROVAL_ID,
            OwnerId = groupApprover.Id,
            Subject = 'Test'
        );
        insert approvalCase;

        Task openTask = new Task(
            WhatId = approvalCase.Id,
            RecordTypeId = TASK_RT_APPROVAL_STEP_ID,
            Status = 'Not Started',
            Subject = 'Test Task',
            OwnerId = groupApprover.Id
        );
        insert openTask;
        TriggerBypass.removeBypass();

        DMT_TaskStatusWhenCompleted__c snapshot = new DMT_TaskStatusWhenCompleted__c(
            Case__c = approvalCase.Id,
            DMT_ViewFieldStatusAtClose__c = '{"opportunity":' + JSON.serialize(frozenOpp) + '}'
        );
        insert snapshot;

        openTask.DMT_ViewStatusAtClose__c = snapshot.Id;
        update openTask;
        return openTask;
    }

    @isTest
    public static void testRestartApprovalTasksOnOpportunityResubmission_DraftExit_RestartsWhenTrackedFieldChanged() {
        Opportunity opp = queryOppWithTrackedFields();
        opp.StageName = 'Draft';
        opp.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        update opp;

        Task openTask = setupApprovalTaskWithSnapshot(opp, 'passport');

        Test.startTest();
        opp.StageName = 'Proposal';
        opp.Name = 'Changed Name';
        update opp;
        Test.stopTest();

        Task staleTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, staleTask.Status, 'Stale task should be cancelled after a tracked field change on Draft-exit resubmission');

        List<Task> replacementTasks = [SELECT Id, RecordTypeId FROM Task WHERE WhatId = :openTask.WhatId AND Id != :openTask.Id];
        Assert.areEqual(1, replacementTasks.size(), 'A replacement task should be created for the same Case');
        // CIBGLOBALD-4117: regression check for a real bug found in live testing - the replacement
        // task's RecordTypeId silently defaulted to the wrong record type when the source query
        // didn't select it, which made the task invisible to DMT_Case_Steps_Controller's
        // RecordType-filtered queries (breaking the passport traffic-light UI) despite the restart
        // itself appearing to succeed.
        Assert.areEqual(TASK_RT_APPROVAL_STEP_ID, replacementTasks[0].RecordTypeId, 'Replacement task must keep the original DMT_Step_Approval record type');

        Case resetCase = [SELECT Status FROM Case WHERE Id = :openTask.WhatId];
        Assert.areEqual(DMT_Constants.PENDING, resetCase.Status, 'Case should be reset to Pending');
    }

    @isTest
    public static void testRestartApprovalTasksOnOpportunityResubmission_DraftExit_NoRestartWhenFieldUnchanged() {
        Opportunity opp = queryOppWithTrackedFields();
        opp.StageName = 'Draft';
        opp.DMT_DateToProposal__c = Datetime.now().addDays(-1);
        update opp;
        // Re-queried after the update so the frozen snapshot reflects the record's actual
        // post-transition state, not whatever opp's in-memory fields held before the update.
        // Mirrors DMT_Line_TriggerHandler_Test's frozenLine re-query for the same reason.
        Opportunity frozenOpp = queryOppWithTrackedFields();

        Task openTask = setupApprovalTaskWithSnapshot(frozenOpp, 'passport');

        Test.startTest();
        opp.StageName = 'Proposal';
        update opp;
        Test.stopTest();

        Task unchangedTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual('Not Started', unchangedTask.Status, 'Task should not be restarted when no tracked field changed');
    }

    @isTest
    public static void testRestartApprovalTasksOnOpportunityResubmission_DraftExit_SkipsFirstSubmission() {
        Opportunity opp = queryOppWithTrackedFields();
        opp.StageName = 'Draft';
        opp.DMT_DateToProposal__c = null;
        update opp;

        Task openTask = setupApprovalTaskWithSnapshot(opp, 'passport');

        Test.startTest();
        // First-ever Draft->Proposal transition: DMT_DateToProposal__c is null going in, so this is
        // not a resubmission - matches AfterCreateOpportunity's From_Draft_to_Proposal decision,
        // which only routed to the compare/restart action when DMT_DateToProposal__c was already set.
        opp.StageName = 'Proposal';
        opp.Name = 'Changed Name';
        update opp;
        Test.stopTest();

        Task unchangedTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual('Not Started', unchangedTask.Status, 'A first-ever submission (no prior DMT_DateToProposal__c) should not restart tasks');
    }

    @isTest
    public static void testRestartApprovalTasksOnOpportunityResubmission_ApprovalEntry_RestartsWhenTrackedFieldChanged() {
        Opportunity opp = queryOppWithTrackedFields();
        opp.StageName = 'Proposal';
        update opp;

        Task openTask = setupApprovalTaskWithSnapshot(opp, 'approval');

        Test.startTest();
        opp.StageName = 'Approval';
        opp.Name = 'Changed Name';
        update opp;
        Test.stopTest();

        Task staleTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, staleTask.Status, 'Stale task should be cancelled when a tracked field changed on Proposal->Approval entry');

        Task replacementTask = [SELECT RecordTypeId FROM Task WHERE WhatId = :openTask.WhatId AND Id != :openTask.Id LIMIT 1];
        Assert.areEqual(TASK_RT_APPROVAL_STEP_ID, replacementTask.RecordTypeId, 'Replacement task must keep the original DMT_Step_Approval record type');
    }

    @isTest
    public static void testRestartApprovalTasksOnOpportunityResubmission_ReadyToCloseEdit_RestartsWhenTrackedFieldChanged() {
        Opportunity opp = queryOppWithTrackedFields();
        opp.StageName = 'Ready to close';
        update opp;

        Task openTask = setupApprovalTaskWithSnapshot(opp, 'readytoclose');

        Test.startTest();
        // Deliberately NOT setting DMT_Is_Change_in_Ready_to_close__c: detection here must come from
        // our own tracked-field comparison, not the flag some edit FlexCards set unconditionally on
        // every save regardless of whether a tracked field actually changed.
        opp.Name = 'Changed Name';
        update opp;
        Test.stopTest();

        Task staleTask = [SELECT Status FROM Task WHERE Id = :openTask.Id];
        Assert.areEqual(DMT_Constants.CANCELLED, staleTask.Status, 'Stale task should be cancelled when a tracked field changes while parked in Ready to close, independent of DMT_Is_Change_in_Ready_to_close__c');

        Task replacementTask = [SELECT RecordTypeId FROM Task WHERE WhatId = :openTask.WhatId AND Id != :openTask.Id LIMIT 1];
        Assert.areEqual(TASK_RT_APPROVAL_STEP_ID, replacementTask.RecordTypeId, 'Replacement task must keep the original DMT_Step_Approval record type');
    }

    // CIBGLOBALD-4117: coverage for stampDateToProposal, migrated from AfterCreateOpportunity's
    // Save_Date_Proposal record-update (removed along with the flow's 3 restart checkpoints).
    @isTest
    public static void testStampDateToProposal_SetsOnDraftToProposalTransition() {
        Opportunity opp = queryOppWithTrackedFields();
        opp.StageName = 'Draft';
        opp.DMT_DateToProposal__c = null;
        update opp;

        Test.startTest();
        opp.StageName = 'Proposal';
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DMT_DateToProposal__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.isNotNull(updatedOpp.DMT_DateToProposal__c, 'DMT_DateToProposal__c should be stamped on a Draft->Proposal transition');
    }

    @isTest
    public static void testStampDateToProposal_DoesNotStampOnOtherTransitions() {
        Opportunity opp = queryOppWithTrackedFields();
        opp.StageName = 'Proposal';
        opp.DMT_DateToProposal__c = null;
        update opp;

        Test.startTest();
        opp.StageName = 'Approval';
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [SELECT DMT_DateToProposal__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.isNull(updatedOpp.DMT_DateToProposal__c, 'DMT_DateToProposal__c should only be stamped specifically on a Draft->Proposal transition');
    }
}