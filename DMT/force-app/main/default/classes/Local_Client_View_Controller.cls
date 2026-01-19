public without sharing class Local_Client_View_Controller {
	@AuraEnabled
    public static String getCountry(String recordId){
        Account cliente = new Account();
        cliente = [SELECT DES_Country_Client__c from Account where id=: recordId limit 1];
        return cliente.DES_Country_Client__c;
    }
    @AuraEnabled
    public static list<Local_Client__c> getLocalClient(String recordId){
       list<Local_Client__c> clienteLocal = [SELECT Id,Cib_Client__c,country_id__c  from Local_Client__c where Cib_Client__c=:recordId];
        system.debug('>>>>>>>>>>>>>>>>>>>>>>>'+clienteLocal);
        return clienteLocal;
    }
}