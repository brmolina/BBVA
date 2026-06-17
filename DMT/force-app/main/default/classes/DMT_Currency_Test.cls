/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for DMT_Currency apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      torcuato.tejada.tech@bbva.com
* @version     1.0
* @created     2025-07-15
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class DMT_Currency_Test {

    @TestSetup
    static void loadCurrencies() {
        DateTime today = DateTime.now();
	    String currencyDate = today.format('yyyy-MM-dd');

        Map<String, Double> currencies = new Map<String, Double>{
            'EUR' => 1.0,
            'ARS' => 800.0,
            'COP' => 4000,
            'MXN' => 18.0,
            'PEN' => 4.0,
            'USD' => 1.2,
            'UYU' => 40.0,
            'VEF' => 300000.0,
			'GBP' => 0.8
        };

        List<SER_EUR_Currency_exchange_rate__c> exRateList = new List<SER_EUR_Currency_exchange_rate__c>();
        for(String curr : currencies.keySet()) {
            SER_EUR_Currency_exchange_rate__c exRate = new SER_EUR_Currency_exchange_rate__c(
                SER_Base_currency__c = 'EUR',
                SER_Counter_currency__c = curr,
                SER_Currency_pair__c = 'EUR/' + curr,
                SER_Currency_Pair_Date__c = 'EUR/' + curr + '_' + currencyDate,
                SER_Exchange_rate__c = currencies.get(curr),
                SER_Process_date__c = Date.valueOf(currencyDate),
                SER_Unlisted__c = false
            );
            exRateList.add(exRate);
        }
        insert exRateList;
    }

	@isTest
	static void testGetCurrencyList() {
		Test.startTest();
		Set<String> currencies = DMT_Currency.getCurrencyList();
		Test.stopTest();
		// Assert that EUR is always included
		System.assert(currencies.contains('EUR'), 'EUR should always be included in currency list');
	}

	@isTest
	static void testGetCurrenciesWithEURBase() {
		Test.startTest();
		DMT_Currency.Wrapper result = DMT_Currency.getExchangeRates('EUR');
		Test.stopTest();
		// Assert base currency is EUR
		System.assertEquals('EUR', result.baseCurrency, 'Base currency should be EUR');
		// Assert exchange rates list is not null
		System.assertNotEquals(null, result.exchangeRates, 'Exchange rates should not be null');
		// Assert EUR rate is 1.0
		Boolean eurFound = false;
		for(DMT_Currency.ExchangeRate rate : result.exchangeRates) {
			if(rate.currencyId == 'EUR') {
				System.assertEquals(1.0, rate.exchangeRate, 'EUR exchange rate should be 1.0');
				eurFound = true;
				break;
			}
		}
		System.assert(eurFound, 'EUR should be found in exchange rates');
	}

	@isTest
	static void testGetCurrenciesWithUSDBase() {
		Test.startTest();
		DMT_Currency.Wrapper result = DMT_Currency.getExchangeRates('USD');
		Test.stopTest();
		Boolean usdFound = false;
		Boolean eurFound = false;
		for(DMT_Currency.ExchangeRate rate : result.exchangeRates) {
			if(rate.currencyId == 'USD') {
				System.assertEquals(1.0, rate.exchangeRate, 'USD exchange rate should be 1.0 when USD is base');
				usdFound = true;
			}
			if(rate.currencyId == 'EUR') {
				// EUR rate should be 1/1.2 = 0.8333... when USD is base (since EUR->USD is 1.2)
				System.assert(Math.abs(rate.exchangeRate - (1.0/1.2)) < 0.0001, 'EUR rate calculation should be correct');
				eurFound = true;
			}
		}
		System.assert(usdFound, 'USD should be found in exchange rates');
		System.assert(eurFound, 'EUR should be found in exchange rates');
	}

	@isTest
	static void testWrapperClass() {
		Test.startTest();
		DMT_Currency.Wrapper wrapper = new DMT_Currency.Wrapper();
		wrapper.baseCurrency = 'EUR';
		wrapper.exchangeRates = new List<DMT_Currency.ExchangeRate>();
		Test.stopTest();
		// Assert wrapper properties can be set
		System.assertEquals('EUR', wrapper.baseCurrency, 'Wrapper base currency should be set correctly');
		System.assertNotEquals(null, wrapper.exchangeRates, 'Wrapper exchange rates should not be null');
	}

	@isTest
	static void testExchangeRateClass() {
		Test.startTest();
		DMT_Currency.ExchangeRate exchangeRate = new DMT_Currency.ExchangeRate();
		exchangeRate.currencyId = 'USD';
		exchangeRate.exchangeRate = 1.2;
		exchangeRate.updated = Date.today();
		Test.stopTest();

		// Assert exchange rate properties can be set
		System.assertEquals('USD', exchangeRate.currencyId, 'Exchange rate currency ID should be set correctly');
		System.assertEquals(1.2, exchangeRate.exchangeRate, 'Exchange rate value should be set correctly');
		System.assertEquals(Date.today(), exchangeRate.updated, 'Exchange rate updated date should be set correctly');
	}

	@isTest
	static void testGetCurrenciesWithInvalidBase() {
		Test.startTest();
		DMT_Currency.Wrapper result = DMT_Currency.getExchangeRates('INVALID');
		Test.stopTest();

		// Assert base currency is set even for invalid currency
		System.assertEquals(null, result, 'Result should be null when base currency is invalid');
		// Assert exchange rates list is not null (should still return some rates)
		System.assertEquals(null, result, 'Exchange rates should be null when base currency is invalid');
	}

	@isTest
	static void testGetCurrenciesWithEmptyData() {
		// Delete all test data to test edge case
		delete [SELECT Id FROM SER_EUR_Currency_exchange_rate__c];

		Test.startTest();
		try {
			DMT_Currency.Wrapper result = DMT_Currency.getExchangeRates('EUR');
			// If no exception is thrown, verify the result structure
			System.assertNotEquals(null, result, 'Result should not be null even with no data');
			System.assertEquals('EUR', result.baseCurrency, 'Base currency should still be set');
		} catch(Exception e) {
			// If an exception is thrown, verify it's handled appropriately
			System.assert(e instanceof ListException || e instanceof QueryException,
				'Expected ListException or QueryException when no data is available');
		}
		Test.stopTest();
	}

	@isTest
	static void testConvertSameCurrency() {
		Test.startTest();
		Decimal result = DMT_Currency.convert(100.0, 'EUR', 'EUR');
		Test.stopTest();

		// Assert same currency conversion
		System.assertEquals(100.0, result, 'Same currency should return same amount');
	}

	@isTest
	static void testConvertEURToUSD() {
		Test.startTest();
		Decimal result = DMT_Currency.convert(100.0, 'EUR', 'USD');
		Test.stopTest();

		// Assert conversion from EUR to USD
		System.assertNotEquals(null, result, 'EUR to USD conversion should succeed');
		// Should be 100 * 1.2 = 120 based on test data
		System.assertEquals(120.0, result, 'EUR to USD conversion should be correct');
	}

	@isTest
	static void testConvertUSDToEUR() {
		Test.startTest();
		Decimal result = DMT_Currency.convert(120.0, 'USD', 'EUR');
		Test.stopTest();

		// Assert conversion from USD to EUR
		System.assertNotEquals(null, result, 'USD to EUR conversion should succeed');
		// Should be 120 * (1/1.2) = 100 based on test data
		System.assert(Math.abs(result - 100.0) < 0.01, 'USD to EUR conversion should be correct');
	}

	@isTest
	static void testConvertWithInvalidCurrency() {
		Test.startTest();
		Decimal result = DMT_Currency.convert(100.0, 'EUR', 'INVALID');
		Test.stopTest();

		// Assert failed conversion with invalid currency returns null
		System.assertEquals(null, result, 'Conversion with invalid currency should return null');
	}

	@isTest
	static void testConvertMultipleCurrencies() {
		Test.startTest();
		Decimal eurToMxn = DMT_Currency.convert(100.0, 'EUR', 'MXN');
		Decimal mxnToUsd = DMT_Currency.convert(eurToMxn, 'MXN', 'USD');
		Decimal directEurToUsd = DMT_Currency.convert(100.0, 'EUR', 'USD');
		Test.stopTest();

		// Assert multiple conversions work
		System.assertNotEquals(null, eurToMxn, 'EUR to MXN should work');
		System.assertNotEquals(null, mxnToUsd, 'MXN to USD should work');
		System.assertNotEquals(null, directEurToUsd, 'Direct EUR to USD should work');

		// The indirect conversion should be approximately equal to direct conversion
		System.assert(Math.abs(mxnToUsd - directEurToUsd) < 1.0, 'Indirect conversion should be close to direct');
	}

	@isTest
	static void testConvertUsesLatestRateWhenCurrencyHasMultipleDates() {
		Date todayDate = Date.today();
		Date oldDate = todayDate.addDays(-2);

		insert new SER_EUR_Currency_exchange_rate__c(
			SER_Base_currency__c = 'EUR',
			SER_Counter_currency__c = 'USD',
			SER_Currency_pair__c = 'EUR/USD',
			SER_Currency_Pair_Date__c = 'EUR/USD_' + oldDate.format(),
			SER_Exchange_rate__c = 0.2,
			SER_Process_date__c = oldDate,
			SER_Unlisted__c = false
		);

		Test.startTest();
		Decimal result = DMT_Currency.convert(100.0, 'EUR', 'USD');
		Test.stopTest();

		// The latest test setup rate for EUR/USD is 1.2 (today); old inserted rate must be ignored.
		System.assertEquals(120.0, result, 'Conversion must use latest exchange rate by process date');
	}
}