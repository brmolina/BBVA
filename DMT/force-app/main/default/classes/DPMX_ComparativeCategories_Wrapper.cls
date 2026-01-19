/**
* ____________________________________________________________________________
* Corporate Rates Wrapper
* Wrapper class for the ASO service "corporate-rates"
* ____________________________________________________________________________
* @author      David Otero Garcia <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-09-04
* @modified
* @systemLayer
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class DPMX_ComparativeCategories_Wrapper {
    /*
    * @Description: Descripion the categories to which the acquiring customer belongs, refers to a grouping of business lines that are governed by the customer's economic activity and are defined according to the business lines classified by the regulatory entity for these services, which is BANXICO.
    */
    @AuraEnabled
    global String description {get; set;}

    /*
    * @Description: Unique identifier of the category.
    */
    @AuraEnabled
    global String id {get; set;}

    /*
    * @Description: Information about the business related to the customer
    */
    @AuraEnabled
    global List<BusinessInformations> businessInformations {get; set;}
    
    /*
    * @Description: Information about the business related to the customer
    */
    global class BusinessInformations {
        /*
        * @Description: Official identifying name of the Company of those legal entities that are clients of the Entity
        */
        @AuraEnabled
        global String companyName {get; set;}
        /*
        * @Description: Description of the family to which the acquiring customer belongs, refers to a grouping of business lines that are governed by the customer's economic activity and are defined according to the business lines classified by the regulatory entity for these services, which is BANXICO
        */
        @AuraEnabled
        global Rate rate {get; set;}
        /*
        * @Description: Name that allows the Group to be unequivocally identified
        */
        @AuraEnabled
        global String groupName {get; set;}
    }

    /*
    * @Description: Information about the rates of the category.
    */
    global class Rate {
        /*
        * @Description: Detail of each rate.
        */
        @AuraEnabled
        global List<ItemizeRates> itemizeRates {get; set;}
    }

    /*
    * @Description: Detail of each rate.
    */
    global class ItemizeRates {
        /*
        * @Description: Description of the rate type.
        */
        @AuraEnabled
        global String rateType {get; set;}

        /*
        * @Description: Detail mode in which the collection rate is applied.
        */
        @AuraEnabled
        global ItemizeRateUnit itemizeRateUnit {get; set;}
    }

    /*
    * @Description: Detail mode in which the collection rate is applied.
    */
    global class ItemizeRateUnit {
        /*
        * @Description: Unit type in which the data is applied.
        */
        @AuraEnabled
        global String unitType {get; set;}

        /*
        * @Description: Unit of measurement of the interest rate.
        */
        @AuraEnabled
        global Decimal value {get; set;}

        /*
        * @Description: Monetary amount.
        */
        @AuraEnabled
        global Decimal amount {get; set;}

        /*
        * @Description: String based on ISO-4217 for specifying the currency.
        */
        @AuraEnabled
        global String currency_y {get; set;}
    }
}