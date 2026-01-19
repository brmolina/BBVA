/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PotitionBankTable_Ctlr
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_PotitionBankTable_Service and
* Arc_Gen_PotitionBankTable_Service_Helper.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-11-27 mariohumberto.ramirez.contractor@bbva.com
*             Change the object limits exposure to risk position summary
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Change methods getRecordTypeId and deleteRecord
* |2020-07-27 joseluis.garcia4.contractor@bbva.com
*             Add method call to build nested data.
* |2020-07-28 joseluis.garcia4.contractor@bbva.com
*             Add refreshAutomaticPosition() method.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-10-01 joseluis.garcia4.contractor@bbva.com
*             Separate arce__last_update_position__c field update from actual refresh.
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_PotitionBankTable_Ctlr {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example Arc_Gen_Validate_Customer_Service service = new Arc_Gen_Validate_Customer_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_PotitionBankTable_Ctlr() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to create the table
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return all the information to create the table
    * @example ResponseWrapper wrapper = new ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class ResponseWrapper {
        /**
        * @Description: Boolean that represent a succesfull call
        */
        @AuraEnabled public Boolean successResponse {get;set;}
        /**
        * @Description: Map with some info in the data
        */
        @AuraEnabled public Arc_Gen_DataTable jsonResponse {get;set;}
        /**
        * @Description: String with an error response
        */
        @AuraEnabled public String errorResponse {get;set;}
        /**
        * @Description: String with a record type Id
        */
        @AuraEnabled public String recorTypeId {get;set;}
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return a JSON with the data to construct the policie table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param recordId - Id of the account_has_analysis.
    * @param inputClass - String with whe name of the controller class
    * @return response - Wrapper with the data to construct the policie table
    * @example dataResponse(recordId, inputClass)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static ResponseWrapper dataResponse(Id recordId, String inputClass) {
        final ResponseWrapper response = new ResponseWrapper();
        try {
            response.successResponse = true;
            final System.Type objType = Type.forName(inputClass);
            final Arc_Gen_PotitionTable_Interface interfaceClass = (Arc_Gen_PotitionTable_Interface) objType.newInstance();
            final Arc_Gen_DataTable tableData = interfaceClass.getData(recordId);
            response.jsonResponse = Arc_Gen_PotitionBankTable_Service.buildNestedData(tableData);
        } catch (Exception e) {
            response.successResponse = false;
            response.errorResponse = e.getMessage() + ' : ' + e.getLineNumber();
        }
        return response;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Forces a call to the limits service to update positions.
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García  joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-07-28
    * @param recordId - Id of the account_has_analysis.
    * @param inputClass - String with whe name of the controller class
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void refreshAutomaticPosition(Id recordId, String inputClass) {
        // Reset last position update date.
        final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c(Id = recordId, arce__last_update_position__c = null);
        arce.Arc_Gen_AccHasAnalysis_Data.updateRecords(aha);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Return an Id of an recordType
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param recordTypeDevName - developer name of the record type
    * @return Id of a recordType
    * @example getRecordTypeId(recordTypeDevName)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static ResponseWrapper getRecordTypeId(String recordTypeDevName) {
        final ResponseWrapper response = new ResponseWrapper();
        try {
            response.successResponse = true;
            response.recorTypeId = Arc_Gen_PotitionBankTable_Service.getRecordTypeId(recordTypeDevName);
        } catch (Exception ex) {
            response.successResponse = false;
            response.errorResponse = ex.getMessage() + ' : ' + ex.getLineNumber();
        }
        return response;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Delete a record
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-25
    * @param recordId - id of the record to delete
    * @return true/false
    * @example deleteRecord(recordId)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static ResponseWrapper deleteRecord(String recordId) {
        final ResponseWrapper response = new ResponseWrapper();
        try {
            response.successResponse = true;
            Arc_Gen_PotitionBankTable_Service.deleteRecord(recordId);
        } catch (Exception ex) {
            response.successResponse = false;
            response.errorResponse = ex.getMessage() + ' : ' + ex.getLineNumber();
        }
        return response;
    }
}