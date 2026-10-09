/**
 * @description Denormalizes Group Name / Main Holder Name onto the Opportunity (Grupo y Main
 * Holder en Opportunity tras migración Multiholder) so Salesforce Reports and other processes can
 * read them directly, without needing to consult/send the full Multiholder structure to ADA.
 * - Group Name: taken directly from Custom_Association_Opportunity__c.Group__c when populated
 *   (fed by the external Multiholder system); otherwise falls back to the same resolution NBC
 *   views already use (DMT_HPG_Utils.buildClientGroupStructure traversal off the Opportunity's
 *   Account) - pure SOQL, safe to call from trigger context.
 * - Main Holder Name: for Multiholder Opportunities, the client flagged via
 *   Custom_Association_Opportunity__c.g_customer_id__c; for non-Multiholder Opportunities, the
 *   Opportunity's own Account name (DMT_HPG_Utils.getMainHolderNames()).
 */
public without sharing class DMT_OpportunityGroupHolderService {

    /**
     * @description Recomputes and persists DMT_Group_Name__c / DMT_Main_Holder_Name__c for the
     * given Opportunities. Bulk-safe. Wraps its own update DML with TriggerBypass so it can be
     * called from a trigger context (DMT_CustomAssocOppTrigger) without causing recursion.
     * @param opportunityIds Ids of the Opportunities to (re)sync
     */
    public static void syncGroupAndMainHolderNames(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }

        Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>([
            SELECT Id, AccountId, Account.Name, DMT_Group_Name__c, DMT_Main_Holder_Name__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
            WITH USER_MODE
        ]);
        if (opportunities.isEmpty()) {
            return;
        }

        Map<Id, String> groupNameFromAssociationByOppId = new Map<Id, String>();
        for (Custom_Association_Opportunity__c assoc : [
            SELECT Opportunity__c, Group__r.Name
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c IN :opportunities.keySet() AND Group__c != null
            WITH USER_MODE
            ORDER BY CreatedDate
        ]) {
            if (!groupNameFromAssociationByOppId.containsKey(assoc.Opportunity__c)) {
                groupNameFromAssociationByOppId.put(assoc.Opportunity__c, assoc.Group__r.Name);
            }
        }

        Map<Id, String> fallbackAccountNameByOppId = new Map<Id, String>();
        for (Opportunity opp : opportunities.values()) {
            fallbackAccountNameByOppId.put(opp.Id, opp.Account != null ? opp.Account.Name : null);
        }
        Map<Id, String> mainHolderNameByOppId = DMT_HPG_Utils.getMainHolderNames(opportunities.keySet(), fallbackAccountNameByOppId);

        List<Opportunity> toUpdate = new List<Opportunity>();
        for (Opportunity opp : opportunities.values()) {
            String groupName = groupNameFromAssociationByOppId.get(opp.Id);
            if (groupName == null) {
                groupName = '';
                if (opp.AccountId != null) {
                    Map<String, Object> hierarchy = DMT_HPG_Utils.buildClientGroupStructure(opp.AccountId);
                    groupName = hierarchy.get('groupName') != null ? (String) hierarchy.get('groupName') : '';
                }
            }
            String mainHolderName = mainHolderNameByOppId.get(opp.Id);

            if (opp.DMT_Group_Name__c != groupName || opp.DMT_Main_Holder_Name__c != mainHolderName) {
                toUpdate.add(new Opportunity(
                    Id = opp.Id,
                    DMT_Group_Name__c = groupName,
                    DMT_Main_Holder_Name__c = mainHolderName
                ));
            }
        }

        if (toUpdate.isEmpty()) {
            return;
        }

        Boolean alreadyBypassed = TriggerBypass.bypassTrigger;
        if (!alreadyBypassed) {
            TriggerBypass.setBypass();
        }
        try {
            update toUpdate;
        } finally {
            if (!alreadyBypassed) {
                TriggerBypass.removeBypass();
            }
        }
    }
}