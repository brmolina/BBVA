/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AutoRetailTableInsert_Helper
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
* |2021-02-25 eduardoefrain.hernandez.contractor@bbva.com
*             Remove decimal parsing in years
* |2021-03-04 eduardoefrain.hernandez.contractor@bbva.com
*             Added tableType validation parameter to the validateCompanyName method
* |2021-04-15 eduardoefrain.hernandez.contractor@bbva.com
*             Update methods with a lot of parameters to only one data map parameter
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:LongVariable')
public class Arc_Gen_AutoRetailTableInsert_Helper {
    /**
        * @Description: String with value "false"
    */
    static final string FALSE_S = 'false';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailTableInsert_Helper controller = new Arc_Gen_AutoRetailTableInsert_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_AutoRetailTableInsert_Helper() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain all the information to create the table
    * -----------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return all the information to create the table
    * @example Arc_Gen_AutoRetailTableInsert_Helper.YearData wrapper = new BehaviorTableData()
    * -----------------------------------------------------------------------------------------------
    **/
    public class YearData {
        /**
        * @Description: Stock rotation description of the year 1
        */
        @AuraEnabled public String stockRotationYear1 {get;set;}
        /**
        * @Description: Total units sold in the year 1
        */
        @AuraEnabled public Decimal totalUnitsYear1 {get;set;}
        /**
        * @Description: Slected year 1
        */
        @AuraEnabled public String year1 {get;set;}
        /**
        * @Description: Stock rotation description of the year 2
        */
        @AuraEnabled public String stockRotationYear2 {get;set;}
        /**
        * @Description: Total units sold in the year 2
        */
        @AuraEnabled public Decimal totalUnitsYear2 {get;set;}
        /**
        * @Description: Slected year 2
        */
        @AuraEnabled public String year2 {get;set;}
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Custom exception that throws when an error occured while try to save the data
    * -----------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @example throw new Arc_Gen_AutoRetailTableInsert_Helper.SaveTableRecordsException('Something')
    * -----------------------------------------------------------------------------------------------
    **/
    public class SaveTableRecordsException extends Exception {}
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Custom exception that throws when the user input invalid data
    * -----------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @example throw new Arc_Gen_AutoRetailTableInsert_Helper.InvalidParametersException('Something')
    * -----------------------------------------------------------------------------------------------
    **/
    public class InvalidParametersException extends Exception {}
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Custom exception that throws when a generic error occurs
    * -----------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @example throw new Arc_Gen_AutoRetailTableInsert_Helper.AutoRetailGenericException('Something')
    * -----------------------------------------------------------------------------------------------
    **/
    public class AutoRetailGenericException extends Exception {}
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that inserts the table values
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param data - Map with the values typed by the user
    * @param tableObj - arce__autoretail_behavior_table__c record
    * @return void
    * @example Arc_Gen_AutoRetailTableInsert_Helper.insertTable(data, tableObj)
    * --------------------------------------------------------------------------------------
    **/
    public static void insertTable(Map<String, Object> data, arce__autoretail_behavior_table__c tableObj) {
        final arce.Arc_Gen_GenericUtilities.SaveResult sr1 = arce.Arc_Gen_GenericUtilities.insertRecords(new List<sObject>{tableObj});
        manageError(sr1);
        final List<arce__autoretail_behavior_by_year__c> yearsObjs = new List<arce__autoretail_behavior_by_year__c>();
        final YearData yearObj = getYearData(data);
        yearsObjs.add(setDataByYear(tableObj.Id, yearObj.stockRotationYear1, yearObj.totalUnitsYear1, yearObj.year1));
        yearsObjs.add(setDataByYear(tableObj.Id, yearObj.stockRotationYear2, yearObj.totalUnitsYear2, yearObj.year2));
        final arce.Arc_Gen_GenericUtilities.SaveResult saveRes = arce.Arc_Gen_GenericUtilities.insertRecords(yearsObjs);
        manageError(saveRes);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that updates the table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param data - Map with the values typed by the user
    * @param tableObj - arce__autoretail_behavior_table__c record
    * @return void
    * @example Arc_Gen_AutoRetailTableInsert_Helper.updateTable(data, tableObj)
    * --------------------------------------------------------------------------------------
    **/
    public static void updateTable(Map<String, Object> data, arce__autoretail_behavior_table__c tableObj) {
        final List<sObject> yearsObjs = new List<sObject> {tableObj};
        final YearData yearObj = getYearData(data);
        final arce__autoretail_behavior_by_year__c year1Obj = setDataByYear(tableObj.Id, yearObj.stockRotationYear1, yearObj.totalUnitsYear1, yearObj.year1);
        year1Obj.Id = (String)data.get('standardYear1Id');
        final arce__autoretail_behavior_by_year__c year2Obj = setDataByYear(tableObj.Id, yearObj.stockRotationYear2, yearObj.totalUnitsYear2, yearObj.year2);
        year2Obj.Id = (String)data.get('standardYear2Id');
        yearsObjs.add(year1Obj);
        yearsObjs.add(year2Obj);
        final arce.Arc_Gen_GenericUtilities.SaveResult saveRes = arce.Arc_Gen_GenericUtilities.updateRecords(yearsObjs);
        manageError(saveRes);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that set the child records by year
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param tableId - Id of the arce__autoretail_behavior_table__c.
    * @param rotationDesc - Description of the rotation of the stock
    * @param unitsSold - Units sold in year
    * @param year - selected year
    * @return arce__autoretail_behavior_by_year__c - Child data by year
    * @example Arc_Gen_AutoRetailTableInsert_Helper.setDataByYear(tableId, rotationDesc, unitsSold, year)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__autoretail_behavior_by_year__c setDataByYear(String tableId, String rotationDesc, Decimal unitsSold, String year) {
        return new arce__autoretail_behavior_by_year__c(
            arce__autoretail_behavior_table_id__c = tableId,
            arce__gf_stock_rotation_desc__c = rotationDesc,
            arce__gf_prd_typ_sold_units_number__c = unitsSold,
            arce__year_id__c = year
        );
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return a wrapper to construct the year records
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param data - Map with the values typed by the user
    * @return YearData - Wrapper with the data of a year record
    * @example Arc_Gen_AutoRetailTableInsert_Helper.getYearData(data)
    * --------------------------------------------------------------------------------------
    **/
    public static YearData getYearData(Map<String, Object> data) {
        final YearData obj = new YearData();
        obj.stockRotationYear1 = (String)validateField(data.get('stockRotationYear1'), 'text');
        obj.totalUnitsYear1 = (Decimal)validateField(data.get('totalUnitsYear1'), 'number');
        obj.year1 = (String)data.get('year1');
        obj.stockRotationYear2 = (String)validateField(data.get('stockRotationYear2'), 'text');
        obj.totalUnitsYear2 = (Decimal)validateField(data.get('totalUnitsYear2'), 'number');
        obj.year2 = (String)data.get('year2');
        return obj;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that throws an exception if an error occured when a dml operation is executed
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param saveResult - Wrapper that contains the status of a dml operation
    * @return void
    * @example Arc_Gen_AutoRetailTableInsert_Helper.manageError(saveResult)
    * --------------------------------------------------------------------------------------
    **/
    public static void manageError(arce.Arc_Gen_GenericUtilities.SaveResult saveResult) {
        if(saveResult.status == FALSE_S) {
            throw new SaveTableRecordsException(saveResult.message);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that validates if a field is null
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param field - value of a field
    * @param fieldType - type of the field -> text, number
    * @return Object - Returns the same field
    * @example Arc_Gen_AutoRetailTableInsert_Helper.validateField(field, fieldType)
    * --------------------------------------------------------------------------------------
    **/
    public static Object validateField(Object field, String fieldType) {
        switch on fieldType {
            when 'text' {
                if((String)field == null || (String)field == '') {
                    throw new InvalidParametersException(System.label.Lc_arce_autoRetailTable_FieldValidationError);
                }
            }
            when 'number' {
                if((Decimal)field == null) {
                    throw new InvalidParametersException(System.label.Lc_arce_autoRetailTable_FieldValidationError);
                }
                if((Decimal)field < 0) {
                    throw new InvalidParametersException(System.label.Lc_arce_autoRetailTable_NumberFieldValidationError);
                }
            }
        }
        return field;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that validates if the typed company is duplicated
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param companyName - Name of the company
    * @param brandName - String with whe name of the controller class
    * @param tableType - 1 -> New, 2 -> SemiNew
    * @return void
    * @example Arc_Gen_AutoRetailTableInsert_Helper.validateCompanyName(companyName, brandName)
    * --------------------------------------------------------------------------------------
    **/
    public static void validateCompanyName(Map<String, Object> data) {
        final List<arce__autoretail_behavior_table__c> tableRecords = Arc_Gen_AutoRetailBehaviorTable_Data.getByCompanyAndBrand(data);
        if(!tableRecords.isEmpty()) {
            throw new InvalidParametersException(System.label.Lc_arce_autoRetailTable_DuplicatedCompanyError);
        }
    }
}