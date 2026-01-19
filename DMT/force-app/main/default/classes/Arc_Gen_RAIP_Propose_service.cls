/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RAIP_Propose_controller
* @Author   eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 14/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Controller class to propose an independent rating
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-11-15 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation
* |2019-03-31 juanignacio.hita.contractor@bbva.com
*             Refactoring to integrate workflow interface
* |2020-05-20 juanignacio.hita.contractor@bbva.com
*             Added traceability for RAIP
* |2020-06-05 juanignacio.hita.contractor@bbva.com
*             Changed text traceability messages for RAIP
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-04 juanignacio.hita.contractor@bbva.com
*             Adds aha name (analysisId) param in traceability record
* |2021-02-19 joseluis.garcia4.contractor@bbva.com
*             Include call to action persistence service.
* |2021-03-03 juanignacio.hita.contractor@bbva.com
*             Adds traceability event funcionality to the action, refactor setArceValues
* |2021-04-07 joseluis.garcia4.contractor@bbva.com
*             Change references to Arc_Gen_RatingGlobal_* classes.
* |2021-01-03 saimassimilianno.jordana.contractor@bbva.com
*             setTraceability meth0d modified to show the new version.

* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_RAIP_Propose_service {
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		27/01/2020
    * @author	eduardoefrain.hernandez.contractor@bbva.com
    */
    @testVisible
    private Arc_Gen_RAIP_Propose_service() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that sets the arce__Analysis__c with the new values of the propose
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 19/02/2020
    * @param String arceId - Standard Id of the arce__Analysis__c
    * @return arce__Analysis__c - ARCE record ready to update
    * @example arce__Analysis__c arce = Arc_GBL_RAIP_Propose_Locator.setArceValues(arceId, selectedAmbit);
    **/
    public static arce.Arc_Gen_RatingGlobal_data.SaveResult toPropose(Id arceId, String userId, String selectedAmbit, arce__Account_has_Analysis__c aha) {
        final arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data();

        // Persist action into Oracle.
        arce.Arc_Gen_ActionsPersistence_Service.persistArceAction(arceId, arce.Arc_Gen_ActionsPersistence_Service.ACTION_PROPOSE);

        // Update status and create traceability record.
        final arce__Analysis__c arceObj = arce.Arc_Gen_ArceAnalysis_Data.gerArce(aha.Id);
        final arce__Analysis__c arce = setArceValues(arceObj, userId, selectedAmbit);
        final arce__rating__c arceRating = setRatingValues(aha);
        final arce.Arc_Gen_RatingGlobal_data.SaveResult response = locator.updateRecords(new List<sObject>{arce,arceRating});
        if (response.status == 'true') {
            try {
                final List<User> userPropuesto = new List<User>();
                user newUser = new user();
                newUser.id = userId;
                userPropuesto.add(newUser);
                sendNotifications(arceId, userPropuesto);
            } catch (Exception e) {
                System.debug('Error notificactions');
            }
            final String actionAuditType = aha.arce__RAR_rating_tool_id__c == '2021RTC_NBF' ? 'Arc_IFIS_Traceability' : 'Arc_Gen_Traceability' ;
            setTraceability(arceId, selectedAmbit, arce.OwnerId, aha.Name, actionAuditType);

            final Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wkflWrapper = new Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper(null, aha, arceObj, 'PROPOSE-IRP');
            wkflWrapper.mapReqAction =  new Map<String, Object> {
                'arce__anlys_wkfl_edit_br_level_type__c' => selectedAmbit,
                'arce__anlys_wkfl_prev_user_name__c' => arce.OwnerId,
                'arce__proposeUser__c' => userId
            };
            final Arc_Gen_TraceabilityEvents.Arc_Gen_Traceability_Wrapper wrapper = Arc_Gen_TraceabilityEvents.saveTraceEvent(wkflWrapper);
            Arc_Gen_TraceabilityEvents.updateTraceEvents(wrapper);
        }
        return response;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that sets the arce__Analysis__c with the new values of the propose
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 19/02/2020
    * @param String arceId - Standard Id of the arce__Analysis__c
    * @param String selectedAmbit
    * @return arce__Analysis__c - ARCE record ready to update
    * @example arce__Analysis__c arce = Arc_GBL_RAIP_Propose_Locator.setArceValues(arceId, selectedAmbit);
    **/
    private static arce__Analysis__c setArceValues(arce__Analysis__c arceObj, String userId, String selectedAmbit) {
        final arce__Analysis__c upArce = new arce__Analysis__c(Id = arceObj.Id);
        upArce.put('arce__anlys_wkfl_edit_br_level_type__c', selectedAmbit);
        upArce.put('arce__wf_status_id__c', arce.Arc_Gen_Constants.RAIP_STATUS_CONTRASTING);
        upArce.put('arce__Stage__c', arce.Arc_Gen_Constants.STAGE_IN_SANCTION);
        upArce.put('arce__anlys_wkfl_prev_user_name__c', arceObj.OwnerId);
        upArce.put('OwnerId', userId);
        upArce.put('arce__proposeUser__c', System.UserInfo.getUserId());
        return upArce;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method that sets the arce__Analysis__c with the new values of the propose
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 19/02/2020
    * @param String arceId - Standard Id of the arce__Analysis__c
    * @return arce__Analysis__c - ARCE record ready to update
    * @example arce__Analysis__c arce = Arc_GBL_RAIP_Propose_Locator.sendNotifications(Id arceId)
    **/
    private static void sendNotifications(Id arceId, List<User> usuarios) {
        final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{arceId})[0];
        arce.Arc_Gen_GenericUtilities.createNotifications(usuarios, arceId, System.Label.Arc_Gen_ArcePropose + ': ' + arceVar.Name);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getAccountInfoById" that retrieves full user information from a list of account Id
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 14/02/2020
    * @param String accHasAnalysisId - Standard Id of the arce__Account_has_Analysis__c
    * @param String selectedAmbit
    * @param String assignedUser
    * @return arce__Analysis__c - ARCE record ready to update
    * @example String arce = Arc_Gen_RAIP_Propose_Controller.validateRating(accHasAnalysisId);
    **/
    private static void setTraceability(String arceId, String selectedAmbit, String assignedUser, String analysisId, String actionAuditType) {
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(assignedUser);
        final String strAmbit = DES_Arc_GBL_Workflow_Helper.gtDescriptionAmbit(selectedAmbit);
        final string traceComments = System.Label.Arc_Gen_Traceability_Propose_RAIP + ' ' + wrpUser.userBasicInfo.Name.abbreviate(60) + ' | ' + System.Label.Arc_Gen_TraceabilityAmbit + ': ' + strAmbit;
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_Traceability_12, 'sendBack', traceComments.abbreviate(255), analysisId, actionAuditType);
        final Map<String, String> auditWF = Arc_Gen_Traceability.genAuditWF(selectedAmbit, arce.Arc_Gen_Constants.STAGE_IN_SANCTION, arce.Arc_Gen_Constants.RAIP_STATUS_CONTRASTING, '');
        Arc_Gen_Traceability.saveTrace(arceId, auditAttr, auditWF);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method that sets the arce__rating__c with the new values of the propose
    --------------------------------------------------------------------------------
    * @author alberto.martinez.carrero.contractor@bbva.com
    * @date 04/04/2022
    * @param arce__Account_has_Analysis__c aha - account has analysis
    * @return arce__rating__c - rating to update
    **/
    private static arce__rating__c setRatingValues(arce__Account_has_Analysis__c aha) {
        final Id idRating = aha.arce__ffss_for_rating_id__r.arce__rating_id__c;
        final arce__rating__c arceRating = new arce__rating__c();
        arceRating.put('Id', idRating);
        arceRating.put('arce__final_rating_after_propose__c', aha.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__total_rating_score_number__c);
        arceRating.put('arce__rating_standalone_after_prop__c', aha.arce__total_rating_score_number__c);
        return arceRating;
    }

}