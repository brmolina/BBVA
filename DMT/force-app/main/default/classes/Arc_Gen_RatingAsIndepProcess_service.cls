/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_service
* @Author   eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2019-04-30
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class of the new rating as independent process
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-08 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |2020-04-21 joseluis.garcia4.contractor@bbva.com
*             Prevents RAIP from being set to status "Preparing analysis".
* |2020-04-27 joseluis.garcia4.contractor@bbva.com
*             Add method to fetch rating tools.
* |2020-04-28 joseluis.garcia4.contractor@bbva.com
*             Implement finalizeRaip method to finalize RAIP if not in scope.
* |2020-05-19 joseluis.garcia4.contractor@bbva.com
*             Updates ARCE to 'Preparing Rating' in method persistRatingModel() (resume RAIP).
* |2020-07-10 eduardoefrain.hernandez.contractor@bbva.com
*             Add saveMessage param to wrapper
* |2020-08-24 eduardoefrain.hernandez.contractor@bbva.com
*             Add rating tool id by geography management
* |2020-08-25 eduardoefrain.hernandez.contractor@bbva.com
*             Change var accHasAnalysis to ahaToUpdate
* |2020-09-18 joseluis.garcia4.contractor@bbva.com
*             Fixes update of rating tool.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-02-24 saimassimilianno.jordana.contractor@bbva.com
*             Added newFFSSWAhas method
* |2021-03-30 saimassimilianno.jordana.contractor@bbva.com
*             Add new parameters to newFFSSWAhas meth0d and include IRP_OVERRIDE_FLOW constant.
* |2021-04-07 joseluis.garcia4.contractor@bbva.com
*             Change references to Arc_Gen_RatingGlobal_* classes.
* |2021-04-27 antonio.munoz.perez.contractor@bbva.com
*             Add GlobalRunWayConfig class.
* |2021-05-05 saimassimilianno.jordana.contractor@bbva.com
*             Parameter deleted and add new one to newFFSSWAhas meth0d.
* |2021-06-09 saimassimilianno.jordana.contractor@bbva.com
*             persistRatingModel Meth0d refactored, IRP_OVERRIDE_FLOW Deleted and irpWfUpdt new meth0d added.
* |2021-11-10 juanignacio.hita.contractor@bbva.com
*             integrate custom steps manual triage configurations for save rating type ids
* |2021-12-09 juanignacio.hita.contractor@bbva.com
*             Adds getInterfaceTriageCnf method
* |2021-12-09 juanignacio.hita.contractor@bbva.com
*             Creates handleResultRecalcRating method
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount,sf:TooManyMethods')
public class Arc_Gen_RatingAsIndepProcess_service {
    /** ----------------------------------------------------------------------------------------------------
    * @Description Stage of a finalized RAIP.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String RAIP_FIN_STAGE = '3';
    /** ----------------------------------------------------------------------------------------------------
    * @Description Status of a finalized RAIP.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String RAIP_FIN_STATUS = '13';
    /**
    * @Description: Integer with the value 12
    */
    static final Integer TWELVE = 12;
    /**
    * @Description: Tool constant
    */
    static final String TOOL = 'TOOL';
    /**
    * @Description: Type constant
    */
    static final String TYPE = 'TYPE';
    /**
    * @Description: IRP triage step save custom metadata config name
    */
    static final String IRPTRI_SAVE_CNF = 'IRPTriageStepSave';
    /**
    * @Description: Rating tool field name by default
    */
    static final String RATING_TOOL_FLD = 'arce__RAR_rating_tool_id__c';
    /**
    * @Description: Rating type field name by default
    */
    static final String RATING_TYPE_FLD = 'arce__g_rtg_tool_typ_id__c';
    /** ----------------------------------------------------------------------------------------------------
    * @Description Wrapper class used to return rating tools to Aura component.
    * ----------------------------------------------------------------------------------------------------
    **/
    public class RatingTool {
        /**
        * @Description: 20-digit identification of the rating tool.
        */
        @AuraEnabled
        public String value { get; set; }

        /**
        * @Description: Rating tool description.
        */
        @AuraEnabled
        public String label { get; set; }

        /**
        * @Description: Rating tool type.
        */
        @AuraEnabled
        public String type { get; set; }

        /**
        * @Description: Constructor.
        */
        public RatingTool(String value, String label, String type) {
            this.value = value;
            this.label = label;
            this.type = type;
        }
    }

    /** ----------------------------------------------------------------------------------------------------
    * @Description Wrapper class used to return triage configuration to client.
    * ----------------------------------------------------------------------------------------------------
    **/
    public class TriageConfig {
        /**
        * @Description: Indicates whether or not the call to the triage engine is done.
        */
        @AuraEnabled
        public Boolean triageCallEnabled { get; set; }

        /**
        * @Description: List of rating tools. Will be null if triageCallEnabled is true.
        */
        @AuraEnabled
        public List<RatingTool> ratingToolList { get; set; }

        /**
        * @Description: List of rating types.
        */
        @AuraEnabled
        public List<RatingTool> ratingTypeList { get; set; }

    }
    /** ----------------------------------------------------------------------------------------------------
    * @Description Wrapper class used to return GlobalRunWay configuration to client.
    * ----------------------------------------------------------------------------------------------------
    **/
    public class GlobalRunWayConfig {
        /**
        * @Description: Indicates whether or not the step to the GlobalRunWayConfig is displayed.
        */
        @AuraEnabled
        public Boolean gblRunWayEnabled { get; set; }

        /**
        * @Description: Indicates whether or not the redirect to the global org option is enabled.
        */
        @AuraEnabled
        public Boolean blockLocalOption { get; set; }
    }
    /** ----------------------------------------------------------------------------------------------------
    * @Description Wrapper class used to return GlobalRunWay configuration to client.
    * ----------------------------------------------------------------------------------------------------
    **/
    public class RunWayURLConfig {
        /**
        * @Description: Indicates whether or not the step to the GlobalRunWayConfig is displayed.
        */
        @AuraEnabled
        public String orgURL { get; set; }

        /**
        * @Description: Indicates whether or not the redirect to the global org option is enabled.
        */
        @AuraEnabled
        public String vfURL { get; set; }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		27/01/2020
    * @author	eduardoefrain.hernandez.contractor@bbva.com
    */
    @testVisible
    private Arc_Gen_RatingAsIndepProcess_service() {

    }
    /**
    * @Class: PreviousARCEData
    * @Description: Wrapper that contain the data of a previously created ARCE
    * @author BBVA
    */
    public class RAIP_Response {
        /**
        * @Description: Save response wrapper
        */
        @AuraEnabled public String saveStatus {get;set;}
        /**
        * @Description: Save response wrapper
        */
        @AuraEnabled public String saveMessage {get;set;}
        /**
        * @Description: Standar Id of the analysis
        */
        @AuraEnabled public String analysisId {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Method that returns a list of rating tools that the user will be
    * able to select from in the RAIP wizard.
    *-------------------------------------------------------------------------------
    * @Date 2020-04-28
    * @Author joseluis.garcia4.contractor@bbva.com
    * @return List<RatingTool> A list of user selectable rating tools.
    * @example getUserSelectableRatingTools()
    *-------------------------------------------------------------------------------
    */
    public static List<RatingTool> getUserSelectableRatingTools() {
        final List<RatingTool> ratingTools = new List<RatingTool>();

        final List<Schema.PicklistEntry> pickvals = arce__Sector__c.arce__rar_rating_tool_id__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry pickval : pickvals) {
            ratingTools.add(new RatingTool(pickval.getValue(), pickval.getLabel(), 'TOOL'));
        }
        return ratingTools;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method that returns a list of rating tool type
    *-------------------------------------------------------------------------------
    * @Date   2021-10-07
    * @Author juanignacio.hita.contractor@bbva.com
    * @return List<RatingTool> A list of user selectable rating tools type.
    * @example getUserRatingToolsType()
    *-------------------------------------------------------------------------------
    */
    public static List<RatingTool> getUserRatingToolsType() {
        final List<RatingTool> ratingTools = new List<RatingTool>();

        final List<Schema.PicklistEntry> pickvals = arce__Sector__c.arce__rar_rating_type__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry pickval : pickvals) {
            ratingTools.add(new RatingTool(pickval.getValue(), pickval.getLabel(), 'TYPE'));
        }
        return ratingTools;
    }


    /**
    *-------------------------------------------------------------------------------
    * @Description Sets a RAIP to finalized.
    *-------------------------------------------------------------------------------
    * @Date 2020-04-29
    * @Author joseluis.garcia4.contractor@bbva.com
    * @param String analysisId - Standard Id of the analysis
    * @param arce.Arc_Gen_ServiceAndSaveResponse resp - Response object in which to save the results.
    *-------------------------------------------------------------------------------
    */
    public static void finalizeRaip(String analysisId, arce.Arc_Gen_ServiceAndSaveResponse resp) {
        try {
            final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{ analysisId })[0];

            analysis.arce__anlys_wkfl_stage_type__c = analysis.arce__Stage__c = RAIP_FIN_STAGE;
            analysis.arce__anlys_wkfl_status_stage_type__c = analysis.arce__wf_status_id__c = RAIP_FIN_STATUS;

            arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c> { analysis });

            resp.saveStatus = 'true';
        } catch (DmlException ex) {
            resp.saveStatus = 'false';
            resp.saveMessage = ex.getMessage();
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method that returns the response of the saved records of RAIP. This method
    * also updates RAIP ARCE to 'Preparing'.
    *-------------------------------------------------------------------------------
    * @Date 2020-08-01
    * @Author eduardoefrain.hernandez.contractor@bbva.com
    * @param String accHasAnalysisId - Standard Id of the current chrome
    * @param String ratingModelValue - Code of the rating model retrieved by Triage service
    * @param String raipType - string to value type of raip
    * @return arce.Arc_Gen_getRatingDataService_data.SaveResult - Wrapper that contains the status and the message of the update
    * @example persistRatingModel(accHasAnalysisId, ratingModelValue)
    *-------------------------------------------------------------------------------
    */
    public static RAIP_Response persistRatingModel(String accHasAnalysisId, String ratingModelValue, String raipType, String triageConfig) {
        final RAIP_Response response = new RAIP_Response();
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasAnalysisId}).get(0);
        final arce__Analysis__c arceList = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<id>{accHasAnalysis.arce__Analysis__c})[0];
        arce__Account_has_Analysis__c ahaToUpdate = new arce__Account_has_Analysis__c(Id = accHasAnalysisId);
        if (!String.isBlank(ratingModelValue)) {
            final String ratingModel = setRatingToolId(ratingModelValue);
            if (Arc_Gen_RatingAsIndepProcess_controller.getIRPTriageStepConfig() == null) {
                ahaToUpdate.arce__RAR_rating_tool_id__c = ratingModel;
                setScaleType(ahaToUpdate, ratingModelValue);
            } else {
                ahaToUpdate = fillRatingToolCustom(ahaToUpdate, ratingModel, triageConfig);
            }
            //final Arc_Gen_getPathDataService_data locator = new Arc_Gen_getPathDataService_data();
            if (ratingModel.length() >= TWELVE) {
                ahaToUpdate.arce__rating_model_type__c = ratingModel.substring(8, 12).replaceFirst('^0*', '');
            }
        }
        arceList.arce__rating_prerating_type__c = raipType;

        // The first time, update RAIP status to Preparing.
        if (arceList.arce__wf_status_id__c == arce.Arc_Gen_Constants.STATUS_VALIDATINGCHECKLIST) {
            arceList.arce__wf_status_id__c = arce.Arc_Gen_Constants.RAIP_STATUS_PREPARING;
        }
        final arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data(); 
        final arce.Arc_Gen_RatingGlobal_data.saveResult res = locator.updateRecords(new List<sObject>{ahaToUpdate,arceList});
        Arc_Gen_NewAnalysis_data.updateArceName(arceList.Id, false);
        // arce.Arc_Gen_WatchList_Utils.setWatchListValue(accHasAnalysis);
        response.saveStatus = res.status == 'true' ? 'true' : 'false';
        response.saveMessage = res.message;
        response.analysisId = accHasAnalysis.arce__Analysis__c;
        Return response;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Method that create FFSS and asociate to Ahas in new IRP workflow
    *-------------------------------------------------------------------------------
    * @Date 2021-02-24
    * @Author saimassimilianno.jordana.contractor@bbva.com
    * @param String accHasAnalysisId - Standard Id of the current ahas.
    * @param String analysisId - Standard Id of the current analysis.
    * @param String flowSelected - Name of flow selected.
    * @example newFFSSWAhas(accHasAnalysisId)
    *-------------------------------------------------------------------------------
    */
    public static void newFFSSWAhas(String accHasAnalysisId, String analysisId, String flowSelected, String rarRating) {
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{analysisId}).get(0);
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasAnalysisId}).get(0);
        final arce__Financial_Statements__c emptyAhasFFSS = Arc_Gen_RatingAsIndepProcess_Data.setFFSSWAhasName(rarRating, accHasAnalysisId);
        accHasAnalysis.arce__ffss_for_rating_id__c = emptyAhasFFSS.Id;
        accHasAnalysis.arce__IRP_Workflow__c = flowSelected;
        analysis.arce__rating_prerating_type__c = 'Rating';
        if (flowSelected == IRPFLOW.CRP.name()) {
            analysis.arce__Stage__c = '2';
            analysis.arce__wf_status_id__c = '12';
        }

        arce.Arc_Gen_GenericUtilities.updateRecords(new List<sObject>{accHasAnalysis,analysis});
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Method that create FFSS and asociate to Ahas in new IRP workflow
    *-------------------------------------------------------------------------------
    * @Date 2021-06-09
    * @Author saimassimilianno.jordana.contractor@bbva.com
    * @param String accHasAnalysisId - Standard Id of the current ahas.
    * @param String flowSelected - Name of flow selected.
    * @example irpWfIpdt(accHasAnalysisId,)
    *-------------------------------------------------------------------------------
    */
    public static void irpWfUpdt(String accHasAnalysisId, String flowSelected) {
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{accHasAnalysisId}).get(0);

        accHasAnalysis.arce__IRP_Workflow__c = flowSelected;

        arce.Arc_Gen_GenericUtilities.updateRecords(new List<sObject>{accHasAnalysis});
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description searches if the configuration has the option of a geography key activated
    *-------------------------------------------------------------------------------
    * @Date 2020-08-24
    * @Author eduardoefrain.hernandez.contractor@bbva.com
    * @param String ratingModelValue - rar rating tool id retrieved by the triage service
    * @return String - modificated rar rating tool id
    * @example setRatingToolId(ratingModelValue)
    *-------------------------------------------------------------------------------
    */
    private static String setRatingToolId(String ratingModelValue) {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIP_EnableRatingToolByGeography');
        final arce__Arce_Config__mdt config = configs[0];
        final boolean result = Boolean.valueOf(config.arce__Value1__c);
        return result ? getRatingToolByGeog(ratingModelValue) : ratingModelValue;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description searches the geography key in the configuration
    *-------------------------------------------------------------------------------
    * @Date 2020-08-24
    * @Author eduardoefrain.hernandez.contractor@bbva.com
    * @param String ratingModelValue - rar rating tool id retrieved by the triage service
    * @return String - modificated rar rating tool id
    * @example setRatingToolId(ratingModelValue)
    *-------------------------------------------------------------------------------
    */
    private static String getRatingToolByGeog(String ratingModelValue) {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIP_RatingToolByGeographyKey');
        final arce__Arce_Config__mdt config = configs[0];
        final String key = String.valueOf(config.arce__Value1__c);
        return ratingModelValue.removeStart(key);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Fills in the fields of the aha object qualification tool depending on the selected tool
    *-------------------------------------------------------------------------------
    * @Date    2021-10-13
    * @Author  juanignacio.hita.contractor@bbva.com
    * @param   arce__Account_has_Analysis__c ahaToUpdate
    * @param   String ratingModel value rating tool
    * @param   String triageConfig (values: TOOL TYPE)
    * @return  arce__Account_has_Analysis__c
    * @example arce__Account_has_Analysis__c ahaToUpdate = fillRatingToolCustom(ahaToUpdate, '', 'TYPE');
    *-------------------------------------------------------------------------------
    */
    private static arce__Account_has_Analysis__c fillRatingToolCustom(arce__Account_has_Analysis__c ahaToUpdate, String ratingModel, String triageConfig) {
        final Map<String,Object> mapValues = new Map<String,Object>();
        arce__Account_has_Analysis__c ahaToReturn = ahaToUpdate;
        final List<String> fieldSave = getIRPTriageSaveCnf();
        if (triageConfig == TOOL) { // PRE
            mapValues.put(fieldSave[0], ratingModel);
        } else if (triageConfig == TYPE) { // POST
            mapValues.put(fieldSave[1], ratingModel);
        }
        ahaToReturn = (arce__Account_has_Analysis__c) arce.Arc_Gen_GenericUtilities.populateObjFromMap(ahaToReturn, mapValues);
        return ahaToReturn;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description  Get IRP triage step configuration of custom metadata, in first position the custom mode and second the local class
    *-------------------------------------------------------------------------------
    * @Date    2021-10-13
    * @Author  juanignacio.hita.contractor@bbva.com
    * @return  List<String>
    * @example List<String> lst = getIRPTriageSaveCnf();
    *-------------------------------------------------------------------------------
    */
    public static List<String> getIRPTriageSaveCnf() {
        final List<arce__Arce_Config__mdt> saveFieldsTriage = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(IRPTRI_SAVE_CNF);
        List<String> fieldSave = new List<String>{RATING_TOOL_FLD, RATING_TYPE_FLD};
        final String fieldTriageStr;
        if (saveFieldsTriage.isEmpty()) {
            fieldTriageStr = null;
        } else {
            fieldTriageStr = saveFieldsTriage[0].arce__Value1__c;
        }
        if (fieldTriageStr != null) {
            fieldSave = fieldTriageStr.split(';');
            if (fieldSave.size() < 2) {
                throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
            }
        }
        return fieldSave;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Return rating tool of account has analysis
    *-------------------------------------------------------------------------------
    * @Date    2021-11-16
    * @Author  juanignacio.hita.contractor@bbva.com
    * @return  String
    * @example String strRet = getRatingIdSelIrp(accHasId);
    *-------------------------------------------------------------------------------
    */
    public static String getRatingIdSelIrp(Id accHasId) {
        final List<String> irpSaveCustom = getIRPTriageSaveCnf();
        final Map<String, Object> mapFldAha = Arc_Gen_Sector_Data.getDynamicFldAha(irpSaveCustom, accHasId);
        final String ahaRatingToolId = (String) mapFldAha.get(irpSaveCustom[0]);
        final String ahaRatingType = (String) mapFldAha.get(irpSaveCustom[1]);
        return ahaRatingToolId == null ? ahaRatingType : ahaRatingToolId;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Return interface name irp triage step
    *-------------------------------------------------------------------------------
    * @Date    2021-12-09
    * @Author  juanignacio.hita.contractor@bbva.com
    * @return  String
    * @example String strRet = getInterfaceTriageCnf();
    *-------------------------------------------------------------------------------
    */
    public static String getInterfaceTriageCnf() {
        final String triageCnf = Arc_Gen_RatingAsIndepProcess_controller.getIRPTriageStepConfig();
        String interName = null;
        if (triageCnf != null) {
            final List<Object> lstConfigStep = (List<Object>) JSON.deserializeUntyped(triageCnf);
            interName = (String) lstConfigStep[1];
        }
        return interName;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Return if should invoking ratios engine service
    *-------------------------------------------------------------------------------
    * @Date    2021-12-09
    * @Author  juanignacio.hita.contractor@bbva.com
    * @return  Boolean
    * @example Boolean retVal = invokeRatiosEngine(recordId, ratingToolSelect);
    *-------------------------------------------------------------------------------
    */
    public static Boolean invokeRatiosEngine(String recordId, String ratingToolSelect) {
        final String nameInterface = Arc_Gen_RatingAsIndepProcess_service.getInterfaceTriageCnf();
        // By default invoke ratios true in IRP
        Boolean invokeRatios = true;
        Arc_Gen_IRPFlowCustom_Interface impl = null;
        if (nameInterface != null) {
            impl = Arc_Gen_GenericUtilitiesInterface.getIRPStepFlow(nameInterface);
            invokeRatios = impl.invokeRatiosEngine(recordId, ratingToolSelect);
        }
        return invokeRatios;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Method that set arce__rating_scale_type__c
    *-------------------------------------------------------------------------------
    * @Date 2023-08-07
    * @Author alberto.martinez.carrero.next@bbva.com
    * @param arce__Account_has_Analysis__c ahaToUpdate
    * @param String ratingModelValue
    * @example setScaleType(ahaToUpdate)
    *-------------------------------------------------------------------------------
    */
    public static void setScaleType(arce__Account_has_Analysis__c ahaToUpdate, String ratingModelValue) {
        if(ratingModelValue.contains('2021RTC_NFI')) {
            ahaToUpdate.arce__rating_scale_type__c = '2';
        }
    }
    /** @Description: ENUM IRPFLOW */
    public enum IRPFLOW {CRP}
}