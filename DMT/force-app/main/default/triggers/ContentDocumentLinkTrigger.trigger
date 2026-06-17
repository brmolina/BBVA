trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
    if(!byPass.CIB_skip_trigger__c) {
        final ContentDocumentLinkTriggerHandler handlerContentVersionLink = ContentDocumentLinkTriggerHandler.getInstance();
        system.debug('>>>>> triggerNew : ' + trigger.new);

        if(Trigger.isAfter){
            if(Trigger.isInsert){
                handlerContentVersionLink.afterInsert(trigger.newMap, trigger.oldMap);
            }
        }
    }
}