/*------------------------------------------------------------------
*Author:        Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
*Project:       ARCE - BBVA Bancomer
*Description:   Class used for the button to Sanction.
*_______________________________________________________________________________________
*Version    Date           Author                               Description
*1.0        30/04/2019     Angel Fuertes Gomez                      Creation.
*1.1        12/11/2019     LUIS ARTURO PARRA ROSAS             SWITCH FOR CHANGING STAGE AND STATE
*1.2        20/11/2019     Javier Soto Carrascosa              Remove data access, fix traceability syle, use generic utilities
*1.3        06/12/2019     LUIS ARTURO PARRA ROSAS             Switch modification
*1.4        26/12/2019     Juan Manuel Perez Ortiz             Add logic to send notifications
*1.5        02/01/2020     Mario H. Ramirez Lio                Added new validation used in BtnSanction_Service_Helper
*1.6        05/02/2020     Juan Ignacio Hita Manso             Added new methods, refactorizaction and parameter analysisType
*1.7        28/02/2020     Juan Ignacio Hita Manso             Added new labels and abbreviate in trace comments
*1.8        03/03/2020     Juan Ignacio Hita Manso             Changed trace title and icon
*1.9        30/03/2020     Jose Luis García                    Update validateFields method to meet GADRDCDE-1301 requirements
*1.10       13/05/2020     Jose Luis García                    Fix traceability texts
*1.11       03/06/2020     Jose Luis García                    Fix success toast not being displayed.
*1.12       04/09/2020     Javier Soto Carrascosa              Remove exception line from message displayed to user
*1.13       16/09/2020     Juan Ignacio Hita Manso             Remove unused variable in WrapperBtnSanction
*1.14       23/09/2020     Sai Jordana                         Added arce. namespace to all classes that are now in the arce-dependencies package
*1.14       04/12/2020     Juan Ignacio Hita Manso             Adds aha name (analysisId) param in traceability record
*1.15       18/02/2021     Jose Luis García                    Include call to action persistence service.
*1.16       20/02/2021     Juan Ignacio Hita Manso             Add traceability events funcionality in the workflow
*1.17       23/02/2021     Carlos Pisador Cañibano             Added new method to change ratings to "validated"
*1.18       07/04/2021     Jose Luis García                    Change references to Arc_Gen_RatingGlobal_* classes.
*1.19       30/04/2021     Otilia Ramona Veres Oltean          Added an empty constructor method.
*1.20       04/05/2021     Otilia Ramona Veres Oltean          Added annotation '@testVIsible' to the empty constructor method.
*1.19       16/06/2021     Jose Luis García                    Action type is now dynamic depending on option selected when sanctioning.
*1.20       18/10/2021     Juan Ignacio Hita Manso             Adds saveTracePostSanction method
*1.21       24/03/2022     Francisco Muñoz Torres              Fix to get the ambit from input data
-----------------------------------------------------------------------------------------*/
public with sharing class Arc_Gen_BtnSanction_service {
    /*
        @Description: String with the api name of the option FINALIZED in the picklist arce__Stage__c
    */
    static final String FINALIZED = '3';
    /*
        @Description: String with the api name of the option Finalized Analysis in the picklist arce__wf_status_id__c
    */
    static final String FINALIZED_ANALYSIS = '10';
    /*
        @Description: String with the api name of the option Contrasting Analysis in the picklist arce__wf_status_id__c
    */
    static final String CONTRASTING_ANALYSIS = '04';
    /*
        @Description: String with the control value GROUP
    */
    static final String GROUP_S = '1';
    /*
        @Description: String with the control value SUCCESS
    */
    static final String SUCCESS = 'SUCCESS';
    /*
        @Description: String with the control value ERROR
    */
    static final String ERROR = 'ERROR';
    /*
        @Description: String with the api value of the picklist arce__prop_int_mod_rec_type__c
    */
    static final String YES = '1';
    /*
        @Description: Name of the field with the ambit type.
    */
    static final String AMBIT_FIELD_NAME = 'arce__anlys_wkfl_edit_br_level_type__c';
    /*
        @Description: Integer with the number 3.
    */
    static final Integer THREE = 3;
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@date 2021-04-30
    */
    @TestVisible
    private Arc_Gen_BtnSanction_service() { }
    /**
    *-------------------------------------------------------------------------------
    * @Description: class to store necessary data in the component.
    *-------------------------------------------------------------------------------
    * @param:       void
    * @return       void
    * @example WrapperBtnSanction wrapper = new WrapperBtnSanction()
    * ------------------------------------------------------------------------------
    */
    public class WrapperBtnSanction {
        /*
            @Description: String with a message to show in the front
        */
        public String gblDescriptionResponse {get;set;}
        /*
            @Description: String with a control value
        */
        public String typeMessage {get;set;}
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Method that saves the scope of sanction
    * -----------------------------------------------------------------------------------------------
    * @author  angel.fuertes2@bbva.com
    * @date    2019-06-20
    * @Method: Save the reason for the sanction
    * @param:  Arc_Gen_Delegation_Wrapper delegation wrapper
    * @param:  Map<String, String> data
    * @return an instance of Arc_Gen_Delegation_Wrapper
    * @example validateIndField(myFieldValue)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_Delegation_Wrapper saveScopeOfSanction(Arc_Gen_Delegation_Wrapper wrapper, Map<string,string> data) {
        Arc_Gen_Delegation_Wrapper wrapperRet = wrapper;
        try {
            Map<String, Object> fieldValueMap = new Map<String, Object>();
            fieldValueMap.put('arce__anlys_wkfl_sanction_rslt_type__c', data.get('sanction'));
            fieldValueMap.put('arce__anlys_wkfl_sanction_rsn_desc__c', data.get('descText'));
            fieldValueMap.put('arce__gf_committee_user_id__c', data.get('idUserSelected'));
            fieldValueMap.put('arce__analysis_risk_sanction_date__c', Date.valueOf(data.get('sancDate')));

            if (date.valueOf(data.get('sancdateCometee')) >= Date.today()) {
                fieldValueMap.put('arce__analysis_risk_expiry_date__c', Date.valueOf(data.get('sancdateCometee')));
            } else {
                throw new DmlException(Label.Arc_Gen_Generic_ErrorComiteeDate);
            }

            final WrapperBtnSanction wrapperBtnSanction = validateFields(Integer.valueOf(data.get('sanction')), data.get('recordId'));
            if (wrapperBtnSanction.typeMessage == SUCCESS) {
                final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(data.get('recordId'), new List<String>{ 'Id', 'Name', 'arce__anlys_wkfl_cnsld_ffss_type__c' });
                final arce__Analysis__c arceUp = arce.Arc_Gen_ArceAnalysis_Data.gerArce(data.get('recordId'));
                // Persist action into Oracle.
                arce.Arc_Gen_ActionsPersistence_Service.persistArceAction(wrapper.analysisId, getActionToPersist(Integer.valueOf(data.get('sanction'))));

                if (Integer.valueOf(data.get('sanction')) < THREE) {
                    changeRatings(data, arceUp);
                }
                // Update status and create traceability record.
                fieldValueMap = Arc_Gen_BtnSanction_service.updateAHABtnSanction(data, wrapper.analysisId, fieldValueMap);

                // Create current action traceability event record
                Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(wrapper, accHasAnalysis, arceUp, 'SANCTION');
                // Create current action workflow event record
                wkflWrapper.mapReqAction = fieldValueMap;
                wkflWrapper = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapper);

                // Save new changes Analysis
                arce.Arc_Gen_ArceAnalysis_Data.editAnalysisFields(wrapper.analysisId, fieldValueMap);

                sanctionTraceability(wrapper, data, accHasAnalysis);
                wrapperRet.codStatus = 200;
                wrapperRet.msgInfo = wrapperBtnSanction.gblDescriptionResponse;
                final String sanction = String.valueOf(fieldValueMap.get('arce__anlys_wkfl_sanction_rslt_type__c'));
                final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(UserInfo.getUserId());
                final String traceComments = Arc_Gen_BtnSanction_service.createTraceComments(sanction, fieldValueMap, wrpUser);
                final String sanctionLabel = arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Analysis__c', 'arce__anlys_wkfl_sanction_rslt_type__c', sanction);
                final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(sanctionLabel, 'sanction', traceComments.abbreviate(255), accHasAnalysis.Name);
                final Map<String, String> auditWF = new Map<String, String>();
                Arc_Gen_Traceability.saveTrace(wrapper.analysisId, auditAttr, auditWF);

                // Insert new trace record and last update
                Arc_Gen_TraceabilityEvents.updateTraceEvents(wkflWrapper);

                // Change stage to Finalized and status to Finalized Analysis when reason has values: Authorized without changes, Authorized with changes or Dismissed
                final Set<Integer> sanctionValues = new Set<Integer>{1,2,3};
                if (sanctionValues.contains(Integer.valueOf(data.get('sanction')))) {
                    saveTracePostSanction(wrapper, accHasAnalysis, fieldValueMap);
                }
            } else if (wrapperBtnSanction.typeMessage == ERROR) {
                wrapperRet.codStatus = 500;
                wrapperRet.msgInfo = wrapperBtnSanction.gblDescriptionResponse;
            }
        } catch(Exception ex) {
            wrapperRet.codStatus = 500;
            wrapperRet.msgInfo = ex.getMessage();
        }
        return wrapperRet;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Method create trace comments
    * -----------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date 2020-02-21
    * @param sanction : sanction ambit
    * @param fieldValueMap : Map<String, Object>
    * @param wrpUser : Wrapper of User
    * @return and string with the comments
    * @example validateFields(picklistValue)
    * -----------------------------------------------------------------------------------------------
    **/
    public static String createTraceComments(String sanction, Map<String, Object> fieldValueMap, arce.Arc_Gen_User_Wrapper wrpUser) {
        String traceComments;
        if (sanction == '1' || sanction == '2') {
            final Date sanctionDate = (Date) fieldValueMap.get('arce__analysis_risk_sanction_date__c');
            final Date expiryDate = (Date) fieldValueMap.get('arce__analysis_risk_expiry_date__c');
            final arce.Arc_Gen_User_Wrapper responsibleUser = arce.Arc_Gen_User_Locator.getUserInfo((String) fieldValueMap.get('arce__gf_committee_user_id__c'));

            traceComments = Label.Arc_Gen_SanctionDate + ': ' + sanctionDate.format() +
                    ' | ' + Label.Arc_Gen_ExpiryDateTrace + ': ' + expiryDate.format() +
                    ' | ' + Label.Arc_Gen_ResponsibleTrace + ': ' + responsibleUser.userBasicInfo.Name;
        } else if (sanction == '3' || sanction == '5') {
            traceComments = String.valueOf(fieldValueMap.get('arce__anlys_wkfl_sanction_rsn_desc__c'));
        } else if (sanction == '4' || sanction == '6') {
            final String ambitValue = (String) fieldValueMap.get(AMBIT_FIELD_NAME);
            final String ambitLabel = arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Analysis__c', AMBIT_FIELD_NAME, ambitValue);
            traceComments = 'Proposed to: ' + wrpUser.userBasicInfo.Name + ' | Ambit: ' + ambitLabel;
        }
        return traceComments;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Method that validates some fields in the analysis
    * -----------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-01-02
    * @param picklistValue -  value of the selected option in the combo box
    * @return an instance of Arc_Gen_BtnSanction_controller.WrapperBtnSanction
    * @example validateFields(picklistValue)
    * -----------------------------------------------------------------------------------------------
    **/
    public static WrapperBtnSanction validateFields(Integer picklistValue, String recordId) {
        WrapperBtnSanction wrp = new WrapperBtnSanction();
        final List<String> accHasIdLts = new List<String>();
        final List<arce__Account_has_Analysis__c> accHasLts = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId).arce__Analysis__c);
        for (arce__Account_has_Analysis__c accHasId: accHasLts) {
            accHasIdLts.add((String)accHasId.Id);
        }
        final  List<arce__Account_has_Analysis__c> accHasDataLts = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(accHasIdLts);

        // Does any proposal have changes?
        Boolean anyWithChanges = hasChanges(accHasDataLts);

        switch on picklistValue {
            // Authorize/Propose without changes
            when 1,6 {
                // Success if ALL proposals do not have changes. Fail if ANY proposal has changes.
                if (anyWithChanges) {
                    wrp.typeMessage = ERROR;
                    wrp.gblDescriptionResponse = Label.Arc_Gen_SanctionErrorMessage;
                } else {
                    wrp.typeMessage = SUCCESS;
                    wrp.gblDescriptionResponse = picklistValue == 1 ? Label.Arc_Gen_SanctionSuccessMessage : Label.Arc_Gen_Sanction;
                }
            }
            // Authorize/Propose with changes
            when 2,4 {
                // Success if ANY proposal has changes. Fail if ALL proposals don't have changes.
                if (anyWithChanges) {
                    wrp.typeMessage = SUCCESS;
                    wrp.gblDescriptionResponse = picklistValue == 2 ? Label.Arc_Gen_SanctionSuccessMessage : Label.Arc_Gen_Sanction;
                } else {
                    wrp.typeMessage = ERROR;
                    wrp.gblDescriptionResponse = Label.Arc_Gen_SanctionErrorMessage;
                }
            }
            // Return or dismiss
            when else {
                // No validation needed.
                wrp.typeMessage = SUCCESS;
                wrp.gblDescriptionResponse = Label.Arc_Gen_Sanction;
            }
        }
        return wrp;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Method logic in the account has analysis of the sanction button
    * -----------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date 2020-02-05
    * @param data -  Selected values
    * @param recordId -  record id analysis
    * @param map<string, object> map of fields
    * @return an instance of Arc_Gen_BtnSanction_controller.WrapperBtnSanction
    * @example validateFields(picklistValue)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> updateAHABtnSanction(Map<string,string> data, String recordId, Map<String, Object> mapFields) {
        final Integer sanction = Integer.valueOf(data.get('sanction'));
        Map<String, Object> mapFieldsRet = mapFields;
        switch on sanction {
            when 1,2,3 {
                mapFieldsRet.put('arce__wf_status_id__c', FINALIZED_ANALYSIS);
                mapFieldsRet.put('arce__Stage__c', '3');
            }
            when 4,6 {
                final String ambit = data.get('ambit');
                final String idUser = Arc_Gen_Propose_Helper.initIdentification(ambit, recordId);
                mapFieldsRet.put('arce__wf_status_id__c', CONTRASTING_ANALYSIS);
                mapFieldsRet.put('OwnerId', idUser);
                if (arce.Arc_Gen_ValidateInfo_utils.isFilled(ambit)) {
                    mapFieldsRet.put(AMBIT_FIELD_NAME, ambit);
                }
            }
            when 5 {
                final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
                mapFieldsRet.put('arce__wf_status_id__c', CONTRASTING_ANALYSIS);
                mapFieldsRet.put('OwnerId', Arc_Gen_Propose_Helper.initIdentification(wrpUser.ambitUser, recordId));
            }
        }
        return mapFieldsRet;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Method that returns list of users
    * -----------------------------------------------------------------------------------------------
    * @author  luisruben.quinto.munoz@bbva.com
    * @date 2019-10-21
    * @Method:      searchUser
    * @param:       String inputTerm for search
    * @return an instance of List<map<String,String>>
    * @example validateIndField(myFieldValue)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<map<String,String>> searchUser(String inputTerm) {
        List<map<String,String>> ltsUsers = new list<map<String,String>>();
        final List<arce.Arc_Gen_User_Wrapper> lstWrap = arce.Arc_Gen_User_Locator.getUsers(inputTerm);
        for (arce.Arc_Gen_User_Wrapper wrap : lstWrap) {
            ltsUsers.add(new map<String,String>{'nameUser' => wrap.userBasicInfo.Name, 'perfilUser' => wrap.profileName, 'idUser' => wrap.userBasicInfo.Id});
        }
        return ltsUsers;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Method that returns the action to persist in the actionPersist API
    * -----------------------------------------------------------------------------------------------
    * @author  joseluis.garcia4.contractor@bbva.com
    * @date    2021-06-16
    * @params  String sanctionType The type of sanction
    * @return  The action to persist in the API
    * -----------------------------------------------------------------------------------------------
    **/
    private static String getActionToPersist(Integer sanctionType) {
        String action = '';
        switch on sanctionType {
            when 1,2 {
                action = arce.Arc_Gen_ActionsPersistence_Service.ACTION_SANCTION;
            }
            when 4,6 {
                action = arce.Arc_Gen_ActionsPersistence_Service.ACTION_PROPOSE;
            }
            when 3 {
                action = arce.Arc_Gen_ActionsPersistence_Service.ACTION_DISCARD;
            }
            when 5 {
                action = arce.Arc_Gen_ActionsPersistence_Service.ACTION_RETURN;
            }
        }
        return action;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Method that evaluates changes
    * -----------------------------------------------------------------------------------------------
    * @author  javier.soto.carrascosa@bbva.com
    * @date 2020-04-02
    * @Method:      searchUser
    * @param:       List<arce__Account_has_Analysis__c> accHasDataLts
    * @return boolean
    * @example hasChanges(List<arce__Account_has_Analysis__c> accHasDataLts)
    * -----------------------------------------------------------------------------------------------
    **/
    private static boolean hasChanges(List<arce__Account_has_Analysis__c> accHasDataLts) {
        Boolean anyWithChanges = false;
        for (arce__Account_has_Analysis__c accAnalysis : accHasDataLts) {
            if (accAnalysis.arce__prop_int_mod_rec_type__c == YES) {
                anyWithChanges = true;
                break;
            }
        }
        return anyWithChanges;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Method saves traceability
    * -----------------------------------------------------------------------------------------------
    * @author  javier.soto.carrascosa@bbva.com
    * @date 2020-05-31
    * @Method:      searchUser
    * @param:       String inputTerm for search
    * @return an instance of List<map<String,String>>
    * @example validateIndField(myFieldValue)
    * -----------------------------------------------------------------------------------------------
    **/
    private static void sanctionTraceability(Arc_Gen_Delegation_Wrapper wrapper, Map<string,string> data, arce__Account_has_Analysis__c accHasAnalysis) {
        string stage = '';
        string titulo = '';
        String ambitSelected = '';
        final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(New List<Id>{wrapper.analysisId})[0];
        switch on Integer.valueOf(data.get('sanction')) {
            when 1, 2, 3 {
                stage = ' | ' + System.Label.Arc_Gen_ExecRepStg + ' : ' + System.Label.Arc_Gen_Stage_03 + ' | ' + System.Label.Arc_Gen_TraceabilityMotivo + ' : ' + arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Analysis__c', 'arce__anlys_wkfl_sanction_rslt_type__c', data.get('sanction'));
                titulo = Label.Arc_Gen_Traceability_10;
            }
            when 4, 6, 5 {
                stage = ' | ' + System.Label.Arc_Gen_ExecRepStg + ' : ' + System.Label.Arc_Gen_Traceability_04 + ' | ' + System.Label.Arc_Gen_TraceabilityMotivo + ' : ' + arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Analysis__c', 'arce__anlys_wkfl_sanction_rslt_type__c', data.get('sanction'));
                titulo = Label.Arc_Gen_Traceability_04;
            }
        }
        if (data.get('ambit') != null) {
            ambitSelected = ' | ' + System.Label.Arc_Gen_TraceabilityAmbit + ': ' + arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Analysis__c', 'arce__anlys_wkfl_edit_br_level_type__c', data.get('ambit'));
        }
        final String comments = ' |' +  System.Label.Arc_Gen_FacultedCometee + ':' + arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Analysis__c', 'arce__bbva_committees_type__c', arceVar.arce__bbva_committees_type__c) + ' | ' +  System.Label.Arc_Gen_SanctionDate + ':' + data.get('sancDate') + ' | ' + System.Label.Arc_Gen_SancdateCometee + ':' + data.get('sancdateCometee') + ambitSelected + stage;
        final Map<String, String> addInfo = Arc_Gen_Traceability.genAuditWF('', stage, '', '');
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(titulo, 'sanction', comments.abbreviate(255), accHasAnalysis.Name);
        Arc_Gen_Traceability.saveTrace(wrapper.analysisId, auditAttr, addInfo);
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Method that updates ratings for all members from one analysis
    * -----------------------------------------------------------------------------------------------
    * @author  carlos.pisador.contractor@bbva.com
    * @date 2021-02-23
    * @Method:      changeRatings
    * @param:       Map<string,string> data
    * @return void
    * @example changeRatings(Map<string,string> data)
    * -----------------------------------------------------------------------------------------------
    **/
    public static void changeRatings(Map<string,string> data, arce__Analysis__c relatedAnlys) {
        final List<String> analysisId = new List<String>();
        final List<sObject> toUpdateLst = new List<sObject>();
        final arce.Arc_Gen_RatingGlobal_data dataAccess = new arce.Arc_Gen_RatingGlobal_data();

        analysisId.add(String.valueOf(relatedAnlys.Id));
        final List<arce__Account_has_Analysis__c> ahaLst = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(analysisId);

        final List<arce__rating__c> ratings = Arc_Gen_ValidateRating_service.changeRatingsData(ahaLst);
        toUpdateLst.addAll(ratings);
        dataAccess.updateRecords(new List<sObject>(toUpdateLst));
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Saves traceability record after to analysis saved
    * -----------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    2021-10-18
    * @param   Arc_Gen_Delegation_Wrapper wrapper
    * @param   arce__Account_has_Analysis__c accHasAnalysis
    * @param   Map<String, Object> fieldValueMap
    * @return  void
    * @example saveTracePostSanction(wrapper, accHasAnalysis, fieldValueMap);
    * -----------------------------------------------------------------------------------------------
    **/
    private static void saveTracePostSanction(Arc_Gen_Delegation_Wrapper wrapper, arce__Account_has_Analysis__c accHasAnalysis, Map<String, Object> fieldValueMap) {
        final arce__Analysis__c arceUpPost = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysis.Id);
        // Create current action traceability event record
        Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapperPost = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(wrapper, accHasAnalysis, arceUpPost, 'SANCTION');
        wkflWrapperPost.mapReqAction = fieldValueMap;
        wkflWrapperPost = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapperPost);
        Arc_Gen_TraceabilityEvents.updateTraceEvents(wkflWrapperPost);
    }
}