/**
* @author       Global Desktop
* @date         05/07/2019
* @description  Trigger de Account Planning
* @Revision
*
* Version   Date            Author          Summary of changes
* ----------------------------------------------------------------------------------
* 0.1       2019/10/15      JSS             Añadida llamada after delete al método deleteRelatedRecords. Añadido método deleteRelatedRecords para eliminar registros relacionados en
                                            los objetos relacionados con el AccountPlanning.  Añadida llamada after al método insertAPHistory.
* 0.2       2019/10/28      JSS             Añadida llamada after update al método updateStatusOnBP. Añadida llamada before update al método updateStatusOnAPnotStarted
*                                           Añadida comprobación mediante la clase SER_TriggerHelper para que no se update el Status de un AP según se crea, ya que en la
*                                           en la creación de un AP al insertarsele el GlobalBanker se produce automáticamente un update del Rollup que cuenta los miembros AP_Team
* 0.3       2019/11/08      JSS             Añadida llamada after insert al método initRelatedBP (en el handler de Global Desktop). Se reordenan las llamadas a los métodos dentro de After-Insert
                                            Modificada llamada al método checkAPperiod -> ahora se mete la lógica del usuarioPerfil en el DES_AccountPlanningHandler
* 0.4       2021/01/07      ICG             [Irene]: añadidos los métodos nuevos del paquete 3.0 de Global Hub
                                            [Carlos]: Añadido el nuevo método del paquete 3.1 para solucionar incidencia del chatter.
* 0.5       2021/02/25      ICG             [Irene]: añadidos los métodos nuevos del paquete 3.4 y modificaciones en invoación a locales
                                            
*
*/
trigger DES_AccountPlanning on acpl__Account_Planning__c (before insert, before update, after insert, after update, after delete) {

     
    final acpl.AccountPlanningHandler apHandler = acpl.AccountPlanningHandler.getInstance();
    final DES_AccountPlanningHandler des_apHandler = DES_AccountPlanningHandler.getInstance(); 
    private static CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();

    if (byPass.CIB_skip_triggers_AP__c) {
            System.debug(Logginglevel.INFO,'>>>>>>> Trigger salteado');
    }
    else {
        if(Trigger.isBefore) {
            if(Trigger.isInsert) {
                des_apHandler.updateEventDate(Trigger.new, null);
                des_apHandler.setFieldsBeforeInsert(Trigger.new);
                des_apHandler.fillDueDate(Trigger.new, null);
                //introducidos con el paquete 3.0
                apHandler.setAPTypeDefault(Trigger.new);
                //introducido en el paquete 3.4
                apHandler.relatedPeriod(Trigger.new);
            }
            else if(Trigger.isUpdate) {
                if (!SER_TriggerHelper.get_MethodFired('AccountPlanning_JustCreatedEvent')) {
                    //apHandler.updateStatusOnAPnotStarted(Trigger.new);
                }
                //cambiamos el orden de la llamada a los metodos del paquete con la versión 3.51
                apHandler.checkAPperiod(Trigger.new, Trigger.oldMap);
                apHandler.updateStatusOnAPnotStarted(Trigger.new);
                //se comenta el método local en la subida 3.4
                //des_apHandler.checkAPperiod(Trigger.new, Trigger.oldMap);
                apHandler.fillMandatoryQuestions(Trigger.new, Trigger.oldMap);
                apHandler.fillValidationDate(Trigger.new, Trigger.oldMap);
                des_apHandler.fillDueDate(Trigger.new, Trigger.oldMap);
                //introducido en el paquete 3.4
                apHandler.updateRelatedPeriod(Trigger.newMap, Trigger.oldMap);
            
            }
        }
        else if(Trigger.isAfter) {
            if(Trigger.isInsert) {
                // con esta linea se controla si se acaba de insertar un registro AP y evitamos que después recien creado
                // se meta en Before-Update por el método updateStatusOnAPnotStarted y se le cambie el estado
                SER_TriggerHelper.set_MetodFired('AccountPlanning_JustCreatedEvent', true);

                apHandler.insertAPHistory(Trigger.newMap, null, true, false);
                des_apHandler.initRelatedBP(Trigger.new);
                des_apHandler.copyAPTeamFromGroup(Trigger.new);
                apHandler.relateAPQuestions(Trigger.new);
                apHandler.changeToTimedOut(Trigger.new);
                des_apHandler.createShareValidator(trigger.newMap, null);
                //cambio subida 14/02/2021     
                des_apHandler.createGroupAnalysis(Trigger.new);

            }
            else if(Trigger.isUpdate) {
                //Introducido paquete 3.4 tiene que ir al principio de la ejecucioon
                apHandler.blockByperiods(Trigger.new, Trigger.oldMap);  
                //A partir de aquí introducidos con el paquete 3.0. Tienen nombres similares pero código distinto
                //en la versión 3.4 se pasa al metodo local de blockUnblockAP para solucionar el problema del chatter
                //apHandler.blockUnblockAP(Trigger.new, Trigger.oldMap);   
                des_apHandler.blockUnblockAP(Trigger.new, Trigger.oldMap);
                apHandler.insertAPHistory(Trigger.newMap, Trigger.oldMap, false, true);
                apHandler.updateStatusOnBP(Trigger.newMap, Trigger.oldMap);
                des_apHandler.createShareValidator(trigger.newMap, trigger.oldMap);
                //des_apHandler.createGroupAnalysis(Trigger.new, Trigger.oldMap);
                des_apHandler.updateLastBPversion(Trigger.new, Trigger.oldMap);
                des_apHandler.insertAudit(Trigger.new, Trigger.oldMap);
                //Paquete 3.1 metodo para corregir incidencia de chatter
                apHandler.sendChatterChangeStatus(Trigger.new, Trigger.oldMap);
                
                
            
            }
            else if(Trigger.isDelete) {
                apHandler.deleteRelatedRecords(Trigger.oldMap);
            }
        }
    }
}