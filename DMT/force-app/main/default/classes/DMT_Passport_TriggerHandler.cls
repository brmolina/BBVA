/**
* ────────────────────────────────────────────────────────────────────
* Passport__c Trigger Handler
* ────────────────────────────────────────────────────────────────────
* @author     torcuato.tejada.contractor@bbva.com
* @modifiedBy
* @version     1.0
* @created     2026-02-02
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class DMT_Passport_TriggerHandler extends DMT_TriggerHandler {

    private List<Passport__c> lstNew;
    private Map<Id,Passport__c> mapNew;
    private Map<Id,Passport__c> mapOld;

    public DMT_Passport_TriggerHandler(){
        this.lstNew=(List<Passport__c>) Trigger.new;
        this.mapNew=(Map<Id,Passport__c>) Trigger.newmap;
        this.mapOld=(Map<Id,Passport__c>) Trigger.oldmap;
    }

    public override void afterUpdate() {
        // CIBGLOBALD-4617: tell open Passports the record changed (replaces Passport__ChangeEvent)
        DTM_Task_Helper.processPassportChange(this.lstNew, this.mapOld);

        // CIBGLOBALD-4507: sync approval Cases/Tasks with the features received from Passport
        DMT_Passport_FeatureSync.sync(this.lstNew, this.mapOld);
    }

    public override void beforeUpdate() {
        
    }

    public override void beforeInsert() {
        
    }

    public override void afterInsert() {
        if(!this.lstNew.isEmpty()){
            DMT_Passport_TriggerHelper.processPassportIntegrationPayload(this.lstNew);
        }


        //after all after update methods
        DMT_AsyncOrchestrator.flush();
    }


}