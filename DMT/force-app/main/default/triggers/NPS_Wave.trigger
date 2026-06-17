/**********************************************************************************
* @author       Global Desktop
* @date         10/10/2019
* @description  Trigger para el objeto NPS_Wave__c
**********************************************************************************/

trigger NPS_Wave on NPS_Wave__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {

        } else if(Trigger.isUpdate) {
             
        }
    } else if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            NPS_WaveTriggerHandler.onAfterInsert(Trigger.new);
        } else if(Trigger.isUpdate) {

        }
    }
}