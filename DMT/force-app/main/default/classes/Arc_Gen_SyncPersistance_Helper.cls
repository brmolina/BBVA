/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SyncPersistance_Helper
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
* |2021-10-27 francisco.munoz.torres.contractor@bbva.com
*             When recovering the last sanctioned ARCE, the expired and unexpired are included in the same step
*             regardless of the sub-process
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_SyncPersistance_Helper {
    /**
    * @Class: RatingParameters
    * @Description: Wrapper that contain the needed params to send the helper
    * @author BBVA
    */
    public class ServiceParameters {
        /**
        * @Description: risk assessment Id of the current account has analysis
        */
        public String riskAssessmentId {get;set;}
        /**
        * @Description: Client number of the current participant
        */
        public String participantId {get;set;}
        /**
        * @Description: risk assessment Id of the account has analysis to copy
        */
        public String relatedAssessment {get;set;}
        /**
        * @Description: Event of the service call (RENEWAL, EDIT, COPY)
        */
        public String eventType {get;set;}
        /**
        * @Description: Type of participant (GROUP, SUBSIDIARY, SUBGROUP, SUPRAGROUP)
        */
        public String participantType {get;set;}
    }
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
    private Arc_Gen_SyncPersistance_Helper() {}
    /**
    *-------------------------------------------------------------------------------
    * @description Web service Post method
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 02/09/2020
    * @param arce.Arc_Gen_getIASOResponse.ServiceResponse serviceResponse - response of the service
    * @return arce.Arc_Gen_ServiceAndSaveResponse - contains the response of the serivce and the status of the saving process
    * @example processResponse(Arc_Gen_getIASOResponse.ServiceResponse serviceResponse)
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse processResponse(arce.Arc_Gen_getIASOResponse.ServiceResponse serviceResponse) {
        final arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        response.serviceCode = serviceResponse.serviceCode;
        response.serviceMessage = serviceResponse.serviceMessage;
        response.serviceResponse = serviceResponse.serviceMessage;
        response.saveStatus = JSON.serialize(serviceResponse.serviceResponse);
        return response;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Sets the parameters of the service call
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 02/09/2020
    * @param Map<String,String> data - Map with the values (accHasAnalysisId, relatedAnalysisId, subprocessType, participantType)
    * @return ServiceParameters - Wrapper that contains the service parameters
    * @example setServiceParams(Map<String,String> data)
    **/
    public static ServiceParameters setServiceParams(Map<String,String> data) {
        final ServiceParameters parameters = new ServiceParameters();

        final arce.Arc_Gen_Account_Has_Analysis_Wrapper currentAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysisAndCustomer(new List<String>{data.get('accHasAnalysisId')})[0];
        final arce.Arc_Gen_Account_Has_Analysis_Wrapper relatedAha = getRelatedAha(currentAha, data.get('relatedAnalysisId'));

        parameters.riskAssessmentId = currentAha.ahaObj.Name;
        parameters.participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient(currentAha.accWrapperObj.accNumber);
        parameters.relatedAssessment = relatedAha.ahaObj.Name;
        parameters.eventType = setEventType((String)data.get('subprocessType'));
        parameters.participantType = (String)data.get('participantType') == '1' ? arce.Arc_Gen_Constants.GROUP_S : arce.Arc_Gen_Constants.SUBS_S;
        return parameters;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the related analyzed client object
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 02/09/2020
    * @param arce.Arc_Gen_Account_Has_Analysis_Wrapper currentAha - Current analyzed client object
    * @param String relatedArceId - Related ARCE id
    * @return arce.Arc_Gen_Account_Has_Analysis_Wrapper - Wrapper of the Account has analysis
    * @example getRelatedAha(Arc_Gen_Account_Has_Analysis_Wrapper currentAha, String relatedArceId)
    **/
    private static arce.Arc_Gen_Account_Has_Analysis_Wrapper getRelatedAha(arce.Arc_Gen_Account_Has_Analysis_Wrapper currentAha, String relatedArceId) {
        arce.Arc_Gen_Account_Has_Analysis_Wrapper relatedAha = new arce.Arc_Gen_Account_Has_Analysis_Wrapper();
        final List<arce__Account_has_Analysis__c> relatedAhaList = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{relatedArceId});
        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> relatedAhaWrapper = arce.Arc_Gen_AccHasAnalysis_Data.getListAHAWrapper(relatedAhaList);
        for(arce.Arc_Gen_Account_Has_Analysis_Wrapper relatedAhaWr : relatedAhaWrapper) {
            if(relatedAhaWr.accWrapperObj.accNumber == currentAha.accWrapperObj.accNumber) {
                relatedAha = relatedAhaWr;
            }
        }
        return relatedAha;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the event type
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 02/09/2020
    * @param subprocessType - Sub process of the ARCE (1 - Renovation, 2 - New, 3 - Modification)
    * @return String - event type of the service call
    * @example setEventType(String subprocessType)
    **/
    @testVisible private static String setEventType(String subprocessType) {
        String eventType;
        switch on subprocessType {
            when '1' {
                eventType = 'RENEWAL';
            }
            when '2' {
                eventType = 'NEW';
            }
            when '3' {
                eventType = 'EDIT';
            }
        }
        return eventType;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains the initial persistance status
    *-------------------------------------------------------------------------------
    * @date 02/09/2020
    * @author Eduardo Efraín Hernández Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @param Boolean persistanceInd - Indicator of the persistance metadata config
    * @param String subprocessType - Sub process of the ARCE (1 - Renovation, 2 - New, 3 - Modification)
    * @return String - Initial Persistance status
    * @example getPersistanceStatus(Boolean persistanceInd, String subprocessType);
    */
    public static Boolean getPersistanceStatus(Boolean persistanceInd, String subprocessType) {
        final List<arce__Arce_Config__mdt> peristSubprocess = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Persistance_AvailableEventTypes');
        final String subprocessValues = peristSubprocess.get(0).arce__Value1__c;
        final List<String> availabSubprocess = subprocessValues.split(',');

        return persistanceInd && availabSubprocess.contains(subprocessType) ? true : false;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get the relatd arce
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 25/09/2020
    * @param List<arce__Account_has_Analysis__c> - current Aha Id in modification or renovation
    * @return arce__Analysis__c - finished record from which the "Mod/Ren" process took its data
    * @example getRelatedArce(List<arce__Account_has_Analysis__c>)
    **/
    public static arce__Analysis__c getRelatedArce(List<arce__Account_has_Analysis__c> ahaList) {
        arce__Analysis__c relatedArce = new arce__Analysis__c();

        final arce.Arc_Gen_Account_Has_Analysis_Wrapper ahaWrap = arce.Arc_Gen_AccHasAnalysis_Data.getListAHAWrapper(ahaList).get(0);
        try {
            relatedArce = arce.Arc_Gen_ArceAnalysis_Data.getLastSancArceByGroup(new Set<Id>{ahaWrap.ahaObj.arce__Analysis__r.arce__Group__c}).get(0);
        } catch (ListException e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Cls_arce_Persistance_Error_NoPreviousARCE);
        }

        return relatedArce;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get the relatd arce
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 25/09/2020
    * @param String serviceCode - Service HTTP code (200, 400, 500, etc...)
    * @param String accHasAnalysisId - Standard Id of the account has analysis
    * @return void
    * @example updateStatus(String serviceCode, String accHasAnalysisId)
    **/
    public static void updateStatus(String serviceCode, String accHasAnalysisId) {
        if(serviceCode.startsWith('2')) {
            final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c(
                Id = accHasAnalysisId,
                arce__persistance_callback_status_type__c = '1'
            );
            arce.Arc_Gen_GenericUtilities.updateRecords(new List<sObject>{aha});
        }
    }
}