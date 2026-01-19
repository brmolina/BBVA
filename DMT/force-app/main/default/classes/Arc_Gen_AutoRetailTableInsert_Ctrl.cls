/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AutoRetailTableInsert_Ctrl
* @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2021-01-26
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class that inserts reords of Auto retail behavior table
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-02-02 eduardoefrain.hernandez.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_AutoRetailTableInsert_Ctrl {
    /**
    * @Description: String with the participant number
    */
    private static Boolean showErrorLog;
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailTableInsert_Ctrl controller = new Arc_Gen_AutoRetailTableInsert_Ctrl()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_AutoRetailTableInsert_Ctrl() {

    }
    /**
    * @Description: static logic that retrieves the value of the ShowTraceErrorLogs metadata
    */
    static {
        final List<arce__Arce_Config__mdt> showErrorsConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ShowTraceErrorLogs');
        showErrorLog = Boolean.valueOf(showErrorsConfig.get(0).arce__Value1__c);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that obtains the data to show in the insert modal
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param selectedRowId - Id of the selected table row
    * @param year1 - Selected year 1
    * @param year2 - Selected year 2
    * @return Arc_Gen_AutoRetailTableRow - Wrapper with the data to construct the autoretail table
    * @example Arc_Gen_AutoRetailTableInsert_Ctrl.getData(selectedRowId, year1, year2)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Arc_Gen_AutoRetailTableRow getData(String selectedRowId, String year1, String year2) {
        Arc_Gen_AutoRetailTableRow response = new Arc_Gen_AutoRetailTableRow();
        try {
            response = Arc_Gen_AutoRetailTableInsert_Service.getDataToEdit(selectedRowId, year1, year2);
        } catch (Exception e) {
            final String errorMsg = showErrorLog ? e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString() : e.getMessage();
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(errorMsg);
        }
        return response;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that inserts the data typed by the user in the Insert Modal
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param data - Map with the values typed by the user
    * @return void
    * @example Arc_Gen_AutoRetailTableInsert_Ctrl.insertRecords(data)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void insertRecords(Map<String, Object> data) {
        try {
            Arc_Gen_AutoRetailTableInsert_Service.orderDataToInsert(data, (String)data.get('operationType'));
        } catch (Exception e) {
            final String errorMsg = showErrorLog ? e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString() : e.getMessage();
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(errorMsg);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that delete the selected record
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param selectedRowId - Id of the record to delete
    * @return void
    * @example Arc_Gen_AutoRetailTableInsert_Ctrl.deleteRecord(selectedRowId)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static void deleteRecord(String selectedRowId) {
        try {
            Arc_Gen_AutoRetailBehaviorTable_Data.deleteRecord(selectedRowId);
        } catch (Exception e) {
            final String errorMsg = showErrorLog ? e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString() : e.getMessage();
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(errorMsg);
        }
    }
}