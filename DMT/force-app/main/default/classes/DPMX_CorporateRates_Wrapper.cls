/**
* ____________________________________________________________________________
* Corporate Rates Wrapper
* Wrapper class for the ASO service "corporate-rates"
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
global class DPMX_CorporateRates_Wrapper {

    /*
    * @Description: Credit rate information
    */
    @AuraEnabled
    global Value credit {get; set;}
    /*
    * @Description: International rate information
    */
    @AuraEnabled
    global Value international {get; set;}
    /*
    * @Description: Rate identifier
    */
    @AuraEnabled
    global String id_y {get; set;}
    /*
    * @Description: Flag indicating whether the debit discount is shown as a percentage or amount
    */
    @AuraEnabled
    global ItemizeType itemizeType {get; set;}
    /*
    * @Description: Month and year of information consulted
    */
    @AuraEnabled
    global String lastUpdateDate {get; set;}
	
    /*
    * @Description: Flag indicating whether the debit discount is shown as a percentage or amount
    */
    global class ItemizeType {
        /*
        * @Description: Import Amount
        */
        @AuraEnabled
        global Decimal amount {get; set;}
        /*
        * @Description: String based on ISO-4217 for specifying the currency related to the monetary amount
        */
        @AuraEnabled
        global String currency_y {get; set;}
        /*
        * @Description: Unit type in which the data is applied, either in percentage or amount
        */
        @AuraEnabled
        global String unitType {get; set;}
        /*
        * @Description: Percentage value
        */
        @AuraEnabled
        global Decimal value {get; set;}
    }
    /*
    * @Description: Percentage of discount, average and exchange rates according to the acquiring family
    
    global class Percentage {
        /*
        * @Description: Percentage of discount, average and exchange rates according to the acquiring family
        
        @AuraEnabled
        global Decimal percentage {get; set;}
    }*/

        /*
        * @Description: Percentage value
        */
        global class Value {
            /*
            * @Description: Percentage value
            */
            @AuraEnabled
            global Decimal value {get; set;}
        }
}