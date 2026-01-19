/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Persistence_Leverage_Service
* @Author   mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 28/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that get data and create json to persist.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-02-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-04-06 mariohumberto.ramirez.contractor@bbva.com
*             The method that looked for the api value of the declared fields of type list in
*             the dynamic form is eliminated because the salesforce api values are not homologated
*             with what the persistence services receive
* |2020-04-15 berthaelena.tellez.contractor@bbva.com
*             Change value N/A for NA
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
public without sharing class Arc_Gen_ServicePersitence_Utils {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param void
    * @return coid
    * @example Arc_Gen_ServicePersitence_Utils Utils = new Arc_Gen_ServicePersitence_Utils()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ServicePersitence_Utils() {

    }
    /*
        * @Description Wrapper class to manage the save of the dynamic form
    */
    public class PersistenceUtils {
        /*
            * @Description List<sObject> with the read only data in dynamic form
        */
        public List<sObject> readOnlyData {get; set;}
        /*
            * @Description List<sObject> with the data to update in the dynamic form
        */
        public List<sObject> dynamicFormData {get; set;}
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that build a Json with the info in the dynamic form
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param configInfoMap - info with the variables needed in the json
    * @param listObject - List of sObject with the dynamic form info to save
    * @return String - JSON config to the persistence service
    * @example getJsonInput(configInfoMap,listObject)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String getJsonInput(Map<String,String> configInfoMap, List<sObject> listObject) {
        PersistenceUtils wrapperInfo = new PersistenceUtils();
        List<String> relatedMapFieldLts = new List<String>();
        List<String> mapFieldReadOnLts = new List<String>();
        List<sObject> accHasAnRelData = new List<sObject>();
        List<sObject> readOnlyData = new List<sObject>();
        final Map<String,dyfr__Field_Config__c> mapFieldInfo = Arc_Gen_FieldConfig_Data.getMapFieldsInfo(new List<String>(configInfoMap.keySet()));
        String dynamicJson = '{';
        for (String mapField: mapFieldInfo.keySet()) {
            if (mapField.contains('.')) {
                relatedMapFieldLts.add(mapField);
            } else if (mapFieldInfo.get(mapField).dyfr__Read_only__c == true) {
                mapFieldReadOnLts.add(mapField);
            }
        }
        if (!relatedMapFieldLts.isEmpty()) {
            accHasAnRelData = arce.Arc_Gen_AccHasAnalysis_Data.getRelatedData(relatedMapFieldLts, String.valueOf(listObject[0].get('id')));
        }
        if (!mapFieldReadOnLts.isEmpty()) {
            readOnlyData = arce.Arc_Gen_AccHasAnalysis_Data.getRelatedData(mapFieldReadOnLts, String.valueOf(listObject[0].get('id')));
        }
        wrapperInfo.readOnlyData = readOnlyData;
        wrapperInfo.dynamicFormData = listObject;
        for (String mapField: mapFieldInfo.keySet()) {
            if (mapField.contains('.')) {
                dynamicJson += buildRelatedJson(mapField, accHasAnRelData, configInfoMap, mapFieldInfo);
            } else {
                dynamicJson += buildJson(mapFieldInfo, wrapperInfo, configInfoMap, mapField);
            }
        }
        return dynamicJson;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Build a dynamic json by type of field
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param mapFieldInfo - info of the dynamic form object
    * @param listObject - List of sObject with the dynamic form info to save
    * @param configInfoMap - info with the variables needed in the json
    * @param mapField - api name of the field to save
    * @return String - JSON config to the persistence service
    * @example buildJson(mapFieldInfo,listObject,configInfoMap,mapField)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static string buildJson(Map<String,dyfr__Field_Config__c> mapFieldInfo, PersistenceUtils wrapperInfo, Map<String,String> configInfoMap, String mapField) {
        String dynamicJson = '';
        switch on mapFieldInfo.get(mapField).dyfr__Type__c {
            when 'number', 'currency' {
                dynamicJson = '"' + configInfoMap.get((String)mapFieldInfo.get(mapField).dyfr__Map_field__c) + '":"' + getDynamicFormDoubleData(mapField, wrapperInfo, mapFieldInfo) + '",';
            }
            when 'checkbox' {
                dynamicJson = '"' + configInfoMap.get((String)mapFieldInfo.get(mapField).dyfr__Map_field__c) + '":"' + getDynamicFormCheckData(mapField, wrapperInfo, mapFieldInfo) + '",';
            }
            when 'radio group' {
                dynamicJson = '"' + configInfoMap.get((String)mapFieldInfo.get(mapField).dyfr__Map_field__c) + '":"' + getDynamicFormRadioData(mapField, wrapperInfo, mapFieldInfo) + '",';
            }
            when else {
                dynamicJson = '"' + configInfoMap.get((String)mapFieldInfo.get(mapField).dyfr__Map_field__c) + '":"' + getDynamicFormTextData(mapField, wrapperInfo, mapFieldInfo) + '",';
            }
        }
        return dynamicJson;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Build a dynamic json by type of field
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param mapField - api name of the field to save
    * @param accHasAnRelData - accoun has analysis object info
    * @param configInfoMap - info with the variables needed in the json
    * @param mapFieldInfo - info of the dynamic form object
    * @return String - JSON config to the persistence service
    * @example buildRelatedJson(mapField,accHasAnRelData,configInfoMap,mapFieldInfo)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static string buildRelatedJson(String mapField, List<arce__Account_has_Analysis__c> accHasAnRelData, Map<String,String> configInfoMap, Map<String,dyfr__Field_Config__c> mapFieldInfo) {
        String dynamicJson = '';
        switch on mapFieldInfo.get(mapField).dyfr__Type__c {
            when 'number', 'currency' {
                dynamicJson = '"' + configInfoMap.get((String)mapFieldInfo.get(mapField).dyfr__Map_field__c) + '":"' + getDataRelatedDouble(mapField, accHasAnRelData) + '",';
            }
            when 'checkbox' {
                dynamicJson = '"' + configInfoMap.get((String)mapFieldInfo.get(mapField).dyfr__Map_field__c) + '":"' + getDataRelatedCheck(mapField, accHasAnRelData) + '",';
            }
            when 'radio group'{
                dynamicJson = '"' + configInfoMap.get((String)mapFieldInfo.get(mapField).dyfr__Map_field__c) + '":"' + getDataRelatedRadio(mapField, accHasAnRelData) + '",';
            }
            when else {
                dynamicJson = '"' + configInfoMap.get((String)mapFieldInfo.get(mapField).dyfr__Map_field__c) + '":"' + getDataRelatedText(mapField, accHasAnRelData) + '",';
            }
        }
        return dynamicJson;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Get the numeric value of an Sobject
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param mapField - api name of the field to get the value
    * @param listObject - List of sObject with the dynamic form info to save
    * @return a numeric value
    * @example getDynamicFormDoubleData(mapField,listObject)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Double getDynamicFormDoubleData(String mapField, PersistenceUtils wrapperInfo, Map<String,dyfr__Field_Config__c> mapFieldInfo) {
        Double value;
        List<sObject> readOnlyDataLts = wrapperInfo.readOnlyData;
        List<sObject> dynamicDataLts = wrapperInfo.dynamicFormData;
        if (mapFieldInfo.get(mapField).dyfr__Read_only__c == true) {
            value = readOnlyDataLts[0].get(mapField) == null ? 0 : Double.valueOf(readOnlyDataLts[0].get(mapField));
        } else {
            value = dynamicDataLts[0].get(mapField) == null ? 0 : Double.valueOf(dynamicDataLts[0].get(mapField));
        }
        return value;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Get the boolean value of an Sobject
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param mapField - api name of the field to get the value
    * @param listObject - List of sObject with the dynamic form info to save
    * @return a boolean value
    * @example getDynamicFormCheckData(mapField,listObject)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Boolean getDynamicFormCheckData(String mapField, PersistenceUtils wrapperInfo, Map<String,dyfr__Field_Config__c> mapFieldInfo) {
        Boolean boolValue;
        List<sObject> readOnlyDataLts = wrapperInfo.readOnlyData;
        List<sObject> dynamicDataLts = wrapperInfo.dynamicFormData;
        if (mapFieldInfo.get(mapField).dyfr__Read_only__c == true) {
            boolValue = readOnlyDataLts[0].get(mapField) == null ? false : Boolean.valueOf(readOnlyDataLts[0].get(mapField));
        } else {
            boolValue = dynamicDataLts[0].get(mapField) == null ? false : Boolean.valueOf(dynamicDataLts[0].get(mapField));
        }
        return boolValue;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Get the label of the picklist selected in the dynamic form
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param mapField - api name of the field to get the value
    * @param listObject - List of sObject with the dynamic form info to save
    * @return the label of the picklist selected
    * @example getDynamicFormRadioData(mapField,listObject)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Boolean getDynamicFormRadioData(String mapField, PersistenceUtils wrapperInfo, Map<String,dyfr__Field_Config__c> mapFieldInfo) {
        String apiValue = '';
        List<sObject> readOnlyDataLts = wrapperInfo.readOnlyData;
        List<sObject> dynamicDataLts = wrapperInfo.dynamicFormData;
        if (mapFieldInfo.get(mapField).dyfr__Read_only__c == true) {
            apiValue = readOnlyDataLts[0].get(mapField) == null ? '' : String.valueOf(readOnlyDataLts[0].get(mapField));
        } else {
            apiValue = dynamicDataLts[0].get(mapField) == null ? '' : String.valueOf(dynamicDataLts[0].get(mapField));
        }
        return apiValue == '1' ? true : false;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Get the String value of an Sobject
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param mapField - api name of the field to get the value
    * @param listObject - List of sObject with the dynamic form info to save
    * @return a String
    * @example getDynamicFormTextData(mapField,listObject)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String getDynamicFormTextData(String mapField, PersistenceUtils wrapperInfo, Map<String,dyfr__Field_Config__c> mapFieldInfo) {
        String textValue;
        List<sObject> readOnlyDataLts = wrapperInfo.readOnlyData;
        List<sObject> dynamicDataLts = wrapperInfo.dynamicFormData;
        if (mapFieldInfo.get(mapField).dyfr__Read_only__c == true) {
            textValue = readOnlyDataLts[0].get(mapField) == null ? '' : String.valueOf(readOnlyDataLts[0].get(mapField));
        } else {
            textValue = dynamicDataLts[0].get(mapField) == null ? 'NA' : String.valueOf(dynamicDataLts[0].get(mapField));
        }
        return textValue.contains('"') ? textValue.remove('"') : textValue;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Get the Double value of a related record
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param field - api name of the field to get the value
    * @param obj - List of sObject with the dynamic form info to save
    * @return a String
    * @example getDataRelatedDouble(field,obj)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Double getDataRelatedDouble(String field, List<sObject> obj) {
        List<String> auxLts = field.split('\\.');
        return obj[0].getSobject(auxLts[0]).get(auxLts[1]) == null ? 0 : Double.valueOf(obj[0].getSobject(auxLts[0]).get(auxLts[1]));
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Get the Boolean value of a related record
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param field - api name of the field to get the value
    * @param obj - List of sObject with the dynamic form info to save
    * @return a String
    * @example getDataRelatedCheck(field,obj)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Boolean getDataRelatedCheck(String field, List<sObject> obj) {
        List<String> auxLts = field.split('\\.');
        return obj[0].getSobject(auxLts[0]).get(auxLts[1]) == null ? false : Boolean.valueOf(obj[0].getSobject(auxLts[0]).get(auxLts[1]));
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Get the label of the picklist selected in the dynamic form
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param mapField - api name of the field to get the value
    * @param listObject - List of sObject with the dynamic form info to save
    * @return the label of the picklist selected
    * @example getDynamicFormRadioData(mapField,listObject)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Boolean getDataRelatedRadio(String field, List<sObject> obj) {
        List<String> auxLts = field.split('\\.');
        String apiValue = '';
        apiValue = obj[0].getSobject(auxLts[0]).get(auxLts[1]) == null ? '' : String.valueOf(obj[0].getSobject(auxLts[0]).get(auxLts[1]));
        return apiValue == '1' ? true : false;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Get the label of a picklist selected in the dynamic form
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2020-02-28
    * @param field - api name of the field to get the value
    * @param obj - List of sObject with the dynamic form info to save
    * @return a String
    * @example getDataRelatedText(field,obj)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String getDataRelatedText(String field, List<sObject> obj) {
        List<String> auxLts = field.split('\\.');
        return obj[0].getSobject(auxLts[0]).get(auxLts[1]) == null ? 'NA' : String.valueOf(obj[0].getSobject(auxLts[0]).get(auxLts[1]));
    }
}