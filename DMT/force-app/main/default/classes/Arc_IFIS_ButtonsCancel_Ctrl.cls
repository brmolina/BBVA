/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsCancel_Ctrl
* @Author         marcos.gimeno.contractor@bbva.com
* @Date           25-05-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Controller class for cancel rating operations.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.contractor@bbva.com
* 25-05-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@SuppressWarnings('sf:PreserveStackTrace')
public with sharing class Arc_IFIS_ButtonsCancel_Ctrl {
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
    private Arc_IFIS_ButtonsCancel_Ctrl() {
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Get picklist value list with discard reasons.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     11-09-2023
    * @return   List with discard reasons
    * @example  List<Map<String, String>> e = fetchDiscardReasons()
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> fetchDiscardReasons() {
        try {
            return arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels(
                'arce__Analysis__c',
                'arce__anlys_wkfl_discard_reason_id__c'
            );
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage());
        }
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Cancellation process controller method.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.contractor@bbva.com
    * @date     25-05-2023
    * @param    ahaId          ID of the Account_has_Analysis__c record
    * @param    reasonValue    Reason for cancellation
    * @param    reasonLabel    Reason label for cancellation
    * @param    reasonDesc     Reason description for cancellation
    * @return   Analysis status update response
    * @example  String e = updateStatus(ahaId, stageToUpdate)
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('PMD.ExcessiveParameterList') 
    @AuraEnabled
    public static String cancelRating(Id ahaId, String reasonValue, String reasonLabel, String reasonDesc) {
        try {
            if (!Arc_IFIS_Buttons_Helper.isButtonAvailable(ahaId, 'Arc_IFIS_BtnCancel')) {
                throw new AuraHandledException(System.Label.arce.Arc_IFIS_ButtonNotAllowed);
            }

            final arce.Arc_Gen_RatingGlobal_data.saveResult response = Arc_IFIS_ButtonsCancel_Service.toCancel(
                ahaId,
                reasonValue,
                reasonLabel,
                reasonDesc
            );

            return JSON.serialize(response);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage());
        }
    }
}