/*-------------------------------------------------------------------------------------------
* @Name     HPGR_Currencies
* @Author   torcuato.tejada.tech@bbva.com
*           cosme.alcazar.tech@bbva.com
* @Date     Created: 2024-07-18
* -------------------------------------------------------------------------------------------
* @Description Currencies_Itf implementation class
* -------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class HPGR_Currencies implements hpgr.Currencies_Itf {

    static final String CURRENCY_CODE_EUR = 'EUR';

    /**
    * @description Get currency values
    * @param baseCurrency : base currency (e.g. 'EUR')
    * @return List<Wrapper> currencies
    */
    public static hpgr.Currencies.Wrapper getCurrencies(String baseCurrency) {
        Date filterDate = Date.today().addDays(-7);
        Set<String> currencies = getCurrencyList();
        List<hpgr.Currencies.ExchangeRate> rates = new List<hpgr.Currencies.ExchangeRate>();
        Decimal baseRate = 1.0;
        List<SER_EUR_Currency_exchange_rate__c> exchangeRates = [SELECT SER_Counter_currency__c, SER_Exchange_rate__c, SER_Process_date__c
                                                                 FROM SER_EUR_Currency_exchange_rate__c
                                                                 WHERE SER_Base_currency__c = :CURRENCY_CODE_EUR
                                                                 AND SER_Counter_currency__c IN :currencies
                                                                 AND SER_Process_date__c > :filterDate
                                                                 ORDER BY SER_Counter_currency__c, SER_Process_date__c DESC];
        // set base currency and get all exchangeRates from EUR
        if (baseCurrency == CURRENCY_CODE_EUR) {
            hpgr.Currencies.ExchangeRate rate = new hpgr.Currencies.ExchangeRate();
            rate.currencyId = CURRENCY_CODE_EUR;
            rate.exchangeRate = baseRate;
            rates.add(rate);
        } else {
            for (SER_EUR_Currency_exchange_rate__c exchangeRate : exchangeRates) {
                if (exchangeRate.SER_Counter_currency__c == baseCurrency) {
                    baseRate = exchangeRate.SER_Exchange_rate__c;
                    hpgr.Currencies.ExchangeRate rate = new hpgr.Currencies.ExchangeRate();
                    rate.currencyId = CURRENCY_CODE_EUR;
                    rate.exchangeRate = 1/baseRate;
                    rates.add(rate);
                }
            }
        }
        for (SER_EUR_Currency_exchange_rate__c exchangeRate : exchangeRates) {
            hpgr.Currencies.ExchangeRate rate = new hpgr.Currencies.ExchangeRate();
            rate.currencyId = exchangeRate.SER_Counter_currency__c;
            rate.exchangeRate = exchangeRate.SER_Exchange_rate__c / baseRate;
            rates.add(rate);
        }
        hpgr.Currencies.Wrapper res = new hpgr.Currencies.Wrapper();
        res.baseCurrency = baseCurrency;
        res.exchangeRates = rates;
        return res;
    }

    /**
    * @description Get currency list
    * @param - : no param
    * @return Set<String> currencies
    */
    public static Set<string> getCurrencyList() {
        Set<String> currencies = new Set<String>();
        currencies.add(CURRENCY_CODE_EUR);
        Schema.DescribeFieldResult pickList = hpgr__Currency__mdt.hpgr__Currency__c.getDescribe();
        for(Schema.PicklistEntry pickVal : pickList.getPicklistValues()){
            currencies.add(pickVal.value);
        }
        return currencies;
    }

    /**
    * @description Get currency picklist values
    * @param localStorageCurrency : localStorage currency (e.g. 'EUR')
    * @return List<Picklist_Wrapper> currencies
    */
    @AuraEnabled
    public static List<hpgr.Currencies.Picklist_Wrapper> getCurrencyPicklist(String localStorageCurrency) {
        Set<String> currencies = new Set<String>();
        List<hpgr.Currencies.Picklist_Wrapper> currencyPicklist = new List<hpgr.Currencies.Picklist_Wrapper>();
        Map<String,hpgr.Currencies.Picklist_Wrapper> currencyPicklistMap = new Map<String,hpgr.Currencies.Picklist_Wrapper>();
        // Get currency picklist values
        Schema.DescribeFieldResult pickList = hpgr__Currency__mdt.hpgr__Currency__c.getDescribe();
        for(Schema.PicklistEntry pickVal : pickList.getPicklistValues()){
            Boolean defaultvalue = false;
            if (pickVal.value == localStorageCurrency) {
                defaultvalue = true;
            }
            currencies.add(pickVal.value);
            hpgr.Currencies.Picklist_Wrapper picklistValue = new hpgr.Currencies.Picklist_Wrapper(pickVal.label, pickVal.value, defaultvalue, 1);
            currencyPicklistMap.put(pickVal.label, picklistValue);
            currencyPicklist.add(picklistValue);
        }
        // Get exchange rates
        List<hpgr.Currencies.Picklist_Wrapper> currencyPicklistUpdated = new List<hpgr.Currencies.Picklist_Wrapper>();
        currencyPicklistUpdated.add(currencyPicklistMap.get(CURRENCY_CODE_EUR));
        String counterCurrency = '';
        Date filterDate = Date.today().addDays(-7);
        for (SER_EUR_Currency_exchange_rate__c currencyExchangeRate : [SELECT SER_Counter_currency__c, SER_Exchange_rate__c, SER_Process_date__c
                                                                        FROM SER_EUR_Currency_exchange_rate__c
                                                                        WHERE SER_Base_currency__c = :CURRENCY_CODE_EUR AND SER_Counter_currency__c IN :currencies AND SER_Process_date__c > :filterDate
                                                                        ORDER BY SER_Counter_currency__c, SER_Process_date__c DESC]) {
            if (counterCurrency != currencyExchangeRate.SER_Counter_currency__c) {
                counterCurrency = currencyExchangeRate.SER_Counter_currency__c;
                hpgr.Currencies.Picklist_Wrapper currencyExchange = currencyPicklistMap.get(counterCurrency);
                currencyExchange.exchangeRate = currencyExchangeRate.SER_Exchange_rate__c;
                currencyPicklistUpdated.add(currencyExchange);
            }
        }
        // Add exchange rate to label
        for (hpgr.Currencies.Picklist_Wrapper picklistValue : currencyPicklistUpdated) {
            if (picklistValue.value != CURRENCY_CODE_EUR) {
                String exchangeRateFormatted = picklistValue.exchangeRate.setScale(6).format();
                picklistValue.label = picklistValue.label + ' (1 ' + CURRENCY_CODE_EUR + ' = ' + exchangeRateFormatted + '  ' + picklistValue.label + ')';
            }
        }
        return currencyPicklistUpdated;
    }
}