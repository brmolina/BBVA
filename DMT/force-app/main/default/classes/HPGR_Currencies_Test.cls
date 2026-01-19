/*-------------------------------------------------------------------------------------------
* @Name     HPGR_Currencies_Test
* @Author   torcuato.tejada.tech@bbva.com
*           cosme.alcazar.tech@bbva.com
* @Date     Created: 2024-07-18
* -------------------------------------------------------------------------------------------
* @Description Test class for 'HPGR_Currencies' apex class
* -------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class HPGR_Currencies_Test {

    static final String CURRENCY_CODE_EUR = 'EUR';
    static final String CURRENCY_CODE_USD = 'USD';

    @IsTest
    static void getCurrenciesTestEUR() {
        SER_EUR_Currency_exchange_rate__c currencyExchangeRate = new SER_EUR_Currency_exchange_rate__c();
        currencyExchangeRate.SER_Counter_currency__c = CURRENCY_CODE_USD;
        currencyExchangeRate.SER_Exchange_rate__c = 1.12;
        currencyExchangeRate.SER_Process_date__c = Date.today();
        insert currencyExchangeRate;
        Test.startTest();
            hpgr.Currencies.Wrapper currencies = HPGR_Currencies.getCurrencies(CURRENCY_CODE_EUR);
            System.assertEquals(2, currencies.exchangeRates.size(), 'getCurrenciesTestEUR - Not passed - exchangeRates.size()');
            System.assertEquals(CURRENCY_CODE_EUR, currencies.baseCurrency, 'getCurrenciesTestEUR - Not passed - baseCurrency');
        Test.stopTest();
    }

    @IsTest
    static void getCurrenciesTestUSD() {
        SER_EUR_Currency_exchange_rate__c currencyExchangeRate = new SER_EUR_Currency_exchange_rate__c();
        currencyExchangeRate.SER_Counter_currency__c = CURRENCY_CODE_USD;
        currencyExchangeRate.SER_Exchange_rate__c = 1.12;
        currencyExchangeRate.SER_Process_date__c = Date.today();
        insert currencyExchangeRate;
        Test.startTest();
            hpgr.Currencies.Wrapper currencies = HPGR_Currencies.getCurrencies(CURRENCY_CODE_USD);
            System.assertEquals(2, currencies.exchangeRates.size(), 'getCurrenciesTestUSD - Not passed - exchangeRates.size()');
            System.assertEquals(CURRENCY_CODE_USD, currencies.baseCurrency, 'getCurrenciesTestUSD - Not passed - baseCurrency');
        Test.stopTest();
    }

    @IsTest
    static void getCurrencyPicklistTest() {
        SER_EUR_Currency_exchange_rate__c currencyExchangeRate = new SER_EUR_Currency_exchange_rate__c();
        currencyExchangeRate.SER_Counter_currency__c = CURRENCY_CODE_USD;
        currencyExchangeRate.SER_Exchange_rate__c = 1.12;
        currencyExchangeRate.SER_Process_date__c = Date.today();
        insert currencyExchangeRate;
        Test.startTest();
            List<hpgr.Currencies.Picklist_Wrapper> currencyPicklist = HPGR_Currencies.getCurrencyPicklist(CURRENCY_CODE_EUR);
            System.assertEquals(2, currencyPicklist.size(), 'getCurrencyPicklistTest - Not passed - currencyPicklist.size()');
            System.assertEquals(CURRENCY_CODE_EUR, currencyPicklist[0].value, 'getCurrencyPicklistTest - Not passed - currency EUR');
            System.assertEquals(true, currencyPicklist[0].selected, 'getCurrencyPicklistTest - Not passed - selected EUR');
            System.assertEquals(1, currencyPicklist[0].exchangeRate, 'getCurrencyPicklistTest - Not passed - exchangeRate EUR');
            System.assertEquals(CURRENCY_CODE_USD, currencyPicklist[1].value, 'getCurrencyPicklistTest - Not passed - currency USD');
            System.assertEquals(false, currencyPicklist[1].selected, 'getCurrencyPicklistTest - Not passed - currency USD');
            System.assertEquals(1.12, currencyPicklist[1].exchangeRate, 'getCurrencyPicklistTest - Not passed - exchangeRate USD');
        Test.stopTest();
    }
}