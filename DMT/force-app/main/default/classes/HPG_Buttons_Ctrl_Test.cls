/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_Buttons_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-04-12
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class HPG_Buttons_Ctrl_Test {
    @IsTest
    static void testInitialData() {
        SER_EUR_Currency_exchange_rate__c currencyExchangeRate = new SER_EUR_Currency_exchange_rate__c();
        currencyExchangeRate.SER_Counter_currency__c = 'USD';
        currencyExchangeRate.SER_Exchange_rate__c = 1.12;
        currencyExchangeRate.SER_Process_date__c = Date.today();
        insert currencyExchangeRate;
        Test.startTest();
            Map<String, Object> retMap = HPG_Buttons_Ctrl.initialData('EUR');
            List<HPG_Buttons_Ctrl.Currency_Wrapper> currencies = (List<HPG_Buttons_Ctrl.Currency_Wrapper>)retMap.get('currencies');
            System.assertEquals(2, currencies.size(), 'testInitialData - Not passed - currencies retrieved');
            System.assertEquals('EUR', currencies[0].value, 'testInitialData - Not passed - currency EUR');
            System.assertEquals(true, currencies[0].selected, 'testInitialData - Not passed - currency EUR');
            System.assertEquals(1, currencies[0].exchangeRate, 'testInitialData - Not passed - currency EUR');
            System.assertEquals('USD', currencies[1].value, 'testInitialData - Not passed - currency USD');
            System.assertEquals(false, currencies[1].selected, 'testInitialData - Not passed - currency USD');
            System.assertEquals(1.12, currencies[1].exchangeRate, 'testInitialData - Not passed - currency USD');
        Test.stopTest();
    }
}