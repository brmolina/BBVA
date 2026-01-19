/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Auto_Position_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-01-28
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_PotitionBankTable_Ctlr
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-07-28 joseluis.garcia4.contractor@bbva.com
*             Update last update of positions only if the call to the service has just been made.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-09-23 otiliaramona.veres.contractor@bbva.com
*             Declared local variable 'dataJson' as final
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_Auto_Position_Service implements Arc_Gen_PotitionTable_Interface {
    /**
    * --------------------------------------------------------------------------------------
    * @Description get data to build table
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-01-28
    * @param recordId - id of the acc has analysis object
    * @return Arc_Gen_DataTable - wrapper with the info to build the table
    * @example getData(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public Arc_Gen_DataTable getData(Id recordId) {
        final Arc_Gen_DataTable dataJson = new Arc_Gen_DataTable();
        dataJson.columns = Arc_Gen_PotitionBankTable_Service_Helper.getColumns(recordId);
        dataJson.data = Arc_Gen_Auto_Position_Service_Helper.getRows(recordId);
        final List<arce__Account_has_Analysis__c> acchasAn = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)recordId});
        if (acchasAn[0].arce__last_update_position__c == null) {
            acchasAn[0].arce__last_update_position__c = System.now();
            arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(acchasAn);
        }
        return dataJson;
    }
}