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