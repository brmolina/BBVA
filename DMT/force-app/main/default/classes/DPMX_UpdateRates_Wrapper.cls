/**
* ____________________________________________________________________________
* Acquirer Activities Wrapper
* Wrapper class for the ASO service "acquirer-activities"
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-11-09
* @modified
* @systemLayer
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class DPMX_UpdateRates_Wrapper {
    
    /*
    * @Description: Costumer id.
    */
    @AuraEnabled
    global String customerId {get; set;}
    /*
    * @Description: Scope of service at the banking level.
    */
    @AuraEnabled
    global String storePay {get; set;}
    /*
    * @Description: Start date of validity of the rate.
    */
    @AuraEnabled
    global String startDate {get; set;}
    /*
    * @Description: Rate expiration date.
    */
    @AuraEnabled
    global String expirationDate {get; set;}
    /*
    * @Description: DTO with information of executive user requesting the update of rates.
    */
    @AuraEnabled
    global BusinessAgent businessAgent {get; set;}
    /*
    * @Description: DTO with information of executive user requesting the update of rates.
    */
    global class BusinessAgent {
        /*
        * @Description: Id of executive user requesting the update of rates.
        */
        @AuraEnabled
        global String id {get; set;}
    }
    /*
    * @Description: DTO with information of executive order authorizing the updating of rates.
    */
    @AuraEnabled
    global BusinessAgentAuthorizes businessAgentAuthorizes {get; set;}
    /*
    * @Description: DTO with information of executive order authorizing the updating of rates.
    */
    global class BusinessAgentAuthorizes {
        /*
        * @Description: Id of executive order authorizing the updating of rates.
        */
        @AuraEnabled
        global String id {get; set;}
    }
    
    /*
    * @Description: List of DTOs with data input information to online Update rates.
    */
    @AuraEnabled
    global List<Rates> rates {get; set;}
    /*
    * @Description: List of DTOs with data input information to online Update rates.
    */
    global class Rates {
        /*
        * @Description: Rate type code.
        */
        @AuraEnabled
        global String typeCode {get; set;}
        /*
        * @Description: Detail mode in which the collection fee is applied.
        */
        @AuraEnabled
        global Fee fee {get; set;}
    }
    
    /*
    * @Description: List of DTOs with data input information to online Update rates.
    */
    global class Fee {
        /*
        * @Description: Value expressed in amount mode.
        */
        @AuraEnabled
        global Amount amount {get; set;}
        /*
        * @Description: Value expressed in percentage mode.
        */
        @AuraEnabled
        global Percentage percentage {get; set;}
    }
    
    /*
    * @Description: List of DTOs with data input information to online Update rates.
    */
    global class Amount {
        /*
        * @Description: Rate Amount.
        */
        @AuraEnabled
        global decimal amount {get; set;}
        /*
        * @Description: String based on ISO-4217 for specifying the currency.
        */
        @AuraEnabled
        global String currency_c {get; set;}
    }
    
    /*
    * @Description: List of DTOs with data input information to online Update rates.
    */
    global class Percentage {
        /*
        * @Description: Rate percentage.
        */
        @AuraEnabled
        global decimal value {get; set;}
    }

}