/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AutoRetailBehaviorTable_Data
* @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2021-01-26
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Data class for Auto retail behavior table
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-01-26 eduardoefrain.hernandez.contractor@bbva.com
*             Class Creation
* |2021-02-15 eduardoefrain.hernandez.contractor@bbva.com
*             Added getPreviousSelectedYear method to manage the previous selected year by the user
* |2021-03-04 eduardoefrain.hernandez.contractor@bbva.com
*             Added tableType validation to the getByCompanyAndBrand method
* |2021-03-24 eduardoefrain.hernandez.contractor@bbva.com
*             Add copying of autoretail table in modification and renovation - Add getAutoRetailToCopy method
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:AvoidSoqlWithNegativeLogic')
public without sharing class Arc_Gen_AutoRetailBehaviorTable_Data {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Data controller = new Arc_Gen_AutoRetailBehaviorTable_Data()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_AutoRetailBehaviorTable_Data() {

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that retrieves a list of records filtered by accHasAnalysisId and tabletype
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param accHasAnalysisId - Id of the account_has_analysis
    * @param tableType - 1 -> New , 2 -> Semi-New
    * @param year1 - Selected year 1
    * @param year2 - Selected year 2
    * @return List<arce__autoretail_behavior_table__c> - List of table rows
    * @example Arc_Gen_AutoRetailBehaviorTable_Data.getAutoRetailData(accHasAnalysisId, tableType, year1, year2)
    * --------------------------------------------------------------------------------------
    **/
    public static List<arce__autoretail_behavior_table__c> getAutoRetailData(Id accHasAnalysisId, String tableType, String year1, String year2) {
        return [SELECT Id, arce__gf_company_name__c, arce__gf_entity_risk_bal_cur_amount__c, arce__gf_group_cmpnt_tl_sum_number__c, arce__gf_prd_typ_sold_units_number__c,
            arce__gf_stock_days_number__c, arce__gf_stock_rotation_desc__c, arce__gf_vehicle_brand_name__c,arce__gf_agencies_number__c,
            (SELECT Id,arce__gf_year_type__c, arce__year_id__c, arce__gf_prd_typ_sold_units_number__c,arce__gf_stock_rotation_desc__c
                FROM arce__Auto_Retail_Behavior_by_Year__r
                WHERE arce__year_id__c =: year1 OR arce__year_id__c =: year2 ORDER BY CreatedDate DESC LIMIT 2)
            FROM arce__autoretail_behavior_table__c
            WHERE arce__account_has_analysis_id__c =: accHasAnalysisId AND arce__gf_product_status_type__c =: tableType
            ORDER BY CreatedDate DESC];
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that retrieves a list of records filtered by Id
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param selectedRowId - Id of the selected row in the table
    * @param year1 - Selected year 1
    * @param year2 - Selected year 2
    * @return List<arce__autoretail_behavior_table__c> - List of table rows
    * @example Arc_Gen_AutoRetailBehaviorTable_Data.getRowById(selectedRowId, year1, year2)
    * --------------------------------------------------------------------------------------
    **/
    public static List<arce__autoretail_behavior_table__c> getRowById(String selectedRowId, String year1, String year2) {
        return [SELECT Id, arce__gf_company_name__c, arce__gf_entity_risk_bal_cur_amount__c, arce__gf_group_cmpnt_tl_sum_number__c, arce__gf_prd_typ_sold_units_number__c,
            arce__gf_stock_days_number__c, arce__gf_stock_rotation_desc__c, arce__gf_vehicle_brand_name__c,arce__gf_agencies_number__c,
            (SELECT Id,arce__gf_year_type__c, arce__year_id__c, arce__gf_prd_typ_sold_units_number__c,arce__gf_stock_rotation_desc__c
                FROM arce__Auto_Retail_Behavior_by_Year__r
                WHERE arce__year_id__c =: year1 OR arce__year_id__c =: year2 ORDER BY CreatedDate DESC LIMIT 2)
            FROM arce__autoretail_behavior_table__c
            WHERE Id =: selectedRowId LIMIT 1];
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return a list of table records filtered by company and brand
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param companyName - Company/Agency name
    * @param brandName - Brand name
    * @param tableType - 1 -> New, 2 -> SemiNew
    * @return List<arce__autoretail_behavior_table__c> - List of table rows
    * @example Arc_Gen_AutoRetailBehaviorTable_Data.getByCompanyAndBrand(companyName, brandName)
    * --------------------------------------------------------------------------------------
    **/
    public static List<arce__autoretail_behavior_table__c> getByCompanyAndBrand(Map<String, Object> data) {
        final String companyName = (String)data.get('companyName');
        final String brandName = (String)data.get('brandName');
        final String tableType = (String)data.get('tableType');
        final String ahaId = (String)data.get('ahaId');
        return [SELECT Id, arce__gf_company_name__c, arce__gf_entity_risk_bal_cur_amount__c, arce__gf_group_cmpnt_tl_sum_number__c, arce__gf_prd_typ_sold_units_number__c,
            arce__gf_stock_days_number__c, arce__gf_stock_rotation_desc__c, arce__gf_vehicle_brand_name__c,arce__gf_agencies_number__c,arce__gf_product_status_type__c
            FROM arce__autoretail_behavior_table__c
            WHERE arce__gf_company_name__c =: companyName AND arce__gf_vehicle_brand_name__c =: brandName AND arce__Account_has_Analysis_id__c =: ahaId AND
                arce__account_has_analysis_id__r.arce__Analysis__r.arce__Stage__c <> '3' AND arce__gf_product_status_type__c =: tableType];
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that Delete a selected record
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param selectedRowId - Id of the record to delete
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Data.deleteRecord(selectedRowId)
    * --------------------------------------------------------------------------------------
    **/
    public static void deleteRecord(String selectedRowId) {
        final List<SObject> recordsToDelete = [SELECT Id, arce__gf_company_name__c, arce__gf_entity_risk_bal_cur_amount__c, arce__gf_group_cmpnt_tl_sum_number__c, arce__gf_prd_typ_sold_units_number__c,
            arce__gf_stock_days_number__c, arce__gf_stock_rotation_desc__c, arce__gf_vehicle_brand_name__c,arce__gf_agencies_number__c
            FROM arce__autoretail_behavior_table__c
            WHERE Id =: selectedRowId LIMIT 1];
        if(recordsToDelete.isEmpty()) {
            throw new Arc_Gen_AutoRetailTableInsert_Helper.AutoRetailGenericException(System.Label.Lc_arce_autoRetailTable_DeleteRecordError);
        } else {
            delete recordsToDelete;
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that obtains the analyzed client of the table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param accHasAnalysisId - Id of the record to retrieve
    * @return arce__Account_has_Analysis__c Aha object record
    * @example Arc_Gen_AutoRetailBehaviorTable_Data.getPreviousSelectedYear(accHasAnalysisId)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c getPreviousSelectedYear(String accHasAnalysisId) {
        return [SELECT arce__year_id__c FROM arce__Account_has_Analysis__c WHERE Id =: accHasAnalysisId LIMIT 1];
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that retrieves a list of records filtered by accHasAnalysisId to clone in Mod/Ren
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-03-24
    * @param ahaIds - Set of Ids of the account_has_analysis
    * @return List<arce__autoretail_behavior_table__c> - List of table rows
    * @example Arc_Gen_AutoRetailBehaviorTable_Data.getAutoRetailToCopy(ahaIds)
    * --------------------------------------------------------------------------------------
    **/
    public static List<arce__autoretail_behavior_table__c> getAutoRetailToCopy(Set<Id> ahaIds) {
        return [SELECT Id, arce__gf_company_name__c, arce__gf_entity_risk_bal_cur_amount__c, arce__gf_group_cmpnt_tl_sum_number__c, arce__gf_prd_typ_sold_units_number__c,
            arce__gf_stock_days_number__c, arce__gf_stock_rotation_desc__c, arce__gf_vehicle_brand_name__c,arce__gf_agencies_number__c,arce__account_has_analysis_id__c,arce__gf_product_status_type__c,
            (SELECT Id,arce__gf_year_type__c, arce__year_id__c, arce__gf_prd_typ_sold_units_number__c,arce__gf_stock_rotation_desc__c
                FROM arce__Auto_Retail_Behavior_by_Year__r)
            FROM arce__autoretail_behavior_table__c
            WHERE arce__account_has_analysis_id__c IN: ahaIds];
    }
}