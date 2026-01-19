/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Analysis_Date_Controller
  * @Author   moises.martinez.dominguez.contractor@bbva.com
  * @Date     Created: 2020-11-11
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Controller class of Arc_Gen_Analysis_Date_Table_cmp component
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-11-11 moises.martinez.dominguez.contractor@bbva.com
  *             Class Creation
  **/
public without sharing class Arc_Gen_Analysis_Date_Controller {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-11
    * @param void
    * @return void
    * @example Arc_Gen_Analysis_Date_Controller controller = new Arc_Gen_Analysis_Date_Controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Analysis_Date_Controller() {

    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get the analysis date info to get picklist values
    *---------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-11
    * @param   recordId - id of the account has analysis
    * @return  String
    * @example getTableData(recordId)
    * --------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getTableData(String recordId) {
        return Arc_Gen_Analysis_Date_Service.getTableData(recordId);
    }

}