/**********************************************************************************
* @author       Glbal Desktop
* @date         06/09/2021
* @description  Trigger para objeto TIER. 
**********************************************************************************/
trigger GtbTierTrigger on tier_gtb__c (after insert, before insert, after update, before update) {
    if(Trigger.isAfter) {
        
       GtbTierTriggerHandler.updateRelatedAccTier(trigger.new);
   }
    if(Trigger.isBefore) {
       GtbTierTriggerHandler.updateTierName(trigger.new);
	
   }
}