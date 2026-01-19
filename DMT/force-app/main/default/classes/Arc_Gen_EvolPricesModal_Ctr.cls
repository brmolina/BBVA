/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_EvolPricesModal_Ctr
* @Author   Mario Humberto Ramirez Lio
* @Date     Created: 2021-26-01
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class to manage Arc_Gen_EvolPricesTableModal cmp
* ------------------------------------------------------------------------------------------------
* |2021-26-01 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_EvolPricesModal_Ctr {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param void
    * @return void
    * @example Arc_Gen_EvolPricesModal_Ctr controller = new Arc_Gen_EvolPricesModal_Ctr()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_EvolPricesModal_Ctr() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description upsert evolution of the prices of the main products records
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param records - String with the records to insert
    * @return string with the response of the action
    * @example insertRecords(records)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static string insertRecords(String records) {
        return Arc_Gen_EvolPricesModal_Service.insertRecords(records);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description method that delete arce__evol_main_prod_agro__c object records
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param records - List String with the record ids to delete
    * @return string with the response of the action
    * @example insertRecords(records)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static string deleteRecords(List<String> records) {
        return Arc_Gen_EvolPricesModal_Service.deleteRecords(records);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description load the records to show in the modal
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param accHasId - id of the accoun has analysis object
    * @return string with the response of the action
    * @example loadRecords(accHasId)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static string loadRecords(String accHasId) {
        return Arc_Gen_EvolPricesModal_Service.loadRecords(accHasId);
    }
}