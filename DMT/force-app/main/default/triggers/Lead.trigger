trigger Lead on Lead (after update, after insert) {
	//Get TriggerHandler
    LeadTriggerHandler Handler = new LeadTriggerHandler();
    
    //ON AFTER UPDATE
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            Handler.OnAfterUpdate(Trigger.new);
            DES_HandlerTerritory.shareWithTerritoryListTrigger(Trigger.new, Trigger.old);
        }
        if(Trigger.isInsert) {
            DES_HandlerTerritory.shareWithTerritoryListTrigger(Trigger.new, null);
        }
    }
    
     
}