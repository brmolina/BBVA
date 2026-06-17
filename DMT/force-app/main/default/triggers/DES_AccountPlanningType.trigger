/**
* @author       Operaciones
* @date         07/01/2020
* @description  Trigger de Account Planning
* @Revision
*
* Version   Date            Author          Summary of changes
* ----------------------------------------------------------------------------------
* 0.1       07/01/2020      ICG             [Irene] Añadida llamada insert relacionada con la nueva lógica de los objetos introducidas en el paquete 3.0


*
*/
trigger DES_AccountPlanningType on acpl__Account_Planning_Type__c(after insert) {
    final acpl.AccountPlanningTypeHandler aptHandler =  new acpl.AccountPlanningTypeHandler();
    private static CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();

    if (byPass.CIB_skip_triggers_AP__c) {
            System.debug(Logginglevel.INFO,'>>>>>>> Trigger salteado');
    }
    else {

        if(Trigger.isAfter) {
            if(Trigger.isInsert) {
                aptHandler.afterInsert(Trigger.new);
            }
        }
    }
}