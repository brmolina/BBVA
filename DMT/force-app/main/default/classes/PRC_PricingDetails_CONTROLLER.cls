/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 26-03-2021
 * @last modified by  : Global Desktop
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   03-03-2021   Global Desktop   Initial Version
**/
public with sharing class PRC_PricingDetails_CONTROLLER {

    /**
    * @description
    * @author Global Desktop | 03-03-2021
    * @param oppid
    * @return Opportunity
    **/
    @AuraEnabled
    public static Opportunity loadrecords(String oppid){
        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
        return [select Id,gf_amiweb_opportunity_id__c,
                (Select id, DES_Product_Family__c from OpportunityLineItems where Opportunityid = :oppid limit 1) ,
                (select Id,rating_scale_type__c,gf_cust_group_rating_type__c,gf_scope_type__c,economic_activity_sector_desc__c,branch_name__c,agency_rating_value_type__c,opportunity_currency_id__c,gf_pricing_risk_product_name__c,gf_ope_agency_rating_type__c,gf_ope_booking_entity_name__c,gf_financing_type_name__c,opportunity_start_date__c,current_expiry_date__c,transaction_country_name__c,gf_operation_term_number__c,gf_funding_curve_type__c,lgd_per__c,gf_on_balance_funding_per__c,gf_off_balance_funding_per__c,amortization_desc__c,payment_type__c,frequency_type__c,currency_id__c,gf_off_bal_mrgn_gen_amount__c,gf_ope_off_balance_margin_per__c,gf_tax_rate_per__c,gf_on_bal_mrgn_gen_amount__c,
                gf_ope_on_balance_margin_per__c,gf_cost_income_ratio_per__c,gf_non_accrual_comission_per__c,gf_accrual_per__c,comments_desc__c,gf_fdg_trd_prpsl_rar_tot_per__c,gf_on_balance_mrgn_stvy_per__c,
                gf_off_balance_mrgn_stvy_per__c,gf_eoy_fdg_trd_prpsl_rar_per__c,gf_trd_prpsl_rorc_funding_per__c,gf_eoy_fdg_trd_prpsl_rorc_per__c,gf_off_balance_total_per__c,gf_ope_ft_yr_ti_amount__c,ead_amount__c,total_nominal_amount__c,gf_trd_prpsl_avg_life_y_number__c,gf_expected_loss_amount__c,gf_economic_capital_amount__c,gf_lgd_avg_per__c,gf_expected_loss_eqv_rating_id__c,gf_tot_risk_wght_asset_amount__c,gf_rwa_reglty_thsd_amount__c from Pricing_Details__r where PRC_Opportunity__c = :oppid limit 1)
                from Opportunity where id = :oppid][0];
    }
    /**
    * @description
    * @author Global Desktop | 03-03-2021
    * @param opp
    * @param olis
    * @return Boolean
    **/
    @AuraEnabled
    public static Boolean checkvisibility(Opportunity opp,list <OpportunityLineItem> olis) {
        final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
        final Boolean resultado = pricingLogic.displayPricingSection(opp,olis);
        return resultado;
    }

  /**
  * @description
  * @author Global Desktop | 03-03-2021
  * @param mapDataMitigant
  **/
  @AuraEnabled
  public static void insertMitigant(Map<String, String> mapDataMitigant) {
    final List<Account> accs = new List<Account>([
      SELECT Id, SER_CClient__c
      FROM Account
      WHERE Id = :mapDataMitigant.get('DES_Client_Mitigant__c')
    ]);

    final Set<String> decimalFields = new Set<String>{'gf_cty_rqst_wrrnty_risk_per__c','gf_mit_rk_rqst_warranty_per__c'};
    final Set<String> dateFields = new Set<String>{'gf_end_guarantee_date__c'};
    final PRC_Mitigant__c mitigant = new PRC_Mitigant__c();
    for(String field : mapDataMitigant.keySet()) {
      if(decimalFields.contains(field) && mapDataMitigant.get(field) != null && mapDataMitigant.get(field) != '') {
        mitigant.put(field, Decimal.valueOf(mapDataMitigant.get(field)));
      } else if(dateFields.contains(field) && mapDataMitigant.get(field) != null && mapDataMitigant.get(field) != '') {
        mitigant.put(field, Date.valueOf(mapDataMitigant.get(field)));
      } else {
        mitigant.put(field, mapDataMitigant.get(field));
      }
    }

    if(!accs.isEmpty()) {
      mitigant.put('gf_providing_warranty_ent_id__c',accs.get(0).SER_CClient__c);
    }
    upsert mitigant;
  }

  /*
  * Method to get mitigant
  */
  @AuraEnabled
  public static List<PRC_Mitigant__c> getMitigants(String priceDetailId) {
    return [Select Id, gf_warranty_type__c, toLabel(gf_subwarranty_name__c) labelWarranty, gf_subwarranty_name__c, gf_providing_warranty_ent_id__c ,gf_cty_rqst_wrrnty_risk_per__c, gf_mit_rk_rqst_warranty_per__c,
    gf_expir_wrrnty_operation_name__c, toLabel(gf_expir_wrrnty_operation_name__c) labelExpiration ,gf_end_guarantee_date__c, gf_external_rating_agncy_type__c, gf_warranty_ptt_rating_type__c, gf_gtr_debtor_group_ind_type__c ,
    gf_cvr_rk_cty_wrrnty_ind_type__c, gf_oppy_mit_dif_ccy_ind_type__c, DES_Client_Mitigant__r.Name, gf_mitigating_comment_desc__c, gf_exprt_cr_eur_agncy_ind_type__c From PRC_Mitigant__c where Pricing_Detail__c = :priceDetailId];

  }

  /**
  * @description
  * @author Global Desktop | 03-03-2021
  * @param oppid
  * @return Boolean
  **/
  @AuraEnabled
  public static Boolean mitigantsVisibility(String oppid) {
    final List<AggregateResult> results = [select count(id) from PRC_Mitigant__c where Pricing_Detail__r.PRC_Opportunity__c = :oppid ];
    final Integer total = Integer.valueOf(results[0].get('expr0'));
    return total > 0;

  }

  /**
  * @description
  * @author Global Desktop | 03-03-2021
  * @param mitigantId
  * @return void
  **/
  @AuraEnabled
  public static void deleteMitigant(String mitigantId) {
    final List<PRC_Mitigant__c> mitigants = new List<PRC_Mitigant__c>([
      SELECT Id FROM PRC_Mitigant__c WHERE Id = :mitigantId
    ]);
    if(!mitigants.isEmpty()) {
      delete mitigants;
    }
  }
}