/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Analysis_Date_Locator
  * @Author   moises.martinez.dominguez.contractor@bbva.com
  * @Date     Created: 2020-11-11
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Locator class for arce__hotel_analysis_date_period__c
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-11-11 moises.martinez.dominguez.contractor@bbva.com
  *             Class Creation
  * |2020-11-30 moises.martinez.dominguez.contractor@bbva.com
  *             change query name table date
  * |2020-12-02 moises.martinez.dominguez.contractor@bbva.com
  *             Add method query all records table date
  **/
  @SuppressWarnings('sf:AvoidSoqlWithNegativeLogic')
  public without sharing class Arc_Gen_Analysis_Date_Locator {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-11
    * @param void
    * @return void
    * @example Arc_Gen_Analysis_Date_Locator data = new Arc_Gen_Analysis_Date_Locator()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Analysis_Date_Locator() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description get tables records
    * ----------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-11
    * @param recordId - id of the account has analysis object
    * @return List<arce__hotel_analysis_date_period__c>
    * @example getAnalysisDateRecords(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static List<arce__hotel_analysis_date_period__c> getAnalysisDateRecords(String recordId) {
      return  [SELECT Id, CurrencyIsoCode, arce__magnitude_unit_type__c
              FROM arce__hotel_analysis_date_period__c
              WHERE arce__account_has_analysis_id__c = :recordId AND Name = 'Dummy Hotel analysisDate Hotel Currency'];
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description update arce__hotel_analysis_date_period__c records
    * ----------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-11
    * @param analysisDateLst - List<arce__hotel_analysis_date_period__c>
    * @return arce.Arc_Gen_ServiceAndSaveResponse wrapper
    * @example updateAnalysisDate(analysisDateLst)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse updateAnalysisDate(List<arce__hotel_analysis_date_period__c> analysisDateLst) {
      arce.Arc_Gen_ServiceAndSaveResponse result = new arce.Arc_Gen_ServiceAndSaveResponse();
      try {
          result.saveStatus = 'true';
          final List<Database.SaveResult> saveRes = database.update(analysisDateLst);
          result.saveMessage = Json.serialize(saveRes);
      } catch (Exception ex) {
          result.saveStatus = 'false';
          result.saveMessage = ex.getMessage();
      }
      return result;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Get arce__hotel_analysis_date_period__c related to arce__account_has_analysis_id__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Moises Martinez Dominguez
    * @Date     2020-12-02
    * @param    rid id related to arce__account_has_analysis_id__c
    * @return   arce__hotel_analysis_date_period__c[] array with arce__hotel_analysis_date_period__c related
    * @example  getAnalysisDate(rid)
    * */
    public static arce__hotel_analysis_date_period__c[] getAllAnalysisDate(Id rid) {
        return [SELECT id,arce__gf_period_start_date__c,arce__gf_period_end_date__c,arce__gf_hotel_occupancy_per__c,
                arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c
                FROM arce__hotel_analysis_date_period__c
                WHERE arce__account_has_analysis_id__c = :rid AND Name != 'Dummy Hotel analysisDate Hotel Currency'];
    }
}