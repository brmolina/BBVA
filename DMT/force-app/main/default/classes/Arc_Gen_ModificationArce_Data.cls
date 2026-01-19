/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_ModificationArce_Data
  * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
  * @Date     Created: 2020-05-20
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Data class to control all the modification logic of a ARCE
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-05-20 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Class Creation
  * |2020-07-23 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Removed unused methods
  **/
  public without sharing class Arc_Gen_ModificationArce_Data {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_ModificationArce_Data data = new Arc_Gen_ModificationArce_Data()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ModificationArce_Data() {

    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method to insert records
    * ---------------------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-05-20
    * @param    ltsRecords - List<insertRecords> list of records to insert
    * @return   void
    * @example  insertArce(ltsRecords)
    * ---------------------------------------------------------------------------------------------------
    **/
    public static void insertRecords(List<sObject> ltsRecords) {
        insert ltsRecords;
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method to update records
    * ---------------------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-05-20
    * @param    ltsRecords - List<updateRecords> list of records to update
    * @return   void
    * @example  updateRecords(ltsRecords)
    * ---------------------------------------------------------------------------------------------------
    **/
    public static void updateRecords(List<sObject> ltsRecords) {
        update ltsRecords;
    }
}