/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Triage_Controller
* @Author   Isabel Ascaso - isabel.ascaso.contractor@bbva.com
* @Date     Created: 2023-07-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2023-07-24 isabel.ascaso.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_Triage_Controller {
    /**
        * @Description: Name of metadata to know the flow suggested
    */
    static final String SUGGESTED_FLOW = 'RTC_Suggested_Flow';

    /**
        * @Description: Name of metadata to know the flow suggested
    */
    static final String MODELS_OPTIONS = 'IRPModelsAvailable';

    /**
        * @Description: code of flow generic
    */
    static final String GENERIC_FLOW = '2021RTC_GEN';

    /**
        * @Description: code of flow generic
    */
    static final String SUBSIDIARY = 'SUBSIDIARY';

    /**
    *-------------------------------------------------------------------------------
    * @description builder to avoid error in sonar
    *-------------------------------------------------------------------------------
    * @author  isabel.ascaso.contractor@bbva.com
    * @date     2023-07-24
    * @Method      Arc_Gen_Triage_Controller
    * @return      nothing.
    * @example     Arc_Gen_Triage_Controller().
    */
    private Arc_Gen_Triage_Controller() {
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
    * @description Method to return the object of ahaExtension by Id
    *-------------------------------------------------------------------------------
    * @author  isabel.ascaso.contractor@bbva.com
    * @date    2023-07-24
    * @Method      getAhaExtension
    * @param       ahaId - record id
    * @return      String
    * @example     public static String getAhaExtension(String ahaId)
    */
    public static arce__AHA_Extension__c getAhaExtension(String ahaId) {
        arce__AHA_Extension__c ahaExtension;

        if(arce__AHA_Extension__c.SObjectType.getDescribe().isAccessible()) {
            final String ahaExtensionId = getAhaExtensionId(ahaId);

            ahaExtension = [SELECT arce__level_Shell__c, arce__filial_Core__c, arce__group_corporative__c, arce__matrizIg__c, arce__legal_EEFF__c, arce__conditions_8116__c, arce__explicit_guarantee__c, arce__parametry5__c, arce__bank_spain__c, arce__group_treasury_subsidiary__c FROM arce__AHA_Extension__c WHERE Id =: ahaExtensionId LIMIT 1];
        }

        return ahaExtension;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to return the suggested flow depends of a metadata
    *-------------------------------------------------------------------------------
    * @author  isabel.ascaso.contractor@bbva.com
    * @date    2023-07-24
    * @Method      returnFlow
    * @param       ahaId - record id
    * @return      String
    * @example     public static String returnFlow(String ahaId)
    */
    @AuraEnabled
    public static String returnFlow(String ahaId, String participantType) {
        String flow;

        if(participantType == SUBSIDIARY) {
            final List<arce__Service_persistence__mdt> mdtConfigList = new List<arce__Service_persistence__mdt>([SELECT DeveloperName, Id, arce__JSON_input__c, arce__api_field_Name__c, arce__iasoVariables__c FROM arce__Service_persistence__mdt where DeveloperName=:SUGGESTED_FLOW]);
            final arce__AHA_Extension__c ahaExtension = getAhaExtension(ahaId);

            List<Arc_Gen_Triage_Controller.SourceConditionWrapper> toolkitFields = new List<Arc_Gen_Triage_Controller.SourceConditionWrapper>();
            toolkitFields = (List<Arc_Gen_Triage_Controller.SourceConditionWrapper>) JSON.deserializeStrict(mdtConfigList[0].arce__JSON_input__c, List<Arc_Gen_Triage_Controller.SourceConditionWrapper>.class);

            for(Arc_Gen_Triage_Controller.SourceConditionWrapper wrapp: toolkitFields) {
                System.debug('flow ' + wrapp.flow);
                final List<String> fieldsTrue = wrapp.fieldsTrue.split(',');
                final List<String> fieldsFalse = wrapp.fieldsFalse.split(',');
                Boolean isThisFlow = true;

                //Check the fields are true
                for(String field : fieldsTrue) {
                    final Boolean thisFieldValue = (Boolean) ahaExtension.get(field);
                    System.debug('wrapp ' + thisFieldValue);
                    isThisFlow = isThisFlow && thisFieldValue;
                }

                //Check the rest of the fields at false
                for(String field : fieldsFalse) {
                    final Boolean thisFieldValue = (Boolean) ahaExtension.get(field);
                    System.debug('wrapp ' + thisFieldValue);
                    isThisFlow = isThisFlow && !thisFieldValue;
                }

                System.debug('isThisFlow ' + isThisFlow);

                if(isThisFlow) {
                    flow = wrapp.flow;
                    break;
                }
            }
        } else {
            flow = GENERIC_FLOW;
        }
        System.debug(flow);
        return flow;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to return the suggested flow depends of a metadata
    *-------------------------------------------------------------------------------
    * @author  isabel.ascaso.contractor@bbva.com
    * @date    2023-07-24
    * @Method      returnFlow
    * @param       ahaId - record id
    * @return      String
    * @example     public static String returnFlow(String ahaId)
    */
    @AuraEnabled
    public static String returnJsonFlow() {
        final List<arce__Service_persistence__mdt> mdtConfigList = new List<arce__Service_persistence__mdt>([SELECT DeveloperName, Id, arce__JSON_input__c, arce__api_field_Name__c, arce__iasoVariables__c FROM arce__Service_persistence__mdt where DeveloperName=:SUGGESTED_FLOW]);

        return mdtConfigList[0].arce__JSON_input__c;
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
    *-------------------------------------------------------------------------------
    * @description Method to return all the model option of the ARCE RTC
    *-------------------------------------------------------------------------------
    * @author  isabel.ascaso.contractor@bbva.com
    * @date    2023-07-24
    * @Method      returnFlow
    * @return      List
    * @example     public static List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> returnFlow()
    */
    @AuraEnabled
    @SuppressWarnings('sf:AvoidGetSetMethods')
    public static List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> getModelOptions() {
        System.debug('entra');
        final List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues = new List<Arc_Gen_RatingAsIndepProcess_controller.WfValue>();
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(MODELS_OPTIONS);
        System.debug(configs);
        if (!configs.isEmpty() && configs[0].arce__Value1__c != 'false') {
            final String configWf = configs[0].arce__Value1__c;
            for (String current : configWf.split(';')) {
                System.debug(current);
                final List<String> keyValue = current.split(':');
                System.debug(keyValue[0]);
                System.debug(keyValue[1]);
                wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(keyValue[0], keyValue[1]));
            }
        }

        return wfValues;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Wrapper used to know the flow is suggested
    * as required by the service.
    *-------------------------------------------------------------------------------
    **/
    public class SourceConditionWrapper {
        /**
        * @Description: field to check true.
        */
        public String fieldsTrue { get; set; }

        /**
        * @Description: field to check false.
        */
        public String fieldsFalse { get; set; }
        /**
        * @Description: Flow to show ; .
        */
        public String flow { get; set; }

    }
}