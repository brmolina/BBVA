/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_getRatingDataService_controller
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 22/10/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Obtains the response of the rating calculation service
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |28/10/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |23/7/2019  eduardoefrain.hernandez.contractor@bbva.com
*             Added comments.
* |2020-04-14 mariohumberto.ramirez.contractor@bbva.com
*             Added setupRatingPrev method
* |25/5/2020  juanignacio.hita.contractor@bbva.com
*             Added "getCustomerData" and "validationQualitativeQuestion" methods
* |16/6/2020  joseluis.garcia4.contractor@bbva.com
*             Raise an error if calculating a rating on an analysis with no permission to edit.
* |2020-06-29 mariohumberto.ramirez.contractor@bbva.com
*             Update class for HU GADRDCDE-1577 Mejora Tabla Información Financiera
*             The call to the rating service for the previous financial statement was eliminated
* |16/7/2020  joseluis.garcia4.contractor@bbva.com
*             Clear Leveraged Test results after calculating rating.
* |17/09/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Add throwAuraExcept method instead of "throw new AuraHandledException"
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-04-30 otiliaramona.veres.contractor@bbva.com
* 			  Added an empty constructor method.
* |2021-05-04 otiliaramona.veres.contractor@bbva.com
* 			  Added annotation '@testVisible' to the empty constructor method.
* |2021-12-23 francisco.munoz.torres.contractor@bbva.com
* 			      Added persistFFSS method
* |2021-11-24 juanignacio.hita.contractor@bbva.com
* 			  Add callPersistModifiers method that call qualitativeBlock service before to call rating in IRP.
* |2022-03-22 juanignacio.hita.contractor@bbva.com
* 			  Changes callPersistModifiers for invoke getFullFieldsAha method
* |2022-04-07 francisco.munoz.torres.contractor@bbva.com
* 			  Checks if can persist ratios
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_getRatingDataService_controller {
    /**
    * @Description: Error Literal
    */
    private final static String ERROR_TEXT = 'Error';
    /**
    * @Description: False Literal
    */
    private final static String FALSE_TEXT = 'false';
    /**
    * @Description: False Literal
    */
    private static final String QUALITATIVE_SERVICE = 'qualitativeBlocks';
    /**
    * @Description: False Literal
    */
    private static final String PERSISTENCE_CONFIG = 'empPersistenceQualitativeIRP';
    /**
    * @Description: False Literal
    */
    private static final String CONFIG_QUALITATIVE_IRP = 'IRPQualitativeService';
    /**
    * @Description: False Literal
    */
    private static final String ERROR_MESSAGE = 'errorMessage';
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@Date   Created:2021-04-30
    */
    @TestVisible
    private Arc_Gen_getRatingDataService_controller() { }
    /**
    * @Class: ClientData
    * @Description: Wrapper that contain all the rating service parameters
    * @author BBVA
    */
    public class ClientData {
        /**
        * @Description: Indicates name of the customer
        */
        @AuraEnabled public String customerName {get;set;}
        /**
        * @Description: Indicates if the numeber of the customer
        */
        @AuraEnabled public String customerId {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get the selected analysis from the id (account has analysis object)
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 21/05/2020
    * @param String accHasId
    * @return arce__Analysis__c
    * @example arce__Analysis__c arce = Arc_Gen_getRatingDataService_controller.getAnalysis(accHasId)
    **/
    @AuraEnabled
    public static arce__Analysis__c getAnalysis(String accHasId) {
        try {
            return arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasId);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the client data
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String analysisId
    * @return ClientData - A wrapper with the data of the client
    * @example public static ClientData getCustomerData(String analysisId
    **/
    @AuraEnabled
    public static ClientData getCustomerData(String analysisId) {
        ClientData data = new ClientData();
        List<String> customerData = new List<String>();
        customerData = Arc_Gen_getRatingDataService_service.getCustomerData(analysisId);
        data.customerName = customerData[0];
        data.customerId = customerData[1];
        Return data;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that persist FFSS if not persisted yet
    --------------------------------------------------------------------------------
    * @author francisco.munoz.torres.contractor@bbva.com
    * @date 23/12/2021
    * @param String ahaId
    * @return arce.Arc_Gen_ServiceAndSaveResponse - A wrapper with the result of a DML operation and service call
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse persistFFSS(String ahaId)
    **/
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse persistFFSS(String ahaId) {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        final Boolean hasPermissions = Arc_Gen_TabSet_service.getPermissionToEdit(ahaId) == 'true';
        if (hasPermissions) {
            try {
                final arce__Account_has_Analysis__c ahaData = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];
                if(ahaData.arce__newFFSS_ind__c == null) {
                  Arc_Gen_Balance_Tables_data dataAccess = new Arc_Gen_Balance_Tables_data();

                  List<arce__Financial_Statements__c> validFFSS = dataAccess.getFinancialStatements(new List<String>{ahaData.arce__ffss_for_rating_id__c});
                  Arc_Gen_Balance_Tables_service.RatiosAndRatingResponse buildTablesResp = new Arc_Gen_Balance_Tables_service.RatiosAndRatingResponse();
                  final String ratingToolSelect = Arc_Gen_RatingAsIndepProcess_service.getRatingIdSelIrp(ahaId);
                  final Boolean isRAIP = ahaData.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c == arce.Arc_Gen_Constants.SUBPROCESS_RATING;

                  final Boolean invokeRatios = isRAIP ? Arc_Gen_RatingAsIndepProcess_service.invokeRatiosEngine(ahaId, ratingToolSelect) : true;
                  if (invokeRatios) {
                      buildTablesResp = Arc_Gen_Balance_Tables_service.buildTables(ahaId, validFFSS, isRAIP, false);
                  } else {
                      buildTablesResp = Arc_Gen_Balance_Tables_service.createRatiosAndRespWrapper(validFFSS[0].arce__financial_statement_id__c);
                  }

                  if (buildTablesResp.ratiosStatus == System.Label.Cls_arce_Success200) {
                    response.serviceCode = '200';
                  } else {
                    final Map<String, Object> errorWrapper = new Map<String, Object>();
                    errorWrapper.put('errorCode', '500');
                    errorWrapper.put('errorTitle', System.Label.Arc_Gen_Error);
                    errorWrapper.put(ERROR_MESSAGE, buildTablesResp.ratiosErrorMsg);
                    response.serviceCode = '500';
                    response.serviceMessage = JSON.serialize(errorWrapper);
                  }
                } else {
                  response.serviceCode = '200';
                }
            } catch(CalloutException ex) {
                response.serviceCode = '500';
                response.serviceMessage = ex.getMessage();
            }
        } else {
            final Map<String, Object> errorWrapper = new Map<String, Object>();
            errorWrapper.put('errorCode', '403');
            errorWrapper.put('errorTitle', System.Label.Arc_Gen_Error);
            errorWrapper.put(ERROR_MESSAGE, System.Label.Arc_Gen_Generic_NotAllowed);
            response.serviceCode = '403';
            response.serviceMessage = JSON.serialize(errorWrapper);
        }
        return response;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the response FROM the service class
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param String analysisId
    * @param String customerId
    * @return arce.Arc_Gen_ServiceAndSaveResponse - A wrapper with the result of a DML operation and service call
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupRating(String analysisId,String customerId)
    **/
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse setupRating(String analysisId, String customerId, String serviceMock) {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        final Boolean hasPermissions = Arc_Gen_TabSet_service.getPermissionToEdit(analysisId) == 'true';
        if (hasPermissions) {
            try {
                if(serviceMock == ERROR_TEXT) {
                    throw new CalloutException();
                }
                response = Arc_Gen_getRatingDataService_service.setupRating(analysisId, customerId, null, serviceMock);

                // Clear Leveraged Test results.
                Arc_Gen_TestLeverage_service.clearTestLeveragedResults(analysisId);
            } catch(CalloutException ex) {
                response.saveStatus = FALSE_TEXT;
                response.serviceMessage = ex.getMessage();
            }
        } else {
            final Map<String, Object> errorWrapper = new Map<String, Object>();
            errorWrapper.put('errorCode', '403');
            errorWrapper.put('errorTitle', System.Label.Arc_Gen_Error);
            errorWrapper.put(ERROR_MESSAGE, System.Label.Arc_Gen_Generic_NotAllowed);
            response.serviceCode = '403';
            response.serviceMessage = JSON.serialize(errorWrapper);
        }
        return response;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that validate qualitative questions
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 24/04/2020
    * @param String accHasId
    * @return Map<String, List<dyfr__Field_Config__c>>
    * @example Map<String, List<dyfr__Field_Config__c>> lstFc = Arc_Gen_getRatingDataService_controller.validationQualitativeQuestion(accHasId)
    **/
    @AuraEnabled
    public static Map<String, List<dyfr__Field_Config__c>> validationQualitativeQuestion(String accHasId, arce__Analysis__c analysis) {
        Map<String, List<dyfr__Field_Config__c>> mapTabEmptyFc = new Map<String, List<dyfr__Field_Config__c>>();
        try {
            // Get sector and tabset information, the map contains the name of the template and code of the sector
            final List<arce__Account_has_Analysis__c> lstAccHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasId});
            final Map<String, String> mapTabset = Arc_Gen_Sector_Data.getMapTabSet(lstAccHasAnalysis[0], analysis.arce__anlys_wkfl_sub_process_type__c);
            mapTabEmptyFc = Arc_Gen_getRatingDataService_service.validationQualitativeQuestion(accHasId, mapTabset);
        } catch (Exception e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Arc_Gen_ApexCallError + e.getMessage() + ' - ' + e.getStackTraceString());
        }
        return mapTabEmptyFc;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @description Call the persistModifiers engine
    * @param aHasAnalysId Id of the account has analysis.
    * @param methodType persistence type name.
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce.Arc_Gen_PersistModifiers_Service.VariablePersistenceResult callPersistModifiers(String aHasAnalysId, String methodType, arce__Analysis__c analysisObj) {
        arce.Arc_Gen_PersistModifiers_Service.VariablePersistenceResult response = new arce.Arc_Gen_PersistModifiers_Service.VariablePersistenceResult();
        try {
            final List<arce__Arce_Config__mdt> lstArceConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(CONFIG_QUALITATIVE_IRP);
            if (lstArceConfig[0].arce__Value1__c == 'true' && analysisObj.arce__anlys_wkfl_sub_process_type__c == arce.Arc_Gen_Constants.SUBPROCESS_RATING) {
                final arce.Arc_Gen_Account_Has_Analysis_Wrapper ahaFullObject = Arc_Gen_ArceDataModel_Locator.getFullFieldsAha(aHasAnalysId);
                final arce.Arc_Gen_PersistModifiers_Service calloutService = new arce.Arc_Gen_PersistModifiers_Service(QUALITATIVE_SERVICE, PERSISTENCE_CONFIG, true);
                response = calloutService.persistVariablesOfAnalysis(ahaFullObject);
            } else {
                response.serviceCode = '200';
            }
        } catch (Exception ex) {
            final Map<String, Object> errWrapper = new Map<String, Object>();
            errWrapper.put('errorCode', '403');
            errWrapper.put('errorTitle', arce.Arc_Gen_RatingGlobal_Constants.ERROR_TEXT);
            errWrapper.put(ERROR_MESSAGE, System.Label.Arc_Gen_RatingError_GenericError);
            response.serviceCode = '403';
            response.serviceMessage = JSON.serialize(errWrapper);
        }
        return response;
    }
}