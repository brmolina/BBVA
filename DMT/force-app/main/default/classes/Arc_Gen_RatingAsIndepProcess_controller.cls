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
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyMethods, sf:AvoidUsingTestIsRunningTest, PMD.ExcessiveParameterList')
public class Arc_Gen_RatingAsIndepProcess_controller {
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
    * @Description False literal.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String FALSE_LITERAL = 'false';
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
    private static final String PRERATING_VALUE = 'Prerating';
    /** ----------------------------------------------------------------------------------------------------
    * @Description options step triage
    * ---------------------------------------------------------------------------------------------------- **/
    public static final List<String> OPTIONS_TRIAGE = new List<String> {'PRE', 'POST', 'BOTH'};
    /** ----------------------------------------------------------------------------------------------------
    * @Description custom config irp triage step
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String CNF_TRIAGESTEP = 'IRPTriageStepInterface';
    /** ----------------------------------------------------------------------------------------------------
    * @Description custom config RAIP Call TriageEngine
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String IRPCALLTRIAGE = 'RAIPCallTriageEngine';
    /**
    * @Description: String with value for FINAL_STAGE in ARCE
    */
    static final String FINAL_STAGE = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow')[0].arce__Value1__c) == true ? '14' : '10';
    /**
    * @Description: String with value for STAGE_CLOSED in ARCE
    */
    static final String STAGE_CLOSED = '3';
    /**
    * @Description: String with value for REASON_PICK in ARCE
    */
    static final String REASON_PICK = '2';
    /**
    * @Description: String with value for TRUE_LITERAL in ARCE
    */
    static final String TRUE_LITERAL = 'true';
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
    * @description method that call callEngineFinancialState and return the status of engine.
    *--------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 2020-10-01
    * @param recordId recordId of the account_has_analysis and the list of elements selected from the table.
    * @param lista data for the tables
    * @return list with values of the response.
    * @example public static Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse callEngineFinancialState(String recordId,String lista) {
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
        Arc_Gen_RatingAsIndepProcess_service.TriageConfig triageConfig =
            new Arc_Gen_RatingAsIndepProcess_service.TriageConfig();

        // Get whether or not triage engine is called from config.
        final List<arce__Arce_Config__mdt> callTriage = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(IRPCALLTRIAGE);
        Boolean callTriageEngine = false;
        if (!callTriage.isEmpty()) {
            callTriageEngine = Boolean.valueOf(callTriage[0].arce__Value1__c);
        }
        triageConfig.triageCallEnabled = callTriageEngine;
        // If triage call will not be done, fetch list of rating tool ids the user will
        // be able to select from.
        if (!callTriageEngine || Test.isRunningTest()) {
            if (stepConfig == null || interName == null || stepConfig == '' && !Test.isRunningTest()) { // default config
                triageConfig.ratingToolList = Arc_Gen_RatingAsIndepProcess_service.getUserSelectableRatingTools();
            } else { // triage steps custom config
                final Map<String, String> objParams = new Map<String, String> {
                    'interName' => interName,
                    'stepConfig' => stepConfig,
                    'accHasId' => accHasId
                };
                setTriageCustom(triageConfig, objParams);
            }
        }

        return triageConfig;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description set triage custom from interface IRP
    *--------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   22/02/2022
    * @param  Arc_Gen_RatingAsIndepProcess_service.TriageConfig triageConfig
    * @param  Map<String, String> objParams
    * @return void
    **/
    public static void setTriageCustom(Arc_Gen_RatingAsIndepProcess_service.TriageConfig triageConfig, Map<String, String> objParams) {
        final Arc_Gen_IRPFlowCustom_Interface impl = Arc_Gen_GenericUtilitiesInterface.getIRPStepFlow(objParams.get('interName'));
        final String stepConfig = objParams.get('stepConfig');
        final String accHasId = objParams.get('accHasId');
        if (stepConfig == OPTIONS_TRIAGE[0] || stepConfig == OPTIONS_TRIAGE[2]) {
            triageConfig.ratingToolList = impl.preTriageStep(accHasId);
        } else if (stepConfig == OPTIONS_TRIAGE[1]) {
            triageConfig.ratingToolList = impl.postTriageStep(accHasId);
        }
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
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            final String param = Arc_Gen_Triage_service.setServiceParameters(analysisId, customerId, true);
            final Arc_Gen_Triage_helper.triageResponse resp = Arc_Gen_Triage_service.setupTriageService(analysisId, param, '');

            // Check if ARCE is in scope.
            final Boolean scopeArce = Boolean.valueOf(resp.groupInScope);
            if (!scopeArce) {
                // Client is not scope of ARCE, finalize raip.
                Arc_Gen_RatingAsIndepProcess_service.finalizeRaip(analysisId, resp.response);
            }

            // Build response.
            final Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put('arceInScope', scopeArce);
            responseMap.put('riskSegment', resp.riskSegment);
            resp.response.serviceMessage = JSON.serialize(responseMap);

            response = resp.response;
        } catch (Exception ex) {
            response.serviceMessage = System.Label.Lc_arce_NewARCE_UnexpectedError;
            response.saveStatus = '500';
        }
        return response;
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
        try {
            analysisresponse = Arc_Gen_NewAnalysis_Service.setanalysis(data);
            return JSON.serialize(analysisresponse);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage() + ex.getStackTraceString());  // NOSONAR
        }
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
        final arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            final Map<String, String> responseMap = new Map<String, String>();
            final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{analysisId})[0];

            responseMap.put('accHasAnalysisId', aha.Id);
            responseMap.put('analysisId', analysisId);
            responseMap.put('customerId', aha.arce__Customer__c); 
            response.serviceMessage = JSON.serialize(responseMap);
            response.saveStatus = 'true';
        } catch (ListException ex) {
            response.saveStatus = FALSE_LITERAL;
            response.serviceMessage = ex.getMessage();
        }
        Return JSON.serialize(response);
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
        try {
            // Finalize RAIP and set discard reason.
            final String discardReason = System.Label.Arc_Gen_FinalizePreratingDiscardReason;
            final arce__Analysis__c analysisToUpdate = new arce__Analysis__c(
                Id = arceId,
                arce__Stage__c = '3',
                arce__wf_status_id__c = '13',
                arce__anlys_wkfl_discard_reason_id__c = discardReason,
                arce__end_date__c = System.today()
            );
            arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c> { analysisToUpdate });

            // Create traceability record.
            final List<arce__Account_has_Analysis__c> lstAccHas = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(arceId);
            final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(discardReason, 'approve', discardReason, lstAccHas[0].Name);
            final Map<String, String> auditWF = new Map<String, String>();
            Arc_Gen_Traceability.saveTrace(arceId, auditAttr, auditWF);
        } catch(DmlException ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ErrorSumPersOR);  // NOSONAR
        } catch(Exception ex) {
            throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
        }
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
        final Arc_Gen_RatingAsIndepProcess_service.GlobalRunWayConfig globalRunWayStep = new  Arc_Gen_RatingAsIndepProcess_service.GlobalRunWayConfig();
        // Get whether or not globalRunWay step is displayed from config.
        final List<arce__Arce_Config__mdt> runWayConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIP_EnableGlobalRunway');
        // Get whether or not globalRunWay options from config.
        final List<arce__Arce_Config__mdt> blockLocalConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIP_BlockLocalRedirect');
        Boolean diplayRunWayStep = false;
        Boolean blockLocalOption= false;
        if (!runWayConfig.isEmpty()) {
            diplayRunWayStep = Boolean.valueOf(runWayConfig[0].arce__Value1__c);
        }
        if (!blockLocalConfig.isEmpty()) {
            blockLocalOption = Boolean.valueOf(blockLocalConfig[0].arce__Value1__c);
        }
        globalRunWayStep.gblRunWayEnabled = diplayRunWayStep;
        globalRunWayStep.blockLocalOption = blockLocalOption;
        return globalRunWayStep;
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
        //Get local class from config.
        final List<arce__Arce_Config__mdt> urlConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIP_RunWayLocalURLsClass');
        final String localClass = Test.isRunningTest() || urlConfig.isEmpty() ? 'Arc_GBL_RAIPRunWayURLs' : urlConfig[0].arce__Value1__c;
        final Type inter = Type.forName(localClass);
        final Arc_Gen_GetRAIPRunWayURLs_Interface urls = (Arc_Gen_GetRAIPRunWayURLs_Interface) inter.newInstance();
        return urls.urlsConfig();
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
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
          if(!Test.isRunningTest() && getArceConfig('RAIPRiskFilter')) {
            response = Arc_Gen_RiskFilters_Service.calloutService(new Map<String, Object> {'customerId' => customerId, 'analysisId' => arceId});
          }
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
        }
        return response;
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
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow');
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
        final List<WfValue> wfValues = new List<WfValue>();

        String optionsAct = 'empty';

        for (String current : profilingResult.split(';')) {
            if (current.contains(modelSelected)) {
                optionsAct = current;
                break;
            }
        }

        final List<Schema.PicklistEntry> pickvals = arce__Account_has_Analysis__c.arce__IRP_Workflow__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry pickval : pickvals) {
            if (optionsAct.contains(String.valueOf(pickval.getValue()))) {
                wfValues.add(new WfValue(pickval.getValue(), pickval.getLabel()));
            }
        }
        return wfValues;
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
        final String mtdName = raipType == 'AnalysisCorp' ? 'IRPModelsAvailable' : 'Model2012IRP';
        final List<WfValue> wfValues = new List<WfValue>();
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(mtdName);

        if (!configs.isEmpty() && configs[0].arce__Value1__c != FALSE_LITERAL) {
            final String configWf = configs[0].arce__Value1__c;
            for (String current : configWf.split(';')) {
                final List<String> keyValue = current.split(':');
                wfValues.add(new WfValue(keyValue[0], keyValue[1]));
            }
        }

        return wfValues;
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
        final List<WfValue> wfValues = new List<WfValue>();
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RatingTypeByModel');
        final String modelToVerify = eeffButton ? arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)analysisId})[0].arce__RAR_rating_tool_id__c : modelSelec;

        if (!configs.isEmpty() && configs[0].arce__Value1__c != FALSE_LITERAL && String.isNotBlank(modelToVerify)) {
            final String woutFlow = modelToVerify.replaceAll('[iacIAC]+rpsubsidiary|[IAC]+RPSUBSIDIARY|[iacIAC]+rpgroup|[IAC]+RPGROUP|[iacIAC]+rp|[IAC]+RP','');
            final String configWf = configs[0].arce__Value1__c;
            for (String current : configWf.split(';')) {
                final List<String> keyValue = current.split(':');
                if (woutFlow.equals(keyValue[0])) {
                    addToWfValue(wfValues, keyValue[1].split(','));
                }
            }
        } else {
            wfValues.add(new WfValue(PRERATING_VALUE, PRERATING_LABEL));
            wfValues.add(new WfValue(RATING_LABEL, RATING_LABEL));
        }

        return wfValues;
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Helper method for checkRatingType.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 20/09/2021
    * @author saimasimilianno.jordana.contractor@bbva.com
    * @return List<WfValue>
    * @example checkRatingType(wfValues, ratings);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static void addToWfValue(List<WfValue> wfValues, List<String> ratings) {
        for (String current : ratings) {
            if(current.equalsIgnoreCase(RATING_LABEL)) {
                wfValues.add(new WfValue(RATING_LABEL, RATING_LABEL));
            } else if (current.equalsIgnoreCase(PRERATING_VALUE)) {
                wfValues.add(new WfValue(PRERATING_VALUE, PRERATING_LABEL));
            }
        }
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
        final List<arce__Arce_Config__mdt> triageStep = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(CNF_TRIAGESTEP);
        String valueCnf = triageStep[0].arce__Value1__c == null ? null: triageStep[0].arce__Value1__c;
        valueCnf = Test.isRunningTest() ? 'PRE;Arc_GBL_IRPFlowCustom' : triageStep[0].arce__Value1__c;
        if (valueCnf != null) {
            final List<String> keyValue = valueCnf.split(';');
            if (OPTIONS_TRIAGE.contains(keyValue[0]) && keyValue[1] != null) {
                valueCnf = JSON.serialize(keyValue);
            } else {
                throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
            }
        }
        return valueCnf;
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
        final Arc_Gen_RatingAsIndepProcess_service.TriageConfig triageConfig = new Arc_Gen_RatingAsIndepProcess_service.TriageConfig();
        final List<arce__Arce_Config__mdt> callTriageArceConf = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(IRPCALLTRIAGE);
        final Boolean callTriageEngine = Test.isRunningTest() || !callTriageArceConf.isEmpty() ? Boolean.valueOf(callTriageArceConf[0].arce__Value1__c) : false;
        triageConfig.triageCallEnabled = callTriageEngine;
        if (!callTriageEngine || Test.isRunningTest()) {
            if (accHasId == null || interName == null) { // default config
                triageConfig.ratingTypeList = Arc_Gen_RatingAsIndepProcess_service.getUserSelectableRatingTools();
            } else { // triage steps custom config
                final Arc_Gen_IRPFlowCustom_Interface impl = Arc_Gen_GenericUtilitiesInterface.getIRPStepFlow(interName);
                triageConfig.ratingTypeList = impl.bothTriageStep(accHasId);
            }
        }
        return triageConfig;
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
        final Arc_Gen_IRPFlowCustom_Interface impl = Arc_Gen_GenericUtilitiesInterface.getIRPStepFlow(interName);
        final List<WfValue> wfValues = new List<WfValue>();
        final List<String> ratings = impl.checkRatingToolId(analysisId, ratingTool);
        if(ratings.contains(PRERATING_LABEL)) {
            wfValues.add(new WfValue(PRERATING_VALUE, PRERATING_LABEL));
        }
        if(ratings.contains(RATING_LABEL)) {
            wfValues.add(new WfValue(RATING_LABEL, RATING_LABEL));
        }
        return wfValues;
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Method to retrieve Arce_config for riskFilters.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 28/10/2021
    * @author amunguia.contractor@bbva.com
    * @return Boolean
    * @example getArceConfig(String name);
    *---------------------------------------------------------------------------------------------------------------------
    */
    private static Boolean getArceConfig(String arceConf) {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(arceConf);
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
        if(getArceConfig('RAIPValidatePrerating')) {
            final arce.Arc_Gen_ServiceAndSaveResponse response;
            final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(arceId)[0];
            //Get local class from config.
            response = Arc_Gen_ValidateRating_service.setupValidateRating(aha.Id, aha.arce__ffss_for_rating_id__r.arce__rating_id__c, null, false);
            if(response.serviceCode != '200') {
                throw new AuraHandledException(System.Label.Arc_Gen_ValidatePrerating);  // NOSONAR
            }
        }
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
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('EnableOverlays');
        final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> {accHasAnalisysId})[0];
        final Boolean overlaysEnabled = configs.isEmpty() ? false : Boolean.valueOf(configs[0].arce__Value1__c);
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
        return Arc_Gen_ModalFinanStatemController.callEngineFinancialState(recordId, updatedEEFF, financialIdList, isRAIP, isFinancialRAIP, ratingToolSelect, null);
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
        return Arc_Gen_ModalFinanStatemController.consultFSdetails(recordId, fsServiceId, false);
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
        System.debug('getSalesEngine ahaId ' + ahaId);
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId});
        System.debug('getSalesEngine ahaList ' + ahaList); 
        final Arc_gen_Sales_Service.ResponseWrapper response;
        try {
            response = Arc_gen_Sales.processData(ahaList, raipType);

            System.debug('getSalesEngine message ' + response);
            if(response != null && response.calculationResult != true) {
                cancelARCE(ahaList);
            }

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
    public static void cancelARCE(List<arce__Account_has_Analysis__c> ahaList) {
        try {
            final arce__Analysis__c arceUp = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaList[0].Id);
            arceUp.put('arce__wf_status_id__c', FINAL_STAGE);
            arceUp.put('arce__Stage__c', STAGE_CLOSED);
            arceUp.put('arce__anlys_wkfl_discard_reason_id__c', REASON_PICK);
            arceUp.put('arce__anlys_wkfl_discard_reason_desc__c', System.Label.Arc_Gen_NoSalesEngine);
            final List<arce__Analysis__c> arceList = New List<arce__Analysis__c>();
            arceList.add(arceUp);

            // Create current action traceability event record
            Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(null, ahaList[0], arceUp, 'REMOVE');
            wkflWrapper.mapReqAction.put('arce__anlys_wkfl_discard_reason_id__c', REASON_PICK);
            wkflWrapper.mapReqAction.put('arce__anlys_wkfl_discard_reason_desc__c', System.Label.Arc_Gen_NoSalesEngine);
            wkflWrapper.mapReqAction.put('arce__anlys_wkfl_discard_reason_desc__c', System.Label.Arc_Gen_NoSalesEngine);
            wkflWrapper = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapper);

            arce.Arc_Gen_ArceAnalysis_Data.updateArce(arceList);

            final string traceComments = Label.Cls_arce_ReturnReason + ' ' + System.Label.Arc_Gen_NoSalesEngine;
            final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_ArceRemoveTitle, 'deny', traceComments.abbreviate(255), ahaList[0].Name);
            final Map<String, String> auditWF = new Map<String, String>();
            final dwp_cvad__Action_Audit__c event = Arc_Gen_Traceability.saveTrace(arceUp.Id, auditAttr, auditWF);
            System.debug('cancelARCE ' + event);
            // Insert new trace record and last update
            Arc_Gen_TraceabilityEvents.updateTraceEvents(wkflWrapper);
        } catch (Exception e) {
            System.debug(loggingLevel.ERROR, e);
        }

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
        final List<arce__Arce_Config__mdt> arceConfList = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Is_Corporate');
        final String isCorp = arceConfList.isEmpty() ? 'false' : arceConfList[0].arce__Value1__c;
        Boolean isActive = false;
        if(isCorp == TRUE_LITERAL) {
            final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('SalesServiceActive');
            isActive = Boolean.valueOf(configs[0].arce__Value1__c);
        }

        return isActive;
    }
}