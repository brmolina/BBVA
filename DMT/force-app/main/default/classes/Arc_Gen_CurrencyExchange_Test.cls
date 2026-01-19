/**
* @File Name          : Arc_Gen_CurrencyExchange_Test.cls
* @Description        : Test class for currency exchange logic
* @Author             : joseluis.garcia4.contractor@bbva.com
* @Group              : ARCE
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    2020-07-31   joseluis.garcia4.contractor@bbva.com    Initial Version
**/
@IsTest
public class Arc_Gen_CurrencyExchange_Test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method. Test call to currency exchange logic.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * --------------------------------------------------------------------------------------
    **/
    @IsTest public static void testCurrencyExchangeLogic() {
        final Arc_Gen_CurrencyExchange_Interface impl = Arc_Gen_GenericUtilitiesInterface.getCurrencyExchangeClass();
        final Arc_Gen_CurrencyExchange_Params parameters = new Arc_Gen_CurrencyExchange_Params();
        parameters.baseCurrency = 'MXN';
        parameters.targetCurrency = 'EUR';
        parameters.exchangeRateOrigin = 'IRISK';
        parameters.exchangeRateDate = System.today();

        final Arc_Gen_CurrencyExchange_Wrapper result = impl.getCurrencyExchangeInfo(parameters);
        System.assert(result.getCurrencyExchangeRate('EUR') != null, 'Exchange rate should not be null');
    }
}