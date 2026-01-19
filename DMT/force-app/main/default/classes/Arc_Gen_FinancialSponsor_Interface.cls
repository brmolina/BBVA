/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FinancialSponsor_Interface
* @Author   ARCE
* @Date     Created: 22/06/2020
* -----------------------------------------------------------------------------------------------
* @Description Interface to be implemented by the logic used to obtain Financial Sponsor status
* for an economic group.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-06-22 joseluis.garcia4.contractor@bbva.com
*             Interface creation.
* -----------------------------------------------------------------------------------------------
*/
public interface Arc_Gen_FinancialSponsor_Interface {
    /**
    * @Description: Method that checks if a financial sponsor exists for a given economic group.
    * @param economicGroupNumber - Account number of the group
    * @return whether a financial sponsor exists for the group.
    */
    Boolean getFinancialSponsorStatus(String economicGroupNumber);
}