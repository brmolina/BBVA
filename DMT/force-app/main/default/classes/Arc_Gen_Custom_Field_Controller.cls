/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Custom_Field_Controller
* @Author   aleksandar.dinkov.contractor@bbva.com 
* @Date     Created: 2023-07-10
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description: Arc_Gen_Custom_Field_Controller
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2023-07-10       aleksandar.dinkov.contractor@bbva.com            Class creation.
* ------------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_Custom_Field_Controller {
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		2023-07-10
    * @author	aleksandar.dinkov.contractor@bbva.com
    */
    @TestVisible
    private Arc_Gen_Custom_Field_Controller() {

    }
    /**
    * @description fetchAccounts
    * @author aleksandar.dinkov.contractor@bbva.com | 2023-07-10
    * @param String recordId
    * @param String fieldName
    * @param String objectName
    * @return String
    **/
    @AuraEnabled
    public static String getFieldValue(String ahaId, String fieldName, String objectName) {
        String returnValue;
        sObject obj;
        switch on objectName {
            when 'arce__Modifier__c' {
                obj = (arce__Modifier__c) arce.Arc_Gen_Modifiers_Utils.getModifierInfo(new Set<String>{ahaId})[0];
            } when 'arce__AHA_Extension__c' {
                final arce__Account_has_Analysis__c ahaObj = (arce__Account_has_Analysis__c) getSObjectInfo('arce__Account_has_Analysis__c', ahaId, null);
                obj = (arce__AHA_Extension__c) getSObjectInfo('arce__AHA_Extension__c', ahaObj.arce__AHA_Extension__c, null);
            } when 'arce__Account_has_Analysis__c' {
                obj = (arce__Account_has_Analysis__c) getSObjectInfo('arce__Account_has_Analysis__c', ahaId, null);
            }
        }
        try {
            returnValue = String.valueOf(Decimal.valueOf(String.valueOf(obj.get(fieldName))).setScale(2));
        } catch (Exception ex) {
            returnValue = String.valueOf(obj.get(fieldName));
        }
        return returnValue;
    }
    /**
    * @description getSObjectInfo
    * @author aleksandar.dinkov.contractor@bbva.com | 2023-07-10
    * @param String objectName
    * @param String recordId
    * @param List<String> moreFields
    * @return SObject
    **/
    public static SObject getSObjectInfo(String objectName, String recordId, List<String> moreFields) {
        String fieldsString = arce.Arc_Gen_GenericUtilities.getAllFields(objectName);
        List<String> allFields = fieldsString.split(',');
        Integer index = allFields.indexOf('lastvieweddate');
        if(index != -1) {
            allFields.remove(index);
        }
        index = allFields.indexOf('lastreferenceddate');
        if(index != -1) {
            allFields.remove(index);
        }
        if(moreFields != null) {
            allFields.addAll(moreFields);
        }
        String queryString = 'SELECT ' + String.join(allFields, ',');
        queryString += ' FROM ' + objectName + ' WHERE Id = :recordId';
        return Database.query(String.escapeSingleQuotes(queryString));
    }

}