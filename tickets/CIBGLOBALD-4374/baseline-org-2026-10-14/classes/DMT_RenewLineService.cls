/**
 * @description Apex replacement for the OmniStudio Integration Procedure "DealManagement_renewLine"
 *              (bootstrap DataRaptor "DmtDrRenewLine" + write DataRaptor "DmtDpRenewLine"),
 *              previously reached only via the DMT_MarcoGeneral FlexCard/PubSub bridge.
 *              Used by dmtRenewLineModal to load a read-only preview of the line being
 *              renewed, and to create the successor DMT_Line__c together with a full
 *              duplicate of its related records (Risk Line Terms, Line Product Items,
 *              Team Members and the Custom Association + its Clients).
 *
 *              Notes for future maintainers / sandbox validation:
 *              - DMT_Warranty__c and DMT_Currency_Provision__c are read by the original
 *                bootstrap DataRaptor for display purposes only; the original write
 *                DataRaptor (DmtDpRenewLine) never duplicates them on renew, so this
 *                class intentionally does not duplicate them either.
 *              - The "products" accordion shown for OtherProducts lines is informational
 *                only in the simple renew flow (the original formulas force value/disabled
 *                to "true" unconditionally for OtherProducts), it does not affect which
 *                Risk Line Terms get duplicated: ALL Risk Line Terms of the source line
 *                are always duplicated onto the successor line, regardless of
 *                DMT_Renew_Status__c.
 *              - Unlike the New Line flow, renewLine() re-reads the source line and its
 *                children directly from the database by Id instead of trusting a
 *                client-echoed JSON blob, since this operation duplicates financial/risk
 *                data end to end.
 */
public with sharing class DMT_RenewLineService {

    private static final String DEFAULT_ORIGIN = 'Salesforce';
    private static final String DEFAULT_ENTIFIC = 'HO';
    private static final String OPPORTUNITY_CODE_ORIGIN = 'ESCD';
    private static final String OPPORTUNITY_CODE_OPERATION_TYPE = 'LIN';
    private static final String RECORD_TYPE_TREASURY_SETTLEMENT = 'TreasurySettlement';
    private static final String RECORD_TYPE_OTHER_PRODUCTS = 'OtherProducts';
    private static final String CLIENT_TYPE_CUSTOMER = 'Customer';
    private static final String DEFAULT_TEAM_ACCESS_LEVEL = 'Read';

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getLineForRenewal(Id lineId) {
        try {
            if (lineId == null) {
                throw new AuraHandledException('lineId is required');
            }

            DMT_Line__c line = getSourceLine(lineId);
            List<DMT_Risk_Line_Term__c> riskTerms = getSourceRiskTerms(lineId);

            Map<String, Object> result = new Map<String, Object>();
            result.put('lineId', line.Id);
            result.put('lineName', line.Name);
            result.put('RecordTypeName', line.RecordType.DeveloperName);
            result.put('ClientName', line.Client__r != null ? line.Client__r.Name : '');
            result.put('clientId', line.Client__c);
            result.put('DES_Client_Type__c', line.Client_Type__c);
            result.put('clientCode', line.Client_Code__c);
            result.put('groupCode', line.Client_Code__c);
            result.put('Booking_Geography__c', line.Booking_Geography__c);
            result.put('productList', buildProductListForDisplay(line.RecordType.DeveloperName, riskTerms));

            return result;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_RenewLineService', 'getLineForRenewal', 'DMT', 'lineId=' + lineId);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Id renewLine(Id lineId, String lineName) {
        try {
            if (lineId == null || String.isBlank(lineName)) {
                throw new AuraHandledException('lineId and lineName are required');
            }
            if (!DMT_Utils.hasWriteAccess()) {
                throw new AuraHandledException('You do not have permission to renew lines');
            }

            DMT_Line__c source = getSourceLine(lineId);
            List<DMT_Risk_Line_Term__c> sourceRiskTerms = getSourceRiskTerms(lineId);
            List<DMT_Line_Product_Item__c> sourceProductItems = getSourceProductItems(lineId);
            List<DMT_TeamMember__c> sourceTeamMembers = getSourceTeamMembers(lineId);
            Custom_Association__c sourceAssociation = getSourceAssociation(source.Custom_Association__c);
            List<Custom_Association_Client__c> sourceAssociationClients = sourceAssociation != null
                ? getSourceAssociationClients(sourceAssociation.Id)
                : new List<Custom_Association_Client__c>();

            Date newStartDate = source.End_Date__c != null ? source.End_Date__c.addDays(1) : Date.today();
            Date newEndDate = resolveEndDate(source.RecordType.DeveloperName, newStartDate);

            DMT_Line__c newLine = buildNewLine(source, lineName, newStartDate, newEndDate);
            Database.insert(newLine, AccessLevel.USER_MODE);

            if (sourceAssociation != null) {
                Custom_Association__c newAssociation = buildNewAssociation(sourceAssociation, newLine.Id);
                Database.insert(newAssociation, AccessLevel.USER_MODE);

                newLine.Custom_Association__c = newAssociation.Id;
                Database.update(newLine, AccessLevel.USER_MODE);

                if (!sourceAssociationClients.isEmpty()) {
                    List<Custom_Association_Client__c> newAssociationClients = new List<Custom_Association_Client__c>();
                    for (Custom_Association_Client__c src : sourceAssociationClients) {
                        newAssociationClients.add(buildNewAssociationClient(src, newAssociation.Id));
                    }
                    Database.insert(newAssociationClients, AccessLevel.USER_MODE);
                }
            }

            if (!sourceRiskTerms.isEmpty()) {
                List<DMT_Risk_Line_Term__c> newRiskTerms = new List<DMT_Risk_Line_Term__c>();
                for (DMT_Risk_Line_Term__c src : sourceRiskTerms) {
                    newRiskTerms.add(buildNewRiskTerm(src, newLine.Id));
                }
                Database.insert(newRiskTerms, AccessLevel.USER_MODE);
            }

            if (!sourceProductItems.isEmpty()) {
                List<DMT_Line_Product_Item__c> newProductItems = new List<DMT_Line_Product_Item__c>();
                for (DMT_Line_Product_Item__c src : sourceProductItems) {
                    newProductItems.add(buildNewProductItem(src, newLine.Id));
                }
                Database.insert(newProductItems, AccessLevel.USER_MODE);
            }

            List<DMT_TeamMember__c> newTeamMembers = new List<DMT_TeamMember__c>();
            for (DMT_TeamMember__c src : sourceTeamMembers) {
                newTeamMembers.add(buildNewTeamMember(src, newLine.Id));
            }
            if (newTeamMembers.isEmpty()) {
                newTeamMembers.add(buildDefaultTeamMember(newLine.Id));
            }
            Database.insert(newTeamMembers, AccessLevel.USER_MODE);

            return newLine.Id;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_RenewLineService', 'renewLine', 'DMT', 'lineId=' + lineId);
            throw new AuraHandledException(e.getMessage());
        }
    }

    // =========================================================
    // Queries
    // =========================================================
    private static DMT_Line__c getSourceLine(Id lineId) {
        return [
            SELECT Id, Name, Client__c, Client__r.Name, Client_Code__c, Client_Type__c,
                   Booking_Geography__c, CurrencyIsoCode, Start_Date__c, End_Date__c,
                   Amount__c, Waiver__c, Repos_Limit__c, Repos_Limit_6M__c,
                   First_Breakclause__c, Breakclause_Frequency__c, DMT_Entity__c,
                   DMT_Comments__c, DMT_Additional_Restrictions__c, DMT_Approver__c,
                   DMT_ApproverGlobalBanker__c, DMT_Booking_Unit_Risk_Analyst__c,
                   DMT_Client_Use__c, DMT_Franchise_L12M__c, DMT_Nominal__c, DMT_Operation__c,
                   DMT_RAROEC_RORC_Proposal__c, DMT_LastLevelId__c, g_limit_last_level_type__c,
                   FD_Amount__c, DvP_Amount__c, RecordTypeId, RecordType.DeveloperName,
                   Custom_Association__c
            FROM DMT_Line__c
            WHERE Id = :lineId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    private static List<DMT_Risk_Line_Term__c> getSourceRiskTerms(Id lineId) {
        return [
            SELECT Id, Name, CurrencyIsoCode, DMT_Amount__c, DMT_Init_Term__c, DMT_End_Term__c,
                   DMT_Comments__c, DMT_ID_User__c, DMT_Product__c, DMT_Risk_Type__c,
                   DMT_LastLevelId__c, DMT_Renew_Status__c, DMT_Parent_Product__c,
                   g_branch_id__c, g_limit_sinds_ast_subsec_id__c, g_limit_sinds_ast_sctr_id__c,
                   g_expert_criteria_risk_type__c, g_multioperation_ind_type__c,
                   g_isda_waiver_ind_type__c, g_notary_crtfn_ind_type__c,
                   g_gtee_public_adm_ind_type__c, g_gbl_product_subcategory_id__c,
                   g_global_product_id__c, g_global_product_category_id__c,
                   g_global_product_subfamily_id__c, g_global_product_family_id__c,
                   g_bullet_ind_type__c, g_line_cond_guarantee_ind_type__c,
                   g_smscl_internal_ratg_type__c, gf_min_rorc_wo_fcg_per__c,
                   gf_min_rorc_fcg_per__c, gf_min_raroec_wo_fcg_per__c, gf_min_raroec_fcg_per__c,
                   gf_break_cl_days_number__c, gf_inscol_months_grace_number__c,
                   gf_loan_eca_cntrb_per__c, gf_loan_value_per__c, gf_revolvence_pd_days_number__c,
                   gf_prev_renewal_group_line_id__c, gf_group_priority_line_id__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :lineId
            WITH USER_MODE
            ORDER BY Id
        ];
    }

    private static List<DMT_Line_Product_Item__c> getSourceProductItems(Id lineId) {
        return [
            SELECT Id, Name, CurrencyIsoCode, Product__c, DMT_FDRestriction__c,
                   DMT_DVPRestriction__c, DMT_DerivativeRestriction__c, Product_Code_Value__c,
                   Max_Tenor_WC__c, Max_Tenor_WOC__c, g_global_product_subfamily_id__c,
                   g_global_product_id__c, g_global_product_category_id__c,
                   g_global_product_family_id__c, g_gbl_product_subcategory_id__c
            FROM DMT_Line_Product_Item__c
            WHERE Line__c = :lineId
            WITH USER_MODE
        ];
    }

    private static List<DMT_TeamMember__c> getSourceTeamMembers(Id lineId) {
        return [
            SELECT Id, Name, User__c, AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :lineId
            WITH USER_MODE
        ];
    }

    private static Custom_Association__c getSourceAssociation(Id associationId) {
        if (associationId == null) {
            return null;
        }
        List<Custom_Association__c> results = [
            SELECT Id, Name, CurrencyIsoCode, Group__c, g_group_id__c, g_customer_id__c,
                   gf_customer_group_id__c
            FROM Custom_Association__c
            WHERE Id = :associationId
            WITH USER_MODE
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    private static List<Custom_Association_Client__c> getSourceAssociationClients(Id associationId) {
        return [
            SELECT Id, Name, CurrencyIsoCode, DMT_FDAmount__c, DMT_DVPAmount__c, g_customer_id__c,
                   Alpha_Code_Client__c, DMT_Amount__c, DMT_Term__c
            FROM Custom_Association_Client__c
            WHERE Custom_Association__c = :associationId
            WITH USER_MODE
        ];
    }

    // =========================================================
    // Record builders (duplication)
    // =========================================================
    private static DMT_Line__c buildNewLine(DMT_Line__c source, String lineName, Date newStartDate, Date newEndDate) {
        DMT_Line__c newLine = new DMT_Line__c();
        newLine.Name = lineName;
        newLine.RecordTypeId = source.RecordTypeId;
        newLine.Client__c = source.Client__c;
        newLine.Client_Code__c = source.Client_Code__c;
        newLine.Booking_Geography__c = source.Booking_Geography__c;
        newLine.DMT_Client_Entific__c = source.Booking_Geography__c;
        newLine.CurrencyIsoCode = source.CurrencyIsoCode;
        newLine.Start_Date__c = newStartDate;
        newLine.End_Date__c = newEndDate;
        newLine.Amount__c = source.Amount__c;
        newLine.Waiver__c = source.Waiver__c;
        newLine.Repos_Limit__c = source.Repos_Limit__c;
        newLine.Repos_Limit_6M__c = source.Repos_Limit_6M__c;
        newLine.First_Breakclause__c = source.First_Breakclause__c;
        newLine.Breakclause_Frequency__c = source.Breakclause_Frequency__c;
        newLine.DMT_Entity__c = source.DMT_Entity__c;
        newLine.DMT_Comments__c = source.DMT_Comments__c;
        newLine.DMT_Additional_Restrictions__c = source.DMT_Additional_Restrictions__c;
        newLine.DMT_Approver__c = source.DMT_Approver__c;
        newLine.DMT_ApproverGlobalBanker__c = source.DMT_ApproverGlobalBanker__c;
        newLine.DMT_Booking_Unit_Risk_Analyst__c = source.DMT_Booking_Unit_Risk_Analyst__c;
        newLine.DMT_Client_Use__c = source.DMT_Client_Use__c;
        newLine.DMT_Franchise_L12M__c = source.DMT_Franchise_L12M__c;
        newLine.DMT_Nominal__c = source.DMT_Nominal__c;
        newLine.DMT_Operation__c = source.DMT_Operation__c;
        newLine.DMT_RAROEC_RORC_Proposal__c = source.DMT_RAROEC_RORC_Proposal__c;
        newLine.DMT_LastLevelId__c = source.DMT_LastLevelId__c;
        newLine.g_limit_last_level_type__c = source.g_limit_last_level_type__c;
        newLine.FD_Amount__c = source.FD_Amount__c;
        newLine.DvP_Amount__c = source.DvP_Amount__c;
        newLine.DMT_Origin__c = DEFAULT_ORIGIN;
        newLine.DMT_Parent_Line__c = source.Id;
        newLine.Line_Id__c = getExternalLineCode(source.Booking_Geography__c);
        return newLine;
    }

    private static Custom_Association__c buildNewAssociation(Custom_Association__c source, Id newLineId) {
        Custom_Association__c newAssociation = new Custom_Association__c();
        newAssociation.Name = source.Name;
        newAssociation.CurrencyIsoCode = source.CurrencyIsoCode;
        newAssociation.Group__c = source.Group__c;
        newAssociation.g_group_id__c = source.g_group_id__c;
        newAssociation.g_customer_id__c = source.g_customer_id__c;
        newAssociation.gf_customer_group_id__c = source.gf_customer_group_id__c;
        newAssociation.DMT_Line__c = newLineId;
        return newAssociation;
    }

    private static Custom_Association_Client__c buildNewAssociationClient(Custom_Association_Client__c source, Id newAssociationId) {
        Custom_Association_Client__c newClient = new Custom_Association_Client__c();
        newClient.Name = source.Name;
        newClient.CurrencyIsoCode = source.CurrencyIsoCode;
        newClient.DMT_FDAmount__c = source.DMT_FDAmount__c;
        newClient.DMT_DVPAmount__c = source.DMT_DVPAmount__c;
        newClient.g_customer_id__c = source.g_customer_id__c;
        newClient.Alpha_Code_Client__c = source.Alpha_Code_Client__c;
        newClient.DMT_Amount__c = source.DMT_Amount__c;
        newClient.DMT_Term__c = source.DMT_Term__c;
        newClient.Custom_Association__c = newAssociationId;
        return newClient;
    }

    private static DMT_Risk_Line_Term__c buildNewRiskTerm(DMT_Risk_Line_Term__c source, Id newLineId) {
        DMT_Risk_Line_Term__c newTerm = new DMT_Risk_Line_Term__c();
        newTerm.Name = source.Name;
        newTerm.CurrencyIsoCode = source.CurrencyIsoCode;
        newTerm.DMT_Amount__c = source.DMT_Amount__c;
        newTerm.DMT_Init_Term__c = source.DMT_Init_Term__c;
        newTerm.DMT_End_Term__c = source.DMT_End_Term__c;
        newTerm.DMT_Comments__c = source.DMT_Comments__c;
        newTerm.DMT_ID_User__c = source.DMT_ID_User__c;
        newTerm.DMT_Product__c = source.DMT_Product__c;
        newTerm.DMT_Risk_Type__c = source.DMT_Risk_Type__c;
        newTerm.DMT_LastLevelId__c = source.DMT_LastLevelId__c;
        newTerm.g_branch_id__c = source.g_branch_id__c;
        newTerm.g_limit_sinds_ast_subsec_id__c = source.g_limit_sinds_ast_subsec_id__c;
        newTerm.g_limit_sinds_ast_sctr_id__c = source.g_limit_sinds_ast_sctr_id__c;
        newTerm.g_expert_criteria_risk_type__c = source.g_expert_criteria_risk_type__c;
        newTerm.g_multioperation_ind_type__c = source.g_multioperation_ind_type__c;
        newTerm.g_isda_waiver_ind_type__c = source.g_isda_waiver_ind_type__c;
        newTerm.g_notary_crtfn_ind_type__c = source.g_notary_crtfn_ind_type__c;
        newTerm.g_gtee_public_adm_ind_type__c = source.g_gtee_public_adm_ind_type__c;
        newTerm.g_gbl_product_subcategory_id__c = source.g_gbl_product_subcategory_id__c;
        newTerm.g_global_product_id__c = source.g_global_product_id__c;
        newTerm.g_global_product_category_id__c = source.g_global_product_category_id__c;
        newTerm.g_global_product_subfamily_id__c = source.g_global_product_subfamily_id__c;
        newTerm.g_global_product_family_id__c = source.g_global_product_family_id__c;
        newTerm.g_bullet_ind_type__c = source.g_bullet_ind_type__c;
        newTerm.g_line_cond_guarantee_ind_type__c = source.g_line_cond_guarantee_ind_type__c;
        newTerm.g_smscl_internal_ratg_type__c = source.g_smscl_internal_ratg_type__c;
        newTerm.gf_min_rorc_wo_fcg_per__c = source.gf_min_rorc_wo_fcg_per__c;
        newTerm.gf_min_rorc_fcg_per__c = source.gf_min_rorc_fcg_per__c;
        newTerm.gf_min_raroec_wo_fcg_per__c = source.gf_min_raroec_wo_fcg_per__c;
        newTerm.gf_min_raroec_fcg_per__c = source.gf_min_raroec_fcg_per__c;
        newTerm.gf_break_cl_days_number__c = source.gf_break_cl_days_number__c;
        newTerm.gf_inscol_months_grace_number__c = source.gf_inscol_months_grace_number__c;
        newTerm.gf_loan_eca_cntrb_per__c = source.gf_loan_eca_cntrb_per__c;
        newTerm.gf_loan_value_per__c = source.gf_loan_value_per__c;
        newTerm.gf_revolvence_pd_days_number__c = source.gf_revolvence_pd_days_number__c;
        newTerm.gf_prev_renewal_group_line_id__c = source.gf_prev_renewal_group_line_id__c;
        newTerm.gf_group_priority_line_id__c = source.gf_group_priority_line_id__c;
        newTerm.DMT_Line__c = newLineId;
        newTerm.DMT_Parent_Product__c = source.Id;
        return newTerm;
    }

    private static DMT_Line_Product_Item__c buildNewProductItem(DMT_Line_Product_Item__c source, Id newLineId) {
        DMT_Line_Product_Item__c newItem = new DMT_Line_Product_Item__c();
        newItem.Name = source.Name;
        newItem.CurrencyIsoCode = source.CurrencyIsoCode;
        newItem.Product__c = source.Product__c;
        newItem.DMT_FDRestriction__c = source.DMT_FDRestriction__c;
        newItem.DMT_DVPRestriction__c = source.DMT_DVPRestriction__c;
        newItem.DMT_DerivativeRestriction__c = source.DMT_DerivativeRestriction__c;
        newItem.Product_Code_Value__c = source.Product_Code_Value__c;
        newItem.Max_Tenor_WC__c = source.Max_Tenor_WC__c;
        newItem.Max_Tenor_WOC__c = source.Max_Tenor_WOC__c;
        newItem.g_global_product_subfamily_id__c = source.g_global_product_subfamily_id__c;
        newItem.g_global_product_id__c = source.g_global_product_id__c;
        newItem.g_global_product_category_id__c = source.g_global_product_category_id__c;
        newItem.g_global_product_family_id__c = source.g_global_product_family_id__c;
        newItem.g_gbl_product_subcategory_id__c = source.g_gbl_product_subcategory_id__c;
        newItem.Line__c = newLineId;
        return newItem;
    }

    private static DMT_TeamMember__c buildNewTeamMember(DMT_TeamMember__c source, Id newLineId) {
        DMT_TeamMember__c newMember = new DMT_TeamMember__c();
        newMember.Name = source.Name;
        newMember.User__c = source.User__c != null ? source.User__c : UserInfo.getUserId();
        newMember.AccessLevel__c = String.isNotBlank(source.AccessLevel__c) ? source.AccessLevel__c : DEFAULT_TEAM_ACCESS_LEVEL;
        newMember.Line__c = newLineId;
        return newMember;
    }

    private static DMT_TeamMember__c buildDefaultTeamMember(Id newLineId) {
        DMT_TeamMember__c newMember = new DMT_TeamMember__c();
        newMember.User__c = UserInfo.getUserId();
        newMember.AccessLevel__c = DEFAULT_TEAM_ACCESS_LEVEL;
        newMember.Line__c = newLineId;
        return newMember;
    }

    // =========================================================
    // Helpers
    // =========================================================
    private static Date resolveEndDate(String recordTypeName, Date newStartDate) {
        if (recordTypeName == RECORD_TYPE_TREASURY_SETTLEMENT) {
            Date afterElevenMonths = newStartDate.addMonths(11);
            return Date.newInstance(afterElevenMonths.year(), afterElevenMonths.month(), Date.daysInMonth(afterElevenMonths.year(), afterElevenMonths.month()));
        }
        return newStartDate.addYears(1);
    }

    private static String getExternalLineCode(String bookingGeography) {
        Map<String, Object> request = new Map<String, Object>();
        request.put('origin', OPPORTUNITY_CODE_ORIGIN);
        request.put('operationType', OPPORTUNITY_CODE_OPERATION_TYPE);
        request.put('entific', String.isNotBlank(bookingGeography) ? bookingGeography : DEFAULT_ENTIFIC);

        DMT_OpportunityCodes.Wrapper response = DMT_OpportunityCodes.getOpportunityCode(request);
        return (response != null && response.data != null) ? response.data.opportunityId : null;
    }

    private static List<Map<String, Object>> buildProductListForDisplay(String recordTypeName, List<DMT_Risk_Line_Term__c> riskTerms) {
        List<Map<String, Object>> productList = new List<Map<String, Object>>();
        if (recordTypeName != RECORD_TYPE_OTHER_PRODUCTS) {
            return productList;
        }
        for (DMT_Risk_Line_Term__c term : riskTerms) {
            if (term.DMT_Parent_Product__c == term.Id) {
                Map<String, Object> item = new Map<String, Object>();
                item.put('Id', term.Id);
                item.put('Name', term.Name);
                item.put('value', 'true');
                item.put('disabled', 'true');
                productList.add(item);
            }
        }
        return productList;
    }
}