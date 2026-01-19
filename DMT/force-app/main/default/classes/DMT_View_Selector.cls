public with sharing  class DMT_View_Selector {

    public static List<Task> getTaskApprover(String taskId, String recordOrLineId){

        List<Task> taskRecord =  [SELECT Id, OwnerId, WhatId FROM Task WHERE Id =:taskId AND WhatId =: recordOrLineId WITH SECURITY_ENFORCED LIMIT 1];

        return taskRecord;
    }
    public static List<Case> getCaseApprover(String recordOrLineId){

        List<Case> caseRecord = [SELECT OwnerId, DMT_Line__c, opportunity_id__c,DMT_LineOpportunity__c, DMT_Line__r.RecordType.Name, DMT_Line__r.RecordType.DeveloperName
                                    FROM Case
                                    WHERE Id = :recordOrLineId OR DMT_Line__c =:recordOrLineId OR opportunity_id__c =:recordOrLineId
                                    WITH SECURITY_ENFORCED
                                    LIMIT 1];

        return caseRecord;
    }
    public static List<Group> getGroup(String owmnerView){

        List<Group> groupRecord = [SELECT DeveloperName FROM Group WHERE Id = :owmnerView  WITH SECURITY_ENFORCED LIMIT 1];

        return groupRecord;
    }
    public static Opportunity getOpportunityWithRelatedData(String recordId, String recordTypeDeveloperName){
        return [SELECT Id, Name, Entific__c, DMT_Entity__c, DMT_DATE_Initial_Date__c, DMT_DATE_Maturity_Date__c, DMT_CUR_Notional_Amount__c, DMT_Opp_Id__c,
                    CurrencyIsoCode, RecordTypeId, Amount, DMT_requested_passport__c, Deal_total_amount__c, Des_product_name__c, Owner.Name,
                    DMT_Capital_Action__c, DMT_Tenor__c, DMT_Threshold_Type__c,
                    // parent Account fields
                        AccountId, Account.DES_Structure_Type__c,
                        Account.Past2_FY_Corp_Synd_Lending_amount__c, Account.Past_FY_Corp_Synd_Lending_amount__c, Account.Current_FY_Corp_Synd_Lending_amount__c,
                        Account.Next_FY_Corp_Synd_Lending_amount__c, Account.Past2_FY_Structured_Finance_amount__c, Account.Past_FY_Structured_Finance_amount__c,
                        Account.Current_FY_Structured_Finance_amount__c, Account.Next_FY_Structured_Finance_amount__c, Account.Past2_FY_Str_Trade_Finance_amount__c,
                        Account.Past_FY_Str_Trade_Finance_amount__c, Account.Current_FY_Str_Trade_Finance_amount__c, Account.Next_FY_Str_Trade_Finance_amount__c,
                        Account.Past2_FY_Rates_amount__c, Account.Past_FY_Rates_amount__c, Account.Current_FY_Rates_amount__c, Account.Next_FY_Rates_amount__c,
                        Account.Past2_FY_GTF_amount__c, Account.Past_FY_GTF_amount__c, Account.Current_FY_GTF_amount__c, Account.Name,
                        Account.Next_FY_GTF_amount__c, Account.Past2_FY_Working_Capital_amount__c, Account.Past_FY_Working_Capital_amount__c,
                        Account.Current_FY_Working_Capital_amount__c, Account.Next_FY_Working_Capital_amount__c, Account.Past2_FY_Total_Non_X_Sell_amount__c,
                        Account.Past_FY_Total_Non_X_Sell_amount__c, Account.Current_FY_Total_Non_X_Sell_amount__c,Account.Next_FY_Total_Non_X_Sell_amount__c,
                        Account.Past2_FY_ECM_M_A_Amount__c, Account.Past_FY_ECM_M_A_Amount__c, Account.Current_FY_ECM_M_A_Amount__c,
                        Account.Next_FY_ECM_M_A_amount__c, Account.Past2_FY_DCM_amount__c, Account.Past_FY_DCM_amount__c,
                        Account.Current_FY_DCM_amount__c, Account.Next_FY_DCM_amount__c, Account.Past2_FY_Credit_Equity_amount__c,
                        Account.Past_FY_Credit_Equity_amount__c, Account.Current_FY_Credit_Equity_amount__c, Account.Next_FY_Credit_Equity_amount__c,
                        Account.Past2_FY_FX_CCS_amount__c, Account.Past_FY_FX_CCS_amount__c,Account.Current_FY_FX_CCS_amount__c,
                        Account.Next_FY_FX_CCS_amount__c, Account.Past2_FY_Cash_Management_amount__c, Account.Past_FY_Cash_Management_amount__c,
                        Account.Current_FY_Cash_Management_amount__c, Account.Next_FY_Cash_Management_amount__c, Account.Past2_FY_Client_Resources_amount__c,
                        Account.Past_FY_Client_Resources_amount__c, Account.Current_FY_Client_Resources_amount__c, Account.Next_FY_Client_Resources_amount__c,
                        Account.Past2_FY_Securities_Services_amount__c, Account.Past_FY_Securities_Services_amount__c, Account.Current_FY_Securities_Services_amount__c,
                        Account.Next_FY_Securities_Services_amount__c, Account.Past2_FY_Total_X_Sell_amount__c, Account.Past_FY_Total_X_Sell_amount__c,
                        Account.Current_FY_Total_X_Sell_amount__c, Account.Next_FY_Total_X_Sell_amount__c,
                        Account.Past2_FY_Total_Revenues_amount__c, Account.Past_FY_Total_Revenues_amount__c,Account.Current_FY_Total_Revenues_amount__c,
                        Account.Next_FY_Total_Revenues_amount__c, Account.gf_xb_cust_ope_revenue_2ya_per__c, Account.gf_xb_cust_ope_revenue_ly_per__c,
                        Account.gf_xb_cust_ope_revenue_cyr_per__c, Account.gf_xb_cust_ope_revenue_nxy_per__c, Account.gf_kpi_trans_fees_2ya_amount__c,
                        Account.gf_kpi_trans_fees_ly_amount__c, Account.gf_kpi_trans_fees_cyr_amount__c, Account.gf_kpi_trans_fees_nxy_amount__c,
                        Account.Revenues_Last_Year_number__c,  Account.Revenues_Current_Year_number__c, Account.Revenues_Next_Year_number__c,
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
                    // child X_sell__r
                    (
                        SELECT Id, Year__c, g_notional_amount__c FROM X_sell__r
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
                        g_product_id__c, gf_green_bonus__c, gf_country_risk__c, des_product_name__c, DMT_Risk_Type__c, DMT_TXA_Comentarios__c,
                        Product2Id, Product2.Name, Product2.CurrencyIsoCode,
                        Product2.ProductCode, Product2.DMT_Product_category__c, Product2.DMT_Product_Subcategory__c, Product2.DMT_Product_Subfamily__c,
                        Product2.DMT_Code_Level__c, Product2.dmt_global_product_id__c, Product2.Family, Product2.DMT_Product_family__c,
                        Product2.DMT_Classification_Level__c, DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DMT_ExpectedFinal_Take__c, DMT_Expected_Drawn__c,
                        DMT_Extension_Duration_Fees__c, DMT_PricingGrid_OR_StepUps__c, DES_Tenor_years__c,
                        // child Opportunity_Mitigants__r
                        (
                            SELECT Id, CurrencyIsoCode, Name, Mitigant_Type__c, Commercial_Percentage__c, Political_Percentage__c, External_Rating__c,
                            Liquidation_Period__c, Counterpart__c, SCRA__c, AVC_Check__c, Garantor_European_ECA__c, European_Bank_Check__c
                            FROM Opportunity_Mitigants__r ORDER BY CreatedDate
                        ),
                        // child Opportunity_Tenors__r
                        (
                            SELECT Id, CurrencyIsoCode, gf_tenor_date__c, gj_nominal_amount_db__c, gf_nominal_amount_fb__c, gf_spread_db__c, gf_spread_fb__c,
                            gf_accrual_fees_bp__c, gf_non_accrual_fees_bp__c
                            FROM Opportunity_Tenors__r
                        )
                        FROM OpportunityLineItems ORDER BY LastModifiedDate DESC
                    ),
                    // child DMT_MDE_Opportunities_Clients__r
                    (
                        SELECT Id, External_Rating__c,Counterpart__c, Group_Sales_Check__c, g_upd_lmscl_internal_ratg_type__c,g_upd_smscl_internal_ratg_type__c, European_Bank_Check__c, SCRA__c,AVC_Check__c,
                        Revenues_Last_Year_number__c, Revenues_Current_Year_number__c, Revenues_Next_Year_number__c, Revenues_Next_Year_1_number__c, Revenues_Next_Year_2_number__c,
                        EBITDA_Last_Year_number__c, EBITDA_Current_Year_number__c, EBITDA_Next_Year_number__c, EBITDA_Next_Year_1_number__c, EBITDA_Next_Year_2_number__c,
                        EBIT_Next_Year_number__c,EBIT_Last_Year_number__c,EBIT_Current_Year_number__c,EBIT_Next_Year_1_number__c, EBIT_Next_Year_2_number__c,
                        Net_Income_Last_Year_number__c,Net_Income_Current_Year_number__c, Net_Income_Next_Year_number__c, Net_Income_Next_Year_1_number__c, Net_Income_Next_Year_2_number__c,
                        Free_Cash_Flow_Last_Year_number__c, Free_Cash_Flow_Current_Year_number__c, Free_Cash_Flow_Next_Year_number__c, Free_Cash_Flow_Next_Year_1_number__c,Free_Cash_Flow_Next_Year_2_number__c,
                        Debt_EBITDA_Last_Year_number__c, Debt_EBITDA_Current_Year_number__c, Debt_EBITDA_Next_Year_number__c, Debt_EBITDA_Next_Year_1_number__c, Debt_EBITDA_Next_Year_2_number__c,
                        Net_Debt_EBITDA_Last_Year_number__c, Net_Debt_EBITDA_Current_Year_number__c,Net_Debt_EBITDA_Next_Year_number__c, Net_Debt_EBITDA_Next_Year_1_number__c, Net_Debt_EBITDA_Next_Year_2_number__c,
                        Last_Year_Formula__c, Other_Relevant_Ratios_desc__c, cstk_sust_indicators_comments__c, Geographical_Footprint_desc__c, Relationship_Status_desc__c, Industry_Overview_desc__c,
                        Qualitative_Assesment_of_X_Sell_Rev_desc__c, gf_esg_score_close_ope_name__c, gf_co_list_tcfd_ind_type__c, gf_paris_agreement_ind_type__c, gf_customer_sustnbl_strg_desc__c,
                        gf_pitch_oppy_l12m_ibf_desc__c, gf_pitch_oppy_l12m_gm_desc__c, gf_pitch_oppy_l12m_gtb_desc__c, Current_FY_Corp_Synd_Lending_amount__c, Next_FY_Corp_Synd_Lending_amount__c,
                        Past_FY_Corp_Synd_Lending_amount__c, Past2_FY_Corp_Synd_Lending_amount__c, Current_FY_Structured_Finance_amount__c, Next_FY_Structured_Finance_amount__c,
                        Past_FY_Structured_Finance_amount__c, Past2_FY_Structured_Finance_amount__c, Current_FY_Str_Trade_Finance_amount__c, Next_FY_Str_Trade_Finance_amount__c,
                        Past_FY_Str_Trade_Finance_amount__c, Past2_FY_Str_Trade_Finance_amount__c, Current_FY_Rates_amount__c, Next_FY_Rates_amount__c, Past_FY_Rates_amount__c,
                        Past2_FY_Rates_amount__c, Current_FY_GTF_amount__c, Next_FY_GTF_amount__c, Past_FY_GTF_amount__c, Past2_FY_GTF_amount__c, Current_FY_Working_Capital_amount__c,
                        Next_FY_Working_Capital_amount__c, Past_FY_Working_Capital_amount__c, Past2_FY_Working_Capital_amount__c, Current_FY_Total_Non_X_Sell_amount__c,
                        Next_FY_Total_Non_X_Sell_amount__c, Past_FY_Total_Non_X_Sell_amount__c, Past2_FY_Total_Non_X_Sell_amount__c, Current_FY_ECM_M_A_Amount__c, Next_FY_ECM_M_A_Amount__c,
                        Past_FY_ECM_M_A_Amount__c, Past2_FY_ECM_M_A_Amount__c, Current_FY_Credit_Equity_amount__c, Next_FY_Credit_Equity_amount__c, Past_FY_Credit_Equity_amount__c,
                        Past2_FY_Credit_Equity_amount__c, Current_FY_FX_CCS_amount__c, Next_FY_FX_CCS_amount__c, Past_FY_FX_CCS_amount__c, Past2_FY_FX_CCS_amount__c, Current_FY_Cash_Management_amount__c,
                        Next_FY_Cash_Management_amount__c, Past_FY_Cash_Management_amount__c, Past2_FY_Cash_Management_amount__c, Current_FY_Client_Resources_amount__c, Next_FY_Client_Resources_amount__c,
                        Past_FY_Client_Resources_amount__c, Past2_FY_Client_Resources_amount__c, Current_FY_Securities_Services_amount__c, Next_FY_Securities_Services_amount__c,
                        Past_FY_Securities_Services_amount__c, Past2_FY_Securities_Services_amount__c, Current_FY_Total_X_Sell_amount__c, Next_FY_Total_X_Sell_amount__c, Past_FY_Total_X_Sell_amount__c,
                        Past2_FY_Total_X_Sell_amount__c, Current_FY_Total_Revenues_amount__c, Next_FY_Total_Revenues_amount__c, Past_FY_Total_Revenues_amount__c, Past2_FY_Total_Revenues_amount__c,
                        DMT_Opp_Threats_Related_Deal__c, DMT_Purpose__c, DMT_Description_Issues__c, DMT_Exception_Pool__c, DMT_Target__c, DMT_Current__c, DMT_Tiering_Action__c, DMT_Commitment_Deadline__c,
                        DMT_External_Rating__c, DMT_Sector__c, DMT_Subsector__c, DMT_Activity__c, DMT_History_Deal__c, DMT_Applicable_Jurisdiction__c,DMT_Security_Package__c, DMT_Rating_Scenarios__c,
                        DMT_Other_Relevant_Issues__c, DMT_Competition_Deal__c, DMT_AA_Industry__c, DMT_Asset_Allocation_limit__c, DMT_Financial_Program_limit__c, DMT_Country_Risk__c, DMT_Economic_LGD__c,
                        DMT_Regulatory_LGD__c, DMT_Leveraged_Lending__c, DMT_Credit_Risk_Opinion_By__c, DMT_tri__c, DMT_positioning__c, DMT_cca__c, DMT_cta__c, DMT_tri_Engagement_Plan__c,
                        DMT_scope__c, DMT_comments__c,  DMT_reputational_risk__c, DMT_equator_Principles__c, DMT_cleanTech__c, DMT_portfolio_Alignment__c, DMT_kpiLink_Margin_Adjustment__c
                        FROM DMT_MDE_Opportunities_Clients__r LIMIT 1
                    ),
                    // chils Global_Structures__r
                    (
                        SELECT Id, Name, DMT_Type__c, DMT_Funds__c
                        FROM Global_Structures__r
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
                                            WITH SECURITY_ENFORCED LIMIT 1];
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
}