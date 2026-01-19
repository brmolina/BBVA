public with sharing class DMT_Passport_Selector {
    public static DMT_Line__c getLine(String recordId) {
        return [SELECT Name,Waiver__c, DMT_DerivativesAmount__c, Line_Id__c, DMT_Client_Entific__c, Booking_Geography__c, OwnerId, DMT_Status_Completed__c, Start_Date__c, End_Date__c, CurrencyIsoCode, Line_Details__c, Client__c, Client_Code__c, Client__r.Name, Client_Type__c,
                    Client__r.DES_Tax_Identification_Number__c, Custom_Association__c, Custom_Association__r.Name, Client__r.Group_Code_EGS__c, Client__r.DES_Main_Parent__r.Name, DvP_Amount__c, FD_Amount__c, DMT_Total_Amount__c, Client__r.DES_Activity__c,
                    Repos_Limit_6M__c, Repos_Limit__c, DMT_ClientStarCode__c, DMT_Client_Rating_Date__c, DMT_ClientRating__c, DMT_ClientContracts__c, DMT_Parent_Line__r.Line_Id__c, DMT_Parent_Line__r.CurrencyIsoCode, DMT_Parent_Line__r.DvP_Amount__c,
                    DMT_Parent_Line__r.FD_Amount__c, DMT_Parent_Line__r.DMT_DerivativesAmount__c, DMT_Parent_Line__r.End_Date__c, DMT_Parent_Line__r.Start_Date__c , DMT_ApproverGlobalBanker__r.DMT_External_Id__c, DMT_Booking_Unit_Risk_Analyst__r.DMT_External_Id__c, DMT_Approver__r.DMT_External_Id__c,
                    RecordType.DeveloperName, DMT_LastLevelId__c, Amount__c, Status__c, Closed__c, DMT_line_template_type__c, DMT_Parent_Line__c, DMT_Parent_Code_Form__c
        FROM DMT_Line__c
        WHERE Id = :recordId WITH SECURITY_ENFORCED];
    }

    public static List<DMT_Risk_Line_Term__c> getRiskLineTerm(String recordId) {
        return [SELECT Id, DMT_End_Term__c, DMT_Init_Term__c, DMT_Amount__c, DMT_Parent_Product__c, DMT_Parent_Product__r.DMT_End_Term__c, DMT_Parent_Product__r.DMT_Amount__c, DMT_Parent_Product__r.gf_group_priority_line_id__c,
            DMT_Parent_Product__r.CurrencyIsoCode
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :recordId AND DMT_Risk_Type__c = 'Derivatives' WITH SECURITY_ENFORCED];
    }

    public static List<DMT_Risk_Line_Term__c> getRiskLineAll(String recordId) {
        return [SELECT DMT_Amount__c, Name
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :recordId WITH SECURITY_ENFORCED];
    }

    public static List<DMT_Risk_Line_Term__c> getRiskLineTermWithoutDerivatives(List<String> recordsId) {
        return [SELECT Id, DMT_End_Term__c, DMT_Line__r.Line_Id__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__r.Line_Id__c IN :recordsId AND DMT_Risk_Type__c != 'Derivatives' WITH SECURITY_ENFORCED];
    }

    public static List<DMT_Risk_Line_Term__c> getRiskLineTermWhithoutRiskType(String recordId) {
        return [SELECT Id, DMT_End_Term__c, DMT_Line__r.Line_Id__c, g_global_product_family_id__c, g_global_product_subfamily_id__c, g_global_product_category_id__c, g_gbl_product_subcategory_id__c, g_global_product_id__c,
            DMT_Amount__c, CurrencyIsoCode, (SELECT Id, g_currency_id__c FROM DMT_Currency_Provisions__r), (SELECT Id, g_limits_grid_guarantee_type__c FROM DMT_Warranties__r), DMT_LastLevelId__c, DMT_Product__r.DMT_Product_family__c,
            DMT_Product__r.DMT_Product_Subfamily__c, DMT_Product__r.DMT_Product_category__c, DMT_Product__r.DMT_Product_Subcategory__c, DMT_Product__r.ProductCode, g_bullet_ind_type__c, DMT_Init_Term__c,
            g_limit_sinds_ast_sctr_id__c, g_limit_sinds_ast_subsec_id__c, gf_inscol_months_grace_number__c, gf_loan_value_per__c, g_notary_crtfn_ind_type__c, g_gtee_public_adm_ind_type__c, gf_loan_eca_cntrb_per__c,
            gf_min_raroec_fcg_per__c, gf_min_raroec_wo_fcg_per__c, gf_min_rorc_fcg_per__c, gf_min_rorc_wo_fcg_per__c, gf_revolvence_pd_days_number__c, g_multioperation_ind_type__c, DMT_Comments__c, g_branch_id__c, gf_group_priority_line_id__c,
            DMT_Parent_Product__c, DMT_Parent_Product__r.DMT_End_Term__c, DMT_Parent_Product__r.DMT_Amount__c, DMT_Parent_Product__r.gf_group_priority_line_id__c,
            DMT_Parent_Product__r.CurrencyIsoCode, DMT_Product__r.Name, g_expert_criteria_risk_type__c, Name
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :recordId AND DMT_Risk_Type__c = '' WITH SECURITY_ENFORCED];
    }

    public static List<Opportunity> getOpportunity(String recordId) {
        List<Opportunity> opp = [SELECT Name,DMT_Entity__c ,DMT_Sanction__c, DMT_CurrencyText__c,DMT_Opp_Id__c,DMT_CUR_Notional_Amount__c,DMT_Notional_Items_Sum__c,DMT_DATE_Maturity_Date__c,opp_external_id__c, DES_Client_Text__c,Booking__c,
                DES_Booking_Geography__c, OwnerId, StageName, DMT_DATE_Initial_Date__c, DES_Date_Won_Lost__c,Account.g_customer_id__c, CurrencyIsoCode, Account.Client_STAR_ID__c, Account.Name,
                Account.DES_Client_Type__c, Account.DES_Tax_Identification_Number__c, AccountId, Account.Group_Code_EGS__c, Account.DES_Main_Parent__r.Name, DMT_NUM_Version__c, Entific__c,
                Account.DES_Group_Code__c, DMT_Threshold_Type__c
        FROM Opportunity
        WHERE Id = :recordId OR DMT_Opp_Id__c = :recordId WITH SECURITY_ENFORCED LIMIT 1];
        return opp;
    }

    public static Account getAccountWithRelatedListsFromOppId(String oppRecordId){ // CIBGLOBALD-2027
        return [SELECT Id, Name, DES_Group_Code__c, DES_Main_Parent__c, DES_Main_Parent__r.Name,g_customer_id__c, Client_STAR_ID__c, DES_Client_Type__c, DES_Tax_Identification_Number__c, Group_Code_EGS__c, DES_Structure_Type__c,
                    /* Child Local Client */
                    (
                        SELECT Id, Alpha_code__c FROM Local_Clients__r LIMIT 1
                    ),
                    /* Child Opportunity */
                    (
                        SELECT Id, Name, DMT_Entity__c, DMT_Opp_Id__c, DMT_CUR_Notional_Amount__c, DMT_Notional_Items_Sum__c, DMT_DATE_Maturity_Date__c, opp_external_id__c, DES_Client_Text__c, Booking__c, DES_Booking_Geography__c,
                        OwnerId, StageName, DMT_DATE_Initial_Date__c, DES_Date_Won_Lost__c, CurrencyIsoCode, DMT_NUM_Version__c, Entific__c, AccountId, DMT_CurrencyText__c, DMT_Client_Type__c, Account.DES_Client_Type__c, Account.DES_Rating_Int__c,
                        Account.Client_STAR_ID__c, Account.Name,Account.g_customer_id__c, DMT_Sanction__c, DMT_Sanction__r.Line_Id__c, DMT_Threshold_Type__c, DMT_Booking_Unit_Risk_Analyst__r.DMT_External_Id__c, DMT_ApproverGlobalBanker__r.DMT_External_Id__c, DMT_Approver__r.DMT_External_Id__c,
                        DMT_Currency__c,
                            /* Child Opportunity Client */
                            (
                                SELECT Id, Counterpart__c,DMT_Sector__c , AVC_Check__c, Group_Sales_Check__c, European_Bank_Check__c, g_upd_lmscl_internal_ratg_type__c, External_Rating__c, SCRA__c, Group_Sales__c
                                FROM DMT_MDE_Opportunities_Clients__r
                            ),
                            // Child Opportunity DMT_X_Sell__c
                            (
                                SELECT Id, OwnerId, Name, CurrencyIsoCode, g_year__c, g_notional_amount__c, DMT_Currency__c, Opportunity__c, Year__c
                                FROM X_sell__r
                            ),
                            // Child Opportunity Line Items
                            (
                                SELECT Id,Name,gf_maturity_date__c,DMT_Associated_Line_Product__c,ProductCode,gf_accrual_fees_bp__c,DMT_Risk_Type__c,Product2Id,gf_entity_id__c,gf_financing_type__c,gf_funding_cost_db__c,gf_green_bonus__c,gf_social_bond__c,gf_funding_cost_fb__c,
                                CurrencyIsoCode,g_product_id__c,gf_country_risk__c,gf_country_rating__c,gf_crr2_essential_public_services__c,Funding_Curve__c,Life_Funding_Type__c,gf_amortization_type__c,gf_payment_frequency__c,
                                gf_intermediate_date__c,g_branch_id__c,gf_initial_date__c,g_currency_id__c, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c,
                                // Child Opportunity Mitigants
                                (
                                    SELECT id,AVC__c,AVC_Check__c,Internal_Rating__c,DMT_Country_Guarantor__c,European_Bank_Check__c,CurrencyIsoCode,european_Bank__c,DMT_Opportunity_Product__c,Mitigant__c,mitigant_type__c,counterpart__c,
                                    rating_long_Scale__c,External_Rating__c,SCRA__c,Liquidation_Period__c,End_Date__c,Commercial_Percentage__c,Political_Percentage__c,Garantor_European_ECA__c
                                    FROM Opportunity_Mitigants__r
                                ),
                                // Child Opportunity Tenors
                                (
                                    SELECT Id,DMT_Opportunity_Product__c,gf_tenor_date__c,gj_nominal_amount_db__c,gf_nominal_amount_fb__c,gf_spread_db__c,gf_spread_fb__c,gf_accrual_fees_bp__c,gf_non_accrual_fees_bp__c
                                    FROM Opportunity_Tenors__r
                                )
                            FROM OpportunityLineItems
                            )
                        FROM Opportunities WHERE Id = :oppRecordId LIMIT 1
                    )
                FROM Account
                WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id = :oppRecordId)
                WITH SECURITY_ENFORCED LIMIT 1];
    }

    public static List<Custom_Association_Client__c> getLineClients(List<String> customAIds) {
        return [SELECT  Id, IsDeleted, Name, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Custom_Association__c,
        g_entific_id__c, Local_Client_Child__c, Alpha_Code__c, Alpha_Code_Client__c, g_customer_id__c,
        DMT_Amount__c, DMT_Term__c, gf_cutoff_date__c, DMT_ClientContracts__c, DMT_ClientRating__c, DMT_Client_Rating_Date__c, DMT_ClientStarCode__c
        FROM Custom_Association_Client__c
        WHERE Custom_Association__c IN :customAIds WITH SECURITY_ENFORCED];
    }
    public static List<DMT_Line__c> getCurrentLinesByClient(Date startDateLine, String recordId, String parentId) { // check if we can exclude the current line
        return [SELECT Name, Line_Id__c, DMT_Client_Entific__c, Booking_Geography__c, OwnerId, DMT_Status_Completed__c, Start_Date__c, End_Date__c, CurrencyIsoCode, Line_Details__c, Client__c, Client_Code__c, Client__r.Name, Client_Type__c,
        Client__r.DES_Tax_Identification_Number__c, Custom_Association__c, Custom_Association__r.Name, Client__r.Group_Code_EGS__c, Client__r.DES_Main_Parent__r.Name
        FROM DMT_Line__c
        WHERE Status__c = 'Closed' AND Closed__c = 'Won' AND End_Date__c > = :startDateLine AND Id != :recordId AND Line_Id__c != :parentId AND Product__c = 'Treasury Line' WITH SECURITY_ENFORCED];
    //    WHERE DMT_Status_Completed__c = : 'Closed Won' AND End_Date__c > = :startDateLine AND Id != :recordId WITH SECURITY_ENFORCED];
    }
    public static List<DMT_Line_Product_Item__c> getProductLineItems(String recordId){
        return [SELECT CurrencyIsoCode,Max_Tenor_WC__c ,Max_Tenor_WOC__c,Product__c,  Id, Name, Product__r.ProductCode,
        Product__r.DMT_Product_family__c,Line__c,Product__r.DMT_Product_Subfamily__c,Product__r.DMT_Product_category__c,Product__r.DMT_Product_Subcategory__c,
        Product__r.DMT_Global_Product_Id__c, Product__r.Name, Product_Code_Value__c,
        DMT_DerivativeRestriction__c,DMT_FDRestriction__c,DMT_DVPRestriction__c, Line__r.Booking_Geography__c FROM DMT_Line_Product_Item__c WHERE Line__c = :recordId WITH SECURITY_ENFORCED LIMIT 200];
    }

    public static Id getRecordTypeId(String name,String sobjectType) {
        return [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType WHERE SobjectType =: sobjectType AND Name =: name WITH SECURITY_ENFORCED].Id;
    }

    public static Id getAppproverId(String approverId) {
        String queueDeveloperName = [SELECT Id,DMT_Group__c FROM DMT_Approver__c WHERE DMT_External_Id__c =: approverId WITH SECURITY_ENFORCED LIMIT 1]?.DMT_Group__c;
         return [SELECT Id FROM Group WHERE Type = 'Queue' and DeveloperName = :queueDeveloperName LIMIT 1]?.Id;
    }
    public static DMT_Approver__c getApprover(String approverId) {
        return [SELECT Id,DMT_ApproverType__r.name FROM DMT_Approver__c WHERE DMT_External_Id__c =: approverId WITH SECURITY_ENFORCED LIMIT 1];
    }

    public static List<DMT_Task_Type__c> getTaskType(String taskId) {
        return [SELECT Id,Name, DMT_ApprovalEdit__c FROM DMT_Task_Type__c WHERE DMT_External_Id__c =: taskId WITH SECURITY_ENFORCED LIMIT 1];
    }

    public static List<DMT_Line__c> getLineByExternalId(String externalId) {
        List<DMT_Line__c> lines = [SELECT Name, Line_Id__c, DMT_Client_Entific__c, Booking_Geography__c, OwnerId, DMT_Status_Completed__c, Start_Date__c, End_Date__c, CurrencyIsoCode, Line_Details__c, Client__c, Client_Code__c, Client__r.Name, Client_Type__c,
                    Client__r.DES_Tax_Identification_Number__c, Custom_Association__c, Custom_Association__r.Name, Client__r.Group_Code_EGS__c, Client__r.DES_Main_Parent__r.Name, DvP_Amount__c, FD_Amount__c, DMT_Total_Amount__c, (SELECT Id, DMT_Amount__c, DMT_Risk_Type__c, DMT_Product__c FROM Risk_Line_Terms__r)
        FROM DMT_Line__c
        WHERE Line_Id__c = :externalId WITH SECURITY_ENFORCED LIMIT 1];

        return lines;
    }

    public static Passport__c getPassport(String lineId) {
        return [SELECT Id,DMT_Passport_Save__c,DMT_Is_Obsoleted_Passport_Save__c, DMT_Line__r.Line_Id__c, DMT_Line__r.Status__c,DMT_Line__r.DMT_Additional_Restrictions__c, DMT_Line__c, DMT_Line__r.OwnerId, DMT_Line__r.Client_Type__c, DMT_Line__r.Client__c, DMT_Line__r.Client_Code__c, DMT_Line__r.RecordType.DeveloperName FROM Passport__c WHERE DMT_Line__c =: lineId WITH SECURITY_ENFORCED LIMIT 1];
    }

    public static List<Task> getTask(String lineId) {
        List<Case> cases = [SELECT Id, DMT_Line__c FROM Case WHERE DMT_Line__c =: lineId WITH SECURITY_ENFORCED];
        return [SELECT Id FROM Task WHERE WhatId = :cases WITH SECURITY_ENFORCED];
    }
    public static List<Task> getTaskbyOpp(String opportunityId) {
        List<Case> cases = [SELECT Id, opportunity_id__c  FROM Case WHERE opportunity_id__c =: opportunityId WITH SECURITY_ENFORCED];
        return [SELECT Id FROM Task WHERE WhatId = :cases WITH SECURITY_ENFORCED];
    }

    public static List<Case> getCaseByLineFeature(Id lineId, String featureId) {
        return [SELECT Id, DMT_Line__c, opportunity_id__c, DMT_Feature_Id__c FROM Case WHERE (DMT_Line__c = :lineId OR opportunity_id__c = :lineId) AND DMT_Feature_Id__c = :featureId WITH SECURITY_ENFORCED];
    }

    public static List<DMT_Selected_Features__c> getSelectedFeatures(Id lineId) {
        return [SELECT Id, Line__c, Feature__c, Feature__r.gf_code_value_id__c FROM DMT_Selected_Features__c WHERE Line__c = :lineId WITH SECURITY_ENFORCED];
    }

    public static List<DMT_Selected_Features__c> getSelectedFeaturesOPP(Id recordId) {
        return [SELECT Id, Opportunity__c, Feature__c, Feature__r.gf_code_value_id__c FROM DMT_Selected_Features__c WHERE Opportunity__c = :recordId WITH SECURITY_ENFORCED];
    }

    public static List<Task> getApprovalEditTasks(String lineId) {
        List<Case> cases = [SELECT Id, DMT_Line__c, opportunity_id__c FROM Case WHERE DMT_Line__c =: lineId OR opportunity_id__c = :lineId WITH SECURITY_ENFORCED];
        return [SELECT Id, Owner.Name, DMT_Task_Type__r.Name FROM Task WHERE WhatId = :cases AND Status != :DMT_Constants.COMPLETED AND Status != :DMT_Constants.CANCELLED AND Status != :DMT_Constants.FINISHED AND DMT_Task_Type__r.DMT_ApprovalEdit__c = true WITH SECURITY_ENFORCED];
    }

    public static Passport__c passportById(Id recordId) {
        return [SELECT Id,DMT_Passport_Save__c,DMT_Is_Obsoleted_Passport_Save__c,Opportunity__c,Opportunity__r.RecordType.DeveloperName,Opportunity__r.StageName,Opportunity__r.DMT_Opp_Id__c ,Opportunity__r.OwnerId,DMT_Line__r.Line_Id__c, DMT_Line__r.Status__c, DMT_Line__c, DMT_Line__r.DMT_Additional_Restrictions__c, DMT_Line__r.OwnerId, DMT_Line__r.Client_Type__c, DMT_Line__r.Client__c, DMT_Line__r.Client_Code__c, DMT_Line__r.RecordType.DeveloperName FROM Passport__c WHERE Id = :recordId WITH SECURITY_ENFORCED];
    }

    public static Passport__c passportByIdOpportunity(Id recordId) {
        return [SELECT Id, Opportunity__r.dmt_opp_id__c,DMT_Line__c ,Opportunity__c,DMT_Is_Obsoleted_Passport_Save__c,DMT_Passport_Save__c, Opportunity__r.StageName, Opportunity__r.OwnerId,Opportunity__r.RecordType.DeveloperName, DMT_Line__r.DMT_Additional_Restrictions__c FROM Passport__c WHERE Opportunity__c = :recordId WITH SECURITY_ENFORCED];
    }

    public static List<Local_Client__c> getLocalclient (List<String> localclientId) {
        return [SELECT Id, Alpha_code__c FROM Local_Client__c WHERE Alpha_code__c IN :localclientId WITH SECURITY_ENFORCED];
    }

    public static List<DMT_TeamMember__c> getTeamMember (String recordId) {
        return [SELECT Id, AccessLevel__c FROM DMT_TeamMember__c WHERE Line__c = :recordId AND User__c = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
    }

   /* public static List<DMT_TeamMember__c> getTeamMemberBulk (Set<Id> recordsId) {
        return [SELECT Id, AccessLevel__c FROM DMT_TeamMember__c WHERE Line__c IN :recordsId AND User__c = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
    }*/

    public static List<DMT_TeamMember__c> getTeamMemberOpportunity (String recordId) {
        return [SELECT Id, AccessLevel__c FROM DMT_TeamMember__c WHERE Opportunity__c = :recordId AND User__c = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
    }

    public static List<DMT_Taxonomy_Values__c > getTaxonomyValues(String catalog) {
        return [SELECT Id, DMT_Key__c, DMT_Catalog__c, DMT_Name_EN__c, DMT_Name__c, DMT_Value__c FROM DMT_Taxonomy_Values__c WHERE DMT_Catalog__c  = :catalog WITH SECURITY_ENFORCED];
    }

    public static List<DMT_Fuature_Rule__c> getFeatureRulesDMTO () {
        return [SELECT Id, DMT_Validate_Type__c, dmt_message__c, DMT_Field__c FROM DMT_Fuature_Rule__c WHERE DMT_Validate_Type__c = 'DMTO' WITH SECURITY_ENFORCED];
    }
    public static DMT_Opportunity_Client__c getOpportunityClient(String recordId){
        return [SELECT Id, Counterpart__c, AVC_Check__c,Group_Sales_Check__c, European_Bank_Check__c, g_upd_lmscl_internal_ratg_type__c, External_Rating__c, SCRA__c, Group_Sales__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :recordId WITH SECURITY_ENFORCED];
    }

    public static List<OpportunityLineItem> getOpportunityLineItems(String recordId){
        return [SELECT Id,gf_maturity_date__c,ProductCode,DMT_Risk_Type__c,Product2Id,gf_entity_id__c,gf_financing_type__c,gf_funding_cost_db__c,gf_green_bonus__c,gf_social_bond__c,gf_funding_cost_fb__c,CurrencyIsoCode,g_product_id__c,gf_country_risk__c,gf_country_rating__c,gf_crr2_essential_public_services__c,Funding_Curve__c,Life_Funding_Type__c,gf_amortization_type__c,gf_payment_frequency__c,gf_intermediate_date__c,g_branch_id__c,gf_initial_date__c,g_currency_id__c
        FROM OpportunityLineItem
        WHERE OpportunityId  = :recordId WITH SECURITY_ENFORCED];
    }

    /* public static List<DMT_Opportunity_Mitigant__c > getMitigantsOpportunity(List<Id> oppLineitemsIds) {
        return [SELECT id,AVC__c,AVC_Check__c,European_Bank_Check__c,CurrencyIsoCode,european_Bank__c,DMT_Opportunity_Product__c,Mitigant__c,mitigant_type__c,counterpart__c,rating_long_Scale__c,External_Rating__c,SCRA__c,Liquidation_Period__c,End_Date__c,DMT_Currency__c,Commercial_Percentage__c,Political_Percentage__c,Garantor_European_ECA__c
            FROM DMT_Opportunity_Mitigant__c
            WHERE DMT_Opportunity_Product__c IN :oppLineitemsIds WITH SECURITY_ENFORCED];
    } */

    /**
    * @description  This method get the amortization payments by opportunity line items id set
    * @author BBVA DMT | 07-10-2025
    * @param oppLineitemsIds
    * @return List<DMT_Opportunity_Tenor__c>
    **/
    public static List<DMT_Opportunity_Tenor__c> getAmortizationPayments(Set<Id> oppLineitemsIds) {
        return [SELECT Id,DMT_Opportunity_Product__c,gf_tenor_date__c,gj_nominal_amount_db__c,gf_nominal_amount_fb__c,gf_spread_db__c,gf_spread_fb__c,gf_accrual_fees_bp__c,gf_non_accrual_fees_bp__c
        FROM DMT_Opportunity_Tenor__c
        WHERE DMT_Opportunity_Product__c  IN :oppLineitemsIds WITH SECURITY_ENFORCED];
    }

    public static List<GroupMember> getUserGroupMembers(){
        return [SELECT  Group.Name from GroupMember  where UserOrGroupId = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
    }

    public static Passport__c passportByOppExtId(String extId) {
        return [SELECT Id, DMT_Is_Obsoleted_Passport_Save__c FROM Passport__c WHERE Opportunity__r.DMT_Opp_Id__c  = :extId WITH SECURITY_ENFORCED LIMIT 1];
    }

    public static List<DMT_Taxonomy_Values__c> getTaxonomyValuesByValueAndCatalog(String value, String catalog){
        return [SELECT DMT_Key__c, DMT_Value__c, gf_catalog_atrb_val1_name_c__c, DMT_Name_EN__c from DMT_Taxonomy_Values__c WHERE DMT_Value__c LIKE :value AND DMT_Catalog__c =: catalog AND DMT_Active__c = :true WITH SECURITY_ENFORCED];
    }

    public static List<DMT_Taxonomy_Values__c> getTaxonomyValuesByCatalogsAndNames(List<String> catalogsList, List<String> namesList_en){
        return [SELECT Name, DMT_Value__c, DMT_Name_EN__c, DMT_Catalog__c FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c IN :catalogsList AND DMT_Name_EN__c IN :namesList_en
            WITH SECURITY_ENFORCED
            ORDER BY DMT_Catalog__c, DMT_Name_EN__c];
    }

    public static Map<Id, DMT_Taxonomy_Values__c> getTaxonomyByIds(List<Id> taxoIds) {
        Map<Id, DMT_Taxonomy_Values__c> taxMap = new Map<Id, DMT_Taxonomy_Values__c>([SELECT Id,gf_catalog_atrb_val3_name__c, gf_catalog_atrb_val4_name__c, gf_catalog_atrb_val5_name__c FROM DMT_Taxonomy_Values__c]);
        return taxMap;
    }

    public static Custom_Association__c getCustomAssoById(String caId) {
        return [SELECT Id, gf_customer_group_id__c FROM Custom_Association__c WHERE gf_customer_group_id__c  = :caId WITH SECURITY_ENFORCED LIMIT 1];
    }

    public static List<DMT_Consolidated_Line__c> getConsolidatedById(String lineId) {
        return [SELECT Id, gf_group_line_id__c,g_line_status_type__c FROM DMT_Consolidated_Line__c WHERE gf_group_line_id__c  = :lineId FOR UPDATE];
    }
    public static List<DMT_Approver__c> getApprovers(List<String> featuresApproverIds){
        return [SELECT Id, Name, DMT_ApproverType__r.Name, DMT_External_Id__c FROM DMT_Approver__c WHERE DMT_ApproverType__r.Name IN ('Risk', 'Business') AND DMT_External_Id__c IN :featuresApproverIds];
    }

    public static List<DMT_Risk_Line_Term__c> getSingularRisk(Id lineId){
        return [SELECT DMT_Singular__c, DMT_Line__c, DMT_Max_Date__c, DMT_Singular_FD__c, DMT_Singular_DvP__c, DMT_Risk_Type__c
                             FROM DMT_Risk_Line_Term__c
                             WHERE DMT_Line__c = : lineId AND  DMT_Singular__c = true
                             WITH SECURITY_ENFORCED];
    }
}

//Campos no encontrados en Salesforce
//gf_booking_id__c
//gf_greater_one_year_term_ind_type__c
//gf_trade_guaranties_ind_type__c