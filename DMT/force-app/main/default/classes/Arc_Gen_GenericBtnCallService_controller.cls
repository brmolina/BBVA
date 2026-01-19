/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_GenericBtnCallService_controller
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 18/12/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Controller class for GenericBtnCallService aura component
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |18/12/2020 juanignacio.hita.contractor@bbva.com
*             Class creation
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_GenericBtnCallService_controller {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    30/4/2019
    * @param   void
    * @return  void
    * @example Arc_Gen_GenericBtnCallService_controller data = new Arc_Gen_GenericBtnCallService_controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_GenericBtnCallService_controller() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the account has analysis wrapper
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    30/4/2019
    * @param   String accHasId
    * @return  Arc_Gen_Account_Has_Analysis_Wrapper - A wrapper with the accounts and analysis dataa
    * @example Arc_Gen_Account_Has_Analysis_Wrapper accWrapper = getInfoAnalysis(accHasId);
    **/
    @AuraEnabled
    public static arce.Arc_Gen_Account_Has_Analysis_Wrapper getInfoAnalysis(String accHasId) {
        arce.Arc_Gen_Account_Has_Analysis_Wrapper accHasWrapper = new arce.Arc_Gen_Account_Has_Analysis_Wrapper();
        try {
            final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> lstAccHas = arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysisAndCustomer(new List<String>{accHasId});
            accHasWrapper = lstAccHas[0];
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
        return accHasWrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the client data
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    18/12/2020
    * @param   String confName - Arce config record local service implementation
    * @param   Map<String, Object> mapObj - Map with the parametersd data
    * @return  ClientData - A wrapper with the data of the client
    * @example Arc_Gen_ServiceAndSaveResponse res = executeService(confName, mapObj);
    **/
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse executeService(String confName, Map<String, Object> mapObj) {
        arce.Arc_Gen_ServiceAndSaveResponse service = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            final arce.Arc_Gen_IASO_Utils_Interface serviceLocalCLass = Arc_Gen_GenericUtilitiesInterface.getLocalServiceIASO(confName);
            final String reqJSON = serviceLocalCLass.setServiceParams(mapObj);
            final arce.Arc_Gen_getIASOResponse.ServiceResponse resService = serviceLocalCLass.callService(reqJSON);
            service = serviceLocalCLass.setupService(resService, mapObj);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
        return service;
    }
}