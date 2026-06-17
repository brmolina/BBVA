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
trigger DES_Template on dyfr__Template__c(after insert) {
    final acpl.TemplateHandler templateHandler =  new acpl.TemplateHandler();
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            templateHandler.afterInsert(Trigger.new);
        }
    }
}