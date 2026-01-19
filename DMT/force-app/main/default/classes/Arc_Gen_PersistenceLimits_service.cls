/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistenceLimits_service
* @Author   Juan Ignacio Hita Manso
* @Date     Created: 2020-30-09
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages call limits and exposure persistence services
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-10-01 Juan Ignacio Hita Manso
*             Class creation.
* |2020-10-25 Juan Ignacio Hita Manso
*             Add callLimitsPersService method
* |2020-10-25 Juan Ignacio Hita Manso
*             Add call method for update the status limit persistence service
* |2020-05-14 Juan Ignacio Hita Manso
*             Refactoring class
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_PersistenceLimits_service {
    /**
        * @Description: Name of the limits persistence service for add a row
    */
    static final string SERV_ADD_LIMIT = 'limitsAddPersist';
    /**
        * @Description: Name of the limits persistence service for remove a row
    */
    static final string SERV_DEL_LIMIT = 'limitsDelPersist';
    /**
        * @Description: Name of the limits persistence service for remove a row
    */
    static final string SERV_LIMITS = 'limitsPersist';
    /**
        * @Description: Codes accepted by persistence services
    */
    static final List<String> CODES_ACCEPT = new List<String> {'200', '201', '202', '204'};

    /*------------------------------------------------------------------------------------------------------
    * @Description Builder Arc_Gen_PersistenceLimits_service
    * -----------------------------------------------------------------------------------------------------
    * @Author   Juan Ignacio Hita Manso
    * @Date     2020-09-30
    * @param    null
    * @return   Arc_Gen_PersistenceLimits_service
    * @example  new Arc_Gen_PersistenceLimits_service()
    * */
    @TestVisible
    private Arc_Gen_PersistenceLimits_service() {}
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that gets the data and calls the limit persistence service
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-01
    * @param   Id accHasId
    * @param   Id limitExpId
    * @return  Boolean
    * @example Boolean retValue = callAddLimitService(accHasId, limitExpId);
    **/
    public static Boolean callAddLimitService(Id accHasId, Id limitExpId) {
        Boolean calloutOK = false;
        // Get fields for persistence of the data
        final Map<Id, arce__limits_exposures__c> mapLimit = arce.Arc_Gen_LimitsExposures_Data.getMapExposureDataAha(accHasId, new List<Id>{limitExpId});
        final arce__limits_exposures__c limitExpo = mapLimit.get(limitExpId);
        final Map<String, Object> jsonIn = Arc_Gen_PersistenceLimits_helper.createDataLimit(limitExpo, null);

        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(jsonIn)) {
            final List<arce__Account_has_Analysis__c> accHasAnLts = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasId});
            final Map<Id, arce.Arc_Gen_Account_Wrapper> accWrapMap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accHasAnLts[0].arce__Customer__c});
            final String participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient((String)accWrapMap.get(accHasAnLts[0].arce__Customer__c).accNumber);
            final String jsonInput = '{"risk-assessment-id" : "' + accHasAnLts[0].Name +
                '","participant-id" : "' + participantId + '","limit-id" : "' + limitExpId +
                '", "JSONIN" : ' + JSON.serialize(JSON.serialize(jsonIn)) +'}';
            final arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERV_ADD_LIMIT,jsonInput);
            if (CODES_ACCEPT.contains(iasoResponse.serviceCode)) {
                calloutOK = true;
            } else {
                Arc_Gen_Validate_Customer_Data.updateStatusLimitPers(acchasId, calloutOK);
            }
        }
        return calloutOK;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that calls the persistence service to remove a limit
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-06
    * @param   Id accHasId
    * @param   Id limitExpId
    * @return  Boolean
    * @example Boolean retValue = callDeleteLimitService(accHasId, limitExpId);
    **/
    public static Boolean callDeleteLimitService(Id accHasId, Id limitExpId) {
        Boolean calloutOK = false;
        final List<arce__Account_has_Analysis__c> accHasAnLts = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasId});
        final Map<Id, arce.Arc_Gen_Account_Wrapper> accWrapMap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accHasAnLts[0].arce__Customer__c});
        final String participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient((String)accWrapMap.get(accHasAnLts[0].arce__Customer__c).accNumber);

        final String jsonInput = '{"risk-assessment-id" : "' + accHasAnLts[0].Name +
            '","participant-id" : "' + participantId +
            '","limit-id" : "' + limitExpId + '"}';
        final arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERV_DEL_LIMIT, jsonInput);
        if (CODES_ACCEPT.contains(iasoResponse.serviceCode)) {
            calloutOK = true;
        }
        return calloutOK;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that calls the limits persistence service
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-10-26
    * @param   Id accHasId
    * @param   arce__Account_has_Analysis__c newAha
    * @param   List<arce__limits_exposures__c> lstLimitExp
    * @return  Boolean
    * @example Boolean retValue = callLimitsPersService(accHasId, newAha, lstLimitExp);
    **/
    public static Boolean callLimitsPersService(Id accHasId, arce__Account_has_Analysis__c newAha, List<arce__limits_exposures__c> lstLimitExp) {
        Boolean calloutOK = false;
        final List<arce__limits_exposures__c> lstLimits = lstLimitExp;
        if (lstLimits == null) {
            // Get fields for persistence of the data
            final Map<Id, arce__limits_exposures__c> mapLimit = arce.Arc_Gen_LimitsExposures_Data.getMapExposureDataAha(accHasId, new List<Id>());
            lstLimits = mapLimit.values();
        }
        final Map<String, Object> jsonIn = Arc_Gen_PersistenceLimits_helper.limitsJSON(lstLimits, newAha);

        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(jsonIn)) {
            final List<arce__Account_has_Analysis__c> accHasAnLts = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasId});
            final Map<Id, arce.Arc_Gen_Account_Wrapper> accWrapMap = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{accHasAnLts[0].arce__Customer__c});
            final String participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient((String)accWrapMap.get(accHasAnLts[0].arce__Customer__c).accNumber);
            final String jsonInput = '{"risk-assessment-id" : "' + accHasAnLts[0].Name +
                '","participant-id" : "' + participantId +
                '", "JSONIN" : ' + JSON.serialize(JSON.serialize(jsonIn)) +'}';
            final arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERV_LIMITS, jsonInput);
            if (CODES_ACCEPT.contains(iasoResponse.serviceCode)) {
                calloutOK = true;
            }
            Arc_Gen_Validate_Customer_Data.updateStatusLimitPers(acchasId, calloutOK);
        }
        return calloutOK;
    }

}