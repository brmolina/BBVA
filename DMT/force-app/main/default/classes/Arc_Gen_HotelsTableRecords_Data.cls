/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_HotelsTableRecords_Data
* @Author   Juan Manuel Perez Ortiz - juanmanuel.perez.ortiz.contractor@bbva.com
* @Date     Created: 2021-05-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Data class for hotel template table records
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-05-20 juanmanuel.perez.ortiz.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_HotelsTableRecords_Data {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_HotelsTableRecords_Data service = new Arc_Gen_HotelsTableRecords_Data()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_HotelsTableRecords_Data() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a list of contracts and appraisals data of account has analysis to cloned ARCE
    * -----------------------------------------------------------------------------------------------
    * @Author   Juan Manuel Perez Ortiz juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2021-05-20
    * @param    accHasAnaIds - Set with account has analysis ids
    * @return   List<arce__contracts_and_appraisals__c> - List of arce__contracts_and_appraisals__c object
    * @example  getAccContractsAppraisalsData(Set<Id> accHasAnaIds)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__contracts_and_appraisals__c> getAccContractsAppraisalsData(Set<Id> accHasAnaIds) {
        return [SELECT arce__account_has_analysis_id__c,arce__currency_id__c,arce__magnitude_unit_type__c,CurrencyIsoCode,arce__last_assessed_date__c,arce__gf_hotel_name__c,arce__gf_htl_ownshp_ctrct_dur_number__c,arce__gf_hotel_contract_type_name__c,arce__appraisal_amount__c,arce__gf_current_expiration_date__c FROM arce__contracts_and_appraisals__c  WHERE arce__account_has_analysis_id__c IN :accHasAnaIds];
}
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a list of date or period hotel of account has analysis to cloned ARCE
    * -----------------------------------------------------------------------------------------------
    * @Author   Juan Manuel Perez Ortiz juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2021-05-20
    * @param    accHasAnaIds - Set with account has analysis ids
    * @return   List<arce__hotel_analysis_date_period__c> - List of arce__hotel_analysis_date_period__c object
    * @example  getAccDatePeriodData(Set<Id> accHasAnaIds)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__hotel_analysis_date_period__c> getAccDatePeriodData(Set<Id> accHasAnaIds) {
        return [SELECT arce__account_has_analysis_id__c,CurrencyIsoCode,Name,arce__gf_rev_per_avail_room_amount__c,arce__gf_period_end_date__c,arce__gf_period_start_date__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__magnitude_unit_type__c FROM arce__hotel_analysis_date_period__c  WHERE arce__account_has_analysis_id__c IN :accHasAnaIds];
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a list of hotel category data of account has analysis to cloned ARCE
    * -----------------------------------------------------------------------------------------------
    * @Author   Juan Manuel Perez Ortiz juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2021-05-20
    * @param    accHasAnaIds - Set with account has analysis ids
    * @return   List<arce__hotel_analysis_category__c> - List of arce__hotel_analysis_category__c object
    * @example  getAccHotelCategoryData(Set<Id> accHasAnaIds)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__hotel_analysis_category__c> getAccHotelCategoryData(Set<Id> accHasAnaIds) {
        return [SELECT arce__account_has_analysis_id__c,CurrencyIsoCode,Name,arce__gf_rev_per_avail_room_amount__c,arce__gf_hotel_occupancy_per__c,arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_hotel_category_type__c,arce__magnitude_unit_type__c FROM arce__hotel_analysis_category__c  WHERE arce__account_has_analysis_id__c IN :accHasAnaIds];
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a list of hotel projection data of account has analysis to cloned ARCE
    * -----------------------------------------------------------------------------------------------
    * @Author   Juan Manuel Perez Ortiz juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2021-05-20
    * @param    accHasAnaIds - Set with account has analysis ids
    * @return   List<arce__hotel_projection__c> - List of arce__hotel_projection__c object
    * @example  getAccHotelProjectionData(Set<Id> accHasAnaIds)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<arce__hotel_projection__c> getAccHotelProjectionData(Set<Id> accHasAnaIds) {
        return [SELECT arce__account_has_analysis_id__c,arce__gf_hotel_avg_daily_rate_amount__c,CurrencyIsoCode,arce__gf_debt_available_funds_amount__c,arce__gf_htl_gs_oper_profit_amount__c,arce__gf_interest_expense_amount__c,arce__gf_hotel_breakeven_occup_per__c,arce__gf_hotel_occupancy_per__c,arce__gf_loan_funded_amount__c,arce__gf_debt_svc_covrg_ratio_number__c,arce__gf_rev_per_avail_room_amount__c,arce__magnitude_unit_type__c,arce__gf_const_proj_year_number_type__c FROM arce__hotel_projection__c  WHERE arce__account_has_analysis_id__c IN :accHasAnaIds];
    }

}