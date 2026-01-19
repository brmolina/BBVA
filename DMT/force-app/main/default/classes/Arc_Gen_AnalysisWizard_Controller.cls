/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_AnalysisWizard_Controller
  * @Author   joseluis.garcia4.contractor@bbva.com
  * @Date     Created: 2020-04-08
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Controller of the analysis wizard of the new ARCE modal. Some methods from the
  * Arc_Gen_NewAnalysis_Controller class have been moved here to disgregate responsibilities among
  * classes.
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-04-08 joseluis.garcia4.contractor@bbva.com
  *             Class creation.
  * |2020-04-27 ricardo.almanza.contractor@bbva.com
  *             Added callTriage method.
  * |2020-04-05 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Added flowModifiedArce method.
  * |2020-05-20 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Change class reference in method called persistenceDmlModificationARCE()
  * |2020-06-26 joseluis.garcia4.contractor@bbva.com
  *             Adds updateArceSectorAndStatus method, called when sector selection is manual.
  * |2020-08-12 mariohumberto.ramirez.contractor@bbva.com
  *             Update flowModifiedArce method for Hu Renovation
  * |2020-08-25 mariohumberto.ramirez.contractor@bbva.com
  *             Add new callEcoGroupParticipantsPer method
  * |2020-09-14 joseluis.garcia4.contractor@bbva.com
  *             Remove unused SectorResponse wrapper class.
  * |2020-09-14 mariohumberto.ramirez.contractor@bbva.com
  *             modify callEcoGroupParticipantsPer method, now return an arce.Arc_Gen_ServiceAndSaveResponse wrapper
  * |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
  *             Added arce. namespace to all classes that are now in the arce-dependencies package
  * |2020-09-24 eduardoefrain.hernandez.contractor@bbva.com
  *             Update flowModifiedArce, getPersistanceCallConfig methods parameters & Create callCreateCopyAssessments method
  *             modify callEcoGroupParticipantsPer method, now return an arce.Arc_Gen_ServiceAndSaveResponse wrapper
  * |2020-12-17 juanignacio.hita.contractor@bbva.com
  *             Add callRiskFilters method
  * |2021-12-02 francisco.munoz.torres.contractor@bbva.com
  *             Add callRatioEngineOnModification method
  * |2021-12-23 francisco.munoz.torres.contractor@bbva.com
  *             Remove callRatioEngineOnModification method
  * |2022-04-01 juanignacio.hita.contractor@bbva.com
  *             Add checkChangesTriage, checkManualTriage, retrieveExistingArce methods
  **/
@SuppressWarnings('sf:TooManyMethods')
public with sharing class Arc_Gen_AnalysisWizard_Controller {
    /**
    * @Description: String with SUBSIDIARY string
    */
    static final string SUBSIDIARY = 'SUBSIDIARY';
    /**
    * @Description: String with GROUP string
    */
    static final string GROUP_NAME = 'GROUP';

    /**
    * Empty constructor to avoid static code analysis tool warnings.
    */
    private Arc_Gen_AnalysisWizard_Controller() { }  // NOPMD

    /**
    *-------------------------------------------------------------------------------
    * @description Gets whether triage engine should be called.
    *--------------------------------------------------------------------------------
    * @date 26/06/2020
    * @author joseluis.garcia4.contractor@bbva.com
    * @return Boolean - Whether the triage engine should be called.
    */
    @AuraEnabled
    public static Boolean getCallTriageEngineConfig() {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('AnalysisCallTriageEngine');
        Boolean result;

        if (configs.isEmpty()) {
            result = false;
        } else {
            final arce__Arce_Config__mdt config = configs[0];
            result = Boolean.valueOf(config.arce__Value1__c);
        }

        return result;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description set the analysis in the response
    *--------------------------------------------------------------------------------
    * @date 02/11/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param recordId recordId - id of the account_has_analysis
    * @param String analysisType (arce__anlys_wkfl_sub_process_type__c)
    * @return AnalysisResponse - Response of the created ARCE
    * @example setupAnalysis(String recordId, String analysisType) {
    */
    @AuraEnabled
    public static String setanalysis(Map<string,string> data) {
        Arc_Gen_NewAnalysis_Service.AnalysisResponse analysisresponse = new Arc_Gen_NewAnalysis_Service.AnalysisResponse();
        analysisresponse = Arc_Gen_NewAnalysis_Service.setanalysis(data);
        return JSON.serialize(analysisresponse);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that calls the Persistance service.
    *-------------------------------------------------------------------------------
    * @date 09/04/2019
    * @author ricardo.almanza.contractor@bbva.com
    * @param String analysisId - Analysis Id
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse callPersistence(String customerId, String analysisId)
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callPersistence(String analysisId) {
        return Arc_Gen_NewAnalysis_Controller.callPersistence(analysisId);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that calls the Persistance service.
    *-------------------------------------------------------------------------------
    * @date 09/04/2019
    * @author ricardo.almanza.contractor@bbva.com
    * @param String analysisId - Analysis Id
    * @param String customerId - Account Id
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse callTriage(String analysisId,String customerId)
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callTriage(String analysisId,String customerId, String clientId) {
        return Arc_Gen_NewAnalysis_Controller.callTriage(analysisId,customerId,clientId);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that checks for changes in the type of analysis from response
    * triage engine service against a new analysis
    *-------------------------------------------------------------------------------
    * @date    31/03/2022
    * @author  juanignacio.hita.contractor@bbva.com
    * @param   String analysisId - Analysis Id
    * @param   String existArceIdToMod - Existing arce id
    * @return  Boolean
    * @example Boolean ret = checkChangesTriage(analysisId, existArceIdToMod)
    */
    @AuraEnabled
    public static Boolean checkChangesTriage(String analysisId, String existArceIdToMod) {
        return Arc_Gen_NewAnalysis_Controller.checkChangesTriage(analysisId, existArceIdToMod);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that checks for changes in the type of analysis from response
    * triage engine service against a new analysis
    *-------------------------------------------------------------------------------
    * @date    31/03/2022
    * @author  juanignacio.hita.contractor@bbva.com
    * @param   String accHasId - Analysis Id
    * @return  Map<String, String> data
    * @example Boolean ret = checkManualTriage(accHasId, data)
    */
    @AuraEnabled
    public static Boolean checkManualTriage(Id accHasId, Map<String, String> data) {
        return Arc_Gen_NewAnalysis_Controller.checkManualTriage(accHasId, data);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description set the analysis in the response
    *--------------------------------------------------------------------------------
    * @date 02/11/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param recordId recordId - id of the account_has_analysis
    * @param String analysisType (arce__anlys_wkfl_sub_process_type__c)
    * @return AnalysisResponse - Response of the created ARCE
    * @example setupAnalysis(String recordId, String analysisType) {
    */
    @AuraEnabled
    public static void updateArceToPreparing(String arceId, String analysisType) {
        Arc_Gen_AnalysisWizard_Service.updateStatusArce(arceId, '02', (analysisType == null) ? arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{arceid})[0].arce__anlys_wkfl_sub_process_type__c : analysisType);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Updates the sector and top-down/bottom-up indicator, as well as
    * sets the ARCE status to preparing (only called when sector selection is manual).
    *--------------------------------------------------------------------------------
    * @date 26/06/2020
    * @author joseluis.garcia4.contractor@bbva.com
    * @param String arceId - id of the ARCE
    * @param String sector - Selected sector
    * @param String indicator - Selected indicator (whether group financial info is consolidated)
    * @param String analysisType (arce__anlys_wkfl_sub_process_type__c)
    */
    @AuraEnabled
    public static void updateArceSectorAndStatus(String arceId, String sector, String indicator, String analysisType) {
        // Update AHA sectors and indicator.
        Arc_Gen_AnalysisWizard_Service.updateSector(arceId, sector, indicator);

        // Update ARCE Status.
        updateArceToPreparing(arceId, analysisType);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Call copy limits persistance
    *--------------------------------------------------------------------------------
    * @date 25/10/2021
    * @author francisco.munoz.torres.contractor@bbva.com
    * @param String analysisId - id of the ARCE
    * @param String sector - Selected sector
    * @param String indicator - Selected indicator (whether group financial info is consolidated)
    * @param String analysisType (arce__anlys_wkfl_sub_process_type__c)
    */
    @AuraEnabled
    public static void callCopyLimits(String arceId) {
      final Map<String, Object> data = new Map<String, Object> {
        'analysisId' => arceId,
        'idUserSelected' => userinfo.getuserId()
      };
      Arc_Gen_PersistenceCopyLimits_service.callCopyLimitsService(data);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description call the path of the service
    *-------------------------------------------------------------------------------
    * @date 30/04/2019
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @param analysisId analysisId of the account has analysis
    * @param customerId customerId Id of the client
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the service
    * @example callPathService(String analysisId,String customerId,Boolean isorphan) {
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callPathService(String analysisId, String customerId, Boolean isorphan) {
        final Arc_Gen_getPathDataService_service.SetupPathWrapper pathParameters = new Arc_Gen_getPathDataService_service.SetupPathWrapper();
        final String customerNumber = Arc_Gen_getPathDataService_service.getCustomerNumber(analysisId, customerId);
        final Arc_Gen_getPathDataService_service service = new Arc_Gen_getPathDataService_service();
        pathParameters.analysisId = analysisId;
        pathParameters.customerId = customerId;
        pathParameters.clientNumber = customerNumber;
        pathParameters.subsidiary = (isorphan ? SUBSIDIARY : GROUP_NAME);
        pathParameters.saveobject = true;
        return service.setupPath(pathParameters);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Call risk filter local service
    *-------------------------------------------------------------------------------
    * @date    17/12/2020
    * @author  juanignacio.hita.contractor@bbva.com
    * @param   customerId customerId Id of the client
    * @param   analysisId analysisId
    * @return  Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the service
    * @example Arc_Gen_ServiceAndSaveResponse saveAnd = callRiskFilters(customerId, analysisId);
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callRiskFilters(String customerId, String analysisId) {
        final Map<String, Object> mapObj = new Map<String, Object> {
            'customerId' => customerId,
            'analysisId' => analysisId
        };
        return Arc_Gen_RiskFilters_Service.calloutService(mapObj);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description The process of modifying an ARCE begins
    *-------------------------------------------------------------------------------
    * @date 04/05/2020
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @param Map<String, String> data Map with the following values:
    *                            String modRenVar,String selectedSector,String accountswraper,subprocess,persistanceInd,isHolding
    * @return
    * @example public static String flowModifiedArce(Map<String, String> data) {
    */
    @AuraEnabled
    public static String flowModifiedArce(Map<String, String> data) {
        return Arc_Gen_ModificationArce_Controller.persistenceDmlModificationARCE(data);
    }
    /**
    *------------------------------------------------------------------------------------------------------------
    * @description Method that calls the economic group participant persitance service.
    *------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 24/04/2020
    * @param String listparticipant - list participant wrapper
    * @param String accountsParticipants - accounts participants info
    * @param String analysisId - Analysis Id
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service
    * @example callEcoGroupParticipantsPer(listparticipant, acctsPart, analysisId)
    * -----------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callEcoGroupParticipantsPer(String listparticipant, String acctsPart, String analysisId) {
        final Arc_Gen_CallListParticipant.innertoreturnlistp listparticipants = (Arc_Gen_CallListParticipant.innertoreturnlistp) JSON.deserialize(listparticipant, Arc_Gen_CallListParticipant.innertoreturnlistp.Class);
        final List<arce.Arc_Gen_Account_Wrapper> accPartWrapLts = (List<arce.Arc_Gen_Account_Wrapper>) JSON.deserialize(acctsPart, List<arce.Arc_Gen_Account_Wrapper>.Class);
        return Arc_Gen_EcoGroupPartPersist_Service.callPersistence(listparticipants, accPartWrapLts, analysisId);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that returns the indicator of the persistance service calling
    *-------------------------------------------------------------------------------
    * @date 03/09/2020
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return Boolean - Indicates if is necessary to call the persistance service
    * @example getPersistanceCallConfig() {
    */
    @AuraEnabled
    public static Boolean getPersistanceCallConfig() {
        return Arc_Gen_SyncPersistance_Service.getPersistanceIndicator();
    }
    /**
    *-------------------------------------------------------------------------------
    * @description call the createCopyAssessments service (copying process persistance)
    *-------------------------------------------------------------------------------
    * @date 03/09/2020
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @param Map<string,string> data analysisId of the account has analysis
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the service
    * @example callCreateCopyAssessments(Map<string,string> data) {
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callCreateCopyAssessments(Map<string,string> data) {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            response = Arc_Gen_SyncPersistance_Service.setupPersistanceService(data);
        } catch (Exception e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Arc_Gen_ApexCallError + e.getMessage() + ' - ' + e.getStackTraceString());
        }
        return response;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Retrieves data of existing arce mod/renov and previous arce new
    *-------------------------------------------------------------------------------
    * @date    07/04/2022
    * @author  juanignacio.hita.contractor@bbva.com
    * @param   Id arceId
    * @param   Id arceIdModRenv
    * @return  String - JSON serialize
    * @example String ret = retrieveExistingArce(arceId, arceIdModRenv)
    */
    @AuraEnabled
    public static String retrieveExistingArce(Id arceId, Id arceIdModRenv) {
        final Arc_Gen_ModificationArce_Service.AnalysisResponse wrapper = new Arc_Gen_ModificationArce_Service.AnalysisResponse();
        return JSON.serialize(Arc_Gen_ModificationArce_Service.getPrevArceData(wrapper, arceId, arceIdModRenv));
    }
}