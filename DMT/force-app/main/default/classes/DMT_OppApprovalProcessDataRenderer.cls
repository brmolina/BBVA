public with sharing class DMT_OppApprovalProcessDataRenderer implements DMT_ViewRenderer {
    String debtLabel = 'Debt Funds (Mn)';
    String equityLabel = 'Equity Funds (Mn)';
    String usesLabel = 'Uses (Mn)';
    Decimal debtSum = 0;
    Decimal equitySum = 0;
    Decimal usesSum = 0;
    List<DMT_Global_Structure__c> debtRecords = new List<DMT_Global_Structure__c>();
    List<DMT_Global_Structure__c> equityRecords = new List<DMT_Global_Structure__c>();
    List<DMT_Global_Structure__c> usesRecords = new List<DMT_Global_Structure__c>();

    Boolean globalStructureDataBuilt = false;
    private static Map<String, Map<String, String>> picklistLabelCache = new Map<String, Map<String, String>>();

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }
        try {
            Integer CURRENT_YEAR = Date.today().year();

            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">APPROVAL PROCESS DATA</h2>';

            html += buildHtmlBasicFinancials(data, CURRENT_YEAR);
            html += buildHtmlClientInfo(data);
            html += buildHtmlBusinessPlan(data, CURRENT_YEAR);
            html += buildHtmlTiering(data);
            html += buildgetHtmlSustainableFinance(data);
            html += buildHtmlMainCharacteristics(data);
            html += buildHtmlOtherAspects(data);
            html += buildHtmlGlobalStructures(data);
            html += DMT_FormattingUtils.tableRow1column('Competition for the deal', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Competition_Deal__c))
            + '</br></br>';
            html += buildHtmlRisksInfo(data)
                 + '</br></br>';

            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_OppApprovalProcessDataRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String buildHtmlRisksInfo(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Risks Info</h3>'
        //    + '</div>&nbsp;</br>';
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New('Asset Allocation Limit', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Asset_Allocation_limit__c), 'Financial Program Limit', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Financial_Program_limit__c))
            + DMT_FormattingUtils.tableRow2columns_New('Country Risk', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Country_Risk__c), 'Economic LGD', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Economic_LGD__c))
            + DMT_FormattingUtils.tableRow2columns_New('Leverage Lending', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Leveraged_Lending__c), '', '')
            + DMT_FormattingUtils.tableRow1column('Credit Risk Opinion Provided by', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Credit_Risk_Opinion_By__c))
            + '</table></div></div>&nbsp;</br>';
    }

    private String buildHtmlBasicFinancials(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        String html = '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Basic Financials</h3>'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                    + '<td colspan="7" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>BASIC FINANCIALS</strong></td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+' '+ '</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 1)+'</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 0)+' (optional)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 1)+' (optional)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 2)+' (optional)</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 3)+' (optional)</strong></td>'
                    + '</tr>';

        List<String> label = new List<String>{'Revenues','EBITDA','EBIT', 'Net Income','Free Cash Flow', 'Debt / EBITDA', 'Net Debt / EBITDA'};
        List<String> values = new List<String>{'Revenues_', 'EBITDA_', 'EBIT_', 'Net_Income_', 'Free_Cash_Flow_', 'Debt_EBITDA_', 'Net_Debt_EBITDA_'};
        for(Integer i = 0; i < label.size(); i++){
            html += '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+label[i]+'</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Last_Year_number__c'))+'</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Current_Year_number__c'))+'</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_number__c'))+'</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_1_number__c'))+'</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'+DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_2_number__c'))+'</td>'
                + '</tr>';
        }
        html += '</table>'
            + '<div>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow1column('Other Relevant Ratios', DMT_FormattingUtils.checkNull(data.oppClient.Other_Relevant_Ratios_desc__c))
            + DMT_FormattingUtils.tableRow1column('Basic Financials Comments', DMT_FormattingUtils.checkNull(data.oppClient.cstk_sust_indicators_comments__c))
            + '</table></div></div>&nbsp;</br>';
        return html;
    }

    private String buildHtmlClientInfo(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Client Information</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New('Geographical Footprint', DMT_FormattingUtils.checkNull(data.oppClient.Geographical_Footprint_desc__c), 'Relationship Status', DMT_FormattingUtils.checkNull(data.oppClient.Relationship_Status_desc__c))
            + DMT_FormattingUtils.tableRow1column('Industry Overview', DMT_FormattingUtils.checkNull(data.oppClient.Industry_Overview_desc__c))
            + '</table></div></div>&nbsp;</br>';
    }

    private String buildHtmlBusinessPlan(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        String html = '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Business Plan Data</h3>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr>'
            + '<td colspan="7" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>BUSINESS PLAN</strong></td>'
            + '</tr>'
            + '<tr>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+''+ '</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 2)+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 1)+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 0)+' E</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 1)+' E</strong></td>'
            + '</tr>';

        List<String> labelBPD = new List<String>{'Corp. Synd. Lending','Structured Finance','Structured Trade Finance', 'Rates','GTF', 'Working Capital', 'Total Non X-Sell',
                                                'ECM/M&A', 'DCM', 'Credit/Equity', 'FX/CCS','Cash Management','Client Resources','Securities Services', 'Total X-Sell',
                                                'Total Revenues','% Cross Border Revenues', 'Transactional KPI'};
        List<String> valueBPD = new List<String>{'FY_Corp_Synd_Lending_amount__c', 'FY_Structured_Finance_amount__c', 'FY_Str_Trade_Finance_amount__c', 'FY_Rates_amount__c', 'FY_GTF_amount__c',
                                                'FY_Working_Capital_amount__c', 'FY_Total_Non_X_Sell_amount__c', 'FY_ECM_M_A_Amount__c', 'FY_DCM_amount__c', 'FY_Credit_Equity_amount__c',
                                                'FY_FX_CCS_amount__c', 'FY_Cash_Management_amount__c', 'FY_Client_Resources_amount__c', 'FY_Securities_Services_amount__c',
                                                'FY_Total_X_Sell_amount__c', 'FY_Total_Revenues_amount__c','gf_xb_cust_ope_revenue_', 'gf_kpi_trans_fees_'};
        for(Integer i = 0; i < labelBPD.size(); i++){
            String apiName1, apiName2, apiName3, apiName4;
            if(valueBPD[i] == 'gf_xb_cust_ope_revenue_'){
                apiName1 = valueBPD[i]+'2ya_per__c'; apiName2 = valueBPD[i]+'ly_per__c'; apiName3 = valueBPD[i]+'cyr_per__c'; apiName4 = valueBPD[i]+'nxy_per__c';
            }else if(valueBPD[i] == 'gf_kpi_trans_fees_'){
                apiName1 = valueBPD[i]+'2ya_amount__c'; apiName2 = valueBPD[i]+'ly_amount__c'; apiName3 = valueBPD[i]+'cyr_amount__c'; apiName4 = valueBPD[i]+'nxy_amount__c';
            }else{
                apiName1 = 'Past2_'+valueBPD[i]; apiName2 = 'Past_'+valueBPD[i]; apiName3 = 'Current_'+valueBPD[i]; apiName4 = 'Next_'+valueBPD[i];
            }

            String labelStyle = (labelBPD[i] == 'Total Non X-Sell' || labelBPD[i] == 'Total X-Sell' || labelBPD[i] == 'Total Revenues') ? 'background-color: #F3F3F3; font-weight:bold;' : '';
            String cellStart = '<td style="padding: 8px; border-bottom: 1px solid #ccc; ' + labelStyle + '">';
            String cellEnd = '</td>';

            html += '<tr>'
                    + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + labelBPD[i] + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                    + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.opportunity.Account.get(apiName1)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                    + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.opportunity.Account.get(apiName2)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                    + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.opportunity.Account.get(apiName3)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                    + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.opportunity.Account.get(labelBPD[i].contains('Total') ? apiName4 : apiName3)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                    + '</tr>';
        }
        html += '</table></div>&nbsp;</br>'
             + '<table class="style-table style-border" style="width:100%; border-collapse: separate; border-spacing: 10px 0; table-layout: fixed; margin-left: -10px; margin-right: -10px;">'
             + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
             + DMT_FormattingUtils.tableRow1column('History of the deal', DMT_FormattingUtils.checkNull(data.oppClient.DMT_History_Deal__c))
             + DMT_FormattingUtils.tableRow2columns_New('Commitment Deadline:', DMT_FormattingUtils.changeDateFormat(data.oppClient.DMT_Commitment_Deadline__c), 'Exception Pool:', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c))
             + '</table></br>';
        return html;
    }

    private String buildHtmlTiering(DMT_ViewController.LineDataWrapper data) {
        return '<table class="style-table" style="width:100%; border-collapse: collapse;">'
             + '<tr>'
             + '<td style="width: 60%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Tiering Action</strong></td>'
             + '<td style="width: 20%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;">Current</td>'
             + '<td style="width: 20%; padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;">Target</td>'
             + '</tr>'
             + '<tr>'
             + '<td style="padding: 8px; border-bottom: 1px solid #ccc; ">'+DMT_FormattingUtils.checkNull(data.oppClient.DMT_Tiering_Action__c)+'</td>'
             + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: smaller;">'+DMT_FormattingUtils.checkNull(data.oppClient.DMT_Current__c)+'</td>'
             + '<td style="padding: 8px; border-bottom: 1px solid #ccc; font-size: smaller;">'+DMT_FormattingUtils.checkNull(data.oppClient.DMT_Target__c)+'</td>'
             + '</tr>'
             + '</table></br>&nbsp;</br>';
    }

    private String buildgetHtmlSustainableFinance(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Sustainable Finance</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New('ESG Score', DMT_FormattingUtils.checkNull(data.oppClient.gf_esg_score_close_ope_name__c), 'TCFD', DMT_FormattingUtils.checkNull(data.oppClient.gf_co_list_tcfd_ind_type__c))
            + DMT_FormattingUtils.tableRow1column('Paris Aligned', DMT_FormattingUtils.checkNull(data.oppClient.gf_paris_agreement_ind_type__c))
            + DMT_FormattingUtils.tableRow1column('Other', DMT_FormattingUtils.checkNull(data.oppClient.gf_customer_sustnbl_strg_desc__c))
            + DMT_FormattingUtils.tableRow1column('IB&F', DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_ibf_desc__c))
            + DMT_FormattingUtils.tableRow1column('GM', DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_gm_desc__c))
            + DMT_FormattingUtils.tableRow1column('GTB', DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_gtb_desc__c))
            + DMT_FormattingUtils.tableRow2columns_New(System.Label.dmt_cl_TRI_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_tri__c), System.Label.dmt_cl_Positioning_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_positioning__c))
            + DMT_FormattingUtils.tableRow2columns_New(System.Label.dmt_cl_CCA_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_cca__c), System.Label.dmt_cl_CTA_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_cta__c))
            + DMT_FormattingUtils.tableRow2columns_New(System.Label.dmt_cl_TRIEngagementPlan_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_tri_Engagement_Plan__c), System.Label.dmt_cl_Scope_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_scope__c))
            + DMT_FormattingUtils.tableRow1column(System.Label.dmt_cl_Comments_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_comments__c))
            + DMT_FormattingUtils.tableRow1column(System.Label.dmt_cl_ReputationalRisk_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_reputational_risk__c))
            + DMT_FormattingUtils.tableRow1column(System.Label.dmt_cl_EquatorPrinciples_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_equator_Principles__c))
            + DMT_FormattingUtils.tableRow1column(System.Label.dmt_cl_CleanTech_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_cleanTech__c))
            + DMT_FormattingUtils.tableRow1column(System.Label.dmt_cl_PortfolioAlignment_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_portfolio_Alignment__c))
            + DMT_FormattingUtils.tableRow1column(System.Label.dmt_cl_KPILinkMarginAdjustment_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_kpiLink_Margin_Adjustment__c))
            + '</table></div></div>&nbsp;</br>';
    }

    private String buildHtmlMainCharacteristics(DMT_ViewController.LineDataWrapper data) {
        return '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">MAIN CHARACTERISTICS OF THE DEAL</h3>'
            + DMT_FormattingUtils.tableRow1columnWithHelper('1. DESCRIPTION AND ISSUES', 'Brief description of the deal presented, main transactional features and changes vs former facility if any and key issues to be discussed (Max 617 characters)', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Description_Issues__c)) + '</br>'
            + DMT_FormattingUtils.tableRow1columnWithHelper('2. PURPOSE', 'Product/Banker\'s description of the use of funds of the facility/(ies) presented (Max 206 characters)', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Purpose__c)) + '</br>'
            + DMT_FormattingUtils.tableRow1columnWithHelper('3. OPPORTUNITIES & THREATS RELATED TO THE DEAL', 'Banker\'s insight on the impact of this deal: advantages, opportunities and potential issues - external or internal - which may arise. (Max. 103 characters/line)', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Opp_Threats_Related_Deal__c)) + '</br>';
    }

    private String buildHtmlOtherAspects(DMT_ViewController.LineDataWrapper data) {
        return '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">OTHER ASPECTS</h3>'
            + DMT_FormattingUtils.tableRow1column('Applicable jurisdiction',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Applicable_Jurisdiction__c)) + '</br>'
            + DMT_FormattingUtils.tableRow1column('Security Package',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Security_Package__c)) + '</br>'
            + DMT_FormattingUtils.tableRow1column('Rating Scenarios',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Rating_Scenarios__c)) + '</br>'
            + DMT_FormattingUtils.tableRow1column('Other relevant issues',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Other_Relevant_Issues__c)) + '</br>';
    }

    private String buildHtmlGlobalStructures(DMT_ViewController.LineDataWrapper data) {
        buildGlobalStructuresData(data);

        String html = '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Global Structures</h3>'
            + '<table style="width:100%; border-collapse: collapse;">'
            + '<tr><td style="width:50%; vertical-align: top; padding-right: 10px;">';

        // Debt
        html += '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr><th colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + debtLabel + '</strong></th></tr>';
        for (DMT_Global_Structure__c gs : debtRecords) {
            html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.Name) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.DMT_Funds__c) + '</td></tr>';
        }
        html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TOTAL</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + debtSum + '</strong></td></tr></table>';

        // Spacer + Equity
        html += '&nbsp;<br/>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr><th colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + equityLabel + '</strong></th></tr>';
        for (DMT_Global_Structure__c gs : equityRecords) {
            html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.Name) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.DMT_Funds__c) + '</td></tr>';
        }
        html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TOTAL</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + equitySum + '</strong></td></tr></table>';

        html += '</td><td style="width:50%; vertical-align: top; padding-left: 10px;">';

        // Uses
        html += '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr><th colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + usesLabel + '</strong></th></tr>';
        for (DMT_Global_Structure__c gs : usesRecords) {
            html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.Name) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.DMT_Funds__c) + '</td></tr>';
        }
        html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TOTAL</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + usesSum + '</strong></td></tr></table>';

        html += '</td></tr></table></div>&nbsp;</br>';
        return html;
    }

    // ====================================================================================================
    // PDF RENDERING
    // ====================================================================================================

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return new Map<String, Object>();
        }
        try {
            Integer CURRENT_YEAR = Date.today().year();
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 60 });
            contentList.add(DMT_Create_Pdf_Controller.createTitle('APPROVAL PROCESS DATA'));

            contentList.addAll(buildPdfBasicFinancials(data, CURRENT_YEAR));
            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 60 });

            contentList.addAll(buildPdfClientInfo(data));
            contentList.addAll(buildPdfBusinessPlan(data, CURRENT_YEAR));
            contentList.add(getPdfTiering(data));

            contentList.addAll(buildPdfSustainableFinance(data));
            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

            contentList.addAll(buildPdfMainCharacteristics(data));
            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

            contentList.addAll(buildPdfOtherAspects(data));
            contentList.addAll(buildPdfGlobalStructures(data));

            contentList.add(DMT_Create_Pdf_Controller.createListText(new List<String>{'Competition for the deal'}, new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.DMT_Competition_Deal__c)}, 'ONE'));

            contentList.addAll(buildPdfRisksInfo(data));

            component.put('content', contentList);
            component.put('name', 'Approval Process Data');

            System.debug('returning component: ' + JSON.serialize(component));
            return component;

        } catch (Exception e) {
            System.debug('Error in DMT_OppApprovalProcessDataRenderer renderPdfJson, ' + e.getMessage() + ' ' + e.getLineNumber());
            System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_OppApprovalProcessDataRenderer','renderPdfJson','DMT',''));
            return new Map<String, Object>();
        }
    }

    private List<Object> buildPdfRisksInfo(DMT_ViewController.LineDataWrapper data) {
        List<Object> result = new List<Object>();
        result.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 70 });
        Map<String, Object> clientInfoTitle = DMT_Create_Pdf_Controller.createTitle('Risks Info');
        clientInfoTitle.put('type', 'text');
        ((Map<String, Object>) clientInfoTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) clientInfoTitle.get('style')).put('textColor', '#004481');
        result.add(clientInfoTitle);

        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'Asset Allocation Limit','Country Risk', 'Leverage Lending', 'Financial Program Limit', 'Economic LGD'},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.DMT_Asset_Allocation_limit__c),DMT_FormattingUtils.checkNull(data.oppClient.DMT_Country_Risk__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Leveraged_Lending__c), DMT_FormattingUtils.checkNull(data.oppClient.DMT_Financial_Program_limit__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Economic_LGD__c)},
            ''));
        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'Credit Risk Opinion Provided by'},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.DMT_Credit_Risk_Opinion_By__c)},
            'ONE'));
        return result;
    }

    private List<Object> buildPdfBasicFinancials(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        List<Object> result = new List<Object>();
        Map<String, Object> basicTitle = DMT_Create_Pdf_Controller.createTitle('Basic Financials');
        basicTitle.put('type', 'text');
        ((Map<String, Object>) basicTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) basicTitle.get('style')).put('textColor', '#004481');
        result.add(basicTitle);

        List<Object> titleSectionBF = DMT_Create_Pdf_Controller.createTitleSection('BASIC FINANCIALS');
        result.add(titleSectionBF[0]);
        result.add(titleSectionBF[1]);

        List<List<String>> basicHead = new List<List<String>>{new List<String>{'', String.valueOf(CURRENT_YEAR - 1), String.valueOf(CURRENT_YEAR - 0), String.valueOf(CURRENT_YEAR + 1), String.valueOf(CURRENT_YEAR + 2), String.valueOf(CURRENT_YEAR + 3)}};
        List<List<String>> basicRows = new List<List<String>>();
        List<String> labels = new List<String>{'Revenues','EBITDA','EBIT', 'Net Income','Free Cash Flow', 'Debt / EBITDA', 'Net Debt / EBITDA'};
        List<String> values = new List<String>{'Revenues_', 'EBITDA_', 'EBIT_', 'Net_Income_', 'Free_Cash_Flow_', 'Debt_EBITDA_', 'Net_Debt_EBITDA_'};

        for (Integer i = 0; i < labels.size(); i++) {
            basicRows.add(new List<String>{
                labels[i],
                DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Last_Year_number__c')),
                DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Current_Year_number__c')),
                DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_number__c')),
                DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_1_number__c')),
                DMT_FormattingUtils.checkNull(data.oppClient.get(values[i] + 'Next_Year_2_number__c'))
            });
        }
        result.add(DMT_Create_Pdf_Controller.createTable(basicHead, basicRows));
        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'Other Relevant Ratios','Basic Financials Comments'},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.Other_Relevant_Ratios_desc__c), DMT_FormattingUtils.checkNull(data.oppClient.cstk_sust_indicators_comments__c)},
            'ONE'));
        return result;
    }

    private List<Object> buildPdfClientInfo(DMT_ViewController.LineDataWrapper data) {
        List<Object> result = new List<Object>();
        Map<String, Object> clientInfoTitle = DMT_Create_Pdf_Controller.createTitle('Client Information');
        clientInfoTitle.put('type', 'text');
        ((Map<String, Object>) clientInfoTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) clientInfoTitle.get('style')).put('textColor', '#004481');
        result.add(clientInfoTitle);

        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'Geographical Footprint','Relationship Status'},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.Geographical_Footprint_desc__c),DMT_FormattingUtils.checkNull(data.oppClient.Relationship_Status_desc__c)},
            ''));
        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'Industry Overview'},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.Industry_Overview_desc__c)},
            'ONE'));
        return result;
    }

    private List<Object> buildPdfBusinessPlan(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        List<Object> result = new List<Object>();
        result.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 70 });
        Map<String, Object> bpdTitle = DMT_Create_Pdf_Controller.createTitle('Business Plan Data');
        bpdTitle.put('type', 'text');
        ((Map<String, Object>) bpdTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) bpdTitle.get('style')).put('textColor', '#004481');
        result.add(bpdTitle);

        List<Object> titleSectionBPD = DMT_Create_Pdf_Controller.createTitleSection('BUSINESS PLAN');
        result.add(titleSectionBPD[0]);
        result.add(titleSectionBPD[1]);

        List<List<String>> bpdHead = new List<List<String>>{new List<String>{'', String.valueOf(CURRENT_YEAR - 2), String.valueOf(CURRENT_YEAR - 1), String.valueOf(CURRENT_YEAR + 0), String.valueOf(CURRENT_YEAR + 1)}};
        List<List<String>> bpdRows = new List<List<String>>();
        List<String> labelBPD = new List<String>{'Corp. Synd. Lending','Structured Finance','Structured Trade Finance', 'Rates','GTF', 'Working Capital', 'Total Non X-Sell',
                                                'ECM/M&A', 'DCM', 'Credit/Equity', 'FX/CCS','Cash Management','Client Resources','Securities Services', 'Total X-Sell',
                                                'Total Revenues','% Cross Border Revenues', 'Transactional KPI'};
        List<String> valueBPD = new List<String>{'FY_Corp_Synd_Lending_amount__c', 'FY_Structured_Finance_amount__c', 'FY_Str_Trade_Finance_amount__c', 'FY_Rates_amount__c', 'FY_GTF_amount__c',
                                                'FY_Working_Capital_amount__c', 'FY_Total_Non_X_Sell_amount__c', 'FY_ECM_M_A_Amount__c', 'FY_DCM_amount__c', 'FY_Credit_Equity_amount__c',
                                                'FY_FX_CCS_amount__c', 'FY_Cash_Management_amount__c', 'FY_Client_Resources_amount__c', 'FY_Securities_Services_amount__c',
                                                'FY_Total_X_Sell_amount__c', 'FY_Total_Revenues_amount__c','gf_xb_cust_ope_revenue_', 'gf_kpi_trans_fees_'};

        for (Integer i = 0; i < labelBPD.size(); i++) {
            String apiName1, apiName2, apiName3, apiName4;
            if(valueBPD[i] == 'gf_xb_cust_ope_revenue_'){
                apiName1 = valueBPD[i]+'2ya_per__c'; apiName2 = valueBPD[i]+'ly_per__c'; apiName3 = valueBPD[i]+'cyr_per__c'; apiName4 = valueBPD[i]+'nxy_per__c';
            } else if(valueBPD[i] == 'gf_kpi_trans_fees_'){
                apiName1 = valueBPD[i]+'2ya_amount__c'; apiName2 = valueBPD[i]+'ly_amount__c'; apiName3 = valueBPD[i]+'cyr_amount__c'; apiName4 = valueBPD[i]+'nxy_amount__c';
            } else {
                apiName1 = 'Past2_'+valueBPD[i]; apiName2 = 'Past_'+valueBPD[i]; apiName3 = 'Current_'+valueBPD[i]; apiName4 = 'Next_'+valueBPD[i];
            }
            bpdRows.add(new List<String>{
                labelBPD[i],
                DMT_FormattingUtils.checkNull(data.opportunity.Account.get(apiName1)),
                DMT_FormattingUtils.checkNull(data.opportunity.Account.get(apiName2)),
                DMT_FormattingUtils.checkNull(data.opportunity.Account.get(apiName3)),
                DMT_FormattingUtils.checkNull(data.opportunity.Account.get(apiName4))
            });
        }
        result.add(DMT_Create_Pdf_Controller.createTable(bpdHead, bpdRows));
        result.add(DMT_Create_Pdf_Controller.createListText(new List<String>{'History of the deal'}, new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.DMT_History_Deal__c)}, 'ONE'));
        result.add(DMT_Create_Pdf_Controller.createListText(new List<String>{'Commitment Deadline', 'Exception Pool'}, new List<String>{DMT_FormattingUtils.changeDateFormat(data.oppClient.DMT_Commitment_Deadline__c), DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c)}, ''));
        return result;
    }

    private Object getPdfTiering(DMT_ViewController.LineDataWrapper data) {
        List<List<String>> tierHead = new List<List<String>>{ new List<String>{'Tiering Action', 'Current', 'Target'} };
        List<List<String>> tierBody = new List<List<String>>{
            new List<String>{
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Tiering_Action__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Current__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Target__c)}
        };
        return DMT_Create_Pdf_Controller.createTable(tierHead, tierBody);
    }

    private List<Object> buildPdfSustainableFinance(DMT_ViewController.LineDataWrapper data) {
        List<Object> result = new List<Object>();
        result.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });
        Map<String, Object> sFTitle = DMT_Create_Pdf_Controller.createTitle('Sustainable Finance');
        sFTitle.put('type', 'text');
        ((Map<String, Object>) sFTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) sFTitle.get('style')).put('textColor', '#004481');
        result.add(sFTitle);

        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'ESG Score', 'TCFD'},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.gf_esg_score_close_ope_name__c),DMT_FormattingUtils.checkNull(data.oppClient.gf_co_list_tcfd_ind_type__c)},
            ''));
        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'Paris Aligned', 'Other', 'IB&F', 'GM', 'GTB'},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.gf_paris_agreement_ind_type__c), DMT_FormattingUtils.checkNull(data.oppClient.gf_customer_sustnbl_strg_desc__c),
                            DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_ibf_desc__c), DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_gm_desc__c),
                            DMT_FormattingUtils.checkNull(data.oppClient.gf_pitch_oppy_l12m_gtb_desc__c)},
            'ONE'));

        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{System.Label.dmt_cl_TRI_Title, System.Label.dmt_cl_CCA_Title, System.Label.dmt_cl_TRIEngagementPlan_Title,
                System.Label.dmt_cl_Positioning_Title, System.Label.dmt_cl_CTA_Title, System.Label.dmt_cl_Scope_Title},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.DMT_tri__c), DMT_FormattingUtils.checkNull(data.oppClient.DMT_cca__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_tri_Engagement_Plan__c), DMT_FormattingUtils.checkNull(data.oppClient.DMT_positioning__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_cta__c), DMT_FormattingUtils.checkNull(data.oppClient.DMT_scope__c)},
            ''));

        result.add(DMT_Create_Pdf_Controller.createListText(new List<String>{System.Label.dmt_cl_Comments_Title, System.Label.dmt_cl_ReputationalRisk_Title, System.Label.dmt_cl_EquatorPrinciples_Title, 
            System.Label.dmt_cl_CleanTech_Title, System.Label.dmt_cl_PortfolioAlignment_Title, System.Label.dmt_cl_KPILinkMarginAdjustment_Title}, 
            new List<String>{ DMT_FormattingUtils.checkNull(data.oppClient.DMT_comments__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_reputational_risk__c), DMT_FormattingUtils.checkNull(data.oppClient.DMT_equator_Principles__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_cleanTech__c), DMT_FormattingUtils.checkNull(data.oppClient.DMT_portfolio_Alignment__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_kpiLink_Margin_Adjustment__c)}, 'ONE'));

        return result;
    }

    private List<Object> buildPdfMainCharacteristics(DMT_ViewController.LineDataWrapper data) {
        List<Object> result = new List<Object>();
        Map<String, Object> mcdTitle = DMT_Create_Pdf_Controller.createTitle('MAIN CHARACTERISTICS OF THE DEAL');
        mcdTitle.put('type', 'text');
        ((Map<String, Object>) mcdTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) mcdTitle.get('style')).put('textColor', '#004481');
        result.add(mcdTitle);

        result.add(createHelperTable('1. DESCRIPTION AND ISSUES', 'Brief description of the deal presented, main transactional features and changes vs former facility if any and key issues to be discussed (Max 617 characters)', data.oppClient.DMT_Description_Issues__c));
        result.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });
        result.add(createHelperTable('2. PURPOSE', 'Product/Banker\'s description of the use of funds of the facility/(ies) presented (Max 206 characters)', data.oppClient.DMT_Purpose__c));
        result.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });
        result.add(createHelperTable('3. OPPORTUNITIES & THREATS RELATED TO THE DEAL', 'Banker\'s insight on the impact of this deal: advantages, opportunities and potential issues - external or internal - which may arise. (Max. 103 characters/line)', data.oppClient.DMT_Opp_Threats_Related_Deal__c));
        return result;
    }

    private Map<String, Object> createHelperTable(String title, String helperText, String value) {
        List<List<Object>> head = new List<List<Object>>{ new List<Object>{title} };
        List<List<Object>> body = new List<List<Object>>{
            new List<Object>{ new Map<String,Object>{'content'=> helperText, 'styles'=>new Map<String,Object>{'fontSize'=>8,'textColor'=>'#666666','fontStyle'=>'italic'}} },
            new List<Object>{ DMT_FormattingUtils.checkNull(value) }
        };
        return DMT_Create_Pdf_Controller.createTableObj(head, body);
    }

    private List<Object> buildPdfOtherAspects(DMT_ViewController.LineDataWrapper data) {
        List<Object> result = new List<Object>();
        Map<String, Object> oaTitle = DMT_Create_Pdf_Controller.createTitle('OTHER ASPECTS');
        oaTitle.put('type', 'text');
        ((Map<String, Object>) oaTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) oaTitle.get('style')).put('textColor', '#004481');
        result.add(oaTitle);

        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'Applicable jurisdiction', 'Security Package', 'Rating Scenarios', 'Other relevant issues'},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.DMT_Applicable_Jurisdiction__c), DMT_FormattingUtils.checkNull(data.oppClient.DMT_Security_Package__c),
                            DMT_FormattingUtils.checkNull(data.oppClient.DMT_Rating_Scenarios__c), DMT_FormattingUtils.checkNull(data.oppClient.DMT_Other_Relevant_Issues__c)},
            'ONE'));
        return result;
    }

    private List<Object> buildPdfGlobalStructures(DMT_ViewController.LineDataWrapper data) {
        buildGlobalStructuresData(data);
        List<Object> result = new List<Object>();

        Map<String, Object> gsTitle = DMT_Create_Pdf_Controller.createTitle('Global Structures');
        gsTitle.put('type', 'text');
        ((Map<String, Object>) gsTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) gsTitle.get('style')).put('textColor', '#004481');
        result.add(gsTitle);

        List<Object> leftColumnItems = new List<Object>();
        List<Object> rightColumnItems = new List<Object>();

        // Left Column: Debt (Always render)
        leftColumnItems.add(new Map<String, Object>{
            'content' => createGlobalStructureTable(debtRecords, debtLabel, debtSum, '48%'),
            'margin' => new Map<String, Object>{ 'bottom' => 0 } // Reset margin
        });

        // Left Column: Equity (Always render)
        leftColumnItems.add(new Map<String, Object>{
            'content' => createGlobalStructureTable(equityRecords, equityLabel, equitySum, '48%'),
            'margin' => new Map<String, Object>{ 'bottom' => 0 }
        });

        // Right Column: Uses (Always render)
        rightColumnItems.add(new Map<String, Object>{
            'content' => createGlobalStructureTable(usesRecords, usesLabel, usesSum, '48%'),
            'margin' => new Map<String, Object>{ 'bottom' => 0 }
        });

        Map<String, Object> leftCell = new Map<String, Object>{
            'content' => '', 'type' => 'custom', 'custom' => leftColumnItems, 'styles' => new Map<String, Object>{ 'valign' => 'top', 'cellWidth' => '50%' }
        };
        Map<String, Object> rightCell = new Map<String, Object>{
            'content' => '', 'type' => 'custom', 'custom' => rightColumnItems, 'styles' => new Map<String, Object>{ 'valign' => 'top', 'cellWidth' => '50%' }
        };

        Map<String, Object> masterTable = DMT_Create_Pdf_Controller.createTableObj(new List<List<Object>>(), new List<List<Object>>{ new List<Object>{ leftCell, rightCell } });
        masterTable.put('theme', 'plain');
        masterTable.put('columnStyles', new Map<String, Object>{ '0' => new Map<String, Object>{ 'cellWidth' => '50%' }, '1' => new Map<String, Object>{ 'cellWidth' => '50%' } });

        result.add(masterTable);
        result.add(new Map<String, Object>{ 'type' => 'lineBreak' });
        return result;
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

    private Map<String, Object> createGlobalStructureTable(List<DMT_Global_Structure__c> records, String headerTitle, Decimal totalSum, String tableWidth) {
        List<List<Object>> head = new List<List<Object>>();
        head.add(new List<Object>{
            new Map<String, Object>{
                'content' => headerTitle, 'colSpan' => 2,
                'styles' => new Map<String, Object>{ 'halign' => 'center', 'fillColor' => new List<Integer>{174, 174, 174}, 'textColor' => 0, 'fontStyle' => 'bold', 'lineWidth' => 0 }
            }
        });

        List<List<Object>> body = new List<List<Object>>();
        Map<String, Object> rowStyle = new Map<String, Object>{ 'lineWidth' => new Map<String, Object>{ 'bottom' => 0.1, 'top' => 0, 'left' => 0, 'right' => 0 }, 'lineColor' => 200 };

        for (DMT_Global_Structure__c gs : records) {
            Map<String, Object> nameStyle = rowStyle.clone(); nameStyle.put('halign', 'left');
            Map<String, Object> fundStyle = rowStyle.clone(); fundStyle.put('halign', 'right');
            body.add(new List<Object>{
                new Map<String, Object>{ 'content' => DMT_FormattingUtils.checkNull(gs.Name), 'styles' => nameStyle },
                new Map<String, Object>{ 'content' => DMT_FormattingUtils.checkNull(gs.DMT_Funds__c), 'styles' => fundStyle }
            });
        }

        Map<String, Object> totalStyleBase = new Map<String, Object>{ 'fontStyle' => 'bold', 'fillColor' => '#F3F3F3', 'lineWidth' => 0 };
        Map<String, Object> totalStyleRight = totalStyleBase.clone(); totalStyleRight.put('halign', 'right');
        body.add(new List<Object>{
            new Map<String, Object>{ 'content' => 'TOTAL', 'styles' => totalStyleBase },
            new Map<String, Object>{ 'content' => String.valueOf(totalSum), 'styles' => totalStyleRight }
        });

        Map<String, Object> tableConfig = new Map<String, Object>();
        tableConfig.put('type', 'tableCustom');
        tableConfig.put('head', head);
        tableConfig.put('body', body);
        tableConfig.put('theme', 'plain');
        tableConfig.put('width', tableWidth);
        tableConfig.put('columns', new List<Map<String, Object>>{
            new Map<String, Object>{ 'header' => 'Name', 'dataKey' => '0' },
            new Map<String, Object>{ 'header' => 'Funds', 'dataKey' => '1' }
        });
        return tableConfig;
    }
}