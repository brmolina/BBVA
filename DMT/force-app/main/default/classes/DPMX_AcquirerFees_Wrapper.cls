/**
* ____________________________________________________________________________
* Aquirer Fees Wrapper
* Wrapper class for the ASO service "acquirer-fees"
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-08-31
* @modified
* @systemLayer
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class DPMX_AcquirerFees_Wrapper {
    /*
    * @Description: Month of consultation of the acquirer's fees
    */
    @AuraEnabled
    global String consultationMonth {get; set;}
    /*
    * @Description: Month name
    */
    @AuraEnabled
    global String monthName {get; set;}
    /*
    * @Description: Year
    */
    @AuraEnabled
    global Integer year {get; set;}
    /*
    * @Description: Commission charged to acquirer
    */
    @AuraEnabled
    global String feeType {get; set;}
    /*
    * @Description: Commission charged to acquirer
    */
    @AuraEnabled
    global List<Fees> fees {get; set;}
    /*
    * @Description: Commission charged to acquirer
    */
    global class Fees {
        /*
        * @Description: Is selected
        */
        @AuraEnabled
        global Boolean isSelected {get; set;}
        /*
        * @Description: Credit Card Fee Information
        */
        @AuraEnabled
        global Decimal creditCard {get; set;}
        /*
        * @Description: Debit Card Fee Information
        */
        @AuraEnabled
        global DebitCard debitCard {get; set;}
        /*
        * @Description: International Card Fee Information
        */
        @AuraEnabled
        global Decimal internationalCard {get; set;}
        /*
        * @Description: Profitability information
        */
        @AuraEnabled
        global Profit profit {get; set;}
        /*
        * @Description: Current scenario in which the acquirer finds itself
        */
        @AuraEnabled
        global String scenarioType {get; set;}
    }
    /*
    * @Description: Debit Card Fee Information
    */
    global class DebitCard {
        /*
        * @Description: Unit type in which the data is applied
        */
        @AuraEnabled
        global String unitType {get; set;}
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
        * @Description: Unit of measurement of the interest fees in percentage
        */
        @AuraEnabled
        global Decimal value {get; set;}
    }
    /*
    * @Description: Profitability information
    */
    global class Profit {
        /*
        * @Description: Profitability as a percentage of the acquirer
        */
        @AuraEnabled
        global Decimal profitability {get; set;}
        /*
        * @Description: Acquirer's profitability in amount and currency
        */
        @AuraEnabled
        global ProfitAmount profitAmount {get; set;}
    }
    /*
    * @Description: Acquirer's profitability in amount and currency
    */
    global class ProfitAmount {
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