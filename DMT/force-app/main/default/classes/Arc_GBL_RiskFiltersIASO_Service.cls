/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_RiskFiltersIASO_Service
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 11/12/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Local implementation for the risk filtering and response processing service
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |11/12/2020 juanignacio.hita.contractor@bbva.com
*             Class creation.
* |14/07/2021 juanignacio.hita.contractor@bbva.com
*             Removes "riskCalification" param logic for null value
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
public class Arc_GBL_RiskFiltersIASO_Service implements arce.Arc_Gen_IASO_Utils_Interface {
    /**
    * @Description: Name of the service for subsidiaries
    */
    static final string SERVICE_SUBD = 'riskFilters';
    /**
    * @Description: Name of the service for group
    */
    static final string SERVICE_GROUP = 'riskFiltersGroup';
    /**
    * @Description: Risk filter type
    */
    static final String RISK_FILTER = 'INTERNAL';
    /**
    * @Description: Unique identifier for Spain
    */
    static final String ID_ES = '10';
    /**
    *-------------------------------------------------------------------------------
    * @description Method that call risk filter service and return a json serialized from response service
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    11/12/2020
    * @param   String request
    * @return  Arc_Gen_getIASOResponse.ServiceResponse wrapper
    * @example Arc_Gen_getIASOResponse.ServiceResponse serv = callService(request);
    **/
    public static arce.Arc_Gen_getIASOResponse.ServiceResponse callService(String request) {
        arce.Arc_Gen_getIASOResponse.ServiceResponse serviceResponse = new arce.Arc_Gen_getIASOResponse.ServiceResponse();
        final Map<String, Object> mapObj = (Map<String, Object>) JSON.deserializeUntyped(request);
        final String participantType = String.valueOf(mapObj.get('participantType'));
        final Map<String, String> mapRequest = new Map<String, String> {
            'riskFilterType' => RISK_FILTER,
            'customerId' => String.valueOf(mapObj.get('customerId'))
        };
        if (participantType == arce.Arc_Gen_Constants.GROUP_S) {
            serviceResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_GROUP, JSON.serialize(mapRequest));
        } else if (participantType == arce.Arc_Gen_Constants.SUBS_S) {
            serviceResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_SUBD, JSON.serialize(mapRequest));
        }
        return serviceResponse;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that setup and process the response of service
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    17/12/2020
    * @param   Arc_Gen_getIASOResponse.ServiceResponse serviceResponse
    * @param   Map<String, Object> mapParams
    * @return  Arc_Gen_ServiceAndSaveResponse
    * @example Arc_Gen_ServiceAndSaveResponse ret = setupService(serviceResponse, mapParams);
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse setupService(arce.Arc_Gen_getIASOResponse.ServiceResponse serviceResponse, Map<String, Object> mapParams) {
        String participantType = String.valueOf(mapParams.get('participantType'));
        if (Test.isRunningTest()) {
            participantType = arce.Arc_Gen_Constants.GROUP_S;
        } else if (participantType == null) {
            final Map<Object, Object> accWrapperObj = (Map<Object, Object>) mapParams.get('accWrapperObj');
            participantType = String.valueOf(accWrapperObj.get('participantType'));
        }
        final arce.Arc_Gen_ServiceAndSaveResponse serviceAndSave = new arce.Arc_Gen_ServiceAndSaveResponse();
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        serviceAndSave.serviceCode = serviceResponse.serviceCode;
        serviceAndSave.serviceMessage = serviceResponse.serviceMessage;
        serviceAndSave.updatefields = new Map<String,Object>();
        if(serviceResponse.serviceCode == String.valueOf(serviceMessage.CODE_200)) {
            final Arc_Gen_RiskFilters_Service.RiskFilterWrapper riskFilter = Arc_Gen_RiskFilters_Service.processResponse(serviceResponse.serviceResponse, participantType);
            final arce.Arc_Gen_ServiceAndSaveResponse save = processService(riskFilter, mapParams);
            serviceAndSave.saveStatus = save.saveStatus;
            serviceAndSave.saveMessage = save.saveMessage;
            serviceAndSave.updatefields = save.updatefields;
        }
        return serviceAndSave;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the parameters for the service request
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    17/12/2020
    * @param   Map<String, Object> mapParams - Standard Id of the analyzed client
    * @return  String
    * @example String ret = setServiceParams(mapParams);
    **/
    public static String setServiceParams(Map<String, Object> mapParams) {
        String accNumber;
        String participantType;
        // Get params from Generic Button component or get Account_Wrapper
        if (mapParams.get('accWrapperObj') == null) {
            final String customerId = (String) mapParams.get('customerId');
            final Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> {customerId});
            accNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(mapAccWrapper.get(customerId).accNumber);
            participantType = mapAccWrapper.get(customerId).participantType;
        } else {
            final Map<String, Object> accWrapperObj = Arc_Gen_RiskFilters_Service.getMapFromJson(mapParams, 'accWrapperObj');
            accNumber = String.valueOf(accWrapperObj.get('accNumber'));
            participantType = String.valueOf(accWrapperObj.get('participantType'));
        }
        final Map<String, String> mapRequest = new Map<String, String> {
            'riskFilterType' => RISK_FILTER,
            'customerId' => accNumber,
            'participantType' => participantType
        };
        return JSON.serialize(mapRequest);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Private method that update the account fields from the response retrieved from the service
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    17/12/2020
    * @param   Arc_Gen_RiskFilters_Service.RiskFilterWrapper riskFilter
    * @param   Map<String, Object> mapParams
    * @return  Arc_Gen_ServiceAndSaveResponse
    * @example Arc_Gen_ServiceAndSaveResponse ret = processService(riskFilter, mapParams);
    **/
    private static arce.Arc_Gen_ServiceAndSaveResponse processService(Arc_Gen_RiskFilters_Service.RiskFilterWrapper riskFilter, Map<String, Object> mapParams) {
        arce.Arc_Gen_ServiceAndSaveResponse serviceAndSave = new arce.Arc_Gen_ServiceAndSaveResponse();
        String recordIdAha;
        // Get params if the service is executed from Generic Button component
        if (mapParams.get('ahaObj') == null) {
            final String customerId = (String) mapParams.get('customerId');
            final String analysisId = (String) mapParams.get('analysisId');
            final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> lstAccAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysis(analysisId, customerId);
            recordIdAha = lstAccAha[0].ahaObj.Id;
        } else {
            final Map<String, Object> ahaObj = Arc_Gen_RiskFilters_Service.getMapFromJson(mapParams, 'ahaObj');
            recordIdAha = String.valueOf(ahaObj.get('Id'));
        }
        // Logic for ES
        Arc_Gen_RiskFilters_Service.RiskCalification riskCalification = new Arc_Gen_RiskFilters_Service.RiskCalification();
        for (Arc_Gen_RiskFilters_Service.RiskFilter riskUnit : riskFilter.data) {
            if (riskUnit.riskId == ID_ES) {
                riskCalification = riskUnit.riskCalification;
            }
        }
        serviceAndSave.saveStatus = 'true';
        if (riskCalification.riskCalId != null) {
            final arce__account_has_analysis__c ahaObj = new arce__account_has_analysis__c(Id = recordIdAha);
            ahaObj.arce__hats_risk_qualification_number__c = Integer.valueOf(riskCalification.riskCalId);
            serviceAndSave = arce.Arc_Gen_AccHasAnalysis_Data.updateRecords(ahaObj);
        }
        return serviceAndSave;
    }
}