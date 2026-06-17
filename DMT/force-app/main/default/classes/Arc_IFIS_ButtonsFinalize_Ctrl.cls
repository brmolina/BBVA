/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsFinalize_Ctrl
* @Author         marcos.gimeno.contractor@bbva.com
* @Date           25-05-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Controller class for finalize rating process.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.contractor@bbva.com
* 25-05-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@SuppressWarnings('PMD.AvoidGlobalModifier,sf:PreserveStackTrace,sf:OnlyOneReturn')
public with sharing class Arc_IFIS_ButtonsFinalize_Ctrl {
    /**
    * @description Constant with the status in progress
    **/
    static final String STATUS_PROGRESS = 'IN_PROGRESS';
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Empty constructor to avoid sonar warnings.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     26-05-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private Arc_IFIS_ButtonsFinalize_Ctrl() {
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description This method is exposed to aura and returns the rating data for a given Aha record.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    ahaId    Account Has Analysis Id in `String` format
    * @return   The response object for validated operations.
    * @example  arce.Arc_IFIS_Buttons_Wrp.ValidateResponse e = getRatingData(ahaId)
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce.Arc_IFIS_Buttons_Wrp.ValidateResponse getRatingData(String ahaId) {
        arce.Arc_IFIS_Buttons_Wrp.ValidateResponse response;

        try {
            if (String.isNotBlank(ahaId)) {
                final List<arce__Account_has_Analysis__c> ahas = [
                    SELECT
                        Id,
                        arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c,
                        arce__Analysis__r.arce__rating_prerating_type__c,
                        arce__Analysis__r.arce__is_RTC__c,
                        arce__ffss_for_rating_id__r.arce__rating_id__c,
                        arce__ffss_for_rating_id__r.arce__rating_id__r.arce__rating_short_value_type__c,
                        arce__recalculate_rating__c,
                        arce__AHA_Extension__r.arce__rating_copies_created__c,
                        arce__AHA_Extension__r.arce__rating_copies_validated__c
                    FROM arce__Account_has_Analysis__c
                    WHERE Id = :ahaId
                    WITH USER_MODE
                    LIMIT 1
                ];
                final arce__Account_has_Analysis__c aha = arce.Arc_IFIS_Buttons_Helper.validateAhaData(ahas);

                final String buttonType = aha.arce__Analysis__r.arce__rating_prerating_type__c ==
                    arce.Arc_Gen_RatingGlobal_Constants.RATING
                    ? arce.Arc_Gen_RatingGlobal_Constants.RATINGVAL
                    : arce.Arc_Gen_RatingGlobal_Constants.FINALIZATION;
                response = Arc_IFIS_ButtonsFinalize_Service.getRatingData(aha, buttonType);
            } else {
                response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(
                    null,
                    false,
                    System.Label.arce.Arc_IFIS_Error_Aha_Not_Provided
                );
            }
        } catch (Exception e) {
            /*AuraHandledException auraException = new AuraHandledException(e.getMessage());
            auraException.setMessage(e.getMessage());
            throw auraException;*/
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e.getMessage()); //NOSONAR
        }

        return response;
    }

    /**
    * Executes rating validation service call
    * @param valDataJson JSON string with validation data
    * @return Response object with validation result
    */
    @AuraEnabled
    public static arce.Arc_IFIS_Buttons_Wrp.ValidateResponse callRatingValidation(String valDataJson) {
        try {
            final Arc_IFIS_Buttons_Wrp.ValidationData valData = (Arc_IFIS_Buttons_Wrp.ValidationData) JSON.deserialize(
                valDataJson,
                Arc_IFIS_Buttons_Wrp.ValidationData.class
            );

            if (!arce.Arc_IFIS_TabSet_Service.getPermissionToEdit(valData.ahaId)) {
                return arce.Arc_IFIS_Buttons_Helper.createResponseObj(
                    null,
                    false,
                    System.Label.arce.Arc_IFIS_Error_NotAllowed
                );
            }

            return Arc_IFIS_ButtonsFinalize_Service.validateRating(valData);
        } catch (Exception e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(
                System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage()
            );
            return null;
        }
    }

    /**
    * Executes rating persistence with ParticipantRelations service
    * @param ahaId Account Has Analysis record ID
    * @return Response object with persistence result
    */
    @AuraEnabled
    public static Arc_IFIS_Buttons_Wrp.ValidateResponse callRatingPersistence(String ahaId) {
        try {
            return Arc_IFIS_ButtonsFinalize_Service.persistRatingParticipants(ahaId);
        } catch (Exception e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(
                System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage()
            );
            return null;
        }
    }

    /**
    * Executes rating cloning process (synchronous or asynchronous)
    * @param valDataJson JSON string with validation data
    * @return Response object with cloning result
    **/
    @AuraEnabled
    public static Arc_IFIS_Buttons_Wrp.ValidateResponse callRatingClone(String valDataJson) {

        try {
            final Arc_IFIS_Buttons_Wrp.ValidationData valData = (Arc_IFIS_Buttons_Wrp.ValidationData) JSON.deserialize(
                valDataJson,
                Arc_IFIS_Buttons_Wrp.ValidationData.class
            );

            return Arc_IFIS_ButtonsFinalize_Service.cloneRating(valData);
        } catch (Exception e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(
                System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage()
            );
            return null;
        }
    }

    /**
    * Builds traceability records, closes the source analysis, and sends finalization notifications.
    * Must be called after a successful callRatingClone() invocation.
    * @param valDataJson JSON string with validation data
    * @return Response object with finalization result
    **/
    @AuraEnabled
    public static Arc_IFIS_Buttons_Wrp.ValidateResponse callFinalizeRating(String valDataJson) {
        try {
            final Arc_IFIS_Buttons_Wrp.ValidationData valData = (Arc_IFIS_Buttons_Wrp.ValidationData) JSON.deserialize(
                valDataJson,
                Arc_IFIS_Buttons_Wrp.ValidationData.class
            );

            return Arc_IFIS_ButtonsFinalize_Service.finalizeRating(valData);
        } catch (Exception e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(
                System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage()
            );
            return null;
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Retrieve user data in wrapper format.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * @param    selectedAmbit    Selected ambit in front
    * @return   Service validation response
    * @example  arce.Arc_IFIS_Buttons_Wrp.ValidateResponse e = fetchUsers(selectedAmbit)
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce.Arc_IFIS_Buttons_Wrp.ValidateResponse fetchUsers(String selectedAmbit) {
        final Map<String, Object> data = new Map<String, Object>();
        String errorMessage = null;

        if (String.isBlank(selectedAmbit)) {
            errorMessage = System.Label.arce.Arc_IFIS_AmbitRequired;
        } else {
            try {
                final arce.Arc_IFIS_Buttons_Wrp.DelegationWrapper wrapper = Arc_IFIS_ButtonsFinalize_Service.fetchUsersByAmbit(
                    selectedAmbit
                );
                data.put('userList', wrapper.lstUsers);
            } catch (Exception e) {
                throw new AuraHandledException(System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage());
            }
        }

        return arce.Arc_IFIS_Buttons_Helper.createResponseObj(data, errorMessage == null, errorMessage);
    }

    /**
    * @description
    * @author Global Desktop | 24-11-2021
    * @param selectedAmbit
    * @param aHaId
    * @return arce.Arc_IFIS_Buttons_Wrp.ValidateResponse
    **/
    @AuraEnabled
    public static arce.Arc_IFIS_Buttons_Wrp.ValidateResponse fetchUsersAha(String selectedAmbit, String aHaId) {
        arce.Arc_IFIS_Buttons_Wrp.ValidateResponse ret;
        Map<String, Object> data;
        Arc_Gen_Delegation_Wrapper wrapper;

        if (String.isNotBlank(selectedAmbit) && String.isNotBlank(aHaId)) {
            try {
                data = new Map<String, Object>();
                final List<arce__Account_has_Analysis__c> aHa = [
                    SELECT id, arce__Analysis__r.arce__proposeUser__c
                    FROM arce__Account_has_Analysis__c
                    WHERE Id = :aHaId
                    LIMIT 1
                ];
                wrapper = Arc_GBL_Workflow_Helper.fetchUsersByAmbit(selectedAmbit);
                for (Integer i = 0; i < wrapper.lstUsers.size(); i++) {
                    if (aHa.get(0).arce__Analysis__r.arce__proposeUser__c == wrapper.lstUsers.get(i).get('value')) {
                        wrapper.lstUsers.remove(i);
                    }
                }
                data.put('userList', wrapper.lstUsers);
                ret = arce.Arc_IFIS_Buttons_Helper.createResponseObj(data, true, null); //NOSONAR
            } catch (Exception e) {
                throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e.getMessage()); //NOSONAR
            }
        } else {
            ret = arce.Arc_IFIS_Buttons_Helper.createResponseObj(
                null,
                false,
                'Ambit must be provided to the APEX controller'
            );
        }
        return ret;
    }

    /**
    * @description
    * @author Global Desktop
    * @param region
    * @param level
    * @param accHasAnalysisId
    * @return String
    **/
    @AuraEnabled
    public static String fetchRegionLevel(String region, String level, String accHasAnalysisId) {
        try {
            final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(
                System.UserInfo.getUserId()
            );
            final Arc_Gen_Delegation_Wrapper wrapper = DES_Arc_GBL_Workflow_Helper.fetchLevelRegion(
                wrpUser.ambitUser,
                region,
                level,
                accHasAnalysisId,
                true
            );
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e); //NOSONAR
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that controls the rating proposition.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        28-05-2024
    * @param       ahaId    arce__Account_has_Analysis__c record ID
    * @return      Wrapper with data quality result
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String dataQualityValidation(String ahaId) {
        try {
            final Id recordId = (Id) ahaId;
            return arce.Arc_IFIS_Buttons_Helper.checkDataQuality(String.valueOf(recordId));
        } catch (Exception e) {
            final AuraHandledException auraException = new AuraHandledException(e.getMessage());
            auraException.setMessage(e.getStackTraceString());
            throw auraException; 
        }
    }
}