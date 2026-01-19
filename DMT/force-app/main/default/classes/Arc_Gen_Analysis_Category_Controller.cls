/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Analysis_Category_Controller
  * @Author   moises.martinez.dominguez.contractor@bbva.com
  * @Date     Created: 2020-11-12
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Controller class of Arc_Gen_Analysis_Category_Table component
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-11-12 moises.martinez.dominguez.contractor@bbva.com
  *             Class Creation
  **/
public without sharing class Arc_Gen_Analysis_Category_Controller {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-11
    * @param void
    * @return void
    * @example Arc_Gen_Analysis_Category_Controller controller = new Arc_Gen_Analysis_Category_Controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Analysis_Category_Controller() {

    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get the analysis category info to get picklist values
    *---------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-12
    * @param   recordId - id of the account has analysis
    * @return  String
    * @example getTableData(recordId)
    * --------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getTableData(String recordId) {
        return Arc_Gen_Analysis_Category_Service.getTableData(recordId);
    }

}