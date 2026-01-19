/**********************************************************************************
* @author       Global Desktop
* @date         14/11/2019
* @description  Clase programable que lanza el batch para notificar a los miembros del AP team
* @Revision
**********************************************************************************/
global without sharing class AP_EventNotificationSchedulable implements Schedulable {
    /*
    * @author       Global Desktop
    * @Description  Ejecuta el batch para notificar a los miembros del AP
    */
    global void execute(SchedulableContext scMain) {
        acpl__Account_Plan_Settings__c apSetting = acpl__Account_Plan_Settings__c.getInstance();
        AP_EventNotificationBatch eventNotifBatch = new AP_EventNotificationBatch();
        database.executebatch(eventNotifBatch,(Integer)apSetting.acpl__NotificationSchedulable_batch_size__c);
    }
}