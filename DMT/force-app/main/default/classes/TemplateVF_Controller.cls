/**
 *
 *
 * @author VASS
 */
public with sharing class TemplateVF_Controller {

  /**
   *
   *
   * Year
   */
  public Integer yearTable { get; set; }
  /**
   *
   *
   * RARRORC year
   */
  public Integer yearRARRORCTable { get; set; }
  /**
   *
   *
   * Name Recordtype
   */
  public String recordTypeName { get; set; }
  /**
   *
   *
   * template
   */
  public DES_Template__c parentTempl { get; set; }
  /**
   *
   *
   * template
   */
  public DES_Template_Table__c templ { get; set; }
  /**
   *
   *
   * is compass
   */
  public Boolean isCompass { get; set; }
  /**
   *
   *
   * disabled
   */
  public String disabled { get; set; }
  /**
   *
   *
   * bookin
   */
  public String booking { get; set; }
  /*
   * Script var para ejecutar código javascript desde el controlador
   *
   */
  public string scriptvar { get; set; }
  /*
   * List fields for sustainable
   *
   */
  public List<FieldSetMemberWrapperClass> lFields1 { get; set; }
  /*
   * List fields for sustainable
   *
   */
  public List<FieldSetMemberWrapperClass> lFields2Y { get; set; }
  /*
   * List fields for sustainable
   *
   */
  public List<FieldSetMemberWrapperClass> lFields2N { get; set; }
  /*
   * List fields for sustainable
   *
   */
  public List<FieldSetMemberWrapperClass> lFields3 { get; set; }
  /*
   * Field for description
   *
   */
  public String desciption1 { get; set; }
  /*
   * Field for description
   *
   */
  public String desciption3 { get; set; }
  /*
   * Field for description
   *
   */
  public String greenFields { get; set; }
  /*
   * Field for description
   *
   */
  public String transFields { get; set; }
  /*
   * Field for description
   *
   */
  public String socialFields { get; set; }
  /*
   * Field for description
   *
   */
  public String sustainFields { get; set; }
  /*
   * Field for description
   *
   */
  public String carbonFields { get; set; }
  /*
   * Field for description
   *
   */
  public String otherFields { get; set; }
   /*
   * Field for ToolkitSector
   *
   */
  public String sectorToolkit { get; set; }
  /**
   *
   *
   * profile name
   */
  private String profileName;




  /* Metdo1 */
  public void saveOnChangeField(DES_Template_Table__c templUpdate) {
    try {

      system.debug('templUpdate1 -> ' + templUpdate);
      if((parentTempl.opportunity_id__r.NBC_Decision_Taken_type__c == Label.NBC_Decision_Recommended || parentTempl.opportunity_id__r.NBC_Decision_Taken_type__c == Label.NBC_Decision_Not_Recommended) && profileName != Label.DES_ADMIN_PROFILE && profileName != Label.DES_SP_PROFILE) {
        disabled = 'true';
      } else if(parentTempl.opportunity_id__r.NBC_Decision_Taken_type__c == Label.NBC_Decision_Pending) {
        upsert templUpdate;
        TemplateVF_ControllerHandler.updateOppSustainable(templUpdate, parentTempl);
      } else if(parentTempl.opportunity_id__r.NBC_Decision_Taken_type__c == null) {
        if((parentTempl.Pending_approval_type__c || parentTempl.Template_approved_type__c) && profileName != Label.DES_ADMIN_PROFILE && profileName != Label.DES_SP_PROFILE) {
          disabled = 'true';
        } else {
          upsert templUpdate;
          TemplateVF_ControllerHandler.updateOppSustainable(templUpdate, parentTempl);
        }
      }
      system.debug('templUpdate2 -> ' + templUpdate);

    } catch (Exception e) {
      String consoleError;
      consoleError = '<script> console.log(\' Error on save: [' + e.getMessage() + '  ]\'); </script>';
      scriptvar = '<div class="text-red">Can´t save, insufficient access rights on object id.</div>' + consoleError;
    }



  }
  /* Metdo2 */
  public TemplateVF_Controller(ApexPages.StandardController stdController) {
    scriptvar='';

    /* Declare variables*/
    DES_Template__c template = new DES_Template__c();
    template = (DES_Template__c)stdController.getRecord();
    Id templId;
    getToolkitSector(template); //NOSONAR
    templId = template.Id;
    parentTempl = new DES_Template__c();
    templ = new DES_Template_Table__c();
    profileName = [SELECT id, Name from Profile where id = :userinfo.getProfileId() LIMIT 1].get(0).Name;

    String /*dateEngloba, yearEngloba, */ dateRARRORC, yearRARRORC;
    system.debug('>>>>> stdController: ' + stdController);
    system.debug('>>>>> template:' + template);
    /* Get the template with field DES_Revenue_Update_Engloba__c from client */
    if(templId != null) {

      parentTempl = [SELECT other_information_desc__c,Revenues_Year_number__c,All_in_Drawn_Undrawn_desc__c,Amiweb_Id_id__c,Amiweb_Proposal_desc__c,Applicable_Jurisdiction_desc__c,Approval_Date_date__c,Asset_Allocation_type__c,
                     Availability_Period1_number__c,Availability_Period2_number__c,Availability_Period3_number__c,Availability_Period4_number__c,Average_Life1_number__c,Average_Life2_number__c,Average_Life3_number__c,
                     Average_Life4_number__c,Bankers_desc__c,Banker_desc__c,Banker_Name_desc__c,BBVA_Commitment1_number__c,BBVA_Commitment2_number__c,BBVA_Commitment3_number__c,BBVA_Commitment4_number__c,
                     New_Up_Front_Fee_NonAccrual1_desc__c,New_Up_Front_Fee_NonAccrual2_desc__c,New_Up_Front_Fee_NonAccrual3_desc__c,New_Up_Front_Fee_NonAccrual4_desc__c,Old_Up_Front_Fee_NonAccrual1_desc__c,Old_Up_Front_Fee_NonAccrual2_desc__c,Old_Up_Front_Fee_NonAccrual3_desc__c,Old_Up_Front_Fee_NonAccrual4_desc__c,
                     Past2_FY_Cash_Management_amount__c,Past2_FY_Client_Resources_amount__c,Past2_FY_Corp_Synd_Lending_amount__c,Past2_FY_Credit_Equity_amount__c,Past2_FY_DCM_amount__c,Past2_FY_ECM_M_A_Amount__c,Past2_FY_FX_CCS_amount__c,Past2_FY_GTF_amount__c,Past2_FY_Rates_amount__c,Past2_FY_Securities_Services_amount__c,Past2_FY_Structured_Finance_amount__c,
                     Past2_FY_Total_Non_X_Sell_amount__c,Past2_FY_Total_Revenues_amount__c,Past2_FY_Total_X_Sell_amount__c,Past2_FY_Working_Capital_amount__c,
                     BBVA_Commit_Mn_amount__c,Blended_RaR_number__c,Blended_RORC_number__c,Booking_type__c,Borrower_s_name_Fiscal_ID_desc__c,Calification_type__c,Capital_Action_type__c,Client_Id__c,Committee_id__c,
                     Commit_Deadline_date__c,COMPASS_Deal_s_Standalone_ROEC_per__c,COMPASS_Deal_s_Standalone_RORC_per__c,COMPASS_Expected_ROEC_per__c,COMPASS_Expected_RORC_per__c,COMPASS_RPM_LTM_ROEC_per__c,COMPASS_RPM_LTM_RORC_per__c,
                     Competition_For_the_Deal_desc__c,Completed_By_desc__c,Consumption_desc__c,Corp_Lending_Support_type__c,Country_Risk_Limit_type__c,Country_Risk_type__c,CreatedById,CreatedDate,Credit_Risk_Opinion_Provided_By_desc__c,
                     CurrencyIsoCode,Current_FY_Cash_Management_amount__c,Current_FY_Client_Resources_amount__c,Current_FY_Corp_Synd_Lending_amount__c,Current_FY_Credit_Equity_amount__c,Current_FY_DCM_amount__c,Current_FY_ECM_M_A_Amount__c,
                     Current_FY_FX_CCS_amount__c,Current_FY_GTF_amount__c,Current_FY_Rates_amount__c,Current_FY_Securities_Services_amount__c,Current_FY_Structured_Finance_amount__c,Current_FY_Total_Non_X_Sell_amount__c,Current_FY_Total_Revenues_amount__c,
                     Current_FY_Total_X_Sell_amount__c,Current_FY_Working_Capital_amount__c,DCM_ECM_amount__c,DCM_ECM_Opinion_type__c,Deal_Amount_Bn_amount__c,Debt_EBITDA_Current_Year_number__c,Debt_EBITDA_Last_Year_number__c,Debt_EBITDA_Next_Year_1_number__c,
                     Debt_EBITDA_Next_Year_2_number__c,Debt_EBITDA_Next_Year_number__c,Debt_Funds_Num_1_number__c,Debt_Funds_Num_2_number__c,Debt_Funds_Num_3_number__c,Debt_Funds_Num_4_number__c,Debt_Funds_Num_5_number__c,Debt_Funds_Text_1_desc__c,Debt_Funds_Text_2_desc__c,
                     Debt_Funds_text_3_desc__c,Debt_Funds_text_4_desc__c,Debt_Funds_Text_5_desc__c,Debt_Funds_Total_number__c,Derivative_RaR_number__c,Derivative_RORC_number__c,DSCR1_number__c,DSCR2_number__c,DSCR3_number__c,DSCR4_number__c,EBITDA_Current_Year_number__c,
                     EBITDA_Last_Year_number__c,EBITDA_Next_Year_1_number__c,EBITDA_Next_Year_2_number__c,EBITDA_Next_Year_number__c,EBIT_Current_Year_number__c,EBIT_Last_Year_number__c,EBIT_Next_Year_1_number__c,EBIT_Next_Year_2_number__c,EBIT_Next_Year_number__c,ECA_Coverage_per__c,
                     ECA_Name_Fiscal_Id_type__c,ECA_Rating_type__c,Economic_capital_RWA_amount__c,Equator_Principles_type__c,Equity_Funds_num_1_number__c,Equity_Funds_num_2_number__c,Equity_Funds_num_3_number__c,Equity_Funds_num_4_number__c,Equity_Funds_text_1_desc__c,
                     Equity_Funds_text_2_desc__c,Equity_Funds_text_3_desc__c,Equity_Funds_text_4_desc__c,Equity_Funds_Total_number__c,Expected_Final_Take1_number__c,Expected_Final_Take2_number__c,Expected_Final_Take3_number__c,Expected_Final_Take4_number__c,
                     Ext_Rating_type__c,Financial_Program_type__c,Floor_Clause_desc__c,Franchise_amount__c,Free_Cash_Flow_Current_Year_number__c,Free_Cash_Flow_Last_Year_number__c,Free_Cash_Flow_Next_Year_1_number__c,Free_Cash_Flow_Next_Year_2_number__c,
                     Free_Cash_Flow_Next_Year_number__c,Geographical_Footprint_desc__c,Global_Banker_desc__c,Global_Banker_Id_desc__c,Global_Banker_Name_desc__c,GM_DCM_Support_type__c,GM_ex_derivative_DCM_amount__c,Group_Client_desc__c,GTB_Ex_credit_lines_guarantees_amount__c,
                     GTB_Support_type__c,Guarantor_s_name_Fiscal_ID_desc__c,History_of_the_deal_desc__c,Id,Industry_AA_type__c,Industry_Overview_desc__c,Internal_Rating_Date_date__c,Int_Rating_type__c,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,LastReferencedDate,
                     LastViewedDate,Last_Visit_to_the_Client_desc__c,Leveraged_Lending_type__c,Leverage_Ratio1_number__c,Leverage_Ratio2_number__c,Leverage_Ratio3_number__c,Leverage_Ratio4_number__c,LGD_if_applies_per__c,Main_characteristics_desc__c,Main_Performance_Indicators_desc__c,Maturity_door_to_door1_number__c,
                     Maturity_door_to_door2_number__c,Maturity_door_to_door3_number__c,Maturity_door_to_door4_number__c,Name,Net_Debt_EBITDA_Current_Year_number__c,Net_Debt_EBITDA_Last_Year_number__c,Net_Debt_EBITDA_Next_Year_1_number__c,Net_Debt_EBITDA_Next_Year_2_number__c,Net_Debt_EBITDA_Next_Year_number__c,
                     Net_Income_Current_Year_number__c,Net_Income_Last_Year_number__c,Net_Income_Next_Year_1_number__c,Net_Income_Next_Year_2_number__c,Net_Income_Next_Year_number__c,New_All_in_Drawn1_desc__c,New_All_in_Drawn2_desc__c,New_All_in_Drawn3_desc__c,New_All_in_Drawn4_desc__c,New_All_in_Undrawn1_desc__c,New_All_in_Undrawn2_desc__c,
                     New_All_in_Undrawn3_desc__c,New_All_in_Undrawn4_desc__c,New_Applicable_Margin1_desc__c,New_Applicable_Margin2_desc__c,New_Applicable_Margin3_desc__c,New_Applicable_Margin4_desc__c,New_Commitment_Fee1_desc__c,New_Commitment_Fee2_desc__c,New_Commitment_Fee3_desc__c,New_Commitment_Fee4_desc__c,New_Expected_Drawn1_desc__c,
                     New_Expected_Drawn2_desc__c,New_Expected_Drawn3_desc__c,New_Expected_Drawn4_desc__c,New_Extension_Duration_Fee1_desc__c,New_Extension_Duration_Fee2_desc__c,New_Extension_Duration_Fee3_desc__c,New_Extension_Duration_Fee4_desc__c,New_Funding_Cost1_desc__c,New_Funding_Cost2_desc__c,New_Funding_Cost3_desc__c,New_Funding_Cost4_desc__c,
                     New_Liquidity_Fee1_desc__c,New_Liquidity_Fee2_desc__c,New_Liquidity_Fee3_desc__c,New_Liquidity_Fee4_desc__c,New_Money_for_BBVA1_desc__c,New_Money_for_BBVA2_desc__c,New_Money_for_BBVA3_desc__c,New_Money_for_BBVA4_desc__c,New_Other_Fees1_desc__c,New_Other_Fees2_desc__c,New_Other_Fees3_desc__c,New_Other_Fees4_desc__c,
                     New_Pricing_Grid_Step_Up1_desc__c,New_Pricing_Grid_Step_Up2_desc__c,New_Pricing_Grid_Step_Up3_desc__c,New_Pricing_Grid_Step_Up4_desc__c,New_Up_Front_Fee1_desc__c,New_Up_Front_Fee2_desc__c,New_Up_Front_Fee3_desc__c,New_Up_Front_Fee4_desc__c,New_Utilisation_Fee1_desc__c,New_Utilisation_Fee2_desc__c,New_Utilisation_Fee3_desc__c,
                     New_Utilisation_Fee4_desc__c,Next_FY_Cash_Management_amount__c,Next_FY_Client_Resources_amount__c,Next_FY_Corp_Synd_Lending_amount__c,Next_FY_Credit_Equity_amount__c,Next_FY_DCM_amount__c,Next_FY_ECM_M_A_amount__c,Next_FY_FX_CCS_amount__c,Next_FY_GTF_amount__c,Next_FY_Rates_amount__c,Next_FY_Securities_Services_amount__c,
                     Next_FY_Structured_Finance_amount__c,Next_FY_Total_Non_X_Sell_amount__c,Next_FY_Total_Revenues_amount__c,Next_FY_Total_X_Sell_amount__c,Next_FY_Working_Capital_amount__c,Notional_Exposure_Percent_per__c,NY_Deal_s_Standalone_RAR_per__c,NY_Deal_s_Standalone_RORC_per__c,Old_All_in_Drawn1_desc__c,Old_All_in_Drawn2_desc__c,Old_All_in_Drawn3_desc__c,
                     Old_All_in_Drawn4_desc__c,Old_All_in_Undrawn1_desc__c,Old_All_in_Undrawn2_desc__c,Old_All_in_Undrawn3_desc__c,Old_All_in_Undrawn4_desc__c,Old_Applicable_Margin1_desc__c,Old_Applicable_Margin2_desc__c,Old_Applicable_Margin3_desc__c,Old_Applicable_Margin4_desc__c,Old_Commitment_Fee1_desc__c,Old_Commitment_Fee2_desc__c,Old_Commitment_Fee3_desc__c,Old_Commitment_Fee4_desc__c,
                     Old_Expected_Drawn1_desc__c,Old_Expected_Drawn2_desc__c,Old_Expected_Drawn3_desc__c,Old_Expected_Drawn4_desc__c,Old_Extension_Duration_Fee1_desc__c,Old_Extension_Duration_Fee2_desc__c,Old_Extension_Duration_Fee3_desc__c,Old_Extension_Duration_Fee4_desc__c,Old_Funding_cost1_desc__c,Old_Funding_cost2_desc__c,Old_Funding_cost3_desc__c,Old_Funding_cost4_desc__c,
                     Old_Liquidity_fee1_desc__c,Old_Liquidity_fee2_desc__c,Old_Liquidity_fee3_desc__c,Old_Liquidity_fee4_desc__c,Old_Money_for_BBVA1_desc__c,Old_Money_for_BBVA2_desc__c,Old_Money_for_BBVA3_desc__c,Old_Money_for_BBVA4_desc__c,Old_Other_Fees1_desc__c,Old_Other_Fees2_desc__c,Old_Other_Fees3_desc__c,Old_Other_Fees4_desc__c,Old_Pricing_Grid_Step_Up1_desc__c,Old_Pricing_Grid_Step_Up2_desc__c,
                     Old_Pricing_Grid_Step_Up3_desc__c,Old_Pricing_Grid_Step_Up4_desc__c,Old_Up_Front_Fee1_desc__c,Old_Up_Front_Fee2_desc__c,Old_Up_Front_Fee3_desc__c,Old_Up_Front_Fee4_desc__c,Old_Utilisation_Fee1_desc__c,Old_Utilisation_Fee2_desc__c,Old_Utilisation_Fee3_desc__c,Old_Utilisation_Fee4_desc__c,opportunity_id__c,Opportunity_Product_Id__c,Oppties_Threats_Related_To_The_Deal__c,Other_Fees_desc__c,
                     Other_Relevant_Information_desc__c,Other_Relevant_Issues_desc__c,Other_Relevant_Ratios_desc__c,Past_FY_Cash_Management_amount__c,Past_FY_Client_Resources_amount__c,Past_FY_Corp_Synd_Lending_amount__c,Past_FY_Credit_Equity_amount__c,Past_FY_DCM_amount__c,Past_FY_ECM_M_A_Amount__c,Past_FY_FX_CCS_amount__c,Past_FY_GTF_amount__c,Past_FY_Rates_amount__c,Past_FY_RORC_per__c,Past_FY_Securities_Services_amount__c,
                     Past_FY_Structured_Finance_amount__c,Past_FY_Total_Non_X_Sell_amount__c,Past_FY_Total_Revenues_amount__c,Past_FY_Total_X_Sell_amount__c,Past_FY_Working_Capital_amount__c,Pending_approval_type__c,Product_Purpose_desc__c,Project_Sponsor_desc__c,Project_s_Tail1_number__c,Project_s_Tail2_number__c,Project_s_Tail3_number__c,Project_s_Tail4_number__c,Provision_by_Bank_of_Spain_per__c,Purpose_desc__c,
                     Qualitative_Assesment_of_X_Sell_Rev_desc__c,Qual_Assessment_of_Estimate_Revenue_desc__c,RaR_Approval_from_type__c,RAR_FY_Avg_life_per__c,RAR_Past_FY_per__c,RAR_YTD_per__c,Rating_Scenarios_desc__c,Rating_Scenario_desc__c,RecordTypeId,RecordType.Name,Relationship_Status_desc__c,Reputational_Risk_type__c,cust_fee_tier1_amount__c,cust_fee_tier2_amount__c,cust_fee_tier3_amount__c,cust_fee_tier4_amount__c,Revenues_Current_Year_number__c,Revenues_Last_Year_number__c,Revenues_Next_Year_1_number__c,Revenues_Next_Year_2_number__c,
                     Revenues_Next_Year_number__c,Risk_Opinion_type__c,Role_of_BBVA1_desc__c,Role_of_BBVA2_desc__c,Role_of_BBVA3_desc__c,Role_of_BBVA4_desc__c,RORC_FY_Avg_life_per__c,Sectorial_Norms_type__c,Security_Package_desc__c,Sponsor_s_Name_Fiscal_ID_desc__c,SPPI_Test_type__c,Standalone_RaR1_number__c,Standalone_RaR2_number__c,Standalone_RaR3_number__c,Standalone_RaR4_number__c,Standalone_RORC1_number__c,Standalone_RORC2_number__c,
                     Standalone_RORC3_number__c,Standalone_RORC4_number__c,Sub_limit_desc__c,Sub_limit_if_any1_number__c,Sub_limit_if_any2_number__c,Sub_limit_if_any3_number__c,Sub_limit_if_any4_number__c,Sustainable_Deal_type__c,Sustainable_Finance_Opinion_Provide_desc__c,Syndicate_Support_type__c,Syndication_Opinion_type__c,SystemModstamp,Template_approved_type__c,Tenor_desc__c,Tenor_number__c,Tenor_Years1_number__c,Tenor_Years2_number__c,
                     Tenor_Years3_number__c,Tenor_Years4_number__c,Third_Party_opinion_certification_type__c,Tiering_Action_type__c,Tier_1_Economics_number__c,Tier_1_N_Banks_number__c,Tier_1_Ticket_Mn_number__c,Tier_2_Economics_number__c,Tier_2_N_Banks_number__c,Tier_2_Ticket_Mn_number__c,Tier_3_Economics_number__c,Tier_3_N_Banks_number__c,Tier_3_Ticket_Mn_number__c,Tier_4_or_above_Economics_number__c,Tier_4_or_above_N_Banks_number__c,
                     Tier_4_or_above_Ticket_Mn_number__c,/*Tier_desc__c,*/curncy_trans_year_one_type__c,curncy_trans_year_two_type__c,curncy_trans_year_three_type__c,curncy_trans_year_four_type__c,Transaction_Deal_Amount1_number__c,Transaction_Deal_Amount2_number__c,Transaction_Deal_Amount3_number__c,Transaction_Deal_Amount4_number__c,Transaction_Type1_desc__c,Transaction_Type2_desc__c,Transaction_Type3_desc__c,Transaction_Type4_desc__c,
                     Type_of_Deal_desc__c,Underwriting1_desc__c,Underwriting2_desc__c,Underwriting3_desc__c,Underwriting4_desc__c,Underwriting_desc__c,Underwriting_type__c,Uses_num_1_number__c,Uses_num_2_number__c,Uses_num_3_number__c,Uses_num_4_number__c,Uses_num_5_number__c,Uses_num_6_number__c,Uses_num_7_number__c,Uses_num_8_number__c,Uses_num_9_number__c,Uses_num_10_number__c,Uses_num_11_number__c,Uses_text_2_desc__c,
                     Uses_text_3_desc__c,Uses_text_4_desc__c,gf_ead_tranche_1_amount__c,gf_ead_tranche_2_amount__c,gf_ead_tranche_3_amount__c,gf_ead_tranche_4_amount__c,Uses_text_5_desc__c,Uses_text_6_desc__c,Uses_text_7_desc__c,Uses_text_8_desc__c,Uses_text_9_desc__c,Uses_text_10_desc__c,Uses_text_11_desc__c,Uses_text_desc__c,Uses_Total_number__c,YTD_RORC_per__c, opportunity_id__r.Account.DES_Revenue_Update_Engloba__c, opportunity_id__r.Account.DES_RAR_EVA_RORC_Update_Engloba__c, opportunity_id__r.NBC_Decision_Taken_type__c
                     ,gf_esg_score_close_ope_name__c, gf_co_list_tcfd_ind_type__c, gf_paris_agreement_ind_type__c, gf_customer_sustnbl_strg_desc__c, gf_pitch_oppy_l12m_ibf_desc__c, gf_pitch_oppy_l12m_gm_desc__c, gf_pitch_oppy_l12m_gtb_desc__c, gf_equator_princ_catg_type__c, gf_crr_social_env_project_type__c, gf_sustnbl_proyect_cmnt_desc__c
                     , gf_green_proj_sustnbl_ind_type__c, gf_env_sustnbl_activity_name__c, gf_env_sustnbl_agency_ind_type__c, gf_green_bond_project_ind_type__c, gf_ngreen_rduc_carbon_ind_type__c, gf_ngreen_act_rduc_carbon_desc__c, gf_social_project_ind_type__c, gf_social_project_desc__c, gf_socl_sustnbl_agncy_ind_type__c, gf_socl_green_bond_ind_type__c, gf_sustnbl_loan_corp_ind_type__c, gf_sustainability_value_name__c, gf_sust_sustnbl_agncy_ind_type__c
                     ,gf_bldgs_env_carbon_ind_type__c, gf_bldgs_carbon_env_impc_desc__c, gf_bldgs_env_ncarbon_ind_type__c, gf_bldgs_ncarbon_env_impc_desc__c, gf_neutral_env_impc_ind_type__c
                     , gf_old_interest_rate_tr1_desc__c, gf_old_interest_rate_tr2_desc__c, gf_old_interest_rate_tr3_desc__c, gf_old_interest_rate_tr4_desc__c, gf_new_interest_rate_tr1_desc__c, gf_new_interest_rate_tr2_desc__c, gf_new_interest_rate_tr3_desc__c, gf_new_interest_rate_tr4_desc__c, gf_xb_cust_ope_revenue_ly_per__c, gf_xb_cust_ope_revenue_cyr_per__c, gf_xb_cust_ope_revenue_nxy_per__c, gf_end_user_ind_type__c
                     , gf_xb_cust_ope_revenue_2ya_per__c, gf_kpi_trans_fees_ly_amount__c, gf_kpi_trans_fees_cyr_amount__c, gf_kpi_trans_fees_nxy_amount__c, gf_kpi_trans_fees_2ya_amount__c,gf_risk_ases_user_cmnt_desc__c, gf_prohibited_actvy_ind_type__c,gf_corp_transaction_ind_type__c , gf_high_risk_country_ind_type__c, gf_public_law_corp_ind_type__c, cstk_tri_engagement_plan__c, cstk_tri__c, cstk_cca__c, cstk_cta__c, cstk_group_alignment_degree__c, cstk_sector_alignment_degree__c, cstk_emissions_intensity__c, cstk_emissions_intensity_units__c, cstk_sector_affected__c, cstk_positioning__c, cstk_g_thermal_coal_exps_ind_type__c, cstk_g_thermal_coal_exps_i_src_type__c, cstk_g_coal_prgrsv_red_pl_ind_type__c, cstk_gf_thermal_coal_rev_wg_per__c, cstk_gf_thermal_coal_prod_wg_per__c, cstk_sust_indicators_comments__c
                     ,Next2_FY_Corp_Synd_Lending_amount__c,Next2_FY_Structured_Finance_amount__c,Next2_FY_Str_Trade_Finance_amount__c,Next2_FY_Rates_amount__c, Next2_FY_GTF_amount__c,Next2_FY_Working_Capital_amount__c,Next2_FY_Total_Non_X_Sell_amount__c,Next2_FY_ECM_M_A_amount__c,Next2_FY_DCM_amount__c,Next2_FY_Credit_Equity_amount__c,Next2_FY_FX_CCS_amount__c,Next2_FY_Cash_Management_amount__c,Next2_FY_Client_Resources_amount__c,Next2_FY_Securities_Services_amount__c,Next2_FY_Total_X_Sell_amount__c,Next2_FY_Total_Revenues_amount__c,gf_xb_cust_ope_revenue_nxy2_per__c,gf_kpi_trans_fees_nxy2_amount__c
                     FROM DES_Template__c where id = :templId];

      templ = [SELECT id, gf_old_interest_rate_tr1_desc__c, gf_old_interest_rate_tr2_desc__c, gf_old_interest_rate_tr3_desc__c, gf_old_interest_rate_tr4_desc__c, gf_new_interest_rate_tr1_desc__c, gf_new_interest_rate_tr2_desc__c, gf_high_risk_country_ind_type__c, gf_corp_transaction_ind_type__c, gf_new_interest_rate_tr3_desc__c, gf_prohibited_actvy_ind_type__c, gf_public_law_corp_ind_type__c, gf_new_interest_rate_tr4_desc__c, gf_xb_cust_ope_revenue_ly_per__c, gf_xb_cust_ope_revenue_cyr_per__c, gf_xb_cust_ope_revenue_nxy_per__c, gf_xb_cust_ope_revenue_2ya_per__c, gf_kpi_trans_fees_ly_amount__c, gf_kpi_trans_fees_cyr_amount__c, gf_kpi_trans_fees_nxy_amount__c, gf_kpi_trans_fees_2ya_amount__c, gf_ead_tranche_1_amount__c,gf_ead_tranche_2_amount__c,gf_ead_tranche_3_amount__c,gf_ead_tranche_4_amount__c,gf_esg_score_close_ope_name__c,Past2_FY_Str_Trade_Finance_amount__c,Past_FY_Str_Trade_Finance_amount__c,Current_FY_Str_Trade_Finance_amount__c,Next_FY_Str_Trade_Finance_amount__c, gf_co_list_tcfd_ind_type__c	,Sustainable_Deal_type__c, gf_bldgs_env_carbon_ind_type__c, gf_bldgs_carbon_env_impc_desc__c, gf_bldgs_env_ncarbon_ind_type__c, gf_bldgs_ncarbon_env_impc_desc__c, gf_neutral_env_impc_ind_type__c, gf_green_proj_sustnbl_ind_type__c, gf_env_sustnbl_activity_name__c, gf_env_sustnbl_agency_ind_type__c, gf_green_bond_project_ind_type__c, gf_ngreen_rduc_carbon_ind_type__c,
      gf_ngreen_act_rduc_carbon_desc__c, gf_social_project_ind_type__c, gf_social_project_desc__c, gf_socl_sustnbl_agncy_ind_type__c, gf_socl_green_bond_ind_type__c, gf_sustnbl_loan_corp_ind_type__c, gf_sustainability_value_name__c, gf_sust_sustnbl_agncy_ind_type__c, gf_paris_agreement_ind_type__c, gf_customer_sustnbl_strg_desc__c, gf_pitch_oppy_l12m_ibf_desc__c, gf_pitch_oppy_l12m_gm_desc__c, Sectorial_Norms_type__c, Equator_Principles_type__c, Sustainable_Finance_Opinion_Provide_desc__c, Reputational_Risk_type__c, gf_pitch_oppy_l12m_gtb_desc__c, gf_equator_princ_catg_type__c, gf_crr_social_env_project_type__c, gf_sustnbl_proyect_cmnt_desc__c, Revenues_Year_number__c, EBITDA_Next_Year_number__c, Revenues_Last_Year_number__c, EBITDA_Last_Year_number__c, Revenues_Current_Year_number__c, Revenues_Next_Year_number__c, Revenues_Next_Year_1_number__c, Revenues_Next_Year_2_number__c, EBITDA_Current_Year_number__c, EBITDA_Next_Year_1_number__c, EBITDA_Next_Year_2_number__c, EBIT_Last_Year_number__c, EBIT_Current_Year_number__c, EBIT_Next_Year_number__c, EBIT_Next_Year_1_number__c, EBIT_Next_Year_2_number__c, Net_Income_Last_Year_number__c, Net_Income_Current_Year_number__c, Net_Income_Next_Year_number__c,gf_end_user_ind_type__c, Net_Income_Next_Year_1_number__c, Net_Income_Next_Year_2_number__c, Free_Cash_Flow_Last_Year_number__c, Free_Cash_Flow_Current_Year_number__c,
      Free_Cash_Flow_Next_Year_number__c, Free_Cash_Flow_Next_Year_1_number__c, Free_Cash_Flow_Next_Year_2_number__c, Debt_EBITDA_Last_Year_number__c, Debt_EBITDA_Current_Year_number__c, Debt_EBITDA_Next_Year_number__c, Debt_EBITDA_Next_Year_1_number__c, Debt_EBITDA_Next_Year_2_number__c, Net_Debt_EBITDA_Last_Year_number__c, Net_Debt_EBITDA_Current_Year_number__c, Net_Debt_EBITDA_Next_Year_number__c, Net_Debt_EBITDA_Next_Year_1_number__c, Net_Debt_EBITDA_Next_Year_2_number__c, Transaction_Type1_desc__c, Transaction_Type2_desc__c, Transaction_Type3_desc__c, Transaction_Type4_desc__c, Transaction_Deal_Amount1_number__c, Transaction_Deal_Amount2_number__c, Transaction_Deal_Amount3_number__c, Transaction_Deal_Amount4_number__c, curncy_trans_year_one_type__c, curncy_trans_year_two_type__c, curncy_trans_year_three_type__c, curncy_trans_year_four_type__c, Role_of_BBVA1_desc__c, Role_of_BBVA2_desc__c, Role_of_BBVA3_desc__c, Role_of_BBVA4_desc__c, Underwriting1_desc__c, Underwriting2_desc__c, Underwriting3_desc__c, Underwriting4_desc__c, BBVA_Commitment1_number__c, BBVA_Commitment2_number__c, BBVA_Commitment3_number__c, BBVA_Commitment4_number__c, Expected_Final_Take1_number__c, Expected_Final_Take2_number__c, Expected_Final_Take3_number__c, Expected_Final_Take4_number__c, Sub_limit_desc__c, Sub_limit_if_any1_number__c, Sub_limit_if_any2_number__c, Sub_limit_if_any3_number__c,
      Sub_limit_if_any4_number__c, New_Money_for_BBVA1_desc__c, New_Money_for_BBVA2_desc__c, New_Money_for_BBVA3_desc__c, New_Money_for_BBVA4_desc__c, Old_Money_for_BBVA1_desc__c, Old_Money_for_BBVA2_desc__c, Old_Money_for_BBVA3_desc__c, Old_Money_for_BBVA4_desc__c, Maturity_door_to_door1_number__c, Maturity_door_to_door2_number__c, Maturity_door_to_door3_number__c, Maturity_door_to_door4_number__c, Availability_Period1_number__c, Availability_Period2_number__c, Availability_Period3_number__c, Availability_Period4_number__c, Tenor_Years1_number__c, Tenor_Years2_number__c, Tenor_Years3_number__c, Tenor_Years4_number__c, Average_Life1_number__c, Average_Life2_number__c, Average_Life3_number__c, Average_Life4_number__c, Project_s_Tail1_number__c, Project_s_Tail2_number__c, Project_s_Tail3_number__c, Project_s_Tail4_number__c, DSCR1_number__c, DSCR2_number__c, DSCR3_number__c, DSCR4_number__c, Leverage_Ratio1_number__c, Leverage_Ratio2_number__c, Leverage_Ratio3_number__c, Leverage_Ratio4_number__c, Standalone_RaR1_number__c, Standalone_RORC1_number__c, Standalone_RaR2_number__c, Standalone_RORC2_number__c, Standalone_RaR3_number__c, Standalone_RORC3_number__c, Standalone_RaR4_number__c, Standalone_RORC4_number__c, Old_Up_Front_Fee1_desc__c, New_Up_Front_Fee1_desc__c, Old_Up_Front_Fee2_desc__c, New_Up_Front_Fee2_desc__c, Old_Up_Front_Fee3_desc__c, New_Up_Front_Fee3_desc__c,
      Old_Up_Front_Fee4_desc__c, New_Up_Front_Fee4_desc__c, Old_Up_Front_Fee_NonAccrual1_desc__c, New_Up_Front_Fee_NonAccrual1_desc__c, Old_Up_Front_Fee_NonAccrual2_desc__c, New_Up_Front_Fee_NonAccrual2_desc__c, Old_Up_Front_Fee_NonAccrual3_desc__c, New_Up_Front_Fee_NonAccrual3_desc__c, Old_Up_Front_Fee_NonAccrual4_desc__c, New_Up_Front_Fee_NonAccrual4_desc__c, Old_Funding_cost1_desc__c, New_Funding_Cost1_desc__c, Old_Funding_cost2_desc__c, New_Funding_Cost2_desc__c, Old_Funding_cost3_desc__c, New_Funding_Cost3_desc__c, Old_Funding_cost4_desc__c, New_Funding_Cost4_desc__c, Old_Liquidity_fee1_desc__c, New_Liquidity_Fee1_desc__c, Old_Liquidity_fee2_desc__c, New_Liquidity_Fee2_desc__c, Old_Liquidity_fee3_desc__c, New_Liquidity_Fee3_desc__c, Old_Liquidity_fee4_desc__c, New_Liquidity_Fee4_desc__c, Old_Applicable_Margin1_desc__c, New_Applicable_Margin1_desc__c, Old_Applicable_Margin2_desc__c, New_Applicable_Margin2_desc__c, Old_Applicable_Margin3_desc__c, New_Applicable_Margin3_desc__c, Old_Applicable_Margin4_desc__c, New_Applicable_Margin4_desc__c, Old_Pricing_Grid_Step_Up1_desc__c, New_Pricing_Grid_Step_Up1_desc__c, Old_Pricing_Grid_Step_Up2_desc__c, New_Pricing_Grid_Step_Up2_desc__c, Old_Pricing_Grid_Step_Up3_desc__c, New_Pricing_Grid_Step_Up3_desc__c, Old_Pricing_Grid_Step_Up4_desc__c, New_Pricing_Grid_Step_Up4_desc__c, Old_Commitment_Fee1_desc__c, New_Commitment_Fee1_desc__c,
      Old_Commitment_Fee2_desc__c, New_Commitment_Fee2_desc__c, Old_Commitment_Fee3_desc__c, New_Commitment_Fee3_desc__c, Old_Commitment_Fee4_desc__c, New_Commitment_Fee4_desc__c, Old_Utilisation_Fee1_desc__c, New_Utilisation_Fee1_desc__c, Old_Utilisation_Fee2_desc__c, New_Utilisation_Fee2_desc__c, Old_Utilisation_Fee3_desc__c, New_Utilisation_Fee3_desc__c, Old_Utilisation_Fee4_desc__c, New_Utilisation_Fee4_desc__c, Old_Extension_Duration_Fee1_desc__c, New_Extension_Duration_Fee1_desc__c, Old_Extension_Duration_Fee2_desc__c, New_Extension_Duration_Fee2_desc__c, Old_Extension_Duration_Fee3_desc__c, New_Extension_Duration_Fee3_desc__c, Old_Extension_Duration_Fee4_desc__c, New_Extension_Duration_Fee4_desc__c, Other_Fees_desc__c, Old_Other_Fees1_desc__c, New_Other_Fees1_desc__c, Old_Other_Fees2_desc__c, New_Other_Fees2_desc__c, Old_Other_Fees3_desc__c, New_Other_Fees3_desc__c, Old_Other_Fees4_desc__c, New_Other_Fees4_desc__c, Old_Expected_Drawn1_desc__c, New_Expected_Drawn1_desc__c, Old_Expected_Drawn2_desc__c, New_Expected_Drawn2_desc__c, Old_Expected_Drawn3_desc__c, New_Expected_Drawn3_desc__c, Old_Expected_Drawn4_desc__c, New_Expected_Drawn4_desc__c, Old_All_in_Drawn1_desc__c, New_All_in_Drawn1_desc__c, Old_All_in_Drawn2_desc__c, New_All_in_Drawn2_desc__c, Old_All_in_Drawn3_desc__c, New_All_in_Drawn3_desc__c, Old_All_in_Drawn4_desc__c, New_All_in_Drawn4_desc__c, Old_All_in_Undrawn1_desc__c,
      New_All_in_Undrawn1_desc__c, Old_All_in_Undrawn2_desc__c, New_All_in_Undrawn2_desc__c, Old_All_in_Undrawn3_desc__c, New_All_in_Undrawn3_desc__c, Old_All_in_Undrawn4_desc__c, New_All_in_Undrawn4_desc__c, Past2_FY_Corp_Synd_Lending_amount__c, Past_FY_Corp_Synd_Lending_amount__c, Current_FY_Corp_Synd_Lending_amount__c, Next_FY_Corp_Synd_Lending_amount__c, Past2_FY_Structured_Finance_amount__c, Past_FY_Structured_Finance_amount__c, Current_FY_Structured_Finance_amount__c, Next_FY_Structured_Finance_amount__c, Past2_FY_Rates_amount__c, Past_FY_Rates_amount__c, Current_FY_Rates_amount__c, Next_FY_Rates_amount__c, Past2_FY_GTF_amount__c, Past_FY_GTF_amount__c, Current_FY_GTF_amount__c, Next_FY_GTF_amount__c, Past2_FY_Working_Capital_amount__c, Past_FY_Working_Capital_amount__c, Current_FY_Working_Capital_amount__c, Next_FY_Working_Capital_amount__c, Past2_FY_Total_Non_X_Sell_amount__c, Past_FY_Total_Non_X_Sell_amount__c, Current_FY_Total_Non_X_Sell_amount__c, Next_FY_Total_Non_X_Sell_amount__c, Past2_FY_ECM_M_A_Amount__c, Past_FY_ECM_M_A_Amount__c, Current_FY_ECM_M_A_Amount__c, Next_FY_ECM_M_A_amount__c, Past2_FY_DCM_amount__c, Past_FY_DCM_amount__c, Current_FY_DCM_amount__c, Next_FY_DCM_amount__c, Past2_FY_Credit_Equity_amount__c, Past_FY_Credit_Equity_amount__c, Current_FY_Credit_Equity_amount__c, Next_FY_Credit_Equity_amount__c, Past2_FY_FX_CCS_amount__c, Past_FY_FX_CCS_amount__c,
      Current_FY_FX_CCS_amount__c, Next_FY_FX_CCS_amount__c, Past2_FY_Cash_Management_amount__c, Past_FY_Cash_Management_amount__c, Current_FY_Cash_Management_amount__c, Next_FY_Cash_Management_amount__c, Past2_FY_Client_Resources_amount__c, Past_FY_Client_Resources_amount__c, Current_FY_Client_Resources_amount__c, Next_FY_Client_Resources_amount__c, Past2_FY_Securities_Services_amount__c, Past_FY_Securities_Services_amount__c, Current_FY_Securities_Services_amount__c, Next_FY_Securities_Services_amount__c, Past2_FY_Total_X_Sell_amount__c, Past_FY_Total_X_Sell_amount__c, Current_FY_Total_X_Sell_amount__c, Next_FY_Total_X_Sell_amount__c, Past2_FY_Total_Revenues_amount__c, Past_FY_Total_Revenues_amount__c, Current_FY_Total_Revenues_amount__c, Next_FY_Total_Revenues_amount__c, Debt_Funds_Text_1_desc__c, Debt_Funds_Num_1_number__c, Uses_text_desc__c, Uses_num_1_number__c, Debt_Funds_Text_2_desc__c, Debt_Funds_Num_2_number__c, Uses_text_2_desc__c, Uses_num_2_number__c, Debt_Funds_text_3_desc__c, Debt_Funds_Num_3_number__c, Uses_text_3_desc__c, Uses_num_3_number__c, Debt_Funds_text_4_desc__c, Debt_Funds_Num_4_number__c, Uses_text_4_desc__c, Uses_num_4_number__c, Debt_Funds_Text_5_desc__c, Debt_Funds_Num_5_number__c, Uses_text_5_desc__c, Uses_num_5_number__c, Debt_Funds_Total_number__c, Uses_text_6_desc__c, Uses_num_6_number__c, Uses_text_7_desc__c, Uses_num_7_number__c,
      Equity_Funds_text_1_desc__c, Equity_Funds_num_1_number__c, Uses_text_8_desc__c, Uses_num_8_number__c, Equity_Funds_text_2_desc__c, Equity_Funds_num_2_number__c, Uses_text_9_desc__c, Uses_num_9_number__c, Equity_Funds_text_3_desc__c, Equity_Funds_num_3_number__c, Uses_text_10_desc__c, Uses_num_10_number__c, Equity_Funds_text_4_desc__c, Equity_Funds_num_4_number__c, Uses_text_11_desc__c, Uses_num_11_number__c, Equity_Funds_Total_number__c, Uses_Total_number__c, Parent_Template__c, cstk_tri_engagement_plan__c, cstk_tri__c, cstk_cca__c, cstk_cta__c, cstk_group_alignment_degree__c, cstk_sector_alignment_degree__c, cstk_emissions_intensity__c, cstk_emissions_intensity_units__c, cstk_sector_affected__c, cstk_positioning__c, cstk_g_thermal_coal_exps_ind_type__c, cstk_g_thermal_coal_exps_i_src_type__c, cstk_g_coal_prgrsv_red_pl_ind_type__c, cstk_gf_thermal_coal_rev_wg_per__c, cstk_gf_thermal_coal_prod_wg_per__c, cstk_sust_indicators_comments__c ,Next2_FY_Corp_Synd_Lending_amount__c,Next2_FY_Structured_Finance_amount__c,Next2_FY_Str_Trade_Finance_amount__c,Next2_FY_Rates_amount__c, Next2_FY_GTF_amount__c,Next2_FY_Working_Capital_amount__c,Next2_FY_Total_Non_X_Sell_amount__c,Next2_FY_ECM_M_A_amount__c,Next2_FY_DCM_amount__c,Next2_FY_Credit_Equity_amount__c,Next2_FY_FX_CCS_amount__c,Next2_FY_Cash_Management_amount__c,Next2_FY_Client_Resources_amount__c,Next2_FY_Securities_Services_amount__c,Next2_FY_Total_X_Sell_amount__c,Next2_FY_Total_Revenues_amount__c,gf_xb_cust_ope_revenue_nxy2_per__c,gf_kpi_trans_fees_nxy2_amount__c
      FROM DES_Template_Table__c WHERE Parent_Template__c = :templId];

      templ.need_Update__c =  true;

      lFields1 = getFieldSetFromTemplate (template.Id, 'Sustainable_Client_information'); //NOSONAR
      lFields3 = getFieldSetFromTemplate (template.Id, 'Sustainable_Assessment'); //NOSONAR
      lFields2Y = getFieldSetFromTemplate (template.Id, 'Sustainable_Transaction_Y'); //NOSONAR
      lFields2N = getFieldSetFromTemplate (template.Id, 'Sustainable_Transaction_N'); //NOSONAR

      desciption1 = 'Brief description of client’s sustainability strategy (can include plans for a transition to a low carbon economy/meeting the Paris Agreement, international sustainability commitments, green investments or relevant divestments, etc.)';
      desciption3 = 'Brief description of sustainable finance pitches to the client in the last 12 months and opportunities identified.';
      greenFields = 'gf_env_sustnbl_activity_name__c, gf_env_sustnbl_agency_ind_type__c, gf_green_bond_project_ind_type__c';
      transFields = 'gf_ngreen_act_rduc_carbon_desc__c';
      socialFields = 'gf_social_project_desc__c,gf_socl_sustnbl_agncy_ind_type__c,gf_socl_green_bond_ind_type__c';
      sustainFields = 'gf_sustainability_value_name__c,gf_sust_sustnbl_agncy_ind_type__c,cstk_g_thermal_coal_exps_ind_type__c, cstk_g_thermal_coal_exps_i_src_type__c, cstk_g_coal_prgrsv_red_pl_ind_type__c, cstk_gf_thermal_coal_rev_wg_per__c, cstk_gf_thermal_coal_prod_wg_per__c';
      carbonFields = 'gf_bldgs_carbon_env_impc_desc__c';
      otherFields = 'gf_bldgs_ncarbon_env_impc_desc__c';

    }

    if((parentTempl.opportunity_id__r.NBC_Decision_Taken_type__c == Label.NBC_Decision_Recommended || parentTempl.opportunity_id__r.NBC_Decision_Taken_type__c == Label.NBC_Decision_Not_Recommended) && profileName != Label.DES_ADMIN_PROFILE && profileName != Label.DES_SP_PROFILE) {
      disabled = 'true';
    } else if(parentTempl.opportunity_id__r.NBC_Decision_Taken_type__c == Label.NBC_Decision_Pending) {
      disabled = 'false';
    } else if(parentTempl.opportunity_id__r.NBC_Decision_Taken_type__c == null) {
      if((parentTempl.Pending_approval_type__c || parentTempl.Template_approved_type__c) && profileName != Label.DES_ADMIN_PROFILE && profileName != Label.DES_SP_PROFILE) {
        disabled = 'true';
      } else {
        disabled = 'false';
      }
    }

    if(parentTempl.Revenues_Year_number__c == null) {
      parentTempl.Revenues_Year_number__c = Date.today().year()-1;
    }


    recordTypeName = Schema.SObjectType.DES_Template__c.getRecordTypeInfosById().get(parentTempl.RecordTypeId).getDeveloperName();

    yearTable = date.today().year();

    dateRARRORC = parentTempl.opportunity_id__r.Account.DES_RAR_EVA_RORC_Update_Engloba__c;
    yearRARRORCTable = date.today().year();

    if(dateRARRORC != null) {
      yearRARRORC = dateRARRORC.substring(0,4);
      yearRARRORCTable = Integer.valueof(yearRARRORC);
    }

    // Verify if booking is equals compass
    system.debug('>>>>> ');
    //String book = Util_PickList.getLabelFromAPI('Opportunity', 'DES_Booking_Geography__c').get(parentTempl.Booking_type__c);
    booking = Util_PickList.getLabelFromAPI('Opportunity', 'DES_Booking_Geography__c').get(parentTempl.Booking_type__c);
    isCompass = booking == 'Compass' ? true : false;
    system.debug('>>>>> parentTempl.Booking_type__c : ' + parentTempl.Booking_type__c);
    system.debug('>>>>> booking : ' + booking);
    system.debug('>>>>> isCompass : ' + isCompass);
  }

  /* Guarda template Table*/
  public void saveBasicFinancials() {
    system.debug('>>>>> templ : ' + templ);
    saveOnChangeField(TemplateVF_ControllerHandler.saveBasicFinancials(templ));
    system.debug('>>>>> templ : ' + templ);
  }

  /* Guarda template Table*/
  public void saveBusinessPlan() {
    saveOnChangeField(TemplateVF_ControllerHandler.saveBusinessPlan(templ));
  }

  /* Guarda template Table*/
  public void saveGlobalStructure() {
    saveOnChangeField(TemplateVF_ControllerHandler.saveGlobalStructure(templ));
  }

  /* Guarda template Table*/
  public void saveTransactionOverview() {
    saveOnChangeField(TemplateVF_ControllerHandler.saveTransactionOverview(templ));
  }

  /* Guarda template Table*/
  public void saveSustainable() {
    saveOnChangeField(TemplateVF_ControllerHandler.saveSustainableDeal(templ));
  }



  /*
  * Sutainable Finance Section
  */
  public List<FieldSetMemberWrapperClass> getFieldSetFromTemplate (String templateID, String fieldSet) {
    NonCLientWrapperClass wrpNonclient;
    wrpNonclient = new NonCLientWrapperClass();
    List<FieldSetMemberWrapperClass> wrapperList;
    wrapperList = new List<FieldSetMemberWrapperClass>();
    String objectName;
    objectName = 'DES_template__c';
    String recorText;
    recorText = 'RecordTypeId';
    String boolText;
    boolText = 'BOOLEAN';
    System.debug(recorText+':'+boolText);
    List<String> lFields;
    lFields = new List<String>();

    Schema.SObjectType sObj;
    sObj = Schema.getGlobalDescribe().get(objectName);

    List<DES_Template__c> lTemplate;
    lTemplate = [SELECT id, RecordTypeId FROM DES_template__c WHERE id = :templateID];
    String idRecordType;
    idRecordType = lTemplate.get(0).RecordTypeId;

    try {
      String fieldSetName;
      fieldSetName = fieldSet;

      for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(fieldSetName).getFields()) {
        FieldSetMemberWrapperClass wrapper;
        wrapper = new FieldSetMemberWrapperClass();
        wrapper.isDBRequired = fieldMember.getDbRequired();
        wrapper.isRequired = fieldMember.getRequired();
        wrapper.fieldType = String.valueOf(fieldMember.getType());
        wrapper.fieldLabel = fieldMember.getLabel();
        wrapper.fieldAPIName = fieldMember.getFieldPath();
        wrapper.isValidationField = false;

        if(wrapper.fieldAPIName==recorText) {
          wrapper.fieldValue = idRecordType;
        }

        wrapperList.add(wrapper);
        lFields.add(wrapper.fieldAPIName);
        System.debug(wrapper.fieldAPIName);
      }
    } catch(Exception exc) {
      system.debug('exc ' + exc);
    }

    wrpNonclient.wrapperList = wrapperList;
    wrpNonclient.recordType = idRecordType;

	return wrapperList;
  }

  /* Guarda Toolkit Sector*/
  public void getToolkitSector(DES_Template__c template) {
    system.debug('>>>>> templ : ' + template);
    final DES_Template__c templateaux = [SELECT Id, opportunity_id__r.AccountId, opportunity_id__r.Account.DES_Main_Parent__c FROM DES_Template__c WHERE Id = :template.Id LIMIT 1];
    if (templateaux != null && templateaux.opportunity_id__r.Account.DES_Main_Parent__c != null) {
      final String accountParent = templateaux.opportunity_id__r.Account.DES_Main_Parent__c;
      final List<cstk__Toolkit__c> toolkits = [SELECT Id, cstk__account_id__r.DES_Group_Code__c, cstk__account_id__r.DES_Activity__c, cstk__account_id__r.DES_AGGR_Sector__c FROM cstk__Toolkit__c WHERE cstk__account_id__c = :accountParent LIMIT 1];
      if (!toolkits.isEmpty()) {
        final Map<String, Object> res = new Map<String, Object>(); //NOSONAR
        final String toolkitId = toolkits[0].Id; //NOSONAR
        final String groupCode = toolkits[0].cstk__account_id__r.DES_Group_Code__c;
        final List<arce__Account_has_Analysis__c> listaHasAcc = [SELECT id, name, DES_Local_Client__c, arce__WF_Stage_WF_Status__c, arce__Analysis__r.arce__wf_status_id__c, arce__Analysis__r.arce__Stage__c, IsDeleted, CreatedDate, DES_Local_Client__r.Cib_Client__r.Name, DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c
                                                                FROM arce__Account_has_Analysis__c
                                                                WHERE  arce__Analysis__r.arce__wf_status_id__c = '13' AND arce__Analysis__r.arce__Stage__c = '3' AND arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c in ('1','2') AND DES_Local_Client__r.Cib_Client__r.business_group_header_type__c = true AND DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c = :groupCode AND arce__Analysis__r.arce__rating_prerating_type__c = 'Rating'
                                                                ORDER BY arce__ffss_for_rating_id__r.arce__ffss_submitted_type__c ASC, CreatedDate DESC];    
        final cstk__toolkit_settings__mdt config = cstk.Utils.getGeneralConfiguration();
        final String sectorValues = config.cstk__toolkit_sector__c;
        final CSTK_Client.SectorWrapper allSectValues = (CSTK_Client.SectorWrapper)System.JSON.deserialize(sectorValues, CSTK_Client.SectorWrapper.class);
        String sectorPicklistLabel = Util_PickList.getLabelFromAPI('Account', 'DES_AGGR_Sector__c').get(toolkits[0].cstk__account_id__r.DES_AGGR_Sector__c);
        String activityPicklistLabel = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(toolkits[0].cstk__account_id__r.DES_Activity__c);

        if (!listaHasAcc.isEmpty()) {

          final List<AggregateResult> actSplitList = [SELECT toLabel(arce__sector_id__c), toLabel(arce__Subsector_id_2012__c), toLabel(arce__gf_company_economic_actvy_id_2012__c), SUM(arce__gf_subindustry_weight_per__c) sum_perc_activity
                                                      FROM arce__Activity_Split__c 
                                                      WHERE arce__Account_has_Analysis__c = :listaHasAcc[0].id
                                                      GROUP BY arce__sector_id__c, arce__Subsector_id_2012__c, arce__gf_company_economic_actvy_id_2012__c
                                                      ORDER BY SUM(arce__gf_subindustry_weight_per__c) DESC];
          final List<AggregateResult> listaGeos = [SELECT toLabel(arce__sector_id__c), toLabel(arce__Subsector_id__c), toLabel(arce__gf_company_economic_actvy_id__c), SUM(arce__gf_subindustry_weight_per__c) FROM arce__Activity_Split_2012__c WHERE arce__Account_has_Analysis__c =:listaHasAcc[0].id GROUP BY arce__sector_id__c, arce__Subsector_id__c, arce__gf_company_economic_actvy_id__c ORDER BY SUM(arce__gf_subindustry_weight_per__c) DESC];

          if (!actSplitList.isEmpty() && !String.isEmpty(String.valueOf(actSplitList[0].get('arce__sector_id__c')))){
            res.put('sector', CSTK_Utils.mapArceSector(String.valueOf(actSplitList[0].get('arce__sector_id__c')), String.valueOf(actSplitList[0].get('arce__Subsector_id_2012__c')), String.valueOf(actSplitList[0].get('arce__gf_company_economic_actvy_id_2012__c')), allSectValues.arceValues));
          } else if (!listaGeos.isEmpty()) {
            res.put('sector', CSTK_Utils.mapArceSector(String.valueOf(listaGeos[0].get('arce__sector_id__c')), String.valueOf(listaGeos[0].get('arce__Subsector_id__c')), String.valueOf(listaGeos[0].get('arce__gf_company_economic_actvy_id__c')), allSectValues.arceValues));
          } else {
            // KSAG-- Tiene sentido pasar el valor de  la label en este punto? o debería de ser el API? lo mismo en la otra linea
            res.put('sector', CSTK_Utils.mapClientSector(sectorPicklistLabel, activityPicklistLabel, allSectValues.clientValues));
          }
        } else {
          res.put('sector', CSTK_Utils.mapClientSector(sectorPicklistLabel, activityPicklistLabel, allSectValues.clientValues));
        }
        sectorToolkit = String.valueOf(res.get('sector')); //NOSONAR
        system.debug('>>>>> sector toolkit : ' + sectorToolkit);
      }
    }
  }


  /*
  *Wrapper Class
  */
  public class NonCLientWrapperClass {

    /*
    *Wrapper Field
    */
    @AuraEnabled
    public String recordType { get; set; }
    /*
    *Wrapper List
    */
    @AuraEnabled
    public List<FieldSetMemberWrapperClass> wrapperList { get; set; }

  }

  /*
  *Wrapper class
  */
  public class FieldSetMemberWrapperClass {
    /*
    *Wrapper Field
    */
    @AuraEnabled
    public Boolean isValidationField { get; set; }
    /*
    *Wrapper Field
    */
    @AuraEnabled
    public Boolean isDBRequired { get; set; }
    /*
    *Wrapper Field
    */
    @AuraEnabled
    public Boolean isRequired { get; set; }
    /*
    *Wrapper Field
    */
    @AuraEnabled
    public String fieldType { get; set; }
    /*
    *Wrapper Field
    */
    @AuraEnabled
    public String fieldLabel { get; set; }
    /*
    *Wrapper Field
    */
    @AuraEnabled
    public String fieldAPIName { get; set; }
    /*
    *Wrapper Field
    */
    @AuraEnabled
    public String fieldValue { get; set; }
    /*@AuraEnabled
    public List<Schema.PicklistEntry> pickListValues { get; set; }*/

  }
}