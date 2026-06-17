trigger CommercialAlertTrigger on almd__Commercial_Alert__c (before insert, before update, after insert, after update) {

	if(Trigger.isBefore) {
		if(Trigger.isInsert) {
			CommercialAlertTriggerHandler.concatenateBBVASA(trigger.new);
	        CommercialAlertTriggerHandler.concatenateAlertName(trigger.new, null);
	        CommercialAlertTriggerHandler.setLookupUsers(trigger.new, null);
            CommercialAlertTriggerHandler.setRecordType(trigger.new);
			CommercialAlertTriggerHandler.informOwner(trigger.new);
		}
		if(Trigger.isUpdate) {
			CommercialAlertTriggerHandler.setNameUpdate(trigger.new, trigger.oldMap);
			CommercialAlertTriggerHandler.checkClosedAlert(trigger.oldMap, trigger.newMap);
			CommercialAlertTriggerHandler.setLookupUsers(trigger.new, trigger.oldMap);
			CommercialAlertTriggerHandler.informOwner(trigger.new);
		}
	}

	if(Trigger.isAfter) {
        Map<Id, almd__Commercial_Alert__c> newAlertMap;
        newAlertMap = CommercialAlertTriggerHandler.filtrarDescartadas(trigger.new);

		if(Trigger.isInsert) {
            CommercialAlertTriggerHandler.createManualSharing(newAlertMap.values(), null);
		}
		if(Trigger.isUpdate) {
			CommercialAlertTriggerHandler.checkOwnerBankerChange(newAlertMap.values(), trigger.oldMap);
			CommercialAlertTriggerHandler.createManualSharing(newAlertMap.values(), trigger.oldMap);
			CommercialAlertTriggerHandler.afterUpdate(newAlertMap.values(), trigger.old, newAlertMap, trigger.oldMap);
            if(!CommercialAlertTriggerHandler.listComAlertShareToDelete.isEmpty()) {
                system.debug('CommercialAlertTriggerHandler.listComAlertShareToDelete: ' + CommercialAlertTriggerHandler.listComAlertShareToDelete);
                delete CommercialAlertTriggerHandler.listComAlertShareToDelete;
            }
            CommercialAlertTriggerHandlerWihoutShare.alertShareToDelete(JSON.serialize(Desktop_Utils.alertShareToDelete));
		}
	}

}