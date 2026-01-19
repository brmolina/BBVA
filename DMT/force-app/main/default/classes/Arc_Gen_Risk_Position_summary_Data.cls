/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Risk_Position_summary_Data
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-11-27
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Data class of arce__risk_position_summary__c object
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-11-27 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Added new methods getPositionSummaryByAccount, getPositionSummaryByProd, insertRecords
* |2020-03-20 berthaelena.tellez.contractor@bbva.com
*             Added new file arce__account_Id__r.AccountNumber in method getPositionSummaryData
* |2020-07-27 joseluis.garcia4.contractor@bbva.com
*             Added field ProductCode to getPositionSummaryData() query.
* |2020-11-11 juanignacio.hita.contractor@bbva.com
*             Added arce__Product_id__r.Family field in getPositionSummaryData method
* |2021-02-02 luisdavid.rivera.ortiz@bbva.com
*             Eliminated unused fields
*-----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_Risk_Position_summary_Data {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-11-27
    * @param void
    * @return void
    * @example Arc_Gen_Risk_Position_summary_Data data = new Arc_Gen_Risk_Position_summary_Data()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Risk_Position_summary_Data() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Return arce__risk_position_summary__c data
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-11-27
    * @param recordIds - List<Id> of arce__risk_position_summary__c object
    * @return List of arce__risk_position_summary__c data
    * @example getPositionSummaryData(recordIds)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__risk_position_summary__c> getPositionSummaryData(List<Id> recordIds) {
        return [SELECT arce__account_Id__c,arce__account_Id__r.ParentId,arce__account_Id__r.AccountNumber,arce__account_Id__r.Name,arce__account_has_analysis_id__c,
                arce__account_has_analysis_id__r.arce__Customer__c,arce__account_has_analysis_id__r.arce__Customer__r.Name,
                arce__banrel_comments_desc__c,arce__banrel_commitment_name__c,
                arce__customer_country_name__c,CreatedById,CurrencyIsoCode,arce__banrel_current_limit_name__c,LastModifiedById,arce__participant_name__c,
                arce__banrel_uncommitment_name__c,arce__banrel_outstanding_name__c,OwnerId,arce__Product_id__c,arce__Product_id__r.Name,
                arce__Product_id__r.ExternalId,arce__Product_id__r.ProductCode,
                RecordTypeId,Name,arce__Product_id__r.Family
                FROM arce__risk_position_summary__c
                WHERE arce__account_has_analysis_id__c = :recordIds];
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that return's a record type id of the arce__risk_position_summary__c object
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-11-27
    * @param recordTypeDevName - developer name of the record type
    * @return Id of the recordType
    * @example getRecordTypeRiskPositionSum(recordTypeDevName)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Id getRecordTypeRiskPositionSum(String recordTypeDevName) {
        return Schema.SObjectType.arce__risk_position_summary__c.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that delete arce__risk_position_summary__c data
    * -----------------------------------------------------------------------------------------------
    * @param recort2Del - List Ids of records to delete
    * @return void
    * @example deleteRecord(recort2Del)
    * -----------------------------------------------------------------------------------------------
    **/
    public static void deleteRecord(List<String> recort2Del) {
        delete [SELECT Id FROM arce__risk_position_summary__c WHERE Id = :recort2Del];
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Return arce__risk_position_summary__c data
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param recordIds - List<Id> of arce__risk_position_summary__c object
    * @return List of arce__risk_position_summary__c data
    * @example getPositionSummaryByAccount(accHasIdLts, accIdLts)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__risk_position_summary__c> getPositionSummaryByAccount(List<Id> accHasIdLts, List<Id> accIdLts) {
        return [SELECT arce__account_Id__c,arce__account_Id__r.ParentId,arce__account_Id__r.Name,arce__account_has_analysis_id__c,
                        arce__account_has_analysis_id__r.arce__Customer__c,arce__account_has_analysis_id__r.arce__Customer__r.Name,
                        arce__account_has_analysis_id__r.arce__group_asset_header_type__c,
                        arce__banrel_comments_desc__c,arce__banrel_commitment_name__c,arce__customer_country_name__c,CreatedById,CurrencyIsoCode,
                        arce__banrel_current_limit_name__c,LastModifiedById,arce__participant_name__c,arce__banrel_uncommitment_name__c,
                        arce__banrel_outstanding_name__c,OwnerId,arce__Product_id__c,arce__Product_id__r.Name,
                        RecordTypeId,Name
                FROM arce__risk_position_summary__c
                WHERE arce__account_has_analysis_id__c = :accHasIdLts AND arce__account_Id__c = :accIdLts];
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Return arce__risk_position_summary__c data
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param recordIds - List<Id> of arce__risk_position_summary__c object
    * @return List of arce__risk_position_summary__c data
    * @example getPositionSummaryByAccount(accHasIdLts, accIdLts)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__risk_position_summary__c> getPositionSummaryByProd(List<Id> accHasIdLts, List<String> accIdLts) {
        return [SELECT arce__account_Id__c,arce__account_Id__r.ParentId,arce__account_Id__r.Name,arce__account_has_analysis_id__c,
                        arce__account_has_analysis_id__r.arce__Customer__c,arce__account_has_analysis_id__r.arce__Customer__r.Name,
                        arce__account_has_analysis_id__r.arce__group_asset_header_type__c,
                        arce__banrel_comments_desc__c,arce__banrel_commitment_name__c,arce__customer_country_name__c,CreatedById,CurrencyIsoCode,
                        arce__banrel_current_limit_name__c,LastModifiedById,arce__participant_name__c,arce__banrel_uncommitment_name__c,
                        arce__banrel_outstanding_name__c,OwnerId,arce__Product_id__c,arce__Product_id__r.Name,arce__Product_id__r.ExternalId,
                        RecordTypeId,Name
                FROM arce__risk_position_summary__c
                WHERE arce__account_has_analysis_id__c = :accHasIdLts AND arce__Product_id__r.ExternalId = :accIdLts];
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Insert arce__risk_position_summary__c record
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param records - List<arce__risk_position_summary__c>
    * @return void
    * @example insertRecords(records)
    * -----------------------------------------------------------------------------------------------
    **/
    public static void insertRecords(List<arce__risk_position_summary__c> records) {
        if (!records.isEmpty()) {
            insert records;
        }
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Update arce__risk_position_summary__c record
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-01-28
    * @param records - List<arce__risk_position_summary__c>
    * @return void
    * @example insertRecords(records)
    * -----------------------------------------------------------------------------------------------
    **/
    public static void updateRecords(List<arce__risk_position_summary__c> records) {
        if (!records.isEmpty()) {
            update records;
        }
    }
}