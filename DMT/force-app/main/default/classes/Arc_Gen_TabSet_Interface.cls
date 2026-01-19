/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_TabSet_Interface
* @Author   adrian.caro.nex@bbva.com
* @Date     Created: 26/06/2023
* -----------------------------------------------------------------------------------------------
* @Description Interface to be implemented by the logic used to obtain local logic
* -----------------------------------------------------------------------------------------------
* @Changes
* |2023-06-26 adrian.caro.next@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public interface Arc_Gen_TabSet_Interface {
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Method that determines if it has permissions with local logic
    *---------------------------------------------------------------------------------------------------
    * @Author adrian.caro.next@bbva.com
    * @Date 26-06-2023
    * @param recordId - id of account has analysis
    * @return Boolean contains the operation result
    * @example Id recordId
    * --------------------------------------------------------------------------------------------------
    **/
    Boolean hasPermissions(Id recordId);
}