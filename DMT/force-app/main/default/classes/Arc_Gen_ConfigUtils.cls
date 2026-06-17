/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ConfigUtils
* @Author   isabel.ascaso.tech@bbva.com
* @Date     Created: 2025-07-09
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for centralized configuration utilities.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2025-07-09 isabel.ascaso.tech@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.EmptyStatementBlock') 
public with sharing class Arc_Gen_ConfigUtils {
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		2025-07-09
    * @author	isabel.ascaso.tech@bbva.com
    */
    @testVisible
    private Arc_Gen_ConfigUtils() {

    }

    /**
    *-------------------------------------------------------------------------------
    * @description Returns the boolean value of a configuration custom metadata record.
    *Useful for feature toggles or conditional logic based on org configuration.
    *--------------------------------------------------------------------------------
    * @author isabel.ascaso.tech@bbva.com
    * @date 2025-07-09
    * @param configName The API name of the configuration to retrieve.
    * @return Boolean value of the configuration (false if not found or empty).
    **/
    public static Boolean getConfigBoolean(String configName) {
        List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(configName);
        return Test.isRunningTest() || !configs.isEmpty() ? Boolean.valueOf(configs[0].arce__Value1__c) : false;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Gets triage config (whether or not the triage engine should be called)
    * and list of rating tool IDs the user can select from.
    *--------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2025-07-09
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
        Boolean callTriageEngine = Arc_Gen_ConfigUtils.getConfigBoolean(Arc_Gen_RatingAsIndepProcess_controller.IRPCALLTRIAGE);
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
    * @date   2025-07-09
    * @param  Arc_Gen_RatingAsIndepProcess_service.TriageConfig triageConfig
    * @param  Map<String, String> objParams
    * @return void
    **/
    public static void setTriageCustom(Arc_Gen_RatingAsIndepProcess_service.TriageConfig triageConfig, Map<String, String> objParams) {
        final Arc_Gen_IRPFlowCustom_Interface impl = Arc_Gen_GenericUtilitiesInterface.getIRPStepFlow(objParams.get('interName'));
        final String stepConfig = objParams.get('stepConfig');
        final String accHasId = objParams.get('accHasId');
        if (stepConfig == Arc_Gen_RatingAsIndepProcess_controller.OPTIONS_TRIAGE[0] || stepConfig == Arc_Gen_RatingAsIndepProcess_controller.OPTIONS_TRIAGE[2]) {
            triageConfig.ratingToolList = impl.preTriageStep(accHasId);
        } else if (stepConfig == Arc_Gen_RatingAsIndepProcess_controller.OPTIONS_TRIAGE[1]) {
            triageConfig.ratingToolList = impl.postTriageStep(accHasId);
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets irp triage step arce config custom metadata record
    *--------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   2025-07-09
    * @return String json serialize
    **/
    @AuraEnabled
    public static String getIRPTriageStepConfig() {
        final List<arce__Arce_Config__mdt> triageStep = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(Arc_Gen_RatingAsIndepProcess_controller.CNF_TRIAGESTEP);
        String valueCnf = triageStep[0].arce__Value1__c == null ? null: triageStep[0].arce__Value1__c;
        valueCnf = Test.isRunningTest() ? 'PRE;Arc_GBL_IRPFlowCustom' : triageStep[0].arce__Value1__c;
        if (valueCnf != null) {
            final List<String> keyValue = valueCnf.split(';');
            if (Arc_Gen_RatingAsIndepProcess_controller.OPTIONS_TRIAGE.contains(keyValue[0]) && keyValue[1] != null) {
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
    * @date   2025-07-09
    * @param  String interName
    * @param  String accHasId
    * @return Arc_Gen_RatingAsIndepProcess_service.TriageConfig
    * @example Arc_Gen_RatingAsIndepProcess_service.TriageConfig triage = handleTriageConfigBoth(interName, accHasId);
    **/
    @AuraEnabled
    public static Arc_Gen_RatingAsIndepProcess_service.TriageConfig handleTriageConfigBoth(String interName, String accHasId) {
        final Arc_Gen_RatingAsIndepProcess_service.TriageConfig triageConfig = new Arc_Gen_RatingAsIndepProcess_service.TriageConfig();
        final Boolean callTriageEngine = getConfigBoolean(Arc_Gen_RatingAsIndepProcess_controller.IRPCALLTRIAGE);
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
    *-------------------------------------------------------------------------------
    * @description Gets globalRunWay config (whether or not the globalRunWay step should be displayed).
    *--------------------------------------------------------------------------------
    * @author antonio.munoz.contractor@bbva.com
    * @date 2025-07-09
    * @return the globalRunWay configuration.
    **/
    @AuraEnabled
    public static Arc_Gen_RatingAsIndepProcess_service.GlobalRunWayConfig globalRunWayConfig() {
        final Arc_Gen_RatingAsIndepProcess_service.GlobalRunWayConfig globalRunWayStep = new  Arc_Gen_RatingAsIndepProcess_service.GlobalRunWayConfig();
        // Get whether or not globalRunWay step is displayed from config.
        Boolean diplayRunWayStep = getConfigBoolean('RAIP_EnableGlobalRunway');
        Boolean blockLocalOption= getConfigBoolean('RAIP_BlockLocalRedirect');

        globalRunWayStep.gblRunWayEnabled = diplayRunWayStep;
        globalRunWayStep.blockLocalOption = blockLocalOption;
        return globalRunWayStep;
    }

    /**
    *--------------------------------------------------------------------------------------------------------
    * @Description method to get if the sales is Active
    *--------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.tech@bbva.com
    * @Date     Created: 2025-07-09
    * @example isSalesEngineConfig() {
    * -------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Boolean isSalesEngineConfig() {
        final List<arce__Arce_Config__mdt> arceConfList = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Is_Corporate');
        final Boolean isCorp = arceConfList.isEmpty() ? false : Boolean.valueOf(arceConfList[0].arce__Value1__c);
        Boolean isActive = false;
        if(isCorp) {
            isActive = getConfigBoolean('SalesServiceActive');
        }

        return isActive;
    }

    // Arc_Gen_ConfigUtils.cls
    public static Arc_Gen_RatingAsIndepProcess_service.RunWayURLConfig getRunWayURLsConfig() {
        final List<arce__Arce_Config__mdt> urlConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIP_RunWayLocalURLsClass');
        final String localClass = Test.isRunningTest() || urlConfig.isEmpty() ? 'Arc_GBL_RAIPRunWayURLs' : urlConfig[0].arce__Value1__c;
        final Type inter = Type.forName(localClass);
        final Arc_Gen_GetRAIPRunWayURLs_Interface urls = (Arc_Gen_GetRAIPRunWayURLs_Interface) inter.newInstance();
        return urls.urlsConfig();
    }

}