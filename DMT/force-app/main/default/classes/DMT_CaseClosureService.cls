/**
 * Single responsibility: set a Case's Status. Used both to finish a case (approval complete) and to
 * send it back to In Progress (routing to the next approver) - the status itself is the caller's
 * decision, this class only applies it safely in bulk.
 *
 * Every entry point that closes or re-opens a Case's status - the bulk massive-closure modal, the
 * single-task approval screen, and any future caller - must call this same class and method, so
 * "how a Case's status gets set" can never drift into two different implementations again.
 */
public with sharing class DMT_CaseClosureService {

    public static void setStatus(Id caseId, String status) {
        setStatuses(new List<Id>{ caseId }, status);
    }

    public static void setStatuses(List<Id> caseIds, String status) {
        if (caseIds == null || caseIds.isEmpty() || String.isBlank(status)) {
            return;
        }
        List<Case> casesToUpdate = new List<Case>();
        for (Id caseId : caseIds) {
            if (caseId != null) {
                casesToUpdate.add(new Case(Id = caseId, Status = status));
            }
        }
        DMT_DmlUtils.updateMany(casesToUpdate, 'setStatuses');
    }
}