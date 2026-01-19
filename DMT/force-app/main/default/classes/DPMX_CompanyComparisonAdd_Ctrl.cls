/**
* ____________________________________________________________________________
* Controller class for DPMX_CompanyComparisonAdd.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-09-26
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_CompanyComparisonAdd_Ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_CompanyComparisonAdd_Ctrl() {

    }
    /**
    * @description Get data
    * @param dynamicPricing : dynamicPricing record
    * @param companyComparisonList : List of stored DPMX_Company_Comparison__c records
    * @param discountWrapper : Discont service wrapper
    * @return List of companies that will be shown on lightning:dualListbox
    */
    @AuraEnabled
    public static Map<String,Object> getData (String recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        Set<Id> accountIdSet = new Set<Id>();
        System.debug(recordId);
        List<DPMX_Company_Comparison__c> companyComparisionexistenLst = [Select Id, Name, companyName__c, Dynamic_Pricing__c, groupName__c, Company__c, Debit__c, Credit__c, International__c, CurrencyIsoCode, isVisible__c, isGs__c
                FROM DPMX_Company_Comparison__c WHERE Dynamic_Pricing__c =:recordId];
                List<DPMX_Company_Comparison__c> companyComparisionvisibleLst =  new List<DPMX_Company_Comparison__c>();
                System.debug(companyComparisionexistenLst);
            for(DPMX_Company_Comparison__c companyComparison : companyComparisionexistenLst){
                if(companyComparison.isVisible__c){
                    companyComparisionvisibleLst.add(companyComparison);
                }
            }
            retMap.put('accountsSelected', companyComparisionvisibleLst);
            retMap.put('accountsOptions', companyComparisionexistenLst);
        retMap.put('success', true);
        return retMap;
    }
    /**
    * @description Insert/Delete data into DPMX_Company_Comparison__c object
    * @param accountsSelected : List of selected companies
    * @param companyComparisonList : List of stored DPMX_Company_Comparison__c records
    * @return retMap with success as true
    */
    @AuraEnabled
    public static Map<String,Object> saveData (String recordId, List<String> accountsSelected) {
        Map<String, Object> retMap = new Map<String, Object>();
        List<DPMX_Company_Comparison__c> companyComparisionexistenLst = [Select Id, isVisible__c
                FROM DPMX_Company_Comparison__c WHERE Dynamic_Pricing__c =:recordId];
        List<DPMX_Company_Comparison__c> companyComparisionToUpdtLst = new List<DPMX_Company_Comparison__c>();
                for(DPMX_Company_Comparison__c companyComparison : companyComparisionexistenLst){
                    system.debug(accountsSelected.contains(companyComparison.id) + ' - '+ companyComparison.id + ' - ' +accountsSelected);
                    companyComparison.isVisible__c = accountsSelected.contains(companyComparison.id);
                    companyComparisionToUpdtLst.add(companyComparison);
                }
                Update companyComparisionToUpdtLst;

        retMap.put('success', true);
        return retMap;
    }
}