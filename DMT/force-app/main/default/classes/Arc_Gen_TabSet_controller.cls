/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_TabSet_controller
* @Author   Angel Fuertes Gomez
* @Date     Created: 27/03/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages the tabs to be shown in the ARCE and the edition permits.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-23 Angel Fuertes Gomez
*             Class creation.
* |2019-06-21 mariohumberto.ramirez.contractor@bbva.com
*             Deleted method that was calling to the completeness class
* |2019-07-23 mariohumberto.ramirez.contractor@bbva.com
*             Add new string "DevTemplate" in WrapperTabSet
* |2019-07-29 mariohumberto.ramirez.contractor@bbva.com
*             Add new boolean "changeStatus" in WrapperTabSet
* |2019-10-28 mariohumberto.ramirez.contractor@bbva.com
*             Add new call to the method Arc_Gen_TabSet_service.getUnitChangeResponse()
* |2019-12-02 mariohumberto.ramirez.contractor@bbva.com
*             Add new param in columnReduction in TabsWrapper
* |2020-04-24 eduardoefrain.hernandez.contractor@bbva.com
*             Add methods updateGroupFields, getAccHasAnalysis and throwAuraExcept
*             to update the automated fields in group chrome
* |2020-04-27 joseluis.garcia4.contractor@bbva.com
*             Handles exception case of no sector being found for an analysis.
* |2020-06-09 cesaroctavio.villanueva.cebal@bbva.com
*             Added update to limits when an account has analysis is being retrieved
* |2020-06-17 cesaroctavio.villanueva.cebal@bbva.com
*             Updated limit update method to call
* |2020-06-18 mariohumberto.ramirez.contractor@bbva.com
*             Fixed the call to the 'updatelimit.updateLimitLeverage' method, this is now called
*             only when the analysis is not RAIP
* |2020-07-01 juanignacio.hita.contractor@bbva.com
*             Removed unused 'updateLimit' variable in getAccHasAnalysis method
* |2020-08-18 joseluis.garcia4.contractor@bbva.com
*             Fix error message when resuming ARCE.
* |2020-08-13 juanignacio.hita.contractor@bbva.com
*             Fix exception message on upload tab when the analysis is in verification checklist state.
* |2020-09-18 joseluis.garcia4.contractor@bbva.com
*             Do not update leveraged materiality on Tabset initialization.
* |2021-02-09 juanpedro.benito.contractor@bbva.com
*             Handle Id of Activity split sObject in callTemplateAnalysisJson method
* |2021-05-27 juanignacio.hita.contractor@bbva.com
*             Add warningMessage attribute wrapper and call method for fill.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.EmptyStatementBlock')
public without sharing class Arc_Gen_TabSet_controller {
    /**
    * @Description: Literal for 'arce__Account_has_Analysis__c'
    */
    static final String ACCHAS_LITERAL = 'arce__Account_has_Analysis__c';

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_TabSet_controller controller = new Arc_Gen_TabSet_controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private Arc_Gen_TabSet_controller() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to create the component
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @return all the information to create the component
    * @example TabsWrapper tabswrapper = new TabsWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class TabsWrapper {
        /**
        * @Description: List of WrapperTabSet to save the info of tab (name, percent...)
        */
        @AuraEnabled public List<WrapperTabSet> lstNamesTemplates {get;set;}
        /**
        * @Description: Contain the information of permission
        */
        @AuraEnabled public String gblPermissionEdit {get;set;}
        /**
        * @Description: Boolean to show and hide the component
        */
        @AuraEnabled public boolean gblResultResponse {get;set;}
        /**
        * @Description: Description of the response
        */
        @AuraEnabled public String gblDesResponse {get;set;}
        /**
        * @Description: Boolean param to change the arce status
        */
        @AuraEnabled public Boolean changeStatus {get;set;}
        /**
        * @Description: Message to show if the unit have been change
        */
        @AuraEnabled public String unitChangeRes {get;set;}
        /**
        * @Description: manage the columns in the policie table
        */
        @AuraEnabled public String columnReduction {get;set;}
        /**
        * @Description: warning arce finalized
        */
        @AuraEnabled public boolean warningMessage {get;set;}
        /**
        * @Description: ffss id
        */
        @AuraEnabled public String ffssId {get;set;}
        /**
        * @Description: modifier id
        */
        @AuraEnabled public String modifiId {get;set;}
        /**
        * @Description: arce__Rating_variables_details__c id
        */
        @AuraEnabled public String ratingVarDet {get;set;}
        /**
        * @Description: arce__Activity_Split__c id
        */
        @AuraEnabled public String actSplId {get;set;}
        /**
        * @Description: arce__Account_has_Analysis__c id
        */
        @AuraEnabled public String ahaId {get;set;}
        /**
        * @Description: arce__AHA_Extension__c id
        */
        @AuraEnabled public String ahaExtId {get;set;}
        /**
        * @Description: ahaObj List
        */
        @AuraEnabled public List<arce__Account_has_Analysis__c> ahaObj {get;set;}
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Wrapper that contain the information of the tab
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @return the information to create the tab
    * @example WrapperTabSet wrapper = new WrapperTabSet()
    * -----------------------------------------------------------------------------------------------
    **/
    public class WrapperTabSet {
        /**
        * @Description: Name of the template
        */
        public String nameTemplate {get;set;}
        /**
        * @Description: Name of the section
        */
        public String nameSection {get;set;}
        /**
        * @Description: Percent of the tab with complete fields
        */
        public Integer percent {get;set;}
        /**
        * @Description: Boolean status visible tab
        */
        public Boolean isVisible {get;set;}
        /**
        * @Description: DevName of the template
        */
        public String devTemplate {get;set;}
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a JSON with the information to create the Tabset component
    * -----------------------------------------------------------------------------------------------
    * @param recordId - Id of the current account has analisys object
    * @return JSON with the information to create the Tabset component
    * @example getTabsJson(recordId)
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getTabsJson(Id recordId) {
        final TabsWrapper wrapper = new TabsWrapper();
        try {
            wrapper.gblResultResponse = true;
            final String resJSON = Arc_Gen_TabSet_service.getTemplatesByAccHasAnalysisJson(recordId);
            wrapper.lstNamesTemplates = (List<WrapperTabSet>) JSON.deserialize(resJSON, List<WrapperTabSet>.class);
            wrapper.gblPermissionEdit = Arc_Gen_TabSet_service.getPermissionToEdit(recordId);
            wrapper.columnReduction = Arc_Gen_TabSet_service.getColumnReduction(recordId);
            wrapper.warningMessage = Arc_Gen_TabSet_service.getWarningMessage(recordId, resJSON);
            wrapper.ahaObj = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<Id>{recordId});
            wrapper.ahaId = wrapper.ahaObj[0].Id;
            wrapper.ahaExtId = wrapper.ahaObj[0].arce__AHA_Extension__c;
            final List<arce__Activity_Split__c> actSplIds = wrapper.ahaObj.isEmpty() ? new List<arce__Activity_Split__c>() : getactSplId(recordId);
            wrapper.actSplId = actSplIds.isEmpty() ? '' : actSplIds[0].Id;
            wrapper.ffssId = wrapper.ahaObj.isEmpty() ? '' : wrapper.ahaObj[0].arce__ffss_for_rating_id__c;
            final List<arce__rating_variables_detail__c> ratingVars = wrapper.ahaObj.isEmpty() ? new List<arce__rating_variables_detail__c>() : getRatingVariableDet(recordId);
            wrapper.ratingVarDet = ratingVars.isEmpty() ? '' : ratingVars[0].Id;
            wrapper.modifiId = recordId == null ? null : arce.Arc_Gen_Modifiers_Utils.getModifierInfo(new Set<String>{ String.valueOf(recordId) })[0]?.Id;
        } catch (Arc_Gen_TabSet_service.NoTabsetConfigFoundException ex) {
            wrapper.gblResultResponse = false;
            wrapper.gblDesResponse= ex.getMessage();
        } catch(Exception ex) {
            wrapper.gblResultResponse = false;
            wrapper.gblDesResponse= ex.getMessage() + ' : ' + ex.getLineNumber();
        }
        return JSON.serialize(wrapper);
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description
    * ----------------------------------------------------------------------------------------------------
    * @Author   Noelia.ruiz.lopez.contractor@bbva.com
    * @Date     10-04-2025
    * @param    accHasAnId - The ID of the Account has Analysis Standard record (18-character ID)
    * @param    accHasAnId - Valid 18-character Account has Analysis ID
    * @return   List<arce__rating_variables_detail__c> - Never null, may be empty
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static List<arce__rating_variables_detail__c> getRatingVariableDet(String accHasAnId) {
        List<arce__rating_variables_detail__c> result = new List<arce__rating_variables_detail__c>();
        if (!String.isBlank(accHasAnId)) {
            final String queryString = 'SELECT ' + arce.Arc_Gen_GenericUtilities.getAllFields('arce__rating_variables_detail__c') +
                                ' FROM arce__rating_variables_detail__c WHERE arce__account_has_analysis_id__c = :accHasAnId';
            result = Database.query(String.escapeSingleQuotes(queryString));
        }
        return result;
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description
    * ----------------------------------------------------------------------------------------------------
    * @Author   Noelia.ruiz.lopez.contractor@bbva.com
    * @Date     10-04-2025
    * @param    accHasAnId - The ID of the Account has Analysis Standard record (18-character ID)
    * @param    accHasAnId - Valid 18-character Account has Analysis ID
    * @return   List<arce__rating_variables_detail__c> - Never null, may be empty
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static List<arce__Activity_Split__c> getactSplId(String accHasAnId) {
        List<arce__Activity_Split__c> result = new List<arce__Activity_Split__c>();
        if (!String.isBlank(accHasAnId)) {
            final String queryString = 'SELECT ' + arce.Arc_Gen_GenericUtilities.getAllFields('arce__Activity_Split__c') +
                                ' FROM arce__Activity_Split__c' +
                                ' WHERE arce__Account_has_Analysis__c = :accHasAnId';
            result = Database.query(String.escapeSingleQuotes(queryString));
        }
        return result;
    }
    /*
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a JSON with the information to create the Tabs
    * -----------------------------------------------------------------------------------------------
    * @param recordId - Id of the current account has analisys object
    * @return JSON with the information to create the Tabs
    * @example callTemplateAnalysisJson(recordId)
    * -----------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static TabsWrapper callTemplateAnalysisJson(String recordId) {
        final TabsWrapper wrapperResp = new TabsWrapper();
        final Id recId = (Id) recordId;
        if (recId.getSobjectType().getDescribe().getName() == ACCHAS_LITERAL) {
            try {
                wrapperResp.changeStatus = Arc_Gen_TabSet_service.changeArceState(recordId);
                wrapperResp.gblDesResponse= Arc_Gen_TabSet_service.getTemplatesByAccHasAnalysisJson(recordId);
                wrapperResp.unitChangeRes = Arc_Gen_TabSet_service.getUnitChangeResponse(recordId);
            } catch(Exception ex) {
                wrapperResp.gblDesResponse= ex.getMessage();
            }
        }
        return wrapperResp;
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     2020-04-23
    * @param    String accHasAnId - Account has Analysis Standard Id
    * @return   String - process response JSON
    * @example  public static date updateGroupFields(List<Date> dateList)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce__Account_has_Analysis__c getAccHasAnalysis(String accHasAnId) {
        arce__Account_has_Analysis__c response = new arce__Account_has_Analysis__c();
        try {
            response = Arc_Gen_SetAutomatedFileds_Service.getAccHasAnalysis(accHasAnId);
        } catch(Exception ex) {
            throwAuraExcept(ex.getMessage());
        }
        Return response;
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     2020-04-23
    * @param    String accHasAnId - Account has Analysis Standard Id
    * @return   String - process response JSON
    * @example  public static date updateGroupFields(List<Date> dateList)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String updateGroupFields(arce__Account_has_Analysis__c accHasAn) {
        String response;
        try {
            if (accHasAn.arce__Analysis__r.arce__Stage__c != arce.Arc_Gen_Constants.STAGE_FINALIZED) {
                response = JSON.serialize(Arc_Gen_SetAutomatedFileds_Service.updateGroupFields(accHasAn));
            }
        } catch(Exception ex) {
            throwAuraExcept(ex.getMessage());
        }
        Return response;
    }
    /*----------------------------------------------------------------------------------------------------
    *@Description
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     2020-04-23
    * @param    String message - Message that will be passed to the front by an exception
    * @return   void
    * @example  public static date throwAuraExcept(String message)
    * ----------------------------------------------------------------------------------------------------
    **/
    private static void throwAuraExcept(String message) {
        final AuraHandledException auraError = new AuraHandledException(message);
        auraError.setMessage(message);
        throw auraError;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Get metadata
    * -----------------------------------------------------------------------------------------------
    * @autor    joseluis.miralles.tech@bbva.com
    * @date     09-10-2025
    * @param    metadataList metadata names
    * @return   String with metadata information
    * @example  String e = getTempgetMetadataates(metadataList)
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled(cacheable=true)
    public static String getMetadata(List <String> metadataList) {
        String response;
        try {
            final Map<String, String> arceConfigsMap = arce.Arc_Gen_DataQuality_Utils.getCustomMetadatas(metadataList);
            response = JSON.serialize(arceConfigsMap);
        } catch (Exception e) {
            throwAuraExcept(e.getMessage());
        }
        return response;
    }
}