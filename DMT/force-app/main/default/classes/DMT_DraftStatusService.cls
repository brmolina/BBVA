/**
 * Single responsibility: move a Line and/or Opportunity back to Draft (used when an approver
 * returns a proposal for rework). Mirrors the Approver_UpdateStep Integration Procedure's
 * "UpdateLineOppToDraft" block, which runs the same DataRaptor Load transform twice - once with
 * CancelValue=false, then again with CancelValue=true - replicated here as two update passes over
 * the same records so the side effects match exactly.
 */
public with sharing class DMT_DraftStatusService {

    public static void moveToDraft(Id lineId, Id oppId) {
        moveToDraft(
            lineId != null ? new List<Id>{ lineId } : new List<Id>(),
            oppId != null ? new List<Id>{ oppId } : new List<Id>()
        );
    }

    public static void moveToDraft(List<Id> lineIds, List<Id> oppIds) {
        Set<Id> lineIdSet = new Set<Id>(lineIds == null ? new List<Id>() : lineIds);
        Set<Id> oppIdSet = new Set<Id>(oppIds == null ? new List<Id>() : oppIds);
        lineIdSet.remove(null);
        oppIdSet.remove(null);

        if (lineIdSet.isEmpty() && oppIdSet.isEmpty()) {
            return;
        }

        List<DMT_Line__c> lines = lineIdSet.isEmpty() ? new List<DMT_Line__c>() : [
            SELECT Id, Status__c, Allowed__c FROM DMT_Line__c WHERE Id IN :lineIdSet WITH SYSTEM_MODE
        ];
        List<Opportunity> opps = oppIdSet.isEmpty() ? new List<Opportunity>() : [
            SELECT Id, StageName, DMT_Cancel__c FROM Opportunity WHERE Id IN :oppIdSet WITH SYSTEM_MODE
        ];

        if (lines.isEmpty() && opps.isEmpty()) {
            return;
        }

        applyDraftValues(lines, opps, false);
        applyDraftValues(lines, opps, true);
    }

    private static void applyDraftValues(List<DMT_Line__c> lines, List<Opportunity> opps, Boolean cancelValue) {
        List<SObject> toUpdate = new List<SObject>();
        for (DMT_Line__c line : lines) {
            line.Status__c = 'Draft';
            line.Allowed__c = cancelValue;
            toUpdate.add(line);
        }
        for (Opportunity opp : opps) {
            opp.StageName = 'Draft';
            opp.DMT_Cancel__c = cancelValue;
            toUpdate.add(opp);
        }
        DMT_DmlUtils.updateMany(toUpdate, 'moveToDraft_' + cancelValue);
    }
}