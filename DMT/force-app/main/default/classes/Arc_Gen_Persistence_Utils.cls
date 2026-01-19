/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Persistence_Utils
* @Author   Javier Soto Carrascosa
* @Date     Created: 04/042020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages save for Basic Data
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-04 Javier Soto Carrascosa
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-10-26 Juan Ignacio Hita
*             Add addDateToMap method
* |2021-01-12 Juan Ignacio Hita
*             Add CODES_ACCEPT and 202 code
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_Persistence_Utils {

    /**
        * @Description: Name of service for copy all the limits
    */
    static final List<String> CODES_ACCEPT = new List<String> {'200', '201', '202', '204'};

    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Arc_Gen_Persistence_Utils
    * -----------------------------------------------------------------------------------------------------
    * @Author   Javier Soto
    * @Date     2020-04-06
    * @param    null
    * @return   Arc_Gen_Persistence_Utils
    * @example  new Arc_Gen_Persistence_Utils()
    * */
    @TestVisible
    private Arc_Gen_Persistence_Utils() {}
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Custom Exception for Persistence Utils
    * ----------------------------------------------------------------------------------------------------
    * @Author   Javier Soto Carrascosa  javier.soto.carrascosa@bbva.com
    * @Date     Created: 2020-02-24
    * @example throw new PersistenceException('Unexpected Error');
    * ----------------------------------------------------------------------------------------------------
    **/
    public class PersistenceException extends Exception {}
    /**
    *-------------------------------------------------------------------------------
    * @description  Method getAhaFromSobject
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2020-04-04
    * @param List<sObject> listObject
    * @return   arce__Account_has_Analysis__c
    * @example getAhaFromSobject(listObject)
    **/
    public static arce__Account_has_Analysis__c getAhaFromSobject(List<sObject> listObject) {
        arce__Account_has_Analysis__c ahaData = new arce__Account_has_Analysis__c();
        Integer ahaCount = 0;
        for(sObject obj : listObject) {
            switch on obj {
                when arce__Account_has_Analysis__c aha {
                    ahaCount++;
                    ahaData = aha;
                }
            }
        }
        if (ahaCount>1 || ahaCount==0) {
            throw new PersistenceException('Unexpected persistence error');
        }
        return ahaData;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that fields Map and Key if Map is filled
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param Map<String, Object> finalWSMap
    * @param string - key
    * @param Map<String,Object>  - keyValue
    * @return Map<String, Object> with WS structure for objects that are filled
    * @example addifFilled(finalWSMap,key,keyValue)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addifFilled(Map<String, Object> finalWSMap, String key, Map<String,Object> keyValue) {
        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoMapObj(keyValue)) {
            finalWSMap.put(key,keyValue);
        }
        return finalWSMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that fields Map and Key if List Map is filled
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param List<Map<String, Object>> finalWSMap
    * @param string - key
    * @param Map<String,Object>  - keyValue
    * @return Map<String, Object> with WS structure for objects that are filled
    * @example addifFilled(finalWSMap,key,keyValue)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> addifFilledList(Map<String, Object> finalWSMap, String key, List<Map<String,Object>> keyValue) {
        if (arce.Arc_Gen_ValidateInfo_utils.hasInfoListMapObj(keyValue)) {
            finalWSMap.put(key,keyValue);
        }
        return finalWSMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for business risk info callout
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param String - iasoWS
    * @param String - jsonWS
    * @return boolean - callout executed OK / KO
    * @example addIndicators(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean executePersistence(String iasoWS, String jsonWS) {
        boolean res;
        final arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        iasoResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(iasoWS,jsonWS);
        serviceAndSaveResp.serviceCode = iasoResponse.serviceCode;
        serviceAndSaveResp.serviceMessage = iasoResponse.serviceMessage;
        if(CODES_ACCEPT.contains(serviceAndSaveResp.serviceCode)) {
            res = true;
        } else {
            PersistenceException excep = new PersistenceException();
            excep.setMessage('Unexpected persistence error');
            throw excep;
        }
        return res;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method to retrieve ENUM from map an code
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param string - key
    * @param Map<String,String> - map of enums
    * @return String
    * @example getEnumFromMap(code,originMap)
    * -----------------------------------------------------------------------------------------------
    **/
    public static String getEnumFromMap(String code, Map<String,String> originMap) {
        String finalEnum = '';
        if (originMap.containsKey(code)) {
            finalEnum = originMap.get(code);
        } else {
            throw new PersistenceException('Error Mapping ENUM, code does not exist.');
        }
        return finalEnum;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method to retrieve default value for list selecto
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param string - key
    * @return String
    * @example defaultValueList(code)
    * -----------------------------------------------------------------------------------------------
    **/
    public static String defaultValueList(String code) {
        String returnCode;
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled(code)) {
            returnCode = code;
        } else {
            returnCode = '0';
        }
        return returnCode;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method to retrieve default value for list selecto
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param string - key
    * @return String
    * @example defaultValueList(code)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean booleanFromYesNo(String value) {
        Boolean returnBool;
        if (value==null || value == '2') {
            returnBool = false;
        } else {
            returnBool = true;
        }
        return returnBool;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Get Configuration Information
    *--------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 10/04/2020
    * @param configurationName - String with the configuration name
    * @return arce__Service_persistence__mdt
    * @example public arce__Service_persistence__mdt getConfigurationInfo(String configurationName)
    *--------------------------------------------------------------------------------
    **/
    public static Map<String, arce__Service_persistence__mdt> getConfigurationInfo(List<String> configurationNames) {
        final Map<String, arce__Service_persistence__mdt> mapListConfigs = new Map<String, arce__Service_persistence__mdt>();
        final List<arce__Service_persistence__mdt> mdtConfigList = new List<arce__Service_persistence__mdt>([SELECT DeveloperName, Id, arce__JSON_input__c, arce__api_field_Name__c, arce__iasoVariables__c FROM arce__Service_persistence__mdt where DeveloperName=:configurationNames]);
        if (mdtConfigList.size() == configurationNames.size()) {
            for (arce__Service_persistence__mdt configElement : mdtConfigList) {
                mapListConfigs.put(configElement.DeveloperName, configElement);
            }
        } else {
            throw new QueryException('Error, missing Persistence Configuration'+configurationNames);
        }
        return mapListConfigs;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Add date value in objInput map
    *--------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   26/10/2020
    * @param  Map<String, Object> objInput
    * @param  String keyValue
    * @param  Date valueFld
    * @return void
    * @example addDateToMap(objInput, keyValue, valueFld);
    *--------------------------------------------------------------------------------
    **/
    public static void addDateToMap(Map<String, Object> objInput, String keyValue, Date valueFld) {
        if (valueFld != null) {
            final List<String> lstDate = String.valueOf(valueFld).split(' ');
            objInput.put(keyValue, lstDate[0]);
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Check and abbreviate string
    *--------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date   19/11/2021
    * @param  String inputString
    * @param  Integer maxChar
    * @return String
    * @example cutString(inputString, maxChar);
    *--------------------------------------------------------------------------------
    **/
    public static String cutString(String inputString, Integer maxChar) {
      final String returnCutted;
      if (arce.Arc_Gen_ValidateInfo_utils.isFilled(inputString)) {
          returnCutted = inputString.abbreviate(maxChar);
      }
      return returnCutted;
  }
}