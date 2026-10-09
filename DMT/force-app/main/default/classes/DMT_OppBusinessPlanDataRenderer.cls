public without sharing class DMT_OppBusinessPlanDataRenderer implements DMT_ViewRenderer {

    // Row labels and their corresponding API field on DMT_Opportunity_Business_Plan__c
    private static final List<String> ROW_LABELS = new List<String>{
        'Corp. Synd. Lending', 'Structured Finance', 'Structured Trade Finance',
        'Rates', 'GTF', 'Working Capital', 'Total Non X-Sell',
        'ECM', 'M&A', 'DCM', 'Credit/Equity', 'FX/CCS',
        'Cash Management', 'Client Resources', 'Securities Services', 'Total X-Sell',
        'Total Revenues', '% Cross Border Revenues', 'Transactional KPI'
    };

    private static final List<String> ROW_FIELDS = new List<String>{
        'Current_FY_Corp_Synd_Lending_amount__c', 'Current_FY_Structured_Finance_amount__c', 'Current_FY_Str_Trade_Finance_amount__c',
        'Current_FY_Rates_amount__c', 'Current_FY_GTF_amount__c', 'Current_FY_Working_Capital_amount__c', 'Current_FY_Total_Non_X_Sell_amount__c',
        'Current_FY_ECM_M_A_Amount__c', 'Current_FY_M_A_amount__c', 'Current_FY_DCM_amount__c', 'Current_FY_Credit_Equity_amount__c',
        'Current_FY_FX_CCS_amount__c', 'Current_FY_Cash_Management_amount__c', 'Current_FY_Client_Resources_amount__c',
        'Current_FY_Securities_Services_amount__c', 'Current_FY_Total_X_Sell_amount__c',
        'Current_FY_Total_Revenues_amount__c', 'gf_xb_cust_ope_revenue_cyr_per__c', 'gf_kpi_trans_fees_cyr_amount__c'
    };

    private static final Set<String> TOTAL_ROWS = new Set<String>{'Total Non X-Sell', 'Total X-Sell', 'Total Revenues'};

    private static final List<String> X_SELL_FIELDS = new List<String>{
        'Current_FY_ECM_M_A_Amount__c', 'Current_FY_M_A_amount__c', 'Current_FY_DCM_amount__c', 'Current_FY_Credit_Equity_amount__c',
        'Current_FY_FX_CCS_amount__c', 'Current_FY_Cash_Management_amount__c', 'Current_FY_Client_Resources_amount__c', 'Current_FY_Securities_Services_amount__c'
    };

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            Integer CURRENT_YEAR = Date.today().year();
            String comparisonAccountName = data.oppAccountParentName;

            // Group BP records by geography
            Map<String, List<DMT_Opportunity_Business_Plan__c>> recordsByGeo = groupByGeography(data.businessPlanRecords);

            String html = '<div>'
                        + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Business Plan Data'
                        + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '') + '</h2>';

            if (recordsByGeo.isEmpty()) {
                html += '<p style="color: #666;">No Business Plan records found.</p>';
            } else {
                for (String geo : recordsByGeo.keySet()) {
                    if (geo != 'GLOBAL') {
                        html += renderHtmlGeographyTable(geo, recordsByGeo.get(geo), CURRENT_YEAR, data.taxonomyH007BPMap);
                    }
                }
                // GLOBAL is always computed live as the sum of all non-GLOBAL geography records,
                // mirroring dmt_business_plan_table_geography.js's _buildGlobalAggregatedRows().
                // The persisted GLOBAL record is never read here: it's only kept in sync when a
                // user saves through that LWC, so trusting it directly can show stale totals.
                List<DMT_Opportunity_Business_Plan__c> aggregatedGlobal = DMT_BusinessPlanGlobalAggregator.buildAggregatedGlobalRecords(data.businessPlanRecords, ROW_FIELDS);
                if (!aggregatedGlobal.isEmpty()) {
                    html += renderHtmlGeographyTable('GLOBAL', aggregatedGlobal, CURRENT_YEAR, data.taxonomyH007BPMap);
                }
            }

            // Extract Qualitative Assessment and Currency from the GLOBAL BP record
            DMT_Opportunity_Business_Plan__c globalBpRecord = findGlobalRecord(data.businessPlanRecords);
            String qualitativeAssessment = (globalBpRecord != null) ? DMT_FormattingUtils.checkNull(globalBpRecord.DMT_QAOTER__c) : '';
            String currency_val = (globalBpRecord != null) ? DMT_FormattingUtils.checkNull(globalBpRecord.DMT_Currency__c) : '';
            String xsellCostToIncome = (globalBpRecord != null) ? DMT_FormattingUtils.checkNull(globalBpRecord.DMT_Xsell_Cost_to_Income__c) : '';

            html += '</div>'
                + '<div style="margin-top: 20px;"></div>'
                + '<table class="style-table style-border" style="width:100%; border-collapse: separate; border-spacing: 10px 0; table-layout: fixed; margin-left: -10px; margin-right: -10px;">'
                + '<colgroup><col style="width: 50%;"><col style="width: 50%;"></colgroup>'
                + DMT_FormattingUtils.tableRow2columns_New('Qualitative Assessment of the estimated Revenues', qualitativeAssessment, 'Currency', currency_val)
                + DMT_FormattingUtils.tableRow2columns_New('Xsell Cost to Income', xsellCostToIncome, '', '')
                + '</table>'
                + '<div style="margin-top: 20px;"></div>';


            return html;

        } catch (Exception e) {
            System.debug('Error in DMT_OppBusinessPlanDataRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String renderHtmlGeographyTable(String geoCode, List<DMT_Opportunity_Business_Plan__c> records, Integer CURRENT_YEAR, Map<String, String> taxonomyH007Map) {
        String geoLabel = (taxonomyH007Map != null && taxonomyH007Map.containsKey(geoCode))
            ? taxonomyH007Map.get(geoCode)
            : geoCode;

        // Index records by year
        Map<Integer, DMT_Opportunity_Business_Plan__c> recordByYear = new Map<Integer, DMT_Opportunity_Business_Plan__c>();
        for (DMT_Opportunity_Business_Plan__c rec : records) {
            if (rec.DMT_Year__c != null) {
                recordByYear.put(Integer.valueOf(rec.DMT_Year__c), rec);
            }
        }

        // 5 year columns: CY-2, CY-1, CY, CY+1, CY+2
        List<Integer> years = new List<Integer>{CURRENT_YEAR - 2, CURRENT_YEAR - 1, CURRENT_YEAR, CURRENT_YEAR + 1, CURRENT_YEAR + 2};

        String html = '<table class="style-table" style="width:100%; border-collapse: collapse; margin-bottom: 15px;">'
            + '<tr>'
            + '<td colspan="6" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>Business Plan - ' + geoLabel + '</strong></td>'
            + '</tr>'
            + '<tr>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong></strong></td>';

        for (Integer yr : years) {
            html += '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + yr + '</strong></td>';
        }
        html += '</tr>';

        for (Integer i = 0; i < ROW_LABELS.size(); i++) {
            String label = ROW_LABELS[i];
            String apiField = ROW_FIELDS[i];
            Boolean isTotalRow = TOTAL_ROWS.contains(label);

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
                    : (label == 'Total X-Sell') ? DMT_BusinessPlanGlobalAggregator.computeXSellTotal(rec, X_SELL_FIELDS)
                    : rec.get(apiField);
                html += cellStart + boldOpen + DMT_FormattingUtils.checkNull(val) + boldClose + cellEnd;
            }
            html += '</tr>';
        }

        html += '</table>';
        return html;
    }

    // ====================================================================================================
    // HELPERS
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

    /**
     * Finds the first GLOBAL BP record (any year). Used to extract DMT_QAOTER__c and DMT_Currency__c.
     */
    private DMT_Opportunity_Business_Plan__c findGlobalRecord(List<DMT_Opportunity_Business_Plan__c> records) {
        if (records == null || records.isEmpty()) return null;
        for (DMT_Opportunity_Business_Plan__c rec : records) {
            if (rec.DMT_Booking_Geography__c == 'GLOBAL') return rec;
        }
        // Fallback: return the first record if no GLOBAL found
        return records[0];
    }
}