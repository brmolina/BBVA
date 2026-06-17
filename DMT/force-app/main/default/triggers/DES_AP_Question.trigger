/**
* @author       Global Desktop
* @date         
* @description  Trigger de AP_Question__c
* @Revision
* 
* Version   Date            Author          Summary of changes
* 0.1       2019/10/28      JSS             Añadido método updateStatusOnAP que sirve para actualizar el estado del AP relacionado
* 0.2       2021/03/02      ICG             [Irene] Cambio para la versión 3.40 de AP
*/
trigger DES_AP_Question on acpl__AP_Question__c (after update, before insert, before update) {
    
    final acpl.AP_QuestionHandler apQuestion = acpl.AP_QuestionHandler.getInstance();

    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            apQuestion.updateStatusOnAP(Trigger.newMap,Trigger.oldMap);
        }
    }
    if(Trigger.isBefore) {
        if(Trigger.isUpdate) {
            apQuestion.updateFinalResponse(Trigger.newMap,Trigger.oldMap);
        }
        else if(Trigger.isInsert) {
            apQuestion.insertFinalResponse(Trigger.new);
        }
    }
    
}