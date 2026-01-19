/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AutoRetailBehaviorTable_Service
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
*             Added an update of the accHasAnalysis to save the selected year
* |2021-03-01 eduardoefrain.hernandez.contractor@bbva.com
*             Factorize methods to implement the executive summary table
* |2021-04-15 eduardoefrain.hernandez.contractor@bbva.com
*             Update methods with a lot of parameters to only one data map parameter
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_AutoRetailBehaviorTable_Service {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Service controller = new Arc_Gen_AutoRetailBehaviorTable_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_AutoRetailBehaviorTable_Service() {

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return a Map with the data to construct the autoretail table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param accHasAnalysis - Id of the account_has_analysis
    * @param tableType - 1 -> New, 2 -> SemiNew
    * @param year1 - Selected year 1
    * @param year2 - Selected year 2
    * @return response - Wrapper with the data to construct the policie table
    * @example Arc_Gen_AutoRetailBehaviorTable_Service.getAutoRetailData(accHasAnalysis, tableType, year1, year2)
    * --------------------------------------------------------------------------------------
    **/
    public static Map<String,Object> getAutoRetailData(arce__Account_has_Analysis__c accHasAnalysis, String tableType, String year1, String year2) {
        final Map<String,Object> mapResponse = new Map<String,Object>();

        final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c(
            Id = accHasAnalysis.Id,
            arce__year_id__c = year2
        );
        arce.Arc_Gen_GenericUtilities.updateRecords(new List<SObject>{aha});
        final List<Arc_Gen_TableColumns> columns = Arc_Gen_AutoRetailBehaviorTable_Helper.getColumns(year1, year2);
        final Map<String, Object> data = new Map<String, Object> {
            'accHasAnalysisId' => accHasAnalysis.Id,
            'tableType' => tableType,
            'year1' => year1,
            'year2' => year2,
            'isExecSummary' => false
        };
        final List<Arc_Gen_AutoRetailTableRow> rows = getAutoRetRows(data);

        mapResponse.put('columns', columns);
        mapResponse.put('rows', rows);
        return mapResponse;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return a Map with the data to construct the autoretail table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-03-01
    * @param data - map with the values:
    *        tableType - 1 -> New, 2 -> SemiNew
    *        year1 - Selected year 1
    *        year2 - Selected year 2
    * @return List<Arc_Gen_AutoRetailTableRow> - List of rows to build the table
    * @example Arc_Gen_AutoRetailBehaviorTable_Service.getAutoRetailData(accHasAnalysis, tableType, year1, year2)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_AutoRetailTableRow> getAutoRetRows(Map<String, Object> data) {
        final String accHasAnalysisId = (String)data.get('accHasAnalysisId');
        final String tableType = (String)data.get('tableType');
        final String year1 = (String)data.get('year1');
        final String year2 = (String)data.get('year2');

        List<Arc_Gen_AutoRetailTableRow> rows = new List<Arc_Gen_AutoRetailTableRow>();
        final List<arce__autoretail_behavior_table__c> dataList = Arc_Gen_AutoRetailBehaviorTable_Data.getAutoRetailData(accHasAnalysisId, tableType, year1, year2);
        if(dataList.isEmpty()) {
            rows.add(Arc_Gen_AutoRetailBehaviorTable_Helper.setTotalRow(0, 0, 0, 0));
        } else {
            final Map<String, Object> dataParams = new Map<String, Object> {'dataList' => dataList, 'year1' => year1, 'year2' => year2, 'isExecSummary' => (Boolean)data.get('isExecSummary')};
            rows = Arc_Gen_AutoRetailBehaviorTable_Helper.getData(dataParams);
        }
        return rows;
    }
}