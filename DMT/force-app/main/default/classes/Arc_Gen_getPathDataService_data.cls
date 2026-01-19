/**
* @File Name          : Arc_Gen_getPathDataService_data.cls
* @Description        : Class that gets information FROM rating service
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : javier.soto.carrascosa@bbva.com
* @Last Modified On   : 12/04/2020 00:00:00
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    30/4/2019 18:04:16   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    23/7/2019 18:04:16   eduardoefrain.hernandez.contractor@bbva.com     Added comments
* 1.2    26/9/2019 08:29:00   javier.soto.carrascosa@bbva.com                 Remove mock
* 1.3    11/12/2019 15:04:29  manuelhugo.castillo.contractor@bbva.com         Replace method 'getAccountHasAnalysis' to arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysis
* 1.4    11/12/2019 15:04:29  manuelhugo.castillo.contractor@bbva.com         Modify method 'getAnalysisAndCustomer' Account Wrapper
* 1.5    01/04/2020 18:35:29  juanmanuel.perez.ortiz.contractor@bbva.com      Modify method 'callPathService' to convert eventType in dynamic value
* 1.6    12/04/2020 00:00:00  javier.soto.carrascosa@bbva.com                 Add support to retrieve local field from risk assessment location
* 1.6    23/09/2020     saimassimilianno.jordana.contractor@bbva.com          Added arce. namespace to all classes that are now in the arce-dependencies package
**/
public with sharing class Arc_Gen_getPathDataService_data {
/**
* @Class: SaveResult
* @Description: Wrapper that contain the information of a DML Result
* @author BBVA
*/
    /**
    * @Description: String Header value 1
    */
    static final string HEADER = '1';
    public class SaveResult {
        /**
        * @Description: Status of the DML operation
        */
        public String status {get;set;}
        /**
        * @Description: Message if the DML operation fails
        */
        public String message {get;set;}
        public map <String,Object> updatefields {get;set;}

    }
/**
*-------------------------------------------------------------------------------
* @description Method that calls the path service
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String analysisId - Analysis Id
* @param String customerId - Customer Id
* @return arce.Arc_Gen_getIASOResponse.serviceResponse - Wrapper with the service response
* @example public arce.Arc_Gen_getIASOResponse.serviceResponse callPathService(String analysisId,String customerId)
**/
    public arce.Arc_Gen_getIASOResponse.serviceResponse callPathService(String analysisId,String customerId,String subsidiary,String arceId) {
        arce.Arc_Gen_getIASOResponse.serviceResponse response = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        final String serviceName = 'pathEngine';
        arce.Arc_Gen_User_Wrapper wrapper = arce.Arc_Gen_User_Locator.getUserInfo(UserInfo.getUserId());
        final String federationId = wrapper.businessAgentId;
        final String subprocessType = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{arceId})[0].arce__anlys_wkfl_sub_process_type__c;
        final String eventType = arce.Arc_Gen_GenericUtilities.getEventTypeValue(subprocessType);
        response = arce.Arc_Gen_getIASOResponse.calloutIASO(serviceName, '{"analysisId":"'+analysisId+'","customerId":"'+customerId+'","subsidiary":"'+subsidiary+'","federationId":"'+federationId+'","eventType":"'+eventType+'"}');
        Return response;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that gets an AccountHasAnalysis record
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String analysisId - Analysis Id
* @param String customerId - Customer Id
* @return List<arce__Account_has_Analysis__c> - List of Account Has Analysis
* @example public List<arce__Account_has_Analysis__c> getAccountHasAnalysis(String analysisId,String customerId)
**/
    public List<arce__Account_has_Analysis__c> getAccountHasAnalysis(String analysisId,String customerId) {
        return [SELECT id,Name,arce__path__c,arce__Customer__r.AccountNumber,arce__Analysis__c  FROM arce__Account_has_Analysis__c WHERE arce__Analysis__c =: analysisId AND arce__Customer__c =: customerId];
    }
/**
*-------------------------------------------------------------------------------
* @description Method that gets the ARCE and the customer of an AccountHasAnalysis
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param String accHasAnalysisId - Account Has Analysis Id
* @return List<String> - List with analysis and customer of an Account Has Analysis
* @example public static List<String> getAnalysisAndCustomer(String accHasAnalysisId)
**/
    public static List<String> getAnalysisAndCustomer(String accHasAnalysisId) {
        List<String> lstStrRecords = new List<String>{accHasAnalysisId};
        List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> lstAHAAndCustomer = arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysisAndCustomer(lstStrRecords);
        List<String> idList = new List<String>();
        for(arce.Arc_Gen_Account_Has_Analysis_Wrapper ahaWrapper : lstAHAAndCustomer) {
            idList.add((String)ahaWrapper.ahaObj.arce__Analysis__c);
            idList.add((String)ahaWrapper.accWrapperObj.accId);
            idList.add((String)ahaWrapper.accWrapperObj.accNumber);
            if(ahaWrapper.ahaObj.arce__group_asset_header_type__c == HEADER) {
                idList.add((String)System.Label.Cls_arce_PathGroup);
            } else {
                idList.add((String)System.Label.Cls_arce_PathSubsidiary);
            }
        }
        Return idList;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that updates a sObject list
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 28/05/2019
* @param List<sObject> recordsToUpdate - Records to Update
* @return SaveResult Wrapper with the DML Response
* @example public SaveResult updateRecords(List<sObject> recordsToUpdate)
**/
    public arce.Arc_Gen_ServiceAndSaveResponse updateRecords(List<sObject> recordsToUpdate) {
        final arce.Arc_Gen_ServiceAndSaveResponse updateResults = new arce.Arc_Gen_ServiceAndSaveResponse();
        updateResults.saveStatus = 'true';
        Database.SaveResult[] sr = database.update(recordsToUpdate, false);
        boolean error=false;
        String msg='';
        for(Database.SaveResult res : sr) {
            error = res.isSuccess() ? error : true;
            msg += res.isSuccess() ? '' : String.valueof(res.getErrors());
        }
        updateResults.saveMessage = Json.serialize(sr);
        if(error) {
            updateResults.saveStatus = 'false';
            updateResults.saveMessage = msg;
        }
        Return updateResults;
    }
}