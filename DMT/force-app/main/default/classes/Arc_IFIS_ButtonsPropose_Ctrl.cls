/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsPropose_Ctrl
* @Author         marcos.gimeno.next@bbva.com
* @Date           28-08-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Controller class to propose IFIS rating.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 28-08-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
public with sharing class Arc_IFIS_ButtonsPropose_Ctrl {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Custom Exception that extends exception.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    public virtual class CustomException extends Exception {
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Empty constructor.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_IFIS_ButtonsPropose_Ctrl() {
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

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Checks the validity of the rating and initializes the delegation.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    ahaId    arce__Analysis__c record ID
    * @return   Wrapper with delegation info
    * @example  String e = initDelegation(Id ahaId)
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String initDelegation(Id ahaId) {
        try {
            final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaId);
            final List<arce__Account_has_Analysis__c> ahas = [
                SELECT
                    Id,
                    arce__ffss_for_rating_id__r.arce__rating_id__c,
                    arce__ffss_for_rating_id__r.arce__rating_id__r.arce__rating_short_value_type__c,
                    arce__recalculate_rating__c,
                    arce__AHA_Extension__r.arce__rating_copies_created__c,
                    arce__AHA_Extension__r.arce__rating_copies_validated__c,
                    arce__RAR_rating_tool_id__c,
                    (SELECT Id FROM arce__Rating_Copies__r)
                FROM arce__Account_has_Analysis__c
                WHERE id = :ahaId
                WITH USER_MODE
                LIMIT 1
            ];
            final arce__Account_has_Analysis__c aha = arce.Arc_IFIS_Buttons_Helper.validateAhaData(ahas);

            final Arc_IFIS_Buttons_Wrp.ValidateResponse response = Arc_IFIS_ButtonsPropose_Service.getRatingData(
                aha,
                'PROPOSAL'
            );

            if (
                response.success &&
                String.valueOf(response.data.get('recalculateRating')) == arce.Arc_IFIS_Buttons_Helper.DEFAULT_MESSAGE
            ) {
                final arce.Arc_Gen_User_Wrapper userWrap = arce.Arc_Gen_User_Locator.getUserInfo(
                    System.UserInfo.getUserId()
                );
                final Arc_Gen_Delegation_Wrapper wrapper = Arc_Gen_Propose_Helper.initDelegation(
                    userWrap.ambitUser,
                    analysis.Id,
                    'RAIP-PROPOSE',
                    false
                );
                return JSON.serialize(wrapper);
            } else {
                return JSON.serialize(response);
            }
        } catch (Exception e) {
            throw new AuraHandledException(
                e.getMessage() == System.Label.arce.Arc_Gen_RecalcRatWarning
                    ? System.Label.arce.Arc_Gen_RecalcRatWarning
                    : System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage()
            );
        }
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that controls the rating proposition.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * @param    analysisId       arce__Analysis__c record ID
    * @param    selectedAmbit    Selected ambit
    * @return   Wrapper with propose rating response
    * @example  String e = proposeRating(analysisId, selectedAmbit)
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String proposeRating(String analysisId, String selectedAmbit, String userId) {
        try {
            List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(
                new List<String>{ analysisId }
            );

            if (ahaList.isEmpty()) {
                throw new AuraHandledException(System.Label.arce.Arc_IFIS_Wizard_Aha_Not_Found);
            }

            final arce__Account_has_Analysis__c selectedAha = ahaList[0];

            if (!arce.Arc_IFIS_Buttons_Helper.isButtonAvailable(selectedAha.Id, 'Arc_IFIS_BtnPropose')) {
                throw new AuraHandledException(System.Label.arce.Arc_IFIS_ButtonNotAllowed);
            }

            final arce.Arc_Gen_RatingGlobal_data.saveResult response = Arc_IFIS_ButtonsPropose_Service.toPropose(
                analysisId,
                selectedAmbit,
                userId,
                selectedAha
            );
            return JSON.serialize(response);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage());
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method that controls the rating proposition.
    * -----------------------------------------------------------------------------------------------
    * @autor    joseluis.miralles.contractor@bbva.com
    * @date     01/03/2024
    * @param    analysisId       arce__Analysis__c record ID
    * @example  String e = fieldsValidation(analysisId)
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String fieldsValidation(String analysisId) {
        try {
            final arce__Analysis__c analysis = [
                SELECT id, arce__is_RTC__c
                FROM arce__Analysis__c
                WHERE id = :analysisId
                LIMIT 1
            ];

            return String.valueOf(analysis.arce__is_RTC__c);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage());
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Check that overlay has been calculated
    *--------------------------------------------------------------------------------
    * @date 30/08/2021
    * @author amunguia.contractor@bbva.com
    * @param Id recordId
    * @return String
    */
    @AuraEnabled
    public static String getPermissionOverlay(Id recordId) {
        String message = 'Show';
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(
            'EnableOverlays'
        );
        final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(
            new List<String>{ recordId }
        )[0];
        final Boolean overlaysEnabled = configs.isEmpty() ? false : Boolean.valueOf(configs[0].arce__Value1__c);
        if (aha.arce__Analysis__r.arce__is_RTC__c) {
            message = arce.Arc_Gen_Overlays_Utils.checkRatingAndOverlays(overlaysEnabled, aha);
        }
        return message;
    }

    /**
    * @description validates Parent Subsidiary data from web service
    * @author joseluis.miralles.contractor@bbva.com | 06-11-2023
    * @param String ahaId
    * @return MessageResponse
    **/
    @AuraEnabled
    public static arce.Arc_IFIS_ValidatePS.MessageResponse validateParentSubsidiary(Id ahaId) {
        return arce.Arc_IFIS_ValidatePS.callParentSubsidiary(ahaId);
    }

    /**
    * @description Refresh Parent Subsidiary data from web service
    * @author joseluis.miralles.contractor@bbva.com | 06-11-2023
    * @param String ahaId
    * @return MessageResponse
    **/
    @AuraEnabled
    public static arce.Arc_IFIS_RetrievePS_Controller.MessageResponse refreshParentSubsidiary(Id ahaId) {
        arce.Arc_IFIS_RetrievePS_Controller.MessageResponse responsePS = arce.Arc_IFIS_RetrievePS_Controller.callIFISParentSubsidiary(
            ahaId
        );
        if (responsePS.status == arce.Arc_IFIS_ValidatePS.VALUE_SUCCESS) {
            final arce.Arc_Gen_GenericUtilities.SaveResult updRes = Arc_IFIS_ButtonsPropose_Service.setRecalculateRatingValue(
                ahaId,
                '1'
            );
            if (updRes.status == 'false') {
                responsePS.status = arce.Arc_IFIS_ValidatePS.VALUE_ERROR;
                responsePS.message = updRes.message;
            }
        }
        return responsePS;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that return
    *--------------------------------------------------------------------------------
    * @date		11/03/2021
    * @author	Global Desktop
    * @param Id arceId - Standard Id of the ARCE record
    * @param String selectedAmbit - Ambito seleccionado
    * @return returns boolean
    * @example getAmbits(Id recordId)
    */
    @AuraEnabled
    public static String fetchUsers(String selectedAmbit) {
        try {
            final Arc_Gen_Delegation_Wrapper wrapper = DES_Arc_GBL_Workflow_Helper.fetchUsersProposeRaip(selectedAmbit);
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e); //NOSONAR
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that return
    *--------------------------------------------------------------------------------
    * @date		11/03/2021
    * @author	Global Desktop
    * @param Id arceId - Standard Id of the ARCE record
    * @param String selectedAmbit - Ambito seleccionado
    * @return returns boolean
    * @example getAmbits(Id recordId)
    */
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
                false
            );
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e); //NOSONAR
        }
    }
}