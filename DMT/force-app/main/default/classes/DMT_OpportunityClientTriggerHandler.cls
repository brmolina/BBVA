/**
 * ────────────────────────────────────────────────────────────────────
 * DMT_Opportunity_Client__c Trigger Handler
 * ────────────────────────────────────────────────────────────────────
 */
public without sharing class DMT_OpportunityClientTriggerHandler extends DMT_TriggerHandler {

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
        helper.syncInferredAccountGroupFields(lstNew); // CIBGLOBALD-3981
    }

    public override void afterInsert() {


        // DMT_AsyncOrchestrator.flush() must always be the LAST statement of
        // afterInsert()/afterUpdate(). enqueue() only queues a payload; flush() is what actually
        // dispatches everything queued so far. Call it once per trigger context, after every Helper
        // method has had a chance to enqueue - never inside a Helper's own loop.
        DMT_AsyncOrchestrator.flush();
    }

    public override void afterUpdate() {
        DMT_OpportunityClientTriggerHelper helper = new DMT_OpportunityClientTriggerHelper();
        helper.checkOpportunityClientChanges(lstNew, mapOld);

        
        // DMT_AsyncOrchestrator.flush() must always be the LAST statement of
        // afterInsert()/afterUpdate(). enqueue() only queues a payload; flush() is what actually
        // dispatches everything queued so far. Call it once per trigger context, after every Helper
        // method has had a chance to enqueue - never inside a Helper's own loop.
        DMT_AsyncOrchestrator.flush();
    }

    

}