/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FinStatDetails_Service_Helper
* @Author   mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 19/12/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Helper class for Arc_Gen_FinStatDetails_Service
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-12-19 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-01-29 juanmanuel.perez.ortiz.contractor@bbva.com
*             Modified getNumberOfEmployees() method, add Account Has Analysis Wrapper
* |2020-05-26 joseluis.garcia4.contractor@bbva.com
*             Distinct web services for client and group.
* |2020-06-08 joseluis.garcia4.contractor@bbva.com
*             Fix bug with different format in financialStatementDetailsGroup service.
* |2021-01-21 saimassimilianno.jordana.contractor@bbva.com
*             Modified all getAccountInfoById calls to return the correct accountWrapper if customAccount exists.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2022-03-14 francisco.munoz.torres.contractor@bbva.com
*             Get audit data from FFSS detail service
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_FinStatDetails_Service_Helper {
    /**
    * @Description: String with the name of the service financial statement details (for clients)
    */
    static final string FINAN_STAT_DETAILS_CLIENT = 'financialStatementDetails';
    /**
    * @Description: String with the name of the service financial statement details (for clients)
    */
    static final string FINAN_STAT_DETAILS_GROUP = 'financialStatementDetailsGroup';
    /*
    * @Description Group participant type.
    */
    private static final String PART_TYPE_GROUP = 'GROUP';
    /**
    * @Description: String with the name of the dummy financial statement
    */
    static final string DUMMY_FFSS = 'dummyFFSS';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-12-19
    * @param void
    * @return void
    * @example Arc_Gen_FinStatDetails_Service_Helper helper = new Arc_Gen_FinStatDetails_Service_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_FinStatDetails_Service_Helper() {

    }
    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method that consult the financial statement details service
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-12-19
    * @param    ahaId - Id of the account_has_analysis
    * @param    fsServiceId - Id of the financial statement
    * @return   Arc_Gen_ModalFinanStatemController.FinancialDetailsWrapper - Wrapper with the FFSS details
    * @example  getFFSSDetail(ahaId, ahaId) {
    * ----------------------------------------------------------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_ModalFinanStatemController.FinancialDetailsWrapper getFFSSDetail(String ahaId,String fsServiceId) {
        final Arc_Gen_ModalFinanStatemController.FinancialDetailsWrapper responseWrapper = new Arc_Gen_ModalFinanStatemController.FinancialDetailsWrapper();
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        if (fsServiceId == DUMMY_FFSS || fsServiceId == null) {
            responseWrapper.employeesNumber = null;
            responseWrapper.audit = new Arc_Gen_ModalFinanStatemController.Audit();
            responseWrapper.gblSuccessOperation = true;
        } else {
            final String accountNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient((String)arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysisAndCustomer(new List<String>{ahaId})[0].accWrapperObj.accNumber);
            final String params = '{"accountNumber":"' + accountNumber + '","fsServiceId":"' + fsServiceId + '"}';
            final String serviceName = getServiceName(ahaId);
            final HttpResponse response = arce.Arc_Gen_getIASOResponse.getServiceResponse(serviceName, params);
            if (response.getStatusCode() == serviceMessage.CODE_200) {
                final Map<String, Object> mapResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

                // Format of data object may be either a list or an object, depending on
                // the service that is called (group or business). Cast data to the correct type.
                final Object dataObj = mapResponse.get('data');
                Map<String, Object> dataMap;
                if (dataObj instanceof List<Object>) {
                    dataMap = (Map<String, Object>) ((List<Object>) dataObj).get(0);
                } else {
                    dataMap = (Map<String, Object>) dataObj;
                }

                responseWrapper.employeesNumber = (Integer)dataMap.get('employeesNumber');
                responseWrapper.audit = new Arc_Gen_ModalFinanStatemController.Audit(dataMap.get('audit'));
                responseWrapper.gblRespServiceCode = serviceMessage.CODE_200;
                responseWrapper.gblSuccessOperation = true;
            } else {
                responseWrapper.gblRespServiceCode = response.getStatusCode();
                responseWrapper.gblSuccessOperation = false;
                responseWrapper.gblResulError = System.Label.Cls_arce_GRP_servError;
            }
        }
        return responseWrapper;
    }
    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description Returns the name of the financialStatementDetails service to apply given the participant
    * type of the account bound to the AHA record.
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-05-26
    * @param    ahaId - Id of the account_has_analysis
    * @return   String - Name of the service to use
    * ----------------------------------------------------------------------------------------------------------------------------------------
    **/
    private static String getServiceName(String ahaId) {
        // Get participant type.
        final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> { ahaId })[0];
        final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(aha);
        final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> {clientId}).get(clientId);
        final String participantType = accWrapper.participantType;

        // Check if service is available for groups.
        if (participantType == PART_TYPE_GROUP) {
            final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('GroupFFSSServicesAvailable');

            if (configs.isEmpty() || String.isEmpty(configs[0].arce__Value1__c) || !Boolean.valueOf(configs[0].arce__Value1__c)) {
                throw new Arc_Gen_Balance_Tables_service.NoFinancialStatementDataException(Arc_Gen_Balance_Tables_service.NoFinancialStatementReason.NO_FFSS_NO_SERVICE);
            }
        }

        // Get service name to use depending on participant type.
        return participantType == PART_TYPE_GROUP ? FINAN_STAT_DETAILS_GROUP : FINAN_STAT_DETAILS_CLIENT;
    }
}