/**
* ____________________________________________________________________________
* Controller class for DPMX_CompanyComparison.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-07-22
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_CompanyComparison_Ctrl {
	/**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_CompanyComparison_Ctrl() {

    }
    /**
    * @description ??????????????????????
    * @param recordId : Dynamic Pricing Id
    * @param discountWrapper : Discont service wrapper
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String recordId) {
        System.debug('CAO - DPMX_CompanyComparison_Ctrl.getInitialData - recordId: ' + recordId);
        // Por alguna razón el servicio de discountWrapper no llega aunque se esté enviando desde Container - Preguntar a Torcuato
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Id =:recordId];
        Account account = [SELECT Id, Name, DES_AGGR_Sector__c FROM Account WHERE Id =: dynamicPricing.Company_Name__c];
        // DES_Activity__c
        retMap.put('account', account);
        retMap.put('success', true);
        return retMap;
    }
    /**
    * @description ??????????????????????
    * @param companies : List with companies info
    * @param accounts : Accounts to add
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> addConmpanies (List<Company_Info> companies, String accountsSelected) {
        System.debug('CAO - DPMX_CompanyComparison_Ctrl.addConmpanies - accountsSelected: ' + accountsSelected);
        Map<String, Object> retMap = new Map<String, Object>();
        //for (Account account : accountsSelected) {
        //    Company_Info company = new Company_Info();
        //    company.id = '';
        //    company.name = account.Name;
        //    company.credit = 1.45; // Falta saber cómo obtener el dato
        //    company.debit = 2.06; // Falta saber cómo obtener el dato
        //    company.international = 2.35; // Falta saber cómo obtener el dato
        //    companies.add(company);
        //}
        retMap.put('companies', companies);
        retMap.put('success', true);
        return retMap;
    }
    public class Company_Info {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public Decimal credit {get; set;}
        @AuraEnabled
        public Decimal debit {get; set;}
        @AuraEnabled
        public Decimal international {get; set;}
    }
}