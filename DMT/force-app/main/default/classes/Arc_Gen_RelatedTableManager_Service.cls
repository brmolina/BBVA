/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_RelatedTableManager_Service
  * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
  * @Date     Created: 2020-10-21
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Service class of Arc_Gen_RelatedTableManager_cmp component
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-10-21 mariohumberto.ramirez.contractor@bbva.com
  *             Class Creation
  **/
public without sharing class Arc_Gen_RelatedTableManager_Service {
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
    private Arc_Gen_RelatedTableManager_Service() {

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
    * @param   className - class reference to save values
    * @return  Arc_Gen_ServiceAndSaveResponse
    * @example saveCombos(recordId, value, combo, className)
    * --------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse saveCombos(String recordId, String value, String combo, String className) {
        final System.Type objType = Type.forName(className);
        final Arc_Gen_RelatedTableManager_Interface classLocModRen = (Arc_Gen_RelatedTableManager_Interface)objType.newInstance();
        return classLocModRen.saveCombos(recordId, value, combo);
    }
}