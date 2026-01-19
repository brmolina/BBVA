/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ToAssign_controller
* @Author   Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
* @Date     Created: 2019-05-04
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class used for the button to Assign in the stage of Sanction.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-04 angel.fuertes2@bbva.com
*             Class creation.
* |2020-07-13 joseluis.garcia4.contractor@bbva.com
*             Check for edit permissions.
* |2020-08-18 joseluis.garcia4.contractor@bbva.com
*             Change reference from Arc_Gen_StatusButtons to arce.Arc_Gen_GenericUtilities.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_ToAssign_controller {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty priavate constructor
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 2019-09-25
    * @example private Arc_Gen_ToAssign_controller ()
    **/
    @TestVisible
    private Arc_Gen_ToAssign_controller () {
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method to find users
    * ---------------------------------------------------------------------------------------------------
    * @Author   Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
    * @Date     Created: 2019-05-04
    * @param inputTerm - String to find users
    * @return a list of map with the users
    * @example searchUser(inputTerm)
    * ---------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static List<map<String,String>> searchUser(String inputTerm) {
        return Arc_Gen_ToAssign_service.searchUser(inputTerm);
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method to assign the arce
    * ---------------------------------------------------------------------------------------------------
    * @Author   Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
    * @Date     Created: 2019-05-04
    * @param userId - id of the user selected
    * @param recordId - id of the arce
    * @return a string
    * @example toAssign(userId, recordId)
    * ---------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String toAssign(Id userId, Id recordId) {
        if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(recordId, 'Arc_Gen_BtnToAssign')) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }

        return Arc_Gen_ToAssign_service.toAssign(userId,recordId);
    }
}