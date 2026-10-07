/**
 * Single responsibility: move ContentDocumentLinks from a Case to the Task that closed it, so
 * documents attached during the approval process stay with the historical record of that decision.
 * Bulk-safe - one query per object regardless of how many Case/Task pairs are given - and dedupes
 * against links that already exist on the target Task, so calling this twice for the same pair
 * never creates duplicate links.
 *
 * This is deliberately the one responsibility in this refactor that callers should run through
 * DMT_AsyncOrchestrator (see DMT_DocumentTransferPayload) rather than inline: its real cost scales
 * with how many documents are attached to a Case, which has no relationship to how many
 * tasks/cases are being closed in the same transaction, so it can't be bounded by input size alone
 * the way the other single-responsibility services here can.
 */
public with sharing class DMT_DocumentTransferService {

    public static void transferDocuments(Id caseId, Id taskId) {
        transferDocuments(new Map<Id, Id>{ caseId => taskId });
    }

    public static void transferDocuments(Map<Id, Id> taskIdByCaseId) {
        if (taskIdByCaseId == null || taskIdByCaseId.isEmpty()) {
            return;
        }

        Map<Id, Id> validTaskIdByCaseId = new Map<Id, Id>();
        for (Id caseId : taskIdByCaseId.keySet()) {
            Id taskId = taskIdByCaseId.get(caseId);
            if (caseId != null && taskId != null) {
                validTaskIdByCaseId.put(caseId, taskId);
            }
        }
        if (validTaskIdByCaseId.isEmpty()) {
            return;
        }

        Set<Id> caseIds = validTaskIdByCaseId.keySet();
        Map<Id, List<ContentDocumentLink>> existingByCaseId = new Map<Id, List<ContentDocumentLink>>();
        for (ContentDocumentLink link : [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :caseIds
            WITH SYSTEM_MODE
        ]) {
            if (!existingByCaseId.containsKey(link.LinkedEntityId)) {
                existingByCaseId.put(link.LinkedEntityId, new List<ContentDocumentLink>());
            }
            existingByCaseId.get(link.LinkedEntityId).add(link);
        }
        if (existingByCaseId.isEmpty()) {
            return;
        }

        Set<Id> targetTaskIds = new Set<Id>(validTaskIdByCaseId.values());
        Map<String, Boolean> existingTaskLinks = new Map<String, Boolean>();
        for (ContentDocumentLink taskLink : [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :targetTaskIds
            WITH SYSTEM_MODE
        ]) {
            existingTaskLinks.put(taskLink.LinkedEntityId + ':' + taskLink.ContentDocumentId, true);
        }

        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        List<ContentDocumentLink> linksToDelete = new List<ContentDocumentLink>();
        for (Id caseId : existingByCaseId.keySet()) {
            Id targetTaskId = validTaskIdByCaseId.get(caseId);
            List<ContentDocumentLink> caseLinks = existingByCaseId.get(caseId);
            linksToDelete.addAll(caseLinks);
            for (ContentDocumentLink old : caseLinks) {
                String linkKey = targetTaskId + ':' + old.ContentDocumentId;
                if (existingTaskLinks.containsKey(linkKey)) {
                    continue;
                }
                newLinks.add(new ContentDocumentLink(
                    ContentDocumentId = old.ContentDocumentId,
                    LinkedEntityId    = targetTaskId,
                    ShareType         = 'V',
                    Visibility        = 'InternalUsers'
                ));
            }
        }

        // Insert the new links before deleting the old ones, so a mid-operation failure never
        // leaves a moment where the record has no linked documents at all.
        DMT_DmlUtils.insertMany(newLinks, 'transferDocuments_insert');
        DMT_DmlUtils.deleteMany(linksToDelete, 'transferDocuments_delete');
    }
}