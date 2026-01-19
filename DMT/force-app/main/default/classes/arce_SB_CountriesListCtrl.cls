/**
* ____________________________________________________________________________
* Controller class for arce_ShadowBanking.cmp aura Component
* ____________________________________________________________________________
* @author      DAvid Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-10-10
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global with sharing class arce_SB_CountriesListCtrl {
 /**
    * @description Private constructor to avoid sonar err
    */
    public arce_SB_CountriesListCtrl() {

    }
    /**
    * @description Get data from services
    * @param 
    * @return retMap list
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData () {
        Map<String, Object> retMap = new Map<String, Object>();
        Map<String,String> bankCountriesSBList =ARC_utils.bankCountriesSBList();
        Map<String,String> insurerCountriesSBList =ARC_utils.insurerCountriesSBList();

        retMap.put('bankCountriesSBList',bankCountriesSBList);
        retMap.put('insurerCountriesSBList',insurerCountriesSBList); 

        return retMap;
    }
}