/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Contracts_Appraisals_Service
  * @Author   Juan Manuel Perez Ortiz juanmanuel.perez.ortiz.contractor@bbva.com
  * @Date     Created: 2020-11-10
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Service class of Arc_Gen_Contracts_Appraisals_Table_cmp component
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-11-10 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Class Creation
  * |2020-11-13 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Modified record creation name
  **/
public without sharing class Arc_Gen_Contracts_Appraisals_Service {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_Contracts_Appraisals_Service service = new Arc_Gen_Contracts_Appraisals_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Contracts_Appraisals_Service() {

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
    * @Description get the contracts and appraisals info to get picklist values
    *---------------------------------------------------------------------------------------------------
    * @Author  juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date    2020-11-10
    * @param   recordId - id of the account has analysis
    * @return  String
    * @example getTableData(recordId)
    * --------------------------------------------------------------------------------------------------
    **/
    public static String getTableData(String recordId) {
        Arc_Gen_Contracts_Appraisals_Service.DataTable tableWrapper = new Arc_Gen_Contracts_Appraisals_Service.DataTable();
        final List<arce__contracts_and_appraisals__c> tableInfo = Arc_Gen_Contracts_Appraisals_Locator.getContractsAppraisalsRecords(recordId);
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
    * @Author  juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date    2020-11-10
    * @param   recordId - id of the account has analysis
    * @return  void
    * @example insertTableRecord(recordId)
    * --------------------------------------------------------------------------------------------------
    **/
    public static void insertTableRecord(String recordId) {
        final List<arce__contracts_and_appraisals__c> contractsAppraisals = Arc_Gen_Contracts_Appraisals_Locator.getContractsAppraisalsRecords(recordId);
        if (contractsAppraisals.isEmpty()) {
            arce__contracts_and_appraisals__c dummyRecordAppr = new arce__contracts_and_appraisals__c();
            dummyRecordAppr.arce__gf_hotel_name__c = 'Dummy Hotel Currency and Units';
            dummyRecordAppr.CurrencyIsoCode = 'EUR';
            dummyRecordAppr.arce__magnitude_unit_type__c = '3';
            dummyRecordAppr.arce__account_has_analysis_id__c = recordId;
            insert dummyRecordAppr;
        }
    }
}