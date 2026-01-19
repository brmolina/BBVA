/**********************************************************************************
* @author       Global Desktop
* @date         03/07/2019
* @description  Clase programable que lanza el batch para notificar a los miembros del AP
* @Revision
**********************************************************************************/
global with sharing class AP_NotificationSchedulable implements Schedulable {
    /*
    * @author       Global Desktop
    * @Description  Ejecuta el batch para notificar a los miembros del AP
    */
    global void execute(SchedulableContext scMain) {
        acpl__Account_Plan_Settings__c apSetting = acpl__Account_Plan_Settings__c.getInstance();
        AP_NotificationBatch genPriorityNotifBatch = new AP_NotificationBatch();
        database.executebatch(genPriorityNotifBatch,(Integer)apSetting.acpl__NotificationSchedulable_batch_size__c);
    }
}