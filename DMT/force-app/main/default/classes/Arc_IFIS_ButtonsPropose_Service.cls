/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsPropose_Service
* @Author         marcos.gimeno.next@bbva.com
* @Date           28-08-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Service class to propose IFIS rating.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 28-08-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
public with sharing class Arc_IFIS_ButtonsPropose_Service {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Main method with the logic of the rating proposal process.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    analysisId       ID of the Analysis__c record
    * @param    selectedAmbit    Selected ambit
    * @param    aha              Account_has_Analysis__c record
    * @return   DML update result
    * @example  arce.Arc_Gen_RatingGlobal_data.SaveResult e = toPropose(arceId, selectedAmbit, aha)
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_RatingGlobal_data.SaveResult toPropose(
        Id analysisId,
        String selectedAmbit,
        String currentUserId,
        arce__Account_has_Analysis__c aha
    ) {
        final arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data();

        final String userId = UserInfo.getUserId();
        // Update status and create traceability record
        final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(aha.Id);
        final arce__Analysis__c analysisToUpd = setAnalysisValues(analysis, userId, selectedAmbit);
        final arce__rating__c ratingToUpd = setRatingValues(aha);

        final arce.Arc_Gen_RatingGlobal_data.SaveResult response = locator.updateRecords(
            new List<sObject>{ analysisToUpd, ratingToUpd }
        );
        if (response.status == 'true') {
            arce.Arc_IFIS_Buttons_Helper.sendNotifications(analysisId, System.Label.arce.Arc_IFIS_Notification_Propose);
            setTraceability(analysisId, selectedAmbit, currentUserId);
        }

        return response;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description This method gets the rating data for a given Aha record and returns it as a
    *              Arc_IFIS_Buttons_Wrp.ValidateResponse object.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    ahaId arce__Account_has_Analysis__c record
    * @param    buttonType Type of button that triggers the action
    * @return   The modified response object for validated operations.
    * @example  Arc_IFIS_Buttons_Wrp.ValidateResponse e = getRatingData(aha)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Arc_IFIS_Buttons_Wrp.ValidateResponse getRatingData(
        arce__Account_has_Analysis__c aha,
        String buttonType
    ) {
        Arc_IFIS_Buttons_Wrp.ValidateResponse response;
        final Map<String, Object> data = new Map<String, Object>();
        String message = arce.Arc_IFIS_Buttons_Helper.DEFAULT_MESSAGE;

        try {
            arce.Arc_Gen_RatingGlobal_data locator = new arce.Arc_Gen_RatingGlobal_data();
            final arce__Account_has_Analysis__c ahaRating = locator.getAccountHasAnalysis(aha.Id)[0];

            message = checkRatingValid(ahaRating, message, buttonType);
            data.putAll(getRatingDataMap(ahaRating, message));
            //response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(data, true, null);
            response = new Arc_IFIS_Buttons_Wrp.ValidateResponse(data, true, null);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return response;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Gets the rating data for a given Aha record and returns it as a Map.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.next@bbva.com
    * @date        26-02-2024
    * @param       ahaRating arce__Account_has_Analysis__c record
    * @param       message Message to show
    * @return      Map with rating data
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> getRatingDataMap(arce__Account_has_Analysis__c ahaRating, String message) {
        final Map<String, Object> data = new Map<String, Object>();
        data.put('subProcessType', ahaRating.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c);
        data.put('ratingId', ahaRating.arce__ffss_for_rating_id__r.arce__rating_id__c);
        data.put('recalculateRating', message);
        return data;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Checks if the recalculate rating value is valid and returns a message.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.next@bbva.com
    * @date        26-02-2024
    * @param       ahaRating arce__Account_has_Analysis__c record
    * @param       message Message to show
    * @param       buttonType Type of button that triggers the action
    * @return      Message to show
    * -----------------------------------------------------------------------------------------------
    **/
    private static String checkRatingValid(arce__Account_has_Analysis__c ahaRating, String message, String buttonType) {
        final Map<String, String> labelByType = new Map<String, String>{
            'PROPOSAL' => System.Label.arce.Arc_Gen_RecalcRatWarning,
            arce.Arc_Gen_RatingGlobal_Constants.FINALIZATION => System.Label.arce.Arc_Gen_RecalcRatWarningPre,
            arce.Arc_Gen_RatingGlobal_Constants.RATINGVAL => System.Label.arce.Arc_Gen_RecalcRatWarningVal
        };

        if (ahaRating.arce__recalculate_rating__c != null && ahaRating.arce__recalculate_rating__c != '4') {
            Map<String, String> mapa = arce.Arc_Gen_GenericUtilities.getMapLabelFromValue(
                'arce__Account_has_Analysis__c',
                'arce__recalculate_rating__c'
            );
            if (!mapa.isEmpty() && mapa.get(ahaRating.arce__recalculate_rating__c) != null) {
                String recalc = mapa.get(ahaRating.arce__recalculate_rating__c).toLowerCase();
                message = labelByType.get(buttonType) + ' ' + recalc;
            }
        }

        return message;
    }
    
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Sets the arce__Analysis__c with the new values of the propose.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    analysis         Analysis__c record
    * @param    userId           Current user ID
    * @param    selectedAmbit    Selected ambit
    * @return   arce__Analysis__c object with new values
    * @example  arce__Analysis__c e = setAnalysisValues(analysis, userId, selectedAmbit)
    * -----------------------------------------------------------------------------------------------
    **/
    private static arce__Analysis__c setAnalysisValues(
        arce__Analysis__c analysis,
        String userId,
        String selectedAmbit
    ) {
        final arce__Analysis__c analysisToUpd = new arce__Analysis__c(Id = analysis.Id);
        analysisToUpd.put('arce__anlys_wkfl_edit_br_level_type__c', selectedAmbit);
        analysisToUpd.put('arce__wf_status_id__c', arce.Arc_Gen_Constants.RAIP_STATUS_CONTRASTING);
        analysisToUpd.put('arce__Stage__c', arce.Arc_Gen_Constants.STAGE_IN_SANCTION);
        analysisToUpd.put('arce__anlys_wkfl_prev_user_name__c', analysis.OwnerId);
        analysisToUpd.put('OwnerId', userId);
        analysisToUpd.put('arce__proposeUser__c', userId);
        return analysisToUpd;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Sets the arce__rating__c with the new values of the propose.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    aha    Account_has_Analysis__c record
    * @return   arce__rating__c object with new values
    * @example  arce__rating__c e = setRatingValues(aha)
    * -----------------------------------------------------------------------------------------------
    **/
    private static arce__rating__c setRatingValues(arce__Account_has_Analysis__c aha) {
        final Id ratingId = aha.arce__ffss_for_rating_id__r.arce__rating_id__c;
        final arce__rating__c ratingToUpd = new arce__rating__c();
        ratingToUpd.put('Id', ratingId);
        ratingToUpd.put(
            'arce__final_rating_after_propose__c',
            aha.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__total_rating_score_number__c
        );
        ratingToUpd.put('arce__rating_standalone_after_prop__c', aha.arce__total_rating_score_number__c);
        return ratingToUpd;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Creates the traceability event for the rating button.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    analysisId       ID of the Analysis__c record
    * @param    selectedAmbit    Selected ambit
    * @param    assignedUser     Assigned user
    * @return   void
    * @example  setTraceability(analysisId, selectedAmbit, assignedUser, analysisId)
    * -----------------------------------------------------------------------------------------------
    **/
    private static void setTraceability(String analysisId, String selectedAmbit, String assignedUser) {
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(assignedUser);
        final String strAmbit = arce.Arc_Gen_GenericUtilities.getLabelFromValue(
            'arce__Analysis__c',
            'arce__anlys_wkfl_edit_br_level_type__c',
            selectedAmbit
        );
        final string traceComments =
            System.Label.arce.Arc_IFIS_Traceability_Propose +
            ' ' +
            wrpUser.userBasicInfo.Name.abbreviate(60) +
            ' | ' +
            System.Label.arce.Arc_IFIS_Traceability_Ambit +
            ': ' +
            strAmbit;

        final arce.Arc_IFIS_Traceability.AuditWF auditWFWrap = new arce.Arc_IFIS_Traceability.AuditWF();
        auditWFWrap.ambit = selectedAmbit;
        auditWFWrap.stage = arce.Arc_Gen_Constants.STAGE_IN_SANCTION;
        auditWFWrap.status = arce.Arc_Gen_Constants.RAIP_STATUS_CONTRASTING;
        auditWFWrap.action = '';

        arce.Arc_IFIS_Traceability.saveStatusEvent(
            analysisId,
            'Proposed',
            traceComments.abbreviate(255),
            arce.Arc_IFIS_Traceability.genAuditWF(auditWFWrap)
        );
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Set arce__recalculate_rating__c field value
    * -----------------------------------------------------------------------------------------------
    * @autor       joseluis.miralles.contractor@bbva.com
    * @date        08/02/2024
    * @param       aha Id of the Account_has_Analysis__c record
    * @param       value Value to set
    * @return      SaveResult object
    * @example     arce.Arc_IFIS_ButtonsPropose_Service.setRecalculateRatingValue(ahaId, value)
    * -----------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_GenericUtilities.SaveResult setRecalculateRatingValue(Id ahaId, String value) {
        final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(
            new List<String>{ ahaId }
        )[0];
        aha.arce__recalculate_rating__c = value;
        return arce.Arc_Gen_GenericUtilities.updateRecords(new List<arce__Account_has_Analysis__c>{ aha });
    }
}