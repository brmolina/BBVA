/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_CurrencyExchange_Params
* @Author   joseluis.garcia4.contractor@bbva.com
* @Date     Created: 30/07/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Wrapper class used to store parameters to the currency exchange logic.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-07-30 joseluis.garcia4.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_CurrencyExchange_Params {
    /*
    * @Description: Currency (ISO-4217 code) used as the base for the currency exchange rates.
    */
    public String baseCurrency { get; set; }
    /*
    * @Description: List of currencies (ISO-4217 codes) used as targets for the currency exchange rates to obtain.
    */
    public List<String> targetCurrencies { get; set; }
    /*
    * @Description: Origin of the conversion (responsible for facilitating the ratios). Leave null if does not apply.
    */
    public String exchangeRateOrigin { get; set; }
    /*
    * @Description: The date of the exchange rate. null should be interpreted as "latest"
    */
    public Date exchangeRateDate { get; set; }

    /*
    * @Description: Utility property to use when there is only one desired target currency.
    */
    public String targetCurrency {
        get {
            return targetCurrencies[0];
        }

        set {
            this.targetCurrencies = new List<String> { value };
        }
    }
}