/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FlowSuggested_Controller
* @Author   Isabel Ascaso - isabel.ascaso.contractor@bbva.com
* @Date     Created: 2023-11-13
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_FlowSuggested component
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2023-11-13 isabel.ascaso.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_FlowSuggested_Controller {
    /** @Description: field name rating tool */
    private static final String RATING_TOOL = 'arce__RAR_rating_tool_id__c';

    /** @Description: field name entity type */
    private static final String ENTITY_TYPE = 'arce__EntityType__c';

    /** @Description: true string */
    private static final String TRUE_S = 'true';

    /** @Description: false string */
    private static final String FALSE_S = 'false';
    /**
    *-------------------------------------------------------------------------------
    * @description builder to avoid error in sonar
    *-------------------------------------------------------------------------------
    * @author  isabel.ascaso.contractor@bbva.com
    * @date     2023-07-24
    * @Method      Arc_Gen_FlowSuggested_Controller
    * @return      nothing.
    * @example     Arc_Gen_FlowSuggested_Controller().
    */
    private Arc_Gen_FlowSuggested_Controller() {
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to return the id of ahaExtension
    *-------------------------------------------------------------------------------
    * @author  isabel.ascaso.contractor@bbva.com
    * @date    2023-07-24
    * @Method      getAhaExtensionId
    * @param       ahaId - record id
    * @return      String
    * @example     public static String getAhaExtensionId(String ahaId)
    */
    @AuraEnabled
    public static String getAhaExtensionId(String ahaId) {
        final List<arce__Account_has_Analysis__c> listAha= arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> {ahaId});
        final String ahaExtId = listAha[0].arce__AHA_Extension__c;
        return ahaExtId;
    }


    /**
    *-------------------------------------------------------------------------------
    * @description get if is a group or subsidiary
    *-------------------------------------------------------------------------------
    * @author  isabel.ascaso.contractor@bbva.com
    * @date    2023-07-24
    * @Method      returnFlow
    * @return      List
    * @example     public static List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> returnFlow()
    */
    @AuraEnabled
    public static String getParticipantType(String ahaId) {
        final arce__Account_has_Analysis__c ahaFullObject = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> {ahaId})[0];
        final List<Id> lstAccsId = new List<Id>();
        lstAccsId.add(ahaFullObject.arce__Customer__c);
        final Map<Id, arce.Arc_Gen_Account_Wrapper> mapAccount = arce.Arc_Gen_Account_Locator.getAccountInfoById(lstAccsId);

        return mapAccount.get(ahaFullObject.arce__Customer__c).participantType;
    }

    /**
    * @Description Method to update the ahaExtension with triage fields
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 13/11/2023
    * @author isabel.ascaso.ruiz.contractor@bbva.com
    * @return Boolean
    * @example Boolean value = updateExtensionTriage();
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String updateExtensionTriage(String accHasAnalysisId, Map<String, String> formDataMap) {
        final String ahaExtensionId = getAhaExtensionId(accHasAnalysisId);
        final arce__AHA_Extension__c ahaExtension = new arce__AHA_Extension__c();
        final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c();
        for (String fieldName : formDataMap.keySet()) {
            if(fieldName != ENTITY_TYPE && fieldName == RATING_TOOL) {
                aha.put(fieldName, formDataMap.get(fieldName));
            } else if(fieldName != ENTITY_TYPE) {
                if(formDataMap.get(fieldName) == TRUE_S || formDataMap.get(fieldName) == FALSE_S) {
                    ahaExtension.put(fieldName,  Boolean.valueOf(formDataMap.get(fieldName)));
                } else {
                    ahaExtension.put(fieldName, formDataMap.get(fieldName));
                }

            }
        }
        aha.put('id', accHasAnalysisId);
        ahaExtension.put('id', ahaExtensionId);
        arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(new List<sObject>{ahaExtension, aha});

        String ratingSystem;
        ratingSystem = [SELECT toLabel(arce__rating_system__c) FROM arce__AHA_Extension__c WHERE Id =: ahaExtensionId].arce__rating_system__c;
        return ratingSystem;
    }
}