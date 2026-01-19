/** ********************************************************************************
* @author       JSS
* @date         02/06/2020
* @description  Controlador del componente lighning PRC_PriceForm
* @Revision
********************************************************************************* */
@SuppressWarnings('sf:AvoidGetSetMethods,sf:AvoidUsingTestIsRunningTest')
public with sharing class PRC_PriceForm_CONTROLLER {

  /**
  * @author       JCT
  * @description  Método que recupera la info de Pricing Detail del objeto de Salesforce
  */
  @AuraEnabled
  public static PRC_Pricing_Detail__c getPricingDetail(String oppId) {
	System.debug('>>>>>>>>>>>>>>>> getPricingDetail. oppId: ' + oppId );

  PRC_Pricing_Detail__c resultado;
    List<PRC_Pricing_Detail__c> pdList = [SELECT Id, gf_pricing_risk_product_name__c, gf_pricing_risk_product_id__c, currency_id__c, PRC_Opportunity__r.CurrencyIsoCode,
                                         rating_scale_type__c, PRC_Opportunity__r.Account.DES_Rating_Int__c, CurrencyIsoCode,
                                         gf_cust_group_rating_type__c, PRC_Opportunity__r.Account.DES_Main_Parent__c, PRC_Opportunity__r.Account.DES_Main_Parent__r.DES_Rating_Int__c,
                                         gf_ope_booking_entity_name__c, PRC_Opportunity__r.DES_Booking_Geography__c,
                                         PRC_Opportunity__r.Account.Id,business_area_desc__c,
                                         gf_scope_type__c, economic_activity_sector_desc__c, branch_name__c, agency_rating_value_type__c, gf_ope_agency_rating_type__c,
                                         gf_financing_type_name__c, gf_operation_term_number__c, gf_funding_curve_type__c, amortization_desc__c, payment_type__c, frequency_type__c,
                                         gf_on_balance_funding_per__c, gf_off_balance_funding_per__c, gf_on_bal_mrgn_gen_amount__c, gf_off_bal_mrgn_gen_amount__c,
                                         gf_ope_on_balance_margin_per__c, gf_ope_off_balance_margin_per__c, transaction_country_name__c
                                         FROM PRC_Pricing_Detail__c WHERE PRC_Opportunity__c = :oppId LIMIT 1];
    if (!pdList.isEmpty() && pdList.size() == 1) {
      resultado = pdList.get(0);
    }
    return resultado;
  }

  /**
  * @description
  * @author Global Desktop | 03-03-2021
  * @return String
  **/
  @AuraEnabled
  public static String getPickList() {
    final PRC_PPL_Response respObject = new PRC_PPL_Response();

    final Map<String,String> jsonInputMap = new Map<String,String>();
    jsonInputMap.put('whole-request','test');
    final HttpResponse response =  Test.isRunningTest() ? PRC_MockHttpResponseGenerator.respond_WsPicklists() : iaso.GBL_Integration_GenericService.invoke('PRCBankingProposal',jsonInputMap);
    respObject.body=response.getBody();
    respObject.status =response.getStatusCode();
		respObject.wsErrorMsg =response.getStatus();
    return JSON.serialize(respObject);
  }

  /**
  * @description
  * @author Global Desktop | 03-03-2021
  * @param booking
  * @return PRC_bookingRating__mdt
  **/
  @AuraEnabled
  public static PRC_bookingRating__mdt getPickRating(string booking) {
    PRC_bookingRating__mdt[] rating = [SELECT PRC_taxRate__c,PRC_costToIncome__c,Label FROM PRC_bookingRating__mdt WHERE Label =:booking limit 1];
    if(rating.size() == 0) {
      rating = [SELECT PRC_taxRate__c,PRC_costToIncome__c,Label FROM PRC_bookingRating__mdt WHERE PRC_oppBook__c =:booking limit 1];
      if(rating.size() == 0) {
      	rating = [SELECT PRC_taxRate__c,PRC_costToIncome__c FROM PRC_bookingRating__mdt WHERE Label ='OTHER' limit 1];
      }
    }
    return rating.size() == 0 ? null : rating[0];
  }
}