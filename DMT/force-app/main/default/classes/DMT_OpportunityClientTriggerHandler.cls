/**
 * ────────────────────────────────────────────────────────────────────
 * DMT_Opportunity_Client__c Trigger Handler
 * ────────────────────────────────────────────────────────────────────
 */
public with sharing class DMT_OpportunityClientTriggerHandler extends DMT_TriggerHandler {

    private List<DMT_Opportunity_Client__c> lstNew;
    private Map<Id, DMT_Opportunity_Client__c> mapNew;
    private Map<Id, DMT_Opportunity_Client__c> mapOld;
    private List<DMT_Opportunity_Client__c> lstOld;

    public DMT_OpportunityClientTriggerHandler() {
        this.lstNew = (List<DMT_Opportunity_Client__c>) Trigger.new;
        this.mapNew = (Map<Id, DMT_Opportunity_Client__c>) Trigger.newMap;
        this.mapOld = (Map<Id, DMT_Opportunity_Client__c>) Trigger.oldMap;
        this.lstOld = (List<DMT_Opportunity_Client__c>) Trigger.old;
    }

    public override void beforeInsert() {
        DMT_OpportunityClientTriggerHelper helper = new DMT_OpportunityClientTriggerHelper();
        helper.syncInitialXSellTotals(lstNew);
    }
}