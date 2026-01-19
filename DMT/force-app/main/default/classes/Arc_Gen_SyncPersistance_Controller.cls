/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SyncPersistance_Controller
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
public class Arc_Gen_SyncPersistance_Controller {
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
    private Arc_Gen_SyncPersistance_Controller() {}
    /**
    *-------------------------------------------------------------------------------
    * @description Method that inits the calling of the service
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 28/09/2020
    * @param String accHasAnalysisId - Standard Id of the analyzed client
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the service
    * @example initCallingPersistance(String accHasAnalysisId)
    **/
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse initCallingPersistance(String accHasAnalysisId) {
        final Map<String, String> data = Arc_Gen_SyncPersistance_Service.getServiceParameters(accHasAnalysisId);
        return Arc_Gen_AnalysisWizard_Controller.callCreateCopyAssessments(data);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains the object of the account has analysis with a given id
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 28/09/2020
    * @param String accHasAnalysisId - Standard Id of the analyzed client
    * @return List<arce__Account_has_Analysis__c> - Object list of Analyzed Clients
    * @example getAccHasAnalysis(String accHasAnalysisId)
    **/
    @AuraEnabled
    public static List<arce__Account_has_Analysis__c> getAccHasAnalysis(String accHasAnalysisId) {
        return arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasAnalysisId});
    }
}