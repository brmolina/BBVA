/* Author:        Juan Carlos Terrón
	Company:       Accenture
	Description:   Schedulable class to delete duplicate email messages on the same thread due to multiaddress email-to-case

	History:
	<Date>          <Author>                <Description>
	19/12/2017		Juan Carlos Terrón		Initial version
	26/01/2018		Juan Carlos Terrón		Modified Deletion bucles to avoid recursive calls. */
public with sharing class SER_E2C_DuplicatedThreadCleaner implements Queueable {
	/*Log to insert*/
	CIB_Log__c log;
	/*Oldest creation date of the time range*/
	Datetime oldestCD;
	/*Newest creation date of the time range*/
	Datetime newestCD;
	/*Map of unique codes and its current selected email*/
	Map<String,EmailMessage> mapCodes;
	/*Map of emails from previous process in email message trigger*/
	Map<Id,EmailMessage> mapEmails;
	/*Map of emails to delete after processing*/
	Map<Id,EmailMessage> mapToDelete;
	/*Constructor*/
	public SER_E2C_DuplicatedThreadCleaner(Map<Id,EmailMessage> mapEmails) {
		this.log = new CIB_Log__c();
		this.mapEmails = mapEmails;
		this.mapCodes = new Map<String,EmailMessage>();
		this.mapToDelete = new Map<Id,EmailMessage>();
	}
	/*Overrided execute batch method*/
	public void execute(QueueableContext context) {
		try {
			this.log.CIB_ErrorMessage__c = '';
			this.log.CIB_Subject__c = 'SER_E2C_DuplicatedThreadCleaner JOB';

			for(EmailMessage email : this.mapEmails.values()) {
				this.processOldestCD(email);
				this.fillProcessMaps(email);
			}
			this.log.CIB_ErrorMessage__c += 'Mapa de procesamiento: '+this.mapCodes.size()+'\n';
			this.log.CIB_ErrorMessage__c += 'Mapa de borrado: '+this.mapToDelete.size()+'\n';
			this.newestCD 		= this.oldestCD.addSeconds(30); //Final point of criteria time range
			this.oldestCD 	= this.oldestCD.addSeconds(-30); //Initial point of criteria time range.
			for(EmailMessage email : this.retrieveDuplicatedEmails().values()) {
				this.processMaps(email);
			}
			this.log.CIB_ErrorMessage__c += 'Mapa de procesamiento: '+this.mapCodes.size()+'\n';
			this.log.CIB_ErrorMessage__c += 'Mapa de borrado: '+this.mapToDelete.size()+'\n';
			if(!this.mapToDelete.isEmpty()) { //If the map to delete isn't empty we delete de map values.
				Boolean next;
				next = true;
				while(next) {
					next = this.deleteEmails();
				}
			}
			this.log.CIB_ErrorMessage__c += 'Mapa de borrado: '+this.mapToDelete.size()+'\n';
			insert this.log; //Error log creation.
		} catch(Exception ex) { //Error Log creation for non-controlled exceptions.
			this.log = new CIB_Log__c();
			this.log.CIB_ErrorMessage__c = ex.getStackTraceString()+'\n'+ex.getMessage();
			this.log.CIB_Subject__c = 'SER_E2C_DuplicatedThreadCleaner';
			insert this.log;
		}
	}

	private Map<Id,EmailMessage> retrieveDuplicatedEmails() {
		Map<Id,EmailMessage> duplicates;
		duplicates = new Map<Id,EmailMessage>();
		for(EmailMessage email : [
				select 	Id,SER_UniqueCode__c,CreatedDate
				from	EmailMessage
				where	IsDeleted = false
						AND
						(CreatedDate <= :this.newestCD
						AND CreatedDate >= :this.oldestCD)
						AND SER_UniqueCode__c in :this.mapCodes.keyset()
						order by Id asc
		]) {
			duplicates.put(email.Id,email);
		}
		return duplicates;
	}
	private void processOldestCD(EmailMessage email) {
		final Datetime emailCD = email.CreatedDate;
		if(this.oldestCD == null) {
			this.oldestCD = emailCD;
		} else if(emailCD <= this.oldestCD) {
			this.oldestCD = emailCD;
		}
	}
	private void fillProcessMaps(EmailMessage email) {
		final String e2cCode = email.SER_UniqueCode__c;
		if(String.isNotBlank(e2cCode) && this.mapCodes.containsKey(e2cCode)) {
			final EmailMessage auxiliar = this.mapCodes.get(e2cCode);
			final Boolean notSameEmail = email.Id != auxiliar.Id;
			final Boolean previousEmail = email.CreatedDate <= auxiliar.CreatedDate;
			if(notSameEmail && previousEmail) {
				this.mapToDelete.put(auxiliar.Id,auxiliar);
				this.mapCodes.put(email.SER_UniqueCode__c,email);
				if(this.mapToDelete.containsKey(email.Id)) {
					this.mapToDelete.remove(email.Id);
				}
			} else if(notSameEmail) {
				this.mapToDelete.put(email.Id,email);
			}
		} else if(String.isNotBlank(e2cCode)) {
			this.mapCodes.put(email.SER_UniqueCode__c,email);
		}
	}
	private void processMaps(EmailMessage email) {
		final String e2cCode = email.SER_UniqueCode__c;
		if(String.isNotBlank(e2cCode) && this.mapCodes.containsKey(e2cCode)) {
			final EmailMessage auxiliar = this.mapCodes.get(e2cCode);
			final Boolean notSameEmail = email.Id != auxiliar.Id;
			final Boolean previousEmail = email.CreatedDate <= auxiliar.CreatedDate;
			final Boolean inTimeRange = email.CreatedDate <= this.newestCD && email.CreatedDate >= this.oldestCD;
			if(notSameEmail && previousEmail && inTimeRange) {
				this.mapToDelete.put(auxiliar.Id,auxiliar);
				this.mapCodes.put(email.SER_UniqueCode__c,email);
				if(this.mapToDelete.containsKey(email.Id)) {
					this.mapToDelete.remove(email.Id);
				}
			} else if(notSameEmail) {
				this.mapToDelete.put(email.Id,email);
			}
		} else if(String.isNotBlank(e2cCode)) {
			this.mapCodes.put(email.SER_UniqueCode__c,email);
		}
	}
	private Boolean deleteEmails() {
		Boolean result;
		result = false;
		try {
			if(this.mapToDelete.isEmpty() == false) {
				delete this.mapToDelete.values();
				result = true;
			}
		} catch(Exception error) {
			final String errorMessage = error.getMessage();
			final String emailId = errorMessage.substring(errorMessage.indexOfIgnoreCase('02s'),errorMessage.indexOfIgnoreCase('02s')+18);
			this.mapToDelete.remove(emailId);
		}
		return result;
	}
}