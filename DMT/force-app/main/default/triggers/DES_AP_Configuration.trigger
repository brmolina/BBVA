/**
* @author       Global Desktop
* @date         12/03/2020
* @description  Trigger de Account Planning Configuration
**/
trigger DES_AP_Configuration on acpl__AP_PeriodConfiguration__c (after update) {
    
    DES_AP_ConfigurationHandler des_apConfigHandler = DES_AP_ConfigurationHandler.getInstance();
    
    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            des_apConfigHandler.fillDueDate(Trigger.new, Trigger.oldMap);
        }
    }
}