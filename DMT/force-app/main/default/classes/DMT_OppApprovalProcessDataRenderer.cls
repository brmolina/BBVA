/**
 * ADDING OR REMOVING A FIELD? Three different shapes here, matching where the field actually lives:
 *
 *   1. Scalar DMT_Opportunity_Client__c fields (most of this tab) - add the field API name to
 *      TRACKED_OPP_CLIENT_FIELDS below, next to wherever it's rendered from data.oppClient.
 *
 *   2. Business Plan / Basic Financials rows (DMT_Opportunity_Business_Plan__c) - add it to
 *      BASIC_FINANCIALS_FIELDS or BP_ROW_FIELDS, whichever table it belongs to. Both already drive
 *      their own rendered table, so a field added there is automatically displayed too.
 *
 *   3. Global Structure / Banking Pool Structure rows - add it to
 *      GLOBAL_STRUCTURE_FIELDS / BANKING_POOL_FIELDS.
 *
 * See DMT_ApprovalProcessDataRenderer for how this fits the other record types, and
 * DMT_MultiObjectFieldTrackableRenderer for the getChildSections() contract used below.
 *
 * CIBGLOBALD-4117 - removed a private ProfitabilityContext class plus getProfitabilityContext()/
 * formatProfitabilityMetric()/toDecimalOrNull(): they read data.featuresList's 'profitability' key
 * but nothing in renderHtml() consumed the result - dead code. If restored, it must both render in
 * renderHtml() and be tracked via getTrackedFields()/getTrackedFieldsByObject()/getChildSections();
 * featuresList isn't a queryable field, so tracking it needs its own strategy.
 */
public without sharing class DMT_OppApprovalProcessDataRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {
    Decimal debtSum = 0;
    Decimal equitySum = 0;
    Decimal usesSum = 0;
    List<DMT_Global_Structure__c> debtRecords = new List<DMT_Global_Structure__c>();
    List<DMT_Global_Structure__c> equityRecords = new List<DMT_Global_Structure__c>();
    List<DMT_Global_Structure__c> usesRecords = new List<DMT_Global_Structure__c>();

    Boolean globalStructureDataBuilt = false;
    private static Map<String, Map<String, String>> picklistLabelCache = new Map<String, Map<String, String>>();

    // ====================================================================================================
    // STRING CONSTANTS
    // ====================================================================================================
    private static String debtLabel = 'Debt Funds (Mn)';
    private static String equityLabel = 'Equity Funds (Mn)';
    private static String usesLabel = 'Uses (Mn)';
    private static final String TAB_DEAL = 'Deal';
    private static final String TAB_CLIENT_PROFITABILITY = 'Client Profitability';
    private static final String TAB_BUSINESS_PLAN = 'Business Plan Data';
    private static final String TAB_CLIENT_INFO = 'Client Information';
    private static final String SECTION_MAIN_CHARACTERISTICS = 'Main Characteristics';
    private static final String SECTION_RISK = 'Risk';
    private static final String SECTION_CLIENT_TIER = 'Client Tier or Position in the Banking Pool';
    private static final String SECTION_SUSTAINABLE_FINANCE = 'Sustainable Finance';
    private static final String SECTION_OTHER_ASPECTS = 'Other Aspects of the Deal';
    private static final String SECTION_GLOBAL_STRUCTURES = 'Global Structure of the Deal';
    private static final String SECTION_BANKING_POOL = 'Banking Pool Structure';
    private static final String SECTION_BASIC_FINANCIALS = 'Basic Financials';
    private static final String SECTION_CLIENT_INFO_DETAIL = 'Client Info';
    private static final String LABEL_TIERING_ACTION = 'Tiering Action';
    private static final String LABEL_CURRENT_TIER = 'Current Tier';
    private static final String LABEL_TARGET_TIER = 'Target Tier';
    private static final String LABEL_EXCEPTION_POOL = 'Exception Pool';
    private static final String LABEL_COMPETITION = 'Competition for the deal';
    private static final String LABEL_ASSET_ALLOCATION = 'Asset Allocation Limit';
    private static final String LABEL_FINANCIAL_PROGRAM = 'Financial Program Limit';
    private static final String LABEL_EQUATOR_SCOPE = 'Equator Principles Scope';
    private static final String LABEL_EQUATOR_CATEGORY = 'Equator Principles Category';
    private static final String LABEL_INFRASTRUCTURE = 'Infrastructure Supporting Factor';
    private static final String LABEL_KPI_MARGIN = 'KPI Margin Adjustment';
    private static final String LABEL_COMMENTS = 'Comments';
    private static final String LABEL_HISTORY = 'History of the Deal';
    private static final String LABEL_COMMITMENT = 'Commitment Deadline';
    private static final String LABEL_DESCRIPTION = 'Description of the deal';
    private static final String LABEL_PURPOSE = 'Purpose';
    private static final String LABEL_OPP_THREATS = 'Opportunities & Threats Related to the Deal';
    private static final String LABEL_SOURCE_USES = 'Source and Uses';
    private static final String LABEL_SECURITY = 'Security Package';
    private static final String LABEL_RATING = 'Rating Scenarios';
    private static final String LABEL_OTHER_ISSUES = 'Other relevant issues';
    private static final String LABEL_TICKET = 'Ticket (Mn)';
    private static final String LABEL_FEES = 'Fees';
    private static final String LABEL_MARGIN = 'Margin';
    private static final String LABEL_N_BANKS = 'Nº banks';
    private static final String LABEL_QUALITATIVE_ASSESSMENT = 'Qualitative Assessment of the estimated Revenues';
    private static final String LABEL_CURRENCY = 'Currency';
    private static final String LABEL_XSELL_COST = 'Xsell Cost to Income';
    private static final String LABEL_GEO_FOOTPRINT = 'Geographical Footprint';
    private static final String LABEL_RELATIONSHIP = 'Relationship Status';
    private static final String LABEL_INDUSTRY = 'Industry Overview';
    private static final String LABEL_APPLICABLE_JURISDICTION = 'Applicable jurisdiction';
    private static final String LABEL_OTHER_RELEVANT_RATIOS = 'Other Relevant Ratios';
    private static final String LABEL_BASIC_FIN_COMMENTS = 'Basic Financials Comments';
    private static final String VALUE_YES = 'Yes';
    private static final String VALUE_NO = 'No';
    private static final String VALUE_TOTAL = 'TOTAL';
    private static final String ERROR_OPP_DATA_NOT_PROVIDED = 'Opportunity data not provided';
    private static final String ERROR_PREFIX = 'Error: ';
    private static final String TIER_1 = 'Tier 1';
    private static final String TIER_2 = 'Tier 2';
    private static final String TIER_3 = 'Tier 3';
    private static final String TIER_4_ABOVE = 'Tier 4 or above';
    private static final String LABEL_CLIENT_RORC_YTD = 'Client RORC NBC YTD (%)';
    private static final String LABEL_ECONOMIC_PROFIT = 'Economic Profit RORC NBC 12m (Non Xsell)';
    private static final String LABEL_RWA_TOTAL = 'RWA Total RORC NBC Last12m*CET1 (Non Xsell)';

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    private String buildHtmlTabHeader(String title) {
        return '<h2 style="font-size: 18px; color: #004481; margin: 24px 0 8px 0; '
             + 'border-bottom: 2px solid #004481; padding-bottom: 4px; font-weight: bold;">'
             + title + '</h2>';
    }

    private String buildHtmlSpacer() {
        return '<div style="margin-top: 16px;"></div>';
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>' + ERROR_OPP_DATA_NOT_PROVIDED + '</div>';
        }
        try {
            Integer CURRENT_YEAR = Date.today().year();
            String comparisonAccountName = data.oppAccountParentName;

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Approval Process Data'
                + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '') + '</h2>';

            // ── Tab: Deal ─────────────────────────────────────────
            html += buildHtmlTabHeader(TAB_DEAL);
            html += buildHtmlMainCharacteristics(data);
            html += buildHtmlSpacer();
            html += buildHtmlTiering(data);
            html += buildHtmlSpacer();
            html += buildHtmlOtherAspects(data);
            html += buildHtmlSpacer();
            html += buildHtmlGlobalStructures(data);
            html += buildHtmlSpacer();
            html += buildHtmlBankingPoolStructure(data);
            html += buildHtmlSpacer();
            html += '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
                  + DMT_FormattingUtils.tableRow1column(LABEL_COMPETITION,
                        DMT_FormattingUtils.checkNull(data.oppClient.DMT_Competition_Deal__c))
                  + '</table>';
            html += buildHtmlSpacer();
            html += buildgetHtmlSustainableFinance(data);
            html += buildHtmlSpacer();
            html += buildHtmlRisksInfo(data);
            html += buildHtmlSpacer();
            html += buildHtmlSppiAndApprovers(data);
            html += buildHtmlSpacer();

            // ── Tab: Client Profitability ──────────────────────────
            html += buildHtmlTabHeader(TAB_CLIENT_PROFITABILITY);
            html += buildHtmlClientProfitability(data);
            html += buildHtmlSpacer();

            // ── Tab: Business Plan Data ────────────────────────────
            html += buildHtmlTabHeader(TAB_BUSINESS_PLAN);
            html += buildHtmlBusinessPlan(data, CURRENT_YEAR);
            html += buildHtmlSpacer();

            // ── Tab: Client Information ────────────────────────────
            html += buildHtmlTabHeader(TAB_CLIENT_INFO);
            html += buildHtmlBasicFinancials(data);
            html += buildHtmlSpacer();
            html += buildHtmlClientInfo(data);
            html += buildHtmlSpacer();

            html += '</div>';
            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_OppApprovalProcessDataRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>' + ERROR_PREFIX + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String buildHtmlRisksInfo(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">' + SECTION_RISK + '</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New(
                LABEL_ASSET_ALLOCATION,
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Asset_Allocation_limit__c),
                LABEL_FINANCIAL_PROGRAM,
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Financial_Program_limit__c)
            )
            // CIBGLOBALD-4117 - editable on the Deal Risk tab (dmt_approval_deal_risk_fields.js) but
            // never displayed here - found via a field-drift audit.
            + DMT_FormattingUtils.tableRow1column(
                'Top 3 Active Facilities (included in PF limits)',
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Top_3_Active_Facilities__c)
            )
            + '</table></div></div>';
    }

    // CIBGLOBALD-4117 - the SPPI TEST section (dmt_approval_deal_sppi_fields.js) and
    // DMT_Financial_Sponsors__c (dmt_OppApproversInfoForm, embedded in this same Deal tab) are both
    // editable directly on Opportunity but were never displayed by this renderer - found via a
    // field-drift audit. Everything else this class renders comes from data.oppClient/child objects.
    private String buildHtmlSppiAndApprovers(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">SPPI Test</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New(
                'SPPI Test Status',
                DMT_FormattingUtils.checkNull(data.opportunity.DMT_SPPI_Status__c),
                'User',
                DMT_FormattingUtils.checkNull(data.opportunity.DMT_SPPI_User__c)
            )
            + DMT_FormattingUtils.tableRow1column_checkbox('File Uploaded', data.opportunity.DMT_SPPI_File_Uploaded__c)
            // DMT_Financial_Sponsors__c is a Checkbox (Boolean), not free text - confirmed via its own
            // field-meta.xml help text ('Where a Financial Sponsor holds direct ownership, control or
            // significant influence'), corrected after an earlier wrong assumption.
            + DMT_FormattingUtils.tableRow1column_checkbox('Financial Sponsors', data.opportunity.DMT_Financial_Sponsors__c)
            + '</table></div></div>';
    }

    private String buildHtmlClientProfitability(DMT_ViewController.LineDataWrapper data) {
        List<DMT_FormattingUtils.DisplayField> fields = new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField(
                System.Label.dmt_cl_ClientsGlobalRORCCIBPastFY_Title,
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Clients_Global_RORC_CIB_Past_FY__c)),
            new DMT_FormattingUtils.DisplayField(
                System.Label.dmt_cl_ClientsGlobalRorcLastFY_Title,
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_CDD_Clients_Global_Rorc_Last_FY__c)),
            new DMT_FormattingUtils.DisplayField(
                LABEL_CLIENT_RORC_YTD,
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_RORC_YTD__c)),
            new DMT_FormattingUtils.DisplayField(
                LABEL_ECONOMIC_PROFIT,
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_Net_Incomes__c)),
            new DMT_FormattingUtils.DisplayField(
                LABEL_RWA_TOTAL,
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_RWA__c)),
            // CIBGLOBALD-4117 - editable on the Client Profitability tab
            // (dmt_approval_client_profitability_fields.js) but never displayed here - found via a
            // field-drift audit.
            new DMT_FormattingUtils.DisplayField(
                'Xsell Cost to Income (%)',
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Xsell_Cost_to_Income__c))
        };
        return '<div><div class="slds-scope">'
            + DMT_FormattingUtils.generateHtmlTable(fields)
            + '</div></div>';
    }

    private String buildHtmlBasicFinancials(DMT_ViewController.LineDataWrapper data) {
        Integer quarter = (Date.today().month() - 1) / 3 + 1;
        Integer yearOffset = (quarter == 4) ? 1 : 0;
        Integer CURRENT_YEAR = Date.today().year() + yearOffset;
        Map<String, List<DMT_Opportunity_Business_Plan__c>> bfRecordsByGeo = groupByGeography(data.businessPlanRecords);
        Map<Integer, DMT_Opportunity_Business_Plan__c> globalBpByYear = mapByYear(bfRecordsByGeo.get('GLOBAL'));

        String html = '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">' + SECTION_BASIC_FINANCIALS + '</h3>'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr style="page-break-inside: avoid;">'
                    + '<td colspan="6" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Basic Financials</strong></td>'
                    + '</tr>'
                    + '<tr style="page-break-inside: avoid;">'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+' '+ '</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 1)+'</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 0)+' (optional)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 1)+' (optional)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 2)+' (optional)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 3)+' (optional)</strong></td>'
                    + '</tr>';

        List<String> label = new List<String>{'Revenues','EBITDA','EBIT', 'Net Income','Free Cash Flow', 'Debt / EBITDA', 'Net Debt / EBITDA'};
        for(Integer i = 0; i < label.size(); i++){
            html += '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+label[i]+'</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(getBpValueByYear(globalBpByYear, CURRENT_YEAR - 1, BASIC_FINANCIALS_FIELDS[i]))+'</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(getBpValueByYear(globalBpByYear, CURRENT_YEAR, BASIC_FINANCIALS_FIELDS[i]))+'</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(getBpValueByYear(globalBpByYear, CURRENT_YEAR + 1, BASIC_FINANCIALS_FIELDS[i]))+'</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(getBpValueByYear(globalBpByYear, CURRENT_YEAR + 2, BASIC_FINANCIALS_FIELDS[i]))+'</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(getBpValueByYear(globalBpByYear, CURRENT_YEAR + 3, BASIC_FINANCIALS_FIELDS[i]))+'</td>'
                + '</tr>';
        }
        html += '</table>'
            + '<div>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + DMT_FormattingUtils.tableRow1column(LABEL_OTHER_RELEVANT_RATIOS, DMT_FormattingUtils.checkNull(data.oppClient.Other_Relevant_Ratios_desc__c))
            + DMT_FormattingUtils.tableRow1column(LABEL_BASIC_FIN_COMMENTS, DMT_FormattingUtils.checkNull(data.oppClient.cstk_sust_indicators_comments__c))
            // CIBGLOBALD-4117 - editable on the Client Info tab (dmt_approval_client_info_fields.js's
            // basicFinancialsFieldsExtra, DMT_Opportunity_Client__c) but never displayed here -
            // distinct from the DMT_Opportunity_Business_Plan__c Currency field rendered elsewhere
            // in this class (buildHtmlBusinessPlan) - found via a field-drift audit.
            + DMT_FormattingUtils.tableRow1column('Currency', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Currency__c))
            + '</table></div></div>';
        return html;
    }

    private String buildHtmlClientInfo(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">' + SECTION_CLIENT_INFO_DETAIL + '</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New(
                LABEL_GEO_FOOTPRINT,
                DMT_FormattingUtils.checkNull(data.oppClient.Geographical_Footprint_desc__c),
                LABEL_RELATIONSHIP,
                DMT_FormattingUtils.checkNull(data.oppClient.Relationship_Status_desc__c)
            )
            + DMT_FormattingUtils.tableRow2columns_New(
                LABEL_INDUSTRY,
                DMT_FormattingUtils.checkNull(data.oppClient.Industry_Overview_desc__c),
                '', ''
            )
            + '</table></div></div>';
    }

    // Row labels and their corresponding API field on DMT_Opportunity_Business_Plan__c
    private static final List<String> BP_ROW_LABELS = new List<String>{
        'Corp. Synd. Lending', 'Structured Finance', 'Structured Trade Finance',
        'Rates', 'GTF', 'Working Capital', 'Total Non X-Sell',
        'ECM', 'M&A', 'DCM', 'Credit/Equity', 'FX/CCS',
        'Cash Management', 'Client Resources', 'Securities Services', 'Total X-Sell',
        'Total Revenues', '% Cross Border Revenues', 'Transactional KPI'
    };

    private static final List<String> BP_ROW_FIELDS = new List<String>{
        'Current_FY_Corp_Synd_Lending_amount__c', 'Current_FY_Structured_Finance_amount__c', 'Current_FY_Str_Trade_Finance_amount__c',
        'Current_FY_Rates_amount__c', 'Current_FY_GTF_amount__c', 'Current_FY_Working_Capital_amount__c', 'Current_FY_Total_Non_X_Sell_amount__c',
        'Current_FY_ECM_M_A_Amount__c', 'Current_FY_M_A_amount__c', 'Current_FY_DCM_amount__c', 'Current_FY_Credit_Equity_amount__c',
        'Current_FY_FX_CCS_amount__c', 'Current_FY_Cash_Management_amount__c', 'Current_FY_Client_Resources_amount__c',
        'Current_FY_Securities_Services_amount__c', 'Current_FY_Total_X_Sell_amount__c',
        'Current_FY_Total_Revenues_amount__c', 'gf_xb_cust_ope_revenue_cyr_per__c', 'gf_kpi_trans_fees_cyr_amount__c'
    };

    private static final Set<String> BP_TOTAL_ROWS = new Set<String>{'Total Non X-Sell', 'Total X-Sell', 'Total Revenues'};

    private static final List<String> BP_X_SELL_FIELDS = new List<String>{
        'Current_FY_ECM_M_A_Amount__c', 'Current_FY_M_A_amount__c', 'Current_FY_DCM_amount__c', 'Current_FY_Credit_Equity_amount__c',
        'Current_FY_FX_CCS_amount__c', 'Current_FY_Cash_Management_amount__c', 'Current_FY_Client_Resources_amount__c', 'Current_FY_Securities_Services_amount__c'
    };

    // Basic Financials table (buildHtmlBasicFinancials) - one row per label, read off the GLOBAL
    // DMT_Opportunity_Business_Plan__c record only. Order matches the 'label' list there.
    private static final List<String> BASIC_FINANCIALS_FIELDS = new List<String>{
        'DMT_Revenues_number__c', 'DMT_EBITDA_number__c', 'DMT_EBIT_number__c', 'DMT_Net_Income_number__c',
        'DMT_Free_Cash_Flow_number__c', 'DMT_Debt_EBITDA_number__c', 'DMT_Net_Debt_EBITDA_number__c'
    };

    // The qualitative fields buildHtmlBusinessPlan reads off the GLOBAL DMT_Opportunity_Business_Plan__c
    // record specifically, alongside the per-geography BP_ROW_FIELDS table.
    private static final List<String> BUSINESS_PLAN_GLOBAL_FIELDS = new List<String>{
        'DMT_QAOTER__c', 'DMT_Currency__c', 'DMT_Xsell_Cost_to_Income__c'
    };

    // buildHtmlGlobalStructures groups DMT_Global_Structure__c rows by DMT_Type__c (Funding Debt /
    // Funding Equity / Uses) and sums DMT_Funds__c per group; Name is shown per row.
    private static final List<String> GLOBAL_STRUCTURE_FIELDS = new List<String>{ 'Name', 'DMT_Type__c', 'DMT_Funds__c' };

    // buildHtmlBankingPoolStructure shows one DMT_Banking_Pool_Structure__c row per tier (Name).
    private static final List<String> BANKING_POOL_FIELDS = new List<String>{ 'Name', 'DMT_Ticket__c', 'DMT_Fees__c', 'DMT_Margin__c', 'DMT_N_Banks__c' };

    // Every scalar field this tab reads off data.oppClient (DMT_Opportunity_Client__c), across every
    // section - Main Characteristics, Risk, Client Tier, Sustainable Finance, Other Aspects,
    // Client Profitability, Basic Financials comments, and Client Info.
    private static final List<String> TRACKED_OPP_CLIENT_FIELDS = new List<String>{
        'DMT_History_Deal__c', 'DMT_Commitment_Deadline__c', 'DMT_Description_Issues__c', 'DMT_Purpose__c', 'DMT_Opp_Threats_Related_Deal__c',
        'DMT_Competition_Deal__c',
        'DMT_Sustainable_Deal__c', 'DMT_equator_Principles__c', 'DMT_Equator_Principles_Category__c', 'DMT_Infrastructure_Supporting_Factor__c', 'DMT_KPI_Margin_Adjustment__c', 'DMT_comments__c',
        'DMT_Asset_Allocation_limit__c', 'DMT_Financial_Program_limit__c',
        'DMT_Clients_Global_RORC_CIB_Past_FY__c', 'DMT_CDD_Clients_Global_Rorc_Last_FY__c', 'DMT_Client_RORC_YTD__c', 'DMT_Client_Net_Incomes__c', 'DMT_Client_RWA__c',
        'DMT_Tiering_Action__c', 'DMT_Current__c', 'DMT_Target__c', 'DMT_Exception_Pool__c',
        'DMT_SourceAndUses__c', 'DMT_Applicable_Jurisdiction__c', 'DMT_Security_Package__c', 'DMT_Rating_Scenarios__c', 'DMT_Other_Relevant_Issues__c',
        'Other_Relevant_Ratios_desc__c', 'cstk_sust_indicators_comments__c',
        'Geographical_Footprint_desc__c', 'Relationship_Status_desc__c', 'Industry_Overview_desc__c',
        // CIBGLOBALD-4117 - found untracked via a field-drift audit against the live edit-side LWCs:
        // DMT_Currency__c (Client Info tab), DMT_Xsell_Cost_to_Income__c (Client Profitability tab),
        // DMT_Top_3_Active_Facilities__c (Deal Risk tab) - all editable, none previously tracked.
        'DMT_Currency__c', 'DMT_Xsell_Cost_to_Income__c', 'DMT_Top_3_Active_Facilities__c'
    };

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    // These four are editable directly on Opportunity and were missed by the original migration,
    // which only checked this class's own renderHtml() output (a different, read-only surface)
    // rather than the live editing LWCs - found via a field-drift audit. The SPPI TEST section
    // lives in this component's own Deal tab (dmt_approval_deal_sppi_fields.js);
    // DMT_Financial_Sponsors__c is editable via dmt_OppApproversInfoForm, embedded in the same
    // Approval Process Data tab. Everything else on this tab lives on DMT_Opportunity_Client__c or
    // on one of the three child objects below.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{
            'DMT_SPPI_Status__c', 'DMT_SPPI_User__c', 'DMT_SPPI_File_Uploaded__c', 'DMT_Financial_Sponsors__c'
        };
    }

    // Fields for the three child objects live here too, keyed by object - DMT_SnapshotChildComparator
    // reads them from this map, not from getChildSections() (which only describes the structural
    // parent/child relationship). opportunityBusinessPlan's fields union the Basic Financials and
    // Business Plan tables plus the GLOBAL-only qualitative fields, since one section covers both
    // tables - they read the same object.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        Set<String> businessPlanFields = new Set<String>();
        businessPlanFields.addAll(BASIC_FINANCIALS_FIELDS);
        businessPlanFields.addAll(BP_ROW_FIELDS);
        businessPlanFields.addAll(BUSINESS_PLAN_GLOBAL_FIELDS);
        businessPlanFields.add('DMT_Year__c');
        businessPlanFields.add('DMT_Booking_Geography__c');

        return new Map<String, List<String>>{
            'DMT_Opportunity_Client__c' => TRACKED_OPP_CLIENT_FIELDS,
            'DMT_Opportunity_Business_Plan__c' => new List<String>(businessPlanFields),
            'DMT_Global_Structure__c' => GLOBAL_STRUCTURE_FIELDS,
            'DMT_Banking_Pool_Structure__c' => BANKING_POOL_FIELDS
        };
    }

    // Four child sections, each a direct child of the Opportunity (parentValueField 'Id').
    // opportunityClient is the SAME section DMT_OpportunityClientRenderer declares for the "Client"
    // component - both read DMT_Opportunity_Client__c, so this declares the identical structural
    // parameters (object, lookup, parent value) and only contributes its own field list on top.
    // DMT_SnapshotChildComparator unions the two components' fields rather than one overwriting
    // the other - see the note there.
    // CIBGLOBALD-4117 - ChildSection(componentName, snapshotSectionKey, childObjectApiName,
    // childLookupField, parentValueField[, orderBy]):
    //   componentName       - this component's display name, matching its DMT_Items__c row;
    //                         shows up in logs/labels, not used for lookups.
    //   snapshotSectionKey  - the key this section's rows are stored under in the frozen JSON
    //                         snapshot. Shared across every component that reads the same child
    //                         object under the same key - fields from all of them get queried and
    //                         compared together, so add/remove fields on the OBJECT's
    //                         getTrackedFieldsByObject() map, never invent a new key for one field.
    //   childObjectApiName  - the SObject to query for this section's rows. Must match a key in
    //                         this renderer's own getTrackedFieldsByObject() map, or nothing gets
    //                         queried/compared for it.
    //   childLookupField    - the field ON childObjectApiName that points back to the parent record.
    //   parentValueField    - the field ON THE PARENT (Opportunity/Line) whose value is matched
    //                         against childLookupField - almost always 'Id'; a different value here
    //                         means an extra hop (see Custom_Association_Client__c's hand-written
    //                         special case in DMT_ApprovalChangeStep_Handler for why that one isn't
    //                         generic).
    //   orderBy (optional)  - ORDER BY clause for the child query, when row order matters for the
    //                         comparison.
    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>{
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Approval Process Data', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Approval Process Data', 'opportunityBusinessPlan', 'DMT_Opportunity_Business_Plan__c',
                'DMT_Opportunity__c', 'Id'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Approval Process Data', 'opportunityGlobalStructure', 'DMT_Global_Structure__c',
                'DMT_Opportunity__c', 'Id'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Approval Process Data', 'opportunityBankingPoolStructure', 'DMT_Banking_Pool_Structure__c',
                'DMT_Opportunity__c', 'Id'
            )
        };
    }

    private String buildHtmlBusinessPlan(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        String html = '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">' + TAB_BUSINESS_PLAN + '</h3>';

        // Group BP records by geography
        Map<String, List<DMT_Opportunity_Business_Plan__c>> recordsByGeo = groupByGeography(data.businessPlanRecords);

        if (recordsByGeo.isEmpty()) {
            html += '<p style="color: #666;">No Business Plan records found.</p>';
        } else {
            // GLOBAL is always computed live as the sum of all non-GLOBAL geography records,
            // mirroring dmt_business_plan_table_geography.js's _buildGlobalAggregatedRows().
            // The persisted GLOBAL record is never read here: it's only kept in sync when a user
            // saves through that LWC, so trusting it directly can show stale totals.
            List<DMT_Opportunity_Business_Plan__c> aggregatedGlobal = DMT_BusinessPlanGlobalAggregator.buildAggregatedGlobalRecords(data.businessPlanRecords, BP_ROW_FIELDS);
            if (!aggregatedGlobal.isEmpty()) {
                html += renderBPHtmlGeographyTable('GLOBAL', aggregatedGlobal, CURRENT_YEAR, data.taxonomyH007BPMap);
            }
            for (String geo : recordsByGeo.keySet()) {
                if (geo != 'GLOBAL') {
                    html += renderBPHtmlGeographyTable(geo, recordsByGeo.get(geo), CURRENT_YEAR, data.taxonomyH007BPMap);
                }
            }
        }

        // Extract Qualitative Assessment and Currency from the GLOBAL BP record
        DMT_Opportunity_Business_Plan__c globalBpRecord = findGlobalBPRecord(data.businessPlanRecords);
        String qualitativeAssessment = (globalBpRecord != null) ? DMT_FormattingUtils.checkNull(globalBpRecord.DMT_QAOTER__c) : '';
        String currency_val = (globalBpRecord != null) ? DMT_FormattingUtils.checkNull(globalBpRecord.DMT_Currency__c) : '';
        String DMT_Xsell_Cost_to_Income_val = (globalBpRecord != null) ? DMT_FormattingUtils.checkNull(globalBpRecord.DMT_Xsell_Cost_to_Income__c) : '';

        html += '</div>'
            + '<div style="margin-top: 20px;"></div>'
            + '<table class="style-table style-border" style="width:100%; border-collapse: separate; border-spacing: 10px 0; table-layout: fixed; margin-left: -10px; margin-right: -10px;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New(LABEL_QUALITATIVE_ASSESSMENT, qualitativeAssessment, LABEL_CURRENCY, currency_val)
            + DMT_FormattingUtils.tableRow2columns_New(LABEL_XSELL_COST, DMT_Xsell_Cost_to_Income_val, '', '')
            + '</table>'
            + '<div style="margin-top: 20px;"></div>';

        return html;
    }

    private String renderBPHtmlGeographyTable(String geoCode, List<DMT_Opportunity_Business_Plan__c> records, Integer CURRENT_YEAR, Map<String, String> taxonomyH007Map) {
        String geoLabel = (taxonomyH007Map != null && taxonomyH007Map.containsKey(geoCode))
            ? taxonomyH007Map.get(geoCode)
            : geoCode;

        Map<Integer, DMT_Opportunity_Business_Plan__c> recordByYear = new Map<Integer, DMT_Opportunity_Business_Plan__c>();
        for (DMT_Opportunity_Business_Plan__c rec : records) {
            if (rec.DMT_Year__c != null) {
                recordByYear.put(Integer.valueOf(rec.DMT_Year__c), rec);
            }
        }

        List<Integer> years = new List<Integer>{CURRENT_YEAR - 2, CURRENT_YEAR - 1, CURRENT_YEAR, CURRENT_YEAR + 1, CURRENT_YEAR + 2};

        String html = '<table class="style-table" style="width:100%; border-collapse: collapse; margin-bottom: 15px;">'
            + '<tr>'
            + '<td colspan="6" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + TAB_BUSINESS_PLAN + ' - ' + geoLabel + '</strong></td>'
            + '</tr>'
            + '<tr>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong></strong></td>';

        for (Integer yr : years) {
            html += '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + yr + '</strong></td>';
        }
        html += '</tr>';

        for (Integer i = 0; i < BP_ROW_LABELS.size(); i++) {
            String label = BP_ROW_LABELS[i];
            String apiField = BP_ROW_FIELDS[i];
            Boolean isTotalRow = BP_TOTAL_ROWS.contains(label);

            String labelStyle = isTotalRow ? 'background-color: #F3F3F3; font-weight:bold;' : '';
            String cellStart = '<td style="padding: 8px; border-bottom: 1px solid #ccc; ' + labelStyle + '">';
            String cellEnd = '</td>';
            String boldOpen = isTotalRow ? '<strong>' : '';
            String boldClose = isTotalRow ? '</strong>' : '';

            html += '<tr>' + cellStart + boldOpen + label + boldClose + cellEnd;

            for (Integer yr : years) {
                DMT_Opportunity_Business_Plan__c rec = recordByYear.get(yr);
                // "Total X-Sell" is always recomputed live from its component rows, never read
                // from the stored field, matching transformApexData() in the LWC.
                Object val = (rec == null) ? null
                    : (label == 'Total X-Sell') ? DMT_BusinessPlanGlobalAggregator.computeXSellTotal(rec, BP_X_SELL_FIELDS)
                    : rec.get(apiField);
                html += cellStart + boldOpen + DMT_FormattingUtils.checkNull(val) + boldClose + cellEnd;
            }
            html += '</tr>';
        }

        html += '</table>';
        return html;
    }


    private String buildHtmlTiering(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">' + SECTION_CLIENT_TIER + '</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New(LABEL_TIERING_ACTION, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Tiering_Action__c), LABEL_CURRENT_TIER, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Current__c))
            + DMT_FormattingUtils.tableRow2columns_New(LABEL_TARGET_TIER, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Target__c), LABEL_EXCEPTION_POOL, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c))
            + '</table></div></div>';
    }

    private String buildgetHtmlSustainableFinance(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">' + SECTION_SUSTAINABLE_FINANCE + '</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New(
                'Sustainable Deal',
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Sustainable_Deal__c),
                'Equator Principles Scope',
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_equator_Principles__c))
            + DMT_FormattingUtils.tableRow2columns_New(
                'Equator Principles Category',
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Equator_Principles_Category__c),
                'Infrastructure Supporting Factor',
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Infrastructure_Supporting_Factor__c))
            + DMT_FormattingUtils.tableRow2columns_New(
                'KPI Margin Adjustment',
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_KPI_Margin_Adjustment__c),
                'Comments',
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_comments__c))
            + '</table></div></div>';
    }

    private String buildHtmlMainCharacteristics(DMT_ViewController.LineDataWrapper data) {
        return '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">' + SECTION_MAIN_CHARACTERISTICS + '</h3>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + '<tr><td colspan="2" style="padding-bottom: 8px; padding-top: 8px; padding-right: 16px; vertical-align: top;">'
            + '<div><strong>' + LABEL_HISTORY + '</strong></div>'
            + '<div style="min-height: 25px; border-bottom: 1px solid #ccc; padding-bottom: 4px;">' + DMT_FormattingUtils.checkNull(data.oppClient.DMT_History_Deal__c) + '</div>'
            + '</td></tr>'
            + DMT_FormattingUtils.tableRow2columns_New(LABEL_COMMITMENT, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Commitment_Deadline__c), LABEL_DESCRIPTION, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Description_Issues__c))
            + DMT_FormattingUtils.tableRow2columns_New(LABEL_PURPOSE, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Purpose__c), LABEL_OPP_THREATS, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Opp_Threats_Related_Deal__c))
            + '</table>';
    }

    private String buildHtmlOtherAspects(DMT_ViewController.LineDataWrapper data) {
        return '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">' + SECTION_OTHER_ASPECTS + '</h3>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New(LABEL_SOURCE_USES, data.oppClient.DMT_SourceAndUses__c == true ? VALUE_YES : VALUE_NO, LABEL_APPLICABLE_JURISDICTION, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Applicable_Jurisdiction__c))
            + DMT_FormattingUtils.tableRow2columns_New(LABEL_SECURITY, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Security_Package__c), LABEL_RATING, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Rating_Scenarios__c))
            + DMT_FormattingUtils.tableRow2columns_New(LABEL_OTHER_ISSUES, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Other_Relevant_Issues__c), '', '')
            + '</table>';
    }

    private String buildHtmlGlobalStructures(DMT_ViewController.LineDataWrapper data) {
        buildGlobalStructuresData(data);

        String html = '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">' + SECTION_GLOBAL_STRUCTURES + '</h3>'
            + '<table style="width:100%; border-collapse: collapse;">'
            + '<tr><td style="width:50%; vertical-align: top; padding-right: 10px;">';

        // Debt
        html += '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr><th colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + debtLabel + '</strong></th></tr>';
        for (DMT_Global_Structure__c gs : debtRecords) {
            html += + '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc;">' + getDisplayName(gs.Name, gs.Id) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.DMT_Funds__c) + '</td></tr>';
        }
        html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + VALUE_TOTAL + '</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + debtSum + '</strong></td></tr></table>';

        // Spacer + Equity
        html += '&nbsp;<br/>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr><th colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + equityLabel + '</strong></th></tr>';
        for (DMT_Global_Structure__c gs : equityRecords) {
            html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc;">' + getDisplayName(gs.Name, gs.Id) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.DMT_Funds__c) + '</td></tr>';
        }
        html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + VALUE_TOTAL + '</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + equitySum + '</strong></td></tr></table>';

        html += '</td><td style="width:50%; vertical-align: top; padding-left: 10px;">';

        // Uses
        html += '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr><th colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + usesLabel + '</strong></th></tr>';
        for (DMT_Global_Structure__c gs : usesRecords) {
            html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc;">' + getDisplayName(gs.Name, gs.Id) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.DMT_Funds__c) + '</td></tr>';
        }
        html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + VALUE_TOTAL + '</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + usesSum + '</strong></td></tr></table>';

        html += '</td></tr></table></div>&nbsp;</br>';
        return html;
    }

        private String buildHtmlBankingPoolStructure(DMT_ViewController.LineDataWrapper data) {
        Map<String, DMT_Banking_Pool_Structure__c> tierMap = new Map<String, DMT_Banking_Pool_Structure__c>();

        for (DMT_Banking_Pool_Structure__c row : data.bankingPoolStructures) {
            tierMap.put(row.Name, row);
        }

        List<String> tiers = new List<String>{ TIER_1, TIER_2, TIER_3, TIER_4_ABOVE };

        String html = '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">' + SECTION_BANKING_POOL + '</h3>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr>'
            + '<td colspan="5" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + SECTION_BANKING_POOL + '</strong></td>'
            + '</tr>'
            + '<tr>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong></strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + LABEL_TICKET + '</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + LABEL_FEES + '</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + LABEL_MARGIN + '</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + LABEL_N_BANKS + '</strong></td>'
            + '</tr>';

        for (String tier : tiers) {
            DMT_Banking_Pool_Structure__c row = tierMap.get(tier);

            html += '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-style: italic;">' + tier + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(row != null ? row.DMT_Ticket__c : null) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(row != null ? row.DMT_Fees__c : null) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(row != null ? row.DMT_Margin__c : null) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(row != null ? row.DMT_N_Banks__c : null) + '</td>'
                + '</tr>';
        }

        html += '</table></div>&nbsp;</br>';
        return html;
    }

    private void buildGlobalStructuresData(DMT_ViewController.LineDataWrapper data) {
        if (globalStructureDataBuilt) return;

        if (!data.opportunity.Global_Structures__r.isEmpty()) {
            Schema.DescribeFieldResult fieldResult = DMT_Global_Structure__c.DMT_Type__c.getDescribe();
            Map<String, String> apiToLabel = new Map<String, String>();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                apiToLabel.put(entry.getValue(), entry.getLabel());
            }
            debtLabel = apiToLabel.get('Funding Debt') != null ? apiToLabel.get('Funding Debt') : 'Debt Funds (Mn)';
            equityLabel = apiToLabel.get('Funding Equity') != null ? apiToLabel.get('Funding Equity') : 'Equity Funds (Mn)';
            usesLabel = apiToLabel.get('Uses') != null ? apiToLabel.get('Uses') : 'Uses (Mn)';

            debtSum = 0; equitySum = 0; usesSum = 0;
            debtRecords.clear(); equityRecords.clear(); usesRecords.clear();

            for (DMT_Global_Structure__c gs : data.opportunity.Global_Structures__r) {
                Decimal funds = gs.DMT_Funds__c != null ? gs.DMT_Funds__c : 0;
                if (gs.DMT_Type__c == 'Funding Debt') { debtRecords.add(gs); debtSum += funds; }
                else if (gs.DMT_Type__c == 'Funding Equity') { equityRecords.add(gs); equitySum += funds; }
                else if (gs.DMT_Type__c == 'Uses') { usesRecords.add(gs); usesSum += funds; }
            }
        }
        globalStructureDataBuilt = true;
    }

    private Boolean isTechnicalName(String value, Id recordId) {
        if (String.isBlank(value)) {
            return false;
        }

        String trimmedValue = value.trim();

        if (recordId != null && trimmedValue == String.valueOf(recordId)) {
            return true;
        }

        return Pattern.matches('^[a-zA-Z0-9]{15,18}$', trimmedValue);
    }

    private String getDisplayName(String value, Id recordId) {
        return isTechnicalName(value, recordId) ? '' : DMT_FormattingUtils.checkNull(value);
    }

    // ====================================================================================================
    // BUSINESS PLAN HELPERS
    // ====================================================================================================

    private Map<String, List<DMT_Opportunity_Business_Plan__c>> groupByGeography(List<DMT_Opportunity_Business_Plan__c> records) {
        Map<String, List<DMT_Opportunity_Business_Plan__c>> result = new Map<String, List<DMT_Opportunity_Business_Plan__c>>();
        if (records == null || records.isEmpty()) return result;

        for (DMT_Opportunity_Business_Plan__c rec : records) {
            String geo = rec.DMT_Booking_Geography__c;
            if (String.isBlank(geo)) geo = 'GLOBAL';
            if (!result.containsKey(geo)) {
                result.put(geo, new List<DMT_Opportunity_Business_Plan__c>());
            }
            result.get(geo).add(rec);
        }
        return result;
    }

    private Map<Integer, DMT_Opportunity_Business_Plan__c> mapByYear(List<DMT_Opportunity_Business_Plan__c> records) {
        Map<Integer, DMT_Opportunity_Business_Plan__c> result = new Map<Integer, DMT_Opportunity_Business_Plan__c>();
        if (records == null) {
            return result;
        }
        for (DMT_Opportunity_Business_Plan__c rec : records) {
            if (rec.DMT_Year__c != null) {
                result.put(Integer.valueOf(rec.DMT_Year__c), rec);
            }
        }
        return result;
    }

    private Object getBpValueByYear(Map<Integer, DMT_Opportunity_Business_Plan__c> bpByYear, Integer year, String apiField) {
        DMT_Opportunity_Business_Plan__c bp = bpByYear.get(year);
        return bp != null ? bp.get(apiField) : null;
    }

    private DMT_Opportunity_Business_Plan__c findGlobalBPRecord(List<DMT_Opportunity_Business_Plan__c> records) {
        if (records == null || records.isEmpty()) return null;
        for (DMT_Opportunity_Business_Plan__c rec : records) {
            if (rec.DMT_Booking_Geography__c == 'GLOBAL') return rec;
        }
        return records[0];
    }

}