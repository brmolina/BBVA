/**
* ____________________________________________________________________________
* Acquirer Activities Fees Wrapper
* Wrapper class for the ASO service "acquirer-activities/fees"
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-02-06
* @modified
* @systemLayer
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class DPMX_AcquirerActivitiesFees_Wrapper {
    /*
    * @Description: Commission charged to acquirer
    */
    @AuraEnabled
    global String commissionType {get; set;}
    /*
    * @Description: Verify tipe of debit
    */
    @AuraEnabled
    global Boolean isDebit {get; set;}
    /*
    * @Description: Month of consultation of the acquirer's fees
    */
    @AuraEnabled
    global String consultMonth {get; set;}
    /*
    * @Description: Unique identifier of the acquisition fees
    */
    @AuraEnabled
    global String id {get; set;}
    /*
    * @Description: Information on acquirer's fees
    */
    @AuraEnabled
    global List<Scenario> scenarios {get; set;}
    /*
    * @Description: Information on acquirer's fees
    */
    global class Scenario {
        /*
        * @Description: Current scenario in which the acquirer finds itself
        */
        @AuraEnabled
        global String scenarioType {get; set;}
        /*
        * @Description: 
        */
        @AuraEnabled
        global Fees fees {get; set;}
    }
    /*
    * @Description: Information on acquirer's fees
    */
    global class Fees {
        /*
        * @Description: Detail of each fee
        */
        @AuraEnabled
        global List<ItemizeFees> itemizeFees {get; set;}
        /*
        * @Description: Profitability information
        */
        @AuraEnabled
        global Profitability profitability {get; set;}
    }
    /*
    * @Description: Detail of each fee
    */
    global class ItemizeFees {
        /*
        * @Description: Description of the fee type
        */
        @AuraEnabled
        global String feeType {get; set;}
        /*
        * @Description: Detail mode in which the collection fee is applied
        */
        @AuraEnabled
        global ItemizeFeeUnit itemizeFeeUnit {get; set;}
    }
    /*
    * @Description: Detail mode in which the collection fee is applied
    */
    global class ItemizeFeeUnit {
        /*
        * @Description: Monetary amount
        */
        @AuraEnabled
        global Decimal amount {get; set;}
        /*
        * @Description: String based on ISO-4217 for specifying the currency related to the monetary amount
        */
        @AuraEnabled
        global String currency_y {get; set;}
        /*
        * @Description: Unit type in which the data is applied
        */
        @AuraEnabled
        global String unitType {get; set;}
        /*
        * @Description: Unit of measurement of the interest fees
        */
        @AuraEnabled
        global Decimal value {get; set;}
    }
    /*
    * @Description: Profitability information
    */
    global class Profitability {
        /*
        * @Description: Profitability as a percentage of the acquirer
        */
        @AuraEnabled
        global Decimal percentage {get; set;}
        /*
        * @Description: Acquirer's profitability in amount and currency
        */
        @AuraEnabled
        global AmountCurrency amount {get; set;}
    }
    /*
    * @Description: amount + currency fields
    */
    global class AmountCurrency {
        /*
        * @Description: Monetary amount
        */
        @AuraEnabled
        global Decimal amount {get; set;}
        /*
        * @Description: String based on ISO-4217 for specifying the currency related to the monetary amount
        */
        @AuraEnabled
        global String currency_y {get; set;}
    }
}