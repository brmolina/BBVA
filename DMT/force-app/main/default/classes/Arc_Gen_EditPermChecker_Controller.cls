/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_EditPermChecker_Controller
* @Author   BBVA
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_EditPermChecker_serviceCmp.
* ------------------------------------------------------------------------------------------------
* @Changes
* |2020-03-10 joseluis.garcia4.contractor@bbva.com
*             Class creation
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_EditPermChecker_Controller {
    /** Make class not constructible. */
    private Arc_Gen_EditPermChecker_Controller() { }  //NOPMD

    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that returns whether or not the current user is allowed to
    * modify an ARCE analysis.
    * --------------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2020-03-10
    * @param recordId - Id of the account_has_analysis.
    * @return true if the current user can modify the analysis, false otherwise
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Boolean getUserHasPermissionToEdit(String recordId) {
        return Arc_Gen_TabSet_service.getPermissionToEdit(recordId) == 'true';
    }
}