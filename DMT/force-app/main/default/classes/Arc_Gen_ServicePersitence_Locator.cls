/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ServicePersitence_Locator
* @Author   mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 28/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that obtains the data of the custom metadata Service Persistence
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-02-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_ServicePersitence_Locator {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-28
    * @param void
    * @return void
    * @example Arc_Gen_ServicePersitence_Locator locator = new Arc_Gen_ServicePersitence_Locator()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ServicePersitence_Locator() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-28
    * @param configurationName - Developer name of the custom metadatata to consult
    * @return Map<String,String> - Map with the configuration info
    * @example retConfigurationInfo(configurationName)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Map<String,String> retConfigurationInfo(String configurationName) {
        final Map<String,String> configInfoMap = new Map<String,String>();
        final List<arce__Service_persistence__mdt> configurationInfo = getPersistenceInfo(configurationName);
        if (configurationInfo.isEmpty()) {
            throw new Queryexception(Label.Arc_Gen_MetadataListEmpty);
        } else {
            final List<String> mapFieldsLts = (List<String>)configurationInfo[0].arce__api_field_Name__c.split(',');
            final List<String> iasoParamsLts = (List<String>)configurationInfo[0].arce__iasoVariables__c.split(',');
            if (iasoParamsLts.size() == mapFieldsLts.size()) {
                for (integer i = 0; i < iasoParamsLts.size(); i++) {
                    configInfoMap.put(mapFieldsLts[i], iasoParamsLts[i]);
                }
            } else {
                throw new ListException(Label.Arc_Gen_DiffListSize);
            }
        }
        return configInfoMap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description  Get Configuration Information
    *--------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-02-28
    * @param configurationName - String with the configuration name
    * @return List<arce__Service_persistence__mdt>
    * @example getPersistenceInfo(configurationName)
    *--------------------------------------------------------------------------------
    **/
    public static List<arce__Service_persistence__mdt> getPersistenceInfo(String configurationName) {
        return [SELECT Id, arce__api_field_Name__c, arce__JSON_input__c, arce__iasoVariables__c FROM arce__Service_persistence__mdt WHERE DeveloperName = :configurationName];

    }
}