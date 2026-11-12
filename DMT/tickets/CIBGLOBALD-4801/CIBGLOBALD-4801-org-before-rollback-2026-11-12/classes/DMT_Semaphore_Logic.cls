public with sharing class DMT_Semaphore_Logic {

    public class SemaphoreRule {
        public String requiredStatus;
        public String requiredColorCapability;
        public String requiredColorWorkflow;
        public String colorLogicalOperatorType;
    }

    public static Boolean evaluate(SemaphoreRule rule, String currentCapabilityColor, String currentWorkflowColor) {
        Boolean capabilityOk = isColorAllowed(currentCapabilityColor, rule.requiredColorCapability);
        Boolean workflowOk = isColorAllowed(currentWorkflowColor, rule.requiredColorWorkflow);

        if (rule.colorLogicalOperatorType == 'AND') return capabilityOk && workflowOk;
        if (rule.colorLogicalOperatorType == 'OR') return capabilityOk || workflowOk;

        // No operator
        Boolean hasCapability = String.isNotBlank(rule.requiredColorCapability);
        Boolean hasWorkflow   = String.isNotBlank(rule.requiredColorWorkflow);
        if (hasCapability && hasWorkflow) return capabilityOk || workflowOk;
        if (hasCapability) return capabilityOk;
        if (hasWorkflow)   return workflowOk;
        return false;
    }

    private static Boolean isColorAllowed(String currentColor, String allowedColorsRaw) {
        if (String.isBlank(allowedColorsRaw) || String.isBlank(currentColor)) return false;
        Set<String> allowedColors = new Set<String>(allowedColorsRaw.split(';'));
        return allowedColors.contains(currentColor.trim().toUpperCase());
    }

    public static Boolean isRuleApplicable(SemaphoreRule rule, String currentFunctionalStatus) {
        return rule.requiredStatus != null && rule.requiredStatus.equalsIgnoreCase(currentFunctionalStatus);
    }

    public static String normalizeToShortColor(String rawColor) {
        if (String.isBlank(rawColor)) {
            return null;
        }
        String upper = rawColor.trim().toUpperCase();
        if (upper == 'GREEN' || upper == 'GRE') return 'GRE';
        if (upper == 'YELLOW' || upper == 'YEL') return 'YEL';
        if (upper == 'RED') return 'RED';
        if (upper == 'WHITE' || upper == 'WHI') return 'WHI';
        if (upper == 'GRAY' || upper == 'GRA') return 'GRA';
        return null;
    }

    // CIBGLOBALD-4801 - Values read from the Passport JSON (Passport__c.DMT_Passport_Save__c) and from the approval Tasks
    private static final String REQUIRED_TYPE_YES = 'Y';
    private static final String SANCTION_APPROVAL = 'approval';
    private static final String STEP_RESULT_YES = 'Yes';
    private static final String STEP_RESULT_NO = 'No';
    private static final String CASE_STATUS_IN_PROGRESS = 'In Progress';
    private static final String STATUS_CLOSED_WON = 'Closed Won';

    /**
     * CIBGLOBALD-4801 - Passport features and Approval Cases of one Opportunity or DMT Line, as the traffic light
     * rules need them. cases are newest first, each with its latest DMT_Step_Approval Task (DMT_Case_Steps_Selector).
     */
    public class RecordFeatureData {
        public Boolean hasPassport = false;
        public List<Object> features = new List<Object>();
        public List<Case> cases = new List<Case>();
    }

    /**
     * CIBGLOBALD-4801 - Loads the newest Passport and the Approval Cases of several Opportunities or several DMT Lines
     * (one object per call): 2 SOQL in total. The selector runs without sharing, so an approver who cannot see every
     * Case gets the same result as the owner. Throws when the Passport JSON cannot be parsed, so the caller blocks.
     * @param recordIds Opportunity Ids or DMT_Line__c Ids
     * @return record Id -> its data; every requested Id is present
     */
    public static Map<Id, RecordFeatureData> loadFeatureData(Set<Id> recordIds) {
        Map<Id, RecordFeatureData> dataByRecordId = new Map<Id, RecordFeatureData>();
        if (recordIds == null || recordIds.isEmpty()) {
            return dataByRecordId;
        }
        for (Id recordId : recordIds) {
            dataByRecordId.put(recordId, new RecordFeatureData());
        }
        Boolean isOpportunity = new List<Id>(recordIds)[0].getSObjectType() == Opportunity.SObjectType;

        List<Passport__c> passports = isOpportunity
            ? DMT_Case_Steps_Selector.getPassportsByOpportunityIds(recordIds)
            : DMT_Case_Steps_Selector.getPassportsByLineIds(recordIds);
        for (Passport__c passport : passports) {
            RecordFeatureData data = dataByRecordId.get(isOpportunity ? passport.Opportunity__c : passport.DMT_Line__c);
            // Newest Passport first (selector order): keep only that one
            if (data == null || data.hasPassport || String.isBlank(passport.DMT_Passport_Save__c)) {
                continue;
            }
            data.hasPassport = true;
            data.features = getPassportFeatures(passport.DMT_Passport_Save__c);
        }

        List<Case> cases = isOpportunity
            ? DMT_Case_Steps_Selector.getApprovalCasesByOpportunityIds(recordIds)
            : DMT_Case_Steps_Selector.getApprovalCasesByLineIds(recordIds);
        for (Case approvalCase : cases) {
            RecordFeatureData data = dataByRecordId.get(isOpportunity ? approvalCase.opportunity_id__c : approvalCase.DMT_Line__c);
            if (data != null) {
                data.cases.add(approvalCase);
            }
        }
        return dataByRecordId;
    }

    /**
     * CIBGLOBALD-4801 - data.features of a saved Passport JSON (Passport__c.DMT_Passport_Save__c); empty when the JSON
     * has no features. Throws when the JSON is not valid.
     */
    public static List<Object> getPassportFeatures(String passportJson) {
        if (String.isBlank(passportJson)) {
            return new List<Object>();
        }
        Object data = ((Map<String, Object>) JSON.deserializeUntyped(passportJson)).get('data');
        Object features = data instanceof Map<String, Object> ? ((Map<String, Object>) data).get('features') : null;
        return features instanceof List<Object> ? (List<Object>) features : new List<Object>();
    }

    /**
     * CIBGLOBALD-4801 - Required Passport features that block moving an Opportunity or a DMT Line to targetStatus.
     * A feature applies when requiredType is Y, it has a traffic light rule (requiredColorCapability and/or
     * requiredColorWorkflow) and requiredStatus is targetStatus ('Closed' also counts for 'Closed Won'), whatever
     * its passportSanction. Capability color = stateName. Workflow color = latest Case of the feature
     * (resolveWorkflowColor), YEL when the feature has tasks but no Case yet. The rule is DMT_Semaphore_Logic.evaluate
     * with colorLogicalOperatorType. Moving to Closed Lost is never blocked.
     * Callers: DMT_FeaturesController.validateSemaphoreRulesForStageChange (path LWCs dmt_custom_path_opp,
     * dmt_custom_path_line, hvsc_oppClosingFlow), DMT_Case_Steps_Controller.moveStatusToReadyToClose,
     * DMT_Line_Helper.avoidPassingApproval.
     * @param features Passport JSON data.features
     * @param casesNewestFirst Approval Cases of the record, newest first, with their latest step Task
     * @param targetStatus stage the record moves to
     * @return names of the blocking features; empty when the move can go ahead
     */
    public static List<String> getBlockingFeatureNames(List<Object> features, List<Case> casesNewestFirst, String targetStatus) {
        List<String> blockingFeatureNames = new List<String>();
        if (features == null || String.isBlank(targetStatus) || 'Closed Lost'.equalsIgnoreCase(targetStatus)) {
            return blockingFeatureNames;
        }
        Map<String, Case> latestCaseByFeatureId = getLatestCaseByFeatureId(casesNewestFirst);

        for (Object rawFeature : features) {
            if (!(rawFeature instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> feature = (Map<String, Object>) rawFeature;
            SemaphoreRule rule = new SemaphoreRule();
            rule.requiredStatus = asString(feature.get('requiredStatus'));
            rule.requiredColorCapability = asString(feature.get('requiredColorCapability'));
            rule.requiredColorWorkflow = asString(feature.get('requiredColorWorkflow'));
            rule.colorLogicalOperatorType = asString(feature.get('colorLogicalOperatorType'));

            Boolean hasTrafficLightRule = String.isNotBlank(rule.requiredColorCapability) || String.isNotBlank(rule.requiredColorWorkflow);
            if (!REQUIRED_TYPE_YES.equalsIgnoreCase(asString(feature.get('requiredType'))) || !hasTrafficLightRule
                    || !appliesToTargetStatus(rule.requiredStatus, targetStatus)) {
                continue;
            }

            Case featureCase = latestCaseByFeatureId.get(asString(feature.get('id')));
            Object tasks = feature.get('tasks');
            Boolean hasTasks = tasks instanceof List<Object> && !((List<Object>) tasks).isEmpty();
            String workflowColor = featureCase != null
                ? resolveWorkflowColor(featureCase.Status, getLatestStepResult(featureCase))
                : (hasTasks ? 'YEL' : null);

            if (!evaluate(rule, normalizeToShortColor(asString(feature.get('stateName'))), normalizeToShortColor(workflowColor))) {
                blockingFeatureNames.add(asString(feature.get('name')));
            }
        }
        return blockingFeatureNames;
    }

    /**
     * CIBGLOBALD-4801 - True when every 'approval' feature of the Passport that has tasks (only those can get a Case)
     * has its latest Case Finished with the latest DMT_Step_Approval Task result Yes. Used by the automatic move to Ready to close of Opportunities
     * (DMT_Case_Steps_Controller.moveStatusToReadyToClose) and Lines (DMT_Line_Helper.avoidPassingApproval,
     * DMT_Line__c.DMT_Approval_Validation__c).
     */
    public static Boolean areApprovalFeaturesApproved(List<Object> features, List<Case> casesNewestFirst) {
        Map<String, Case> latestCaseByFeatureId = getLatestCaseByFeatureId(casesNewestFirst);
        for (Object rawFeature : features == null ? new List<Object>() : features) {
            if (!(rawFeature instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> feature = (Map<String, Object>) rawFeature;
            String featureId = asString(feature.get('id'));
            Object tasks = feature.get('tasks');
            Boolean hasTasks = tasks instanceof List<Object> && !((List<Object>) tasks).isEmpty();
            if (featureId == null || !hasTasks || !SANCTION_APPROVAL.equalsIgnoreCase(asString(feature.get('passportSanction')))) {
                continue;
            }
            Case featureCase = latestCaseByFeatureId.get(featureId);
            if (featureCase == null || featureCase.Status != DMT_Constants.FINISHED
                    || getLatestStepResult(featureCase) != STEP_RESULT_YES) {
                return false;
            }
        }
        return true;
    }

    /**
     * CIBGLOBALD-4801 - Workflow color of a feature from its Case status and latest step result, the same colors the
     * Passport cards show (dmt_passport, dmt_passport_opportunity): Pending / In Progress = YEL, Finished + No = RED,
     * Finished + Yes = GRE, Finished without result = GRA. Moved from DMT_FeaturesController.
     */
    public static String resolveWorkflowColor(String caseStatus, String stepResult) {
        if (caseStatus == DMT_Constants.FINISHED) {
            if (stepResult == STEP_RESULT_NO) {
                return 'RED';
            }
            if (stepResult == STEP_RESULT_YES) {
                return 'GRE';
            }
            return String.isBlank(stepResult) ? 'GRA' : null;
        }
        if (caseStatus == DMT_Constants.PENDING || caseStatus == CASE_STATUS_IN_PROGRESS) {
            return 'YEL';
        }
        return null;
    }

    // CIBGLOBALD-4801 - requiredStatus of the Passport (upper case, e.g. READY TO CLOSE) against the target stage
    private static Boolean appliesToTargetStatus(String requiredStatus, String targetStatus) {
        if (String.isBlank(requiredStatus)) {
            return false;
        }
        return requiredStatus.equalsIgnoreCase(targetStatus)
            || (STATUS_CLOSED_WON.equalsIgnoreCase(targetStatus) && DMT_Constants.CLOSED.equalsIgnoreCase(requiredStatus));
    }

    // CIBGLOBALD-4801 - newest Case per DMT_Feature_Id__c (the list comes newest first)
    private static Map<String, Case> getLatestCaseByFeatureId(List<Case> casesNewestFirst) {
        Map<String, Case> latestCaseByFeatureId = new Map<String, Case>();
        for (Case approvalCase : casesNewestFirst == null ? new List<Case>() : casesNewestFirst) {
            if (String.isNotBlank(approvalCase.DMT_Feature_Id__c) && !latestCaseByFeatureId.containsKey(approvalCase.DMT_Feature_Id__c)) {
                latestCaseByFeatureId.put(approvalCase.DMT_Feature_Id__c, approvalCase);
            }
        }
        return latestCaseByFeatureId;
    }

    // CIBGLOBALD-4801 - DMT_Step_Result__c of the latest step Task loaded with the Case (selector subquery)
    private static String getLatestStepResult(Case approvalCase) {
        List<Task> tasks = approvalCase.getSObjects('Tasks');
        return tasks == null || tasks.isEmpty() ? null : tasks[0].DMT_Step_Result__c;
    }

    // CIBGLOBALD-4801 - JSON value as text (ids and flags can come as numbers)
    private static String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }
}