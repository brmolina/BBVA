/**
* --------------------------------------------------------------------
* Currencies class.
* --------------------------------------------------------------------
* @author     torcuato.tejada.tech@bbva.com
* @modifiedBy
* @version     1.0
* @created     2024-06-14
* @modified
* @systemLayer
* --------------------------------------------------------------------
* @changes
*
* --------------------------------------------------------------------
*/
public with sharing class HPG_Currency {

    /**
    * @description Get currency list
    * @return Set<String> currencies
    */
    public static Set<string> getCurrencyList() {
        Set<String> currencies = new Set<String>();
        currencies.add('EUR');
        Schema.DescribeFieldResult pickList = HPG_Currency__mdt.Currency__c.getDescribe();
        for(Schema.PicklistEntry pickVal : pickList.getPicklistValues()){
            currencies.add(pickVal.value);
        }
        return currencies;
    }

    /**
    * @description Get currency picklist values
    * @param baseCurrency : base currency (e.g. 'EUR')
    * @return List<Wrapper> currencies
    */
    public static Wrapper getCurrencies(String baseCurrency) {
        Date filterDate = Date.today().addDays(-7);
        Set<String> currencies = getCurrencyList();
        system.debug(currencies);
        List<ExchangeRate> rates = new List<ExchangeRate>();
        Decimal baseRate = 1.0;
        List<SER_EUR_Currency_exchange_rate__c> exchangeRates = [SELECT SER_Counter_currency__c, SER_Exchange_rate__c, SER_Process_date__c
                                                                 FROM SER_EUR_Currency_exchange_rate__c
                                                                 WHERE SER_Base_currency__c = 'EUR'
                                                                 AND SER_Counter_currency__c IN :currencies
                                                                 AND SER_Process_date__c > :filterDate
                                                                 ORDER BY SER_Counter_currency__c, SER_Process_date__c DESC];
        // set base currency and get all exchangeRates from EUR
        if (baseCurrency == 'EUR') {
            ExchangeRate rate = new ExchangeRate();
            rate.currencyId = 'EUR';
            rate.exchangeRate = baseRate;
            rate.updated = exchangeRates[0].SER_Process_date__c;
            rates.add(rate);
        } else {
            for (SER_EUR_Currency_exchange_rate__c exchangeRate : exchangeRates) {
                if (exchangeRate.SER_Counter_currency__c == baseCurrency) {
                    baseRate = exchangeRate.SER_Exchange_rate__c;
                    ExchangeRate rate = new ExchangeRate();
                    rate.currencyId = 'EUR';
                    rate.exchangeRate = 1/baseRate;
                    rate.updated = exchangeRate.SER_Process_date__c;
                    rates.add(rate);
                }
            }
        }
        for (SER_EUR_Currency_exchange_rate__c exchangeRate : exchangeRates) {
            ExchangeRate rate = new ExchangeRate();
            rate.currencyId = exchangeRate.SER_Counter_currency__c;
            rate.exchangeRate = exchangeRate.SER_Exchange_rate__c / baseRate;
            rate.updated = exchangeRate.SER_Process_date__c;
            rates.add(rate);
        }
        Wrapper res = new Wrapper();
        res.baseCurrency = baseCurrency;
        res.exchangeRates = rates;
        return res;
    }

    /**
    * @description Wrapper for currencies
    */
	public class Wrapper {
		@AuraEnabled
		public String baseCurrency {get; set;}

		@AuraEnabled
		public List<ExchangeRate> exchangeRates {get; set;}
	}

    /**
    * @description Wrapper for currencies
    */
	public class ExchangeRate {
		@AuraEnabled
		public String currencyId {get; set;}

        @AuraEnabled
		public Decimal exchangeRate {get; set;}

        @AuraEnabled
		public Date updated {get; set;}
	}
}