/**
* --------------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_RAIPRunWayURLs
* @Author   Antonio Muñoz Pérez  antonio.munoz.perez.contractor@bbva.com
* @Date     Created: 2021-04-29
* @Group    ARCE
* --------------------------------------------------------------------------------------------------------
* @Description  GBL class that implements Arc_Gen_GetRAIPRunWayURLs_Interface
* --------------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-04-29 antonio.munoz.perez.contractor@bbva.com
*             Class creation.
* --------------------------------------------------------------------------------------------------------
*/
public With Sharing class Arc_GBL_RAIPRunWayURLs implements Arc_Gen_GetRAIPRunWayURLs_Interface {
    /**
        * @Description: Name of the configuration for organization url runway
    */
    static final String ORG_URL = 'OrgUrlRunAway';
    /**
        * @Description: Name of the configuration with url of visualforce runway
    */
    static final String VF_URL = 'VfUrlRunAway';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that returns the url parameters to connect RAIP runway to global org
    * ----------------------------------------------------------------------------------------------------
    * @Author   antonio.munoz.perez.contractor@bbva.com
    * @Date     2021-04-29
    * @example urlsConfig ()
    * ----------------------------------------------------------------------------------------------------
    **/
    public Arc_Gen_RatingAsIndepProcess_service.RunWayURLConfig urlsConfig () {
        final Arc_Gen_RatingAsIndepProcess_service.RunWayURLConfig rWConfig = new Arc_Gen_RatingAsIndepProcess_service.RunWayURLConfig ();
        rWConfig.orgURL = Arc_Gen_ArceUrlsConfigs_locator.getConfigurationInfo(ORG_URL).url__c;
        rWConfig.vfURL = Arc_Gen_ArceUrlsConfigs_locator.getConfigurationInfo(VF_URL).url__c + 'OOO_AccountProxy';
        return rWConfig;
    }
}