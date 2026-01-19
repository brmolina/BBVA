/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_CurrencyExchange_Wrapper
* @Author   joseluis.garcia4.contractor@bbva.com
* @Date     Created: 30/07/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Wrapper class used for the results of the currency exchange logic.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-07-30 joseluis.garcia4.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_CurrencyExchange_Wrapper {
    /*
    * @Description: The base currency (ISO-4217 code).
    */
    public String baseCurrency { get; set; }
    /*
    * @Description: Exchange rates by currency ISO-4217 code.
    */
    public Map<String, Double> exchangeRates { get; set; }
    /*
    * @Description: The date of the exchange rate.
    */
    public Date exchangeRateDate { get; set; }

    /*
    *--------------------------------------------------------------------------------
    * @Description: Constructor
    *--------------------------------------------------------------------------------
    */
    public Arc_Gen_CurrencyExchange_Wrapper() {
        this.exchangeRates = new Map<String, Double>();
    }
    /**
    *--------------------------------------------------------------------------------
    * @description Gets exchange rate for a currency.
    *--------------------------------------------------------------------------------
    * @author  joseluis.garcia4.contractor@bbva.com
    * @date    30/07/2020
    * @param currencyCode - The ISO-4217 currency code.
    * @return the exchange rate
    **/
    public Double getCurrencyExchangeRate(String currencyCode) {
        return this.exchangeRates.get(currencyCode);
    }
    /**
    *--------------------------------------------------------------------------------
    * @description Set exchange rate for a currency.
    *--------------------------------------------------------------------------------
    * @author  joseluis.garcia4.contractor@bbva.com
    * @date    30/07/2020
    * @param currencyCode - The ISO-4217 currency code.
    * @param exchangeRate - Exchange rate
    **/
    public void setCurrencyExchangeRate(String currencyCode, Double exchangeRate) {
        this.exchangeRates.put(currencyCode, exchangeRate);
    }
}