/**
* ────────────────────────────────────────────────────────────────────
* DMT_Line_Status_Process__c Trigger Handler
* ────────────────────────────────────────────────────────────────────
* @author     franlopez
* @modifiedBy
* @version     1.0
* @created     2026-08-05
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/



public with sharing class DMT_Line_Status_Process_TriggerHandler extends DMT_TriggerHandler {

    private List<DMT_line_status_process__c> lstNew;
    private Map<Id, DMT_line_status_process__c> mapNew;
    private Map<Id, DMT_line_status_process__c> mapOld;


    public DMT_Line_Status_Process_TriggerHandler(){

        this.lstNew = (List<DMT_line_status_process__c>) Trigger.new;
        this.mapNew = (Map<Id, DMT_line_status_process__c>) Trigger.newMap;
        this.mapOld = (Map<Id, DMT_line_status_process__c>) Trigger.oldMap;
    }


    public override void afterInsert() {

        System.debug('DMT_Line_Status_Process_TriggerHandler afterInsert');
        DMT_Line_Status_Process_Helper helper = new DMT_Line_Status_Process_Helper();
        helper.syncDestinationStatusToLines(lstNew);
    }
    

    public override void afterUpdate() {

        System.debug('DMT_Line_Status_Process_TriggerHandler afterUpdate');
        DMT_Line_Status_Process_Helper helper = new DMT_Line_Status_Process_Helper();
        helper.syncDestinationStatusToLines(lstNew);
    }
}