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
trigger DES_Guidance on gfsc__Guidance_for_Success__c(after insert) {
    final acpl.GuidanceForSuccessHandler guidanceHandler =  new acpl.GuidanceForSuccessHandler();
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            guidanceHandler.afterInsert(Trigger.new);
        }
    }
}