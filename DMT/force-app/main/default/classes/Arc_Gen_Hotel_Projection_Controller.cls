/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Hotel_Projection_Controller
  * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
  * @Date     Created: 2020-10-21
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Controller class of Arc_Gen_Hotel_Projection_Table component
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-10-21 mariohumberto.ramirez.contractor@bbva.com
  *             Class Creation
  **/
public without sharing class Arc_Gen_Hotel_Projection_Controller {
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
    private Arc_Gen_Hotel_Projection_Controller() {

    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get the projection table info needed to build the table
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-10-21
    * @param   recordId - id of the account has analysis
    * @return  String
    * @example getTableData(recordId)
    * --------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getTableData(String recordId) {
        return Arc_Gen_Hotel_Projection_Service.getTableData(recordId);
    }
}