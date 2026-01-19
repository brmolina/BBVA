/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_ExchangeRates apex class - DEPRECATED
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-11-09
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class HPG_ExchangeRates_Test {
	@isTest
	static void wrapperTest() {
		Test.startTest();
            HPG_ExchangeRates.Wrapper exchangeRates = new HPG_ExchangeRates.Wrapper();
			exchangeRates.data = new List<HPG_ExchangeRates.CurrencyData>();
			exchangeRates.exchangeCurrency = new HPG_ExchangeRates.ExchangeCurrency();
			exchangeRates.exchangeCurrency.currencyId = 'MXN';
			exchangeRates.exchangeCurrency.currencyName = 'MXN';
			exchangeRates.exchangeCurrency.ratioDescription = 'Month end exchange rate';
			exchangeRates.exchangeCurrency.ratioId = 'MONTH_END_EXCHANGE_RATE';
			exchangeRates.exchangeCurrency.ratioValue = 19.155100000098;
			exchangeRates.success = true;
			exchangeRates.errorMessage = 'Error Message';
			HPG_ExchangeRates.CurrencyData currencyData = new HPG_ExchangeRates.CurrencyData();
			currencyData.baseCurrency = new HPG_ExchangeRates.BaseCurrencyData();
			currencyData.baseCurrency.id = 'EUR';
			currencyData.baseCurrency.name = 'EUR';
			currencyData.exchangeRateDate = '2023-10-01';
			currencyData.exchangeRateOrigin = 'IRISK';
			currencyData.targetCurrencies = new List<HPG_ExchangeRates.TrgtCurrncs>();
			HPG_ExchangeRates.TrgtCurrncs trgtCurrnc = new HPG_ExchangeRates.TrgtCurrncs();
			trgtCurrnc.id = 'MXN';
			trgtCurrnc.name = 'MXN';
			trgtCurrnc.ratios = new List<HPG_ExchangeRates.RatiosData>();
			HPG_ExchangeRates.RatiosData ratioData = new HPG_ExchangeRates.RatiosData();
			ratioData.description = 'Month end exchange rate';
			ratioData.id = 'MONTH_END_EXCHANGE_RATE';
			ratioData.value = 19.155100000098;
			trgtCurrnc.ratios.add(ratioData);
			currencyData.targetCurrencies.add(trgtCurrnc);
            System.assertEquals(true, exchangeRates.success, 'wrapperTest - Not passed - success');
		Test.stopTest();
	}
}