public without sharing class DMT_NBC_OppBusinessPlanDataRenderer implements DMT_ViewRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - every field this renderer itself reads: ROW_FIELDS is exactly what
    // renderHtmlGeographyTable() displays per row (X_SELL_FIELDS, used for the computed "Total
    // X-Sell" row, is already a subset of ROW_FIELDS), and DMT_BusinessPlanGlobalAggregator's
    // aggregation reads nothing outside DMT_Year__c/DMT_Booking_Geography__c/ROW_FIELDS either - so
    // this is self-contained and correct even on a view where no other component happens to read the
    // same object. Year/Geography are added as discriminators for a separate reason: the GLOBAL row
    // is computed live by aggregating every non-GLOBAL row, so any row moving year/geography changes
    // the aggregate even when none of the amount fields themselves change.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        Set<String> fields = new Set<String>(ROW_FIELDS);
        fields.add('DMT_Year__c');
        fields.add('DMT_Booking_Geography__c');
        return new Map<String, List<String>>{
            'DMT_Opportunity_Business_Plan__c' => new List<String>(fields)
        };
    }

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
                'NBC Business Plan Data', 'opportunityBusinessPlan', 'DMT_Opportunity_Business_Plan__c',
                'DMT_Opportunity__c', 'Id'
            )
        };
    }

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
    
    private static final Set<String> AMOUNT_FIELDS = new Set<String>{
        'Current_FY_Corp_Synd_Lending_amount__c', 'Current_FY_Structured_Finance_amount__c', 'Current_FY_Str_Trade_Finance_amount__c',
        'Current_FY_Rates_amount__c', 'Current_FY_GTF_amount__c', 'Current_FY_Working_Capital_amount__c', 'Current_FY_Total_Non_X_Sell_amount__c',
        'Current_FY_ECM_M_A_Amount__c', 'Current_FY_M_A_amount__c', 'Current_FY_DCM_amount__c', 'Current_FY_Credit_Equity_amount__c',
        'Current_FY_FX_CCS_amount__c', 'Current_FY_Cash_Management_amount__c', 'Current_FY_Client_Resources_amount__c',
        'Current_FY_Securities_Services_amount__c', 'Current_FY_Total_X_Sell_amount__c', 'Current_FY_Total_Revenues_amount__c'
    };

    private static final Decimal THOUSAND = 1000;

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Opportunity data not provided</div>';
        }
            
        try {
            // Use CloseDate if the opportunity is available, otherwise use today's date
            Date referenceDate = (data.opportunity != null && data.opportunity.CloseDate != null)
                ? data.opportunity.CloseDate
                : Date.today();
            
            Integer baseYear = getBaseFinancialYear(referenceDate);

            String html = '<div style="font-family: Arial, sans-serif; margin-bottom: 20px;">'// page-break-inside: avoid;
                        + '<h2 style="font-size: 10px; color: #004481; margin-bottom: -2px; font-weight: bold; text-transform: uppercase;">CLIENT RELATIONSHIP*</h2>'
                        
                        + '<div style="margin-bottom: -1px;">'
                        + '<span style="color: #004481; font-weight: bold; font-size: 10px;">Business Plan </span>'
                        + '<span style="color: #888888; font-style: italic; font-size: 8px;">(Figures in Thousands Eur)</span>'
                        + '</div>';
            
            // GLOBAL is always computed live as the sum of all non-GLOBAL geography records,
            // mirroring dmt_business_plan_table_geography.js's _buildGlobalAggregatedRows().
            // The persisted GLOBAL record is never read here: it's only kept in sync when a user
            // saves through that LWC, so trusting it directly can show stale/divergent totals.
            List<DMT_Opportunity_Business_Plan__c> aggregatedGlobal = DMT_BusinessPlanGlobalAggregator.buildAggregatedGlobalRecords(data.businessPlanRecords, ROW_FIELDS);
            if (!aggregatedGlobal.isEmpty()) {
                System.debug('Rendering GLOBAL table aggregated from ' + aggregatedGlobal.size() + ' year(s) of non-GLOBAL geography data.');
                html += renderHtmlGeographyTable('GLOBAL', aggregatedGlobal, baseYear, data.taxonomyH007BPMap);
            }

            html += '</div>';

            //html += buildHtmlXSell(data, CURRENT_YEAR);

            return html;
            
        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppBusinessPlanDataRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    /**
     * Calcula el año base de la tabla financiera basado en la fecha de referencia.
     * Lógica: si mes >= 10 (oct+) → año - 1; si mes < 10 → año - 2
     * Replicates dmt_business_plan_table_geography.js::_getBaseFinancialYear()
     * NOTE: En Apex los meses son 1-12 (enero=1, octubre=10), mientras que en JS son 0-11 (enero=0, octubre=9)
     * Por eso usamos >= 10 aquí (equivalente a >= 9 en JavaScript)
     */
    private Integer getBaseFinancialYear(Date referenceDate) {
        if (referenceDate == null) {
            referenceDate = Date.today();
        }
        Integer month = referenceDate.month(); // 1-12 en Apex
        Integer year = referenceDate.year();
        return month >= 10 ? year - 1 : year - 2;
    }

    private String renderHtmlGeographyTable(String geoCode, List<DMT_Opportunity_Business_Plan__c> records, Integer baseYear, Map<String, String> taxonomyH007Map) {
        String geoLabel = (taxonomyH007Map != null && taxonomyH007Map.containsKey(geoCode))
            ? taxonomyH007Map.get(geoCode)
            : geoCode;

        Map<Integer, DMT_Opportunity_Business_Plan__c> recordByYear = new Map<Integer, DMT_Opportunity_Business_Plan__c>();
        for (DMT_Opportunity_Business_Plan__c rec : records) {
            if (rec.DMT_Year__c != null) {
                recordByYear.put(Integer.valueOf(rec.DMT_Year__c), rec);
            }
        }
        List<Integer> years = new List<Integer>{baseYear, baseYear + 1, baseYear + 2, baseYear + 3, baseYear + 4};

        String html = '<table style="width:70%; border-collapse: collapse; table-layout: fixed; margin: 0 auto 8px auto;">'
            + '<colgroup><col style="width: 30%;"><col style="width: 14%;"><col style="width: 14%;"><col style="width: 14%;"><col style="width: 14%;"><col style="width: 14%;"></colgroup>'
            + '<tr>'
            + '<td colspan="6" style="padding: 4px 6px; background-color: #004481; color: #ffffff; font-size: 8px; color: #ffffff;"><strong style=" color: #ffffff;">Business Plan - ' + geoLabel + '</strong></td>'
            + '</tr>'
            + '<tr>'
            + '<td style="padding: 4px 6px; border: none;"></td>'
            + '<td style="padding: 4px 6px; text-align: center; border-bottom: 1px solid #004481; color: #004481;"><strong style="font-size: 8px;">FY' + baseYear + '</strong></td>'
            + '<td style="padding: 4px 6px; text-align: center; border-bottom: 1px solid #004481; color: #004481;"><strong style="font-size: 8px;">FY' + (baseYear + 1) + '</strong></td>'
            + '<td style="padding: 4px 6px; text-align: center; border-bottom: 1px solid #004481; color: #004481;"><strong style="font-size: 8px;">FY' + (baseYear + 2) + '</strong></td>'
            + '<td style="padding: 4px 6px; text-align: center; border-bottom: 1px solid #004481; color: #004481;"><strong style="font-size: 8px;">FY' + (baseYear + 3) + '</strong></td>'
            + '<td style="padding: 4px 6px; text-align: center; border-bottom: 1px solid #004481; color: #004481;"><strong style="font-size: 8px;">FY' + (baseYear + 4) + '</strong></td>'
            + '</tr>';

        for (Integer i = 0; i < ROW_LABELS.size(); i++) {
            String label = ROW_LABELS[i];
            String apiField = ROW_FIELDS[i];
            Boolean isTotalRow = TOTAL_ROWS.contains(label);

            html += '<tr>';

            if (isTotalRow) {
                String totalCellStyle = 'padding: 4px 6px; background-color: #004481; color: #ffffff; border: 1px solid #004481; font-size: 7px;';
                html += '<td style="' + totalCellStyle + '">' + label + '</td>';
                for (Integer yr : years) {
                    DMT_Opportunity_Business_Plan__c rec = recordByYear.get(yr);
                    // "Total X-Sell" is always recomputed live from its component rows, never read
                    // from the stored field, matching transformApexData() in the LWC.
                    Object val = (rec == null) ? null
                        : (label == 'Total X-Sell') ? DMT_BusinessPlanGlobalAggregator.computeXSellTotal(rec, X_SELL_FIELDS)
                        : rec.get(apiField);
                    html += '<td style="' + totalCellStyle + ' text-align: right;">' + DMT_FormattingUtils.formatDecimalEs(toThousands(apiField, val), 2) + '</td>';
                }
            } else {
                String labelCellStyle = 'padding: 4px 6px; background-color: #00a99d; color: #ffffff; border-bottom: 1px solid #ffffff; font-size: 7px;';
                String valueCellStyle = 'padding: 4px 6px; background-color: #ffffff; color: #004481; text-align: right; border: 1px solid #004481; font-size: 7px;';
                html += '<td style="' + labelCellStyle + '">' + label + '</td>';
                for (Integer yr : years) {
                    DMT_Opportunity_Business_Plan__c rec = recordByYear.get(yr);
                    Object val = (rec != null) ? rec.get(apiField) : null;
                    html += '<td style="' + valueCellStyle + '">' + DMT_FormattingUtils.formatDecimalEs(toThousands(apiField, val), 2) + '</td>';
                }
            }

            html += '</tr>';
        }

        html += '</table>';
        return html;
    }

/*     private String buildHtmlXSell(DMT_ViewController.LineDataWrapper data, Integer CURRENT_YEAR) {
        if (data.xSellOpp.isEmpty()) return '';

        String html = '<div>'
            + '<h3 style="font-size: 13px; color: #004481; margin-bottom: 8px;">Cross SELL</h3>'
            + '<table style="width:100%; border-collapse: collapse;">'
            + '<tr style="page-break-inside: avoid;">'
            + '<td style="padding: 6px; border-bottom: 1px solid #004481; color: #004481;"></td>'
            + '<td style="padding: 6px; border-bottom: 1px solid #004481; color: #004481; text-align: center;"><strong>FY'+(CURRENT_YEAR - 1)+'</strong></td>'
            + '<td style="padding: 6px; border-bottom: 1px solid #004481; color: #004481; text-align: center;"><strong>FY'+CURRENT_YEAR+'E</strong></td>'
            + '<td style="padding: 6px; border-bottom: 1px solid #004481; color: #004481; text-align: center;"><strong>FY'+(CURRENT_YEAR + 1)+'E</strong></td>'
            + '<td style="padding: 6px; border-bottom: 1px solid #004481; color: #004481; text-align: center;"><strong>FY'+(CURRENT_YEAR + 2)+'E</strong></td>'
            + '</tr>';

        for(DMT_X_Sell__c xs : data.xSellOpp){
            String geoLabel = data.taxonomyH007Map.containsKey(xs.Booking_Geography__c) ? data.taxonomyH007Map.get(xs.Booking_Geography__c) : DMT_FormattingUtils.checkNull(xs.Booking_Geography__c);
            
            html += '<tr>'
                + '<td style="padding: 6px; border: 1px solid #004481; color: #004481;">' + geoLabel + '</td>'
                + '<td style="padding: 6px; border: 1px solid #004481; color: #004481; text-align: center;">' + valueOrNA(xs.XSELL_Value_PY__c) + '</td>'
                + '<td style="padding: 6px; border: 1px solid #004481; color: #004481; text-align: center;">' + valueOrNA(xs.XSELL_Value_CY__c) + '</td>'
                + '<td style="padding: 6px; border: 1px solid #004481; color: #004481; text-align: center;">' + valueOrNA(xs.XSELL_Value_NY__c) + '</td>'
                + '<td style="padding: 6px; border: 1px solid #004481; color: #004481; text-align: center;">' + valueOrNA(xs.XSELL_Value_NY1__c) + '</td>'
                + '</tr>';
        }
        
        html += '</table></div>';
        return html;
    } */

    private static String valueOrNA(Object value) {
        String formattedValue = DMT_FormattingUtils.checkNull(value);
        return String.isBlank(formattedValue) ? '' : formattedValue;
    }

    private static String valueOrNAFromText(String value) {
        return String.isBlank(value) ? '' : value;
    }

    // Real amount (DB) -> thousands (view). Non-amount fields and nulls are returned unchanged.
    private static Object toThousands(String apiField, Object value) {
        if (value == null || !AMOUNT_FIELDS.contains(apiField)) {
            return value;
        }
        return Decimal.valueOf(String.valueOf(value)) / THOUSAND;
    }
}