/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_RelatedTableManager_Ctr
  * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
  * @Date     Created: 2020-10-21
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Controller class of Arc_Gen_RelatedTableManager_cmp component
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-10-21 mariohumberto.ramirez.contractor@bbva.com
  *             Class Creation
  * |2020-11-10 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Add logic to return several values in method getCombosValues
  * |2020-11-12 moises.martinez.dominguez.contractor@bbva.com
  *             Add method getCombosValues for Analysis Date or Period and Analysis Category
  * |2020-11-26 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Modified if clauses
  * |2020-11-30 moises.martinez.dominguez.contractor@bbva.com
  *             Add logic if in getCombosValues
  **/
public without sharing class Arc_Gen_RelatedTableManager_Ctr {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-10-21
    * @param void
    * @return void
    * @example Arc_Gen_Hotel_Projection_Controller controller = new Arc_Gen_Hotel_Projection_Controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_RelatedTableManager_Ctr() {

    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Save currency and unit combo box
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-10-21
    * @param   recordId - id of the account has analysis
    * @param   value - value to save
    * @param   combo - type of combo
    * @return  String
    * @example saveCombos(recordId, value, combo)
    * --------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String saveCombos(String recordId, String value, String combo, String className) {
        return JSON.serialize(Arc_Gen_RelatedTableManager_Service.saveCombos(recordId, value, combo, className));
    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get the currency and unit combo value of the hotel projection table
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-10-21
    * @param   recordId - id of the account has analysis
    * @param   tableType - table type to diferenciate among tables
    * @return  String
    * @example getCombosValues(recordId)
    * --------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getCombosValues(String recordId, String tableType) {
        String response;
        if (tableType == 'Contracts_Appraisals') {
            response = Arc_Gen_Contracts_Appraisals_Service.getTableData(recordId);
        }
        else if (tableType == 'Analysis_Date') {
            response = Arc_Gen_Analysis_Date_Service.getTableData(recordId);
        }
        else if (tableType == 'Analysis_Category') {
            response = Arc_Gen_Analysis_Category_Service.getTableData(recordId);
        } else {
            response = Arc_Gen_Hotel_Projection_Controller.getTableData(recordId);
        }
        return response;
    }
}