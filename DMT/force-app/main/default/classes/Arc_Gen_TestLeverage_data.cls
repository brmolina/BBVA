/**
* @File Name          : Arc_Gen_TestLeverage_data.cls
* @Description        : Contains the data methods of the test leveraged
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : cesaroctavio.villanueva.cebal@bbva.com
* @Last Modified On   : 04/06/2020 17:43:29
* @Changes            :
*=======================================================================================================================================
* Ver         Date                     Author                       Modification
*=======================================================================================================================================
* 1.0    30/4/2019  18:00:36   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    23/7/2019  18:00:36   luisruben.quinto.munoz@bbva.com     delete un used method
* 1.1.1  02/12/2019            german.sanchez.perez.contractor@bbva.com
*                              franciscojavier.bueno@bbva.com               Api names modified with the correct name on business glossary
* 1.1    05/3/2020  18:00:36   mariohumberto.ramirez.contractor@bbva.com    deleted unused method
* 1.2    04/06/2020 17:43:29   cesaroctavio.villanueva.cebal@bbva.com       Added new fields required for test leveraged
* 1.3    18/08/2020 10:00:00   joseluis.garcia4.contractor@bbva.com         Add arce__currency_id__c field to getAccountHasAnalysis()
**/
public with sharing class Arc_Gen_TestLeverage_data {
/**
*-------------------------------------------------------------------------------
* @description wrapper for the class
*--------------------------------------------------------------------------------
* @author  eduardoefrain.hernandez.contractor@bbva.com
* @date    30/4/2019
* @Method: SaveResult
* @param:  null
* @return  null
**/
    public class SaveResult {
        public String status {get;set;}
        public String message {get;set;}
    }
/**
*-------------------------------------------------------------------------------
* @description Method that gets an Account Has Analysis record
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param String analysisId
* @return arce__Account_has_Analysis__c - record queried
* @example public arce__Account_has_Analysis__c getAccountHasAnalysis(String analysisId)
**/
    public arce__Account_has_Analysis__c getAccountHasAnalysis(String analysisId) {
        return [SELECT id,currencyIsoCode,arce__Analysis__c,arce__currency_id__c,arce__current_proposed_amount__c,arce__Customer__r.controlled_by_sponsor_type__c,arce__ffss_for_rating_id__r.arce__rating_final__c,arce__smes_eur_comuty_defn_type__c,arce__gross_financial_debt_amount__c,arce__ebitda_interest_number__c,arce__ll_before_adj_ind_type__c,arce__ll_before_adj_clsfn_type__c,arce__ll_after_adj_ind_type__c,arce__ll_after_adj_clsfn_type__c,arce__ll_adj_debt_amount__c,arce__ll_adj_ebitda_amount__c,arce__Analysis__r.arce__controlled_by_sponsor_type__c,arce__current_proposed_local_amount__c,arce__group_asset_header_type__c,arce__employees_number__c FROM arce__Account_has_Analysis__c WHERE Id =: analysisId][0];
    }
/**
*-------------------------------------------------------------------------------
* @description Method that gets the leveraged results in an AccountHasAnalysis record
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param String analysisId
* @return arce__Account_has_Analysis__c - record queried
* @example public arce__Account_has_Analysis__c getLeveragedResults(String analysisId)
**/
    public arce__Account_has_Analysis__c getLeveragedResults(String analysisId) {
        return [SELECT id,toLabel(arce__ll_before_adj_ind_type__c),toLabel(arce__ll_before_adj_clsfn_type__c),toLabel(arce__ll_after_adj_ind_type__c),toLabel(arce__ll_after_adj_clsfn_type__c) FROM arce__Account_has_Analysis__c WHERE Id =: analysisId][0];
    }
/**
*-------------------------------------------------------------------------------
* @description Method that updates an sObject record
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param sObject recordToUpdate
* @return SaveResult - A Wrapper with information of the results of the DML operation
* @example public SaveResult updateRecord(sObject recordToUpdate)
**/
    public SaveResult updateRecord(sObject recordToUpdate) {
        final SaveResult updateResults = new SaveResult();
        try {
            updateResults.status = 'true';
            update(recordToUpdate);
        } catch(DmlException ex) {
            updateResults.status = 'false';
            updateResults.message = ex.getMessage();
        }
        Return updateResults;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that gets the currency of the org
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param String isoCode - Code of the org currency ex. MXN, USD, EUR
* @return CurrencyType - record record queried
* @example public CurrencyType getCurrency(String isoCode)
**/
    public CurrencyType getCurrency(String isoCode) {
        Return [SELECT ConversionRate FROM CurrencyType WHERE IsoCode =: isoCode LIMIT 1];
    }
}