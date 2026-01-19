/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_LimitsTypologies_Data
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Data class for arce__limits_typology__c object
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-20 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-26-11 mariohumberto.ramirez.contractor@bbva.com
*             Added new filter to the query in the method getTypologiesData().
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Added new method getTypologiesByDevName
* |2020-06-12 mariohumberto.ramirez.contractor@bbva.com
*             Added 'getTypologyMap' method
* |2020-07-27 joseluis.garcia4.contractor@bbva.com
*             Add arce__Typology_Order__c and parent topology ID in getTypologiesData()
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_LimitsTypologies_Data {

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_LimitsTypologies_Data data = new Arc_Gen_LimitsTypologies_Data()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_LimitsTypologies_Data() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return arce__limits_typology__c data
    * -----------------------------------------------------------------------------------------------
    * @param - void
    * @return - A List of arce__limits_typology__c data
    * @example getTypologiesData()
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__limits_typology__c> getTypologiesData() {
        return [SELECT Id,Name, arce__risk_typology_level_id__c, arce__risk_typology_parent_id__c, arce__risk_typology_level_type__c, arce__risk_typology_active__c, arce__risk_typo_ext_id__c, arce__Typology_Order__c, arce__risk_typology_parent_id__r.arce__risk_typology_level_id__c FROM arce__limits_typology__c WHERE arce__risk_typology_active__c = TRUE ORDER BY arce__risk_typology_level_id__c];
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the row information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param devName -  developer name of the typology
    * @return arce__limits_typology__c record
    * @example getTypologiesByDevName(devName)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__limits_typology__c getTypologiesByDevName(String devName) {
        return [SELECT Id,Name, arce__risk_typology_level_id__c, arce__risk_typology_parent_id__c, arce__risk_typology_level_type__c, arce__risk_typology_active__c, arce__risk_typo_ext_id__c FROM arce__limits_typology__c WHERE arce__risk_typology_active__c = TRUE AND arce__risk_typology_level_id__c = :devName];
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description a map with the limit tipology info
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-06-12
    * @param void
    * @return Map<Id,arce__limits_typology__c>
    * @example getTypologyMap()
    * --------------------------------------------------------------------------------------
    **/
    public static Map<Id,arce__limits_typology__c> getTypologyMap() {
        Map<Id,arce__limits_typology__c> mapRet = new Map<Id,arce__limits_typology__c>();
        final List<arce__limits_typology__c> limTypoData = getTypologiesData();
        for (arce__limits_typology__c limTypo: limTypoData) {
            mapRet.put(limTypo.Id, limTypo);
        }
        return mapRet;
    }
}