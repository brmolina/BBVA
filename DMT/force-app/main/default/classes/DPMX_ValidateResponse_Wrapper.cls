/**
* ____________________________________________________________________________
* Acquirer Activities Wrapper
* Wrapper class for the ASO service "Validates" Response
* https://catalogs.platform.bbva.com/apicatalog/business/apis/apis-enterprises-stores/versions/global-1.65.2/resources/storesapiacquireractivitiesvalidatev1/
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @modified
* @systemLayer
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/

global class DPMX_ValidateResponse_Wrapper {

    /*
    * @Description:	Proposals available to the customer.
    */
    @AuraEnabled
    global List<Proposed> proposed {get; set;}

    /*
    * @Description: Proposals available to the customer.
    */
    global class Proposed {
        /*
        * @Description:	Scenario given by the type of proposed rates.
        */
        @AuraEnabled
        global string scenaryType {get; set;}

        /*
        * @Description:	Total rates according to the proposals.
        */
        @AuraEnabled
        global Rate rate {get; set;}

        /*
        * @Description:	Total acquirer's expenses amount of the model, used for the profitability calculation.
        */
        @AuraEnabled
        global Amount amount {get; set;}

        /*
        * @Description:	Number for Order *Used for aura only
        */
        @AuraEnabled
        global Integer idOrder {get; set;}
    }

    /*
    * @Description: Information on acquirer's fees.
    */
    global class Rate {
        /*
        * @Description:	Detail of each rate.
        */
        @AuraEnabled
        global List<ItemizeRates> itemizeRates {get; set;}
    }

    /*
    * @Description: Detail of each fee.
    */
    global class ItemizeRates {

        /*
        * @Description:	Identifier of the rate type.
        */
        @AuraEnabled
        global String rateType {get; set;}

        /*
        * @Description:	Detail mode in which the collection rate is applied.
        */
        @AuraEnabled
        global ItemizeRatesUnit itemizeRatesUnit {get; set;}

        /*
        * @Description:	Number for Order *Used for aura only
        */
        @AuraEnabled
        global Integer idOrder {get; set;}
    }

    /*
    * @Description: Detail of each fee.
    */
    global class ItemizeRatesUnit {
        /*
        * @Description:	Unit type in which the data is applied.
        */
        @AuraEnabled
        global string unitRateType {get; set;}

        /*
        * @Description:	Monetary amount.
        */
        @AuraEnabled
        global decimal amount {get; set;}

        /*
        * @Description:	String based on ISO-4217 for specifying the currency related to the monetary amount.
        */
        @AuraEnabled
        global string currency_y {get; set;}

        /*
        * @Description:	Unit of measurement of the interest fees.
        */
        @AuraEnabled
        global decimal percentage {get; set;}
    }

    /*
    * @Description: Detail of each fee.
    */
    global class Amount {
        /*
        * @Description:	Monetary amount.
        */
        @AuraEnabled
        global decimal amount {get; set;}

        /*
        * @Description:	String based on ISO-4217 for specifying the currency related to the monetary amount.
        */
        @AuraEnabled
        global string currency_y {get; set;}
    }

}