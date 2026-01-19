/**
* @File Name          : Arc_Gen_ReturnButton_service.cls
* @Description        : Return an ARCE to the before status.
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 01-22-2024
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    3/5/2019 13:47:37   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    20/11/2019 13:47:37   javier.soto.carrascosa@bbva.com               Reference user interface
* 1.2    10/12/2019 12:47:40   juanmanuel.perez.ortiz.contractor@bbva.com    Add logic to return ARCE
* 1.3    26/12/2019 14:52:11   juanmanuel.perez.ortiz.contractor@bbva.com    Add logic to send notifications
* 1.4    28/02/2020 09:20:00   juanignacio.hita.contractor@bbva.com          Added traceability to "evaluateIdentification"
* 1.5    14/04/2020 11:43:00   juanignacio.hita.contractor@bbva.com          Added raip process and moved constant variables to GenericUtilities
* 1.6    20/05/2020 12:00:00   juanignacio.hita.contractor@bbva.com          Added traceability for RAIP
* 1.7    04/06/2020 11:00:00   juanignacio.hita.contractor@bbva.com          Changed conditional for subprocess type in the identification evaluation
* 1.8    08/06/2020 12:00:00   juanignacio.hita.contractor@bbva.com          Removed the validation of creation scope and moved after the call to the init delegation.
*                                                                            Added validation of ambits list that depend message traceability schedule.
* 1.9    04/12/2020 12:00:00   juanignacio.hita.contractor@bbva.com          Adds aha name (analysisId) param in traceability record
* 1.10   12/02/2021 13:00:00   juanignacio.hita.contractor@bbva.com          Add traceability events funcionality in the workflow
* 1.11   18/02/2021 10:00:00   joseluis.garcia4.contractor@bbva.com          Include call to action persistence service.
* 1.12   20/02/2021 10:00:00   juanignacio.hita.contractor@bbva.com          Add control of the number of different users involved in the Sanction stage
* 1.13   25/03/2021 12:00:00   juanignacio.hita.contractor@bbva.com          Change logic of valAfterInitDelegation ambit method
* 1.14   29/12/2021 14:00:00   saimassimilianno.jordana.contractor@bbva.com  setTraceability meth0d modified, and use the correct userId in
*                                                                            evaluateIdentification meth0d.
* 1.15   30/03/2022 17:00:00   francisco.munoz.torres.contractor@bbva.com    Set owner on RAIP process
* 1.16   04/04/2022 11:30:00   francisco.munoz.torres.contractor@bbva.com    Change traceability user
* 1.17   05/04/2022 11:30:00   francisco.munoz.torres.contractor@bbva.com    Bugfix returning RAIP
**/
public without sharing class Arc_Gen_ReturnButton_service {
    /**
    * @Description : Variable status schedule action workflow delegation
    */
    static final String STAGE_FIELD = 'arce__Stage__c';
    /**
    * @Description : Variable status schedule action workflow delegation
    */
    static final String STATUS_FIELD = 'arce__wf_status_id__c';
    /**
    * @Description : Variable schedule action
    */
    static final String ACTION_SCHEDULE = 'Arc_Gen_Schedule';
    /**
    * @Description : Variable ownerId
    */
    static final String OWNER_ID = 'OwnerId';
    /**
    *-------------------------------------------------------------------------------
    * @description Empty priavate constructor
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 2019-05-13
    * @example private Arc_Gen_ReturnButton_controller ()
    **/
    @TestVisible
    private Arc_Gen_ReturnButton_service () {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that evaluate identification funcionality
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-01-20
    * @param   String accHasAnalysisId
    * @param   Object wrapper
    * @param   String userId
    * @param   String reason
    * @return  Arc_Gen_Delegation_Wrapper
    * @example public Arc_Gen_Delegation_Wrapper evaluateIdentification(accHasAnalysisId, wrapper, userId, reason);
    **/
    public static Arc_Gen_Delegation_Wrapper evaluateIdentification(Id accHasAnalysisId, Object wrapper, String userId, String reason) {
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        final arce__Analysis__c arceAnalysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
        final arce.Arc_Gen_User_Wrapper wrpUserCurrent = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(arceAnalysis.CreatedById);

        Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapper, Arc_Gen_Delegation_Wrapper.class);
        final Map<String, Object> fieldValueMap = new Map<String, Object>();

        // Persist action into Oracle.
        arce.Arc_Gen_ActionsPersistence_Service.persistArceAction(wrapperSerialize.analysisId, arce.Arc_Gen_ActionsPersistence_Service.ACTION_RETURN);

        // Update status and create traceability record.
        fieldValueMap.put('arce__anlys_wkfl_return_reason_desc__c', reason);
        fieldValueMap.put('arce__anlys_wkfl_edit_br_level_type__c', wrapperSerialize.lstAmbits[0].get('value'));

        if (arceAnalysis.arce__anlys_wkfl_sub_process_type__c == arce.Arc_Gen_Constants.SUBPROCESS_RATING) {
            fieldValueMap.putAll(evaluateRAIP(arceAnalysis, userId));
        } else {
            if (wrpUserCurrent.ambitUser == wrapperSerialize.lstAmbits[0].get('value')) {
                fieldValueMap.put(STATUS_FIELD, arce.Arc_Gen_Constants.STATUS_CONTRASTING_ANALYSIS);
                fieldValueMap.put(OWNER_ID, userId);
                wrapperSerialize.codStatus = serviceMessage.CODE_200;
            } else {
                if (wrpUser.ambitUser == wrapperSerialize.lstAmbits[0].get('value')) {
                    fieldValueMap.put(STAGE_FIELD, arce.Arc_Gen_Constants.STAGE_IN_PREPARATION);
                    fieldValueMap.put(STATUS_FIELD, arce.Arc_Gen_Constants.STATUS_PREPARING_ANALYSIS);
                    fieldValueMap.put(OWNER_ID, userId);
                    wrapperSerialize.codStatus = serviceMessage.CODE_200;
                } else {
                    fieldValueMap.put(STATUS_FIELD, arce.Arc_Gen_Constants.STATUS_CONTRASTING_ANALYSIS);
                    fieldValueMap.put(OWNER_ID, userId);
                    wrapperSerialize.codStatus = serviceMessage.CODE_200;
                }
            }
        }

        arce.Arc_Gen_ArceAnalysis_Data.editAnalysisFields(arceAnalysis.Id, fieldValueMap);
        if (wrapperSerialize.codStatus == serviceMessage.CODE_200) {
            final String proposingUser = arceAnalysis.arce__anlys_wkfl_prev_user_name__c;
            try {
                final List<User> userPropuesto = new List<User>();
                user newUser = new user();
                newUser.id = proposingUser;
                userPropuesto.add(newUser);
                sendNotifications(arceAnalysis.Id, userPropuesto);
            } catch (Exception e) {
                System.debug('Error notificactions');
            }
            setTraceability(arceAnalysis, reason, proposingUser, accHasAnalysisId);
        }

        // Create current action traceability event record
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(accHasAnalysisId, new List<String>{ 'Id', 'Name', 'arce__anlys_wkfl_cnsld_ffss_type__c' });
        Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(wrapperSerialize, accHasAnalysis, arceAnalysis, 'RETURN');
        wkflWrapper.mapReqAction = fieldValueMap;
        wkflWrapper = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapper);

        // Insert new trace record and last update
        Arc_Gen_TraceabilityEvents.updateTraceEvents(wkflWrapper);

        return wrapperSerialize;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that set stage and status RAIP
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-01-20
    * @param   arce__Analysis__c arceAnalysis
    * @return  Map<String, Object>
    * @example Map<String, Object> mapObj = evaluateRAIP(arceAnalysis);
    **/
    public static Map<String, Object> evaluateRAIP(arce__Analysis__c arceAnalysis, String userId) {
        Map<String, Object> fieldValueMap = new Map<String, Object>();
        if (arceAnalysis.arce__rating_prerating_type__c == arce.Arc_Gen_Constants.RATING_TYPE || arceAnalysis.arce__is_RTC__c) {
            fieldValueMap.put(STATUS_FIELD, arce.Arc_Gen_Constants.RAIP_STATUS_PREPARING);
            fieldValueMap.put(STAGE_FIELD, arce.Arc_Gen_Constants.STAGE_IN_PREPARATION);
            fieldValueMap.put(OWNER_ID, userId);
        }
        return fieldValueMap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description setTraceability
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-01-20
    * @param   arce__Analysis__c arceAnalysis
    * @param   String reason
    * @param   String userId
    * @return  void
    * @example setTraceability(arceAnalysis, reason, userId);
    **/
    public static void setTraceability(arce__Analysis__c arceAnalysis, String reason, String userId, Id accHasAnalysisId) {
        arce.Arc_Gen_GenericUtilities.createNotifications(Arc_Gen_Notifications_Service.getUsersIds(arceAnalysis.Id), arceAnalysis.Id, System.Label.Arc_Gen_ArceReturn + ': ' + arceAnalysis.Name);
        final arce.Arc_Gen_User_Wrapper targetUser = arce.Arc_Gen_User_Locator.getUserInfo(userId);
        final string traceComments = Label.Arc_Gen_ReturnToTrace + ': ' + targetUser.userBasicInfo.Name.abbreviate(60) + ' | ' + Label.Cls_arce_ReturnReason + ' ' + reason;
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(accHasAnalysisId, new List<String>{ 'Id', 'Name' });
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Cls_arce_ReturnTo, 'sendBack', traceComments.abbreviate(255), accHasAnalysis.Name);
        final Map<String, String> auditWF = new Map<String, String>();
        Arc_Gen_Traceability.saveTrace(arceAnalysis.Id, auditAttr, auditWF);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Validations after the call to the init delegation. The response of the validations is added in delegation wrapper.
    *-------------------------------------------------------------------------------
    * @author   juanignacio.hita.contractor@bbva.com
    * @date     2020-06-08
    * @Method   valAfterInitDelegation
    * @param    wrapper : Delegation wrapper object
    * @param    analysis : arce__Analysis__c object
    * @return   void
    * @example  Arc_Gen_ReturnButton_service.validations(wrapper);
    */
    public static void valAfterInitDelegation(Arc_Gen_Delegation_Wrapper wrapper, arce__Analysis__c analysis) {
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        // Validation 1 : If there is more than one scope in the ambit list of delegation wrapper
        if (wrapper.lstAmbits.size() > 1) {
            wrapper.codStatus = serviceMessage.CODE_500;
            wrapper.msgInfo = System.Label.Arc_Gen_ReturnErrorAmbitList;
        } else {
            // Check if it has been scheduled for analysis before
            if (!Arc_Gen_Traceability_locator.getActionAuditBtn(wrapper.analysisId, ACTION_SCHEDULE).isEmpty()) {
                wrapper.codStatus = serviceMessage.CODE_500;
                wrapper.msgInfo = System.Label.Arc_Gen_ReturnError;
            }
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that sets the arce__Analysis__c with the new values of the propose
    --------------------------------------------------------------------------------
    * @param String arceId - Standard Id of the arce__Analysis__c
    * @param List<User> usuarios - List of User
    * @return arce__Analysis__c - ARCE record ready to update
    * @example arce__Analysis__c arce = Arc_GBL_RAIP_Propose_Locator.sendNotifications(Id arceId)
    **/
    private static void sendNotifications(Id arceId, List<User> usuarios) {
        final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{arceId})[0];
        arce.Arc_Gen_GenericUtilities.createNotifications(usuarios, arceId, System.Label.Arc_Gen_ArceReturn + ': ' + arceVar.Name);
    }
}