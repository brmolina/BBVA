/*
* @author GlobalDesktop
* @description Batch to move opps to big object
*/
public without sharing class OpportunityBigObject implements Database.Batchable<Sobject>, Database.Stateful {

  /* Two years Date */
  private Date fourYears = Date.newInstance(date.today().year()-4, 1, 1); //NOSONAR
  /* Query */
  private String fieldsToSave = ''; //NOSONAR
  /* Query */
  private String pQuery = ''; //NOSONAR

  /* Query */
  private Set<Id> oppsIds = new Set<Id>(); //NOSONAR

  /*
  * Constructor
  */
  public OpportunityBigObject() {
    this.fieldsToSave += 'DES_Expected_Probability__c, DES_Comments__c, gf_total_nominal_sold_amount__c, gf_comm_offer_moppy_ind_type__c, gf_opportunity_product_desc__c';
    this.fieldsToSave += ', DES_Countries__c, DES_Booking_Geography__c, gf_opportunity_nbc_name__c, CIB_Geography_participant__c, AccountId, DES_Client_Text__c';
    this.fieldsToSave += ', DES_Description_rich__c, Committee_id__r.Committee_End_Date__c, Committee_id__r.Committee_Start_Date__c, opportunity_correct_ind_type__c, CreatedDate, gf_comm_plan_opp_ind_type__c';
    this.fieldsToSave += ', DES_Cross_border__c, CurrencyIsoCode, DES_Date_Won_Lost__c, DES_Description_reason_for_lost_deal__c, CloseDate, GCC_Attended_type__c, GCC_Supportive_type__c';
    this.fieldsToSave += ', Geography_CIB_Attended_type__c, Geography_CIB_Supportive_type__c, GTB_Attended_type__c, GTB_Supportive_type__c, GF_Attended_type__c, GF_Supportive_type__c, gcc_participant_desc__c';
    this.fieldsToSave += ', Business_area_desc__c, Business_line_desc__c, coverage_country_name__c, Entity_name__c, solution_name_path_desc__c, gtb_participant_desc__c, gf_participant_desc__c';
    this.fieldsToSave += ', disclosure_info_type__c, Committee_id__r.Name, NBC_Decision_Taken_type__c, DES_NBC_Region__c, gf_oppy_virtual_cmtee_ind_type__c, DES_Confirm_Duplicate_Message__c, Number_of_Initiatives__c';
    this.fieldsToSave += ', Name, Owner.Name, EMPLOYEE_DEPARTMENT_DESC__c, DES_Prospect__r.Name, gf_oppy_reactivated_ind_type__c, gf_reactivation_oppy_date__c, DES_Reasons_Lost__c, region_name__c, DES_Expected_Probability__c';
    this.fieldsToSave += ', DES_Reg_W_Affiliate_Only_BBVA_Compass__c, Risk_Attended_type__c, Risk_Supportive_type__c, risk_participant_desc__c, stage_changed_type__c, StageName, gf_workflow_oppy_status_type__c, sustainable_finance_ind_type__c';
    this.fieldsToSave += ', Template_approved_type__c, DES_Expected_Revenues__c, gf_tot_sold_order_fees_amount__c, Total_of_Opportunity_Products__c, pre_oppy_revenue_next_12m_amount__c, Total_of_Sold_Orders__c, gf_total_sold_ord_stl_amount__c, x_sell_committee_type__c';
    this.pQuery = 'SELECT Id, (Select Id, DES_Opportunity_member_role__c, DES_User__r.Name from Opportunity_Management_members__r) '+ this.fieldsToSave + ' FROM Opportunity ' + (Test.isRunningTest() ? 'LIMIT 1' : 'WHERE AccountId != null AND IsClosed = true AND CreatedDate < :fourYears AND (disclosure_info_type__c = null OR disclosure_info_type__c = \'Not applicable\' OR disclosure_info_type__c = \'Confidential information\')'); //NOSONAR
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    system.debug('twoYears: ' + fourYears);
    system.debug('Query: ' + pQuery.substringAfterLast('WHERE'));
    return Database.getQueryLocator(pQuery);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext bch,List<Opportunity> scope) { //NOSONAR
    final List<Opportunity__b> bigOpps = new List<Opportunity__b>();
    for(Opportunity opp : scope) {
      oppsIds.add(opp.Id);
      String members = '';
      for(DES_Opportunity_Management_member__c iOppMember : opp.Opportunity_Management_members__r) {
        members += iOppMember.DES_User__r.Name + ';' + (iOppMember.DES_Opportunity_member_role__c == null ? '' : iOppMember.DES_Opportunity_member_role__c) + '//';
      }
      final Opportunity__b bigOpp = new Opportunity__b();
      bigOpp.DES_Expected_Probability__c = opp.DES_Expected_Probability__c;
      bigOpp.Opportunity_Members__c = members == '' ? '' : members.substring(0,members.length()-2);
      bigOpp.DES_Comments__c = opp.DES_Comments__c;
      bigOpp.gf_total_nominal_sold_amount__c = opp.gf_total_nominal_sold_amount__c;
      bigOpp.gf_comm_offer_moppy_ind_type__c = isBoolean(opp.gf_comm_offer_moppy_ind_type__c);
      bigOpp.gf_opportunity_product_desc__c = opp.gf_opportunity_product_desc__c;
      bigOpp.DES_Countries__c = opp.DES_Countries__c;
      bigOpp.DES_Booking_Geography__c = opp.DES_Booking_Geography__c;
      bigOpp.gf_opportunity_nbc_name__c = opp.gf_opportunity_nbc_name__c;
      bigOpp.CIB_Geography_participant__c = opp.CIB_Geography_participant__c;
      bigOpp.AccountId__c = opp.AccountId;
      bigOpp.DES_Client_Text__c = opp.DES_Client_Text__c;
      bigOpp.DES_Description_rich__c = opp.DES_Description_rich__c;
      bigOpp.Committee_End_Date__c = opp.Committee_id__r.Committee_End_Date__c;
      bigOpp.Committee_Start_Date__c = opp.Committee_id__r.Committee_Start_Date__c;
      bigOpp.opportunity_correct_ind_type__c = isBoolean(opp.opportunity_correct_ind_type__c);
      bigOpp.CreatedDate__c = opp.CreatedDate;
      bigOpp.gf_comm_plan_opp_ind_type__c = isBoolean(opp.gf_comm_plan_opp_ind_type__c);
      bigOpp.DES_Cross_border__c = isBoolean(opp.DES_Cross_border__c);
      bigOpp.CurrencyIsoCode__c = opp.CurrencyIsoCode ;
      bigOpp.DES_Date_Won_Lost__c = opp.DES_Date_Won_Lost__c;
      bigOpp.DES_Description_reason_for_lost_deal__c = opp.DES_Description_reason_for_lost_deal__c;
      bigOpp.CloseDate__c = opp.CloseDate;
      bigOpp.GCC_Attended_type__c = opp.GCC_Attended_type__c;
      bigOpp.GCC_Supportive_type__c = opp.GCC_Supportive_type__c;
      bigOpp.Geography_CIB_Attended_type__c = opp.Geography_CIB_Attended_type__c;
      bigOpp.Geography_CIB_Supportive_type__c = opp.Geography_CIB_Supportive_type__c;
      bigOpp.GTB_Attended_type__c = opp.GTB_Attended_type__c;
      bigOpp.GTB_Supportive_type__c = opp.GTB_Supportive_type__c;
      bigOpp.GF_Attended_type__c = opp.GF_Attended_type__c;
      bigOpp.GF_Supportive_type__c = opp.GF_Supportive_type__c;
      bigOpp.gcc_participant_desc__c = opp.gcc_participant_desc__c;
      bigOpp.Business_area_desc__c = opp.Business_area_desc__c;
      bigOpp.Business_line_desc__c = opp.Business_line_desc__c;
      bigOpp.coverage_country_name__c = opp.coverage_country_name__c;
      bigOpp.Entity_name__c = opp.Entity_name__c;
      bigOpp.solution_name_path_desc__c = opp.solution_name_path_desc__c;
      bigOpp.gtb_participant_desc__c = opp.gtb_participant_desc__c;
      bigOpp.gf_participant_desc__c = opp.gf_participant_desc__c;
      bigOpp.Id__c = opp.Id;
      bigOpp.disclosure_info_type__c = opp.disclosure_info_type__c;
      bigOpp.Committee_id__c = opp.Committee_id__r.Name;
      bigOpp.NBC_Decision_Taken_type__c = opp.NBC_Decision_Taken_type__c;
      bigOpp.DES_NBC_Region__c = opp.DES_NBC_Region__c;
      bigOpp.gf_oppy_virtual_cmtee_ind_type__c = isBoolean(opp.gf_oppy_virtual_cmtee_ind_type__c);
      bigOpp.DES_Confirm_Duplicate_Message__c = isBoolean(opp.DES_Confirm_Duplicate_Message__c);
      bigOpp.Number_of_Initiatives__c = opp.Number_of_Initiatives__c;
      bigOpp.Name__c = opp.Name;
      bigOpp.Owner__c = opp.Owner.Name;
      bigOpp.EMPLOYEE_DEPARTMENT_DESC__c = opp.EMPLOYEE_DEPARTMENT_DESC__c;
      bigOpp.DES_Prospect__c = opp.DES_Prospect__r.Name;
      bigOpp.gf_oppy_reactivated_ind_type__c = isBoolean(opp.gf_oppy_reactivated_ind_type__c);
      bigOpp.gf_reactivation_oppy_date__c = opp.gf_reactivation_oppy_date__c;
      bigOpp.DES_Reasons_Lost__c = opp.DES_Reasons_Lost__c;
      bigOpp.region_name__c = opp.region_name__c;
      bigOpp.DES_Reg_W_Affiliate_Only_BBVA_Compass__c = isBoolean(opp.DES_Reg_W_Affiliate_Only_BBVA_Compass__c);
      bigOpp.Risk_Attended_type__c = opp.Risk_Attended_type__c;
      bigOpp.Risk_Supportive_type__c = opp.Risk_Supportive_type__c;
      bigOpp.risk_participant_desc__c = opp.risk_participant_desc__c;
      bigOpp.stage_changed_type__c = isBoolean(opp.stage_changed_type__c);
      bigOpp.StageName__c = opp.StageName;
      bigOpp.gf_workflow_oppy_status_type__c = opp.gf_workflow_oppy_status_type__c;
      bigOpp.sustainable_finance_ind_type__c = isBoolean(opp.sustainable_finance_ind_type__c);
      bigOpp.Template_approved_type__c = isBoolean(opp.Template_approved_type__c);
      bigOpp.DES_Expected_Revenues__c = opp.DES_Expected_Revenues__c;
      bigOpp.gf_tot_sold_order_fees_amount__c = opp.gf_tot_sold_order_fees_amount__c;
      bigOpp.Total_of_Opportunity_Products__c = opp.Total_of_Opportunity_Products__c;
      bigOpp.Total_of_Sold_Orders__c = opp.Total_of_Sold_Orders__c;
      bigOpp.pre_oppy_revenue_next_12m_amount__c = opp.pre_oppy_revenue_next_12m_amount__c;
      bigOpp.gf_total_sold_ord_stl_amount__c = opp.gf_total_sold_ord_stl_amount__c;
      bigOpp.x_sell_committee_type__c = isBoolean(opp.x_sell_committee_type__c);
      bigOpps.add(bigOpp);
    }
    if(!Test.isRunningTest()) { //NOSONAR
      database.insertImmediate(bigOpps);
    }
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext bch) {
    Database.executeBatch(new OpportunityLineBigObject(oppsIds), 200);
  }

  /*
  * getExecuteBatchSize method
  */
  private String isBoolean(Boolean value) {
    return value ? 'true' : 'false';
  }

}