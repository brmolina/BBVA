/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_Contracts_Appraisals_Locator
  * @Author   Juan Manuel Perez Ortiz juanmanuel.perez.ortiz.contractor@bbva.com
  * @Date     Created: 2020-11-10
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Locator class for arce__contracts_and_appraisals__c
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-11-10 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Class Creation
  * |2020-11-13 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Modified record filter name
  * |2020-12-02 moises.martinez.dominguez.contractor@bbva.com
  *             Add method query all records table contract and appraisals
  **/
  @SuppressWarnings('sf:AvoidSoqlWithNegativeLogic')
  public without sharing class Arc_Gen_Contracts_Appraisals_Locator {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     2020-11-10
    * @param void
    * @return void
    * @example Arc_Gen_Contracts_Appraisals_Locator data = new Arc_Gen_Contracts_Appraisals_Locator()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_Contracts_Appraisals_Locator() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description get tables records
    * ----------------------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     2020-11-10
    * @param recordId - id of the account has analysis object
    * @return List<arce__contracts_and_appraisals__c>
    * @example getContractsAppraisalsRecords(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static List<arce__contracts_and_appraisals__c> getContractsAppraisalsRecords(String recordId) {
      return  [SELECT Id, CurrencyIsoCode, arce__magnitude_unit_type__c
              FROM arce__contracts_and_appraisals__c
              WHERE arce__account_has_analysis_id__c = :recordId AND arce__gf_hotel_name__c = 'Dummy Hotel Currency and Units'];
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description update arce__contracts_and_appraisals__c records
    * ----------------------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     2020-11-10
    * @param appraisalsLst - List<arce__contracts_and_appraisals__c>
    * @return arce.Arc_Gen_ServiceAndSaveResponse  wrapper
    * @example updateContractsAppraisals(appraisalsLst)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse  updateContractsAppraisals(List<arce__contracts_and_appraisals__c> appraisalsLst) {
      arce.Arc_Gen_ServiceAndSaveResponse  result = new arce.Arc_Gen_ServiceAndSaveResponse ();
      try {
          result.saveStatus = 'true';
          final List<Database.SaveResult> saveRes = database.update(appraisalsLst);
          result.saveMessage = Json.serialize(saveRes);
      } catch (Exception ex) {
          result.saveStatus = 'false';
          result.saveMessage = ex.getMessage();
      }
      return result;
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Get arce__contracts_and_appraisals__c related to arce__account_has_analysis_id__c
    * -----------------------------------------------------------------------------------------------------
    * @Author   Moises Martinez Dominguez
    * @Date     2020-12-02
    * @param    rid id related to arce__account_has_analysis_id__c
    * @return   arce__contracts_and_appraisals__c[] array with arce__contracts_and_appraisals__c related
    * @example  getAnalysisDate(rid)
    * */
    public static arce__contracts_and_appraisals__c[] getAllContractsAppraisals(Id rid) {
        return [SELECT id,arce__gf_hotel_name__c,arce__appraisal_amount__c,arce__last_assessed_date__c,
                arce__gf_htl_ownshp_ctrct_dur_number__c,arce__gf_current_expiration_date__c,
                arce__gf_hotel_contract_type_name__c
                FROM arce__contracts_and_appraisals__c
                WHERE arce__account_has_analysis_id__c = :rid AND arce__gf_hotel_name__c != 'Dummy Hotel Currency and Units'];
    }
}