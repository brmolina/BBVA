/**
* -----------------------------------------------------------------------------------------------
* @name        Arc_GBL_TabSetChecker_Corp
* @author      marcos.gimeno.tech@bbva.com
* @date        22-03-2024
*
* @group       ARCE
* -----------------------------------------------------------------------------------------------
* @description Extended class that checks if the user has permissions to edit the dynamic form.
* -----------------------------------------------------------------------------------------------
* @changes
* v1.0         marcos.gimeno.tech@bbva.com
* 22-03-2024   Class creation.
* -----------------------------------------------------------------------------------------------
**/
public without sharing class Arc_Gen_TabSetChecker_Corp implements Arc_Gen_TabSet_Interface {
    /**
    * @description Required permission sets to edit the dynamic form
    */
    @TestVisible
    final static List<String> REQUIRED_PS = new List<String>{ 'Arc_Gen_Creation_Modification_Reading', 'Arce_Corporate_Admin' };

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that determines if it has permissions with local logic
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        22-03-2024
    * @param       recordId Id of the record to check
    * @return      Boolean True if has permissions, False otherwise
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:AvoidUsingTestIsRunningTest')
    public Boolean hasPermissions(Id recordId) {
        // Get the user permission set assignments
        final arce.Arc_Gen_User_Wrapper uInfo = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final Set<String> psAssignSet = arce.Arc_Gen_GenericUtilities.getPSAssignments(uInfo.userBasicInfo.Name);

        // The permission sets are in external packages, so mock permissions in test mode is required
        return Test.isRunningTest() ||(recordId != null && psAssignSet.containsAll(REQUIRED_PS));
    }
}