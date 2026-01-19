/*------------------------------------------------------------------
*Author:        Esquivel Cázares Mauricio - mauricio.esquivel.contractor@bbva.com / BBVA DWP
*Project:      	ARCE - BBVA Bancomer
*Description:   Class used for the handle data from current group structure on ARCE
*_______________________________________________________________________________________
*Version    Date           Author                               Description
*1.0        16/07/2019     Esquivel Cázares Mauricio                  Creation.
*1.1        26/08/2019     luisarturo.parra.contractor@bbva.com       Modification of retrieveData method
*1.2        06/01/2020     mariohumberto.ramirez.contractor@bbva.com  Added account wrapper
*1.3        12/01/2020     mariohumberto.ramirez.contractor@bbva.com  modify method retrieveData
*1.3        23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
-----------------------------------------------------------------------------------------*/
public with sharing class Arc_Gen_groupTable_controller {
    /**
    *-------------------------------------------------------------------------------
    * @description method for testing
    *--------------------------------------------------------------------------------
    * @date		16/07/2019
    * @author	luisarturo.parra.contractor@bbva.com
    * @param	recordId - Analysis Id
    * @return	arce__Analysis__c
    * @example	 private Arc_Gen_groupTable_controller() {
    */
    @testVisible
    private Arc_Gen_groupTable_controller() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description search for group structure of current arce
    *--------------------------------------------------------------------------------
    * @date		16/07/2019
    * @author	luisarturo.parra.contractor@bbva.com
    * @param	recordId - Analysis Id
    * @return	arce__Analysis__c
    * @example	public static arce__Analysis__c retrieveData(string recordId)
    */
    @AuraEnabled
    public static List<arce.Arc_Gen_Account_Wrapper> retrieveData(String accounts){
        return Arc_Gen_groupTable_service.getMiniArceList(accounts);
    }
}