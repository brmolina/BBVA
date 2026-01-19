/*------------------------------------------------------------------
  *Author:        Luisarturo.parra.contractor@bbva.com
  *Project:       ARCE - BBVA Bancomer
  *Description:   service class of group table:
  *Classes: Arc_Gen_groupTable_service,Arc_Gen_groupTable_data,Arc_Gen_groupTable_controller
  *_______________________________________________________________________________________
  *Version    Date           Author                                       Description
  *1.0        11/04/2019      Luisarturo.parra.contractor@bbva.com           REFACTORIZACION.
  *1.1        06/01/2020      mariohumberto.ramirez.contractor@bbva.com      Replace Account for Account wrapper in the method getMiniArceList
  *1.2        12/01/2020      mariohumberto.ramirez.contractor@bbva.com       Modify method retrieveData
  *1.2        23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
  *-----------------------------------------------------------------------------------------*/
public with sharing class Arc_Gen_groupTable_service {
    /**
    *-------------------------------------------------------------------------------
    * @description Private method for sonar
    *-------------------------------------------------------------------------------
    * @date 14/05/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @example private Arc_Gen_groupTable_controller() {
    */
    @testVisible
    private Arc_Gen_groupTable_service() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Class used to store and return data to user with given account
    *-------------------------------------------------------------------------------
    * @date 14/05/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param string accountId
    * @return List<arceDataRetrieved>
    * @example public static List<arceDataRetrieved> getMiniArceList(string accountId)
    */
    public static List<arce.Arc_Gen_Account_Wrapper> getMiniArceList(String accounts) {
        return (List<arce.Arc_Gen_Account_Wrapper>) JSON.deserialize(accounts, List<arce.Arc_Gen_Account_Wrapper>.Class);
    }
}