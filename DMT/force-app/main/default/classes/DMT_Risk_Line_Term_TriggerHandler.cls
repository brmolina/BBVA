/**
 * @description Trigger handler for DMT_Risk_Line_Term__c. Add logic for each context as needed.
 */
public with sharing class DMT_Risk_Line_Term_TriggerHandler extends DMT_TriggerHandler {
    
    private List<DMT_Risk_Line_Term__c> lstNew;
    private Map<Id,DMT_Risk_Line_Term__c> mapNew;
    private Map<Id,DMT_Risk_Line_Term__c> mapOld;

    public DMT_Risk_Line_Term_TriggerHandler(){
        this.lstNew=(List<DMT_Risk_Line_Term__c>) Trigger.new;
        this.mapNew=(Map<Id,DMT_Risk_Line_Term__c>) Trigger.newmap;
        this.mapOld=(Map<Id,DMT_Risk_Line_Term__c>) Trigger.oldmap;
    }

    public override void beforeInsert(){}

    public override void beforeUpdate(){
        DMT_Risk_Line_Term_Helper.updateLastModifiedByHuman(this.lstNew);
    }
    public override void beforeDelete(){}

    public override void afterInsert(){}

    public override void afterUpdate(){}

    public override void afterDelete(){}

    public override void afterUndelete(){}
}