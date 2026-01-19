/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Contracts_Appraisals_Controller
  * @Author   Juan Manuel Perez Ortiz juanmanuel.perez.ortiz.contractor@bbva.com
  * @Date     Created: 2020-11-10
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Controller class of Arc_Gen_Contracts_Appraisals_Table_cmp component
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-11-10 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Class Creation
  **/
public without sharing class Arc_Gen_Contracts_Appraisals_Controller {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     2020-11-10
    * @param void
    * @return void
    * @example Arc_Gen_Contracts_Appraisals_Controller controller = new Arc_Gen_Contracts_Appraisals_Controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Contracts_Appraisals_Controller() {

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
    @AuraEnabled
    public static String getTableData(String recordId) {
        return Arc_Gen_Contracts_Appraisals_Service.getTableData(recordId);
    }

}