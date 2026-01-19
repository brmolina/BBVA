/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RAIP_FinalizePrerating_Btn_Ctrl
* @Author   alberto.martinez.carrero.tech@bbva.com
* @Date     Created: 2025-06-13
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller of Arc_Gen_RAIP_FinalizePrerating_Btn.cmp
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2025-06-13 alberto.martinez.carrero.tech@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:TooManyMethods, sf:AvoidUsingTestIsRunningTest, PMD.ExcessiveParameterList')
public class Arc_Gen_RAIP_FinalizePrerating_Btn_Ctrl {
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		27/01/2020
    * @author	alberto.martinez.carrero.tech@bbva.com
    */
    @testVisible
    private Arc_Gen_RAIP_FinalizePrerating_Btn_Ctrl() {

    }
    /**
    * @Description: String with value for FINAL_STAGE in ARCE
    */
    static final String FINAL_STAGE = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow')[0].arce__Value1__c) == true ? '14' : '10';
    /**
    * @Description: String with value for STAGE_CLOSED in ARCE
    */
    static final String STAGE_CLOSED = '3';
    /**
    * @Description: String with value for REASON_PICK in ARCE
    */
    static final String REASON_PICK = '2';
    /**
    * @Description: String with value for TRUE_LITERAL in ARCE
    */
    static final String TRUE_LITERAL = 'true';
    /**
    *-------------------------------------------------------------------------------
    * @description Method that finalizes a prerating.
    *-------------------------------------------------------------------------------
    * @date 2020-05-07
    * @author joseluis.garcia4.contractor@bbva.com
    * @param String arceId - ID of the ARCE record.
    */
    @AuraEnabled
    public static void finalizePrerating(String arceId) {
        try {
            // Finalize RAIP and set discard reason.
            final String discardReason = System.Label.Arc_Gen_FinalizePreratingDiscardReason;
            final arce__Analysis__c analysisToUpdate = new arce__Analysis__c(
                Id = arceId,
                arce__Stage__c = '3',
                arce__wf_status_id__c = '13',
                arce__anlys_wkfl_discard_reason_id__c = discardReason,
                arce__end_date__c = System.today()
            );
            arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c> { analysisToUpdate });

            // Create traceability record.
            final List<arce__Account_has_Analysis__c> lstAccHas = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(arceId);
            final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(discardReason, 'approve', discardReason, lstAccHas[0].Name);
            final Map<String, String> auditWF = new Map<String, String>();
            Arc_Gen_Traceability.saveTrace(arceId, auditAttr, auditWF);
        } catch(DmlException ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ErrorSumPersOR);  // NOSONAR
        } catch(Exception ex) {
            throw new AuraHandledException(System.Label.Lc_arce_NewARCE_UnexpectedError);  // NOSONAR
        }
    }
  /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Method to validatePrerating.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 30/11/2021
    * @author amunguia.contractor@bbva.com
    * @example validatePrerating(arceId);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static void validatePrerating(String arceId) {
        if(getArceConfig('RAIPValidatePrerating')) {
            final arce.Arc_Gen_ServiceAndSaveResponse response;
            final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(arceId)[0];
            //Get local class from config.
            response = Arc_Gen_ValidateRating_service.setupValidateRating(aha.Id, aha.arce__ffss_for_rating_id__r.arce__rating_id__c, null, false);
            if(response.serviceCode != '200') {
                throw new AuraHandledException(System.Label.Arc_Gen_ValidatePrerating);  // NOSONAR
            }
        }
    }
    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Method to retrieve Arce_config for riskFilters.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 28/10/2021
    * @author amunguia.contractor@bbva.com
    * @return Boolean
    * @example getArceConfig(String name);
    *---------------------------------------------------------------------------------------------------------------------
    */
    private static Boolean getArceConfig(String arceConf) {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(arceConf);
        Boolean result;

        if (configs.isEmpty()) {
            result = false;
        } else {
            final arce__Arce_Config__mdt config = configs[0];
            result = Boolean.valueOf(config.arce__Value1__c);
        }
        return result;
    }
    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Method to getRecalculateRating.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 02/02/2022
    * @author Alberto Martinez Carrero
    * @example getRecalculateRating(arceId);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String getRecalculateRating(String accHasAnalisysId) {
        String message = 'Show';
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('EnableOverlays');
        final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> {accHasAnalisysId})[0];
        final Boolean overlaysEnabled = configs.isEmpty() ? false : Boolean.valueOf(configs[0].arce__Value1__c);
        message = arce.Arc_Gen_Overlays_Utils.checkRatingAndOverlays(overlaysEnabled,aha);

        return message + ';' + JSON.serialize(aha);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains the response of the limitAdvisor service
    --------------------------------------------------------------------------------
    * @author alberto.martinez.carrero.contractor@bbva.com
    * @date 2022-06-03
    * @param String arce account has analysis Id
    * @return arce.Arc_Gen_ServiceAndSaveResponse - A wrapper with information of saving records
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse
    **/
    @AuraEnabled
    public static Boolean callLimitAdvisor(String aHaId) {
        final arce.Arc_Gen_LimitAdvisor_RP response = arce.Arc_Gen_LimitAdvisor_Service.callLimitAdvisor(aHaId, true, null, false);
        return response.message.detailedMessage == 'SUCCESS' ? true : false;
    }
}