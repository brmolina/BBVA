/**
* ────────────────────────────────────────────────────────────────────
* DMT_X_Sell__c Trigger Handler
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class XSellTriggerHandler extends DMT_TriggerHandler {

    private List<DMT_X_Sell__c> lstNew;
    private Map<Id, DMT_X_Sell__c> mapNew;
    private Map<Id, DMT_X_Sell__c> mapOld;
    private List<DMT_X_Sell__c> lstOld;

    public XSellTriggerHandler() {
        this.lstNew = (List<DMT_X_Sell__c>) Trigger.new;
        this.mapNew = (Map<Id, DMT_X_Sell__c>) Trigger.newMap;
        this.mapOld = (Map<Id, DMT_X_Sell__c>) Trigger.oldMap;
        this.lstOld = (List<DMT_X_Sell__c>) Trigger.old;
    }

    public override void afterInsert() {
        XSellTriggerHelper helper = new XSellTriggerHelper();
        helper.recalculateTotals(lstNew, null);
    }

    public override void afterUpdate() {
        XSellTriggerHelper helper = new XSellTriggerHelper();
        helper.recalculateTotals(lstNew, mapOld);
    }

    public override void afterDelete() {
        XSellTriggerHelper helper = new XSellTriggerHelper();
        helper.recalculateTotals(lstOld, null);
    }

    public override void afterUndelete() {
        XSellTriggerHelper helper = new XSellTriggerHelper();
        helper.recalculateTotals(lstNew, null);
    }
}