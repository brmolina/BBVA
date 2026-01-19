/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AutoRetailBehaviorTable_Ctrl
* @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2021-01-26
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Auto retail behavior table
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-01-26 eduardoefrain.hernandez.contractor@bbva.com
*             Class Creation
* |2021-02-15 eduardoefrain.hernandez.contractor@bbva.com
*             Added getPreviouslySelectedYear method to manage the previous selected year by the user
* |2021-02-15 eduardoefrain.hernandez.contractor@bbva.com
*             Update variable names
* |2021-04-15 eduardoefrain.hernandez.contractor@bbva.com
*             Fix Documentation
* |2022-02-24 francisco.munoz.torres.contractor@bbva.com
*             Send stage and status of the Arce in getPreviouslySelectedYear
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_AutoRetailBehaviorTable_Ctrl {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Ctrl controller = new Arc_Gen_AutoRetailBehaviorTable_Ctrl()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_AutoRetailBehaviorTable_Ctrl() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to create the table
    * -----------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return all the information to create the table
    * @example BehaviorTableData wrapper = new BehaviorTableData()
    * -----------------------------------------------------------------------------------------------
    **/
    public class BehaviorTableData {
        /**
        * @Description: Boolean that represent a succesfull call
        */
        @AuraEnabled public List<Arc_Gen_AutoRetailTableRow> tableData {get;set;}
        /**
        * @Description: Map with some info in the data
        */
        @AuraEnabled public List<Arc_Gen_TableColumns> tableColumns {get;set;}
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to create the table
    * -----------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return all the information to create the table
    * @example SelectedYear wrapper = new SelectedYear()
    * -----------------------------------------------------------------------------------------------
    **/
    public class SelectedYear {
        /**
        * @Description: Boolean that represent a succesfull call
        */
        @AuraEnabled public String hasYearSelected {get;set;}
        /**
        * @Description: Map with some info in the data
        */
        @AuraEnabled public String year {get;set;}
        /**
        * @Description: Indicator of edit permission
        */
        @AuraEnabled public String permissionToEdit {get;set;}
        /**
        * @Description: Status of the AHA
        */
        @AuraEnabled public String arceStage {get;set;}
        /**
        * @Description: State of the AHA
        */
        @AuraEnabled public String arceStatus {get;set;}
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return a JSON with the data to construct the policie table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param data - Map with the data to retrieve data
    * @return BehaviorTableData - Wrapper with the data of the
    * @example Arc_Gen_AutoRetailBehaviorTable_Ctrl.getTableData(data)
    * --------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:DUDataflowAnomalyAnalysis')
    @AuraEnabled
    public static BehaviorTableData getTableData(Map<String, String> data) {
        final BehaviorTableData response = new BehaviorTableData();
        try {
            if(data.isEmpty()) {
                throw new Arc_Gen_AutoRetailTableInsert_Helper.AutoRetailGenericException(System.Label.Lc_arce_autoRetailTable_GetTableDataError);
            }
            final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{data.get('recordId')}).get(0);
            final Map<String,Object> dataMap = Arc_Gen_AutoRetailBehaviorTable_Service.getAutoRetailData(aha, data.get('tableType'), data.get('year1'), data.get('year2'));
            response.tableColumns = (List<Arc_Gen_TableColumns>)dataMap.get('columns');
            response.tableData = (List<Arc_Gen_AutoRetailTableRow>)dataMap.get('rows');
        } catch (Exception e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString());
        }
        return response;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return a Wrapper with the year data of the auto retail table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param accHasAnalysisId - Standard Id of the analyzed client
    * @return SelectedYear - Wrapper with the year data
    * @example Arc_Gen_AutoRetailBehaviorTable_Ctrl.getPreviouslySelectedYear(accHasAnalysisId)
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static SelectedYear getPreviouslySelectedYear(String accHasAnalysisId) {
        final SelectedYear response = new SelectedYear();
        try {
            final arce__Account_has_Analysis__c aha = Arc_Gen_AutoRetailBehaviorTable_Data.getPreviousSelectedYear(accHasAnalysisId);
            final arce__analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
            response.hasYearSelected = aha.arce__year_id__c == null ? 'false' : 'true';
            response.year = aha.arce__year_id__c == null ? '' : aha.arce__year_id__c;
            response.permissionToEdit = Arc_Gen_TabSet_service.getPermissionToEdit(accHasAnalysisId);
            response.arceStage = analysis.arce__Stage__c;
            response.arceStatus = analysis.arce__wf_status_id__c;
        } catch (Exception e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(e.getMessage() + arce.Arc_Gen_Constants.HYPHEN + e.getStackTraceString());
        }
        return response;
    }
}