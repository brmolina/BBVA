trigger ContentVersionTrigger on ContentVersion (before update) {    
    if(TriggerBypass.bypassTrigger) return;
    CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
    if(!byPass.CIB_skip_trigger__c) {
        final ContentVersionTriggerHandler handlerContentVersion = ContentVersionTriggerHandler.getInstance();
        system.debug('>>>>> triggerNew : ' + trigger.new);
        if(Trigger.isBefore){
            if(Trigger.isUpdate){
                handlerContentVersion.beforeUpdate(trigger.newMap, trigger.oldMap);
            }
        }
    }
}