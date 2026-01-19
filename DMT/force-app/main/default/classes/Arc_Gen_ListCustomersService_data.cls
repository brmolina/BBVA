/**
* @File Name          : arce.Arc_Gen_getRatingDataService_data.cls
* @Description        : Obtains the data of the analyzed client to call List Customers Service
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : javier.soto.carrascosa@bbva.com
* @Last Modified On   : 26/9/2019 08:37:00
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    28/05/2019 17:59:32   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.0    25/7/2019 17:59:32   eduardoefrain.hernandez.contractor@bbva.com     Added method getAnalyzedClient
* 1.1    26/9/2019 08:37:00   javier.soto.carrascosa@bbva.com                 Remove mock
* 1.2    04/12/2019 11:47:03  manuelhugo.castillo.contractor@bbva.com         Modify method 'getCustomerRecord' replace AccountData to AccountWrapper
* 1.2    23/09/2020     saimassimilianno.jordana.contractor@bbva.com          Added arce. namespace to all classes that are now in
*                                                                             the arce-dependencies package
**/
public without sharing class Arc_Gen_ListCustomersService_data {
/**
* @Class: SaveResult
* @Description: Wrapper that contain the information of a DML Result
* @author BBVA
*/
    public class SaveResult {
        /**
        * @Description: Status of the DML operation
        */
        public String status {get;set;}
        /**
        * @Description: Message if the DML operation fails
        */
        public String message {get;set;}
    }
/**
*-------------------------------------------------------------------------------
* @description Method that calls a service using the iaso component
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String customerId
* @return arce.Arc_Gen_getIASOResponse.serviceResponse - Wrapper that contains the response of the called service
* @example public arce.Arc_Gen_getIASOResponse.serviceResponse callService(String customerId)
**/
    public arce.Arc_Gen_getIASOResponse.serviceResponse callService(String customerId) {
        arce.Arc_Gen_getIASOResponse.serviceResponse response = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        final String serviceName = 'listCustomers';
        response = arce.Arc_Gen_getIASOResponse.calloutIASO(serviceName, '{"customerId":"'+customerId+'"}');
        Return response;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that calls a service using the iaso component
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String customerId
* @return arce.Arc_Gen_getIASOResponse.serviceResponse - Wrapper that contains the response of the called service
* @example public arce.Arc_Gen_getIASOResponse.serviceResponse callService(String customerId)
**/
    public arce__Account_has_Analysis__c getAnalyzedClient(String recordId) {
        return arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId})[0];
    }
/**
*-------------------------------------------------------------------------------
* @description Method that obtains an account record
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String accNumber
* @return arce.Arc_Gen_getIASOResponse.serviceResponse - Wrapper that contains the response of the called service
* @example public arce.Arc_Gen_getIASOResponse.serviceResponse callRatingService(String analysisId,String customerId)
**/
    public static arce.Arc_Gen_Account_Wrapper getCustomerRecord(String accNumber) {
        List<String> lstAccNumber = new List<String>{accNumber};
        final Map<String,arce.Arc_Gen_Account_Wrapper> accWrap = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(lstAccNumber);
        return accWrap.get(accNumber);
    }
/**
*-------------------------------------------------------------------------------
* @description Method that update a single record
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param sObject recordToUpdate
* @return SaveResult - A wrapper with the results of a DML operation
* @example public SaveResult updateRecord(sObject recordToUpdate)
**/
    public arce.Arc_Gen_ServiceAndSaveResponse updateRecord(sObject recordToUpdate) {
        final arce.Arc_Gen_ServiceAndSaveResponse updateResults = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            updateResults.saveStatus = 'true';
            final Database.SaveResult sare = database.update(recordToUpdate, true);
            updateResults.saveMessage = Json.serialize(sare);
        } catch(DmlException ex) {
            updateResults.saveStatus = 'false';
            updateResults.saveMessage = ex.getMessage();
        }
        Return updateResults;
    }
}