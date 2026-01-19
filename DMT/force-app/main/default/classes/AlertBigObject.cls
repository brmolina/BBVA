/**
* @author Global Desktop
*/
public with sharing class AlertBigObject implements Database.Batchable<Sobject>, Database.Stateful {

  /* Two years Date */
  //private Date twoYears = Date.newInstance(date.today().year()-2, 1, 1); //NOSONAR
  /* Se cambia para poder historificar en Big Object a los 3 años en luar de a los 2 */
  private Date threeYears = Date.newInstance(date.today().year()-3, 1, 1); //NOSONAR
  /* Query */
  private String fieldsToSave = ''; //NOSONAR
  /* Query */
  private String pQuery = ''; //NOSONAR
  /* Query */
  private Set<Id> alertsIds = new Set<Id>(); //NOSONAR

  /*
  * Constructor
  */
  public AlertBigObject() {
    this.fieldsToSave += 'Name, CurrencyIsoCode, altm__Access_to_this_alert__c, altm__Actual_drawn_cr_revolving_per__c, altm__BBVA_rejection_reason_desc__c, ';
    this.fieldsToSave += 'altm__Client_product_accepted_type__c, altm__Client_rejection_reason_desc__c, altm__Expected_drawn_cr_revolving_per__c, altm__ISIN_id__c, ';
    this.fieldsToSave += 'altm__Leveraged_Buyout_start_date__c, altm__Monitor_manager_user_id__c, altm__Origination_manager_user_id__c, altm__Others_rejection_reason_desc__c, ';
    this.fieldsToSave += 'altm__Project_name__c, altm__Rejection_reason_desc__c, altm__Repayment_capital_drawn_per__c, altm__Repayment_credit_limit_revlv_per__c, ';
    this.fieldsToSave += 'altm__Transaction_type_desc__c, altm__User_id__c, altm__alert_expiration_date__c, altm__alert_stage_type__c, altm__amortization_desc__c, ';
    this.fieldsToSave += 'altm__bbva_share_amount__c, altm__bloomberg_ticker_id__c, altm__campaign_id__c, altm__clan_syndicated_contract_id__c, ';
    this.fieldsToSave += 'altm__client_process_accepted_type__c, altm__comm_alerts_perf_actions_type__c, altm__commercial_alert_desc__c, altm__commercial_alert_end_date__c, ';
    this.fieldsToSave += 'altm__commercial_alert_id__c, altm__commercial_alert_record_type__c, altm__commercial_alert_rfq_amount__c, altm__commercial_alert_start_date__c, ';
    this.fieldsToSave += 'altm__commercial_alert_task_type__c, altm__commercial_product_type__c, altm__commercial_subalert_name__c, altm__country_id__c, ';
    this.fieldsToSave += 'altm__data_source_name__c, altm__entity_id__c, altm__execution_indicator_type__c, altm__financial_tail_month_number__c, altm__gf_alert_delay_date__c, ';
    this.fieldsToSave += 'altm__gf_last_upload_alerts_ind_type__c, altm__operation_amount__c, altm__operation_date__c, altm__opperation_amount__c, ';
    this.fieldsToSave += 'altm__origination_manager_team_id__c, altm__origl_currency_operation_amount__c, altm__owner_access_alert_id__c, altm__participant_id__c,altm__participant_id__r.Name, ';
    this.fieldsToSave += 'altm__pricing_data_desc__c, altm__primary_asset_clasification_type__c, altm__priority_alert_type__c, altm__process_discard_status_type__c, ';
    this.fieldsToSave += 'altm__repayment_date__c, altm__sector_id__c, altm__solution_category_id__c, altm__synd_loan_amortization_amount__c, altm__syndicated_contract_id__c, ';
    this.fieldsToSave += 'altm__syndicated_loan_committed_amount__c, altm__syndicated_loan_drawn_amount__c, altm__syndicated_loan_total_amount__c, ';
    this.fieldsToSave += 'altm__syndicated_loan_undrawn_amount__c, altm__syndicated_tranche_type__c, altm__total_transaction_number__c, altm__transaction_dest_country_id__c, ';
    this.fieldsToSave += 'Alert_migrated__c, Client_STAR_ID__c, Group_Client__c, Group_Name__c, Group_Product__c, Group_Type__c, IsMember__c, Members_code__c, ';
    this.fieldsToSave += 'business_group_id__c, gf_alert_owner_user_origl_id__c, gf_alert_short_name__c, participant_name__c, sf_no_db_monitor_manager_user_id__c, ';
    this.fieldsToSave += 'sf_no_db_ori_manager_user_id__c, sf_no_db_user_id__c, IsActiveOwner__c, Owner.Name';

    // Se cambia para seleccionar los regitros de más de 3 años en lugar de dos y para comparar con la StartDate y no la CreatedDate
    //this.pQuery = 'SELECT Id, (select ctcp__gf_team_users_desc__r.Name, ctcp__gf_team_users_desc__r.Email from Alert_Teams__r), '+ this.fieldsToSave + ' FROM altm__Commercial_Alert__c	' + (Test.isRunningTest() ? 'LIMIT 1' : 'WHERE CreatedDate < :twoYears'); //NOSONAR
    this.pQuery = 'SELECT Id, (select ctcp__gf_team_users_desc__r.Name, ctcp__gf_team_users_desc__r.Email from Alert_Teams__r), '+ this.fieldsToSave + ' FROM altm__Commercial_Alert__c ' + (Test.isRunningTest() ? 'LIMIT 1' : 'WHERE altm_commercial_alert_start_date__c < :threeYears'); //NOSONAR
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    //system.debug('twoYears: ' + twoYears);
    system.debug('threeYears: ' + threeYears);
    system.debug('Query: ' + pQuery.substringAfterLast('WHERE'));
    system.debug('Query: ' + pQuery);
    return Database.getQueryLocator(pQuery);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch,List<altm__Commercial_Alert__c> scope) { //NOSONAR
    final List<Commercial_Alert__b> bigAlerts = new List<Commercial_Alert__b>();
    system.debug('scope: ' + scope);
    for(altm__Commercial_Alert__c alert : scope) {
      String miembros = '';
      alertsIds.add(alert.Id);
      for(ctcp__Custom_Team__c customTeam : alert.Alert_Teams__r) {
        miembros += customTeam.ctcp__gf_team_users_desc__r.Name + ';' + customTeam.ctcp__gf_team_users_desc__r.Email + '//';
      }
      final Commercial_Alert__b bigAlert = new Commercial_Alert__b();
      bigAlert.Alert_Team__c = miembros == '' ? '' : miembros.substring(0,miembros.length()-2);
      bigAlert.Alert_migrated__c = isBoolean(alert.Alert_migrated__c);
      bigAlert.Client_Name__c = alert.altm__participant_id__r.Name;
      bigAlert.Client_STAR_ID__c = alert.Client_STAR_ID__c;
      bigAlert.CurrencyIsoCode__c = alert.CurrencyIsoCode;
      bigAlert.Group_Client__c = alert.Group_Client__c;
      bigAlert.Group_Name__c = alert.Group_Name__c;
      bigAlert.Group_Product__c = alert.Group_Product__c;
      bigAlert.Group_Type__c = alert.Group_Type__c;
      bigAlert.Id__c = alert.Id;
      bigAlert.Name__c = alert.Name;
      bigAlert.Owner__c = alert.Owner.Name;
      bigAlert.altm_Access_to_this_alert__c = isBoolean(alert.altm__Access_to_this_alert__c);
      bigAlert.altm_Actual_drawn_cr_revolving_per__c = alert.altm__Actual_drawn_cr_revolving_per__c;
      bigAlert.altm_BBVA_rejection_reason_desc__c = alert.altm__BBVA_rejection_reason_desc__c;
      bigAlert.altm_Client_product_accepted_type__c = alert.altm__Client_product_accepted_type__c;
      bigAlert.altm_Client_rejection_reason_desc__c = alert.altm__Client_rejection_reason_desc__c;
      bigAlert.altm_Expected_drawn_cr_revolving_per__c = alert.altm__Expected_drawn_cr_revolving_per__c;
      bigAlert.altm_ISIN_id__c = alert.altm__ISIN_id__c;
      bigAlert.altm_Leveraged_Buyout_start_date__c = alert.altm__Leveraged_Buyout_start_date__c;
      bigAlert.altm_Monitor_manager_user_id__c = alert.altm__Monitor_manager_user_id__c;
      bigAlert.altm_Others_rejection_reason_desc__c = alert.altm__Others_rejection_reason_desc__c;
      bigAlert.altm_Project_name__c = alert.altm__Project_name__c;
      bigAlert.altm_Rejection_reason_desc__c = alert.altm__Rejection_reason_desc__c;
      bigAlert.altm_Repayment_capital_drawn_per__c = alert.altm__Repayment_capital_drawn_per__c;
      bigAlert.altm_Repayment_credit_limit_revlv_per__c = alert.altm__Repayment_credit_limit_revlv_per__c;
      bigAlert.altm_Transaction_type_desc__c = alert.altm__Transaction_type_desc__c;
      bigAlert.altm_User_id__c = alert.altm__User_id__c;
      bigAlert.altm_alert_expiration_date__c = alert.altm__alert_expiration_date__c;
      bigAlert.altm_alert_stage_type__c = alert.altm__alert_stage_type__c;
      bigAlert.altm_amortization_desc__c = alert.altm__amortization_desc__c;
      bigAlert.altm_bbva_share_amount__c = alert.altm__bbva_share_amount__c;
      bigAlert.altm_bloomberg_ticker_id__c = alert.altm__bloomberg_ticker_id__c;
      bigAlert.altm_clan_syndicated_contract_id__c = alert.altm__clan_syndicated_contract_id__c;
      bigAlert.altm_client_process_accepted_type__c = isBoolean(alert.altm__client_process_accepted_type__c);
      bigAlert.altm_comm_alerts_perf_actions_type__c = alert.altm__comm_alerts_perf_actions_type__c;
      bigAlert.altm_commercial_alert_desc__c = alert.altm__commercial_alert_desc__c;
      bigAlert.altm_commercial_alert_end_date__c = alert.altm__commercial_alert_end_date__c;
      bigAlert.altm_commercial_alert_id__c = alert.altm__commercial_alert_id__c;
      bigAlert.altm_commercial_alert_record_type__c = alert.altm__commercial_alert_record_type__c;
      bigAlert.altm_commercial_alert_rfq_amount__c = alert.altm__commercial_alert_rfq_amount__c;
      bigAlert.altm_commercial_alert_start_date__c = alert.altm__commercial_alert_start_date__c;
      bigAlert.altm_commercial_alert_task_type__c = alert.altm__commercial_alert_task_type__c;
      bigAlert.altm_commercial_product_type__c = alert.altm__commercial_product_type__c;
      bigAlert.altm_commercial_subalert_name__c = alert.altm__commercial_subalert_name__c;
      bigAlert.altm_country_id__c = alert.altm__country_id__c;
      bigAlert.altm_data_source_name__c = alert.altm__data_source_name__c;
      bigAlert.altm_entity_id__c = alert.altm__entity_id__c;
      bigAlert.altm_execution_indicator_type__c = alert.altm__execution_indicator_type__c;
      bigAlert.altm_financial_tail_month_number__c = alert.altm__financial_tail_month_number__c;
      bigAlert.altm_gf_last_upload_alerts_ind_type__c = isBoolean(alert.altm__gf_last_upload_alerts_ind_type__c);
      bigAlert.altm_operation_amount__c = alert.altm__operation_amount__c;
      bigAlert.altm_operation_date__c = alert.altm__operation_date__c;
      bigAlert.altm_opperation_amount__c = alert.altm__opperation_amount__c;
      bigAlert.altm_origination_manager_team_id__c = alert.altm__origination_manager_team_id__c;
      bigAlert.altm_origl_currency_operation_amount__c = alert.altm__origl_currency_operation_amount__c;
      bigAlert.altm_owner_access_alert_id__c = alert.altm__owner_access_alert_id__c;
      bigAlert.altm_participant_id__c = alert.altm__participant_id__c;
      bigAlert.altm_pricing_data_desc__c = alert.altm__pricing_data_desc__c;
      bigAlert.altm_primary_asset_clasification_type__c = alert.altm__primary_asset_clasification_type__c;
      bigAlert.altm_priority_alert_type__c = alert.altm__priority_alert_type__c;
      bigAlert.altm_process_discard_status_type__c = isBoolean(alert.altm__process_discard_status_type__c);
      bigAlert.altm_repayment_date__c = alert.altm__repayment_date__c;
      bigAlert.altm_sector_id__c = alert.altm__sector_id__c;
      bigAlert.altm_solution_category_id__c = alert.altm__solution_category_id__c;
      bigAlert.altm_synd_loan_amortization_amount__c = alert.altm__synd_loan_amortization_amount__c;
      bigAlert.altm_syndicated_contract_id__c = alert.altm__syndicated_contract_id__c;
      bigAlert.altm_syndicated_loan_committed_amount__c = alert.altm__syndicated_loan_committed_amount__c;
      bigAlert.altm_syndicated_loan_drawn_amount__c = alert.altm__syndicated_loan_drawn_amount__c;
      bigAlert.altm_syndicated_loan_total_amount__c = alert.altm__syndicated_loan_total_amount__c;
      bigAlert.altm_syndicated_loan_undrawn_amount__c = alert.altm__syndicated_loan_undrawn_amount__c;
      bigAlert.altm_syndicated_tranche_type__c = alert.altm__syndicated_tranche_type__c;
      bigAlert.altm_total_transaction_number__c = alert.altm__total_transaction_number__c;
      bigAlert.altm_transaction_dest_country_id__c = alert.altm__transaction_dest_country_id__c;
      bigAlert.business_group_id__c = alert.business_group_id__c;
      bigAlert.gf_alert_owner_user_origl_id__c = alert.gf_alert_owner_user_origl_id__c;
      bigAlert.gf_alert_short_name__c = alert.gf_alert_short_name__c;
      bigAlert.participant_name__c = alert.participant_name__c;
      bigAlerts.add(bigAlert);
    }
    if(!Test.isRunningTest()) { //NOSONAR
      system.debug('bigAlerts: ' + bigAlerts);
      database.insertImmediate(bigAlerts);
    }
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    Database.executeBatch(new VisitsEventDelete(alertsIds, 'WhatId', 'Alert'), 100);
  }

  /*
  * getExecuteBatchSize method
  */
  private String isBoolean(Boolean value) {
    return value ? 'true' : 'false';
  }
}