/**
* @File Name          : Arc_Gen_RatingVariablesTable_controller.cls
* @Description        : Controller that obtains the response of the rating variables table from the service
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Group
* @Last Modified By   : joseluis.garcia4.contractor@bbva.com
* @Last Modified On   : 30/4/2019 18:18:26
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    30/4/2019 17:29:51   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    20/5/2020 17:29:51       joseluis.garcia4.contractor@bbva.com        Show qualitative variables in table.
* 1.2    30/4/2021 17:29:51   otiliaramona.veres.contractor@bbva.com          Added an empty constructor method.
* 1.3    04/5/2021 13:11:00   otiliaramona.veres.contractor@bbva.com          Added annotation '@testVisible' to the empty constructor method.
**/
public without sharing class Arc_Gen_RatingVariablesTable_controller {
    /**
    * @Description: Error Literal
    */
    private final static String ERROR_TEXT = 'Error';
    /**
    * @Description: Error Literal
    */
    private final static String SUCCESS_TEXT = 'Success';
/**
*-------------------------------------------------------------------------------
* @description Empty constructor method
*-------------------------------------------------------------------------------
*@author otiliaramona.veres.contractor@bbva.com
*@Date   Created:2021-04-30
*/
@TestVisible
private Arc_Gen_RatingVariablesTable_controller() { }
/**
* @Class: TableResponse
* @Description: Wrapper that contains the response of the table logic
* @author BBVA
*/
    public Class TableResponse {
        /**
        * @Description: Status of the process
        */
        @AuraEnabled public String status {get;set;}
        /**
        * @Description: Json to configure the table
        */
        @AuraEnabled public String tableJson {get;set;}
        /**
        * @Description: Json to configure the table
        */
        @AuraEnabled public String errorMessage {get;set;}
    }
/**
*-------------------------------------------------------------------------------
* @description Method that obtains the data of the rating variables table
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param String analysisId
* @return String
* @example public static String getDataTable(String analysisId)
**/
    @AuraEnabled
    public static TableResponse getDataTable(String ratingId) {
        TableResponse response = new TableResponse();
        try {
            List<arce__rating_variables_detail__c> variablesLevelOne = Arc_Gen_RatingVariablesTable_service.getVariablesLevelOne(ratingId);
            List<arce__rating_variables_detail__c> variablesLevelTwo = Arc_Gen_RatingVariablesTable_service.getVariablesLevelTwo(ratingId);
            response.tableJson = Arc_Gen_RatingVariablesTable_service.setTableJson(variablesLevelOne,variablesLevelTwo);
            response.status = SUCCESS_TEXT;
        } catch(QueryException e) {
            response.status = ERROR_TEXT;
            response.errorMessage = e.getMessage();
        }
        Return response;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that obtains the data of the rating qualitative variable table
--------------------------------------------------------------------------------
* @author eduardoefrain.hernandez.contractor@bbva.com
* @date 30/4/2019
* @param String analysisId
* @return String
* @example public static String getQualitativeTable(String analysisId)
**/
    @AuraEnabled
    public static TableResponse getQualitativeTable(String ratingId) {
        TableResponse response = new TableResponse();
        try {
            final String dataTable = Arc_Gen_RatingVariablesTable_service.getQualitativeVariables(ratingId);
            response.status = SUCCESS_TEXT;
            response.tableJson = dataTable;
        } catch(QueryException e) {
            response.status = ERROR_TEXT;
            response.errorMessage = e.getMessage();
        }
        Return response;
    }
}