/**
* @author       torcuato.tejada.contractor@bbva.com
* @date         24/08/2021
* @description  Client Package Trigger
*
*/
trigger cuco_clientPackage on cuco__client_package__c (before insert, after update) {
    final CucoClientPackageTriggerHandler handler =  new CucoClientPackageTriggerHandler();
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
    }
}