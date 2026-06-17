/**
* @author       Global Desktop
* @date         17/10/2019
* @description  Trigger de BP_GrowthDriver__c
* @Revision
*
* Version   Date            Author          Summary of changes
* 0.1       2019/10/28      JSS             Añadido método updateStatusOnAP que sirve para actualizar el estado del AP relacionado con el BP
* 0.2       2020/01/07      ICG             [Irene]: añadidos los métodos nuevos del paquete 3.0 de Global Hub
*/
trigger DES_APTeam on bupl__AP_Team__c (before insert, before update, before delete, after insert, after delete) {

    final acpl.AP_TeamHandler apTeamHandler = acpl.AP_TeamHandler.getInstance();
    final BP_TeamHandler bpTeamHandler = BP_TeamHandler.getInstance();
    //final DES_AP_TeamHandler des_apTeamHandler = DES_AP_TeamHandler.getInstance();

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            apTeamHandler.fillBPLookup(Trigger.new);
            //DES_AP_TeamHandler.notifyGB(Trigger.new);
            DES_AP_TeamHandler.checkNotGlobalBanker(Trigger.new);
        } else if(Trigger.isUpdate) {
            DES_AP_TeamHandler.checkNotGlobalBanker(Trigger.new);
        } else if(Trigger.isDelete) {
            DES_AP_TeamHandler.checkUserDeleting(Trigger.old);
        }
    }
    else if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            bpTeamHandler.giveAPEditAccess(Trigger.new);
            bpTeamHandler.giveBPEditAccess(Trigger.new);
            DES_AP_TeamHandler.updateStatusOnAP(Trigger.newMap);
            //A partir de aquí introducido con el paquete 3.0. Tienen nombres similares pero código distinto
	    //se usa la ejecucion de la clase global porque la local tiene un paso mas adaptado
            //apTeamHandler.updateStatusOnAP(Trigger.newMap);
        } else if(Trigger.isDelete) {
            bpTeamHandler.removeAPEditAccess(Trigger.old);
            bpTeamHandler.removeBPEditAccess(Trigger.old);
        }
    }
}