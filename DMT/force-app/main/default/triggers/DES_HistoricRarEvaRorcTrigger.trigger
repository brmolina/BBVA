trigger DES_HistoricRarEvaRorcTrigger on DES_Historic_RAR_EVA_RORC__c (before insert) {

    if(trigger.isBefore){
        if(trigger.isInsert){
            DES_HistoricRarEvaRorcTriggerHandler.checkDateHistoricUpdate(trigger.New);
        }
    }

}