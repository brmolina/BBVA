/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_controller
* @Author   eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2019-04-30
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller of the new rating as independent process
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-08-01 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |2020-03-30 eduardoefrain.hernandez.contractor@bbva.com
*             Update arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce call method
* |2020-03-31 juanignacio.hita.contractor@bbva.com
*             Update class test to support new fetchaccounts refactor
* |2020-04-02 joseluis.garcia4.contractor@bbva.com
*             Refactor of New Analysis + RAIP modal.
* |2020-04-24 joseluis.garcia4.contractor@bbva.com
*             Implement call to triage engine.
* |2020-04-29 joseluis.garcia4.contractor@bbva.com
*             Check if client is not ARCE scope.
* |2020-05-07 joseluis.garcia4.contractor@bbva.com
*             Implement finalizePrerating() method.
* |2020-05-19 joseluis.garcia4.contractor@bbva.com
*             Include riskSegment in response.
* |2020-07-14 javier.soto.carrascosa@bbva.com
*             Use header method for risk assessment persistence
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-04 juanignacio.hita.contractor@bbva.com
*             Adds aha name (analysisId) param in traceability record
* |2020-12-18 juanignacio.hita.contractor@bbva.com
*             Add callRiskFilter method
* |2021-02-15 juanpedro.benito.contractor@bbva.com
*             Add getRAIPWfMetadata and picklistValueOfSelectWf methods
* |2021-02-24 saimassimilianno.jordana.contractor@bbva.com
*             Add newFFSSWAhas method
* |2021-03-30 saimassimilianno.jordana.contractor@bbva.com
*             Add new parameters to newFFSSWAhas meth0d.newFFSSWAhas
* |2021-04-27 antonio.munoz.perez.contractor@bbva.com
*             Add globalRunWayConfig() method
* |2021-04-28 antonio.munoz.perez.contractor@bbva.com
*             Add localURLs() method
* |2021-05-05 saimassimilianno.jordana.contractor@bbva.com
*             Add new parameters newFFSSWAhas meth0d.
* |2021-06-09 saimassimilianno.jordana.contractor@bbva.com
*             Modify picklistValueOfSelectWf meth0d and irpWfUpdt, model2012Active new meth0ds added.
* |2021-06-09 saimassimilianno.jordana.contractor@bbva.com
*             Group validation added to control ARP flow usage in picklistValueOfSelectWf meth0d.
* |2021-09-20 saimassimilianno.jordana.contractor@bbva.com
*             checkRatingType and addToWfValue meth0ds added to control rating types.
* |2021-10-06 juanignacio.hita.contractor@bbva.com
*             Add getTriageConfigPost, getIRPTriageStepConfig methods and it modifies getTriageConfig integrate step custom triage.
* |2021-10-28 amunguia.contractor@bbva.com
*             the call to the riskfilter service is controlled according to arce_Config.
* |2021-11-02 juanignacio.hita.contractor@bbva.com
*             Adds checkRatingToolId method that implements local logic to show or hide rating buttons.
* |2021-11-30 amunguia.contractor@bbva.com
*             sent to Provenir Pre-ratings finalized.
* |2022-01-21 saimassimilianno.jordana.contractor@bbva.com
*             picklistValueOfSelectWf refactorized to work with new flows permissions config.
* |2022-02-22 juanignacio.hita.contractor@bbva.com
*             Refactoring getRecalculateRating method
* |2022-04-11 saimassimilianno.jordana.contractor@bbva.com
*             new removeAnalysis method added to remove analysis if EFI calls fails.
* |2022-11-18 antonio.perez.hernandez.contractor@bbva.com
*             New triage mode: Pre-Manual-Post-Auto. getTriageConfig and getIRPTriageStepConfig meth0ds updated. Supress warning IsRunningTest added
* |2023-11-13 isabel.ascaso.ruiz.contractor@bbva.com
*             new method callEngineFinancialState, consultFSdetails created
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyMethods, sf:AvoidUsingTestIsRunningTest, PMD.ExcessiveParameterList, PMD.EmptyStatementBlock, PMD.CyclomaticComplexity')
public class Arc_Gen_RatingAsIndepProcess_controller {
    /** ----------------------------------------------------------------------------------------------------
    * @Description False literal.
    * ---------------------------------------------------------------------------------------------------- **/
    public static final String FALSE_LITERAL = 'false';
    /** ----------------------------------------------------------------------------------------------------
    * @Description Label for Rating.
    * ---------------------------------------------------------------------------------------------------- **/
    public static final String RATING_LABEL = 'Rating';
    /** ----------------------------------------------------------------------------------------------------
    * @Description Label for Pre Rating.
    * ---------------------------------------------------------------------------------------------------- **/
    public static final String PRERATING_LABEL = 'Pre-Rating';
    /** ----------------------------------------------------------------------------------------------------
    * @Description value for Pre Rating.
    * ---------------------------------------------------------------------------------------------------- **/
    public static final String PRERATING_VALUE = 'Prerating';
    /** ----------------------------------------------------------------------------------------------------
    * @Description options step triage
    * ---------------------------------------------------------------------------------------------------- **/
    public static final List<String> OPTIONS_TRIAGE = new List<String> {'PRE', 'POST', 'BOTH'};
    /** ----------------------------------------------------------------------------------------------------
    * @Description custom config irp triage step
    * ---------------------------------------------------------------------------------------------------- **/
    public static final String CNF_TRIAGESTEP = 'IRPTriageStepInterface';
    /** ----------------------------------------------------------------------------------------------------
    * @Description custom config RAIP Call TriageEngine
    * ---------------------------------------------------------------------------------------------------- **/
    public static final String IRPCALLTRIAGE = 'RAIPCallTriageEngine';
    /**
    * @Description: String with value for FINAL_STAGE in ARCE
    */
    static final String FINAL_STAGE = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow')[0].arce__Value1__c) == true ? '14' : '10';
    /**
    * @Description: String with value for TRUE_LITERAL in ARCE
    */
    static final String TRUE_LITERAL = 'true';
    /* @Description String value used to describe callable class.
    */
    private static final String CALLABLE_CLASS = Test.isRunningTest() ? 'Arc_Gen_CallableFromCore_Mock' : 'arce.Arc_Gen_CallableFromCore';
    /**
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		27/01/2020
    * @author	eduardoefrain.hernandez.contractor@bbva.com
    */
    @testVisible
    private Arc_Gen_RatingAsIndepProcess_controller() {

    }
    /** ----------------------------------------------------------------------------------------------------
    * @Description Wrapper class used to return options workflow to Aura component.
    * ----------------------------------------------------------------------------------------------------
    **/
    public class WfValue {
        /**
        * @Description: value for Workflow picklist.
        */
        @AuraEnabled
        public String value { get; set; }

        /**
        * @Description: label for Workflow picklist.
        */
        @AuraEnabled
        public String label { get; set; }

        /**
        * @Description: Constructor
        */
        public WfValue(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Method that returns the response of the saved records of RAIP
    *-------------------------------------------------------------------------------
    * @Date 2020-08-01
    * @Author eduardoefrain.hernandez.contractor@bbva.com
    * @param String accHasAnalysisId - Standard Id of the current chrome
    * @param String ratingModelValue - Code of the rating model retrieved by Triage service
    * @return String - Wrapper that contains the status and the response of the updated
    * @example persistRatingModel(accHasAnalysisId, ratingModelValue)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String persistRatingModel(String accHasAnalysisId, String ratingModelValue, String raipType, String triageConfig) {
        return Json.serialize(Arc_Gen_RatingAsIndepProcess_service.persistRatingModel(accHasAnalysisId, ratingModelValue, raipType, triageConfig));
    }
    /**
    *-------------------------------------------------------------------------------
    * @description method that call callRatiosEngine and return the status of engine.
    *--------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 2020-10-01
    * @param recordId recordId of the account_has_analysis and the list of elements selected from the table.
    * @param lista data for the tables
    * @return list with values of the response.
    * @example public static Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse callRatiosEngine(String recordId,String lista) {
    **/
    @AuraEnabled
    public static Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse callRatiosEngine(String accHasAnalysisId, String ffssList, Boolean isRAIP) {
        Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse resp = new Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse();
        try {
            resp = new Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse();
            resp.ratiosStatus = FALSE_LITERAL;
        } catch(Exception ex) {
            resp.ratiosStatus = FALSE_LITERAL;
            resp.ratiosErrorMsg = ex.getMessage() + ' - ' + ex.getLineNumber();
        }
        return resp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Gets triage config (whether or not the triage engine should be called)
    * and list of rating tool IDs the user can select from.
    *--------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2020-04-27
    * @param accHasId ID of the account has analysis
    * @param interName interface name irp step custom
    * @param stepConfig step triage config custom
    * @return the triage configuration.
    **/
    @AuraEnabled
    public static Arc_Gen_RatingAsIndepProcess_service.TriageConfig getTriageConfig(String accHasId, String interName, String stepConfig) {
        return Arc_Gen_ConfigUtils.getTriageConfig(accHasId, interName, stepConfig);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls triage engine.
    *--------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2020-04-23
    * @param analysisId ID of the analysis
    * @param customerId ID of customer
    * @return Service results
    **/
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callTriage(String analysisId, String customerId) {
        return Arc_Gen_RatingAsIndepProcess_Helper.callTriage(analysisId, customerId);
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
        return Arc_Gen_RatingAsIndepProcess_Data.setanalysis(data);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that calls the Persistance service.
    *-------------------------------------------------------------------------------
    * @date 2020-10-01
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @param String analysisId - Analysis Id
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse callPersistence(String customerId, String analysisId)
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callPersistence(String analysisId, String customerId) {
        final Arc_Gen_PersistanceArceId_service service = new Arc_Gen_PersistanceArceId_service();
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            response = service.setupRiskAssHeader(analysisId, Arc_Gen_SetFinancialSponsor_Service.FINANCIAL_SPONSOR_NO);
        } catch (QueryException ex) {
            response.serviceCode = '404';
            response.serviceMessage = ex.getMessage();
        }
        Return response;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that calls the Persistance service.
    *-------------------------------------------------------------------------------
    * @date 2020-10-01
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @param String analysisId - Analysis Id
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse callPersistence(String customerId, String analysisId)
    */
    @AuraEnabled
    public static String getRAIPData(String analysisId) {
        return Arc_Gen_RatingAsIndepProcess_Data.getRAIPData(analysisId);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that finalizes a prerating.
    *-------------------------------------------------------------------------------
    * @date 2020-05-07
    * @author joseluis.garcia4.contractor@bbva.com
    * @param String arceId - ID of the ARCE record.
    */
    @AuraEnabled
    public static void finalizePrerating(String arceId) {
        Arc_Gen_RatingAsIndepProcess_Helper.finalizePrerating(arceId);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Gets globalRunWay config (whether or not the globalRunWay step should be displayed).
    *--------------------------------------------------------------------------------
    * @author antonio.munoz.contractor@bbva.com
    * @date 2021-04-27
    * @return the globalRunWay configuration.
    **/
    @AuraEnabled
    public static Arc_Gen_RatingAsIndepProcess_service.GlobalRunWayConfig globalRunWayConfig() {
        return Arc_Gen_ConfigUtils.globalRunWayConfig();
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Gets globalRunWay url endpoints.
    *--------------------------------------------------------------------------------
    * @author antonio.munoz.contractor@bbva.com
    * @date 2021-04-27
    * @return the globalRunWay configuration.
    **/
    @AuraEnabled
    public static Arc_Gen_RatingAsIndepProcess_service.RunWayURLConfig localURLs() {
        return Arc_Gen_ConfigUtils.getRunWayURLsConfig();
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that call local service risk filter
    *-------------------------------------------------------------------------------
    * @date   2020-12-18
    * @author juanignacio.hita.contractor@bbva.com
    * @param  String customerId
    * @param  String arceId
    * @return Arc_Gen_ServiceAndSaveResponse
    * @example Arc_Gen_ServiceAndSaveResponse callRiskFilter(customerId, arceId);
    */
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse callRiskFilter(String customerId, String arceId) {
        return Arc_Gen_RatingAsIndepProcess_Helper.callRiskFilter(customerId, arceId);
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Verify if the new IRP workflow is activated.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 15/02/2021
    * @author juanpedro.benito.contractor@bbva.com
    * @return true/false
    * @example isRAIPWfMetadata();
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Boolean isRAIPWfMetadata() {
        return Arc_Gen_ConfigUtils.getConfigBoolean('RAIPSelectWorkflow');
    }
    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description get picklist values.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 2021-02-15
    * @author juanpedro.benito.contractor@bbva.com
    * @return WfValue
    * @example picklistValueOfSelectWf();
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static List<WfValue> picklistValueOfSelectWf(String modelSelected, String profilingResult) {
        return Arc_Gen_RatingAsIndepProcess_Data.picklistValueOfSelectWf(modelSelected, profilingResult);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Method that create FFSS and asociate to Ahas in new IRP workflow
    *-------------------------------------------------------------------------------
    * @Date 2021-02-24
    * @Author saimassimilianno.jordana.contractor@bbva.com
    * @param String accHasAnalysisId - Standard Id of the current Ahas.
    * @param String analysisId - Standard Id of the current Analysis.
    * @param String flowSelected - Irp flow selected apiname.
    * @param String rarRatingTool - RarRatingTool selected on CRP flow.
    * @example newFFSSWAhas(accHasAnalysisId)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static void newFFSSWAhas(String accHasAnalysisId, String analysisId, String flowSelected, String rarRatingTool) {
        try {
            Arc_Gen_RatingAsIndepProcess_service.newFFSSWAhas(accHasAnalysisId, analysisId, flowSelected, rarRatingTool);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
        }

    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method that create FFSS and asociate to Ahas in new IRP workflow
    *-------------------------------------------------------------------------------
    * @Date 2021-06-09
    * @Author saimassimilianno.jordana.contractor@bbva.com
    * @param String accHasAnalysisId - Standard Id of the current ahas.
    * @param String flowSelected - Name of flow selected.
    * @example irpWfUpdt(accHasAnalysisId,flowSelected)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static void irpWfUpdt(String accHasAnalysisId, String flowSelected) {
        try {
            Arc_Gen_RatingAsIndepProcess_service.irpWfUpdt(accHasAnalysisId, flowSelected);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
        }

    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Verify if the new SelectModel 2012 is activated and get options from it.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 01/06/2021
    * @author saimasimilianno.jordana.contractor@bbva.com
    * @return List<WfValue>
    * @example model2012Active();
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static List<WfValue> model2012Active(String raipType) {
        return Arc_Gen_RatingAsIndepProcess_Helper.model2012Active(raipType);
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Check in RatingTypeByModel arceconfig which options are available for rating type.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 20/09/2021
    * @author saimasimilianno.jordana.contractor@bbva.com
    * @return List<WfValue>
    * @example checkRatingType(analysisId, modelSelec);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static List<WfValue> checkRatingType(String analysisId, String modelSelec, Boolean eeffButton) {
        return Arc_Gen_RatingAsIndepProcess_Helper.checkRatingType(analysisId, modelSelec, eeffButton);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets irp triage step arce config custom metadata record
    *--------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   04/10/2021
    * @return String json serialize
    **/
    @AuraEnabled
    public static String getIRPTriageStepConfig() {
        return Arc_Gen_ConfigUtils.getIRPTriageStepConfig();
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Gets triage config when has the "both" option as configuration in triage steps interface
    *--------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   07/10/2021
    * @param  String interName
    * @param  String accHasId
    * @return Arc_Gen_RatingAsIndepProcess_service.TriageConfig
    * @example Arc_Gen_RatingAsIndepProcess_service.TriageConfig triage = handleTriageConfigBoth(interName, accHasId);
    **/
    @AuraEnabled
    public static Arc_Gen_RatingAsIndepProcess_service.TriageConfig handleTriageConfigBoth(String interName, String accHasId) {
        return Arc_Gen_ConfigUtils.handleTriageConfigBoth(interName, accHasId);
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Return rating buttons options with step triage custom interface.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date   2/11/2021
    * @author juanignacio.hita.contractor@bbva.com
    * @param  String analysisId
    * @param  String ratingTool
    * @param  String interName
    * @return List<WfValue>
    * @example List<WfValue> wfVal = checkRatingToolId(analysisId, modelSelec, interName);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static List<WfValue> checkRatingToolId(String analysisId, String ratingTool, String interName) {
        return Arc_Gen_RatingAsIndepProcess_Helper.checkRatingToolId(analysisId, ratingTool, interName);
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Method to validatePrerating.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 30/11/2021
    * @author amunguia.contractor@bbva.com
    * @example validatePrerating(arceId);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static void validatePrerating(String arceId) {
        Arc_Gen_RatingAsIndepProcess_Helper.validatePrerating(arceId);
    }
    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Method to getRecalculateRating.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 02/02/2022
    * @author Alberto Martinez Carrero
    * @example getRecalculateRating(arceId);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String getRecalculateRating(String accHasAnalisysId) {
        String message = 'Show';
        final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> {accHasAnalisysId})[0];
        final Boolean overlaysEnabled = Arc_Gen_ConfigUtils.getConfigBoolean('EnableOverlays');
        message = arce.Arc_Gen_Overlays_Utils.checkRatingAndOverlays(overlaysEnabled,aha);

        return message;
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description method to remove analysis with ECI calls errors.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 13/04//2022
    * @author saimasimilianno.jordana.contractor@bbva.com
    * @return N/A
    * @example removeAnalysis(ahaId);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static void removeAnalysis(String ahaId) {
        Arc_Gen_Remove_Service.updateRemoveInfo(ahaId, '2', 'Removed due to faulty ECI service calls', '');
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Method to get existed analysis and renew.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 22/03/2022
    * @author saimassimilianno.jordana.contractor@bbva.com
    * @example getRenewable(arceId);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String getRenewable(String clientId, String rarRating) {
        final String arceType = rarRating.contains('2019IRP') ? 'Prerating' : 'Rating';
        return Arc_Gen_CorpRenewAnalysis.fetchAnalysis(arceType, clientId, rarRating);
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Method to get existed analysis and renew (RTC).
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 22/03/2022
    * @author joseluis.miralles.tech@bbva.com
    * @example getRenewable(arceId);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String getRenewableRTC(String clientId, String rarRating) {
        final String arceType = rarRating.contains('2021RTC') ? 'Rating' : 'Prerating';
        return Arc_Gen_CorpRenewAnalysis.fetchAnalysisRTC(arceType, clientId, rarRating);
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Method to get existed analysis and renew.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 22/03/2022
    * @author saimassimilianno.jordana.contractor@bbva.com
    * @example getRenewable(arceId);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static void doCloneRecords(String ahacurrent, String data, String rarRating) {
        Arc_Gen_CorpRenewAnalysis.getAllToClone(ahacurrent, data, rarRating);
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description create a new EEFF.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 22/03/2022
    * @author amunguia.contractor@bbva.com
    * @example reateEEFF(ahacurrent, data, rarRating);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static void createEEFF(String ahacurrent, String data, String rarRating) {
        Arc_Gen_CorpRenewAnalysis.createEEFF(ahacurrent, data, rarRating);
    }

    /**
    * @Description Method to get the boolean value for showing the EEFF Corp message
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 21/04/2022
    * @author andres.rodriguez.munoz.contractor@bbva.com
    * @return Boolean
    * @example Boolean value = getShowEEFFCorpMessage();
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Boolean getShowEEFFCorpMessage(){
        Boolean showMessage = false;
        try {
            EEFF_Corp_Setting__mdt defaultSettings = Arc_Gen_RatingAsIndepProcess_Data.getEFFCorpDefaultSettings();
            showMessage = defaultSettings.Show_EEFF_Message__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()); // NOSONAR
        }
        return showMessage;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description method that call callEngineFinancialState and return the status of engine.
    *--------------------------------------------------------------------------------
    * @author isabel.ascaso.ruiz.contractor@bbva.com
    * @date 2019-04-11
    * @param recordId - recordId of the account_has_analysis and the list of elements selected from the table.
    * @param financialIdList - List<String> data for the tables
    * @param isRAIP - Boolean - check if it comes from a RAIP.
    * @param isFinancialRAIP - Boolean - check if it comes from a Financial RAIP.
    * @return Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse
    * @example public static Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse callEngineFinancialState(String recordId,String lista) {
    **/
    @AuraEnabled
    public static Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse callEngineFinancialState(String recordId,List<arce__Financial_Statements__c> updatedEEFF, List<String> financialIdList, Boolean isRAIP, Boolean isFinancialRAIP, String ratingToolSelect) {
        Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse response = Arc_Gen_ModalFinanStatemController.callEngineFinancialState(recordId, updatedEEFF, financialIdList, isRAIP, isFinancialRAIP, ratingToolSelect, null);

        return response;
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method that consult the financial statement details service and set the number of employess of the subsidiary
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.ruiz.contractor@bbva.com
    * @Date     Created: 2019-12-19
    * @param recordId - Id of the account_has_analysis
    * @param fsServiceId - Id of the financial statement
    * @return FinancialDetailsWrapper - wrapper with the result of the operation
    * @example consultFSdetails(recordId, fsServiceId) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Arc_Gen_ModalFinanStatemController.FinancialDetailsWrapper consultFSdetails(String recordId, String fsServiceId) {
        final Arc_Gen_ModalFinanStatemController.FinancialDetailsWrapper response = Arc_Gen_ModalFinanStatemController.consultFSdetails(recordId, fsServiceId, false);

        return response;
    }
    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method that consult the sale engine and retrieve true o false
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.ruiz.tech@bbva.com
    * @Date     Created: 2024-04-16
    * @param recordId - Id of the account_has_analysis
    * @return Boolean - result of the services
    * @example getSalesEngine(recordId) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Arc_gen_Sales_Service.ResponseWrapper getSalesEngine(String ahaId, String raipType) {
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId});
        final Arc_gen_Sales_Service.ResponseWrapper response;
        try {
            response = Arc_gen_Sales.processData(ahaList, raipType);
        } catch (Exception e ) {
            System.debug(loggingLevel.ERROR,'getSalesEngine ERROR ' + e);
            System.debug(loggingLevel.ERROR,'getSalesEngine ERROR ' + e.getLineNumber());
            System.debug(loggingLevel.ERROR,'getSalesEngine ERROR ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }

        return response;
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method to delete the arce and related record
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.ruiz.tech@bbva.com
    * @Date     Created: 2024-04-16
    * @param ahaId - Id of the account_has_analysis
    * @example deleteARCE(recordId) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void cancelARCE(String ahaId) {
        Arc_Gen_RatingAsIndepProcess_Helper.cancelARCE(ahaId);

    }

    /**
    *----------------------------------------------------------------------------------------------------
    * @Description method to create modifier
    *----------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.tech@bbva.com
    * @Date     Created: 2025-05-28
    * @example createModifier(ahaId) {
    *----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void createModifier(String ahaId) {
        Arc_Gen_RatingAsIndepProcess_Data.createModifier(ahaId);
    }

    /**
    *----------------------------------------------------------------------------------------------------
    * @Description method to updateAHa
    *----------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.tech@bbva.com
    * @Date     Created: 2025-05-28
    * @example updateAha(ahaId) {
    *----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void updateAha(String ahaId) {
        Arc_Gen_RatingAsIndepProcess_Data.updateAha(ahaId);
    }

    /**
    *----------------------------------------------------------------------------------------------------
    * @Description method to call parent subsidiary service
    *----------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.tech@bbva.com
    * @Date     Created: 2025-05-28
    * @example callParentSubsidiary() {
    *----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void callParentSubsidiary(String ahaId) {
        final Callable callableFromCore = (Callable) Type.forName(CALLABLE_CLASS).newInstance();
        callableFromCore.call('invocableGroupStructurePS', new Map<String, Object> {'ahaId' => ahaId});
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method to get if the sales is Active
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.ruiz.tech@bbva.com
    * @Date     Created: 2024-04-16
    * @example isSalesEngineConfig() {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Boolean isSalesEngineConfig() {
        return Arc_Gen_ConfigUtils.isSalesEngineConfig();
    }
}