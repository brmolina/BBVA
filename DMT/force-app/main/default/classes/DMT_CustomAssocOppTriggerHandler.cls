/**
 * ────────────────────────────────────────────────────────────────────
 * Custom_Association_Opportunity__c Trigger Handler
 * ────────────────────────────────────────────────────────────────────
 * Dispatches DML events for Custom_Association_Opportunity__c through the
 * DMT_TriggerHandler framework. Add new context methods as behaviours grow.
 */
public with sharing class DMT_CustomAssocOppTriggerHandler extends DMT_TriggerHandler {

    private List<Custom_Association_Opportunity__c> lstNew;
    private Map<Id, Custom_Association_Opportunity__c> mapOld;

    public DMT_CustomAssocOppTriggerHandler() {
        this.lstNew = (List<Custom_Association_Opportunity__c>) Trigger.new;
        this.mapOld = (Map<Id, Custom_Association_Opportunity__c>) Trigger.oldMap;
    }

    public override void afterUpdate() {
        DMT_CustomAssocOppTriggerHelper helper = new DMT_CustomAssocOppTriggerHelper();
        /**
         * @description When the multiholder Main Borrower changes (flagged through the g_customer_id__c
         * field), transfers the Approval Process Data / Client tab information to the newly selected
         * Main Borrower so the user does not lose the data already entered.
         */
        helper.transferMainBorrowerData(lstNew, mapOld);
        syncOpportunities(lstNew);
    }

    public override void afterInsert() {
        syncOpportunities(lstNew);
    }

    public override void afterDelete() {
        syncOpportunities(mapOld.values());
    }

    /**
     * @description Grupo y Main Holder en Opportunity tras migración Multiholder. Whenever a
     * Custom_Association_Opportunity__c record is inserted, updated or deleted, the denormalized
     * DMT_Group_Name__c / DMT_Main_Holder_Name__c fields on the related Opportunity may need to be
     * recomputed (e.g. the Main Borrower flag moved to another client, or the last association was
     * removed reverting the Opportunity to mono-holder).
     * @param assocs Custom_Association_Opportunity__c records to derive the related Opportunity ids from
     */
    private void syncOpportunities(List<Custom_Association_Opportunity__c> assocs) {
        Set<Id> oppIds = new Set<Id>();
        for (Custom_Association_Opportunity__c assoc : assocs) {
            if (assoc.Opportunity__c != null) {
                oppIds.add(assoc.Opportunity__c);
            }
        }
        if (!oppIds.isEmpty()) {
            DMT_OpportunityGroupHolderService.syncGroupAndMainHolderNames(oppIds);
        }
    }
}