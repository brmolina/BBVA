/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_EvolPricesProdTable_Service
* @Author   Mario Humberto Ramirez Lio
* @Date     Created: 2021-26-01
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class to manage Arc_Gen_EvolPricesTableModal cmp
* ------------------------------------------------------------------------------------------------
* |2021-26-01 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_EvolPricesProdTable_Service {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param void
    * @return void
    * @example Arc_Gen_EvolPricesProdTable_Service service = new Arc_Gen_EvolPricesProdTable_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_EvolPricesProdTable_Service() {

    }
    /*
    * @Description wrapper for geographies and activities table
    */
    public class EvolPricesTableWrap {
        /*
        * @Description columns info for geographies and activities table
        */
        @AuraEnabled public List<String> columns {get;set;}
        /*
        * @Description row info for geographies and activities table
        */
        @AuraEnabled public List<List<String>> rowData {get;set;}
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description return the columns and rows of the evolution prices table for agro template
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param accHasId - id of an account has analysis object
    * @return String
    * @example getTableInfo(accHasId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String getTableInfo(String accHasId) {
        final EvolPricesTableWrap wrapper = new EvolPricesTableWrap();
        final List<String> columns = Arc_Gen_evol_main_prod_agro_Locator.getColumnsOfEvolPricesTb(accHasId);
        wrapper.rowData = Arc_Gen_evol_main_prod_agro_Locator.getRowStructure(accHasId, columns);
        final List<String> columnInfo = new List<String>{Label.Arc_Gen_ProductName};
        columnInfo.addAll(columns);
        wrapper.columns = columnInfo;
        return JSON.serialize(wrapper);
    }
}