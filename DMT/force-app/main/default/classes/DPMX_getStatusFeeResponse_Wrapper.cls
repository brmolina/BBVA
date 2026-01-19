/**
* ____________________________________________________________________________
* get status Wrapper response
* Wrapper class for the ASO service "getStatus" response
* https://catalogs.platform.bbva.com/apicatalog/business/apis/apis-enterprises-stores/versions/global-2.8.0/resources/storesapiacquirercategoriesacquirercategoryidrequestsstatusfeev2/
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

global class DPMX_getStatusFeeResponse_Wrapper {
    @AuraEnabled
    global List<Data> data {get; set;}

    /*
    * @Description: Root node
    */
    global class Data {
        /*
        * @Description: Identifier status update rates.
        */
        @AuraEnabled
        global string folio {get; set;}

        /*
        * @Description: Categories for client.
        */
        @AuraEnabled
        global Category category {get; set;}

        /*
        * @Description: Information with the data inpu to online Update tariffs contains tariff information and application in system.
        */
        @AuraEnabled
        global List<ItemizeRates> itemizeRates {get; set;}

        /*
        * @Description: Contains info bussines agent and bussines autorized.
        */
        @AuraEnabled
        global BusinessPeople businessPeople {get; set;}

        /*
        * @Description: Information application to start updating rates and endding rates.
        */
        @AuraEnabled
        global UpdateRates updateRates {get; set;}
    }

    /*
    * @Description: Categories for client.
    */
    global class Category {
        /*
        * @Description: Contains description family customerID.
        */
        @AuraEnabled
        global string description {get; set;}

        /*
        * @Description: Information about the business related to the customer.
        */
        @AuraEnabled
        global BusinessInformation businessInformation {get; set;}
    }

    /*
    * @Description: Information about the business related to the customer.
    */
    global class BusinessInformation {
        /*
        * @Description: Official identifying name of the Company of those legal entities that are clients of the Entit.
        */
        @AuraEnabled
        global string companyName {get; set;}

        /*
        * @Description: Name that allows the Group to be unequivocally identified.
        */
        @AuraEnabled
        global string groupName {get; set;}
    }

    /*
    * @Description: Information with the data inpu to online Update tariffs contains tariff information and application in system.
    */
    global class ItemizeRates {
        /*
        * @Description: Type of status of the request of the acquiring tariff service.
        */
        @AuraEnabled
        global string codeStatus {get; set;}

        /*
        * @Description: Rate type code.
        */
        @AuraEnabled
        global string rateType {get; set;}

        /*
        * @Description: Detail mode in which the collection fee is applied.
        */
        @AuraEnabled
        global Fee fee {get; set;}
    }

    /*
    * @Description: Information with the data inpu to online Update tariffs contains tariff information and application in system.
    */
    global class Fee {
        /*
        * @Description: Unit type in which the data is applied : LISTADO AMOUNT/PERCENTAGE
        */
        @AuraEnabled
        global string unitType {get; set;}

        /*
        * @Description: Monetary amount.
        */
        @AuraEnabled
        global decimal amount {get; set;}

        /*
        * @Description: String based on ISO-4217 for specifying the currency.
        */
        @AuraEnabled
        global string currency_y {get; set;}

        /*
        * @Description: Interest Percentage.
        */
        @AuraEnabled
        global decimal percentage {get; set;}
    }

    /*
    * @Description: Contains info bussines agent and bussines autorized.
    */
    global class BusinessPeople {
        
        /*
        * @Description: Contains information from the executive user requesting the rate update.
        */
        @AuraEnabled
        global BusinessAgent businessAgent {get; set;}

        /*
        * @Description: Contains information from the executive order authorizing the rate update.
        */
        @AuraEnabled
        global BusinessAuthorizes businessAuthorizes {get; set;}
    }

    /*
    * @Description: Contains information from the executive user requesting the rate update.
    */
    global class BusinessAgent {
        /*
        * @Description: Code that allows you to identify the user who made the last modification.
        */
        @AuraEnabled
        global string id {get; set;}
    }

    /*
    * @Description: Contains information from the executive order authorizing the rate update.
    */
    global class BusinessAuthorizes {
        /*
        * @Description: Identifier code of the user responsible for the request.
        */
        @AuraEnabled
        global string id {get; set;}
    }

    /*
    * @Description: Information application to start updating rates and endding rates.
    */
    global class UpdateRates {
        /*
        * @Description: Date indicating the start of application of the commission.
        */
        @AuraEnabled
        global string startDate {get; set;}

        /*
        * @Description: Date indicating the end of the commission's application.
        */
        @AuraEnabled
        global string expirationDate {get; set;}

        /*
        * @Description: Date auditory control last modification rate.
        */
        @AuraEnabled
        global string modifyDate {get; set;}

        /*
        * @Description: Fecha de envio a sistema
        */
        @AuraEnabled
        global string initDateFormalize {get; set;}

        /*
        * @Description: Recordatorio de revisión
        */
        @AuraEnabled
        global string revisionDateFormalize {get; set;}
    }

    /*
    * @Description: pagination
    */
    @AuraEnabled
    global Pagination pagination {get; set;}

    /*
    * @Description: Information application to start updating rates and endding rates.
    */
    global class Pagination {
        /*
        * @Description: Pagination links. These links provide relative URIs to reach different useful pages, such as first, last, next or previous pages.
        */
        @AuraEnabled
        global Links links {get; set;}

        /*
        * @Description: Current page number. This attribue value is 0 when referring to the first page.
        */
        @AuraEnabled
        global Decimal page {get; set;}

        /*
        * @Description: Current page number. This attribue value is 0 when referring to the first page.
        */
        @AuraEnabled
        global Decimal totalPages {get; set;}

        /*
        * @Description: Current page number. This attribue value is 0 when referring to the first page.
        */
        @AuraEnabled
        global Decimal totalElements {get; set;}

        /*
        * @Description: Current page number. This attribue value is 0 when referring to the first page.
        */
        @AuraEnabled
        global Decimal pageSize {get; set;}
    }

    /*
    * @Description: Information application to start updating rates and endding rates.
    */
    global class Links {
        /*
        * @Description: URI to the first page. It will be the URI to the list without paging element.
        */
        @AuraEnabled
        global string first {get; set;}

        /*
        * @Description: URI to the first page. It will be the URI to the list without paging element.
        */
        @AuraEnabled
        global string last {get; set;}

        /*
        * @Description: URI to the first page. It will be the URI to the list without paging element.
        */
        @AuraEnabled
        global string previous {get; set;}

        /*
        * @Description: URI to the first page. It will be the URI to the list without paging element.
        */
        @AuraEnabled
        global string next {get; set;}
    }



}