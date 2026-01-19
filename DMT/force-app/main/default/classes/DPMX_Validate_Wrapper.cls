/**
* ____________________________________________________________________________
* Acquirer Activities Wrapper
* Wrapper class for the ASO service "Validates" Rquequest
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

global class DPMX_Validate_Wrapper {
    /*
    * @Description: Flag to define in the model what value to take the real or customized expenses.
    */
    @AuraEnabled
    global decimal isModel {get; set;}

    /*
    * @Description: Id of the family to which the acquiring customer belongs, refers to a grouping of business lines that are governed by the customer's economic activity and are defined according to the business lines classified by the regulatory entity for these services, which is BANXICO.
    */
    @AuraEnabled
    global String categoryId {get; set;}

    /*
    * @Description: Information about the customer's devices.
    */
    @AuraEnabled
    global Device device {get; set;}

    /*
    * @Description: Information about the customer's devices.
    */
    global class Device {
        /*
        * @Description: Total number of point-of-sale devices.
        */
        @AuraEnabled
        global decimal pointOfSales {get; set;}

        /*
        * @Description: Electronic device used in a debit, credit or smart card transaction.
        */
        @AuraEnabled
        global PinPads pinPads {get; set;}
    }

    /*
    * @Description: Electronic device used in a debit, credit or smart card transaction.
    */
    global class PinPads {
        /*
        * @Description: Number of pin pads installed.
        */
        @AuraEnabled
        global decimal totalPinPads {get; set;}
    }

    /*
    * @Description: Amount payable for invoicing.
    */
    @AuraEnabled
    global List<InvoicingAmounts> invoicingAmounts {get; set;}

    /*
    * @Description: Amount payable for invoicing.
    */
    global class InvoicingAmounts {
        /*
        * @Description: Unique identifier of the specific amount.
        */
        @AuraEnabled
        global String id {get; set;}

        /*
        * @Description: Number of transactions according to type of billing.
        */
        @AuraEnabled
        global decimal transactionsNumber {get; set;}

        /*
        * @Description: Specific amount value.
        */
        @AuraEnabled
        global Amount amount {get; set;}
    }

    /*
    * @Description: Monetary amount.
    */
    global class Amount {
        /*
        * @Description: Monetary amount.
        */
        @AuraEnabled
        global decimal amount {get; set;}

        /*
        * @Description: String based on ISO-4217 for specifying the currency related to the monetary amount.
        */
        @AuraEnabled
        global String currency_y {get; set;}
    }

    /*
    * @Description: Specific amount value.
    */
    @AuraEnabled
    global List<SpecificAmounts> specificAmounts {get; set;}

    /*
    * @Description: Specific amount value.
    */
    global class SpecificAmounts {
        /*
        * @Description: Unique identifier of the specific amount.
        */
        @AuraEnabled
        global String id {get; set;}

        /*
        * @Description: Specific amount value.
        */
        @AuraEnabled
        global Amount amount {get; set;}
    }

}