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

    @AuraEnabled(cacheable=false)
    public static ResponseWrapper getOwnerCaseType(String caseId) {
        if (String.isBlank(caseId)) {
            throw new AuraHandledException('caseId is required.');
        }

        Case c = [
            SELECT Id,
                   OwnerId,
                   DMT_LineOpportunity__c,
                   DMT_Passport_Sanction__c,
                   opportunity_id__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        Id ownerToAnalyze = c.OwnerId;
        ResponseWrapper response = new ResponseWrapper();
        response.updated = false;
        // Update Opportunity approved date only for Opportunity cases and queue owners.
        if (c.DMT_LineOpportunity__c == 'O'
            && c.opportunity_id__c != null
            && ownerToAnalyze != null
            && ownerToAnalyze.getSObjectType() == Group.SObjectType) {

            Group g = DMT_CaseOwnerType_Selector.getGroupById(ownerToAnalyze);
            DMT_Approver__c approver = DMT_CaseOwnerType_Selector.getApproverWithTypeByGroupDeveloperName(g.DeveloperName);

            Boolean isBusinessApprover = approver != null
                && approver.DMT_ApproverType__r != null
                && approver.DMT_ApproverType__r.Name != null
                && approver.DMT_ApproverType__r.Name.equalsIgnoreCase('Business');

            String sanction = c.DMT_Passport_Sanction__c;
            Boolean isAllowedSanction = !String.isBlank(sanction)
                && (sanction.equalsIgnoreCase('approval')
                    || sanction.equalsIgnoreCase('readytoclose'));

            if (isBusinessApprover && isAllowedSanction) {
                update new Opportunity(
                    Id = c.opportunity_id__c,
                    DMT_Bussiness_Approved_Date__c = Date.today()
                );
                response.updated = true;
            }
        }
        
        return response;
    }

    global class ResponseWrapper {
        @AuraEnabled public Boolean updated;
    }
}