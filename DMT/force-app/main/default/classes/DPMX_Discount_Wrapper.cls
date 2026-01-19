/**
* ____________________________________________________________________________
* Discounts Wrapper
* Wrapper class for the ASO service "discounts"
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-08-29
* @modified
* @systemLayer
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class DPMX_Discount_Wrapper {
    /*
    * @Description: Month and year of information consulted
    */
    @AuraEnabled
    global String consultingDate {get; set;}
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
    * @Description: Discount and interchange rates for grouping of lines of business that are governed by the customer's economic activity
    */
    @AuraEnabled
    global List<Rates> rates {get; set;}
    /*
    * @Description: Billing information
    */
    global class Rates {
        /*
        * @Description: Credit rate information
        */
        @AuraEnabled
        global Percentage credit {get; set;}
        /*
        * @Description: Rate identifier
        */
        @AuraEnabled
        global String id_y {get; set;}
        /*
        * @Description: International rate information
        */
        @AuraEnabled
        global Percentage international {get; set;}
        /*
        * @Description: For "INTERCHANGE" refers to the debit exchange number for the draft, for "DISCOUNT" maximum number of debit discount and "AVERAGE_DISCOUNT" average number of debit discount per draft
        */
        @AuraEnabled
        global Decimal number_y {get; set;}
        /*
        * @Description: Flag indicating whether the information is shown in rate or quota
        */
        @AuraEnabled
        global String unitType {get; set;}
    }
    /*
    * @Description: percentage field
    */
    global class Percentage {
        /*
        * @Description: percentage field
        */
        @AuraEnabled
        global Decimal percentage {get; set;}
    }
}