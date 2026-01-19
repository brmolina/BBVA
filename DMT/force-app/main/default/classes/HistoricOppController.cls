/*
* Controller of HistoricOppAccount and HistoricOppProductDetail cmps
*/
public with sharing class HistoricOppController {
  /**
  * SINGLETON PATTERN
  */
  private static HistoricOppController instance;

  /**
  * Constructor
  */
  private HistoricOppController() {
  }

  /**
  * getInstance
  */
  public static HistoricOppController getInstance() {//NOSONAR
    if (instance == null) {
      instance = new HistoricOppController();
    }
    return instance;
  }

  /**
  * Devuelve fields de un objeto
  */
  @AuraEnabled
  public static String getDataOpp(String optyId,String accId) {//NOSONAR
  	final Opportunity__b opp = getOppByIdAndAccount(optyId,accId);
    final List<SObject> lista = new List<SObject>();
    lista.add(opp);
    return getData(lista);
  }

  /**
  * Devuelve fields de un objeto
  */
  @AuraEnabled
  public static String getProduct(String optyId,String optLineId) {
    final OpportunityLineItem__b oppLineItem = getOppLineItemByIdAndOpp(optyId,optLineId);
    final List<SObject> lista = new List<SObject>();
    lista.add(oppLineItem);
    return getData(lista);
  }

  /**
  * Devuelve fields de un objeto
  */
  public static String getData(List<SObject> arrayObj) {//NOSONAR
    String allObjJSON = '{"Items": [';
    for( SObject sObj : arrayObj ) {
      if(!allObjJSON.equalsIgnoreCase('{"Items": [')) {
        allObjJSON += ', ';
      }
      final DescribeSObjectResult describeResult = sObj.getSObjectType().getDescribe();
      final Map<String, Schema.SObjectField> desribedFields = describeResult.fields.getMap();
      String objJSON = '[';
      for( String fieldName :  desribedFields.keySet() ) {
        final Schema.SObjectField field = desribedFields.get( fieldName );
				final Schema.DescribeFieldResult fDesc = field.getDescribe();
        try {
          if(sObj.get(fDesc.getName()) != null) {
            if(!objJSON.equalsIgnoreCase('[') ) {
              objJSON += ', ';
            }
            objJSON += '{';
            objJSON += '"name":"'+fDesc.getName() + '", ' + '"label" : "' + fDesc.getLabel() + '","value":"' + String.valueOf(sObj.get(fDesc.getName())).replaceAll('"','').replaceAll('\n','').replaceAll('\r','') + '"';
            objJSON += '}';
          }
        } catch (SObjectException e) {
          System.debug('Info: Campo no cargado en la query ' + fDesc.getName() );
        }
      }
      objJSON += ']';
      allObjJSON += objJSON;
    }
    allObjJSON += ']}';
    System.debug( ' JSON STRING : ' + allObjJSON );
    return allObjJSON;
  }
  /**
  * Devuelve una lista con opportunity line items por idopp y opp line item
  */
  @AuraEnabled
  public static OpportunityLineItem__b getOppLineItemByIdAndOpp(String optyId,String optLineId  ) {//NOSONAR
    try {
      final List <OpportunityLineItem__b> lstOfOpportunity = [SELECT DES_Funding_Transfer_Price__c, DES_Price_Percent__c, DES_Risk_Fee_Next_12_Months__c, DES_Structured_Opportunity__c, DES_Underwriting_fee__c, DES_Volume_in_Amounts__c,
                                                              aa_committee_approval_ind_type__c, bbva_est_incm_next_12m_amount__c, bbva_prtcp_tranche_amount__c, benefit_sharing_agree_ind_type__c,
                                                              clan_syndicated_loan_id__c, classification_cib_banker_type__c, country_name__c, cplc_cmtee_approval_ind_type__c, credit_drawn_next_12m_per__c, credit_undrawn_next_12m_per__c,
                                                              current_value_portfolio_amount__c, customer_cib_ind_type__c, customer_guarantor_entity_id__c, deal_guarantee_desc__c, deal_total_amount__c, deferred_fee_amount__c,
                                                              deferred_fee_per__c, entity_role_type__c, export_credit_agency_name__c, fee_final_current_year_amount__c, fee_next_12m_amount__c, funding_cost_per__c,
                                                              gf_comt_not_settled_amount__c, gf_current_be_sold_mk_amount__c, gf_est_fee_cust_sycr_bp_amount__c, gf_mk_curr_rsk_synd_amount__c, gf_opportunity_end_year_id__c,
                                                              gf_oppy_credit_agree_sign_date__c, gf_oppy_undwr_approval_year_id__c, gf_own_undwr_mk_rsk_fee_amount__c, gf_product_conn_impl_end_date__c, gf_product_conn_impl_ind_type__c,
                                                              gf_settlement_date__c, gf_tot_sold_order_fees_amount__c, gf_total_net_fees_oppy_amount__c, gf_total_nominal_sold_amount__c, gf_total_oppy_fees_cust_amount__c,
                                                              gf_total_sold_ord_stl_amount__c, gf_upfront_undwr_fees_amount__c, insurance_company_name__c, loan_export_cr_agncy_cntrb_per__c, loan_purpose_desc__c, loan_tenor_month_desc__c,
                                                              multi_tranche_type__c, no_deferred_fee_amount__c, no_deferred_fee_per__c, opening_fee_amount__c, opening_fee_per__c, opportunity_currency_id__c, opportunity_nbc_comments_desc__c,
                                                              opportunity_nbc_recm_date__c, opportunity_nbc_recm_ind_type__c, opportunity_risk_name__c, opportunity_sold_prdt_number__c, oppy_asset_level_1_name__c, oppy_asset_level_2_name__c,
                                                              oppy_asset_level_3_name__c, oppy_nbc_rcmndn_maturity_date__c, oppy_pricing_cmtee_aprvl_date__c, oppy_pricing_cmtee_rspse_type__c, oppy_product_ctrct_comt_date__c,
                                                              oppy_product_offer_area_name__c, oppy_substage_mandate_date__c, oppy_target_country_name__c, oppy_target_industry_name__c, oppy_undwr_cmtee_approval_date__c,
                                                              oppy_undwr_cmtee_rspse_type__c, periodic_fee_amount__c, pre_endrs_fee_next_12m_amount__c, pre_gross_margin_next_12m_per__c, pre_net_margin_next_12m_amount__c,
                                                              pre_net_margin_next_12m_per__c, pre_oppy_revenue_next_12m_amount__c, product_scope_type__c, proposal_requested_ind_type__c, regional_area_name__c, retainer_fee_12m_amount__c,
                                                              risk_committee_approval_date__c, risk_committee_aprvl_ind_type__c, risk_committee_comments_desc__c, risk_effective_date__c, solution_classification_desc__c,
                                                              solution_name_path_desc__c, syndicated_loan_drawn_amount__c, underwriting_agreement_type__c, underwriting_amount__c, undrawn_fee_next_12m_amount__c, undrawn_fee_next_12m_per__c,
                                                              undrw_fee_curr_year_amount__c, unit_price_with_tax_amount__c, DES_Product_Family__c  from OpportunityLineItem__b  WHERE OpportunityId__c=:optyId and OpportunityLineItemId__c=:optLineId ];
      OpportunityLineItem__b opp;
      opp = new OpportunityLineItem__b();
      if(!lstOfOpportunity.isEmpty()) {
        opp = lstOfOpportunity.get(0);
      }
      return opp;
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }

  /**
  * Devuelve una opportunity por id opp y id account
  */
  @AuraEnabled
  public static Opportunity__b getOppByIdAndAccount(String optyId,String accId  ) {//NOSONAR
    try {
      final List <Opportunity__b> lstOfOpportunity = [SELECT DES_Client_Text__c, Name__c, CloseDate__c, CurrencyIsoCode__c, DES_Description_rich__c,
            DES_Countries__c, DES_Reg_W_Affiliate_Only_BBVA_Compass__c, gf_comm_offer_moppy_ind_type__c, DES_Cross_border__c, disclosure_info_type__c, pre_oppy_revenue_next_12m_amount__c,
            Committee_id__c, gf_opportunity_nbc_name__c, DES_Booking_Geography__c, DES_NBC_Region__c, DES_Comments__c, gf_oppy_virtual_cmtee_ind_type__c, DES_Date_Won_Lost__c,
            sustainable_finance_ind_type__c, StageName__c, DES_Expected_Probability__c, DES_Reasons_Lost__c, DES_Description_reason_for_lost_deal__c, Owner__c, Opportunity_Members__c FROM Opportunity__b WHERE AccountId__c = :accId and Id__c = :optyId ];
      Opportunity__b opp;
      opp = new Opportunity__b();
      if(!lstOfOpportunity.isEmpty()) {
          opp = lstOfOpportunity.get(0);
      }
      return opp;
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }
}