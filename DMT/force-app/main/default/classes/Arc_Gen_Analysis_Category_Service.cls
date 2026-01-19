/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Analysis_Category_Service
  * @Author   moises.martinez.dominguez.contractor@bbva.com
  * @Date     Created: 2020-11-12
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Service class of Arc_Gen_Analysis_Category_Table_cmp component
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-11-12 moises.martinez.dominguez.contractor@bbva.com
  *             Class Creation
  * |2020-11-30 moises.martinez.dominguez.contractor@bbva.com
  *             change insert name table category
  **/
  public without sharing class Arc_Gen_Analysis_Category_Service {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-12
    * @param void
    * @return void
    * @example Arc_Gen_Analysis_Category_Service service = new Arc_Gen_Analysis_Category_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Analysis_Category_Service() {

    }
    /*
        @Description wrapper with the info of the porojection table table
    */
    public class DataTable {
        /*
            @Description currency information of the table
        */
        @AuraEnabled public String currencyVal {get;set;}
        /*
            @Description unit information of the table
        */
        @AuraEnabled public String unit {get;set;}
        /*
            @Description show / hide manage button
        */
        @AuraEnabled public String showButton {get;set;}
    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get the analysis date info to get picklist values
    *---------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-12
    * @param   recordId - id of the account has analysis
    * @return  String
    * @example getTableData(recordId)
    * --------------------------------------------------------------------------------------------------
    **/
    public static String getTableData(String recordId) {
        final Arc_Gen_Analysis_Category_Service.DataTable tableWrapper = new Arc_Gen_Analysis_Category_Service.DataTable();
        final List<arce__hotel_analysis_category__c> tableInfo = Arc_Gen_Analysis_Category_Locator.getCategoryRecords(recordId);
        if (!tableInfo.isEmpty()) {
            tableWrapper.currencyVal = tableInfo[0].CurrencyIsoCode;
            tableWrapper.unit = Arc_Gen_Hotel_Projection_Helper.getUnit(tableInfo[0].arce__magnitude_unit_type__c);
        }

        tableWrapper.showButton = Arc_Gen_TabSet_service.getPermissionToEdit(recordId);
        return JSON.serialize(tableWrapper);
    }

    /**
    *---------------------------------------------------------------------------------------------------
    * @Description insert the record dummy with currency and units
    *---------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-12
    * @param   recordId - id of the account has analysis
    * @return  void
    * @example insertTableRecord(recordId)
    * --------------------------------------------------------------------------------------------------
    **/
    public static void insertTableRecord(String recordId) {
        final List<arce__hotel_analysis_category__c> category = Arc_Gen_Analysis_Category_Locator.getCategoryRecords(recordId);
        if (category.isEmpty()) {
            final arce__hotel_analysis_category__c recordCategory = new arce__hotel_analysis_category__c();
            recordCategory.Name = 'Dummy Hotel analysisCategory Hotel Currency';
            recordCategory.CurrencyIsoCode = 'EUR';
            recordCategory.arce__magnitude_unit_type__c = '3';
            recordCategory.arce__account_has_analysis_id__c = recordId;
            insert recordCategory;
        }
    }
}