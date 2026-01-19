/**
* --------------------------------------------------------------------
* Currency exchange rate class for calculating currency conversions
* based on EUR exchange rates.
* --------------------------------------------------------------------
* @author      torcuato.tejada.tech@bbva.com
* @version     1.0
* @created     2024-06-14
* @modified    2025-07-15
* @systemLayer Business Logic
* --------------------------------------------------------------------
* @changes
*
* --------------------------------------------------------------------
*/
public with sharing class DMT_Currency {

    /**
    * @description Get currency list
    * @return Set<String> currencies from HPGR configuration
    */
    public static Set<string> getCurrencyList() {
        Set<String> currencies = new Set<String>();
        currencies.add('EUR');
        Schema.DescribeFieldResult pickList = hpgr__Currency__mdt.hpgr__Currency__c.getDescribe();
        for(Schema.PicklistEntry pickVal : pickList.getPicklistValues()){
            currencies.add(pickVal.value);
        }
        return currencies;
    }

    /**
    * @description Get exchange rates for a given base currency
    * @param baseCurrency : base currency (e.g. 'EUR')
    * @return Wrapper currencies
    */
    public static Wrapper getExchangeRates(String baseCurrency) {
        Date filterDate = Date.today().addDays(-7);
        Set<String> currencies = getCurrencyList();
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
    * @description Convert amount from one currency to another using current exchange rates
    * @param amount Amount to convert
    * @param fromCurrency Source currency code (e.g. 'EUR', 'USD')
    * @param toCurrency Target currency code (e.g. 'MXN', 'ARS')
    * @return Decimal converted amount
    */
    public static Decimal convert(Decimal amount, String fromCurrency, String toCurrency) {
        Decimal converted;
        if (fromCurrency.equalsIgnoreCase(toCurrency)) {
            converted = amount;
        } else {
            try {
                Wrapper currencyData = getExchangeRates(fromCurrency);
                if (currencyData != null && currencyData.exchangeRates != null) {
                    for (ExchangeRate rate : currencyData.exchangeRates) {
                        if (rate.currencyId.equalsIgnoreCase(toCurrency)) {
                            converted = amount * rate.exchangeRate;
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error during currency conversion: ' + e.getMessage());
            }
        }
        return converted;
    }

    /**
    * @description Response wrapper containing base currency and its exchange rates
    */
	public class Wrapper {
		@AuraEnabled
		public String baseCurrency {get; set;}

		@AuraEnabled
		public List<ExchangeRate> exchangeRates {get; set;}
	}

    /**
    * @description Exchange rate data for a specific currency with conversion rate and update date
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