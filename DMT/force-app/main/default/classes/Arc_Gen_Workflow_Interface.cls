/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Delegation_Interface
* @Author   Juan Ignacio Hita Manso juanignacio.hita.contractor@bbva.com
* @Date     Created: 2019-01-07
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Interfaz for Arc_Gen_Delegation_Interface
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-01-07 juanignacio.hita.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public interface Arc_Gen_Workflow_Interface {
    /**
    *-----------------------------------------------------------------------------------------------------------
    * @description : Retrieve wrapper delegation from an action, account has analysis and ambit
    ------------------------------------------------------------------------------------------------------------
    * @author      : juanignacio.hita.contractor@bbva.com
    * @date        : 07/01/2020
    * @param String: ambit
    * @param Id    : analysis record id
    * @param String: action of the workflow
    * @return Arc_Gen_Delegation_Wrapper
    */
    Arc_Gen_Delegation_Wrapper getDelegation(String ambit, Id analysisId, String action, Boolean validate);
    /**
    *-----------------------------------------------------------------------------------------------------------
    * @description : Retrieves identification user from ambit
    ------------------------------------------------------------------------------------------------------------
    * @author      : juanignacio.hita.contractor@bbva.com
    * @date        : 07/01/2020
    * @param String: ambit
    * @param Id    : account has analysis record Id
    * @return String
    */
    String getIdentification(String ambit, Id analysisId);
}