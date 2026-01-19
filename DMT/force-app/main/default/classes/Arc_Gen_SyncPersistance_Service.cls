/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SyncPersistance_Service
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 02/09/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Apex Rest web service to listen the renew asynchronous callback
* The URL is /services/apexrest/RenewCallback/createAssessmentsNotifyResult/v1?risk-assessment-id=01234567890&participant-id=G0012345
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |02/09/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_SyncPersistance_Service {
    /**
    * @Description: String with GROUP string
    */
    static final string SERVICE_NAME = 'createCopyAssessments';
    /**
    *-------------------------------------------------------------------------------
    * @description Web service Post method
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 02/09/2020
    * @param void
    * @return void
    * @example apiService()
    **/
    @TestVisible
    private Arc_Gen_SyncPersistance_Service() {}
    /**
    *-------------------------------------------------------------------------------
    * @description Web service Post method
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 25/09/2020
    * @param String accHasAnalysisId - Current AccHasAnalysis Id
    * @return Map<String, String> - Map of the needed parameters for the service
    * @example getServiceParameters(String accHasAnalysisId)
    **/
    @AuraEnabled
    public static Map<String, String> getServiceParameters(String accHasAnalysisId) {
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasAnalysisId});
        final arce__Analysis__c relatedArce = Arc_Gen_SyncPersistance_Helper.getRelatedArce(ahaList);
        return new Map<String, String> {
            'relatedAnalysisId' => relatedArce.Id,
            'accHasAnalysisId'  => ahaList.get(0).Id,
            'subprocessType'    => ahaList.get(0).arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c,
            'participantType'   => ahaList.get(0).arce__group_asset_header_type__c

        };
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Web service Post method
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 02/09/2020
    * @param Map<string,string> data - Map with the values (accHasAnalysisId, relatedAnalysisId, subprocessType, participantType)
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the service response
    * @example setupPersistanceService(Map<string,string> data)
    **/
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse setupPersistanceService(Map<string,string> data) {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        final String jsonInput = JSON.serialize(Arc_Gen_SyncPersistance_Helper.setServiceParams(data));
        final arce.Arc_Gen_getIASOResponse.ServiceResponse serviceResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, jsonInput);
        response = Arc_Gen_SyncPersistance_Helper.processResponse(serviceResponse);
        Arc_Gen_SyncPersistance_Helper.updateStatus(response.serviceCode, data.get('accHasAnalysisId'));
        return response;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Web service Post method
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 02/09/2020
    * @param String accHasAnalysisId - Standard Id of the analyzed client
    * @return List<arce__Account_has_Analysis__c> - List of analyzed client objects
    * @example getAccHasAnalysis(String accHasAnalysisId)
    **/
    @AuraEnabled
    public static List<arce__Account_has_Analysis__c> getAccHasAnalysis(String accHasAnalysisId) {
        return arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasAnalysisId});
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Web service Post method
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 02/09/2020
    * @param void
    * @return Boolean - persistance metadata config indicator
    * @example getPersistanceIndicator()
    **/
    public static Boolean getPersistanceIndicator() {
        final List<arce__Arce_Config__mdt> peristIndicator = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Persistance_CallServiceIndicator');
        final Boolean indicatorValue = Boolean.valueOf(peristIndicator.get(0).arce__Value1__c);

        return indicatorValue;
    }
}