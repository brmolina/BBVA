/*
* @author GlobalDesktop
+ @description Batch to move product to big object
*/
public without sharing class OpportunityLineBigObject implements Database.Batchable<Sobject>, Database.Stateful {
  /* Query */
  private String fieldsToSave = ''; //NOSONAR
  /* Query */
  private String pQuery = ''; //NOSONAR
  /* Query */
  private Set<Id> stoppsIds; //NOSONAR

  /*
  * Constructor
  */
  public OpportunityLineBigObject(Set<Id> oppsIds) {
    this.stoppsIds = oppsIds;
    this.fieldsToSave += 'gf_total_nominal_sold_amount__c, undrawn_fee_next_12m_amount__c, undrawn_fee_next_12m_per__c, aa_committee_approval_ind_type__c, country_name__c, ';
    this.fieldsToSave += 'oppy_asset_level_1_name__c, oppy_asset_level_2_name__c, oppy_asset_level_3_name__c, gf_upfront_undwr_fees_amount__c, credit_drawn_next_12m_per__c, credit_undrawn_next_12m_per__c, ';
    this.fieldsToSave += 'bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c, gf_total_net_fees_oppy_amount__c, entity_role_type__c, classification_cib_banker_type__c, product_scope_type__c, ';
    this.fieldsToSave += 'customer_cib_ind_type__c, clan_syndicated_loan_id__c, undrw_fee_curr_year_amount__c, cplc_cmtee_approval_ind_type__c, funding_cost_per__c, opportunity_currency_id__c, gf_comt_not_settled_amount__c, ';
    this.fieldsToSave += 'deal_total_amount__c, no_deferred_fee_per__c, no_deferred_fee_amount__c, OpportunityId, pre_oppy_revenue_next_12m_amount__c, DES_Price_Percent__c, unit_price_with_tax_amount__c, ';
    this.fieldsToSave += 'oppy_pricing_cmtee_aprvl_date__c, oppy_pricing_cmtee_rspse_type__c, insurance_company_name__c, solution_classification_desc__c, loan_purpose_desc__c, gf_mk_curr_rsk_synd_amount__c, ';
    this.fieldsToSave += 'periodic_fee_amount__c, regional_area_name__c, retainer_fee_12m_amount__c, proposal_requested_ind_type__c, risk_committee_approval_date__c, risk_effective_date__c, risk_committee_aprvl_ind_type__c, ';
    this.fieldsToSave += 'risk_committee_comments_desc__c, pre_endrs_fee_next_12m_amount__c, DES_Risk_Fee_Next_12_Months__c, opportunity_risk_name__c, gf_oppy_undwr_approval_year_id__c, deal_guarantee_desc__c, ';
    this.fieldsToSave += 'oppy_product_ctrct_comt_date__c, gf_settlement_date__c, DES_Structured_Opportunity__c, solution_name_path_desc__c, oppy_target_country_name__c, oppy_target_industry_name__c, loan_tenor_month_desc__c, ';
    this.fieldsToSave += 'gf_current_be_sold_mk_amount__c, gf_tot_sold_order_fees_amount__c, gf_total_sold_ord_stl_amount__c, opportunity_sold_prdt_number__c, underwriting_agreement_type__c, underwriting_amount__c, ';
    this.fieldsToSave += 'oppy_undwr_cmtee_approval_date__c, oppy_undwr_cmtee_rspse_type__c, DES_Underwriting_fee__c, gf_opportunity_end_year_id__c, opening_fee_amount__c, opening_fee_per__c, gf_own_undwr_mk_rsk_fee_amount__c, ';
    this.fieldsToSave += 'current_value_portfolio_amount__c, DES_Volume_in_Amounts__c, deferred_fee_per__c, deferred_fee_amount__c, oppy_product_offer_area_name__c, loan_export_cr_agncy_cntrb_per__c, export_credit_agency_name__c, ';
    this.fieldsToSave += 'gf_est_fee_cust_sycr_bp_amount__c, fee_next_12m_amount__c, fee_final_current_year_amount__c, gf_oppy_credit_agree_sign_date__c, DES_Funding_Transfer_Price__c, gf_total_oppy_fees_cust_amount__c, ';
    this.fieldsToSave += 'pre_gross_margin_next_12m_per__c, customer_guarantor_entity_id__c, gf_product_conn_impl_ind_type__c, gf_product_conn_impl_end_date__c, bbva_est_incm_next_12m_amount__c, ';
    this.fieldsToSave += 'oppy_substage_mandate_date__c, pre_net_margin_next_12m_amount__c, pre_net_margin_next_12m_per__c, benefit_sharing_agree_ind_type__c, oppy_nbc_rcmndn_maturity_date__c, multi_tranche_type__c, ';
    this.fieldsToSave += 'opportunity_nbc_recm_ind_type__c, opportunity_nbc_recm_date__c, opportunity_nbc_comments_desc__c, DES_Product_Family__c';
    this.pQuery = 'SELECT Id, '+ this.fieldsToSave + ' FROM OpportunityLineItem ' + (Test.isRunningTest() ? 'LIMIT 1' : 'WHERE OpportunityId IN :oppsIds'); //NOSONAR
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    system.debug('Query: ' + pQuery.substringAfterLast('WHERE'));
    final Set<Id> oppsIds = this.stoppsIds;
    system.debug('oppsIds: ' + oppsIds);
    return Database.getQueryLocator(pQuery);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch,List<OpportunityLineItem> scope) { //NOSONAR
    final List<OpportunityLineItem__b> bigOlis = new List<OpportunityLineItem__b>();
    for(OpportunityLineItem oli : scope) {
      final OpportunityLineItem__b bigOli = new OpportunityLineItem__b();
      bigOli.gf_total_nominal_sold_amount__c = oli.gf_total_nominal_sold_amount__c;
      bigOli.undrawn_fee_next_12m_amount__c = oli.undrawn_fee_next_12m_amount__c;
      bigOli.undrawn_fee_next_12m_per__c = oli.undrawn_fee_next_12m_per__c;
      bigOli.aa_committee_approval_ind_type__c = isBoolean(oli.aa_committee_approval_ind_type__c);
      bigOli.country_name__c = oli.country_name__c;
      bigOli.oppy_asset_level_1_name__c = oli.oppy_asset_level_1_name__c;
      bigOli.oppy_asset_level_2_name__c = oli.oppy_asset_level_2_name__c;
      bigOli.oppy_asset_level_3_name__c = oli.oppy_asset_level_3_name__c;
      bigOli.gf_upfront_undwr_fees_amount__c = oli.gf_upfront_undwr_fees_amount__c;
      bigOli.credit_drawn_next_12m_per__c = oli.credit_drawn_next_12m_per__c;
      bigOli.credit_undrawn_next_12m_per__c = oli.credit_undrawn_next_12m_per__c;
      bigOli.bbva_prtcp_tranche_amount__c = oli.bbva_prtcp_tranche_amount__c;
      bigOli.syndicated_loan_drawn_amount__c = oli.syndicated_loan_drawn_amount__c;
      bigOli.gf_total_net_fees_oppy_amount__c = oli.gf_total_net_fees_oppy_amount__c;
      bigOli.entity_role_type__c = oli.entity_role_type__c;
      bigOli.classification_cib_banker_type__c = oli.classification_cib_banker_type__c;
      bigOli.product_scope_type__c = oli.product_scope_type__c;
      bigOli.customer_cib_ind_type__c = oli.customer_cib_ind_type__c;
      bigOli.clan_syndicated_loan_id__c = oli.clan_syndicated_loan_id__c;
      bigOli.undrw_fee_curr_year_amount__c = oli.undrw_fee_curr_year_amount__c;
      bigOli.cplc_cmtee_approval_ind_type__c = isBoolean(oli.cplc_cmtee_approval_ind_type__c);
      bigOli.funding_cost_per__c = oli.funding_cost_per__c;
      bigOli.opportunity_currency_id__c = oli.opportunity_currency_id__c;
      bigOli.gf_comt_not_settled_amount__c = oli.gf_comt_not_settled_amount__c;
      bigOli.deal_total_amount__c = oli.deal_total_amount__c;
      bigOli.deferred_fee_per__c = oli.deferred_fee_per__c;
      bigOli.deferred_fee_amount__c = oli.deferred_fee_amount__c;
      bigOli.oppy_product_offer_area_name__c = oli.oppy_product_offer_area_name__c;
      bigOli.loan_export_cr_agncy_cntrb_per__c = oli.loan_export_cr_agncy_cntrb_per__c;
      bigOli.export_credit_agency_name__c = oli.export_credit_agency_name__c;
      bigOli.gf_est_fee_cust_sycr_bp_amount__c = oli.gf_est_fee_cust_sycr_bp_amount__c;
      bigOli.fee_next_12m_amount__c = oli.fee_next_12m_amount__c;
      bigOli.fee_final_current_year_amount__c = oli.fee_final_current_year_amount__c;
      bigOli.gf_oppy_credit_agree_sign_date__c = oli.gf_oppy_credit_agree_sign_date__c;
      bigOli.DES_Funding_Transfer_Price__c = oli.DES_Funding_Transfer_Price__c;
      bigOli.gf_total_oppy_fees_cust_amount__c = oli.gf_total_oppy_fees_cust_amount__c;
      bigOli.pre_gross_margin_next_12m_per__c = oli.pre_gross_margin_next_12m_per__c;
      bigOli.customer_guarantor_entity_id__c = oli.customer_guarantor_entity_id__c;
      bigOli.gf_product_conn_impl_ind_type__c = isBoolean(oli.gf_product_conn_impl_ind_type__c);
      bigOli.gf_product_conn_impl_end_date__c = oli.gf_product_conn_impl_end_date__c;
      bigOli.bbva_est_incm_next_12m_amount__c = oli.bbva_est_incm_next_12m_amount__c;
      bigOli.oppy_substage_mandate_date__c = oli.oppy_substage_mandate_date__c;
      bigOli.pre_net_margin_next_12m_amount__c = oli.pre_net_margin_next_12m_amount__c;
      bigOli.pre_net_margin_next_12m_per__c = oli.pre_net_margin_next_12m_per__c;
      bigOli.benefit_sharing_agree_ind_type__c = isBoolean(oli.benefit_sharing_agree_ind_type__c);
      bigOli.oppy_nbc_rcmndn_maturity_date__c = oli.oppy_nbc_rcmndn_maturity_date__c;
      bigOli.multi_tranche_type__c = oli.multi_tranche_type__c;
      bigOli.opportunity_nbc_recm_ind_type__c = oli.opportunity_nbc_recm_ind_type__c;
      bigOli.opportunity_nbc_recm_date__c = oli.opportunity_nbc_recm_date__c;
      bigOli.opportunity_nbc_comments_desc__c = oli.opportunity_nbc_comments_desc__c;
      bigOli.no_deferred_fee_per__c = oli.no_deferred_fee_per__c;
      bigOli.no_deferred_fee_amount__c = oli.no_deferred_fee_amount__c;
      bigOli.OpportunityId__c = oli.OpportunityId;
      bigOli.OpportunityLineItemId__c = oli.Id;
      bigOli.pre_oppy_revenue_next_12m_amount__c = oli.pre_oppy_revenue_next_12m_amount__c;
      bigOli.DES_Price_Percent__c = oli.DES_Price_Percent__c;
      bigOli.unit_price_with_tax_amount__c = oli.unit_price_with_tax_amount__c;
      bigOli.oppy_pricing_cmtee_aprvl_date__c = oli.oppy_pricing_cmtee_aprvl_date__c;
      bigOli.oppy_pricing_cmtee_rspse_type__c = oli.oppy_pricing_cmtee_rspse_type__c;
      bigOli.insurance_company_name__c = oli.insurance_company_name__c;
      bigOli.solution_classification_desc__c = oli.solution_classification_desc__c;
      bigOli.loan_purpose_desc__c = oli.loan_purpose_desc__c;
      bigOli.gf_mk_curr_rsk_synd_amount__c = oli.gf_mk_curr_rsk_synd_amount__c;
      bigOli.periodic_fee_amount__c = oli.periodic_fee_amount__c;
      bigOli.regional_area_name__c = oli.regional_area_name__c;
      bigOli.retainer_fee_12m_amount__c = oli.retainer_fee_12m_amount__c;
      bigOli.proposal_requested_ind_type__c = oli.proposal_requested_ind_type__c;
      bigOli.risk_committee_approval_date__c = oli.risk_committee_approval_date__c;
      bigOli.risk_effective_date__c = oli.risk_effective_date__c;
      bigOli.risk_committee_aprvl_ind_type__c = oli.risk_committee_aprvl_ind_type__c;
      bigOli.risk_committee_comments_desc__c = oli.risk_committee_comments_desc__c;
      bigOli.pre_endrs_fee_next_12m_amount__c = oli.pre_endrs_fee_next_12m_amount__c;
      bigOli.DES_Risk_Fee_Next_12_Months__c = oli.DES_Risk_Fee_Next_12_Months__c;
      bigOli.opportunity_risk_name__c = oli.opportunity_risk_name__c;
      bigOli.gf_oppy_undwr_approval_year_id__c = oli.gf_oppy_undwr_approval_year_id__c;
      bigOli.deal_guarantee_desc__c = oli.deal_guarantee_desc__c;
      bigOli.oppy_product_ctrct_comt_date__c = oli.oppy_product_ctrct_comt_date__c;
      bigOli.gf_settlement_date__c = oli.gf_settlement_date__c;
      bigOli.DES_Structured_Opportunity__c = isBoolean(oli.DES_Structured_Opportunity__c);
      bigOli.solution_name_path_desc__c = oli.solution_name_path_desc__c;
      bigOli.oppy_target_country_name__c = oli.oppy_target_country_name__c;
      bigOli.oppy_target_industry_name__c = oli.oppy_target_industry_name__c;
      bigOli.loan_tenor_month_desc__c = oli.loan_tenor_month_desc__c;
      bigOli.gf_current_be_sold_mk_amount__c = oli.gf_current_be_sold_mk_amount__c;
      bigOli.gf_tot_sold_order_fees_amount__c = oli.gf_tot_sold_order_fees_amount__c;
      bigOli.gf_total_sold_ord_stl_amount__c = oli.gf_total_sold_ord_stl_amount__c;
      bigOli.opportunity_sold_prdt_number__c = oli.opportunity_sold_prdt_number__c;
      bigOli.underwriting_agreement_type__c = oli.underwriting_agreement_type__c;
      bigOli.underwriting_amount__c = oli.underwriting_amount__c;
      bigOli.oppy_undwr_cmtee_approval_date__c = oli.oppy_undwr_cmtee_approval_date__c;
      bigOli.oppy_undwr_cmtee_rspse_type__c = oli.oppy_undwr_cmtee_rspse_type__c;
      bigOli.DES_Underwriting_fee__c = oli.DES_Underwriting_fee__c;
      bigOli.gf_opportunity_end_year_id__c = oli.gf_opportunity_end_year_id__c;
      bigOli.opening_fee_amount__c = oli.opening_fee_amount__c;
      bigOli.opening_fee_per__c = oli.opening_fee_per__c;
      bigOli.gf_own_undwr_mk_rsk_fee_amount__c = oli.gf_own_undwr_mk_rsk_fee_amount__c;
      bigOli.current_value_portfolio_amount__c = oli.current_value_portfolio_amount__c;
      bigOli.DES_Volume_in_Amounts__c = oli.DES_Volume_in_Amounts__c;
      bigOli.DES_Product_Family__c = oli.DES_Product_Family__c;
      bigOlis.add(bigOli);
    }
    if(!Test.isRunningTest()) { //NOSONAR
      database.insertImmediate(bigOlis);
    }
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    Database.executeBatch(new VisitsEventDelete(stoppsIds, 'WhatId', 'Opportunity'), 100);
  }

  /*
  * getExecuteBatchSize method
  */
  private String isBoolean(Boolean value) {
    return value ? 'true' : 'false';
  }
}