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
* |2020-08-18 joseluis.garcia4.contractor@bbva.com
*             Add check for permissions.
* |2020-09-11 eduardoefrain.hernandez.contractor@bbva.com
*             Remove ValidateRatingClass
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-04 juanignacio.hita.contractor@bbva.com
*             Adds aha name (analysisId) param in traceability record
* |2021-04-07 joseluis.garcia4.contractor@bbva.com
*             Change references to Arc_Gen_RatingGlobal_* classes.
* |2021/08/31 amunguia.contractor@bbva.com
*             it is checked that overlay has been calculated.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_RAIP_Propose_controller {
    /**
    * @description Parent Subsidiary Service class name
    */
    public static final String PS_SV_NAME = Test.isRunningTest() ? 'Arc_Gen_RetrievePS_Service_Mock' : 'arce.Arc_Gen_RetrievePS_Service';
     /**
    * @description Data Quality class name
    */
    public static final String DATA_QA_NAME = Test.isRunningTest() ? 'Arc_Gen_DataQuality_Mock' : 'arce.Arc_Gen_DataQuality';
    /**
    * @description String "OK" value.
    */
    public static final String VALUE_OK = 'OK';
    /**
    * @description String "Success" value.
    */
    public static final String VALUE_SUCCESS = 'Success';
    /**
    * @description String "Success" value.
    */
    public static final String VALUE_ERROR = 'Error'; 
    /**
    * @description String "Success" value.
    */
    public static final String VALUE_REFRESH_GCP = 'RefreshGCP';
    /**
    * @description String Account_Has_Analysis Id.
    */
    public static final String AHA_ID = 'ahaId';
    /**
    * @description String 2012P1IRP.
    */
    public static final String RATING_IRP_MODEL = '2012P1IRP';

    /**
    * @Class: MessageResponse
    * @Description: Container that contains the message for the Lightning component as a response
    * @author BBVA
    */
    public class MessageResponse {
        /**
        * @Description: Indicates status
        */
        @AuraEnabled public String status {get;set;}
        /**
        * @Description: Indicates message
        */
        @AuraEnabled public String message {get;set;}
        /**
        * @description MessageResponse constructor
        * @author aleksandar.dinkov.contractor@bbva.com | 27-05-2024
        **/
        public MessageResponse() {
            status = VALUE_SUCCESS;
            message = VALUE_OK;
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Custom Exception that extends exception
    *--------------------------------------------------------------------------------
    * @date		30/03/2020
    */
    public virtual class CustomException extends Exception {} 

    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		27/01/2020
    * @author	eduardoefrain.hernandez.contractor@bbva.com
    */
    @testVisible
    private Arc_Gen_RAIP_Propose_controller() {

    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that return
    *--------------------------------------------------------------------------------
    * @date 19/02/2020
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @param Id arceId - Standard Id of the ARCE record
    * @return returns boolean
    * @example getAmbits(Id recordId)
    */
    @AuraEnabled
    public static String initDelegation(Id accHasAnalysisId) {
        try {
            final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
            final Boolean hasValidRating = arce.Arc_Gen_GenericUtilities.validateAllRatingsInArce(arceVar.Id, '2');
            if (hasValidRating) {
                final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
                final Arc_Gen_Delegation_Wrapper wrapper = Arc_Gen_Propose_Helper.initDelegation(wrpUser.ambitUser, arceVar.Id, 'RAIP-PROPOSE',false);
                return JSON.serialize(wrapper);
            } else {
                throw new CustomException(Label.Lc_Arc_RAIP_NoCalculatedRating); //NOSONAR
            }
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e); //NOSONAR
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that return
    *--------------------------------------------------------------------------------
    * @date 19/02/2020
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @param Id arceId - Standard Id of the ARCE record
    * @param String selectedAmbit - Ambito seleccionado
    * @return returns boolean
    * @example getAmbits(Id recordId)
    */
    @AuraEnabled
    public static String toProposeRaip(String arceId, String selectedAmbit, String selectedUser) {
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String> { arceId });
        if (ahaList.isEmpty() || !arce.Arc_Gen_GenericUtilities.isButtonAvailable(ahaList[0].Id, 'Arc_Gen_RAIP_Propose')) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }

        try {
            final arce.Arc_Gen_RatingGlobal_data.saveResult response = Arc_Gen_RAIP_Propose_service.toPropose(arceId, selectedUser, selectedAmbit, ahaList[0]);
            return JSON.serialize(response);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e); //NOSONAR
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
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('EnableOverlays');
        final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> {recordId})[0];
        final Boolean overlaysEnabled = configs.isEmpty() ? false : Boolean.valueOf(configs[0].arce__Value1__c);
        message = arce.Arc_Gen_Overlays_Utils.checkRatingAndOverlays(overlaysEnabled,aha);
        return message;
    }

    /**
    * @description validates Parent Subsidiary data from web service
    * @author aleksandar.dinkov.contractor@bbva.com | 06-11-2023
    * @param String ahaId
    * @return MessageResponse
    **/
    @AuraEnabled
    public static Arc_Gen_ValidatePS.MessageResponse validateParentSubsidiary(Id ahaId, Boolean isTest) {
        return Arc_Gen_ValidatePS.callParentSubsidiary(ahaId, isTest);
    }

    /**
    * @description Refresh Parent Subsidiary data from web service
    * @author aleksandar.dinkov.contractor@bbva.com | 06-11-2023
    * @param String ahaId
    * @return MessageResponse
    **/
    @AuraEnabled
    public static Arc_Gen_ValidatePS.MessageResponse refreshParentSubsidiary(Id ahaId, Boolean isTest) {
        final Callable serviceClass = (Callable) Type.forName(PS_SV_NAME).newInstance();
        final Object callableResponse = serviceClass.call('callParentSubsidiary', new Map<String, Object> {AHA_ID => ahaId});
        return (Arc_Gen_ValidatePS.MessageResponse) JSON.deserialize(JSON.serialize(callableResponse), Arc_Gen_ValidatePS.MessageResponse.class);
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description : Check if is ARP
    *-------------------------------------------------------------------------------
    * @date 2025-09-01
    * @author david.montero.bellon.contractor@bbva.com
    * @param String ahaId
    * @return returns boolean
    * @example isARP(ahaId)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Boolean isARP(String ahaId) {
        Boolean result = false; //NOSONAR

        try {
            final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(
                new List<String>{ ahaId }
            );

            if (!ahaList.isEmpty()) {
                final arce__Account_has_Analysis__c aha = ahaList[0];
                final arce__Analysis__c analysis = aha.arce__Analysis__r;

                if (analysis != null && analysis.arce__anlys_wkfl_sub_process_type__c == Arc_Gen_ArceCore_Constants.FOUR) {
                    final Boolean isARP = aha.arce__RAR_rating_tool_id__c != null && aha.arce__RAR_rating_tool_id__c.contains('ARP');

                    result = isARP; //NOSONAR
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e); //NOSONAR
        }

        return result;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description : Execute ARP Flow Validation
    *-------------------------------------------------------------------------------
    * @date 2025-09-01
    * @author david.montero.bellon.contractor@bbva.com
    * @param String ahaId
    * @return returns MessageResponse
    * @example isARP(ahaId)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static MessageResponse arpFlowValidation(String ahaId) {
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ ahaId });
        MessageResponse response = new MessageResponse();

        if (!ahaList.isEmpty()) {
            final Callable dataQualityClass = (Callable) Type.forName(DATA_QA_NAME).newInstance();
            final String respJson = (String) dataQualityClass.call('arpFlowValidation', new Map<String, Object> {AHA_ID => ahaId});
            response = (MessageResponse) JSON.deserialize(respJson, MessageResponse.Class);
        }
        return response;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description : Check if IRP is RTC
    *-------------------------------------------------------------------------------
    * @date 2024-01-03
    * @author antonio.perez.hernandez.contractor@bbva.com
    * @param String ahaId
    * @return returns boolean
    * @example isRTC(ahaId)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Boolean isRTC(String ahaId) {
        Boolean result = false;

        try {
            final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(
                new List<String>{ ahaId }
            );

            if (!ahaList.isEmpty()) {
                final arce__Account_has_Analysis__c aha = ahaList[0];
                final arce__Analysis__c analysis = aha.arce__Analysis__r;

                if (analysis != null && analysis.arce__anlys_wkfl_sub_process_type__c == Arc_Gen_ArceCore_Constants.FOUR) {
                    final Boolean isRTCEmp = analysis.arce__is_RTC_Emp__c != null && analysis.arce__is_RTC_Emp__c == Arc_Gen_ArceCore_Constants.ONE;
                    final Boolean isRTCCorp = analysis.arce__is_RTC__c != null && analysis.arce__is_RTC__c;

                    result = isRTCEmp || isRTCCorp;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e);
        }

        return result;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description : Check if IRP is RTC
    *-------------------------------------------------------------------------------
    * @date 2024-01-03
    * @author sergio.villaroel.contractor@bbva.com
    * @param String ahaId
    * @return returns boolean
    * @example rtcAutoMeta()
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Boolean rtcAutoMeta() {
        return Arc_Gen_ParentSubsidiary_Controller.rtcAutoMeta();
    }
    /**
    * @Description : Check if actual ORG/Scratch is Corporates and if rating system
    *                is enabled for corporates
    *-------------------------------------------------------------------------------
    * @date 2024-02-10
    * @author aleksandar.dinkov.contractor@bbva.com
    * @return Boolean
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String isCorporates() {
        final List<String> configNames = new List<String>{ 'Is_Corporate', 'EnableRatingSystem' };

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
    * @description Execute Data Quality validations
    * @author aleksandar.dinkov.contractor@bbva.com | 27-05-2024
    * @param String ahaId
    * @return MessageResponse
    **/
    @AuraEnabled
    public static MessageResponse dataQuality(Id ahaId) {
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ ahaId });
        MessageResponse response = new MessageResponse();
        if (!ahaList.isEmpty() && ahaList[0].arce__RAR_rating_tool_id__c != '2021RTC_EXPG') {
            final Callable dataQualityClass = (Callable) Type.forName(DATA_QA_NAME).newInstance();
            final String respJson = (String) dataQualityClass.call('executeDataQuality', new Map<String, Object> {AHA_ID => ahaId});
            response = (MessageResponse) JSON.deserialize(respJson, MessageResponse.Class);
        }
        return response;
    }

    /**
    * @description Refresh Parent Rating data
    * @author aleksandar.dinkov.contractor@bbva.com | 27-05-2024
    * @param String ahaId
    * @return MessageResponse
    **/
    @AuraEnabled
    public static MessageResponse refreshParentRating(Id ahaId) {
        final Callable dataQualityClass = (Callable) Type.forName(DATA_QA_NAME).newInstance();
        final String respJson = (String) dataQualityClass.call('refreshParentRating', new Map<String, Object> {AHA_ID => ahaId});
        MessageResponse response = (MessageResponse) JSON.deserialize(respJson, MessageResponse.Class);
        return response;
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
            final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
            final Arc_Gen_Delegation_Wrapper wrapper = DES_Arc_GBL_Workflow_Helper.fetchLevelRegion(wrpUser.ambitUser,region,level,accHasAnalysisId,false);
            return JSON.serialize(wrapper);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e); //NOSONAR
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description : Check if is 2012P1 rating
    *-------------------------------------------------------------------------------
    * @date 2025-18-02
    * @author david.montero.bellon.contractor@bbva.com
    * @param String ahaId
    * @return returns boolean
    * @example is2012P1(ahaId)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Boolean is2012P1(String ahaId) {
        Boolean result = false; //NOSONAR

        try {
            final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(
                new List<String>{ ahaId }
            );

            if (!ahaList.isEmpty()) {
                final arce__Account_has_Analysis__c aha = ahaList[0];
                final arce__Analysis__c analysis = aha.arce__Analysis__r;

                if (analysis != null && analysis.arce__anlys_wkfl_sub_process_type__c == Arc_Gen_ArceCore_Constants.FOUR) {
                    final Boolean is2012P1 = aha.arce__RAR_rating_tool_id__c != null && aha.arce__RAR_rating_tool_id__c == RATING_IRP_MODEL;

                    result = is2012P1; //NOSONAR
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + ': ' + e); //NOSONAR
        }

        return result;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description : Execute EEFF Audited Validation
    *-------------------------------------------------------------------------------
    * @date 2025-18-02
    * @author david.montero.bellon.contractor@bbva.com
    * @param String ahaId
    * @return returns MessageResponse
    * @example eeffAuditedValidation(ahaId)
    *-------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static MessageResponse eeffAuditedValidation(String ahaId) {
        final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ ahaId });
        MessageResponse response = new MessageResponse();

        if (!ahaList.isEmpty()) {
            final Callable dataQualityClass = (Callable) Type.forName(DATA_QA_NAME).newInstance();
            final String respJson = (String) dataQualityClass.call('eeffAuditedValidation', new Map<String, Object> {AHA_ID => ahaId});
            response = (MessageResponse) JSON.deserialize(respJson, MessageResponse.Class);
        }
        return response;
    }   
}