/*-----------------------------------------------------------------------------------
	Author:        Juan Carlso Terrón
	Company:       Accenture
	Description:   Trigger to handle standard object EmailMessage automatic processes.

	History:
	<Date>          <Author>                <Description>
	08/07/2017		Juan Carlos Terrón		Initial version
-------------------------------------------------------------------------------------*/
//Standard object EmailMessage trigger - CIB Service
trigger SER_EmailMessage_TRIGGER on EmailMessage (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();//Retieve ByPass custom setting instance to filter the processing.
	
	if(!byPass.CIB_skip_trigger__c) { //The value of CIB_skip_trigger__c field controls if the triggers processes are fired when the triggers are fired.
		if (Trigger.isBefore) { //"Before" Trigger events, also handled by DML Operation.
			if(Trigger.isInsert) { //"Insert" event
				SER_EmailMessageMethods.UpdateAddress(Trigger.new);
				SER_EmailMessageMethods.validateFromAddress(Trigger.new);
				SER_EmailMessageMethods.generate_UniqueCode(Trigger.new);
			}
		} else if (Trigger.isAfter) {
			if(Trigger.isInsert) { //"Insert" event
				try { //Try-catched processes to retrieve error logs during email-to-case errors.
					Map<id, EmailMessage> newMapCopy = SER_EmailMessageMethods.checker_duplicatedEmailToCase(Trigger.newMap);
					SER_EmailMessageMethods.assigner_RelatedCaseOwner(newMapCopy);
					SER_EmailMessageMethods.cleaner_MasterCaseNotifications(Trigger.newMap);
				} catch(Exception error) {
					CIB_LogUtils.create_Log(error.getStackTraceString().abbreviate(245) + '... ', error.getMessage().abbreviate(131000) + '... ' + error.getLineNumber());
				}
			}
		} 
	}
}