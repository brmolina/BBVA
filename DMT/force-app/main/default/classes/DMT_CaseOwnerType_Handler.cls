/**
 * @description       : Resolver de tipo de Owner + tipo de Case para Integration Procedure
 * @author            : GitHub Copilot
 * @last modified on  : 05-11-2026
 **/
global without sharing class DMT_CaseOwnerType_Handler implements Callable {

    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }

    private static Object invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        try {
            if (methodName == 'getOwnerCaseType') {
                String caseId = (String) inputMap.get('caseId');
                System.debug('TEST ALEX');
                ResponseWrapper result = getOwnerCaseType(caseId);
                outMap.put('result', result.updated);
                return outMap;
            }

            throw new AuraHandledException('Unsupported method: ' + methodName);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'DMT_CaseOwnerType_Handler error: ' + e.getMessage());
            System.enqueueJob(new DMT_LogExceptionQueueable(
                e.getMessage(),
                e.getStackTraceString(),
                e.getLineNumber(),
                e.getTypeName(),
                'DMT_CaseOwnerType_Handler',
                'invokeMethod',
                'DMT',
                ''
            ));
            throw e;
        }
    }

    // CIBGLOBALD-4117: single-Id signature kept exactly as-is (String, not List<Id>) so the
    // Approver_UpdateStep Integration Procedure's Remote Action - which calls this method by name -
    // never needs to change. All the real logic now lives in the bulk method below; every other
    // caller (DMT_Massive_Task_Closure_Service, DMT_ApprovalTemplate_Controller, and any future one)
    // should call getOwnerCaseTypes() directly instead of looping this wrapper one Id at a time.
    @AuraEnabled(cacheable=false)
    public static ResponseWrapper getOwnerCaseType(String caseId) {
        if (String.isBlank(caseId)) {
            throw new AuraHandledException('caseId is required.');
        }
        Map<Id, ResponseWrapper> results = getOwnerCaseTypes(new List<Id>{ (Id) caseId });
        ResponseWrapper response = results.get((Id) caseId);
        return response != null ? response : new ResponseWrapper();
    }

    /**
     * Bulk version of getOwnerCaseType() - for each Opportunity case owned by a Business-type
     * approver's queue, with a sanction of approval/readytoclose, stamps
     * Opportunity.DMT_Bussiness_Approved_Date__c = today and reports it as updated. One query per
     * object regardless of how many case Ids are given.
     */
    public static Map<Id, ResponseWrapper> getOwnerCaseTypes(List<Id> caseIds) {
        Map<Id, ResponseWrapper> resultByCaseId = new Map<Id, ResponseWrapper>();
        if (caseIds == null || caseIds.isEmpty()) {
            return resultByCaseId;
        }

        Map<Id, Case> caseMap = new Map<Id, Case>([
            SELECT Id, OwnerId, DMT_LineOpportunity__c, DMT_Passport_Sanction__c, opportunity_id__c
            FROM Case
            WHERE Id IN :caseIds
        ]);
        for (Id caseId : caseIds) {
            resultByCaseId.put(caseId, new ResponseWrapper());
        }

        Set<Id> ownerIds = new Set<Id>();
        for (Case c : caseMap.values()) {
            if (c.DMT_LineOpportunity__c == 'O' && c.opportunity_id__c != null
                    && c.OwnerId != null && c.OwnerId.getSObjectType() == Group.SObjectType) {
                ownerIds.add(c.OwnerId);
            }
        }
        if (ownerIds.isEmpty()) {
            return resultByCaseId;
        }

        Map<Id, Group> groupById = new Map<Id, Group>([
            SELECT Id, DeveloperName FROM Group WHERE Id IN :ownerIds
        ]);
        Set<String> groupDeveloperNames = new Set<String>();
        for (Group g : groupById.values()) {
            groupDeveloperNames.add(g.DeveloperName);
        }

        Map<String, DMT_Approver__c> approverByGroupName = new Map<String, DMT_Approver__c>();
        for (DMT_Approver__c approver : [
            SELECT Id, DMT_Group__c, DMT_ApproverType__r.Name
            FROM DMT_Approver__c
            WHERE DMT_Group__c IN :groupDeveloperNames
        ]) {
            approverByGroupName.put(approver.DMT_Group__c, approver);
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Set<Id> processedOppIds = new Set<Id>();
        for (Case c : caseMap.values()) {
            Group g = groupById.get(c.OwnerId);
            if (g == null) {
                continue;
            }
            DMT_Approver__c approver = approverByGroupName.get(g.DeveloperName);
            Boolean isBusinessApprover = approver != null
                && approver.DMT_ApproverType__r != null
                && approver.DMT_ApproverType__r.Name != null
                && approver.DMT_ApproverType__r.Name.equalsIgnoreCase('Business');

            String sanction = c.DMT_Passport_Sanction__c;
            Boolean isAllowedSanction = !String.isBlank(sanction)
                && (sanction.equalsIgnoreCase('approval') || sanction.equalsIgnoreCase('readytoclose'));

            if (isBusinessApprover && isAllowedSanction) {
                resultByCaseId.get(c.Id).updated = true;
                // Two Cases can share the same Opportunity - only one update per Opportunity Id is
                // allowed in a single DML call, so the flag above still reports per-Case, but the
                // actual write is deduplicated.
                if (!processedOppIds.contains(c.opportunity_id__c)) {
                    processedOppIds.add(c.opportunity_id__c);
                    oppsToUpdate.add(new Opportunity(
                        Id = c.opportunity_id__c,
                        DMT_Bussiness_Approved_Date__c = Date.today()
                    ));
                }
            }
        }

        DMT_DmlUtils.updateMany(oppsToUpdate, 'getOwnerCaseTypes');
        return resultByCaseId;
    }

    global class ResponseWrapper {
        @AuraEnabled public Boolean updated = false;
    }
}