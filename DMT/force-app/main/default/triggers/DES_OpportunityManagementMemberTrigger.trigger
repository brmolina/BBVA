/**************************************************************************************************************
Name:            DES_OpportunityManagementMemberTrigger
Description:     Trigger on object DES_Opportunity_Management_member__c
Test Class:

Version        Date            Author            Summary of changes
--------------------------------------------------------------------------------------------------------------
0.1            01/04/2018      DSL          Creación de la clase
0.2            13/07/2018      JSS          Llamada al método fillCountryGBIH del handler para actualizar el country a 'Global' cuando se trata de los 'Industry Head' y 'Global Banker'
**************************************************************************************************************/
trigger DES_OpportunityManagementMemberTrigger on DES_Opportunity_Management_member__c (before insert, before delete, after insert, after delete) {

    final DES_OppManagementMemberTriggerHandler handler = DES_OppManagementMemberTriggerHandler.getInstance();

	system.debug('>>>>> triggerNew: ' + trigger.new);
    if(trigger.isBefore){
        if(trigger.isInsert){
            handler.checkDuplicates(trigger.new);
            DES_OppManagementMemberTriggerHandler.fillCountryGBIH(trigger.new);
            DES_OppManagementMemberTriggerHandler.fillOppManagMemberName(trigger.new);
            system.debug('trigger before: ' + handler.listDuplicates);

        } else if(trigger.isDelete) {
            //handler.logicBeforeDelete(trigger.oldMap);
            DES_OppManagementMemberTriggerHandler.checkIsOwnerDelete(Trigger.old);
        }
    }

    if(trigger.isAfter) {
        // system.debug('estoy aqui y voy a borrar: ' + DES_OppManagementMemberTriggerHandler.listDuplicates);
        if (Trigger.isInsert) {
            DES_OppManagementMemberTriggerHandler.shareChatterNBCVirtual(trigger.newMap);
            DES_OppManagementMemberTriggerHandler.avoidPSDuplicatedTriggerNew(trigger.new);
            system.debug('>>>>> Desktop_Utils.listMiembrosDuplicados: ' + Desktop_Utils.listMiembrosDuplicados);
            if(!Desktop_Utils.listMiembrosDuplicados.isEmpty()) {
                delete Desktop_Utils.listMiembrosDuplicados;
            }

        	DES_OppManagementMemberTriggerHandler.fillGlobalBanker(trigger.newMap);
            if(!handler.listDuplicates.isEmpty()){
          	  system.debug('estoy aqui y voy a borrar');
          	  delete handler.listDuplicates;
            }
            Opportunity_Manag_Member_TriggerHandler.onAfterInsert(Trigger.new);
        }
        if (Trigger.isDelete) {
            DES_OppManagementMemberTriggerHandler.deleteChatterNBCVirtualShare(Trigger.old);
            DES_OppManagementMemberTriggerHandler.deleteOpportunityTeamMember(Trigger.old);
            Opportunity_Manag_Member_TriggerHandler.onAfterDelete(Trigger.old);
        }
	}
}