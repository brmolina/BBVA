public class DES_Simple_Table_Controller {
  
    @AuraEnabled
    public static Account getAccountData(Id accountId) {
            Account account = [SELECT Name,DES_Engloba_Link__c,DES_Datamart_Link__c,DES_Revenue_Update__c,DES_RAR_EVA_RORC_Update__c,CurrencyIsoCode,DES_Revenues__c,DES_Data_scope__c,DES_Operating_expenses__c,DES_EL__c,DES_Taxes__c,DES_Economic_Profit__c,DES_Capital_Charge__c,DES_EVA__c,DES_RARinfo_Capital_Consumption__c,DES_RAR_YTD__c,DES_GROSS_MARGIN__c FROM Account WHERE Id=:accountId];
        	system.debug('la cuenta es:' + account);
		return account;
    }
}