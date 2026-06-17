trigger SER_CurrencyExchangeRate_TRIGGER on SER_EUR_Currency_exchange_rate__c (before insert,before update,before delete,after insert,after update,after delete,after undelete) {
	/*Instancia de bypass*/
	CIB_ByPass__c byPass = CIB_ByPass__c.getInstance();
	if(!byPass.CIB_skip_trigger__c && Trigger.isBefore) {
		if(Trigger.isInsert) {
			SER_CEXMethods.validateUnlistedCurrency(Trigger.new);
			SER_CEXMethods.assignProcessDate(Trigger.new);
		} else if(Trigger.isUpdate) {
			SER_CEXMethods.validateUnlistedCurrency(Trigger.newMap);	
			SER_CEXMethods.assignProcessDate(Trigger.newMap, Trigger.oldMap);
		}
	}
}