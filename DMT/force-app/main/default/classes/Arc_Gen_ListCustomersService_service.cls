/**
* @File Name          : arce.Arc_Gen_getRatingDataService_data.cls
* @Description        : Obtains the data of the analyzed client to call List Customers Service
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : luisruben.quinto.munoz@bbva.com
* @Last Modified On   : 23/7/2019 22:36:19
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    30/4/2019 17:59:32   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    32/7/2019 17:59:32   eduardoefrain.hernandez.contractor@bbva.com     modification to add list customer logic
* 1.2    06/12/2019 11:24:00  jhovanny.delacruz.cruz@bbva.com                 Encryption funcionality enabled
* 1.2    04/12/2019 11:47:03  manuelhugo.castillo.contractor@bbva.com         Modify method 'setupListCustomers' replace Account to AccountWrapper
* 1.3    15/01/2020 11:47:03  javier.soto.carrascosa@bbva.com         Adapt setupListCustomers to support update from AccountWrapper,
*                                                                        adapt ListCustomer to global API structure
* 1.4    29/01/2020 14:59:32   javier.soto.carrascosa@bbva.com     Remove update carrusel method, checkbox is controlled by the QVCD
* 1.5    02/04/2020 14:59:32   javier.soto.carrascosa@bbva.com     Fix enable processing for non mandatory fields
* 1.5    23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
**/
public with sharing class Arc_Gen_ListCustomersService_service {
    public class CustomerData {
        /**
        * @Description: Id of retrieved sector
        */
        @AuraEnabled public String sectorId {get;set;}
        /**
        * @Description: Name of retrieved sector
        */
        @AuraEnabled public String sectorDesc {get;set;}
        /**
        * @Description: Id of retrieved bank
        */
        @AuraEnabled public String bankId {get;set;}
    }
/**
*-------------------------------------------------------------------------------
* @description Method that sets the parameters to the list customer service
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String clientNumber
* @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service and the DML operation
* @example public static arce.Arc_Gen_ServiceAndSaveResponse setupListCustomers(String clientNumber)
**/
    public arce.Arc_Gen_ServiceAndSaveResponse setupListCustomers(String clientNumber, Boolean saveobject) {
        final arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        arce.Arc_Gen_getIASOResponse.serviceResponse iasoResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
        Arc_Gen_ListCustomersService_data locator = new Arc_Gen_ListCustomersService_data();
        Map <String, String> accAttributes = new Map<String, String>();
        Map<Id, Map<String,String>> accUp = new Map<Id, Map<String,String>>();
        final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(clientNumber);
        iasoResponse = locator.callService(customerNumber);
        serviceAndSaveResp.serviceCode = iasoResponse.serviceCode;
        serviceAndSaveResp.serviceMessage = iasoResponse.serviceMessage;
        if(iasoResponse.serviceCode == String.valueOf(serviceMessage.CODE_200)) {
            CustomerData custData = getCustomerData(iasoResponse.serviceResponse);
            accAttributes = buildAccMap(custData);
            if(saveobject) {
                final arce.Arc_Gen_Account_Wrapper customer = Arc_Gen_ListCustomersService_data.getCustomerRecord(clientNumber);
                accUp.put(customer.accId,accAttributes);
                final arce.Arc_Gen_ServiceAndSaveResponse result = arce.Arc_Gen_Account_Locator.accountUpdate(accUp);
                serviceAndSaveResp.saveStatus = result.saveStatus;
                serviceAndSaveResp.saveMessage = result.saveMessage;
            } else {
                serviceAndSaveResp.updatefields = accAttributes;
            }
        }
        Return serviceAndSaveResp;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that gets the customer data from the service response
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String clientNumber
* @return CustomerData - Wrapper that contains the customer data
* @example public static CustomerData getCustomerData(Map<String, Object> serviceResponse)
**/
    public static CustomerData getCustomerData(Map<String, Object> serviceResponse) {
        final CustomerData custData = new CustomerData();
        final Map<String, Object> serviceResp = getMapFromJson(serviceResponse,'data');
        final Map<String, Object> ecoDataMap =  getMapFromJson(serviceResp,'economicData');
        final Map<String, Object> activityMap = getMapFromJson(ecoDataMap,'economicActivity');
        final Map<String, Object> bankMap = getMapFromJson(ecoDataMap,'bank');
        custData.bankId = (String)bankMap.get('id');
        custData.sectorId = (String)activityMap.get('id');
        custData.sectorDesc = (String)activityMap.get('description');
        Return custData;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that build a map of field and values for account Update from list Customer
--------------------------------------------------------------------------------
* @author javier.soto.carrascosa@bbva.com
* @date 2020-01-15
* @param CustomerData custData
* @return Map<String,String>
* @example private Map<String,String> buildAccMap (CustomerData custData)
**/
    private static Map<String,String> buildAccMap (CustomerData custData) {
        Map<String,String> accData = new Map<String,String>();
        accData.put('company_economic_activity_id__c',custData.sectorId);
        accData.put('company_economic_activity_desc__c',custData.sectorDesc);
        accData.put('bank_id__c',custData.bankId);
        return accData;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  public static Arc_Gen_CallListParticipant.Innertoreturnlistp callListParticipants(String encryptedGroup) {
    */
    private static Map<String, Object> getMapFromJson(Map<String, Object> prevMap, String keyToRetrieve) {
        Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(prevMap.get(keyToRetrieve)));
        if (data == null) {
            data = new Map<String, Object>();
        }
        return data;
    }
}