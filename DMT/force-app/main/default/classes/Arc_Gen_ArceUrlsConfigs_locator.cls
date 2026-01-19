/**
* @Name               : Arc_GBL_RAIPRunWayURLs
* @Description        : Class that obtains the data of Arce URL configurations
* @Author             : juanignacio.hita.contractor@bbva.com
* @Group              : ARCE Team
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    04/08/2021   juanignacio.hita.contractor@bbva.com    Initial Version
**/
public without sharing class Arc_Gen_ArceUrlsConfigs_locator {
    /**
        * @Description: Constructor by default
    */
    @TestVisible
    private Arc_Gen_ArceUrlsConfigs_locator() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  Get Configuration Information
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    04/08/2021
    * @param   configurationName - String with the configuration name
    * @return  arce__UrlsArce__c
    * @example List<arce__UrlsArce__c> lst = getConfigurationInfo(configurationName);
    *--------------------------------------------------------------------------------
    **/
    public static UrlsArce__c getConfigurationInfo(String configurationName) {
        final List<UrlsArce__c> mdtUrlsList = new List<UrlsArce__c>([SELECT Id, Name, url__c, parameters_url__c FROM UrlsArce__c
                                                                                WHERE Name = :configurationName]);
        UrlsArce__c urlsArce = null;
        if (!mdtUrlsList.isEmpty()) {
            urlsArce = mdtUrlsList[0];
        }
        return urlsArce;
    }

}