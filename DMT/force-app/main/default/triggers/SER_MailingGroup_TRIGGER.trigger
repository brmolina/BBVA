trigger SER_MailingGroup_TRIGGER on SER_MailingGroup__c (before insert,before update,before delete,after insert,after update,after delete,after undelete) {
	/**
	* @author Juan Carlos Terron
	*/
	CIB_ByPass__c byPass = CIB_ByPass__c.getInstance();

	if(!byPass.CIB_skip_trigger__c && Trigger.isBefore) {
		if(Trigger.isInsert) {
			SER_MailingGroupMethods.validateUser(Trigger.new);
			SER_MailingGroupMethods.validateDefaultMailbox(Trigger.new);
		} else if(Trigger.isUpdate) {
			SER_MailingGroupMethods.validateUser(Trigger.newMap);
			SER_MailingGroupMethods.validateDefaultMailbox(Trigger.new);
		}
	}
}