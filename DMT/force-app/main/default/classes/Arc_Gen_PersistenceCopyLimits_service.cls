/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistenceLimits_service
* @Author   Juan Ignacio Hita Manso
* @Date     Created: 2020-10-28
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages copy limits and notify result persistence services
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-10-28 Juan Ignacio Hita Manso
*             Class creation.
* |2021-01-12 Juan Ignacio Hita Manso
*             Changed callCopyLimitsService method, fix mapping request
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_PersistenceCopyLimits_service {
    /**
        * @Description: Name of service for copy all the limits
    */
    static final string SERV_COPYLIMITS = 'copyLimits';
    /*------------------------------------------------------------------------------------------------------
    * @Description Builder Arc_Gen_PersistenceCopyLimits_service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Juan Ignacio Hita Manso
    * @Date     2020-10-28
    * @param    null
    * @return   Arc_Gen_PersistenceCopyLimits_service
    * @example  new Arc_Gen_PersistenceCopyLimits_service()
    * */
    @TestVisible
    private Arc_Gen_PersistenceCopyLimits_service() {}
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that call to copy limits service
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-28
    * @param   Map<String, Object> data
    * @return  Boolean
    * @example Boolean retValue = callCopyLimitsService(accHasId, limitExpId);
    **/
    public static Boolean callCopyLimitsService(Map<String, Object> data) {
        Boolean calloutOK = false;
        try {
            final String idUserSelected = (String) data.get('idUserSelected');
            final String analysisId = (String) data.get('analysisId');
            // Get fields for persistence of the data
            final List<arce__Account_has_Analysis__c> lstAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(analysisId);
            final arce.Arc_Gen_User_Wrapper wrapUser = arce.Arc_Gen_User_Locator.getUserInfo(idUserSelected);
            final Map<String, Object> jsonIn = Arc_Gen_PersistenceCopyLimits_helper.copyLimitsJson(lstAha, wrapUser, data);
            if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(jsonIn)) {
                final String jsonInput = '{"JSONIN" : ' + JSON.serialize(JSON.serialize(jsonIn)) +'}';
                calloutOK = Arc_Gen_Persistence_Utils.executePersistence(SERV_COPYLIMITS, jsonInput);
            }
        } catch (Arc_Gen_Persistence_Utils.PersistenceException e) {
            calloutOK = false;
        }
        return calloutOK;
    }
}