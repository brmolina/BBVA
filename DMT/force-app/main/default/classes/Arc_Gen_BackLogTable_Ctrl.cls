/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_BackLogTable_Ctrl
* @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-15
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_BackLogTable component
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-15 mariohumberto.ramirez.contractor@bbva.com
*             Class Creation
* |2021-06-29 juanignacio.hita.contractor@bbva.com
*             Added currentYear, lastYear param to wrapper and called getYearColumns method
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_BackLogTable_Ctrl {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-15
    * @param void
    * @return void
    * @example Arc_Gen_BackLogTable_Ctrl controller = new Arc_Gen_BackLogTable_Ctrl()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_BackLogTable_Ctrl() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to create table
    * -----------------------------------------------------------------------------------------------
    * @param void
    * @return all the information to create the table
    * @example ResponseWrapper wrapper = new ResponseWrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class BackLogTable {
        /**
        * @Description: map with the table data
        */
        @AuraEnabled public Map<string,double> backLogData {get;set;}
        /**
        * @Description: current year column
        */
        @AuraEnabled public Integer currentYear {get;set;}
        /**
        * @Description: current year column
        */
        @AuraEnabled public Integer lastYear {get;set;}
        /**
        * @Description: string with the error response
        */
        @AuraEnabled public String errorResponse {get;set;}
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that return's the data needed to build the backLog Table
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-15
    * @param recordId - Id of the account has analysis object
    * @return BackLogTable - wrapper with all the data needed to build the backLog Table
    * @example getTableData(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static BackLogTable getTableData(Id recordId) {
        BackLogTable response = new BackLogTable();
        try {
            final List<arce__Account_has_Analysis__c> accHasData = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<Id>{recordId});
            response.backLogData = Arc_Gen_BackLogTable_Service.dataResp(accHasData[0]);
            Arc_Gen_BackLogTable_Service.getYearColumns(accHasData[0], response);
        } catch (Exception ex) {
            response.errorResponse = ex.getMessage();
        }
        return response;
    }
}