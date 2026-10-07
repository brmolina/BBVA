public without sharing class DMT_OpportunityTriggerHandler {

    //SINGLETON PATTERN
    private static DMT_OpportunityTriggerHandler instance;
    public static DMT_OpportunityTriggerHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DMT_OpportunityTriggerHandler();
        }
        return instance;
    }

  public void calculateAndUpdateNotionalAmounts(Map<ID,Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
      Set<Id> opportunityIdsDMT = new Set<Id>();
        if (newOpps == null || newOpps.isEmpty()) {
            return;
        }

        String rtOppDmtID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get(DMT_Constants.RT_OPP_DMT_NAME)
            .getRecordTypeId();

      for(Opportunity opp :newOpps.values()){
        if(opp.RecordTypeId == rtOppDmtID && opp.DMT_CurrencyText__c != null && oldOppMap.get(opp.Id).DMT_CurrencyText__c != opp.DMT_CurrencyText__c) {
          opportunityIdsDMT.add(opp.Id);

        }
      }

        if (opportunityIdsDMT.isEmpty()) {
            return;
        }

        // Get all OpportunityLineItems for these opportunities
        List<OpportunityLineItem> allOliList = [
            SELECT Id, OpportunityId, DMT_Deal_amount__c, bbva_prtcp_tranche_amount__c, g_currency_id__c, Opportunity.DMT_CurrencyText__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :opportunityIdsDMT
        ];

        // Calculate converted amounts per opportunity
        Map<Id, Decimal> oppConvertedTotals = new Map<Id, Decimal>();
        Map<Id, Decimal> oppNotionalConvertedTotals = new Map<Id, Decimal>();

        for (OpportunityLineItem oli : allOliList) {
            if (!oppConvertedTotals.containsKey(oli.OpportunityId)) {
                oppConvertedTotals.put(oli.OpportunityId, 0);
            }
            if (!oppNotionalConvertedTotals.containsKey(oli.OpportunityId)) {
                oppNotionalConvertedTotals.put(oli.OpportunityId, 0);
            }

            // DMT_Opportunity_amount__c must be based on DMT_Deal_amount__c
            Decimal oliAmount = oli.DMT_Deal_amount__c != null ? oli.DMT_Deal_amount__c : 0;
            Decimal oliNotionalAmount = oli.bbva_prtcp_tranche_amount__c != null ? oli.bbva_prtcp_tranche_amount__c : 0;
           
            // Convert OLI amount to Opportunity's NEW currency
            Decimal convertedAmount = DMT_Currency.convert(
                oliAmount,
                oli.g_currency_id__c,
                newOpps.get(oli.OpportunityId).DMT_CurrencyText__c
            );

            // Convert notional amount to Opportunity's NEW currency with same logic
            Decimal convertedNotionalAmount = DMT_Currency.convert(
                oliNotionalAmount,
                oli.g_currency_id__c,
                newOpps.get(oli.OpportunityId).DMT_CurrencyText__c
            );

            if (convertedAmount == null) {
                newOpps.get(oli.OpportunityId).addError('Exchange rate not found for the currency pair: ' + oli.g_currency_id__c + ' to ' + newOpps.get(oli.OpportunityId).DMT_CurrencyText__c);
                return;
            }
            oppConvertedTotals.put(oli.OpportunityId, oppConvertedTotals.get(oli.OpportunityId) + convertedAmount);
            oppNotionalConvertedTotals.put(oli.OpportunityId, oppNotionalConvertedTotals.get(oli.OpportunityId) + convertedNotionalAmount);
        }

        // Build list for update
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Id oppId : oppConvertedTotals.keySet()) {
            Opportunity opp = newOpps.get(oppId);
            Decimal convertedTotal = oppConvertedTotals.get(oppId).setScale(2, RoundingMode.HALF_UP);
            Decimal convertedNotionalTotal = oppNotionalConvertedTotals.get(oppId).setScale(2, RoundingMode.HALF_UP);

            // Always update DMT_Opportunity_amount__c
            opp.DMT_Opportunity_amount__c = convertedTotal;

            // DMT_CUR_Notional_Amount__c must match the OLI BBVA participant tranche sum
            opp.DMT_CUR_Notional_Amount__c = convertedNotionalTotal;

            oppsToUpdate.add(opp);
        }
    }

    /**
     * @description Bloquea el cierre de oportunidades que tengan Prospect_Subsidiary seleccionada en la multiholder
     */
    public void blockClosedWonWithProspectInMultiholder(List<Opportunity> triggerNew, Map<Id, Opportunity> triggerOldMap) {        
       Id oppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity')?.getRecordTypeId();
        
        // 2. Recopilar IDs de oportunidades con AccountId
        Set<Id> opportunityIdsToValidate = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Opportunity> oppsToValidate = new Map<Id, Opportunity>();
        
        for (Opportunity opp : triggerNew) {
            Opportunity oldOpp = triggerOldMap.get(opp.Id);
            if (opp.AccountId != null && opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won' && opp.RecordTypeId == oppRTId) {
                opportunityIdsToValidate.add(opp.Id);
                accountIds.add(opp.AccountId);
                oppsToValidate.put(opp.Id, opp);
            }
        }
        
        if (opportunityIdsToValidate.isEmpty()) {
            return;
        }

        Set<Id> oppsWithProspect = DMT_Opportunity_Utils.getOpportunityIdsWithProspectInClientOrMultiholder(opportunityIdsToValidate, accountIds);
        
        for (Id oppId : oppsWithProspect) {
            if (oppsToValidate.containsKey(oppId)) {
                Opportunity opp = oppsToValidate.get(oppId);
                opp.addError('You cannot close an Opportunity as Won if the associated client is a \'Prospect\'. Closing an Opportunity implies that the contract is signed and the client must be \'Onboarded\' (or \'Active\').');
            }
        }
    }

    /**
     * @description Identifies new Opportunities that require X-Sell generation
     * and enqueues the async payload for the Orchestrator.
     * @param newOpps List of newly inserted Opportunities (Trigger.new)
     */
    public void enqueueOppXSellGeneration(List<Opportunity> newOpps) {
        Set<Id> oppIdsForXSell = new Set<Id>();
        for (Opportunity opp : newOpps) {
            if (String.isNotBlank(opp.DMT_Entity__c) && opp.AccountId != null) {
                oppIdsForXSell.add(opp.Id);
            }
        }
       
        if (!oppIdsForXSell.isEmpty()) {
            DMT_AsyncOrchestrator.enqueue(new DMT_OppXSellPayload(oppIdsForXSell));
        }
    }
    /**
     * @description Called in AFTER UPDATE trigger.
     * Detects when a DMT_Opportunity moves to a closing stage (Closed Won / Closed Lost)
     * and enqueues an async payload to call the PAWIF integration via DMT_DynamicFieldMapper.
     * @param newOpps Trigger.new
     * @param oldMapOpps Trigger.oldMap
     */
    public void enqueueClosingIntegration(List<Opportunity> newOpps, Map<Id, Opportunity> oldMapOpps) {
        final Set<String> CLOSING_STAGES = new Set<String>{ 'Closed Won', 'Closed Lost' };

        Id oppRTId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            ?.getRecordTypeId();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMapOpps.get(opp.Id);

            Boolean isDMTRecord      = opp.RecordTypeId == oppRTId;
            Boolean isNowClosing     = CLOSING_STAGES.contains(opp.StageName);
            Boolean wasNotYetClosing = !CLOSING_STAGES.contains(oldOpp.StageName);

            if (isDMTRecord && isNowClosing && wasNotYetClosing) {
                DMT_AsyncOrchestrator.enqueue(
                    new DMT_DynamicMapperPayload(opp.Id, 'DMT_Finish_PAWIF', opp.StageName)
                );
            }
        }
    }

    /**
     * @description Called in AFTER UPDATE trigger.
     * Detects when a DMT_Opportunity moves to a closing stage (Closed Won / Closed Lost)
     * and enqueues the DMT_Finish_PAWIF integration asynchronously via DMT_AsyncOrchestrator.
     * @param newOpps Trigger.new
     * @param oldMapOpps Trigger.oldMap
     */
    public void enqueueStageChangeIntegration(List<Opportunity> newOpps, Map<Id, Opportunity> oldMapOpps) {
        final Set<String> CLOSING_STAGES = new Set<String>{ 'Closed Won', 'Closed Lost' };

        Id oppRTId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            ?.getRecordTypeId();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMapOpps.get(opp.Id);

            Boolean isDMTRecord      = opp.RecordTypeId == oppRTId;
            Boolean isNowClosing     = CLOSING_STAGES.contains(opp.StageName);
            Boolean wasNotYetClosing = !CLOSING_STAGES.contains(oldOpp.StageName);

            if (isDMTRecord && isNowClosing && wasNotYetClosing) {
                DMT_AsyncOrchestrator.enqueue(
                    new DMT_DynamicMapperPayload(opp.Id, 'DMT_Finish_PAWIF', opp.StageName)
                );
            }
        }
    }

    /**
     */
    public void updatePassport_OppStatusChanged(List<Opportunity> newOpps, Map<Id, Opportunity> oldMapOpps) {

        Id oppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity')?.getRecordTypeId();

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newOpps) {
            if (opp.RecordTypeId == oppRTId) {
                oppIds.add(opp.Id);
            }
        }

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMapOpps.get(opp.Id);

            Boolean statusChanged = opp.StageName != oldOpp.StageName;
            Boolean passesIntegrity = opp.RecordTypeId == oppRTId;

            if (statusChanged && passesIntegrity) {
                DMT_AsyncOrchestrator.enqueue(new DMT_PassportPayload(opp.Id, opp.AccountId, 'DMTO_EvaluationOpportunity'));
            }
        }
    }

    // DEPRECATED: sustituido por DMT_Semaphore_Logic + validateSemaphoreRulesForStageChange (dmt_custom_path_opp)
    /**
     * @description Dynamically validates if the Opportunity can advance to the target Stage
     * based on the requiredAtStatus property in the Passport JSON payload.
     
    public void validateDynamicStageChange(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        Set<Id> oppIdsToCheck = new Set<Id>();
       
        for (Opportunity opp : newOpps) {
            if (opp.StageName != oldOppMap.get(opp.Id).StageName) {
                oppIdsToCheck.add(opp.Id);
            }
        }
       
        if (oppIdsToCheck.isEmpty()) return;

        Map<Id, Passport__c> passportMap = new Map<Id, Passport__c>();
        for (Passport__c p : [SELECT Opportunity__c, DMT_Passport_Save__c FROM Passport__c WHERE Opportunity__c IN :oppIdsToCheck WITH SYSTEM_MODE]) {
            if (String.isNotBlank(p.DMT_Passport_Save__c)) {
                passportMap.put(p.Opportunity__c, p);
            }
        }

        // Features approved via our own internal Case/Task workflow (Case Finished + latest approval Task result 'Yes')
        // are accepted as proof of approval alongside the Passport JSON's stateName, since the external Passport
        // engine does not always reconcile stateName back to GREEN right after our internal workflow completes.
        Map<Id, Set<String>> workflowApprovedFeaturesByOpp = new Map<Id, Set<String>>();
        for (Case c : [
            SELECT Id, opportunity_id__c, DMT_Feature_Id__c,
                (SELECT Id, DMT_Step_Result__c FROM Tasks
                 WHERE RecordType.DeveloperName = 'DMT_Step_Approval'
                 ORDER BY CreatedDate DESC LIMIT 1)
            FROM Case
            WHERE opportunity_id__c IN :oppIdsToCheck
            AND Status = :DMT_Constants.FINISHED
            AND DMT_Feature_Id__c != null
            WITH SYSTEM_MODE
        ]) {
            if (!c.Tasks.isEmpty() && c.Tasks[0].DMT_Step_Result__c == 'Yes') {
                if (!workflowApprovedFeaturesByOpp.containsKey(c.opportunity_id__c)) {
                    workflowApprovedFeaturesByOpp.put(c.opportunity_id__c, new Set<String>());
                }
                workflowApprovedFeaturesByOpp.get(c.opportunity_id__c).add(c.DMT_Feature_Id__c);
            }
        }

        for (Opportunity opp : newOpps) {
            Passport__c passport = passportMap.get(opp.Id);
            if (passport == null) continue;

            try {
                // Parse the raw JSON map to access features
                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(passport.DMT_Passport_Save__c);
                Map<String, Object> dataMap = (Map<String, Object>) root.get('data');
               
                if (dataMap == null || !dataMap.containsKey('features')) continue;
               
                List<Object> rawFeatures = (List<Object>) dataMap.get('features');
               
                for (Object featureObj : rawFeatures) {
                    Map<String, Object> featureMap = (Map<String, Object>) featureObj;
                   
                    // 1. Establish the Target Status (Fallback to 'Approval' if blank to prevent breaking)
                    String targetStatus = featureMap.containsKey('requiredAtStatus') && String.isNotBlank((String)featureMap.get('requiredAtStatus'))
                        ? (String)featureMap.get('requiredAtStatus')
                        : 'Ready to close';
                   
                    // 2. Check if the feature is Required ('Y')
                    String requiredType = featureMap.containsKey('requiredType') ? (String)featureMap.get('requiredType') : 'N';
                    Boolean isMandatory = requiredType.equalsIgnoreCase('Y');
                   
                    // 3. Dynamic Logic: If moving to the target stage, and it's mandatory, it MUST be GREEN
                    // (or already approved through our internal Case/Task workflow)
                    if (isMandatory && opp.StageName.equalsIgnoreCase(targetStatus)) {
                        String stateName = (String)featureMap.get('stateName');
                        String featureName = (String)featureMap.get('name');
                        String featureId = featureMap.get('id') != null ? String.valueOf(featureMap.get('id')) : null;

                        Boolean isGreenByPassport = stateName != null && stateName.equalsIgnoreCase('GREEN');
                        Boolean isApprovedByWorkflow = featureId != null
                            && workflowApprovedFeaturesByOpp.containsKey(opp.Id)
                            && workflowApprovedFeaturesByOpp.get(opp.Id).contains(featureId);

                        if (!isGreenByPassport && !isApprovedByWorkflow) {
                            opp.addError('Cannot advance to ' + opp.StageName + '. The required Passport feature "' + featureName + '" is not approved (Current state: ' + stateName + ').');
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error parsing Passport JSON during dynamic validation: ' + e.getMessage());
                DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(),e.getStackTraceString(),e.getLineNumber(),e.getTypeName(),'DMT_OpportunityTriggerHandler','validateDynamicStageChange','DMT',''));
            }
        }
    }*/
    /**
     * CIBGLOBALD-3748 Executed After Update. Dynamically verify that the opportunity fields
     * meet the necessary requirements to be submitted to Clan.
     */
    private static final Set<String> FIELDS_TO_CHECK = new Set<String>{
    'DMT_NUM_Version__c',
    'DMT_Opp_Id__c',
    'Name',
    'DMT_DATE_Initial_Date__c',
    'DMT_DATE_Maturity_Date__c',
    'DMT_CurrencyText__c',
    'DMT_Client_Type__c',
    'DMT_branch_id_c__c',
    'DMT_Capital_Action__c',
    'DMT_Entity__c'
    };
    /**
     * CIBGLOBALD-3748 Executed After Update. Dynamically verify that the opportunity fields
     * meet the necessary requirements to be submitted to Clan.
     */
    public void checkReadyToCloseIBF(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        System.debug('checkReadyToCloseIBF newList: ' + newList);
        Id dmtRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            Boolean shouldSend = false;
            System.debug('checkReadyToCloseIBF opp: ' + opp);
            System.debug('checkReadyToCloseIBF dmtRecordTypeId: ' + dmtRecordTypeId);
            System.debug('checkReadyToCloseIBF oldOpp.StageName: ' + oldOpp.StageName);
            System.debug('checkReadyToCloseIBF shouldSend: ' + shouldSend);
            if (opp.RecordTypeId == dmtRecordTypeId && opp.StageName == 'Ready to close' && opp.StageName != oldOpp.StageName && opp.DMT_Product_Area__c == 'IB&F') {
                shouldSend = true;
                System.debug('checkReadyToCloseIBF shouldSend 2: ' + shouldSend);
            }else if (opp.RecordTypeId == dmtRecordTypeId && opp.StageName == 'Ready to close' && hasChangedFields(opp, oldOpp) && opp.DMT_Product_Area__c == 'IB&F'){
                shouldSend = true;
                System.debug('checkReadyToCloseIBF shouldSend 3: ' + shouldSend);
            }

            if (shouldSend) {
                System.debug('checkReadyToCloseIBF opp shouldSend: ' + opp.Id);
                DMT_AsyncOrchestrator.enqueue(
                    new DMT_DynamicMapperPayload(
                        opp.Id,
                        'DMT_Opportunity_RTC_To_Clan',
                        opp.StageName
                    )
                );
            }
        }
        DMT_AsyncOrchestrator.flush();
    }
    /**
     * CIBGLOBALD-3748 Executed After Update. Dynamically verify that the opportunity fields
     * change to be submitted to Clan.
     */
    private Boolean hasChangedFields(Opportunity newOpp, Opportunity oldOpp) {
        for (String fieldName : FIELDS_TO_CHECK) {
            if (newOpp.get(fieldName) != oldOpp.get(fieldName)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description metodo de prueba para enviar opportunities a Clan sin tener que cumplir la logica del metodo checkReadyToCloseIBF.
     */
    @AuraEnabled
    public static void sendToClan(Id opportunityId) {
        Opportunity opp = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        system.debug('sendToClan opp:' + opp.Id);

        DMT_AsyncOrchestrator.enqueue(
            new DMT_DynamicMapperPayload(
                opp.Id,
                'DMT_Opportunity_RTC_To_Clan',
                opp.StageName
            )
        );
        DMT_AsyncOrchestrator.flush();

    }
    /**
     * CIBGLOBALD-3757 Dynamically Verify that the opportunities meet the necessary requirements to be submitted to GTB.
     */
    public void checkOppGTB(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        Id dmtRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            Boolean shouldSend = false;
            if (opp.RecordTypeId == dmtRecordTypeId && opp.StageName != 'Draft' && opp.StageName != oldOpp.StageName && opp.DMT_Product_Area__c == 'GTB') {
                System.debug('checkOppGTB opp: ' + opp.Id);
                DMT_AsyncOrchestrator.enqueue(
                    new DMT_DynamicMapperPayload(
                        opp.Id,
                        'DMT_Opportunity_GTB',
                        opp.StageName
                    )
                );
            }
        }
        DMT_AsyncOrchestrator.flush();
    }
    /**
     * @description metodo de prueba para enviar opportunities a GTB sin tener que cumplir la logica del metodo checkOppGTB.
     */
    @AuraEnabled
    public static void sendToGTB(Id opportunityId) {
        Opportunity opp = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        system.debug('sendToGTB opp:' + opp.Id);

        DMT_AsyncOrchestrator.enqueue(
            new DMT_DynamicMapperPayload(
                opp.Id,
                'DMT_Opportunity_GTB',
                opp.StageName
            )
        );
        DMT_AsyncOrchestrator.flush();

    }

    /**
     * CIBGLOBALD-4117: BEFORE UPDATE. Stamps DMT_DateToProposal__c on every Draft -> Proposal transition, first
     * submission or resubmission alike. This is the only place in the org that sets the field; it
     * was previously done by the AfterCreateOpportunity flow.
     *
     * Mutates Trigger.new directly instead of issuing its own update, so it persists with the same
     * save and cannot re-fire this trigger. restartApprovalTasksOnOpportunityResubmission runs
     * AFTER UPDATE and reads the pre-stamp value from Trigger.oldMap, so the two never interfere.
     */
    public void stampDateToProposal(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        Id dmtOppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(DMT_Constants.RT_OPP_DMT_NAME)?.getRecordTypeId();
        for (Opportunity opp : newOpps) {
            if (opp.RecordTypeId != dmtOppRTId) {
                continue;
            }
            Opportunity oldOpp = oldOppMap.get(opp.Id);
            if (oldOpp.StageName == DMT_Constants.DRAFT && opp.StageName == DMT_Constants.PROPOSAL) {
                opp.DMT_DateToProposal__c = Datetime.now();
            }
        }
    }

    /**
     * CIBGLOBALD-4117: AFTER UPDATE, DMT_Opportunity record type only. Restarts open approval Tasks when a watched
     * field changed, at three checkpoints - each scoped to the Cases with that passport sanction:
     *
     *   1. Leaving Draft for Proposal on a RESUBMISSION (DMT_DateToProposal__c already set) -> 'passport'
     *   2. Proposal -> Approval                                                             -> 'approval'
     *   3. Edited while already parked in Ready to close                                    -> 'readytoclose'
     *
     * Checkpoint 3 detects the change by comparing watched fields rather than trusting
     * DMT_Is_Change_in_Ready_to_close__c: some edit FlexCards set that flag on every save whether or
     * not anything watched changed, and other save paths never set it at all.
     */
    public void restartApprovalTasksOnOpportunityResubmission(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        try {
            Id dmtOppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(DMT_Constants.RT_OPP_DMT_NAME)?.getRecordTypeId();

            Set<Id> draftExitOppIds = new Set<Id>();
            Set<Id> approvalEntryOppIds = new Set<Id>();
            Set<Id> readyToCloseEditOppIds = new Set<Id>();

            for (Opportunity opp : newOpps) {
                if (opp.RecordTypeId != dmtOppRTId) {
                    continue;
                }
                Opportunity oldOpp = oldOppMap.get(opp.Id);

                if (oldOpp.StageName == DMT_Constants.DRAFT && opp.StageName == DMT_Constants.PROPOSAL && oldOpp.DMT_DateToProposal__c != null) {
                    draftExitOppIds.add(opp.Id);
                }
                if (oldOpp.StageName == DMT_Constants.PROPOSAL && opp.StageName == DMT_Constants.APPROVAL) {
                    approvalEntryOppIds.add(opp.Id);
                }
                if (oldOpp.StageName == DMT_Constants.READYTOCLOSE && opp.StageName == DMT_Constants.READYTOCLOSE) {
                    readyToCloseEditOppIds.add(opp.Id);
                }
            }

            if (draftExitOppIds.isEmpty() && approvalEntryOppIds.isEmpty() && readyToCloseEditOppIds.isEmpty()) {
                return;
            }

            Map<Id, Opportunity> newOppsById = new Map<Id, Opportunity>(newOpps);
            restartApprovalTasksForOpportunities(draftExitOppIds, 'passport', newOppsById);
            restartApprovalTasksForOpportunities(approvalEntryOppIds, 'approval', newOppsById);
            restartApprovalTasksForOpportunities(readyToCloseEditOppIds, 'readytoclose', newOppsById);
        } catch (Exception e) {
            logRestartFailure(e, 'Opportunity', 'restartApprovalTasksOnOpportunityResubmission');
        }
    }

    /**
     * CIBGLOBALD-4117: Shared by all three checkpoints - only the Opportunity Ids and the sanction filter differ.
     * Keeps only what is specific to Opportunity (finding this checkpoint's Cases) and hands the
     * rest to DMT_ApprovalChangeStep_Helper.restartStaleApprovalTasks(), shared with
     * DMT_Line_Helper.
     *
     * Called once per checkpoint, so each gets its own sync/async threshold.
     * Queries per call: 1 Case + 2 in the shared gate + 1 per child section.
     */
    private void restartApprovalTasksForOpportunities(Set<Id> qualifyingOppIds, String passportSanctionFilter, Map<Id, Opportunity> newOppsById) {
        if (qualifyingOppIds.isEmpty()) {
            return;
        }
        try {
            Map<Id, Id> caseIdToOppId = new Map<Id, Id>();
            for (Case c : [
                SELECT Id, opportunity_id__c
                FROM Case
                WHERE opportunity_id__c IN :qualifyingOppIds
                AND IsDeleted = false
                AND DMT_Passport_Sanction__c = :passportSanctionFilter
            ]) {
                caseIdToOppId.put(c.Id, c.opportunity_id__c);
            }
            if (caseIdToOppId.isEmpty()) {
                return;
            }

            Map<Id, SObject> qualifyingOpps = new Map<Id, SObject>();
            for (Id oppId : qualifyingOppIds) {
                if (newOppsById.containsKey(oppId)) {
                    qualifyingOpps.put(oppId, newOppsById.get(oppId));
                }
            }

            DMT_ApprovalChangeStep_Helper.restartStaleApprovalTasks(
                caseIdToOppId,
                newOppsById.values(),
                'opportunity',
                DMT_SnapshotChildComparator.forRecords(qualifyingOpps),
                'DMT_OpportunityTriggerHandler'
            );
        } catch (Exception e) {
            logRestartFailure(e, 'Opportunity', 'restartApprovalTasksForOpportunities');
        }
    }

    private static void logRestartFailure(Exception e, String objectName, String methodName) {
        DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
            e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),
            'DMT_OpportunityTriggerHandler', methodName, 'DMT', objectName
        ));
    }

    public void autoStartFirstBusinessApprovalFeature(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppMap) {
        Id dmtOppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(DMT_Constants.RT_OPP_DMT_NAME)?.getRecordTypeId();
        Set<Id> approvalEntryOppIds = new Set<Id>();
        for (Opportunity opp : newOpps) {
            if (opp.RecordTypeId != dmtOppRTId) continue;
            Opportunity oldOpp = oldOppMap.get(opp.Id);
            if (oldOpp != null && oldOpp.StageName == DMT_Constants.PROPOSAL && opp.StageName == DMT_Constants.APPROVAL) {
                approvalEntryOppIds.add(opp.Id);
            }
        }
        if (approvalEntryOppIds.isEmpty()) {
            return;
        }
        Set<Id> oppIdsWithExistingApprovalCase = new Set<Id>();
        for (Case c : DMT_Case_Steps_Selector.getApprovalCasesByOpportunityIds(approvalEntryOppIds)) {
            oppIdsWithExistingApprovalCase.add(c.opportunity_id__c);
        }

        for (Id oppId : approvalEntryOppIds) {
            if (oppIdsWithExistingApprovalCase.contains(oppId)) continue;
            DMT_Case_Steps_Controller.startFirstBusinessApprovalFeature(oppId);
        }
    }
}