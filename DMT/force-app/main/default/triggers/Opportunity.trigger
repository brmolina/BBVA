/**********************************************************************************
 * @author       Accenture
 * @date         01/03/2016
 * @description  Trigger para objeto Opportunity. No crear más triggers para Opportunity, para ello usar la clase OpportunityTriggerHandler y ActivitiesUtils.
 * @Revision
2017/10/26 Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican
    2018/12/14 Añadida lógica para evento before delete
    2019/09/03 Renombrado de métodos onAfterInsert/onAfterUpdate por los nombres más
    descriptivos denormOnAfterInsert/denormOnAfterInsert respectivamente
    2019/09/19 Se saca del metodo denormOnAfterUpdate la llamada al método moveFilesToNBC para que sea independiente.
    2019/09/27 Se elimina llamada inncecesaria al metodo "toggleScheduleNotification"
    2019/11/12 Comentario para intentar actualizar en WolfDev el trigger
    2019/11/20 Creado el metodo para crear chatters en las oportunidades asociadas a un NBC
    17/03/2020 Se añaden llamadas a métodos con lógica Before Insert para las oportunidades de la funcionalidad PRICING
     **********************************************************************************/
trigger Opportunity on Opportunity (before insert,before update,before delete,after insert,after update,after delete) {
        if(TriggerBypass.bypassTrigger) return;
        Id rtOppDMT = Schema.SObjectType.Opportunity
        .getRecordTypeInfosByDeveloperName()
        .get('DMT_Opportunity')
        .getRecordTypeId();
        String rtDevName;
        if (trigger.new != null && trigger.new.size() > 0) {
             Map<Id, Schema.RecordTypeInfo> rtInfoMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosById();
            Schema.RecordTypeInfo rti = rtInfoMap.get(Trigger.new[0].RecordTypeId);
            rtDevName = (rti != null ? rti.getDeveloperName() : null);
        }

        Map<Id,Opportunity> oldMapDeleteOppsNoDMT = new Map<Id,Opportunity>();
        if (Trigger.isDelete){
            for( Opportunity opp : Trigger.old ){
                if (opp.RecordType.DeveloperName != null && opp.RecordType.Id != rtOppDMT){
                    oldMapDeleteOppsNoDMT.put( opp.Id, opp );
                }
            }
        }
       
    
    /*
     *   @AUTHOR Global Desktop
     */
    final DES_relatedOppTeamMembersTriggerHandler handlerOppTM = DES_relatedOppTeamMembersTriggerHandler.getInstance();
    
    /*
     *   @AUTHOR Global Desktop
     */
    final OpportunityTriggerHandler handlerOpp = OpportunityTriggerHandler.getInstance();
    /*
     *   @AUTHOR Global Desktop
     */
    final DMT_OpportunityTriggerHandler dmtHandlerOpp = DMT_OpportunityTriggerHandler.getInstance();
    
    /*
     *   @AUTHOR Global Desktop
     */
    final RelatedTranchesValidations handlerTrancVal = RelatedTranchesValidations.getInstance();
    
    /*
     *   @AUTHOR Global Desktop
     */
    final RelatedProductsValidations handlerProdVal = RelatedProductsValidations.getInstance();

    final DMT_OpportunityTriggerHandler Dmt_HandlerOpp = new DMT_OpportunityTriggerHandler();
    
    /*
     * KPIS Helper Class
     */
    final KPI_Logic_Helper kpiHelper = KPI_Logic_Helper.getInstance();
    
    if(Trigger.isBefore) {
        if( rtDevName != 'DMT_Opportunity'){
            if(Trigger.isUpdate) {
                
                
                OpportunityTriggerHandler.checkConfirmData( Trigger.newMap, Trigger.oldMap );
                OpportunityTriggerHandler.updateProbability( Trigger.new, Trigger.oldMap );
                OpportunityTriggerHandler.setOppRecordType(Trigger.newMap, Trigger.oldMap);
                
                
                handlerProdVal.validateProducts(Trigger.newMap, Trigger.oldMap);
                handlerTrancVal.validateTranches(Trigger.newMap, Trigger.oldMap);
                
                DES_relatedProductsTriggerHandler.setClosedDate(Trigger.new);
                
                OpportunityTriggerHandler.checkIfSimilarOpp(trigger.new, trigger.oldMap);
                handlerOpp.calculateCrossBorder(trigger.new, null);
                handlerOpp.needTemplate(trigger.new, trigger.oldMap);
                handlerOpp.beforeUpdate(trigger.new);
                handlerOpp.confidentialRecordType(trigger.new);
                OpportunityTriggerHandler.completeNBCFinallyBook(trigger.new, trigger.oldMap);
                //handlerOpp.updateIPOpportunityCountry(trigger.new);
            }
            else if(Trigger.isInsert){
                handlerOpp.confidentialRecordType(trigger.new);
                handlerOpp.beforeInsert(trigger.new);
                handlerOpp.calculateCrossBorder(trigger.new, null);
                OpportunityTriggerHandler.updateProbability(trigger.new, null);
                OpportunityTriggerHandler.completeNBCFinallyBook(trigger.new, null);
                //handlerOpp.updateIPOpportunityCountry(trigger.new);
            }
            else if(Trigger.isDelete){
                handlerOpp.checkDeletePermission(oldMapDeleteOppsNoDMT.values());
                handlerOpp.checkLogicForDeletingPricingOpportunity(oldMapDeleteOppsNoDMT.values());
            }
        }else{
            if(Trigger.isUpdate) {
            Dmt_HandlerOpp.calculateAndUpdateNotionalAmounts(trigger.newMap, trigger.oldMap);
            Dmt_HandlerOpp.validateDynamicStageChange(trigger.new, trigger.oldMap);
            }
        }
    } else if(Trigger.isAfter) {
        if( rtDevName != 'DMT_Opportunity'){
            if(LaunchUpdateKPI.getBanKPI()==false) {
                LaunchUpdateKPI.ActivateBanKPI();
                kpiHelper.checkNeedUpdKpi((Trigger.isInsert || Trigger.isDelete), Trigger.newMap, Trigger.oldMap);
            }
            if(Trigger.isInsert) {
                // llamo a la funcion de copia del equipo de oportunidad
                //handlerOppTM.automaticClientTeamCopy(Trigger.newMap, Trigger.oldMap);
                handlerOppTM.accHierarchyTeamCopyToOppTeam(Trigger.newMap, Trigger.oldMap);
                handlerOpp.denormOnAfterInsert(Trigger.new);
                //handlerOpp.calculateCrossBorder(trigger.new, trigger.oldMap);
                handlerOpp.setManualPermissions(Trigger.newMap, Trigger.oldMap);
                OpportunityTriggerHandler2.onAfterInsert(Trigger.new);
            } else if(Trigger.isUpdate) {
                //handlerOppTM.getProductsSpecialist(trigger.newMap, trigger.oldMap);
                //DES_OpportunityTriggerHandler.triggerAfterUpdate(trigger.newMap, trigger.oldMap, trigger.new);
                // llamo a la funcion de copia del equipo de oportunidad
                //handlerOppTM.automaticClientTeamCopy(Trigger.newMap, Trigger.oldMap);
                handlerOppTM.checkOwnerOppMember(Trigger.newMap,Trigger.oldMap);
                handlerOppTM.accHierarchyTeamCopyToOppTeam(Trigger.newMap, Trigger.oldMap);
                handlerOpp.denormOnAfterUpdate(Trigger.new,Trigger.oldMap, Trigger.newMap);
                handlerOpp.moveFilesToNBC(Trigger.newMap, Trigger.oldMap);
                OpportunityTriggerHandler.completeBookTemplate(trigger.new, trigger.oldMap);
                OpportunityTriggerHandler.updateTemplate(trigger.new, trigger.oldMap);
                OpportunityTriggerHandler.crearChatter(trigger.new, trigger.oldMap);
                OpportunityTriggerHandler.crearNbcMembers(trigger.new, trigger.oldMap);
                OpportunityTriggerHandler2.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
                //OpportunityTriggerHandler.showSimilarOppsFound(trigger.new, trigger.oldMap);
                /*  ComentadasCampañasAlertasParaSubidaPosterior
                handlerOpp.closeAccountCampaign(Trigger.newMap, Trigger.oldMap);
                ComentadasCampañasAlertasParaSubidaPosterior    */
                if(!system.isFuture() && !system.isBatch()) {
                    DES_HandlerTerritory.shareNBC(Trigger.newMap, Trigger.oldMap);
                    DES_HandlerTerritory.updateOppShare(Trigger.oldMap, Trigger.newMap);
                }
                OpportunityTriggerHandler2.UpdateReopenOpportunity(trigger.new, trigger.old);

            }
            //else if(Trigger.isDelete){
                // handlerOpp.onAfterDelete(Trigger.old);
                
            //}
        } else {
            // Logic specifically for DMT_Opportunity Record Type
            if(Trigger.isUpdate) {
                handlerOpp.createOppVersionSnapshot(Trigger.new, Trigger.oldMap);
                handlerOpp.updatePassport_OppStatusChanged(Trigger.new,Trigger.oldMap);

            } else if (Trigger.isInsert) {
                dmtHandlerOpp.enqueueOppXSellGeneration(Trigger.new);
            }
            
            // Single flush for the entire DMT Opportunity After context
            DMT_AsyncOrchestrator.flush();
        }
    }
    
    
    
}