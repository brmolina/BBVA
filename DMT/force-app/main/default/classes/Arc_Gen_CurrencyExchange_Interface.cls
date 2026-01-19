/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_CurrencyExchange_Interface
* @Author   joseluis.garcia4.contractor@bbva.com
* @Date     Created: 30/07/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Interface "Arc_Gen_CurrencyExchange_Interface"
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-07-30 joseluis.garcia4.contractor@bbva.com
*             Interface creation.
* -----------------------------------------------------------------------------------------------
*/
public interface Arc_Gen_CurrencyExchange_Interface {
    /*
    * @Description: Gets currency exchange information.
    */
    Arc_Gen_CurrencyExchange_Wrapper getCurrencyExchangeInfo(Arc_Gen_CurrencyExchange_Params params);
}