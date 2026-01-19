/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Hotel_Projection_Locator
  * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
  * @Date     Created: 2020-10-21
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Locator class for arce__hotel_proyection__c
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-10-21 mariohumberto.ramirez.contractor@bbva.com
  *             Class Creation
  * |2020-12-03 moises.martinez.dominguez.contractor@bbva.com
  *             Add query for unit and currency limit 1 for table hotel projection
  **/
public without sharing class Arc_Gen_Hotel_Projection_Locator {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-10-21
    * @param void
    * @return void
    * @example Arc_Gen_Hotel_Projection_Locator data = new Arc_Gen_Hotel_Projection_Locator()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Hotel_Projection_Locator() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description get arce__hotel_projection__c records
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-10-21
    * @param recordId - id of the account has analysis object
    * @return List<arce__hotel_projection__c>
    * @example getHotelProjectionInfo(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static List<arce__hotel_projection__c> getHotelProjectionInfo(String recordId) {
      return  [SELECT Id, arce__account_has_analysis_id__c,arce__gf_const_proj_year_number_type__c, arce__gf_hotel_avg_daily_rate_amount__c, arce__gf_hotel_occupancy_per__c,
                    arce__gf_rev_per_avail_room_amount__c, arce__gf_htl_gs_oper_profit_amount__c, arce__gf_debt_available_funds_amount__c, arce__gf_interest_expense_amount__c,
                    arce__gf_loan_funded_amount__c, arce__gf_debt_svc_covrg_ratio_number__c, arce__gf_hotel_breakeven_occup_per__c,arce__account_has_analysis_id__r.arce__ffss_for_rating_id__r.currencyIsoCode,
                    arce__account_has_analysis_id__r.arce__ffss_for_rating_id__r.arce__magnitude_unit_type__c, CurrencyIsoCode, arce__magnitude_unit_type__c
              FROM arce__hotel_projection__c
              WHERE arce__account_has_analysis_id__c = :recordId];
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description update arce__hotel_projection__c records
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-10-21
    * @param hotelLts - List<arce__hotel_projection__c>
    * @return Arc_Gen_ServiceAndSaveResponse wrapper
    * @example updateHotelProj(hotelLts)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse updateHotelProj(List<arce__hotel_projection__c> hotelLts) {
      arce.Arc_Gen_ServiceAndSaveResponse result = new arce.Arc_Gen_ServiceAndSaveResponse();
      try {
          result.saveStatus = 'true';
          final List<Database.SaveResult> saveRes = database.update(hotelLts);
          result.saveMessage = Json.serialize(saveRes);
      } catch (Exception ex) {
          result.saveStatus = 'false';
          result.saveMessage = ex.getMessage();
      }
      return result;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Get unit an currency limit 1 related to arce__account_has_analysis_id__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Moises Martinez Dominguez
    * @Date     2020-12-03
    * @param    rid id related to arce__account_has_analysis_id__c
    * @return   arce__hotel_projection__c[] array with arce__hotel_projection__c related
    * @example  getprojection(rid)
    * */
    public static arce__hotel_projection__c[] getCurUnitprojection(Id rid) {
        return [SELECT id,arce__magnitude_unit_type__c,CurrencyIsoCode
                FROM arce__hotel_projection__c
                WHERE arce__account_has_analysis_id__c = :rid LIMIT 1];
    }
}