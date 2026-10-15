/**
 * @description Denormalizes Group Name / Main Holder Name onto the Opportunity for Salesforce Reports and other processes.
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
            SELECT Id, AccountId, Account.Name, DMT_Group_Name__c, DMT_Main_Holder_Name__c,
                Entific__c, DMT_Booking_Unit_Risk_Analyst__c, DMT_Booking_Unit_Risk_Analyst__r.DMT_Entific__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
            WITH USER_MODE
        ]);
        if (opportunities.isEmpty()) {
            return;
        }

        Map<Id, String> groupNameFromAssociationByOppId = queryGroupNameFromAssociationByOppId(opportunities.keySet());

        Map<Id, String> fallbackAccountNameByOppId = new Map<Id, String>();
        for (Opportunity opp : opportunities.values()) {
            fallbackAccountNameByOppId.put(opp.Id, opp.Account != null ? opp.Account.Name : null);
        }
        Map<Id, String> mainHolderNameByOppId = DMT_HPG_Utils.getMainHolderNames(opportunities.keySet(), fallbackAccountNameByOppId);

        List<Opportunity> toUpdate = buildOpportunitiesToUpdate(opportunities.values(), groupNameFromAssociationByOppId, mainHolderNameByOppId);

        if (toUpdate.isEmpty()) {
            return;
        }

        updateWithBypass(toUpdate);
    }

    /**
     * @description Builds the list of Opportunity records to update with their resolved Group Name
     * and Main Holder Name, skipping Opportunities whose current values already match or that
     * would fail the Booking Unit Risk Analyst / Entific validation rule.
     * @param opportunities Opportunities to evaluate
     * @param groupNameFromAssociationByOppId Group Name per Opportunity Id sourced from Group__c
     * @param mainHolderNameByOppId Main Holder Name per Opportunity Id
     * @return the Opportunity records (Id + changed fields only) that need to be updated
     */
    private static List<Opportunity> buildOpportunitiesToUpdate(
        List<Opportunity> opportunities,
        Map<Id, String> groupNameFromAssociationByOppId,
        Map<Id, String> mainHolderNameByOppId
    ) {
        List<Opportunity> toUpdate = new List<Opportunity>();
        for (Opportunity opp : opportunities) {
            if (hasEntificMismatch(opp)) {
                continue;
            }

            String groupName = resolveGroupName(opp, groupNameFromAssociationByOppId);
            String mainHolderName = mainHolderNameByOppId.get(opp.Id);

            if (opp.DMT_Group_Name__c != groupName || opp.DMT_Main_Holder_Name__c != mainHolderName) {
                toUpdate.add(new Opportunity(
                    Id = opp.Id,
                    DMT_Group_Name__c = groupName,
                    DMT_Main_Holder_Name__c = mainHolderName
                ));
            }
        }
        return toUpdate;
    }

    /**
     * @description Builds a map of Opportunity Id to Group__r.Name from Custom_Association_Opportunity__c
     * records that have Group__c populated, keeping the first (oldest) one per Opportunity.
     * @param opportunityIds Ids of the Opportunities to look up associations for
     * @return map of Opportunity Id to the associated Group__r.Name
     */
    private static Map<Id, String> queryGroupNameFromAssociationByOppId(Set<Id> opportunityIds) {
        Map<Id, String> groupNameFromAssociationByOppId = new Map<Id, String>();
        for (Custom_Association_Opportunity__c assoc : [
            SELECT Opportunity__c, Group__r.Name
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c IN :opportunityIds AND Group__c != null
            WITH USER_MODE
            ORDER BY CreatedDate
        ]) {
            if (!groupNameFromAssociationByOppId.containsKey(assoc.Opportunity__c)) {
                groupNameFromAssociationByOppId.put(assoc.Opportunity__c, assoc.Group__r.Name);
            }
        }
        return groupNameFromAssociationByOppId;
    }

    /**
     * @description Updates the given Opportunities bypassing the trigger (to avoid recursion),
     * using partial-success DML so a pre-existing data issue on one record (e.g. a validation
     * rule failing on a different field) doesn't block the rest of the batch/chunk.
     * @param toUpdate the Opportunity records (Id + changed fields) to update
     */
    private static void updateWithBypass(List<Opportunity> toUpdate) {
        Boolean alreadyBypassed = TriggerBypass.bypassTrigger;
        if (!alreadyBypassed) {
            TriggerBypass.setBypass();
        }
        try {
            List<Database.SaveResult> results = Database.update(toUpdate, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug(
                            LoggingLevel.WARN,
                            'DMT_OpportunityGroupHolderService: failed to sync Group/Main Holder Name for Opportunity ' +
                                toUpdate[i].Id + ': ' + err.getMessage()
                        );
                    }
                }
            }
        } finally {
            if (!alreadyBypassed) {
                TriggerBypass.removeBypass();
            }
        }
    }

    /**
     * @description Detects whether updating this Opportunity would fail the "Booking Unit Risk
     * Analyst must share the Opportunity's Entific" validation rule, so it can be skipped instead
     * of attempted and logged as a DML failure.
     * @param opp the Opportunity to check (must include Entific__c, DMT_Booking_Unit_Risk_Analyst__c
     * and DMT_Booking_Unit_Risk_Analyst__r.DMT_Entific__c)
     * @return true if updating opp would violate the validation rule
     */
    private static Boolean hasEntificMismatch(Opportunity opp) {
        Boolean mismatch = opp.DMT_Booking_Unit_Risk_Analyst__c != null
            && opp.Entific__c != opp.DMT_Booking_Unit_Risk_Analyst__r.DMT_Entific__c;
        if (mismatch) {
            System.debug(
                LoggingLevel.WARN,
                'DMT_OpportunityGroupHolderService: skipping Opportunity ' + opp.Id +
                    ' - Booking Unit Risk Analyst Entific mismatch would fail validation rule'
            );
        }
        return mismatch;
    }

    /**
     * @description Resolves the Group Name to sync for an Opportunity: the associated Group__c
     * Account name when populated, otherwise the hierarchy-walk fallback.
     * @param opp the Opportunity to resolve the Group Name for
     * @param groupNameFromAssociationByOppId Group Name per Opportunity Id sourced from Group__c
     * @return the resolved Group Name (empty string when none is found)
     */
    private static String resolveGroupName(Opportunity opp, Map<Id, String> groupNameFromAssociationByOppId) {
        String groupName = groupNameFromAssociationByOppId.get(opp.Id);
        if (groupName != null) {
            return groupName;
        }
        if (opp.AccountId == null) {
            return '';
        }
        Map<String, Object> hierarchy = DMT_HPG_Utils.buildClientGroupStructure(opp.AccountId);
        return hierarchy.get('groupName') != null ? (String) hierarchy.get('groupName') : '';
    }
}