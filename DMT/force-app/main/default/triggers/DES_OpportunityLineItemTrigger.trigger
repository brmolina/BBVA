/*
*  @author     Global Desktop
*  @ Description   Trigger del objeto OpportunityLineItem
*
*  @Revision
17/03/2020    JSS    Se añaden llamadas a métodos con lógica para las oportunidades de la funcionalidad PRICING
**/
trigger DES_OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, after insert, after update, after delete) {
    
    if(TriggerBypass.bypassTrigger){
        return;
    }
    
    final DES_sumRevenueOpportunityTriggerHandler handler = DES_sumRevenueOpportunityTriggerHandler.getInstance();
    final OpportunityLineItemPricingTriggerHandler pricingHandler = OpportunityLineItemPricingTriggerHandler.getInstance();
    
    if(Trigger.isBefore) {
        if(Trigger.isInsert || Trigger.isUpdate) {
            List<OpportunityLineItem> oliList = Trigger.new;
            List<OpportunityLineItem> oliListDmtRtExcluded = new List<OpportunityLineItem>();
            Set<Id> oppIds = new Set<Id>();
            Map<Id, Opportunity> oppMap;

            for(OpportunityLineItem oli : oliList) {
                if( oli.OpportunityId!= null ){
                    oppIds.add(oli.OpportunityId);
                } 
            }
            if (!oppIds.isEmpty()) {
                oppMap = new Map<Id, Opportunity>([SELECT Id, RecordType.DeveloperName FROM Opportunity WHERE Id IN :oppIds]);
                for(OpportunityLineItem oli : oliList) {
                    Opportunity opp = oppMap?.get(oli.OpportunityId);
                    if(opp != null && opp.RecordType.DeveloperName != 'DMT_Opportunity') {
                        oliListDmtRtExcluded.add(oli);
                    }

                }
            }
 
            if(!oliListDmtRtExcluded.isEmpty()) {
                fprd.GBL_OpportunityLineItemHandler_cls.setOpportunityProductVersion(oliListDmtRtExcluded);
            }
        

            
            //DES_OpportunityLineItemTriggerHandler.setFamilyProduct(trigger.new);
            if(Trigger.isInsert){
                DMT_OpportunityLineItemHandler.syncNewMoneyAndFinalTakeWithBbvaCommitment(Trigger.new);
                pricingHandler.checkPricingLogicForAddNewOLI(Trigger.new);
                DES_relatedProductsTriggerHandler.insertWithDraftStage(Trigger.new);
                DES_relatedProductsTriggerHandler.fillBbvaParticipationPer(Trigger.new);
                DES_relatedProductsTriggerHandler.fillAmountToBeSold(Trigger.new);
                DMT_OpportunityLineItemHandler.handleAfterInsertOrUpdate(Trigger.new);
                DMT_OpportunityLineItemHandler.calculateTenorYears(Trigger.new);
                DMT_OpportunityLineItemHandler.calculateGreenSocialBonds(Trigger.new, null);
                DMT_OpportunityLineItemHandler.calculateRiskType(Trigger.new, null);
            }
            if(Trigger.isUpdate) {
                DMT_OpportunityLineItemHandler.syncNewMoneyAndFinalTakeWithBbvaCommitment(Trigger.new);
                DES_handleMultitrancheToogling.checkMultitranche(Trigger.newMap,Trigger.oldMap);
                DES_relatedProductsTriggerHandler.checkAutoFillFields(Trigger.newMap,Trigger.oldMap);
                DES_relatedProductsTriggerHandler.fillFinalAllocation(Trigger.newMap,Trigger.oldMap);
                DES_relatedProductsTriggerHandler.fillBbvaParticipationPer(Trigger.newMap,Trigger.oldMap);
                DES_relatedProductsTriggerHandler.fillAmountToBeSold(Trigger.newMap,Trigger.oldMap);
                DMT_OpportunityLineItemHandler.calculateTenorYears(Trigger.new);
                DMT_OpportunityLineItemHandler.calculateGreenSocialBonds(Trigger.new, Trigger.oldMap); 
                DMT_OpportunityLineItemHandler.calculateRiskType(Trigger.new, Trigger.oldMap);   
                //DMT_OpportunityLineItemHandler.syncDealAmountWithBbvaCommitment(oliList);      
            }
        } else if (Trigger.isDelete) {
            pricingHandler.checkLogicForDeletingPricingOLI(Trigger.old);
        }
        
    }
    
    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            handler.setOppDecisionTaken(Trigger.newMap, Trigger.oldMap);
            handler.UpdateTrachaReopenOpportunity(trigger.new, trigger.old);
            DMT_OpportunityLineItemHandler.calculateDmtOpportunityDealAmount(Trigger.newMap,Trigger.oldMap);
            DMT_OpportunityLineItemHandler.calculateOpportunityDatesFromLineItems(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isInsert) {
            DES_relatedProductsTriggerHandler.fillOppPrducts(Trigger.new);
            DES_HandlerTerritory.shareOpportunity (Trigger.new);
            DMT_OpportunityLineItemHandler.calculateOpportunityDatesFromLineItems(Trigger.new, null);
            DMT_OpportunityLineItemHandler.calculateDmtOpportunityDealAmount(Trigger.newMap,Trigger.oldMap);
        }
        if(Trigger.isDelete) {
            pricingHandler.deletePricingData(Trigger.old);
            DES_relatedProductsTriggerHandler.deleteOppPrducts(Trigger.old);
            DES_HandlerTerritory.deleteOppShare (Trigger.old);
            DMT_OpportunityLineItemHandler.calculateDmtOpportunityDealAmount(null,Trigger.oldMap);
        }

    }
    
}