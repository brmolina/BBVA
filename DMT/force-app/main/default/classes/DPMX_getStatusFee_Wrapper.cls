/**
* ____________________________________________________________________________
* get status Wrapper
* Wrapper class for the ASO service "getStatus" Rquequest
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

global class DPMX_getStatusFee_Wrapper {
    /*
    * @Description: Unique identifier of the customer, this attribute only apply for attended channels.
    */
    @AuraEnabled
    global String customerId {get; set;}

    /*
    * @Description: User get generate athorization rate.
    */
    @AuraEnabled
    global String userAuthorized {get; set;}

    /*
    * @Description: Number of elements per page..
    */
    @AuraEnabled
    global Decimal pageSize {get; set;}

    /*
    * @Description: Key to obtain a single page.
    */
    @AuraEnabled
    global Decimal paginationKey {get; set;}


}