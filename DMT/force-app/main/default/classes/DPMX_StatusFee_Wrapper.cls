/**
* ____________________________________________________________________________
* Status fee Wrapper
* Wrapper class for the ASO service "status-fee"
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-02-07
* @modified
* @systemLayer
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
global class DPMX_StatusFee_Wrapper {

    /*
    * @Description: Identifier status update rates.
    */
    @AuraEnabled
    global String folio {get; set;}

    /*
    * @Description: Type of status of the request of the acquiring tariff service. ACTUALIZADO - PENDIENTE - RECHAZADO
    */
    @AuraEnabled
    global String codeStatus {get; set;}

    /*
    * @Description: Categories for client.
    */
    @AuraEnabled
    global Category category {get; set;}

    /*
    * @Description: Categories for client.
    */
    global class Category {

        /*
        * @Description: Contains description family customerID. Ex: Grandes_superficias.
        */
        @AuraEnabled
        global String description {get; set;}

        /*
        * @Description: Information about the business related to the customer.
        */
        @AuraEnabled
        global BusinessInformation businessInformation {get; set;}

    }

    /*
    * @Description: Categories for client.
    */
    global class BusinessInformation {

        /*
        * @Description: Official identifying name of the Company of those legal entities that are clients of the Entit.
        */
        @AuraEnabled
        global String companyName {get; set;}

        /*
        * @Description: Name that allows the Group to be unequivocally identified.
        */
        @AuraEnabled
        global String groupName {get; set;}
    }

    /*
    * @Description: DTO with data input information to online Update rates contains information rate and aplication in system.
    */
    @AuraEnabled
    global ItemizeRate itemizeRate {get; set;}

    /*
    * @Description: DTO with data input information to online Update rates contains information rate and aplication in system.
    */
    global class ItemizeRate {

        /*
        * @Description: Rate type code. Values - DESCUENTODEBITO - CREDITONACIONAL - CREDITOINTERNACIONAL
        */
        @AuraEnabled
        global String rateType {get; set;}

        /*
        * @Description: Information about the business related to the customer.
        */
        @AuraEnabled
        global Fee fee {get; set;}

    }

    /*
    * @Description: Information about the business related to the customer.
    */
    global class Fee {
        /*
        * @Description: Unit type in which the data is applied. Values - PERCENTAGE - AMOUNT
        */
        @AuraEnabled
        global String unitType {get; set;}

        /*
        * @Description: Monetary amount.
        */
        @AuraEnabled
        global Decimal amount {get; set;}

        /*
        * @Description: Interest Percentage.
        */
        @AuraEnabled
        global Decimal percentage {get; set;}

        /*
        * @Description: String based on ISO-4217 for specifying the currency.
        */
        @AuraEnabled
        global String currency_y {get; set;}
    
    }

    /*
    * @Description: DTO contains info bussines agent and bussines autorized.
    */
    @AuraEnabled
    global BusinessPeople businessPeople {get; set;}

    /*
    * @Description: DTO contains info bussines agent and bussines autorized.
    */
    global class BusinessPeople {

        /*
        * @Description: DTO with information of executive user requesting the update of rates.
        */
        @AuraEnabled
        global BusinessAgent businessAgent {get; set;}

        /*
        * @Description: DTO with information of executive order authorizing the updating of rate.
        */
        @AuraEnabled
        global BusinessAuthorizes businessAuthorizes {get; set;}
    }

    /*
    * @Description: DTO with information of executive user requesting the update of rates.
    */
    global class BusinessAgent {
        /*
        * @Description: Code that allows you to identify the user who made the last modification.
        */
        @AuraEnabled
        global String id_y {get; set;}
    }

    /*
    * @Description: DTO with information of executive order authorizing the updating of rate.
    */
    global class BusinessAuthorizes {
        /*
        * @Description: Identifier code of the user responsible for the request.
        */
        @AuraEnabled
        global String id_y {get; set;}
    }

    /*
    * @Description: DTO with information application to start updating rates and endding rates.
    */
    @AuraEnabled
    global UpdateRates updateRates {get; set;}

    /*
    * @Description: DTO with information application to start updating rates and endding rates.
    */
    global class UpdateRates {
        /*
        * @Description: Date indicating the start of application of the commission.
        */
        @AuraEnabled
        global String startDate {get; set;}

        /*
        * @Description: Date indicating the end of the commission's application.
        */
        @AuraEnabled
        global String expirationDate {get; set;}

        /*
        * @Description: Date auditory control last modification rate.
        */
        @AuraEnabled
        global String modifyDate {get; set;}
    }
    
    /*
    * @Description: 
    */
    @AuraEnabled
    global Pagination pagination {get; set;}

    /*
    * @Description: 
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
        * @Description: Total number of pages for the provided pagination and filtering parameters.
        */
        @AuraEnabled
        global Decimal totalPages {get; set;}
        
        /*
        * @Description: Total number of items to the requested list, taking into account possible filtering criteria if specified..
        */
        @AuraEnabled
        global Decimal totalElements {get; set;}
        
        /*
        * @Description: Number of items per page. This attribute value matches pageSize query parameter if provided. Otherwise, this attribute may provide the default page size.
        */
        @AuraEnabled
        global Decimal pageSize {get; set;}
    }
    
    /*
    * @Description: Pagination links. These links provide relative URIs to reach different useful pages, such as first, last, next or previous pages.
    */
    global class Links {
        /*
        * @Description: URI to the first page. It will be the URI to the list without paging element.
        */
        @AuraEnabled
        global String first {get; set;}
        
        /*
        * @Description: URI to the last page based on the current pagination configuration.
        */
        @AuraEnabled
        global String last {get; set;}
        
        /*
        * @Description: URI to the previous page.
        */
        @AuraEnabled
        global String previous {get; set;}
        
        /*
        * @Description: URI to the next page.
        */
        @AuraEnabled
        global String next {get; set;}
    	
    }
}