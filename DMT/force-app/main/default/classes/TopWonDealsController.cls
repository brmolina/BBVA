/*
*@author Global Desktop
*@description Controlador para topWonDealsComponent y TopWonDealsWrapper
*/
public with sharing class TopWonDealsController {

  /*
  * @author Global Desktop
  * @description Recupera los Top Won Deal (del objeto Franchise) relacionados al grupo
  */
  @auraEnabled
  public static String getTopWonDeals(String tableSize, String accId, String timeParam) {

    String tenorParam;
    if(timeParam == '6months') {//NOSONAR
      tenorParam = '6M';
    } else if (timeParam == '3months') {//NOSONAR
      tenorParam = '3M';
    } else if (timeParam == '1month') {//NOSONAR
      tenorParam = '1M';
    } else if(timeParam == 'All') {//NOSONAR
      tenorParam = 'All';
    } else {
      tenorParam = '6M';
    }

      List<DES_TopWonDeals__c> dealsList = new List<DES_TopWonDeals__c>();
    if(tenorParam != 'All') {
            dealsList = [SELECT id, participant_id__c, participant_id__r.Name, year_month_day_date__c,
                            solution_category_id__c, convertCurrency(franch_oper_rslt_amount__c), analytics_operation_id__c,
                            business_area_desc__c, franchise_room_table_id__c, franchise_table_desc__c, platform_application_id__c
                            FROM DES_TopWonDeals__c
                            WHERE participant_id__c = :accId
                            AND tenor_id__c = :tenorParam
                            ORDER BY franch_oper_rslt_amount__c desc];
        } else {
            dealsList = [SELECT id, participant_id__c, participant_id__r.Name, year_month_day_date__c,
                            solution_category_id__c, convertCurrency(franch_oper_rslt_amount__c), analytics_operation_id__c,
                            business_area_desc__c, franchise_room_table_id__c, franchise_table_desc__c, platform_application_id__c
                            FROM DES_TopWonDeals__c
                            WHERE participant_id__c = :accId
                            ORDER BY franch_oper_rslt_amount__c desc];
        }                 

    final Integer dealsNumber = dealsList.size();

      final List<wrapperClass> listWrapperClass = new List<wrapperClass>();
      for(DES_TopWonDeals__c iDeals :dealsList) {
        listWrapperClass.add(new wrapperClass(iDeals, dealsNumber));
      }

      Integer tSize;
      if(tableSize != null) {
        tSize = Integer.valueOf(tableSize);
      }
      if(tSize != null) {
        List<wrapperClass> listaWrapperAux;
    listaWrapperAux = new List<wrapperClass>();
          Integer regTable = tSize;
          if(tSize > listWrapperClass.size()) {
            regTable = listWrapperClass.size();
          }
          for(Integer cn = 0; cn < regTable ; cn++) {
            if(!listWrapperClass.isEmpty() && listWrapperClass.get(cn) != null) {
              listaWrapperAux.add(listWrapperClass.get(cn));
            }
          }
          return JSON.serialize(listaWrapperAux);//NOSONAR
      } else {
        return JSON.serialize(listWrapperClass);
      }
  }

  /*
  * @author Global Desktop
  * @description Recupera el numero de Top Won Deal (del objeto Franchise) relacionados al grupo
  */
  @auraEnabled
  public static Integer getNumberDeals(String accId) {
    return [SELECT count() FROM DES_TopWonDeals__c
                            WHERE participant_id__c = :accId];

  }

  /**
    * @author Global Desktop
    * @description clase para construir lista wrapper
    */
    public class wrapperClass {

      /**
      * @author Global Desktop
      * @description Variables de la clase wrapper
      */
      private String clientName; //NOSONAR
      private String clientRed; //NOSONAR
      private Date dateDeal; //NOSONAR
      private Decimal franchise; //NOSONAR
      private String relProduct; //NOSONAR
      private String isoCode; //NOSONAR
      private Integer listSize; //NOSONAR
      private String idOperation; //NOSONAR
      private String areaName; //NOSONAR
      private String roomFranchise; //NOSONAR
      private String deskFranchise; //NOSONAR
    private String appOperation; //NOSONAR

    /**
    * @author Global Desktop
    * @description Construye lista wrapper
    */
    public wrapperClass(DES_TopWonDeals__c iDeal, Integer nDeals) {
      this.clientName = iDeal.participant_id__r.Name;
      this.clientRed = '/lightning/r/Account/' + iDeal.participant_id__c + '/view';
      this.dateDeal = iDeal.year_month_day_date__c;
      this.franchise = iDeal.franch_oper_rslt_amount__c;
      //this.franchise = String.valueOf(iDeal.franch_oper_rslt_amount__c);
      this.relProduct = iDeal.solution_category_id__c;
      //this.isoCode = iDeal.CurrencyIsoCode;
      this.listSize = nDeals;
      this.idOperation = iDeal.analytics_operation_id__c;
      this.areaName = iDeal.business_area_desc__c;
      this.roomFranchise = iDeal.franchise_room_table_id__c;
      this.deskFranchise = iDeal.franchise_table_desc__c;
    this.appOperation = iDeal.platform_application_id__c;

    }

    }

}