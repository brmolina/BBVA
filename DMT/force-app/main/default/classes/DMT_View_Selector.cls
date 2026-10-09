public without sharing  class DMT_View_Selector {

    public static List<Task> getTaskApprover(String taskId, String recordOrLineId){

        List<Task> taskRecord =  [SELECT Id, OwnerId, WhatId FROM Task WHERE Id =:taskId AND WhatId =: recordOrLineId WITH USER_MODE LIMIT 1];

        return taskRecord;
    }
    public static List<Case> getCaseApprover(String recordOrLineId){

        List<Case> caseRecord = [SELECT OwnerId, DMT_Line__c, opportunity_id__c,DMT_LineOpportunity__c, DMT_Line__r.RecordType.Name, DMT_Line__r.RecordType.DeveloperName
                                    FROM Case
                                    WHERE Id = :recordOrLineId OR DMT_Line__c =:recordOrLineId OR opportunity_id__c =:recordOrLineId
                                    WITH USER_MODE
                                    LIMIT 1];

        return caseRecord;
    }
    public static List<Group> getGroup(String owmnerView){

        List<Group> groupRecord = [SELECT DeveloperName FROM Group WHERE Id = :owmnerView  WITH USER_MODE LIMIT 1];

        return groupRecord;
    }
    public static Opportunity getOpportunityWithRelatedData(String recordId, String recordTypeDeveloperName){
        return [SELECT Id, Name, Entific__c, DMT_Entity__c, DMT_DATE_Initial_Date__c, DMT_DATE_Maturity_Date__c, DMT_CUR_Notional_Amount__c, DMT_Opp_Id__c,DMT_ContingentCommitments__c,
                    CurrencyIsoCode, RecordTypeId,RecordType.DeveloperName, Amount, DMT_requested_passport__c, Deal_total_amount__c, Des_product_name__c, Owner.Name, DMT_branch_id_c__c,DMT_GlobalBanker__c,
                    DMT_Capital_Action__c, DMT_Tenor__c, DMT_Threshold_Type__c,DMT_Product_Area__c, DMT_Sanction__c, DMT_CurrencyText__c, CloseDate,StageName,IsWon,IsClosed,DMT_Opportunity_amount__c,
                    bbva_prtcp_tranche_amount__c, DMT_Confidential__c ,
                    DMT_Booking_EFAN__c, DMT_SPPI_File_Uploaded__c, DMT_SPPI_Status__c, DMT_SPPI_User__c,
                    DMT_Financial_Sponsors__c, DMT_Structured_GTB__c, DMT_Credentials__c,
                    DMT_Under_X_Selling_Monitoring__c, DMT_NewClient__c,
                    // parent Account fields
                        AccountId, Account.DES_Structure_Type__c, Account.g_customer_id__c, Account.Name, Account.DES_Client_Type__c, Account.DES_Main_Parent__c,
                        Account.Current_FY_Corp_Synd_Lending_amount__c, Account.Current_FY_Structured_Finance_amount__c,
                        Account.Current_FY_Str_Trade_Finance_amount__c, Account.Current_FY_Rates_amount__c,
                        Account.Current_FY_GTF_amount__c, Account.Current_FY_Working_Capital_amount__c,
                        Account.Current_FY_Total_Non_X_Sell_amount__c, Account.Current_FY_ECM_M_A_Amount__c,
                        Account.Current_FY_DCM_amount__c, Account.Current_FY_Credit_Equity_amount__c,
                        Account.Current_FY_FX_CCS_amount__c, Account.Current_FY_Cash_Management_amount__c,
                        Account.Current_FY_Client_Resources_amount__c, Account.Current_FY_Securities_Services_amount__c,
                        Account.Current_FY_Total_X_Sell_amount__c, Account.Current_FY_Total_Revenues_amount__c,
                        Account.gf_xb_cust_ope_revenue_2ya_per__c, Account.gf_xb_cust_ope_revenue_ly_per__c,
                        Account.gf_xb_cust_ope_revenue_cyr_per__c, Account.gf_xb_cust_ope_revenue_nxy_per__c,
                        Account.gf_kpi_trans_fees_2ya_amount__c, Account.gf_kpi_trans_fees_ly_amount__c,
                        Account.gf_kpi_trans_fees_cyr_amount__c, Account.gf_kpi_trans_fees_nxy_amount__c,
                        Account.Revenues_Last_Year_number__c, Account.Revenues_Current_Year_number__c, Account.Revenues_Next_Year_number__c,
                        Account.Revenues_Next_Year_1_number__c, Account.Revenues_Next_Year_2_number__c, Account.EBITDA_Last_Year_number__c,
                        Account.EBITDA_Current_Year_number__c, Account.EBITDA_Next_Year_number__c, Account.EBITDA_Next_Year_1_number__c,
                        Account.EBITDA_Next_Year_2_number__c, Account.EBIT_Last_Year_number__c, Account.EBIT_Current_Year_number__c,
                        Account.EBIT_Next_Year_number__c, Account.EBIT_Next_Year_1_number__c, Account.EBIT_Next_Year_2_number__c,
                        Account.Net_Income_Last_Year_number__c, Account.Net_Income_Current_Year_number__c, Account.Net_Income_Next_Year_number__c,
                        Account.Net_Income_Next_Year_1_number__c, Account.Net_Income_Next_Year_2_number__c, Account.Free_Cash_Flow_Last_Year_number__c,
                        Account.Free_Cash_Flow_Current_Year_number__c, Account.Free_Cash_Flow_Next_Year_number__c, Account.Free_Cash_Flow_Next_Year_1_number__c,
                        Account.Free_Cash_Flow_Next_Year_2_number__c, Account.Debt_EBITDA_Last_Year_number__c, Account.Debt_EBITDA_Current_Year_number__c,
                        Account.Debt_EBITDA_Next_Year_number__c, Account.Debt_EBITDA_Next_Year_1_number__c,
                        Account.Debt_EBITDA_Next_Year_2_number__c, Account.Net_Debt_EBITDA_Last_Year_number__c, Account.Net_Debt_EBITDA_Current_Year_number__c,
                        Account.Net_Debt_EBITDA_Next_Year_number__c, Account.Net_Debt_EBITDA_Next_Year_1_number__c, Account.Net_Debt_EBITDA_Next_Year_2_number__c,
                        Account.DES_ID_Fiscal__c, Account.DES_Group_Code__c, Account.DES_Prospect_Client__c, Account.RecordTypeId,
                    // child X_sell__r
                    (
                        SELECT Id, Booking_Geography__c, XSELL_Value_PY__c, XSELL_Value_CY__c, XSELL_Value_NY__c, XSELL_Value_NY1__c FROM X_sell__r
                        ORDER BY CreatedDate ASC
                    ),
                    // child Deal_Team_Members__r
                    (
                        SELECT Full_Name_User__c, AccessLevel__c FROM Deal_Team_Members__r
                    ),
                    // child OpportunityLineItems
                    (
                        SELECT Id, life_funding_type__c, DMT_TXT_ProductNameOLI__c, gf_funding_cost_fb__c, productcode, gj_nominal_amount_db__c, gf_intermediate_date__c,
                        gf_crr2_essential_public_services__c, DMT_Deal_Amount_Tenors__c , gf_notional__c, deal_total_amount__c, funding_curve__c,
                        gf_social_bond__c, gf_global_product_id__c, gf_financing_type__c, gf_spread__c, currencyisocode, gf_initial_date__c, g_branch_id__c,
                        gf_amortization_type__c, gf_payment_frequency__c, gf_non_accrual_fees_bp__c, g_currency_id__c, gf_spread_fb__c, gf_entity_id__c,
                        gf_global_local_parametry_check__c, gf_funding_cost_db__c, gf_maturity_date__c, opportunityid, gf_accrual_fees_bp__c,
                        gf_spread_db__c, name, gf_tenor_date__c, gf_notional_otb__c, gf_nominal_amount_fb__c, gf_product_type_desc__c, gf_country_rating__c,
                        g_product_id__c, gf_green_bonus__c, gf_country_risk__c, des_product_name__c, DMT_Risk_Type__c, DMT_TXT_Comentarios__c,
                        Product2Id, Product2.Name, Product2.CurrencyIsoCode, DMT_Sustainability_bonus_eligible__c, 
                        Product2.ProductCode, Product2.DMT_Product_category__c, Product2.DMT_Product_Subcategory__c, Product2.DMT_Product_Subfamily__c,
                        Product2.DMT_Code_Level__c, Product2.dmt_global_product_id__c, Product2.Family, Product2.DMT_Product_family__c,
                        Product2.DMT_Classification_Level__c, DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DMT_ExpectedFinal_Take__c, DMT_Expected_Drawn__c,
                        DMT_Extension_Duration_Fees__c, DMT_PricingGrid_OR_StepUps__c, DES_Tenor_years__c,g_line_commitment_level_type__c, gf_group_priority_opportunity_id__c,
                        DMT_Deal_amount__c, bbva_prtcp_tranche_amount__c,DMT_Liquidity_Fee__c,DES_Commitment_Fees__c,DES_Other_Fees__c,entity_role_type__c,DMT_Sub_Limit__c,underwriting_agreement_type__c,
                        /* --- NEW FIELDS --- */
                        loan_purpose_desc__c, DMT_bullet_amortization_indicator__c, DMT_balloon_amortization_indicator__c,
                        DMT_sustainable_deal_assessment__c, DMT_Sustainable_Deal_Subtype__c, DMT_sustainable_deal_value__c, DMT_PER_Sustainability_Percentage__c,
                        DMT_Sustainability_deal_value_criteria__c, DMT_RateType__c, syndicated_loan_drawn_amount__c,
                        /* --- LINE / ONE-OFF DEAL FIELDS --- */
                        DMT_Line_Oneoffdeal__c, DMT_Line_Type__c, DMT_Line_Tenor__c, DMT_Line_Amount__c,
                        DMT_Commitment_Line_Amount__c, DMT_Reference_Upfront_Fees__c, DMT_Line_Currency__c, DMT_Use_of_Proceeds__c,
                        /* New Fields  type String  with populate field Number or Percent */
                        DMT_TXT_Commitment_Fees__c, DMT_Utilisation_Fee__c, DMT_TXT_Extension_Duration_Fees__c, DMT_TXT_Other_Fees_Accrual__c, DMT_TXT_Other_Fees_NonAccrual__c,

                        // child Opportunity_Mitigants__r
                        (
                            SELECT Id, CurrencyIsoCode, Name, Mitigant_Type__c, Commercial_Percentage__c, Political_Percentage__c,
                            External_Rating__c, Liquidation_Period__c, Counterpart__c, SCRA__c, AVC_Check__c,
                            Garantor_European_ECA__c, European_Bank_Check__c, DMT_Guarantor_Display__c,
                            End_Date__c, Internal_Rating__c, DMT_Currency__c, DMT_Country_Guarantor__c, DMT_Scoring__c
                            FROM Opportunity_Mitigants__r
                            ORDER BY CreatedDate
                        ),
                        // child Opportunity_Tenors__r
                        (
                            SELECT Id, CurrencyIsoCode, gf_tenor_date__c, gj_nominal_amount_db__c, gf_nominal_amount_fb__c, gf_spread_db__c, gf_spread_fb__c,
                            gf_accrual_fees_bp__c, gf_non_accrual_fees_bp__c
                            FROM Opportunity_Tenors__r ORDER BY CreatedDate ASC
                        ),
                        // child DMT_Opportunity_Money__r
                        (
                            SELECT Id, Name, DMT_All_in_Drawn__c, DMT_All_in_Undrawn__c, DMT_Applicable_Margin__c, DMT_Commitment_Fee__c, DMT_Expected_Drawn__c, DMT_Extension_Duration_Fee__c,
                            DMT_Funding_Cost__c, DMT_Interest_Rate_Period__c, DMT_Liquidity_Fee__c, DMT_Other_Fees_Accrual__c, DMT_Other_Fees_Non_Accrual__c, DMT_Other_Fees__c, 
                            DMT_Pricing_Grid_or_Step_ups__c, DMT_Up_Front_Fee_Accrual__c, DMT_Up_Front_Fee_Non_Accrual__c, DMT_Utilisation_Fee__c, DMT_Opportunity_Product__c,
                            DMT_Is_Old_Money__c
                            FROM Opportunity_Money__r
                        )
                        FROM OpportunityLineItems ORDER BY LastModifiedDate DESC
                    ),
                    // child DMT_MDE_Opportunities_Clients__r
                    (
                        SELECT Id, Alpha_Code_Client__c, External_Rating__c, Counterpart__c, Group_Sales_Check__c, g_upd_lmscl_internal_ratg_type__c, g_upd_smscl_internal_ratg_type__c, European_Bank_Check__c, SCRA__c, AVC_Check__c,
                        Revenues_Last_Year_number__c, Revenues_Current_Year_number__c, Revenues_Next_Year_number__c, Revenues_Next_Year_1_number__c, Revenues_Next_Year_2_number__c,
                        EBITDA_Last_Year_number__c, EBITDA_Current_Year_number__c, EBITDA_Next_Year_number__c, EBITDA_Next_Year_1_number__c, EBITDA_Next_Year_2_number__c,
                        EBIT_Next_Year_number__c, EBIT_Last_Year_number__c, EBIT_Current_Year_number__c, EBIT_Next_Year_1_number__c, EBIT_Next_Year_2_number__c,
                        Net_Income_Last_Year_number__c, Net_Income_Current_Year_number__c, Net_Income_Next_Year_number__c, Net_Income_Next_Year_1_number__c, Net_Income_Next_Year_2_number__c,
                        Free_Cash_Flow_Last_Year_number__c, Free_Cash_Flow_Current_Year_number__c, Free_Cash_Flow_Next_Year_number__c, Free_Cash_Flow_Next_Year_1_number__c, Free_Cash_Flow_Next_Year_2_number__c,
                        Debt_EBITDA_Last_Year_number__c, Debt_EBITDA_Current_Year_number__c, Debt_EBITDA_Next_Year_number__c, Debt_EBITDA_Next_Year_1_number__c, Debt_EBITDA_Next_Year_2_number__c,
                        Net_Debt_EBITDA_Last_Year_number__c, Net_Debt_EBITDA_Current_Year_number__c, Net_Debt_EBITDA_Next_Year_number__c, Net_Debt_EBITDA_Next_Year_1_number__c, Net_Debt_EBITDA_Next_Year_2_number__c,
                        Last_Year_Formula__c, Other_Relevant_Ratios_desc__c, cstk_sust_indicators_comments__c, Geographical_Footprint_desc__c, Relationship_Status_desc__c, Industry_Overview_desc__c,
                        Qualitative_Assesment_of_X_Sell_Rev_desc__c, gf_esg_score_close_ope_name__c, gf_co_list_tcfd_ind_type__c, gf_paris_agreement_ind_type__c, gf_customer_sustnbl_strg_desc__c,
                        gf_pitch_oppy_l12m_ibf_desc__c, gf_pitch_oppy_l12m_gm_desc__c, gf_pitch_oppy_l12m_gtb_desc__c,

                        Current_FY_Corp_Synd_Lending_amount__c, Next_FY_Corp_Synd_Lending_amount__c, Past_FY_Corp_Synd_Lending_amount__c, Past2_FY_Corp_Synd_Lending_amount__c,
                        Current_FY_Structured_Finance_amount__c, Next_FY_Structured_Finance_amount__c, Past_FY_Structured_Finance_amount__c, Past2_FY_Structured_Finance_amount__c,
                        Current_FY_Str_Trade_Finance_amount__c, Next_FY_Str_Trade_Finance_amount__c, Past_FY_Str_Trade_Finance_amount__c, Past2_FY_Str_Trade_Finance_amount__c,
                        Current_FY_Rates_amount__c, Next_FY_Rates_amount__c, Past_FY_Rates_amount__c, Past2_FY_Rates_amount__c,
                        Current_FY_GTF_amount__c, Next_FY_GTF_amount__c, Past_FY_GTF_amount__c, Past2_FY_GTF_amount__c,
                        Current_FY_Working_Capital_amount__c, Next_FY_Working_Capital_amount__c, Past_FY_Working_Capital_amount__c, Past2_FY_Working_Capital_amount__c,
                        Current_FY_Total_Non_X_Sell_amount__c, Next_FY_Total_Non_X_Sell_amount__c, Past_FY_Total_Non_X_Sell_amount__c, Past2_FY_Total_Non_X_Sell_amount__c,
                        Current_FY_ECM_M_A_Amount__c, Next_FY_ECM_M_A_amount__c, Past_FY_ECM_M_A_Amount__c, Past2_FY_ECM_M_A_Amount__c,
                        Past2_FY_DCM_amount__c, Past_FY_DCM_amount__c, Current_FY_DCM_amount__c, Next_FY_DCM_amount__c,
                        Current_FY_Credit_Equity_amount__c, Next_FY_Credit_Equity_amount__c, Past_FY_Credit_Equity_amount__c, Past2_FY_Credit_Equity_amount__c,
                        Current_FY_FX_CCS_amount__c, Next_FY_FX_CCS_amount__c, Past_FY_FX_CCS_amount__c, Past2_FY_FX_CCS_amount__c,
                        Current_FY_Cash_Management_amount__c, Next_FY_Cash_Management_amount__c, Past_FY_Cash_Management_amount__c, Past2_FY_Cash_Management_amount__c,
                        Current_FY_Client_Resources_amount__c, Next_FY_Client_Resources_amount__c, Past_FY_Client_Resources_amount__c, Past2_FY_Client_Resources_amount__c,
                        Current_FY_Securities_Services_amount__c, Next_FY_Securities_Services_amount__c, Past_FY_Securities_Services_amount__c, Past2_FY_Securities_Services_amount__c,
                        Current_FY_Total_X_Sell_amount__c, Next_FY_Total_X_Sell_amount__c, Past_FY_Total_X_Sell_amount__c, Past2_FY_Total_X_Sell_amount__c,
                        Current_FY_Child_X_Sell_amount__c, Next_FY_Child_X_Sell_amount__c , Past_FY_Child_X_Sell_amount__c, Past2_FY_Child_X_Sell_amount__c,
                        Current_FY_Total_Revenues_amount__c, Next_FY_Total_Revenues_amount__c, Past_FY_Total_Revenues_amount__c, Past2_FY_Total_Revenues_amount__c,

                        gf_xb_cust_ope_revenue_2ya_per__c, gf_xb_cust_ope_revenue_ly_per__c, gf_xb_cust_ope_revenue_cyr_per__c, gf_xb_cust_ope_revenue_nxy_per__c,
                        gf_kpi_trans_fees_2ya_amount__c, gf_kpi_trans_fees_ly_amount__c, gf_kpi_trans_fees_cyr_amount__c, gf_kpi_trans_fees_nxy_amount__c,

                        DMT_Opp_Threats_Related_Deal__c, DMT_Purpose__c, DMT_Description_Issues__c, TOLABEL(DMT_Exception_Pool__c), DMT_Target__c, DMT_Current__c, DMT_Tiering_Action__c, DMT_Commitment_Deadline__c,
                        DMT_External_Rating__c, DMT_Sector__c, DMT_Subsector__c, DMT_Activity__c, DMT_History_Deal__c, DMT_Applicable_Jurisdiction__c, DMT_Security_Package__c, DMT_Rating_Scenarios__c,
                        DMT_Other_Relevant_Issues__c, DMT_Competition_Deal__c, DMT_AA_Industry__c, DMT_Asset_Allocation_limit__c, DMT_Financial_Program_limit__c, DMT_Top_3_Active_Facilities__c, DMT_Country_Risk__c, DMT_Economic_LGD__c,
                        DMT_Regulatory_LGD__c, DMT_Leveraged_Lending__c, DMT_Credit_Risk_Opinion_By__c, DMT_tri__c, DMT_positioning__c, DMT_cca__c, DMT_cta__c, DMT_tri_Engagement_Plan__c,
                        DMT_scope__c, DMT_comments__c, DMT_reputational_risk__c, DMT_equator_Principles__c, DMT_cleanTech__c, DMT_portfolio_Alignment__c, DMT_kpiLink_Margin_Adjustment__c,
                        DMT_Scoring__c, DMT_External_Rating_Fitch__c, DMT_External_Rating_Moodys__c, DMT_External_Rating_SP__c, DMT_CAMN__c, DMT_Industry__c,
                        DMT_Enviromental_Social_Framework__c, DMT_Group_Have_Exposure_To_Thermal_Coal__c, DMT_Capacity_Weight__c, DMT_Company_Have_A_Coal_Phase_Out_Plan__c, DMT_Group_Engagement_Plan__c,
                        DMT_KPI_Margin_Adjustment__c, DMT_Clients_Global_RORC_CIB_Past_FY__c, DMT_CDD_Clients_Global_Rorc_Last_FY__c,
                        DMT_Client_Net_Incomes__c, DMT_Client_RWA__c, DMT_Currency__c, DMT_Xsell_Cost_to_Income__c, DMT_Client_RORC_YTD__c, DMT_Sector_Head__c, DMT_Guarantor_Name_Fiscal_ID__c,
                        DMT_Equator_Principles_Category__c, DMT_Infrastructure_Supporting_Factor__c, DMT_SourceAndUses__c, DMT_Sustainable_Deal__c
                    FROM DMT_MDE_Opportunities_Clients__r
                    LIMIT 1
                    ),
                    // chils Global_Structures__r
                    (
                        SELECT Id, Name, DMT_Type__c, DMT_Funds__c
                        FROM Global_Structures__r
                    ),
                    (
                        SELECT Id, Name, DMT_Ticket__c, DMT_Fees__c, DMT_Margin__c, DMT_N_Banks__c
                        FROM Banking_Pool_Structures__r
                        ORDER BY CreatedDate ASC
                    ),
                    // child Opportunity_Business_Plans__r (year + geography model)
                    (
                        SELECT
                            Current_FY_Corp_Synd_Lending_amount__c, Current_FY_Structured_Finance_amount__c, Current_FY_Str_Trade_Finance_amount__c,
                            Current_FY_Rates_amount__c, Current_FY_GTF_amount__c, Current_FY_Working_Capital_amount__c, Current_FY_Total_Non_X_Sell_amount__c,
                            Current_FY_ECM_M_A_Amount__c, Current_FY_M_A_amount__c, Current_FY_DCM_amount__c, Current_FY_Credit_Equity_amount__c,
                            Current_FY_FX_CCS_amount__c, Current_FY_Cash_Management_amount__c, Current_FY_Client_Resources_amount__c,
                            Current_FY_Securities_Services_amount__c, Current_FY_Total_X_Sell_amount__c, Current_FY_Child_X_Sell_amount__c,
                            Current_FY_Total_Revenues_amount__c, gf_xb_cust_ope_revenue_cyr_per__c, gf_kpi_trans_fees_cyr_amount__c,
                            DMT_Booking_Geography__c, DMT_Year__c, DMT_QAOTER__c, DMT_Currency__c, DMT_Active__c,DMT_Xsell_Cost_to_Income__c,
                            DMT_Revenues_number__c, DMT_EBITDA_number__c, DMT_EBIT_number__c, DMT_Net_Income_number__c,
                            DMT_Free_Cash_Flow_number__c, DMT_Debt_EBITDA_number__c, DMT_Net_Debt_EBITDA_number__c
                        FROM Opportunity_Business_Plans__r
                        ORDER BY DMT_Booking_Geography__c, DMT_Year__c
                    ),
                    // child Custom_Associations__r (DMT_Custom_Association_Opportunity__c) + nested multiholder participants
                    (
                        SELECT Id, Group__c, g_group_id__c,
                               gf_cutoff_date__c, gf_origin_application_type__c,
                            (
                                SELECT Id, DMT_g_customer_id__c, DMT_gf_customer_group_id__c, DMT_g_entific_id__c
                                FROM DMT_Client_Associations_Opportunities__r
                            )
                        FROM Custom_Associations__r
                    )
                FROM Opportunity
                WHERE Id = :recordId OR (DMT_Opp_Id__c =:recordId AND RecordType.DeveloperName = :recordTypeDeveloperName)
                ORDER BY CreatedDate DESC LIMIT 1
            ];
    }

    public static List<DMT_Approver__c> getApprover(String developerName){

        List<DMT_Approver__c> approver = [SELECT Approvers_View__c, Approvers_View_Treasury__c, Approvers_View_Opportunity__c
                                            FROM DMT_Approver__c
                                            WHERE DMT_Group__c = :developerName
                                            WITH USER_MODE LIMIT 1];
        return approver;
    }

    @AuraEnabled(cacheable=false)
    public static Case getCaseLineOpportunity(Id caseId) {
        return [SELECT Id, DMT_LineOpportunity__c, opportunity_id__c FROM Case WHERE Id = :caseId LIMIT 1];
    }

    public static List<Custom_Association_Client__c> getCustomAssociationClient(String customAssociationId){

        List<Custom_Association_Client__c> customAssociationClient = [ SELECT Name, g_customer_id__c , DMT_Amount__c, DMT_Term__c, Alpha_Code_Client__c, DMT_FDAmount__c, DMT_DVPAmount__c, DMT_ClientStarCode__c, DMT_ClientContracts__c, CurrencyIsoCode, DMT_ClientRating__c, DMT_Client_Rating_Date__c
                        FROM Custom_Association_Client__c WHERE Custom_Association__c = :customAssociationId];

        return customAssociationClient;
    }

    public static List<String> getFilteredComponentItemOptionByVersionView(String viewType) {
        List<String> componentOptions = new List<String>();
        if (!Schema.sObjectType.DMT_Items__c.isAccessible()) {
            System.debug(LoggingLevel.WARN, 'User does not have access to DMT_Items__c');
            return componentOptions;
        }

        // Check for null to avoid query errors or unnecessary processing
        if (String.isBlank(viewType)) {
            System.debug(LoggingLevel.WARN, 'viewType is null or empty');
            return componentOptions;
        }

        // Execute query with bind variable :viewType
        for (DMT_Items__c item : [SELECT DMT_Component_Item__c FROM DMT_Items__c WHERE DMT_View__r.DMT_Type__c = :viewType AND DMT_View__r.IsVersionView__c = true
            AND IsDeleted = FALSE ORDER BY DMT_order_display__c ASC]) {
            // Add the field value to the list
            if (item.DMT_Component_Item__c != null) {
                componentOptions.add(item.DMT_Component_Item__c);
            }
        }

        return componentOptions;
    }

    public static List<DMT_Items__c> getItemsByApproversViewRecordId(String recordId){
        if (!Schema.sObjectType.DMT_Items__c.isAccessible()) {
            System.debug(LoggingLevel.WARN, 'User does not have access to DMT_Items__c');
            return new List<DMT_Items__c>();
        }
        return [SELECT Id FROM DMT_Items__c WHERE DMT_View__c = :recordId];
    }

    public static List<DMT_ApproversView__c> getViewToDeactivateVersion(String viewType, String recordId){
        if (!Schema.sObjectType.DMT_ApproversView__c.isAccessible()) {
            System.debug(LoggingLevel.WARN, 'User does not have access to DMT_ApproversView__c');
            return new List<DMT_ApproversView__c>();
        }
        return [SELECT Id FROM DMT_ApproversView__c WHERE DMT_Type__c = :viewType AND IsVersionView__c = true AND Id != :recordId];
    }

    // public static List<DMT_Line__c> getRelatedTRSRLines(List<String> customAssociationClientsList, Date startDate, Date endDate, String lineId){
    //     return [SELECT Id, Name, Start_Date__c, End_Date__c, Client__r.Name, CurrencyIsoCode, Client__r.g_customer_id__c, FD_Amount__c, DvP_Amount__c, DMT_DerivativesAmount__c 
    //     from DMT_Line__c
    //     WHERE Client__r.g_customer_id__c IN:  customAssociationClientsList
    //     AND Product__c = 'Treasury Line'
    //     AND Start_Date__c <: endDate
    //     AND End_Date__c >: startDate
    //     AND Id != :lineId];
    // }

    @AuraEnabled(cacheable=false)
    public static List<DMT_Line__c> getRelatedTRSRLines(List<String> customAssociationClientsList,Date startDate,Date endDate,String lineId) {
        Map<Id, DMT_Line__c> uniqueLines = new Map<Id, DMT_Line__c>();

        // 1) Líneas locales por Account / Client__c
        for (DMT_Line__c line : [
            SELECT Id,Line_Id__c,Name,Start_Date__c,End_Date__c,Client__r.Name,CurrencyIsoCode,Client__r.g_customer_id__c,FD_Amount__c,DvP_Amount__c,DMT_DerivativesAmount__c
            FROM DMT_Line__c
            WHERE (
                Client__r.g_customer_id__c IN :customAssociationClientsList
                OR Client_Code__c IN :customAssociationClientsList
            )
            AND Product__c = 'Treasury Line'
            AND Start_Date__c < :endDate
            AND End_Date__c >= :startDate
            AND DMT_Status_Completed__c = 'Closed Won'
            AND Id != :lineId
        ]) {
            uniqueLines.put(line.Id, line);
        }

        // 2) Líneas multiholder por Custom_Association_Client__c
        for (Custom_Association_Client__c cac : [
            SELECT Custom_Association__r.Dmt_Line__r.Id,Custom_Association__r.Dmt_Line__r.Name,Custom_Association__r.Dmt_Line__r.Start_Date__c,Custom_Association__r.Dmt_Line__r.End_Date__c,Custom_Association__r.Dmt_Line__r.Client__r.Name,Custom_Association__r.Dmt_Line__r.CurrencyIsoCode,Custom_Association__r.Dmt_Line__r.Client__r.g_customer_id__c,Custom_Association__r.Dmt_Line__r.FD_Amount__c,Custom_Association__r.Dmt_Line__r.DvP_Amount__c,Custom_Association__r.Dmt_Line__r.DMT_DerivativesAmount__c, Custom_Association__r.Dmt_Line__r.Line_Id__c
            FROM Custom_Association_Client__c
            WHERE g_customer_id__c IN :customAssociationClientsList
            AND Custom_Association__r.Dmt_Line__r.Product__c = 'Treasury Line'
            AND Custom_Association__r.Dmt_Line__r.Start_Date__c < :endDate
            AND Custom_Association__r.Dmt_Line__r.End_Date__c >= :startDate
            AND Custom_Association__r.Dmt_Line__r.DMT_Status_Completed__c = 'Closed Won'
            AND Custom_Association__r.Dmt_Line__r.Id != :lineId
            AND Custom_Association__r.Dmt_Line__c != null
        ]) {
            DMT_Line__c relatedLine = cac.Custom_Association__r.Dmt_Line__r;
            if (relatedLine != null) {
                uniqueLines.put(relatedLine.Id, relatedLine);
            }
        }

        return uniqueLines.values();
    }

    @AuraEnabled
    public static List<Custom_Association_Client__c> getCustomAssociationClientByLineId(Id lineId) {
        return [SELECT Id, g_customer_id__c, Custom_Association__r.DMT_Line__c FROM Custom_Association_Client__c where Custom_Association__r.DMT_Line__c = :lineId];
    }

    @AuraEnabled(cacheable=false)
    public static List<DMT_Line__c> getRelatedTRSRLinesByLineId(Id recordId) {

        DMT_Line__c currentLine = [
            SELECT Id,
                Start_Date__c,
                End_Date__c,
                Client_Type__c,
                Client__r.g_customer_id__c,
                Custom_Association__c
            FROM DMT_Line__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        List<String> customerIds = new List<String>();

        // Si la línea es multiholder / custom
        if (currentLine.Client_Type__c == 'Custom') {
                for (Custom_Association_Client__c cac : [
                    SELECT g_customer_id__c, Custom_Association__r.DMT_Line__r.Start_Date__c, Custom_Association__r.DMT_Line__r.End_Date__c
                    FROM Custom_Association_Client__c
                    WHERE Custom_Association__r.DMT_Line__c = :recordId
                    AND g_customer_id__c != null
                ]) {
                    customerIds.add(cac.g_customer_id__c);
                }
        }
        // Si la línea es customer normal
        else {
            if (currentLine.Client__r.g_customer_id__c != null) {
                customerIds.add(currentLine.Client__r.g_customer_id__c);
            }
        }

        return getRelatedTRSRLines(
            customerIds,
            currentLine.Start_Date__c,
            currentLine.End_Date__c,
            currentLine.Id
        );
    }
    public static List<DMT_Opportunity_Tenor__c> getProfitabilityTenors(List<String> productIds, String oppId) {
            if (productIds == null || productIds.isEmpty() || String.isBlank(oppId)) {
                return new List<DMT_Opportunity_Tenor__c>();
            }
            return [
                SELECT DMT_Opportunity_Product__c,
                    gf_nominal_amount_fb__c,
                    gj_nominal_amount_db__c,
                    DMT_Opportunity_Product__r.gf_group_priority_opportunity_id__c
                FROM DMT_Opportunity_Tenor__c
                WHERE DMT_Opportunity_Product__r.gf_group_priority_opportunity_id__c IN :productIds
                AND DMT_Opportunity_Product__r.OpportunityId = :oppId
            ];
        }
    public static DMT_Line__c getLineWithRelatedData(String recordId, String recordTypeDeveloperName) {
        return [
            SELECT Id, Name, Booking_Geography__c, DMT_Oficina__c, g_limit_last_level_type__c, Start_Date__c, End_Date__c, Line_Term__c, CurrencyIsoCode, DvP_Amount__c, FD_Amount__c, Line_Id__c, DMT_RecordTypeName__c,
                DMT_LastLevelId__c, Amount__c, Client__c, Client__r.Name, Client__r.g_customer_id__c, Client__r.RecordTypeId, Custom_Association__c, Custom_Association__r.g_customer_id__c, Client_Type__c, Repos_Limit__c, Repos_Limit_6M__c, First_Breakclause__c,
                First_Breakclause_Date__c,RecordType.Name, RecordType.DeveloperName, RecordTypeId, DMT_GlobalBanker__c, Breakclause_Frequency__c, Waiver__c, DMT_Operation__c,
                DMT_RAROEC_RORC_Proposal__c, DMT_Nominal__c, DMT_Comments__c, DMT_Franchise_L12M__c, DMT_Client_Rating_Date__c, DMT_ClientStarCode__c, DMT_Approver__c,
                DMT_Approver__r.Name, DMT_Client_Use__c, DMT_ApproverGlobalBanker__c, DMT_Booking_Unit_Risk_Analyst__c, DMT_Booking_Unit_Risk_Analyst__r.Name,
                DMT_ApproverGlobalBanker__r.Name, DMT_Additional_Restrictions__c, DMT_Client_Entific__c,g_line_commitment_level_type__c,Closed__c,Status__c, gf_min_rorc_wo_fcg_per__c, gf_min_raroec_wo_fcg_per__c, DMT_Individual_Disposal_Approval__c , DMT_Bussiness_Approved_Date__c, DMT_Business_Approved_End_Date__c, DMT_Business_Approval_Term_n__c, DMT_Risk_Approval_Term__c,
                // CHILD LINE TEAM MEMBER
                (
                    SELECT Full_Name_User__c, AccessLevel__c FROM Line_Team_Members__r
                ),
                // CHILD RISK LINE TERMS (PRODUCTS)
                (
                    SELECT Id, Name, DMT_Init_Term__c, DMT_End_Term__c, DMT_Amount__c, DMT_Risk_Type__c, CurrencyIsoCode, g_amortization_type__c, gf_payment_frequency__c,
                    DMT_Parent_Product_Name__c, gf_group_priority_line_id__c, DMT_LastLevelId__c, DMT_Product__r.Name,
                    g_bullet_ind_type__c, g_smscl_internal_ratg_type__c, g_branch_id__c, g_limit_sinds_ast_sctr_id__c, g_limit_sinds_ast_subsec_id__c,
                    gf_inscol_months_grace_number__c, gf_loan_value_per__c, g_notary_crtfn_ind_type__c, g_gtee_public_adm_ind_type__c,
                    gf_loan_eca_cntrb_per__c, gf_min_raroec_fcg_per__c, gf_min_raroec_wo_fcg_per__c, gf_min_rorc_fcg_per__c,
                    gf_min_rorc_wo_fcg_per__c, gf_revolvence_pd_days_number__c, g_multioperation_ind_type__c, DMT_Comments__c,
                    g_global_product_family_Id__c, g_global_product_subfamily_Id__c, g_global_product_category_Id__c, g_gbl_product_subcategory_Id__c,
                    DMT_Max_Date__c, DMT_Singular_Active__c, DMT_Singular_Operation__c, DMT_Product_Name__c, DMT_Term__c, DMT_Singular__c, g_line_commitment_level_type__c,
                    // CIBGLOBALD-4117 - editable DVP/FD columns on the Singular-transaction table
                    // (dmt_singular_treasury.js), tracked but not queried until now - found via a
                    // field-drift audit.
                    DMT_Singular_DvP__c, DMT_Singular_FD__c,
                    // CHILD CURRENCY PROVISIONS
                    (
                        SELECT g_currency_id__c, DMT_Risk_Line_Term__c FROM DMT_Currency_Provisions__r
                    ),
                    // CHILD WARRANTIES
                    (
                        SELECT Id, Name, DMT_Risk_Line_Term__c FROM DMT_Warranties__r
                    )
                    FROM Risk_Line_Terms__r
                ),
                // CHILD LINE PRODUCTS
                (
                    SELECT Name, DMT_DerivativeRestriction__c, DMT_FDRestriction__c, DMT_DVPRestriction__c, Max_Tenor_WC__c
                    FROM Line_Products__r
                ),
                // CHILD Custom_Associations__r
                (
                    SELECT Id, g_customer_id__c, Name, gf_customer_group_id__c, Group__r.RecordTypeId, Group__r.RecordType.DeveloperName, // ESCD25LIN00006408ES_01 (if ends with _xx (number)) means its related to a product (risk line term) that has DMT_Line__r.Line_Id__c concatenated (_) gf_group_priority_line_id__c
                    // child Custom_Associations_Clients__r
                    (
                        SELECT Name, Alpha_Code_Client__c, DMT_ClientStarCode__c, DMT_ClientContracts__c, DMT_ClientRating__c, DMT_Client_Rating_Date__c
                        FROM Custom_Associations_Clients__r
                    )
                    FROM Custom_Associations__r
                ),
                // CHILD Opportunities (Sanction lines: Opportunity.DMT_Sanction__c points back to this DMT_Line__c)
                (
                    SELECT Id, DMT_Opp_Id__c
                    FROM Opportunities__r
                    LIMIT 1
                )
            FROM DMT_Line__c
            WHERE Id = :recordId
            OR (
                Line_Id__c = :recordId 
                AND RecordType.DeveloperName = :recordTypeDeveloperName 
                AND Name != null 
                AND (RecordType.DeveloperName = 'Sanction' OR Client_Type__c = 'Custom')
            )
            ORDER BY CreatedDate DESC LIMIT 1
        ];
    }

    public static List<DMT_Underlying__c> getUnderlyingsByOliIds(Set<Id> oliIds) {
        return [
            SELECT Id, Name, DMT_Underlying_Type__c,
                   DMT_Max_Amount__c, DMT_Max_Term__c, DMT_Other_restrictions__c,
                   DMT_Drawn_Reference_Amount__c, DMT_Undrawn_Reference_Amount__c, DMT_Term__c,
                   DMT_Drawn_Speed__c, DMT_Undrawn_Spread__c, DMT_Upfront_Fees__c,
                   DMT_Upfront_Fees_amount__c, DMT_Amortization_Type__c,
                   DMT_Interest_Payment_Frequency__c, DMT_Currency__c, DMT_Opportunity_Product__c
            FROM DMT_Underlying__c
            WHERE DMT_Opportunity_Product__c IN :oliIds
            ORDER BY CreatedDate ASC
        ];
    }
    public static List<DES_Denorm_AccountVisits__c> getAccountVisitsByAccountId(Id accountId) {
        return [SELECT id, DES_Start_Date__c FROM DES_Denorm_AccountVisits__c WHERE DES_Client__c = :accountId AND DES_Start_Date__c != null AND DES_Start_Date__c <= TODAY ORDER BY DES_Start_Date__c DESC]; //NOSONAR
    }
}