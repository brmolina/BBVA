/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AutoRetailTableInsert_Service
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
* |2021-02-15 eduardoefrain.hernandez.contractor@bbva.com
*             Updated orderDataToInsert to set the Id only in the edit option
* |2021-03-04 eduardoefrain.hernandez.contractor@bbva.com
*             Added tableType parameter to the validateCompanyName method calling
* |2021-04-15 eduardoefrain.hernandez.contractor@bbva.com
*             Update methods with a lot of parameters to only one data map parameter
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_AutoRetailTableInsert_Service {
    /**
        * @Description: String with value "edit"
    */
    static final string EDIT_S = 'edit';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailTableInsert_Service controller = new Arc_Gen_AutoRetailTableInsert_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_AutoRetailTableInsert_Service() {

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that obtains the data of the selected row to update in the Edit Modal
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param selectedRowId - Id of the selected table row
    * @param year1 - Selected year 1
    * @param year2 - Selected year 2
    * @return Arc_Gen_AutoRetailTableRow - Wrapper with the data to construct the autoretail table
    * @example Arc_Gen_AutoRetailTableInsert_Service.getDataToEdit(selectedRowId, year1, year2)
    * --------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_AutoRetailTableRow getDataToEdit(String selectedRowId, String year1, String year2) {

        final List<arce__autoretail_behavior_table__c> selectedRow = Arc_Gen_AutoRetailBehaviorTable_Data.getRowById(selectedRowId, year1, year2);
        if(selectedRow.isEmpty()) {
            throw new Arc_Gen_AutoRetailTableInsert_Helper.AutoRetailGenericException(System.label.Lc_arce_autoRetailTable_GetRecordError);
        } else {
            final Map<String, Object> dataParams = new Map<String, Object> {
                'dataList' => new List<arce__autoretail_behavior_table__c>{selectedRow.get(0)},
                'year1' => year1,
                'year2' => year2,
                'isExecSummary' => false
            };
            return Arc_Gen_AutoRetailBehaviorTable_Helper.getData(dataParams).get(0);
        }

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that construct the arce__autoretail_behavior_table__c record
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param data - Map with the values typed by the user
    * @param operationType - indicates if the logic is to insert or to update
    * @return void
    * @example Arc_Gen_AutoRetailTableInsert_Service.orderDataToInsert(data, operationType)
    * --------------------------------------------------------------------------------------
    **/
    public static void orderDataToInsert(Map<String, Object> data, String operationType) {
        final String companyName = (String)Arc_Gen_AutoRetailTableInsert_Helper.validateField(data.get('agencyName'), 'text');
        final String brandName = (String)Arc_Gen_AutoRetailTableInsert_Helper.validateField(data.get('brand'), 'text');

        final arce__autoretail_behavior_table__c tableObj = new arce__autoretail_behavior_table__c (
            arce__account_has_analysis_id__c = (String)data.get('accHasAnalysisId'),
            arce__gf_company_name__c = companyName.toUpperCase().normalizeSpace(),
            arce__gf_agencies_number__c = (Decimal)Arc_Gen_AutoRetailTableInsert_Helper.validateField(data.get('agenciesNumber'), 'number'),
            arce__gf_vehicle_brand_name__c = brandName.toUpperCase().normalizeSpace(),
            arce__gf_entity_risk_bal_cur_amount__c = (Decimal)Arc_Gen_AutoRetailTableInsert_Helper.validateField(data.get('bankRisk'), 'number'),
            arce__gf_stock_days_number__c = (Decimal)Arc_Gen_AutoRetailTableInsert_Helper.validateField(data.get('stockDays'), 'number'),
            arce__gf_product_status_type__c = (String)Arc_Gen_AutoRetailTableInsert_Helper.validateField(data.get('tableType'), 'text')
        );

        if(operationType == EDIT_S) {
            tableObj.Id = (String)data.get('selectedRowId');
            Arc_Gen_AutoRetailTableInsert_Helper.updateTable(data, tableObj);
        } else {
            final Map<String, Object> dataToValidate = new Map<String, Object> {
                'companyName' => companyName.toUpperCase().normalizeSpace(),
                'brandName' => brandName.toUpperCase().normalizeSpace(),
                'tableType' => (String)data.get('tableType'),
                'ahaId' => (String)data.get('accHasAnalysisId')
            };
            Arc_Gen_AutoRetailTableInsert_Helper.validateCompanyName(dataToValidate);
            Arc_Gen_AutoRetailTableInsert_Helper.insertTable(data, tableObj);
        }
    }
}