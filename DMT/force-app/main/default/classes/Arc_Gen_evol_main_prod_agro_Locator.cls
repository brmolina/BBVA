/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_evol_main_prod_agro_Locator
* @Author   Mario Humberto Ramirez Lio
* @Date     Created: 2021-26-01
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Locator class for arce__evol_main_prod_agro__c object
* ------------------------------------------------------------------------------------------------
* |2021-26-01 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2021-16-02 mariohumberto.ramirez.contractor@bbva.com
*             Added new method 'getRecordsByAccHasIds'
* |2021-04-21 brauliobaruchs.sanpedro.contractor@bbva.com
*             Added number format to agro table
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_evol_main_prod_agro_Locator {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param void
    * @return void
    * @example Arc_Gen_evol_main_prod_agro_Locator data = new Arc_Gen_evol_main_prod_agro_Locator()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_evol_main_prod_agro_Locator() {

    }
    /**
    *------------------------------------------------------------------------------------------------------------------
    * @Description get the columns to build the evolution prices table
    *------------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param  recordId - id of the account has analysis object
    * @param  type - table type
    * @return List<String>
    * @example getColumnsOfGeoActTb(recordId, type)
    *------------------------------------------------------------------------------------------------
    **/
    public static List<String> getColumnsOfEvolPricesTb(String recordId) {
        final List<arce__evol_main_prod_agro__c> col = [SELECT arce__year_id__c
                                            FROM arce__evol_main_prod_agro__c
                                            WHERE arce__account_has_analysis_agro_id__c = :recordId
                                            ORDER BY arce__year_id__c DESC];
        final Set<String> columns = new Set<String>();
        for (arce__evol_main_prod_agro__c colData: col) {
            columns.add(String.valueOf(colData.arce__year_id__c));
        }
        return new List<String>(columns);
    }
    /**
    *------------------------------------------------------------------------------------------------------------------
    * @Description get the rows to build the geography and activity table
    *------------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param  recordId - id of the account has analysis object
    * @param  type - table type
    * @param  columns - columns of the table
    * @return List<Map<String,String>>
    * @example getGeoActRowStructure(recordId, type, columns)
    *------------------------------------------------------------------------------------------------
    **/
    public static List<List<String>> getRowStructure(String accHasId, List<String> columns) {
        final List<arce__evol_main_prod_agro__c> data = [SELECT Id, Name, arce__gf_commodity_product_name__c, arce__year_id__c, arce__gf_comod_prd_avg_price_amount__c,arce__account_has_analysis_agro_id__c
                                                                FROM arce__evol_main_prod_agro__c
                                                                WHERE arce__account_has_analysis_agro_id__c = :accHasId
                                                                ORDER BY Name ASC];
        final List<List<String>> rowsTable = new List<List<String>>();
        for (integer i = 0; i < data.size(); i++) {
            final List<String> auxlts = new List<String>();
            auxlts.add(data[i].arce__gf_commodity_product_name__c);
            auxlts.add(data[i].arce__gf_comod_prd_avg_price_amount__c.setscale(2).format());
            auxlts.add(data[i+1].arce__gf_comod_prd_avg_price_amount__c.setscale(2).format());
            auxlts.add(data[i+2].arce__gf_comod_prd_avg_price_amount__c.setscale(2).format());
            rowsTable.add(auxlts);
            i = i + 2;
        }
        return rowsTable;
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
    public static string insertRecords(String records) {
        final arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            final List<arce__evol_main_prod_agro__c> recordLts = (List<arce__evol_main_prod_agro__c>) JSON.deserialize(records, List<arce__evol_main_prod_agro__c>.Class);
            final List<Id> idResLts = new List<Id>();
            final List<Database.upsertResult> uResults = Database.upsert(recordLts);
            for (Database.upsertResult uRes: uResults) {
                idResLts.add(uRes.getId());
            }
            response.createdRsr = idResLts;
            response.saveStatus = 'true';
        } catch (Exception e) {
            response.saveStatus = 'false';
        }
        return JSON.serialize(response);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description method that delete arce__evol_main_prod_agro__c object records
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param records - List String with the record ids to delete
    * @return string with the response of the action
    * @example deleteRecords(records)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static string deleteRecords(List<String> records) {
        final arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            delete [SELECT Id FROM arce__evol_main_prod_agro__c WHERE Id = :records];
            response.saveStatus = 'true';
        } catch (Exception e) {
            response.saveStatus = 'false';
        }
        return JSON.serialize(response);
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
    public static string loadRecords(String accHasId) {
        final List<arce__evol_main_prod_agro__c> recordsLts = [SELECT Id, Name, arce__gf_commodity_product_name__c, arce__year_id__c, arce__gf_comod_prd_avg_price_amount__c,arce__account_has_analysis_agro_id__c
                FROM arce__evol_main_prod_agro__c
                WHERE arce__account_has_analysis_agro_id__c = :accHasId
                ORDER BY Name ASC];
        return JSON.serialize(recordsLts);
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description get all records filter by a list of acc ahs analysis ids
    * ----------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @date   2020-07-27
    * @param accHasId - List of ids of the accoun has analysis object
    * @return List<arce__evol_main_prod_agro__c>
    * @example getRecordsByAccHasIds(accHasIds)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static List<arce__evol_main_prod_agro__c> getRecordsByAccHasIds(Set<Id> accHasIds) {
        return [SELECT Id, Name, arce__gf_commodity_product_name__c, arce__year_id__c, arce__gf_comod_prd_avg_price_amount__c,arce__account_has_analysis_agro_id__c
                FROM arce__evol_main_prod_agro__c
                WHERE arce__account_has_analysis_agro_id__c = :accHasIds
                ORDER BY Name ASC];
    }
}