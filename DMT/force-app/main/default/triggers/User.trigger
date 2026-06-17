/**********************************************************************************
 * @author        Accenture
 * @date            30/05/2016
 * @description    Trigger para objeto User. No implementar la lógica aquí, para ello usar las clases UserTriggerHandlery UserLogic.
 * @Revision
 *                2018/10/04 Añadida funcionalidad para gestionar los usuarios que se asignan/eliminan en el permissionSet que da acceso a los usuarios a Chatter.
 * 
 * REFACTOR 2026:
 *  • Eliminada lógica legacy de asignación automática de Permission Sets E-Commerce.
 *  • Eliminada dependencia de roles obsoletos (GLOBAL MARKETS E-COMMERCE).
 *  • Centralizada la lógica before/after en métodos orquestadores del handler.
 *  • Eliminada duplicidad de lógica (skipAmbit y filtrado de usuarios activos).
 *  • Simplificada estructura para mejorar mantenibilidad y testabilidad.
 *
 * Resultado:
 *  Trigger desacoplado de la lógica de negocio y alineado con patrón
 *  Handler/Orchestrator.
 **********************************************************************************/
trigger User on User(before insert, before update, after insert, after update ){

    final UserTriggerHandler handler = UserTriggerHandler.getInstance();
    final CIB_Bypass__c byPassSettings = CIB_Bypass__c.getInstance();

    if (Trigger.isBefore){

        if (Trigger.isInsert){
            handler.handleBeforeInsert(Trigger.new );

        } else if (Trigger.isUpdate){
            handler.handleBeforeUpdate(Trigger.new, Trigger.oldMap, byPassSettings.CIB_DES_skip_trigger_in_denorm__c);
        }

    } else if (Trigger.isAfter){

        if (Trigger.isInsert){
            handler.handleAfterInsert(Trigger.new, Trigger.newMap, byPassSettings.CIB_DES_skip_trigger_in_denorm__c);

        } else if (Trigger.isUpdate){
            handler.handleAfterUpdate(Trigger.new, Trigger.oldMap, Trigger.newMap, byPassSettings.CIB_DES_skip_trigger_in_denorm__c);
        }
    }
}