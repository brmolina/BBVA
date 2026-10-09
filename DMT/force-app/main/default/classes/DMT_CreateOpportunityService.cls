/**
 * @description Apex replacement for the OmniStudio Integration Procedure branch of
 *              "DealManagement_Screen" (isOpportunity == true) and its bootstrap
 *              "Dmt_IPCreateOpp", previously reached only via the DMT_MarcoGeneral
 *              FlexCard/PubSub bridge. Used by dmtNewOpportunityModal to load creation
 *              parameters and to create a new Opportunity (Subsidiary or Group flow)
 *              plus its related DMT_Opportunity_Client__c (and, for the Group flow,
 *              Custom_Association_Opportunity__c) records, without depending on
 *              OmniStudio Cards.
 *
 *              Design notes for future maintainers:
 *              - Reuses the same remote-action-equivalent static methods the original
 *                Integration Procedure called (DMT_Opportunity_Utils.getComparisonAccount,
 *                DMT_HPG_Utils.lastDate/getCustomerHPGS, DMT_Callout_LeveragedLending,
 *                DMT_GetCreationParameters.getEntityValues, DMT_OpportunityCodes.getOpportunityCode
 *                with operationType='OPP').
 *              - The ~90 financial/ESG fields copied from "GetClientValues:<name>" onto
 *                DMT_Opportunity_Client__c share the exact same API name as custom fields
 *                already present on the comparison Account, so they are copied dynamically
 *                (CLIENT_GROUP_COPY_FIELDS) instead of one assignment per field.
 *              - The Currency Conversion remote action (DMT_Currency_Conversion_Utils.
 *                DMT_Single_Amount_Conversion) requires an existing DMT_Line__c recordId to
 *                do anything; for a brand-new Opportunity that id never resolves to a real
 *                Line, so the conversion is always a no-op (amount kept as entered). That
 *                step is therefore intentionally not replicated here.
 */
public with sharing class DMT_CreateOpportunityService {

    private static final String TAXONOMY_ENTITY_CATALOG = 'h006';
    private static final String ENTITY_BY_ENTIFIC_CATALOG = 'H287';
    private static final String OPPORTUNITY_CODE_ORIGIN = 'ESCD';
    private static final String OPPORTUNITY_CODE_OPERATION_TYPE = 'OPP';
    private static final String DEFAULT_ENTIFIC = 'HO';
    private static final String NON_DISCLOSED_GROUP_CODE = 'GXXXXXXXXXXXXXX';
    private static final String NON_DISCLOSED_CUSTOMER_ID = 'ES0182XXXXXXXXX';
    private static final String NON_DISCLOSED_ACCOUNT_NAME = 'non - disclosed';
    private static final String SUBSIDIARY_CLIENT_TYPE = 'Subsidiary';
    private static final String RATING_TAXONOMY_CATALOG = 'C204';

    // Fields copied 1:1 (same API name on both objects) from the comparison Account
    // onto DMT_Opportunity_Client__c.
    // NOTE: Basic_Financials_Required_Fields__c and Business_Plan_Required_Fields__c are
    // deliberately NOT included here - they are formula fields on DMT_Opportunity_Client__c
    // (calculated from the Revenues_*/EBITDA_*/EBIT_*/Net_Income_*/Free_Cash_Flow_*/Past_FY_*
    // etc. fields below), so they are read-only and cannot be set via DML.
    private static final Set<String> CLIENT_GROUP_COPY_FIELDS = new Set<String>{
        'Current_FY_Cash_Management_amount__c', 'Current_FY_Client_Resources_amount__c', 'Current_FY_Corp_Synd_Lending_amount__c',
        'Current_FY_Credit_Equity_amount__c', 'Current_FY_DCM_amount__c', 'Current_FY_ECM_M_A_Amount__c', 'Current_FY_FX_CCS_amount__c',
        'Current_FY_GTF_amount__c', 'Current_FY_Rates_amount__c', 'Current_FY_Securities_Services_amount__c', 'Current_FY_Str_Trade_Finance_amount__c',
        'Current_FY_Structured_Finance_amount__c', 'Current_FY_Working_Capital_amount__c',
        'Debt_EBITDA_Current_Year_number__c', 'Debt_EBITDA_Last_Year_number__c', 'Debt_EBITDA_Next_Year_1_number__c',
        'Debt_EBITDA_Next_Year_2_number__c', 'Debt_EBITDA_Next_Year_number__c',
        'DMT_Currency__c',
        'EBIT_Current_Year_number__c', 'EBIT_Last_Year_number__c', 'EBIT_Next_Year_1_number__c', 'EBIT_Next_Year_2_number__c', 'EBIT_Next_Year_number__c',
        'EBITDA_Current_Year_number__c', 'EBITDA_Last_Year_number__c', 'EBITDA_Next_Year_1_number__c', 'EBITDA_Next_Year_2_number__c', 'EBITDA_Next_Year_number__c',
        'Free_Cash_Flow_Current_Year_number__c', 'Free_Cash_Flow_Last_Year_number__c', 'Free_Cash_Flow_Next_Year_1_number__c',
        'Free_Cash_Flow_Next_Year_2_number__c', 'Free_Cash_Flow_Next_Year_number__c',
        'gf_customer_sustnbl_strg_desc__c',
        'gf_kpi_trans_fees_2ya_amount__c', 'gf_kpi_trans_fees_cyr_amount__c', 'gf_kpi_trans_fees_ly_amount__c', 'gf_kpi_trans_fees_nxy_amount__c',
        'gf_xb_cust_ope_revenue_2ya_per__c', 'gf_xb_cust_ope_revenue_cyr_per__c', 'gf_xb_cust_ope_revenue_ly_per__c', 'gf_xb_cust_ope_revenue_nxy_per__c',
        'Net_Debt_EBITDA_Current_Year_number__c', 'Net_Debt_EBITDA_Last_Year_number__c', 'Net_Debt_EBITDA_Next_Year_1_number__c',
        'Net_Debt_EBITDA_Next_Year_2_number__c', 'Net_Debt_EBITDA_Next_Year_number__c',
        'Net_Income_Current_Year_number__c', 'Net_Income_Last_Year_number__c', 'Net_Income_Next_Year_1_number__c',
        'Net_Income_Next_Year_2_number__c', 'Net_Income_Next_Year_number__c',
        'Next_FY_Cash_Management_amount__c', 'Next_FY_Client_Resources_amount__c', 'Next_FY_Corp_Synd_Lending_amount__c',
        'Next_FY_Credit_Equity_amount__c', 'Next_FY_DCM_amount__c', 'Next_FY_ECM_M_A_amount__c', 'Next_FY_FX_CCS_amount__c',
        'Next_FY_GTF_amount__c', 'Next_FY_Rates_amount__c', 'Next_FY_Securities_Services_amount__c',
        'Next_FY_Str_Trade_Finance_amount__c', 'Next_FY_Structured_Finance_amount__c', 'Next_FY_Working_Capital_amount__c',
        'Past_FY_Cash_Management_amount__c', 'Past_FY_Client_Resources_amount__c', 'Past_FY_Corp_Synd_Lending_amount__c',
        'Past_FY_Credit_Equity_amount__c', 'Past_FY_DCM_amount__c', 'Past_FY_ECM_M_A_Amount__c', 'Past_FY_FX_CCS_amount__c',
        'Past_FY_GTF_amount__c', 'Past_FY_Rates_amount__c', 'Past_FY_Securities_Services_amount__c',
        'Past_FY_Str_Trade_Finance_amount__c', 'Past_FY_Structured_Finance_amount__c', 'Past_FY_Working_Capital_amount__c',
        'Past2_FY_Cash_Management_amount__c', 'Past2_FY_Client_Resources_amount__c', 'Past2_FY_Corp_Synd_Lending_amount__c',
        'Past2_FY_Credit_Equity_amount__c', 'Past2_FY_DCM_amount__c', 'Past2_FY_ECM_M_A_Amount__c', 'Past2_FY_FX_CCS_amount__c',
        'Past2_FY_GTF_amount__c', 'Past2_FY_Rates_amount__c', 'Past2_FY_Securities_Services_amount__c',
        'Past2_FY_Str_Trade_Finance_amount__c', 'Past2_FY_Structured_Finance_amount__c', 'Past2_FY_Working_Capital_amount__c',
        'Revenues_Current_Year_number__c', 'Revenues_Last_Year_number__c', 'Revenues_Next_Year_1_number__c',
        'Revenues_Next_Year_2_number__c', 'Revenues_Next_Year_number__c'
    };

    // cstk__ (Customer Sustainability Toolkit) source field -> DMT_Opportunity_Client__c target field.
    private static final Map<String, String> CSTK_FIELD_TARGET_MAP = new Map<String, String>{
        'cstk__controversy__c' => 'DMT_reputational_risk__c',
        'cstk__gf_tri_final_score_number__c' => 'DMT_tri__c',
        'cstk__engagement_plan__c' => 'DMT_Group_Engagement_Plan__c',
        'cstk__g_thermal_coal_exps_ind_type__c' => 'DMT_Group_Have_Exposure_To_Thermal_Coal__c',
        'cstk__g_coal_prgrsv_red_pl_ind_type__c' => 'DMT_Company_Have_A_Coal_Phase_Out_Plan__c',
        'cstk__gf_thermal_coal_prod_wg_per__c' => 'DMT_Capacity_Weight__c',
        'cstk__company_affected_by_framework__c' => 'DMT_Enviromental_Social_Framework__c'
    };

    // =========================================================
    // BOOTSTRAP (GET_OPPORTUNITY_INFO -> Dmt_IPCreateOpp)
    // =========================================================
    /**
     * DMT_Creation_Line_Parameters__mdt.DMT_Operation_Type__c stores the Opportunity
     * permission entries with the RecordType LABEL ('DMT Opportunity', with a space) instead
     * of its DeveloperName ('DMT_Opportunity'). getLineCreationParameters() filters that
     * metadata by whatever recordTypeName it receives, so it must be called with this label
     * (not the DeveloperName) or the permission/booking-geography lookup always comes back empty.
     */
    private static final String OPPORTUNITY_OPERATION_TYPE_LABEL = 'DMT Opportunity';
    
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getOpportunityCreationParameters(Id clientId, String groupId, String recordTypeName) {
        try {
            Map<String, Object> base = DMT_CreateLineService.getLineCreationParameters(clientId, groupId, OPPORTUNITY_OPERATION_TYPE_LABEL);
            // Restore the DeveloperName so downstream createOpportunity() can resolve the RecordTypeId.
            base.put('RecordTypeName', recordTypeName);
            String bookingGeography = (String) base.get('BookingGeography');
            Boolean isSubsidiary = base.get('DES_Client_Type__c') == SUBSIDIARY_CLIENT_TYPE;

            List<Map<String, Object>> entityOptions = getEntityOptionsByEntific(bookingGeography);

            String initialEntity;
            if (isSubsidiary) {
                initialEntity = new DMT_GetCreationParameters().getEntityValues(TAXONOMY_ENTITY_CATALOG, bookingGeography);
            } else if (!entityOptions.isEmpty()) {
                initialEntity = (String) entityOptions[0].get('value');
            }

            base.put('entityOptions', entityOptions);
            base.put('oppEntity', initialEntity);
            base.put('entityDisabled', isSubsidiary);
            // Matches the original IP formula: entificDisabled = IF(isSubsidiary == true, true, false).
            // Without this, the LWC's `ip.entificDisabled !== false` check always defaulted to
            // disabled (undefined !== false), permanently locking the Booking Geography combobox
            // for the Group flow and breaking country/client resolution end-to-end.
            base.put('entificDisabled', isSubsidiary);
            base.put('isSubsidiary', isSubsidiary);
            String clientName = getAccountName(clientId);
            base.put('ClientName', clientName);
            // Default name suggestion, matches the original DataRaptor formula:
            // CONCAT("Opportunity ", Account:Name, " ", YEAR(today)).
            base.put('oppName', String.isNotBlank(clientName)
                ? 'Opportunity ' + clientName + ' ' + String.valueOf(Date.today().year())
                : '');
            // Default endDate suggestion: today + 3 months (matches the original IP default).
            base.put('endDate', Date.today().addMonths(3));
            List<Map<String, Object>> clientsByGroup = isSubsidiary ? new List<Map<String, Object>>() : getClientsByGroup(clientId, groupId);
            base.put('clientsByGroup', clientsByGroup);
            System.debug('DMT_DEBUG getOpportunityCreationParameters: clientId=' + clientId + ' groupId=' + groupId
                + ' isSubsidiary=' + isSubsidiary + ' bookingGeography=' + bookingGeography
                + ' clientsByGroup=' + JSON.serialize(clientsByGroup));
            return base;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_CreateOpportunityService', 'getOpportunityCreationParameters', 'DMT', '');
            throw new AuraHandledException('Error loading opportunity creation parameters: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> refreshEntityOptions(String entific) {
        try {
            return getEntityOptionsByEntific(entific);
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_CreateOpportunityService', 'refreshEntityOptions', 'DMT', '');
            throw new AuraHandledException('Error refreshing entity options: ' + e.getMessage());
        }
    }

    // =========================================================
    // CREATE (CREATE_NEW_OPPORTUNITY -> DealManagement_Screen, isOpportunity=true)
    // =========================================================
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> createOpportunity(
        String recordTypeName,
        String name,
        Date startDate,
        Date endDate,
        Id clientId,
        String clientType,
        String bookingGeography,
        String oppEntity,
        Decimal marginPb,
        Decimal notionalAmount,
        Decimal timeLimit,
        Id approverId,
        Boolean isDummyOpp,
        String segment,
        String groupCode,
        List<Map<String, Object>> clientsByGroup
    ) {
        try {
            if (String.isBlank(recordTypeName) || clientId == null) {
                throw new AuraHandledException('recordTypeName and clientId are required');
            }

            Boolean isSubsidiaryFlow = clientType == SUBSIDIARY_CLIENT_TYPE;

            System.debug('DMT_DEBUG createOpportunity INPUT: clientId=' + clientId + ' clientType=' + clientType
                + ' bookingGeography=' + bookingGeography + ' groupCode=' + groupCode
                + ' clientsByGroup=' + JSON.serialize(clientsByGroup));

            // Group flow: resolve the actual per-country client using the group's client list
            // (mirrors the DmTransformGetClientByEntific DataRaptor).
            Id resolvedClientId = clientId;
            if (!isSubsidiaryFlow && clientsByGroup != null) {
                Id groupResolvedClientId = resolveClientByEntific(clientsByGroup, bookingGeography);
                if (groupResolvedClientId != null) {
                    resolvedClientId = groupResolvedClientId;
                }
            }
            System.debug('DMT_DEBUG createOpportunity: isSubsidiaryFlow=' + isSubsidiaryFlow
                + ' resolvedClientId=' + resolvedClientId + ' (raw clientId=' + clientId + ')');

            // RAGetComparisonAccount: for the Group flow the ancestor walk starts from the
            // ORIGINAL (group) client id; for Subsidiary it starts from the resolved client id.
            Map<String, Object> comparisonInput = new Map<String, Object>{
                'oppAccountId' => (isSubsidiaryFlow ? resolvedClientId : clientId)
            };
            Map<String, Object> comparisonResult = DMT_Opportunity_Utils.getComparisonAccount(
                comparisonInput, new Map<String, Object>(), new Map<String, Object>()
            );
           
            Id comparisonAccountId = (Id) comparisonResult.get('comparisonAccountId');
            System.debug('DMT_DEBUG createOpportunity: comparisonResult=' + comparisonAccountId);
            ClientValues clientValues = getClientValues(resolvedClientId, comparisonAccountId);

            // DmtDrtGetOppClient2 (original DataRaptor) resolves both RemoteAction1.clientId and
            // RemoteAction1.customerId from the actual local client account: resolvedClientId
            // (for Subsidiary it IS clientId; for Group it's the per-country client resolved via
            // resolveClientByEntific/clientsByGroup). It must NOT be the raw Group account (clientId
            // in the Group flow), which normally has neither a Prospect_Subsidiary RecordType nor a
            // Local_Client__c record of its own - using it left customerId (and every HPG-sourced
            // DMT_Opportunity_Client__c field) empty for the Group flow.
            // customerId formula: IF(ProspectSubsidiary != null, ProspectSubsidiary.g_customer_id__c,
            // Local_Client__c.Alpha_code__c) where ProspectSubsidiary is that same account re-queried
            // with RecordType.DeveloperName = 'Prospect_Subsidiary'. comparisonAccountId is a
            // DIFFERENT account (used only for the financial CLIENT_GROUP_COPY_FIELDS comparison)
            // and must not be used here.
            String customerId = (clientValues.groupCode == NON_DISCLOSED_GROUP_CODE)
                ? NON_DISCLOSED_CUSTOMER_ID
                : resolveHpgCustomerId(resolvedClientId);

            System.debug('DMT_DEBUG createOpportunity: clientValues.groupCode=' + clientValues.groupCode
                + ' clientValues.clientGCustomerId=' + clientValues.clientGCustomerId
                + ' clientValues.industry=' + clientValues.industry + ' customerId=' + customerId);

            String lastDate = DMT_HPG_Utils.lastDate();

            Map<String, Object> hpgsInput = new Map<String, Object>{
                'clientId' => resolvedClientId,
                'customerId' => customerId,
                'lastDate' => lastDate
            };
            Map<String, Object> hpgsOutput = DMT_HPG_Utils.getCustomerHPGS(
                hpgsInput, new Map<String, Object>(), new Map<String, Object>()
            );
            DMT_HPG_GlobalPosition.Data customerHPG = (DMT_HPG_GlobalPosition.Data) hpgsOutput.get('CustomerHPG');
            System.debug('DMT_DEBUG createOpportunity: customerHPG is ' + (customerHPG == null ? 'NULL (no HPG match)' : 'FOUND'));

            Map<String, Object> leveragedLendingOutput = DMT_Callout_LeveragedLending.callLeveragedLendingService(
                clientValues.groupCode, lastDate, new Map<String, Object>()
            );
            String leveragedLendingIndType = (leveragedLendingOutput != null) ? (String) leveragedLendingOutput.get('leveragedLendingIndType') : null;

            String divisaOpp = resolveCurrencyForEntity(oppEntity);
            String lineId = getOpportunityCode(bookingGeography);
            String branchId = (String.isBlank(oppEntity) || String.isBlank(bookingGeography))
                ? null
                : oppEntity + '-' + bookingGeography;

            Opportunity newOpp = new Opportunity();
            newOpp.RecordTypeId = getOpportunityRecordTypeId(recordTypeName);
            newOpp.Name = name;
            newOpp.StageName = 'Draft';
            newOpp.CloseDate = Date.today().addMonths(3);
            newOpp.AccountId = isSubsidiaryFlow ? resolvedClientId : clientId;
            newOpp.CurrencyIsoCode = divisaOpp;
            newOpp.DMT_CurrencyText__c = divisaOpp;
            newOpp.DMT_ApproverGlobalBanker__c = approverId;
            newOpp.DMT_branch_id_c__c = branchId;
            newOpp.DMT_CUR_Margin_PB__c = marginPb;
            newOpp.DMT_CUR_Notional_Amount__c = notionalAmount;
            newOpp.DMT_DATE_Initial_Date__c = startDate;
            newOpp.DMT_DATE_Maturity_Date__c = Date.today().addMonths(3);
            newOpp.DMT_Entity__c = oppEntity;
            newOpp.dmt_isDraft_opp__c = (isDummyOpp != null && isDummyOpp) || clientValues.isNonDisclosedClient;
            newOpp.DMT_NUM_Time_Limit__c = timeLimit;
            newOpp.DMT_NUM_Version__c = 1;
            newOpp.DMT_Opp_Id__c = lineId;
            newOpp.Entific__c = bookingGeography;

            Database.insert(newOpp, AccessLevel.USER_MODE);

            DMT_Opportunity_Client__c oppClient = buildOpportunityClient(
                newOpp.Id, clientValues, customerHPG, leveragedLendingIndType, segment
            );

            if (isSubsidiaryFlow) {
                Database.insert(oppClient, AccessLevel.USER_MODE);
            } else {
                Custom_Association_Opportunity__c assoc = new Custom_Association_Opportunity__c(
                    Opportunity__c = newOpp.Id,
                    Group__c = clientId,
                    CurrencyIsoCode = divisaOpp,
                    g_customer_id__c = clientValues.clientGCustomerId,
                    g_group_id__c = groupCode,
                    gf_customer_group_id__c = lineId
                );
                Database.insert(assoc, AccessLevel.USER_MODE);

                DMT_Custom_Association_ClientOpportunity__c clientOppAssoc = new DMT_Custom_Association_ClientOpportunity__c(
                    DMT_Custom_Association_Opportunity__c = assoc.Id,
                    DMT_g_entific_id__c = bookingGeography,
                    DMT_g_customer_id__c = clientValues.clientGCustomerId,
                    DMT_gf_customer_group_id__c = lineId
                );
                Database.insert(clientOppAssoc, AccessLevel.USER_MODE);

                oppClient.Custom_Association__c = assoc.Id;
                oppClient.Alpha_Code_Client__c = clientValues.clientGCustomerId;
                Database.insert(oppClient, AccessLevel.USER_MODE);
            }

            return new Map<String, Object>{
                'createdId' => newOpp.Id,
                'createdName' => newOpp.Name,
                'clientRecordId' => oppClient.Id
            };
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_CreateOpportunityService', 'createOpportunity', 'DMT', '');
            throw new AuraHandledException('Error creating opportunity: ' + e.getMessage());
        }
    }

    // =========================================================
    // Helpers
    // =========================================================
    private static String getAccountName(Id clientId) {
        if (clientId == null) {
            return '';
        }
        List<Account> accounts = [SELECT Name FROM Account WHERE Id = :clientId WITH USER_MODE LIMIT 1];
        return accounts.isEmpty() ? '' : accounts[0].Name;
    }

    /**
     * @description Resolves one representative Salesforce client Account per country for the
     *              Group, using the SAME HPG "client positions" service and country-resolution
     *              algorithm as the already-working dmt_MainClientSelectionTable LWC
     *              (sendGroupEvent/fetchClientsForCountryMapping): fetch the Group's HPG client
     *              positions (DMT_HPG_MainTableCustomController.fetchClientDataFromService),
     *              derive each row's country from its external customerId prefix, then resolve
     *              one Salesforce Account id per country via getSalesforceAccountIdsByCustomerIds.
     *              REPLACES a previous direct Account SOQL query on DES_Group_Code__c, which
     *              matched hundreds/thousands of unrelated Accounts for large groups and caused
     *              resolveClientByEntific() to resolve an essentially arbitrary wrong client,
     *              leaving DMT_Opportunity_Client__c fields empty/incorrect for the Group flow.
     */
    @TestVisible
    private static List<Map<String, Object>> getClientsByGroup(Id groupClientId, String groupId) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        if (groupClientId == null) {
            System.debug('DMT_DEBUG getClientsByGroup: groupClientId is null, returning empty list');
            return result;
        }

        // HPG only has data for its last computed snapshot date, not for the literal current
        // calendar date - Date.today() reliably returns 0 rows (success=true, totalElements=0).
        // Same lastDate() used elsewhere in this class (createOpportunity) and by
        // dmt_MainClientSelectionTable's parent page for its searchDate prop.
        Date searchDate = Date.valueOf(DMT_HPG_Utils.lastDate());

        // "With Exposure" (Y) first; if that comes back empty, fall back to all positions (Y/N) -
        // same two-step strategy as dmt_MainClientSelectionTable.fetchClientsForCountryMapping().
        List<String> customerIds = fetchGroupCustomerIds(groupClientId, 'Y', searchDate);
        System.debug('DMT_DEBUG getClientsByGroup: groupClientId=' + groupClientId + ' searchDate=' + searchDate
            + ' clientPositionsType=Y -> ' + customerIds.size() + ' customerId(s): ' + JSON.serialize(customerIds));
        if (customerIds.isEmpty()) {
            customerIds = fetchGroupCustomerIds(groupClientId, 'Y/N', searchDate);
            System.debug('DMT_DEBUG getClientsByGroup: groupClientId=' + groupClientId + ' fallback clientPositionsType=Y/N -> '
                + customerIds.size() + ' customerId(s): ' + JSON.serialize(customerIds));
        }
        System.debug('DMT_DEBUG getClientsByGroup: groupId=' + groupId + ' groupClientId=' + groupClientId
            + ' resolved ' + customerIds.size() + ' external customerId(s) from HPG (total)');
        if (customerIds.isEmpty()) {
            return result;
        }

        Map<String, Id> accountIdsByCustomerId = DMT_HPG_MainTableCustomController.getSalesforceAccountIdsByCustomerIds(customerIds);
        System.debug('DMT_DEBUG getClientsByGroup: getSalesforceAccountIdsByCustomerIds resolved '
            + accountIdsByCustomerId.size() + ' of ' + customerIds.size() + ' customerId(s): '
            + JSON.serialize(accountIdsByCustomerId));

        Map<String, List<String>> customerIdsByCountry = new Map<String, List<String>>();
        for (String custId : customerIds) {
            if (String.isBlank(custId) || custId.length() < 2) {
                continue;
            }
            String country = custId.substring(0, 2);
            if (!customerIdsByCountry.containsKey(country)) {
                customerIdsByCountry.put(country, new List<String>());
            }
            customerIdsByCountry.get(country).add(custId);
        }

        // One representative Salesforce client per country: the first customerId of that
        // country that resolves to a real Account (mirrors sendGroupEvent()'s
        // `externalIds.find(id => resultMap[id])`).
        for (String country : customerIdsByCountry.keySet()) {
            for (String custId : customerIdsByCountry.get(country)) {
                if (accountIdsByCustomerId.containsKey(custId)) {
                    result.add(new Map<String, Object>{ 'country' => country, 'clientId' => accountIdsByCustomerId.get(custId) });
                    break;
                }
            }
        }
        System.debug('DMT_DEBUG getClientsByGroup: result=' + JSON.serialize(result));
        return result;
    }

    /**
     * @description Fetches every HPG client-position row for the Group (paginating through all
     *              pages, same as dmt_MainClientSelectionTable's fetchMore loop) and returns the
     *              raw external customerId of each row. maxPages is a safety cap to avoid an
     *              unbounded callout loop if the HPG service ever returns a bad pagination payload.
     */
    @TestVisible
    private static List<String> fetchGroupCustomerIds(Id groupClientId, String clientPositionsType, Date searchDate) {
        List<String> customerIds = new List<String>();
        Integer page = 1;
        Integer totalPages = 1;
        Integer maxPages = 20;

        do {
            DMT_HPG_GlobalPosition.Wrapper response = DMT_HPG_MainTableCustomController.fetchClientDataFromService(
                groupClientId, String.valueOf(page), '500', new List<String>(), searchDate, clientPositionsType, ''
            );
            System.debug('DMT_DEBUG fetchGroupCustomerIds: groupClientId=' + groupClientId
                + ' clientPositionsType=' + clientPositionsType + ' page=' + page
                + ' response=' + (response == null ? 'NULL' : ('success=' + response.success
                    + ' errorMessage=' + response.errorMessage
                    + ' data.size=' + (response.data == null ? 'NULL' : String.valueOf(response.data.size()))
                    + ' pagination=' + (response.pagination == null ? 'NULL' : JSON.serialize(response.pagination)))));
            if (response == null || response.success != true || response.data == null) {
                break;
            }
            for (DMT_HPG_GlobalPosition.Data row : response.data) {
                if (String.isNotBlank(row.customerId)) {
                    customerIds.add(row.customerId);
                }
            }
            totalPages = (response.pagination != null && response.pagination.totalPages != null)
                ? response.pagination.totalPages
                : 1;
            page++;
        } while (page <= totalPages && page <= maxPages);

        return customerIds;
    }

    private static List<Map<String, Object>> getEntityOptionsByEntific(String entific) {
        List<Map<String, Object>> options = new List<Map<String, Object>>();
        if (String.isBlank(entific)) {
            return options;
        }
        List<DMT_Taxonomy_Relationship__c> relationships = [
            SELECT DMT_Final_Taxonomy_Value__c
            FROM DMT_Taxonomy_Relationship__c
            WHERE DMT_Id_Catalog__c = :ENTITY_BY_ENTIFIC_CATALOG AND DMT_Value_Catalog_Initial__c = :entific
            WITH USER_MODE
        ];
        Set<Id> finalValueIds = new Set<Id>();
        for (DMT_Taxonomy_Relationship__c rel : relationships) {
            if (rel.DMT_Final_Taxonomy_Value__c != null) {
                finalValueIds.add(rel.DMT_Final_Taxonomy_Value__c);
            }
        }
        if (finalValueIds.isEmpty()) {
            return options;
        }
        for (DMT_Taxonomy_Values__c tv : [
            SELECT DMT_Name__c, DMT_Value__c
            FROM DMT_Taxonomy_Values__c
            WHERE Id IN :finalValueIds
            WITH USER_MODE
        ]) {
            options.add(new Map<String, Object>{ 'label' => tv.DMT_Name__c, 'value' => tv.DMT_Value__c });
        }
        return options;
    }

    private static String resolveCurrencyForEntity(String entity) {
        if (String.isBlank(entity)) {
            return null;
        }
        List<DMT_Taxonomy_Values__c> rows = [
            SELECT CurrencyIsoCode
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c = :TAXONOMY_ENTITY_CATALOG AND DMT_Value__c = :entity
            WITH USER_MODE
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0].CurrencyIsoCode;
    }

    /**
     * @description Replicates DmtDrtGetOppClient2's customerId formula:
     *              IF(ProspectSubsidiary != null, ProspectSubsidiary.g_customer_id__c, Local_Client__c.Alpha_code__c)
     *              where ProspectSubsidiary re-queries the same accountId filtered to
     *              RecordType.DeveloperName = 'Prospect_Subsidiary'. This is the value the HPG
     *              service matches against (RemoteAction1.customerId in Opportunity_GetOppClient_Procedure).
     */
    private static String resolveHpgCustomerId(Id accountId) {
        if (accountId == null) {
            return null;
        }
        List<Account> accounts = [
            SELECT Id, g_customer_id__c, RecordType.DeveloperName
            FROM Account
            WHERE Id = :accountId
            WITH USER_MODE
            LIMIT 1
        ];
        if (accounts.isEmpty()) {
            return null;
        }
        if (accounts[0].RecordType.DeveloperName == 'Prospect_Subsidiary') {
            return accounts[0].g_customer_id__c;
        }
        List<Local_Client__c> localClients = [
            SELECT Alpha_code__c
            FROM Local_Client__c
            WHERE Cib_Client__c = :accountId
            WITH USER_MODE
            LIMIT 1
        ];
        return localClients.isEmpty() ? null : localClients[0].Alpha_code__c;
    }

    private static String getOpportunityCode(String bookingGeography) {
        Map<String, Object> request = new Map<String, Object>();
        request.put('origin', OPPORTUNITY_CODE_ORIGIN);
        request.put('operationType', OPPORTUNITY_CODE_OPERATION_TYPE);
        request.put('entific', String.isNotBlank(bookingGeography) ? bookingGeography : DEFAULT_ENTIFIC);

        DMT_OpportunityCodes.Wrapper response = DMT_OpportunityCodes.getOpportunityCode(request);
        return (response != null && response.data != null) ? response.data.opportunityId : null;
    }

    private static Id getOpportunityRecordTypeId(String recordTypeName) {
        Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(recordTypeName);
        if (rtInfo == null) {
            throw new AuraHandledException('Invalid opportunity record type: ' + recordTypeName);
        }
        return rtInfo.getRecordTypeId();
    }

    private static Id resolveClientByEntific(List<Map<String, Object>> clientsByGroup, String bookingGeography) {
        System.debug('DMT_DEBUG resolveClientByEntific: bookingGeography=' + bookingGeography
            + ' clientsByGroup=' + JSON.serialize(clientsByGroup));
        if (clientsByGroup == null || String.isBlank(bookingGeography)) {
            System.debug('DMT_DEBUG resolveClientByEntific: no match possible (null list or blank bookingGeography)');
            return null;
        }
        for (Map<String, Object> entry : clientsByGroup) {
            if (bookingGeography.equals(entry.get('country'))) {
                Object clientIdValue = entry.get('clientId');
                if (clientIdValue != null) {
                    System.debug('DMT_DEBUG resolveClientByEntific: MATCH found, clientId=' + clientIdValue);
                    return (Id) String.valueOf(clientIdValue);
                }
            }
        }
        System.debug('DMT_DEBUG resolveClientByEntific: NO MATCH for bookingGeography=' + bookingGeography);
        return null;
    }
    @TestVisible
    public static ClientValues getClientValues(Id resolvedClientId, Id comparisonAccountId) {
        ClientValues cv = new ClientValues();

        if (resolvedClientId != null) {
            List<Account> clientRows = [
                SELECT Name, Industry, DES_Group_Code__c, DES_Main_Parent__r.DES_Group_Code__c,
                       g_customer_id__c, DES_Segment__c
                FROM Account
                WHERE Id = :resolvedClientId
                WITH USER_MODE
                LIMIT 1
            ];
            if (!clientRows.isEmpty()) {
                cv.industry = clientRows[0].Industry;
                String parentGroupCode = clientRows[0].DES_Main_Parent__r != null
                    ? clientRows[0].DES_Main_Parent__r.DES_Group_Code__c
                    : null;
                cv.groupCode = String.isNotBlank(parentGroupCode)
                    ? parentGroupCode
                    : clientRows[0].DES_Group_Code__c;
                cv.clientGCustomerId = clientRows[0].g_customer_id__c;
                cv.segmentLabel = resolveSegmentLabel(clientRows[0].DES_Segment__c);
                if (clientRows[0].Name == NON_DISCLOSED_ACCOUNT_NAME) {
                    cv.isNonDisclosedClient = true;
                }
            }
        }

        if (comparisonAccountId != null) {
            // Some CLIENT_GROUP_COPY_FIELDS entries may exist in local metadata but not yet be
            // deployed to this org. Filter against the live Account describe so a missing/
            // undeployed field can't blow up the whole dynamic query with "No such column ..."
            // - it's simply skipped (left null) instead.
            Map<String, Schema.SObjectField> accountFieldMap = Schema.SObjectType.Account.fields.getMap();
            Set<String> queryableFields = new Set<String>();
            for (String fieldName : CLIENT_GROUP_COPY_FIELDS) {
                if (accountFieldMap.containsKey(fieldName.toLowerCase())) {
                    queryableFields.add(fieldName);
                }
            }

            String fieldList = 'Id, Name' + (queryableFields.isEmpty() ? '' : ', ' + String.join(new List<String>(queryableFields), ', '));
            String soql = 'SELECT ' + fieldList + ' FROM Account WHERE Id = :comparisonAccountId LIMIT 1';
            List<Account> groupRows = Database.query(soql, AccessLevel.USER_MODE);
            if (!groupRows.isEmpty()) {
                Account groupAccount = groupRows[0];
                if (groupAccount.Name == NON_DISCLOSED_ACCOUNT_NAME) {
                    cv.isNonDisclosedClient = true;
                }
                for (String fieldName : queryableFields) {
                    cv.financialFields.put(fieldName, groupAccount.get(fieldName));
                }
            }

            // cstk__ (Customer Sustainability Toolkit) chain: Account -> cstk__Toolkit__c ->
            // cstk__General_Data__c / cstk__Strategy__c (latest cstk__year__c).
            List<cstk__Toolkit__c> toolkits = [
                SELECT Id
                FROM cstk__Toolkit__c
                WHERE cstk__account_id__c = :comparisonAccountId
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!toolkits.isEmpty()) {
                Id toolkitId = toolkits[0].Id;

                List<cstk__General_Data__c> generalData = [
                    SELECT cstk__controversy__c, cstk__gf_tri_final_score_number__c
                    FROM cstk__General_Data__c
                    WHERE cstk__toolkit_id__c = :toolkitId
                    WITH USER_MODE
                    ORDER BY cstk__year__c DESC
                    LIMIT 1
                ];
                if (!generalData.isEmpty()) {
                    cv.financialFields.put('cstk__controversy__c', generalData[0].cstk__controversy__c);
                    cv.financialFields.put('cstk__gf_tri_final_score_number__c', generalData[0].cstk__gf_tri_final_score_number__c);
                }

                List<cstk__Strategy__c> strategyData = [
                    SELECT cstk__company_affected_by_framework__c, cstk__engagement_plan__c,
                           cstk__g_coal_prgrsv_red_pl_ind_type__c, cstk__g_thermal_coal_exps_ind_type__c,
                           cstk__gf_thermal_coal_prod_wg_per__c
                    FROM cstk__Strategy__c
                    WHERE cstk__toolkit_id__c = :toolkitId
                    WITH USER_MODE
                    ORDER BY cstk__year__c DESC
                    LIMIT 1
                ];
                if (!strategyData.isEmpty()) {
                    cv.financialFields.put('cstk__company_affected_by_framework__c', strategyData[0].cstk__company_affected_by_framework__c);
                    cv.financialFields.put('cstk__engagement_plan__c', strategyData[0].cstk__engagement_plan__c);
                    cv.financialFields.put('cstk__g_coal_prgrsv_red_pl_ind_type__c', strategyData[0].cstk__g_coal_prgrsv_red_pl_ind_type__c);
                    cv.financialFields.put('cstk__g_thermal_coal_exps_ind_type__c', strategyData[0].cstk__g_thermal_coal_exps_ind_type__c);
                    cv.financialFields.put('cstk__gf_thermal_coal_prod_wg_per__c', strategyData[0].cstk__gf_thermal_coal_prod_wg_per__c);
                }
            }
        }

        return cv;
    }
    
    public static DMT_Opportunity_Client__c buildOpportunityClient(
        Id opportunityId,
        ClientValues clientValues,
        DMT_HPG_GlobalPosition.Data customerHPG,
        String leveragedLendingIndType,
        String segment
    ) {
        DMT_Opportunity_Client__c oppClient = new DMT_Opportunity_Client__c();
        oppClient.DMT_MDE_Opportunity__c = opportunityId;
        oppClient.Counterpart__c = clientValues.segmentLabel;
        oppClient.DMT_Industry__c = clientValues.industry;

        for (String fieldName : CLIENT_GROUP_COPY_FIELDS) {
            oppClient.put(fieldName, clientValues.financialFields.get(fieldName));
        }
        for (String cstkField : CSTK_FIELD_TARGET_MAP.keySet()) {
            oppClient.put(CSTK_FIELD_TARGET_MAP.get(cstkField), clientValues.financialFields.get(cstkField));
        }

        if (customerHPG != null) {
            oppClient.DMT_Activity__c = customerHPG.assetAllocationActvyType;
            oppClient.DMT_CAMN__c = customerHPG.activityMinimumLevelCodeId;
            oppClient.DMT_External_Rating_Fitch__c = customerHPG.fitchLtRatingFcType;
            oppClient.DMT_External_Rating_Moodys__c = customerHPG.moodysLtRatingFcType;
            oppClient.DMT_External_Rating_SP__c = customerHPG.spLtRatingLcType;
            oppClient.DMT_Sector__c = customerHPG.assetAllocationSectorType;
            oppClient.DMT_Subsector__c = customerHPG.assetAllocationSubSecType;
            oppClient.External_Rating__c = customerHPG.unifiedExtRatgLtFcType;
            if (customerHPG.totalRatingScoreNumber != null) {
                oppClient.DMT_Scoring__c = Decimal.valueOf(customerHPG.totalRatingScoreNumber).setScale(2, System.RoundingMode.HALF_UP);
            }
            oppClient.g_upd_lmscl_internal_ratg_type__c = resolveRatingValueIfExists(customerHPG.updLmsclInternalRatgType);
        }

        String leveragedLending;
        if (leveragedLendingIndType == 'YES') {
            leveragedLending = 'Yes';
        } else if (leveragedLendingIndType == 'NO') {
            leveragedLending = 'No';
        } else {
            leveragedLending = 'N/A';
        }
        oppClient.DMT_Leveraged_Lending__c = leveragedLending;

        return oppClient;
    }
    
    @TestVisible
    private static String resolveRatingValueIfExists(String ratingValue) {
        if (String.isBlank(ratingValue)) {
            return '';
        }
        List<DMT_Taxonomy_Values__c> matches = [
            SELECT Id
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Active__c = true AND DMT_Catalog__c = :RATING_TAXONOMY_CATALOG AND DMT_Value__c = :ratingValue
            WITH USER_MODE
            LIMIT 1
        ];
        return matches.isEmpty() ? '' : ratingValue;
    }

    @TestVisible
    public class ClientValues {
        public String groupCode;
        public String clientGCustomerId;
        public String industry;
        public String segmentLabel;
        public Boolean isNonDisclosedClient = false;
        public Map<String, Object> financialFields = new Map<String, Object>();
    }

    // Mirrors the legacy DmtDrGetClientFields DataMapper's Segment formula chain
    // (Account.DES_Segment__c code -> friendly label), which fed GetClientValues:Segment ->
    // Counterpart__c in both DmtDpOpportunity_1 and DmtDpOpportunityGroup_1.
    private static String resolveSegmentLabel(String rawSegmentCode) {
        if (rawSegmentCode == '00005') { return 'Corporates'; }
        if (rawSegmentCode == '00006') { return 'Fin Inst-B'; }
        if (rawSegmentCode == '00001') { return 'Sov'; }
        if (rawSegmentCode == '00002') { return 'Pub Inst'; }
        if (rawSegmentCode == '00003') { return 'SME'; }
        if (rawSegmentCode == '00004' || String.isBlank(rawSegmentCode)) { return ' '; }
        return rawSegmentCode;
    }
}