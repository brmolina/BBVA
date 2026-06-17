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

    private class ProfitabilityContext {
        Map<String, Object> summary = new Map<String, Object>();
        String rorcThresholdText = '';
        String raroecThresholdText = '';
    }

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }
        try {
            Integer CURRENT_YEAR = Date.today().year();
            String comparisonAccountName = data.oppAccountParentName;

            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Approval Process Data' + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '') + '</h2>';

            html += buildHtmlBasicFinancials(data, CURRENT_YEAR);
            html += '<div style="margin-top: 20px;"></div>';
            html += buildHtmlClientInfo(data);
            html += '<div style="margin-top: 20px;"></div>';
            html += buildHtmlBusinessPlan(data, CURRENT_YEAR);
            html += '<div style="margin-top: 20px;"></div>';
            html += buildHtmlXSell(data, CURRENT_YEAR);
            html += '<div style="margin-top: 20px;"></div>';
            html += buildHtmlTiering(data);
            html += '<div style="margin-top: 20px;"></div>';
            html += buildgetHtmlSustainableFinance(data);
            html += '<div style="margin-top: 20px;"></div>';
            html += buildHtmlMainCharacteristics(data);
            html += '<div style="margin-top: 20px;"></div>';
            html += buildHtmlOtherAspects(data);
            html += '<div style="margin-top: 20px;"></div>';
            html += buildHtmlGlobalStructures(data);
            html += '<div style="margin-top: 20px;"></div>';
            html += buildHtmlBankingPoolStructure(data);
            html += '<div style="margin-top: 20px;"></div>';
            html += '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + DMT_FormattingUtils.tableRow1column('Competition for the deal', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Competition_Deal__c))
            + '</table>';
            html += '<div style="margin-top: 20px;"></div>';
            
            html += buildHtmlRisksInfo(data);
            html += '<div style="margin-top: 20px;"></div>';
            html += buildHtmlBasicRequirement(data);

            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_OppApprovalProcessDataRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String buildHtmlRisksInfo(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Risks Info</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New(
                'Asset Allocation Limit',
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Asset_Allocation_limit__c),
                'Financial Program Limit',
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Financial_Program_limit__c)
            )
            + '</table></div></div>';
    }

    private String buildHtmlBasicRequirement(DMT_ViewController.LineDataWrapper data) {
        ProfitabilityContext profitabilityContext = getProfitabilityContext(data);
        List<DMT_FormattingUtils.DisplayField> fields = new List<DMT_FormattingUtils.DisplayField>();

        if (!profitabilityContext.summary.isEmpty()) {
            fields.add(new DMT_FormattingUtils.DisplayField('RORC', formatProfitabilityMetric(profitabilityContext.summary.get('rorc'), profitabilityContext.rorcThresholdText)));
            fields.add(new DMT_FormattingUtils.DisplayField('RAROEC', formatProfitabilityMetric(profitabilityContext.summary.get('raroec'), profitabilityContext.raroecThresholdText)));
            fields.add(new DMT_FormattingUtils.DisplayField('RORC Prospective CDD', DMT_FormattingUtils.formatPercent(profitabilityContext.summary.get('rorcProspected'))));
            fields.add(new DMT_FormattingUtils.DisplayField('RAROEC Prospective CDD', DMT_FormattingUtils.formatPercent(profitabilityContext.summary.get('raroecProspected'))));
            fields.add(new DMT_FormattingUtils.DisplayField('Client RORC', DMT_FormattingUtils.formatPercent(profitabilityContext.summary.get('clientRorc'))));
            fields.add(new DMT_FormattingUtils.DisplayField('Revenues 12m', DMT_FormattingUtils.formatProfitabilityDecimal(profitabilityContext.summary.get('incomes12months'), 2)));
        }

        fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_ClientsGlobalRORCCIBPastFY_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Clients_Global_RORC_CIB_Past_FY__c)));
        fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_ClientsGlobalRorcLastFY_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_CDD_Clients_Global_Rorc_Last_FY__c)));
        fields.add(new DMT_FormattingUtils.DisplayField('Exception Pool', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c)));
        fields.add(new DMT_FormattingUtils.DisplayField('Other relevant issues', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Other_Relevant_Issues__c), 'FULL'));

        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Basic Requirement</h3>'
            + '<div class="slds-scope">'
            + DMT_FormattingUtils.generateHtmlTable(fields)
            + '</div></div>';
    }

    private ProfitabilityContext getProfitabilityContext(DMT_ViewController.LineDataWrapper data) {
        ProfitabilityContext context = new ProfitabilityContext();
        if (data == null || data.featuresList == null || data.featuresList.isEmpty()) {
            return context;
        }

        Map<String, Object> feature;
        for (Map<String, Object> item : data.featuresList) {
            if (item != null && item.containsKey('profitability') && item.get('profitability') != null) {
                feature = item;
                break;
            }
        }

        if (feature == null) {
            return context;
        }

        Map<String, Object> profitability = (Map<String, Object>) feature.get('profitability');
        Map<String, Object> audit = profitability.containsKey('audit') && profitability.get('audit') != null ? (Map<String, Object>) profitability.get('audit') : new Map<String, Object>();
        context.rorcThresholdText = formatThresholdPercent(audit.get('rorcThreshold'));
        context.raroecThresholdText = formatThresholdPercent(audit.get('raroecThreshold'));

        List<Object> results = profitability.containsKey('results') ? (List<Object>) profitability.get('results') : null;
        if (results == null || results.isEmpty()) {
            return context;
        }

        for (Object rec : results) {
            Map<String, Object> summary = (Map<String, Object>) rec;
            if (!summary.containsKey('productId') || summary.get('productId') == null) {
                context.summary = summary;
                break;
            }
        }

        return context;
    }

    private String formatProfitabilityMetric(Object value, String thresholdText) {
        String formattedValue = DMT_FormattingUtils.formatPercent(value);
        return String.isBlank(thresholdText) ? formattedValue : formattedValue + ' < ' + thresholdText;
    }

    private String formatThresholdPercent(Object value) {
        if (value == null) {
            return '';
        }

        try {
            return DMT_FormattingUtils.formatPercent(Decimal.valueOf(String.valueOf(value)));
        } catch (Exception e) {
            return '';
        }
    }

    private String buildHtmlBasicFinancials(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        String html = '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Basic Financials</h3>'
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
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + DMT_FormattingUtils.tableRow1column('Other Relevant Ratios', DMT_FormattingUtils.checkNull(data.oppClient.Other_Relevant_Ratios_desc__c))
            + DMT_FormattingUtils.tableRow1column('Basic Financials Comments', DMT_FormattingUtils.checkNull(data.oppClient.cstk_sust_indicators_comments__c))
            + '</table></div></div>';
        return html;
    }

    private String buildHtmlClientInfo(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Client Information</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'

            + DMT_FormattingUtils.tableRow1column(
                'Geographical Footprint',
                DMT_FormattingUtils.checkNull(data.oppClient.Geographical_Footprint_desc__c)
            )

            + DMT_FormattingUtils.tableRow1column(
                'Relationship Status',
                DMT_FormattingUtils.checkNull(data.oppClient.Relationship_Status_desc__c)
            )

            + DMT_FormattingUtils.tableRow1column(
                'Industry Overview',
                DMT_FormattingUtils.checkNull(data.oppClient.Industry_Overview_desc__c)
            )

            + '</table></div></div>';
    }

    private String buildHtmlBusinessPlan(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        String html = '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Business Plan Data</h3>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr style="page-break-inside: avoid;">'
            + '<td colspan="5" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Business Plan</strong></td>'
            + '</tr>'
            + '<tr style="page-break-inside: avoid;">'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+''+ '</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR - 1)+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+CURRENT_YEAR+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 1)+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>'+(CURRENT_YEAR + 2)+'</strong></td>'
            + '</tr>';

        List<String> labelBPD = new List<String>{'Corp. Synd. Lending','Structured Finance','Structured Trade Finance', 'Rates','GTF', 'Working Capital', 'Total Non X-Sell',
                                                'ECM/M&A', 'DCM', 'Credit/Equity', 'FX/CCS','Cash Management','Client Resources','Securities Services', 'Total X-Sell',
                                                'Total Revenues','% Cross Border Revenues', 'Transactional KPI'};
        List<String> valueBPD = new List<String>{'FY_Corp_Synd_Lending_amount__c', 'FY_Structured_Finance_amount__c', 'FY_Str_Trade_Finance_amount__c', 'FY_Rates_amount__c', 'FY_GTF_amount__c',
                                                'FY_Working_Capital_amount__c', 'FY_Total_Non_X_Sell_amount__c', 'FY_ECM_M_A_Amount__c', 'FY_DCM_amount__c', 'FY_Credit_Equity_amount__c',
                                                'FY_FX_CCS_amount__c', 'FY_Cash_Management_amount__c', 'FY_Client_Resources_amount__c', 'FY_Securities_Services_amount__c',
                                                'FY_Child_X_Sell_amount__c', 'FY_Total_Revenues_amount__c','gf_kpi_trans_fees_', 'gf_xb_cust_ope_revenue_'};
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
                    + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.oppClient.get(apiName1)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                    + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.oppClient.get(apiName2)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                    + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.oppClient.get(apiName3)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                    + cellStart + (labelStyle.contains('bold') ? '<strong>' : '') + DMT_FormattingUtils.checkNull(data.oppClient.get(apiName4)) + (labelStyle.contains('bold') ? '</strong>' : '') + cellEnd
                    + '</tr>';
        }
            html += '</table></div>'
                    + '<div style="margin-top: 20px;"></div>'
                    + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
                    + DMT_FormattingUtils.tableRow1column('Qualitative Assessment of the estimated Revenues', DMT_FormattingUtils.checkNull(data.oppClient.Qualitative_Assesment_of_X_Sell_Rev_desc__c))
                    + DMT_FormattingUtils.tableRow1column('History of the deal', DMT_FormattingUtils.checkNull(data.oppClient.DMT_History_Deal__c))
                    + '</table>'
                    + '<table class="style-table style-border" style="width:100%; border-collapse: separate; border-spacing: 10px 0; table-layout: fixed; margin-left: -10px; margin-right: -10px;">'
                    + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
                    + DMT_FormattingUtils.tableRow2columns_New(
                        'Commitment Deadline',
                        DMT_FormattingUtils.changeDateFormat(data.oppClient.DMT_Commitment_Deadline__c),
                        'Exception Pool',
                        DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c)
                    )
                    + DMT_FormattingUtils.tableRow2columns_New(
                        'Currency',
                        DMT_FormattingUtils.checkNull(data.oppClient.DMT_Currency__c),
                        'Xsell Cost to Income (%)',
                        DMT_FormattingUtils.checkNull(data.oppClient.DMT_Xsell_Cost_to_Income__c)
                    )
                    + DMT_FormattingUtils.tableRow2columns_New(
                        'RWA Total RORC NBC Last12m*CET1',
                        DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_RWA__c),
                        'Economic Profit RORC NBC Last 12m',
                        DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_Net_Incomes__c)
                    )
                    + '</table></br>';

                return html;
    }


    private String buildHtmlTiering(DMT_ViewController.LineDataWrapper data) {
        return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Client Tier</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: separate; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New('Tiering Action', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Tiering_Action__c), 'Current Tier', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Current__c))
            + DMT_FormattingUtils.tableRow2columns_New('Target Tier', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Target__c), '', '')
            + '</table></div></div>&nbsp;</br>';
    }

    private String buildgetHtmlSustainableFinance(DMT_ViewController.LineDataWrapper data) {
        if(data.opportunity.DMT_Product_Area__c == 'IB&F') {
            return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Sustainable Finance</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New(System.Label.dmt_cl_ReputationalRisk_Title, getReputationalRiskValue(data.oppClient.DMT_reputational_risk__c), System.Label.dmt_cl_EquatorPrinciples_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_equator_Principles__c))
            + DMT_FormattingUtils.tableRow2columns_New(System.Label.dmt_cl_EnviromentalSocialFramework_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Enviromental_Social_Framework__c), System.Label.dmt_cl_GroupHaveExposureToThermalCoal_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Group_Have_Exposure_To_Thermal_Coal__c))
            + DMT_FormattingUtils.tableRow2columns_New(System.Label.dmt_cl_CapacityWeight_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Capacity_Weight__c), System.Label.dmt_cl_CompanyHaveACoalPhaseOutPlan_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Company_Have_A_Coal_Phase_Out_Plan__c))
            + DMT_FormattingUtils.tableRow2columns_New(System.Label.dmt_cl_KPIMarginAdjustment_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_KPI_Margin_Adjustment__c), System.Label.dmt_cl_TRI_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_tri__c))
            + DMT_FormattingUtils.tableRow2columns_New(System.Label.dmt_cl_GroupEngagementPlan_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Group_Engagement_Plan__c), '', '')
            + '</table></div></div>';
        } else if(data.opportunity.DMT_Product_Area__c == 'GTB') {
            return '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Sustainable Finance</h3>'
            + '<div class="slds-scope">'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow2columns_New(System.Label.dmt_cl_TRI_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_tri__c), '', '')
            + '</table></div></div>';
        } else {
            return '';
        }
    }

    private String buildHtmlMainCharacteristics(DMT_ViewController.LineDataWrapper data) {
        return '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Main Characteristics of the Deal</h3>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            + DMT_FormattingUtils.tableRow1columnWithHelper('1. Description and Issues', 'Brief description of the deal presented, main transactional features and changes vs former facility if any and key issues to be discussed (Max 617 characters)', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Description_Issues__c))
            + DMT_FormattingUtils.tableRow1columnWithHelper('2. Purpose', 'Product/Banker\'s description of the use of funds of the facility/(ies) presented (Max 206 characters)', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Purpose__c))
            + DMT_FormattingUtils.tableRow1columnWithHelper('3. Opportunities & Threats Related to the Deal', 'Banker\'s insight on the impact of this deal: advantages, opportunities and potential issues - external or internal - which may arise. (Max. 103 characters/line)', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Opp_Threats_Related_Deal__c))
            + '</table>';
    }

    private String buildHtmlOtherAspects(DMT_ViewController.LineDataWrapper data) {
        return '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Other Aspects</h3>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout: fixed;">'
            //+ '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
            + DMT_FormattingUtils.tableRow1column('Applicable jurisdiction',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Applicable_Jurisdiction__c))
            + DMT_FormattingUtils.tableRow1column('Security Package',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Security_Package__c))
            + DMT_FormattingUtils.tableRow1column('Rating Scenarios',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Rating_Scenarios__c))
            + DMT_FormattingUtils.tableRow1column('Other relevant issues',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Other_Relevant_Issues__c))
            + '</table>';
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
            html += + '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc;">' + getDisplayName(gs.Name, gs.Id) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.DMT_Funds__c) + '</td></tr>';
        }
        html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TOTAL</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + debtSum + '</strong></td></tr></table>';

        // Spacer + Equity
        html += '&nbsp;<br/>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr><th colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + equityLabel + '</strong></th></tr>';
        for (DMT_Global_Structure__c gs : equityRecords) {
            html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc;">' + getDisplayName(gs.Name, gs.Id) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.DMT_Funds__c) + '</td></tr>';
        }
        html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TOTAL</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + equitySum + '</strong></td></tr></table>';

        html += '</td><td style="width:50%; vertical-align: top; padding-left: 10px;">';

        // Uses
        html += '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr><th colspan="2" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + usesLabel + '</strong></th></tr>';
        for (DMT_Global_Structure__c gs : usesRecords) {
            html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc;">' + getDisplayName(gs.Name, gs.Id) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(gs.DMT_Funds__c) + '</td></tr>';
        }
        html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TOTAL</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + usesSum + '</strong></td></tr></table>';

        html += '</td></tr></table></div>&nbsp;</br>';
        return html;
    }

        private String buildHtmlBankingPoolStructure(DMT_ViewController.LineDataWrapper data) {
        Map<String, DMT_Banking_Pool_Structure__c> tierMap = new Map<String, DMT_Banking_Pool_Structure__c>();

        for (DMT_Banking_Pool_Structure__c row : data.bankingPoolStructures) {
            tierMap.put(row.Name, row);
        }

        List<String> tiers = new List<String>{ 'Tier 1', 'Tier 2', 'Tier 3', 'Tier 4 or above' };

        String html = '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Banking Pool Structure</h3>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr>'
            + '<td colspan="5" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Banking Pool Structure</strong></td>'
            + '</tr>'
            + '<tr>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong></strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Ticket (Mn)</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Fees</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Margin</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Nº banks</strong></td>'
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

    // ====================================================================================================
    // PDF RENDERING
    // ====================================================================================================

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return new Map<String, Object>();
        }
        try {
            Integer CURRENT_YEAR = Date.today().year();
            String comparisonAccountName = data.oppAccountParentName;
            List<Object> contentList = new List<Object>();
            Map<String, Object> component = new Map<String, Object>();

            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 60 });
            contentList.add(DMT_Create_Pdf_Controller.createTitle('Approval Process Data'  + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '')));

            contentList.addAll(buildPdfBasicFinancials(data, CURRENT_YEAR));
            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 60 });

            contentList.addAll(buildPdfClientInfo(data));
            contentList.addAll(buildPdfBusinessPlan(data, CURRENT_YEAR));
            contentList.addAll(buildPdfXSell(data, CURRENT_YEAR));
            contentList.addAll(buildPdfTiering(data));

            contentList.addAll(buildPdfSustainableFinance(data));
            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

            contentList.addAll(buildPdfMainCharacteristics(data));
            contentList.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

            contentList.addAll(buildPdfOtherAspects(data));
            contentList.addAll(buildPdfGlobalStructures(data));
            contentList.addAll(buildPdfBankingPoolStructure(data));

            contentList.add(DMT_Create_Pdf_Controller.createListText(new List<String>{'Competition for the deal'}, new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.DMT_Competition_Deal__c)}, 'ONE'));

            contentList.addAll(buildPdfRisksInfo(data));
            contentList.addAll(buildPdfBasicRequirement(data));

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

        result.add(DMT_Create_Pdf_Controller.generatePdfList(new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Asset Allocation Limit', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Asset_Allocation_limit__c)),
            new DMT_FormattingUtils.DisplayField('Financial Program Limit', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Financial_Program_limit__c))
        }));

        return result;
    }

    private List<Object> buildPdfBasicRequirement(DMT_ViewController.LineDataWrapper data) {
        List<Object> result = new List<Object>();
        ProfitabilityContext profitabilityContext = getProfitabilityContext(data);
        List<DMT_FormattingUtils.DisplayField> fields = new List<DMT_FormattingUtils.DisplayField>();

        Map<String, Object> basicRequirementTitle = DMT_Create_Pdf_Controller.createTitle('Basic Requirement');
        basicRequirementTitle.put('type', 'text');
        ((Map<String, Object>) basicRequirementTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) basicRequirementTitle.get('style')).put('textColor', '#004481');
        result.add(basicRequirementTitle);

        if (!profitabilityContext.summary.isEmpty()) {
            fields.add(new DMT_FormattingUtils.DisplayField('RORC', formatProfitabilityMetric(profitabilityContext.summary.get('rorc'), profitabilityContext.rorcThresholdText)));
            fields.add(new DMT_FormattingUtils.DisplayField('RAROEC', formatProfitabilityMetric(profitabilityContext.summary.get('raroec'), profitabilityContext.raroecThresholdText)));
            fields.add(new DMT_FormattingUtils.DisplayField('RORC Prospective CDD', DMT_FormattingUtils.formatPercent(profitabilityContext.summary.get('rorcProspected'))));
            fields.add(new DMT_FormattingUtils.DisplayField('RAROEC Prospective CDD', DMT_FormattingUtils.formatPercent(profitabilityContext.summary.get('raroecProspected'))));
            fields.add(new DMT_FormattingUtils.DisplayField('Client RORC', DMT_FormattingUtils.formatPercent(profitabilityContext.summary.get('clientRorc'))));
            fields.add(new DMT_FormattingUtils.DisplayField('Revenues 12m', DMT_FormattingUtils.formatProfitabilityDecimal(profitabilityContext.summary.get('incomes12months'), 2)));
        }

        fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_ClientsGlobalRORCCIBPastFY_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Clients_Global_RORC_CIB_Past_FY__c)));
        fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_ClientsGlobalRorcLastFY_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_CDD_Clients_Global_Rorc_Last_FY__c)));
        fields.add(new DMT_FormattingUtils.DisplayField('Exception Pool', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c)));
        fields.add(new DMT_FormattingUtils.DisplayField('Other relevant issues', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Other_Relevant_Issues__c), 'FULL'));

        result.add(DMT_Create_Pdf_Controller.generatePdfList(fields));

        return result;
    }

    private List<Object> buildPdfBasicFinancials(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        List<Object> result = new List<Object>();
        Map<String, Object> basicTitle = DMT_Create_Pdf_Controller.createTitle('Basic Financials');
        basicTitle.put('type', 'text');
        ((Map<String, Object>) basicTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) basicTitle.get('style')).put('textColor', '#004481');
        result.add(basicTitle);

        List<Object> titleSectionBF = DMT_Create_Pdf_Controller.createTitleSection('Basic Financials');
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
            new List<String>{
                'Geographical Footprint',
                'Relationship Status',
                'Industry Overview'
            },
            new List<String>{
                DMT_FormattingUtils.checkNull(data.oppClient.Geographical_Footprint_desc__c),
                DMT_FormattingUtils.checkNull(data.oppClient.Relationship_Status_desc__c),
                DMT_FormattingUtils.checkNull(data.oppClient.Industry_Overview_desc__c)
            },
            'ONE'
        ));

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

        List<Object> titleSectionBPD = DMT_Create_Pdf_Controller.createTitleSection('Business Plan');
        result.add(titleSectionBPD[0]);
        result.add(titleSectionBPD[1]);

        List<List<String>> bpdHead = new List<List<String>>{new List<String>{'', String.valueOf(CURRENT_YEAR - 1), String.valueOf(CURRENT_YEAR), String.valueOf(CURRENT_YEAR + 1),String.valueOf(CURRENT_YEAR + 2)}};
        List<List<String>> bpdRows = new List<List<String>>();
        List<String> labelBPD = new List<String>{'Corp. Synd. Lending','Structured Finance','Structured Trade Finance', 'Rates','GTF', 'Working Capital', 'Total Non X-Sell',
                                                'ECM/M&A', 'DCM', 'Credit/Equity', 'FX/CCS','Cash Management','Client Resources','Securities Services', 'Total X-Sell',
                                                'Total Revenues','% Cross Border Revenues', 'Transactional KPI'};
        List<String> valueBPD = new List<String>{'FY_Corp_Synd_Lending_amount__c', 'FY_Structured_Finance_amount__c', 'FY_Str_Trade_Finance_amount__c', 'FY_Rates_amount__c', 'FY_GTF_amount__c',
                                                'FY_Working_Capital_amount__c', 'FY_Total_Non_X_Sell_amount__c', 'FY_ECM_M_A_Amount__c', 'FY_DCM_amount__c', 'FY_Credit_Equity_amount__c',
                                                'FY_FX_CCS_amount__c', 'FY_Cash_Management_amount__c', 'FY_Client_Resources_amount__c', 'FY_Securities_Services_amount__c',
                                                'FY_Child_X_Sell_amount__c', 'FY_Total_Revenues_amount__c','gf_kpi_trans_fees_','gf_xb_cust_ope_revenue_'};

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
                DMT_FormattingUtils.checkNull(data.oppClient.get(apiName1)),
                DMT_FormattingUtils.checkNull(data.oppClient.get(apiName2)),
                DMT_FormattingUtils.checkNull(data.oppClient.get(apiName3)),
                DMT_FormattingUtils.checkNull(data.oppClient.get(apiName4))
            });
        }
        result.add(DMT_Create_Pdf_Controller.createTable(bpdHead, bpdRows));

        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'Qualitative Assessment of the estimated Revenues'},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.Qualitative_Assesment_of_X_Sell_Rev_desc__c)},
            'ONE'
        ));

        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'History of the deal'},
            new List<String>{DMT_FormattingUtils.checkNull(data.oppClient.DMT_History_Deal__c)},
            'ONE'
        ));

        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'Commitment Deadline', 'Exception Pool'},
            new List<String>{
                DMT_FormattingUtils.changeDateFormat(data.oppClient.DMT_Commitment_Deadline__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c)
            },
            ''
        ));

        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'Currency', 'Xsell Cost to Income (%)'},
            new List<String>{
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Currency__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Xsell_Cost_to_Income__c)
            },
            ''
        ));

        result.add(DMT_Create_Pdf_Controller.createListText(
            new List<String>{'RWA Total RORC NBC Last12m*CET1', 'Economic Profit RORC NBC Last 12m'},
            new List<String>{
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_RWA__c),
                DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_Net_Incomes__c)
            },
            ''
        ));
        return result;
    }

    private List<Object> buildPdfTiering(DMT_ViewController.LineDataWrapper data) {
        List<Object> result = new List<Object>();
        Map<String, Object> clientTierTitle = DMT_Create_Pdf_Controller.createTitle('Client Tier');
        clientTierTitle.put('type', 'text');
        ((Map<String, Object>) clientTierTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) clientTierTitle.get('style')).put('textColor', '#004481');
        result.add(clientTierTitle);

        result.add(DMT_Create_Pdf_Controller.generatePdfList(new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Tiering Action', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Tiering_Action__c)),
            new DMT_FormattingUtils.DisplayField('Current Tier', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Current__c)),
            new DMT_FormattingUtils.DisplayField('Target Tier', DMT_FormattingUtils.checkNull(data.oppClient.DMT_Target__c))
        }));

        return result;
    }

    private List<Object> buildPdfSustainableFinance(DMT_ViewController.LineDataWrapper data) {
        List<Object> result = new List<Object>();
        String productArea = data.opportunity.DMT_Product_Area__c;

        // Si no es IB&F ni GTB, no mostrar la sección
        if (String.isBlank(productArea) || (productArea != 'IB&F' && productArea != 'GTB')) {
            return result;
        }

        result.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });

        Map<String, Object> sFTitle = DMT_Create_Pdf_Controller.createTitle('Sustainable Finance');
        sFTitle.put('type', 'text');
        ((Map<String, Object>) sFTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) sFTitle.get('style')).put('textColor', '#004481');
        result.add(sFTitle);

        List<DMT_FormattingUtils.DisplayField> fields = new List<DMT_FormattingUtils.DisplayField>();

        if (productArea == 'IB&F') {
            fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_ReputationalRisk_Title, getReputationalRiskValue(data.oppClient.DMT_reputational_risk__c)));
            fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_EquatorPrinciples_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_equator_Principles__c)));

            fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_EnviromentalSocialFramework_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Enviromental_Social_Framework__c)));
            fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_GroupHaveExposureToThermalCoal_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Group_Have_Exposure_To_Thermal_Coal__c)));

            fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_CapacityWeight_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Capacity_Weight__c)));
            fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_CompanyHaveACoalPhaseOutPlan_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Company_Have_A_Coal_Phase_Out_Plan__c)));

            fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_KPIMarginAdjustment_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_KPI_Margin_Adjustment__c)));
            fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_TRI_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_tri__c)));

            fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_GroupEngagementPlan_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_Group_Engagement_Plan__c)));
        } else if (productArea == 'GTB') {
            fields.add(new DMT_FormattingUtils.DisplayField(System.Label.dmt_cl_TRI_Title, DMT_FormattingUtils.checkNull(data.oppClient.DMT_tri__c)));
        }

        result.add(DMT_Create_Pdf_Controller.generatePdfList(fields));
        return result;
    }

    public String getReputationalRiskValue(Object rawValue) {
        if (rawValue == null || rawValue == 'null') {
            return 'N/A';
        }

        Integer controversy = Integer.valueOf(String.valueOf(rawValue));
        if (controversy >= 0 && controversy <= 2) {
            return 'Low';
        } else if (controversy >= 3 && controversy <= 4) {
            return 'Medium';
        } else if (controversy > 4) {
            return 'High';
        } else {
            return 'N/A';
        }
    }

    private List<Object> buildPdfMainCharacteristics(DMT_ViewController.LineDataWrapper data) {
        List<Object> result = new List<Object>();
        Map<String, Object> mcdTitle = DMT_Create_Pdf_Controller.createTitle('Main Characteristics of the Deal');
        mcdTitle.put('type', 'text');
        ((Map<String, Object>) mcdTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) mcdTitle.get('style')).put('textColor', '#004481');
        result.add(mcdTitle);

        result.add(createHelperTable('1. Description and Issues', 'Brief description of the deal presented, main transactional features and changes vs former facility if any and key issues to be discussed (Max 617 characters)', data.oppClient.DMT_Description_Issues__c));
        result.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });
        result.add(createHelperTable('2. Purpose', 'Product/Banker\'s description of the use of funds of the facility/(ies) presented (Max 206 characters)', data.oppClient.DMT_Purpose__c));
        result.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 50 });
        result.add(createHelperTable('3. Opportunities & Threats Related to the Deal', 'Banker\'s insight on the impact of this deal: advantages, opportunities and potential issues - external or internal - which may arise. (Max. 103 characters/line)', data.oppClient.DMT_Opp_Threats_Related_Deal__c));
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
        Map<String, Object> oaTitle = DMT_Create_Pdf_Controller.createTitle('Other Aspects');
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

    private List<Object> buildPdfBankingPoolStructure(DMT_ViewController.LineDataWrapper data) {
        List<Object> result = new List<Object>();

        Map<String, DMT_Banking_Pool_Structure__c> tierMap = new Map<String, DMT_Banking_Pool_Structure__c>();
        for (DMT_Banking_Pool_Structure__c row : data.bankingPoolStructures) {
            String key = String.isNotBlank(row.Name) ? row.Name.trim() : null;
            if (String.isNotBlank(key)) {
                tierMap.put(key.trim(), row);
            }
        }

        Map<String, Object> title = DMT_Create_Pdf_Controller.createTitle('Banking Pool Structure');
        title.put('type', 'text');
        ((Map<String, Object>) title.get('style')).put('fontSize', 14);
        ((Map<String, Object>) title.get('style')).put('textColor', '#004481');
        result.add(title);

        List<Object> titleSection = DMT_Create_Pdf_Controller.createTitleSection('Banking Pool Structure');
        result.add(titleSection[0]);
        result.add(titleSection[1]);

        List<List<String>> head = new List<List<String>>{
            new List<String>{'', 'Ticket (Mn)', 'Fees', 'Margin', 'Nº banks'}
        };

        List<List<String>> body = new List<List<String>>();
        List<String> tiers = new List<String>{'Tier 1', 'Tier 2', 'Tier 3', 'Tier 4 or above'};

        for (String tier : tiers) {
            DMT_Banking_Pool_Structure__c row = tierMap.get(tier);

            body.add(new List<String>{
                tier,
                DMT_FormattingUtils.checkNull(row != null ? row.DMT_Ticket__c : null),
                DMT_FormattingUtils.checkNull(row != null ? row.DMT_Fees__c : null),
                DMT_FormattingUtils.checkNull(row != null ? row.DMT_Margin__c : null),
                DMT_FormattingUtils.checkNull(row != null ? row.DMT_N_Banks__c : null)
            });
        }

        result.add(DMT_Create_Pdf_Controller.createTable(head, body));
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
                new Map<String, Object>{ 'content' => getDisplayName(gs.Name, gs.Id), 'styles' => nameStyle },
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

    private String buildHtmlXSell(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        if (data.xSellOpp.isEmpty()) return '';

        String html = '<div>'
            + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Cross SELL</h3>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr style="page-break-inside: avoid;">'
            + '<td colspan="5" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Cross SELL</strong></td>'
            + '</tr>'
            + '<tr style="page-break-inside: avoid;">'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>Geography</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FY'+(CURRENT_YEAR - 1)+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FY'+CURRENT_YEAR+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FY'+(CURRENT_YEAR + 1)+'</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FY'+(CURRENT_YEAR + 2)+'</strong></td>'
            + '</tr>';

        for(DMT_X_Sell__c xs : data.xSellOpp){
            String geoLabel = data.taxonomyH007Map.containsKey(xs.Booking_Geography__c) ? data.taxonomyH007Map.get(xs.Booking_Geography__c) : DMT_FormattingUtils.checkNull(xs.Booking_Geography__c);
            
            html += '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + geoLabel + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(xs.XSELL_Value_PY__c) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(xs.XSELL_Value_CY__c) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(xs.XSELL_Value_NY__c) + '</td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(xs.XSELL_Value_NY1__c) + '</td>'
                + '</tr>';
        }
        
        html += '</table></div>';
        return html;
    }

    private List<Object> buildPdfXSell(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        List<Object> result = new List<Object>();
        if (data.xSellOpp.isEmpty()) return result;

        result.add(new Map<String, Object>{ 'type' => 'pageBreak', 'threshold' => 70 });
        Map<String, Object> xsTitle = DMT_Create_Pdf_Controller.createTitle('Cross SELL');
        xsTitle.put('type', 'text');
        ((Map<String, Object>) xsTitle.get('style')).put('fontSize', 14);
        ((Map<String, Object>) xsTitle.get('style')).put('textColor', '#004481');
        result.add(xsTitle);

        List<Object> titleSectionXS = DMT_Create_Pdf_Controller.createTitleSection('Cross SELL');
        result.add(titleSectionXS[0]);
        result.add(titleSectionXS[1]);

        List<List<String>> xsHead = new List<List<String>>{new List<String>{'Geography', 'FY'+(CURRENT_YEAR - 1), 'FY'+CURRENT_YEAR, 'FY'+(CURRENT_YEAR + 1), 'FY'+(CURRENT_YEAR + 2)}};
        List<List<String>> xsRows = new List<List<String>>();
        
        for(DMT_X_Sell__c xs : data.xSellOpp){
            String geoLabel = data.taxonomyH007Map.containsKey(xs.Booking_Geography__c) ? data.taxonomyH007Map.get(xs.Booking_Geography__c) : DMT_FormattingUtils.checkNull(xs.Booking_Geography__c);
            xsRows.add(new List<String>{
                geoLabel,
                DMT_FormattingUtils.checkNull(xs.XSELL_Value_PY__c),
                DMT_FormattingUtils.checkNull(xs.XSELL_Value_CY__c),
                DMT_FormattingUtils.checkNull(xs.XSELL_Value_NY__c),
                DMT_FormattingUtils.checkNull(xs.XSELL_Value_NY1__c)
            });
        }
        
        result.add(DMT_Create_Pdf_Controller.createTable(xsHead, xsRows));
        return result;
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

}