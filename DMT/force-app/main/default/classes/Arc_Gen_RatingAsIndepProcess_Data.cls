/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_Data
* @Author   saimassimilianno.jordana.contractor@bbva.com
* @Date     Created: 2021-04-09
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Data class of the new rating as independent process
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-08 saimassimilianno.jordana.contractor@bbva.com
*             Class creation.setFFSSWAhasName
* |2020-05-05 saimassimilianno.jordana.contractor@bbva.com
*             Parameter Deleted and added new one in setFFSSWAhasName meth0d.
* |2021-12-22 saimassimilianno.jordana.contractor@bbva.com
*             Info added to ffss related in setFFSSWAhasName meth0d.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.EmptyStatementBlock, PMD.ApexCRUDViolation')
public  with sharing class Arc_Gen_RatingAsIndepProcess_Data {

    /**
    * @description: Empty constructor
    **/
    @TestVisible
    private Arc_Gen_RatingAsIndepProcess_Data() {

    }

    /**
    *---------------------------------------------------------------------------------------
    * @Description  Method  that inserts the ffss with Ahas Name and relate an empty rating
    *---------------------------------------------------------------------------------------
    * @Author   Sai Jordana  saimassimilianno.jordana.contractor@bbva.com
    * @Date     Created: 2021-02-24
    * @param String rarRatingTool - Rar Rating Tool selected by the user.
    * @return   arce__Financial_Statements__c
    * @example  setFFSSWAhasName()
    * -------------------------------------------------------------------------------
    */
    public static arce__Financial_Statements__c setFFSSWAhasName(String rarRatingTool, String ahasId) {
        final arce__rating__c emptyRating = new arce__rating__c();
        if (String.isNotBlank(rarRatingTool)) {
            emptyRating.arce__rar_rating_tool_id__c = rarRatingTool;
        }
        insert emptyRating;

        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c(arce__rating_id__c = emptyRating.Id);
        if (String.isNotBlank(rarRatingTool)) {
            final Boolean isCons = rarRatingTool.left(11) == '00110009091';
            ffss.arce__account_has_analysis_id__c = ahasId;
            ffss.arce__ffss_submitted_type__c = isCons ? '1' : '2';
            ffss.arce__ffss_valid_type__c = isCons ? '1' : '';
        }
        insert ffss;

        return ffss;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Return the default settings for EEFF Corp Setting
    *-------------------------------------------------------------------------------
    * @Date    2022-04-21
    * @Author  andres.rodriguez.munoz.contractor@bbva.com
    * @return  Boolean
    * @example Boolean retVal = invokeRatiosEngine(recordId, ratingToolSelect);
    *-------------------------------------------------------------------------------
    */
    public static EEFF_Corp_Setting__mdt getEFFCorpDefaultSettings() {
        EEFF_Corp_Setting__mdt defaultSettings = [SELECT DeveloperName, Show_EEFF_Message__c FROM EEFF_Corp_Setting__mdt WHERE DeveloperName = 'Default_Settings' WITH SECURITY_ENFORCED]; // NOSONAR
        return defaultSettings;
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
        final arce__Modifier__c  modifier = new arce__Modifier__c();
        modifier.arce__Account_has_AnalysisId__c = ahaId;
        modifier.arce__Tipo__c = '1';
        try {
            if (Schema.sObjectType.arce__Modifier__c.isCreateable()) {
                insert modifier;
            }
        } catch (Exception e) {
            System.debug(loggingLevel.ERROR, 'Error creating modifier: ' + e.getMessage());
            throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
        }
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
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId});
        final arce__AHA_Extension__c ahaExtension = new arce__AHA_Extension__c();
        ahaExtension.Id = ahaList[0].arce__AHA_Extension__c;
        ahaExtension.arce__gf_ratg_corp_adj_ind_type__c = 'N';
        try {
            arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(new List<SObject>{ahaExtension});
        } catch (Exception e) {
            System.debug(loggingLevel.ERROR, 'Error update aha exctension: ' + e.getMessage());
            throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
        }
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
    public static List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> picklistValueOfSelectWf(String modelSelected, String profilingResult) {
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = new List<Arc_Gen_RatingAsIndepProcess_controller.WfValue>();

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
                wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(pickval.getValue(), pickval.getLabel()));
            }
        }
        return wfValues;
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
            response.saveStatus = Arc_Gen_RatingAsIndepProcess_controller.FALSE_LITERAL;
            response.serviceMessage = ex.getMessage();
        }
        Return JSON.serialize(response);
    }
}