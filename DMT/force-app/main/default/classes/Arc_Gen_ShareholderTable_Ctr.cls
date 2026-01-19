/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ShareholderTable_Ctr
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-05-06
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_ShareholderTable component
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-05-06 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_ShareholderTable_Ctr {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-05-06
    * @param void
    * @return void
    * @example Arc_Gen_ShareholderTable_Ctr controller = new Arc_Gen_ShareholderTable_Ctr()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ShareholderTable_Ctr() {

    }
    /*
        @Description wrapper with the info of the shareholder group table
    */
    public class ShareHoldTableWp {
        /*
            @Description row information of the table
        */
        @AuraEnabled public List<Map<String,String>> rowInfo {get;set;}
        /*
            @Description columns information of the table
        */
        @AuraEnabled public Set<String> columnsInfo {get;set;}
        /*
            @Description row data to build the table
        */
        @AuraEnabled public List<List<String>> rowData {get;set;}
        /*
            @Description Boolean to know if there are records to build the table
        */
        @AuraEnabled public Boolean hasInfo {get;set;}
    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description get the shareholder group table info needed to build the table
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-05-06
    * @param   recordId - id of the account has analysis
    * @param   columns2Show - names of the columns to show
    * @return  Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp wrapper with the structure needed to build
    *          the table
    * @example getData(recordId, columns2Show)
    * --------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getData(String recordId, List<String> columns2Show) {
        return JSON.serialize(Arc_Gen_ShareholderTable_Service.getData(recordId, columns2Show));
    }
}