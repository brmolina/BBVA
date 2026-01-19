/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Analysis_Category_Locator
  * @Author   moises.martinez.dominguez.contractor@bbva.com
  * @Date     Created: 2020-11-12
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Locator class for arce__hotel_analysis_category__c
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-11-12 moises.martinez.dominguez.contractor@bbva.com
  *             Class Creation
  * |2020-11-30 moises.martinez.dominguez.contractor@bbva.com
  *             change query name table category
  * |2020-12-02 moises.martinez.dominguez.contractor@bbva.com
  *             Add method query all records table category
  **/
  @SuppressWarnings('sf:AvoidSoqlWithNegativeLogic')
  public without sharing class Arc_Gen_Analysis_Category_Locator {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-12
    * @param void
    * @return void
    * @example Arc_Gen_Analysis_Category_Locator data = new Arc_Gen_Analysis_Category_Locator()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Analysis_Category_Locator() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description get tables records
    * ----------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-12
    * @param recordId - id of the account has analysis object
    * @return List<arce__hotel_analysis_category__c>
    * @example getCategoryRecords(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static List<arce__hotel_analysis_category__c> getCategoryRecords(String recordId) {
      return  [SELECT Id, CurrencyIsoCode, arce__magnitude_unit_type__c
              FROM arce__hotel_analysis_category__c
              WHERE arce__account_has_analysis_id__c = :recordId AND Name = 'Dummy Hotel analysisCategory Hotel Currency'];
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description update arce__hotel_analysis_category__c records
    * ----------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-11
    * @param categoryLst - List<arce__hotel_analysis_category__c>
    * @return arce.Arc_Gen_ServiceAndSaveResponse wrapper
    * @example updateAnalysisCategory(categoryLst)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse updateAnalysisCategory(List<arce__hotel_analysis_category__c> categoryLst) {
      arce.Arc_Gen_ServiceAndSaveResponse result = new arce.Arc_Gen_ServiceAndSaveResponse();
      try {
          result.saveStatus = 'true';
          final List<Database.SaveResult> saveRes = database.update(categoryLst);
          result.saveMessage = Json.serialize(saveRes);
      } catch (Exception ex) {
          result.saveStatus = 'false';
          result.saveMessage = ex.getMessage();
      }
      return result;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Get arce__hotel_analysis_category__c related to arce__account_has_analysis_id__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Moises Martinez Dominguez
    * @Date     2020-12-02
    * @param    rid id related to arce__account_has_analysis_id__c
    * @return   arce__hotel_analysis_category__c[] array with arce__hotel_analysis_category__c related
    * @example  getAnalysisDate(rid)
    * */
    public static arce__hotel_analysis_category__c[] getAllAnalysisCategory(Id rid) {
        return [SELECT id,arce__gf_hotel_category_type__c,arce__gf_hotel_occupancy_per__c,
                arce__gf_hotel_avg_daily_rate_amount__c,arce__gf_rev_per_avail_room_amount__c,
                arce__magnitude_unit_type__c,CurrencyIsoCode
                FROM arce__hotel_analysis_category__c
                WHERE arce__account_has_analysis_id__c = :rid AND Name != 'Dummy Hotel analysisCategory Hotel Currency'];
    }
}