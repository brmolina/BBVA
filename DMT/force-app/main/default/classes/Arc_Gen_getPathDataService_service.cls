/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_getPathDataService_service.cls
* @Author   eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2019-07-25
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service Class for Path Service
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-28 eduardoefrain.hernandez.contractor@bbva.com
*             Initial Version.
* |2019-07-23 eduardoefrain.hernandez.contractor@bbva.com
*             Added Comments.
* |2019-09-25 franciscojavier.bueno@bbva.com
*             Change Salesforce ID by Analysis Number.
* |2019-12-05 jhovanny.delacruz.cruz@bbva.com
*             Enable de encryption method
* |2020-02-04 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add two new parameters in setupPath() and created SetupPathWrapper to avoid 'long parameter lists'
* |2020-01-29 javier.soto.carrascosa@bbva.com
*             Add fixes
* |2020-04-01 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add new parameter in method callPathService
* |2020-04-12 javier.soto.carrascosa@bbva.com
*             Add support to retrieve local field from risk assessment location
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-02-23 juanignacio.hita.contractor@bbva.com
*             Adds setAveragePath method update path_complexity__c in AHA and average path in Analysis
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_getPathDataService_service {
    /**
    * @Description: Constant true boolean
    */
    public static final String TRUEBOOL = 'true';
    /**
    * @Description: SetupPathWrapper
    */
    public class SetupPathWrapper {
        /**
        * @Description: String analysisId
        */
        public String analysisId {get; set;}
        /**
        * @Description: String customerId
        */
        public String customerId {get; set;}
        /**
        * @Description: String clientNumber
        */
        public String clientNumber {get; set;}
        /**
        * @Description: String subsidiary
        */
        public String subsidiary {get; set;}
        /**
        * @Description: String saveObject
        */
        public Boolean saveobject {get; set;}
    }
/**
*-------------------------------------------------------------------------------
* @description Method that sets the variables for the path service
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String analysisId - Analysis Id
* @param String customerId - Customer Id
* @param String customerNumber - Customer Number
* @param String subsidiary - Indicates if the miniARCE is a Group or a Subsidiary
* @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper with the Service response
* @example public arce.Arc_Gen_ServiceAndSaveResponse setupPath(Arc_Gen_getPathDataService_service.SetupPathWrapper pathParameters)
**/
    public arce.Arc_Gen_ServiceAndSaveResponse setupPath(Arc_Gen_getPathDataService_service.SetupPathWrapper pathParameters) {
        String selectedPath,customerNumber;
        arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        Arc_Gen_getPathDataService_data locator = new Arc_Gen_getPathDataService_data();
        arce.Arc_Gen_getIASOResponse.serviceResponse response = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        List<arce__Account_has_Analysis__c> lista = locator.getAccountHasAnalysis(pathParameters.analysisId,pathParameters.customerId);
        customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(pathParameters.clientNumber);
        response = locator.callPathService(lista[0].Name,customerNumber,pathParameters.subsidiary,lista[0].arce__Analysis__c);
        serviceAndSaveResp.serviceCode = response.serviceCode;
        serviceAndSaveResp.serviceMessage = response.serviceMessage;
        serviceAndSaveResp.updatefields = new Map<String,Object>();
        if(response.serviceCode == String.valueOf(serviceMessage.CODE_200)) {
            Map<String, Object> responseMap = response.serviceResponse;
            Object listServiceResp = (Object)responseMap.get('data');
            Map<String, Object> data = (Map<String, Object>)listServiceResp;
            Object operationData = (Object)data.get('operationData');
            Map<String, Object> riskPaths = (Map<String, Object>)operationData;
            List<Object> paths = (List<Object>)riskPaths.get('riskPaths');
            Map<String, Object> assessment = (Map<String, Object>)paths[0];
            Map<String, Object> assessmentPath = (Map<String, Object>)assessment.get('riskPathType');
            selectedPath = (String)assessmentPath.get('id');
            arce.Arc_Gen_ServiceAndSaveResponse save = setPath(pathParameters.analysisId,pathParameters.customerId,selectedPath,pathParameters.saveobject);
            serviceAndSaveResp.saveStatus = save.saveStatus;
            serviceAndSaveResp.saveMessage = save.saveMessage;
            serviceAndSaveResp.updatefields = save.updatefields;
        }
        Return serviceAndSaveResp;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that sets the path in the ARCE
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String analysisId - Analysis Id
* @param String customerId - Customer Id
* @param String selectedPath - Selected Path
* @return Arc_Gen_getPathDataService_data.saveResult - Wrapper that contains the result of a DML process
* @example public static Arc_Gen_getPathDataService_data.saveResult setPath(String analysisId,String customerId,String selectedPath)
**/
    public static arce.Arc_Gen_ServiceAndSaveResponse setPath(String analysisId,String customerId,String selectedPath, Boolean saveobject) {
        arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        Arc_Gen_getPathDataService_data locator = new Arc_Gen_getPathDataService_data();
        List<arce__Account_has_Analysis__c> analysis = locator.getAccountHasAnalysis(analysisId,customerId);
        if(!analysis.isEmpty()) {
            analysis[0].arce__path__c = selectedPath;
            analysis[0].arce__complexity_path_id__c = getComplexityPath(selectedPath);
        }
        if(saveobject) {
            serviceAndSaveResp = locator.updateRecords(analysis);
        } else {
            serviceAndSaveResp.updatefields = new Map<String,Object>();
            serviceAndSaveResp.updatefields.put('arce__path__c',analysis[0].arce__path__c);
            serviceAndSaveResp.updatefields.put('arce__complexity_path_id__c', getComplexityPath(analysis[0].arce__path__c));
        }
        if (serviceAndSaveResp.saveStatus == TRUEBOOL) {
            serviceAndSaveResp = setAveragePath(analysisId, selectedPath);
        }
        Return serviceAndSaveResp;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that obtains the customer number
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String analysisId - Analysis Id
* @param String customerId - Customer Id
* @return String - Customer Number
* @example public static String getCustomerNumber(String analysisId,String customerId)
**/
    public static String getCustomerNumber(String analysisId,String customerId) {
        return arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysis(analysisId,customerId)[0].accWrapperObj.accNumber;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that obtains the customer data
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String accHasAnalysisId - Account Has Analysis Id
* @return String - Customer Data
* @example public static String getCustomerData(String accHasAnalysisId)
**/
    public static List<String> getCustomerData(String accHasAnalysisId) {
        Return Arc_Gen_getPathDataService_data.getAnalysisAndCustomer(accHasAnalysisId);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Calculates complexity average value of the path for the analysis from path aha and arce config
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    22/02/2021
    * @param   String analysisId - Analysis Id
    * @param   String selectedPath - Selected Path
    * @return  Arc_Gen_ServiceAndSaveResponse
    * @example Arc_Gen_ServiceAndSaveResponse service = setAveragePath(analysisId, selectedPath);
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse setAveragePath(String analysisId, String selectedPath) {
        arce.Arc_Gen_ServiceAndSaveResponse serviceAndSave = new arce.Arc_Gen_ServiceAndSaveResponse();
        final Arc_Gen_getPathDataService_data locator = new Arc_Gen_getPathDataService_data();
        final Map<String, Integer> complexityPath = arce.Arc_Gen_GenericUtilities.getConfigComplexityPath();
        final arce__Analysis__c analysis = new arce__Analysis__c(Id = analysisId);
        analysis.arce__gf_destination_path_id__c = String.valueOf(complexityPath.get(selectedPath));
        serviceAndSave = locator.updateRecords(new List<sObject>{analysis});
        return serviceAndSave;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Calculates complexity average value of the path for the analysis from path aha and arce config
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    08/03/2021
    * @param   String selectedPath - Selected Path
    * @return  Integer
    * @example Integer complexPath = getComplexityPath(selectedPath);
    **/
    private static Integer getComplexityPath(String selectedPath) {
        final Map<String, Integer> complexityPath = arce.Arc_Gen_GenericUtilities.getConfigComplexityPath();
        return complexityPath.get(selectedPath);
    }
}