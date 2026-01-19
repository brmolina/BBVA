/**
* ____________________________________________________________________________
* Controller class for HPG_Buttons.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-04-12
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class HPG_Buttons_Ctrl {
    /**
    * @description Get initial data
    * @param params - : params
    * @return retMap initial data
    */
    @AuraEnabled
    public static Map<String,Object> initialData(String localStorageCurrency) {
        Map<String, Object> retMap = new Map<String, Object>();
        retMap.put('currencies', getCurrencyPicklist(localStorageCurrency));
        return retMap;
    }
    /**
    * @description Get currency picklist values
    * @param - : No param
    * @return currency currencies
    */
    @AuraEnabled
    public static List<Currency_Wrapper> getCurrencyPicklist(String localStorageCurrency) {
        Set<String> currencies = new Set<String>();
        List<Currency_Wrapper> currencyPicklist = new List<Currency_Wrapper>();
        Map<String,Currency_Wrapper> currencyPicklistMap = new Map<String,Currency_Wrapper>();
        // Get currency picklist values
        Schema.DescribeFieldResult pickList = HPG_Currency__mdt.Currency__c.getDescribe();
        for(Schema.PicklistEntry pickVal : pickList.getPicklistValues()){
            Boolean defaultvalue = false;
            if (pickVal.value == localStorageCurrency) {
                defaultvalue = true;
            }
            currencies.add(pickVal.value);
            Currency_Wrapper picklistValue = new Currency_Wrapper(pickVal.label, pickVal.value, defaultvalue, 1);
            currencyPicklistMap.put(pickVal.label, picklistValue);
            currencyPicklist.add(picklistValue);
        }
        // Get exchange rates
        List<Currency_Wrapper> currencyPicklistUpdated = new List<Currency_Wrapper>();
        currencyPicklistUpdated.add(currencyPicklistMap.get('EUR'));
        String counterCurrency = '';
        Date filterDate = Date.today().addDays(-7);
        for (SER_EUR_Currency_exchange_rate__c currencyExchangeRate : [SELECT SER_Counter_currency__c, SER_Exchange_rate__c, SER_Process_date__c
                                                                        FROM SER_EUR_Currency_exchange_rate__c
                                                                        WHERE SER_Base_currency__c = 'EUR' AND SER_Counter_currency__c IN :currencies AND SER_Process_date__c > :filterDate
                                                                        ORDER BY SER_Counter_currency__c, SER_Process_date__c DESC]) {
            if (counterCurrency != currencyExchangeRate.SER_Counter_currency__c) {
                counterCurrency = currencyExchangeRate.SER_Counter_currency__c;
                Currency_Wrapper currencyExchange = currencyPicklistMap.get(counterCurrency);
                currencyExchange.exchangeRate = currencyExchangeRate.SER_Exchange_rate__c;
                currencyPicklistUpdated.add(currencyExchange);
            }
        }
        // Add exchange rate to label
        for (Currency_Wrapper picklistValue : currencyPicklistUpdated) {
            if (picklistValue.value != 'EUR') {
                Decimal exchangeRateEUR = 1 / picklistValue.exchangeRate;
                String exchangeRateEURFormatted = String.valueOf(exchangeRateEUR.setScale(6));
                picklistValue.label = picklistValue.label + ' ( ' + exchangeRateEURFormatted + '  EUR)';
            }
        }
        return currencyPicklistUpdated;
    }
    /**
    * @description Wrapper for booking units
    */
	//public class Booking_Unit_Wrapper {
	//	@AuraEnabled
	//	public String label {get; set;}
	//	@AuraEnabled
	//	public String value {get; set;}
    //    @AuraEnabled
	//	public Boolean checked {get; set;}
    //    public Booking_Unit_Wrapper(String label, String value, Boolean checked) {
    //        this.label = label;
    //        this.value = value;
    //        this.checked = checked;
    //    }
	//}
    /**
    * @description Wrapper for currencies
    */
	public class Currency_Wrapper {
		@AuraEnabled
		public String label {get; set;}
		@AuraEnabled
		public String value {get; set;}
        @AuraEnabled
		public Boolean selected {get; set;}
        @AuraEnabled
		public Decimal exchangeRate {get; set;}
        public Currency_Wrapper(String label, String value, Boolean selected, Decimal exchangeRate) {
            this.label = label;
            this.value = value;
            this.selected = selected;
            this.exchangeRate = exchangeRate;
        }
	}
}