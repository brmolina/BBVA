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
    * -----------------------------------------------------------------------------------------------
    * @description Controls the participant relation callout logic for the lightning component.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     10-07-2023
    * @param    ahaId    arce__Account_has_Analysis__c id
    * @return   Response to be returned to the lightning component
    * @example  arce.Arc_IFIS_Buttons_Wrp.ValidateResponse e = callParticipantRelation(ahaId)
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce.Arc_IFIS_Buttons_Wrp.ValidateResponse callParticipantRelation(String ahaId) {
        arce.Arc_IFIS_Buttons_Wrp.ValidateResponse response;

        try {
            // Get related Account Has Analysis
            final List<arce__Account_has_Analysis__c> ahas = arce.Arc_IFIS_Srv_ParticipantRelation.getAccountHasAnalysis(
                ahaId
            );
            final arce__Account_has_Analysis__c aha = ahas.isEmpty() ? new arce__Account_has_Analysis__c() : ahas[0];

            // Get current client account
            final arce.Arc_Gen_Account_Wrapper currentAccount = arce.Arc_IFIS_Srv_ParticipantRelation.getAccountWrapper(
                ahas
            );

            if (aha == null || currentAccount == null) {
                response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(
                    null,
                    false,
                    System.Label.arce.Arc_IFIS_Error_ParticipantRelation +
                        ': ' +
                        System.Label.arce.Arc_IFIS_Wizard_Acc_Not_Found
                );
            } else {
                if (arce.Arc_IFIS_Srv_ParticipantRelation.isServiceEnabled(aha.arce__RAR_rating_tool_id__c)) {
                    // Persist in service
                    final arce.Arc_Gen_ServiceAndSaveResponse servResp = arce.Arc_IFIS_Srv_ParticipantRelation.callService(
                        ahas,
                        currentAccount,
                        STATUS_PROGRESS
                    );

                    if (servResp.serviceCode.contains('20')) {
                        response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(null, true, null);
                    } else {
                        response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(
                            null,
                            false,
                            System.Label.arce.Arc_IFIS_Error_ParticipantRelation +
                                ': ' +
                                System.Label.arce.Arc_IFIS_Wizard_Service_KO
                        );
                    }
                } else {
                    response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(
                        null,
                        true,
                        'Service not enabled for this account has analysis.'
                    );
                }
            }
        } catch (Exception e) {
            response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(
                null,
                false,
                System.Label.arce.Arc_IFIS_Error_ParticipantRelation
            );
        }

        return response;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description This method finalizes a rating by validating it and updating its description.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    ahaId            ID of the aha record.
    * @param    ratingId         ID of the rating record.
    * @param    validatedById    ID of the user who validated the rating.
    * @param    description      New description for the rating.
    * @param    ambit            Ambit of the rating.
    * @return   The response object for validated operations.
    * @example  arce.Arc_IFIS_Buttons_Wrp.ValidateResponse e = validateRating(ahaId, ratingId, validatedById, description, ambit)
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce.Arc_IFIS_Buttons_Wrp.ValidateResponse callRatingValidation(String valDataJson) {
        arce.Arc_IFIS_Buttons_Wrp.ValidateResponse response;

        try {
            final Arc_IFIS_Buttons_Wrp.ValidationData valDataWrap = (Arc_IFIS_Buttons_Wrp.ValidationData) JSON.deserialize(
                valDataJson,
                Arc_IFIS_Buttons_Wrp.ValidationData.class
            );

            // Check if the user has permission to edit the analysis record
            if (arce.Arc_IFIS_TabSet_Service.getPermissionToEdit(valDataWrap.ahaId)) {
                final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(valDataWrap.ahaId);

                final arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper validationWrap = new arce.Arc_Gen_RatingGlobal_helper.ValidationWrapper(
                    valDataWrap.ahaId,
                    valDataWrap.validatedById,
                    valDataWrap.ratingId,
                    valDataWrap.ambit,
                    valDataWrap.description
                );

                final arce.Arc_Gen_ServiceAndSaveResponse servResponse = Arc_IFIS_ButtonsFinalize_Service.setupValidateRatingByUser(
                    validationWrap,
                    analysis
                );

                if (servResponse.serviceCode.contains('20')) {
                    response = Arc_IFIS_ButtonsFinalize_Service.handleValidationSuccess(
                        valDataWrap,
                        Boolean.valueOf(servResponse.saveStatus),
                        servResponse.saveMessage,
                        analysis
                    );
                } else {
                    response = Arc_IFIS_ButtonsFinalize_Service.handleValidationFailure(servResponse.serviceMessage);
                }
            } else {
                response = arce.Arc_IFIS_Buttons_Helper.createResponseObj(
                    null,
                    false,
                    System.Label.arce.Arc_IFIS_Error_NotAllowed
                );
            }
        } catch (Exception e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(
                System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage() + e.getStackTraceString()
            );
        }

        return response;
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
    * @description Get the configuration values to use in the component
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        22-05-2024
    * @return      Serialized JSON with the configuration values
    * @example     String configValues = getArceConfigs()
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled(cacheable=true)
    public static String getArceConfigs() {
        final List<String> configNames = new List<String>{ 'EnableRatingSystem' };

        final Map<String, String> arceConfMap = new Map<String, String>();
        for (String configName : configNames) {
            final List<arce__Arce_Config__mdt> arceConfList = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(
                configName
            );
            for (arce__Arce_Config__mdt arceConf : arceConfList) {
                arceConfMap.put(arceConf.arce__Config_Name__c, arceConf.arce__Value1__c);
            }
        }

        return JSON.serialize(arceConfMap);
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