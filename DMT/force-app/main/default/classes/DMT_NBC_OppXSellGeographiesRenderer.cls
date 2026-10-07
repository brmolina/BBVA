public without sharing class DMT_NBC_OppXSellGeographiesRenderer implements DMT_ViewRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - the NO_XSELL_FIELDS/XSELL_FIELDS/summary fields below are the same
    // DMT_Opportunity_Business_Plan__c fields DMT_OppApprovalProcessDataRenderer already tracks
    // under 'Approval Process Data' (BP_ROW_FIELDS/BUSINESS_PLAN_GLOBAL_FIELDS) - declared again
    // here under this component's own name. DMT_Active__c is a genuinely new discriminator: a
    // geography's rows only render at all when isGeoActive() finds an active record for it, so
    // flipping that flag changes what's on screen even though it's never displayed by value.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        Set<String> fields = new Set<String>(NO_XSELL_FIELDS);
        fields.addAll(XSELL_FIELDS);
        fields.add('Current_FY_Total_X_Sell_amount__c');
        fields.add('Current_FY_Total_Non_X_Sell_amount__c');
        fields.add('Current_FY_Total_Revenues_amount__c');
        fields.add('Current_FY_Child_X_Sell_amount__c');
        fields.add('DMT_Xsell_Cost_to_Income__c');
        fields.add('DMT_Currency__c');
        fields.add('DMT_Booking_Geography__c');
        fields.add('DMT_Active__c');
        fields.add('DMT_Year__c');
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
                'NBC XSell Geographies', 'opportunityBusinessPlan', 'DMT_Opportunity_Business_Plan__c',
                'DMT_Opportunity__c', 'Id'
            )
        };
    }

    // ── No Cross Sell rows (6) ─────────────────────────────────────────────
    private static final List<String> NO_XSELL_LABELS = new List<String>{
        'Corp. Lending (Net of funding cost)',
        'Struct. Finance (Net of funding cost)',
        'Rates (Net of CVA)',
        'GTF (Net of funding cost)',
        'Working Capital (Net of funding cost)',
        'STF (Net of funding cost)'
    };
    private static final List<String> NO_XSELL_FIELDS = new List<String>{
        'Current_FY_Corp_Synd_Lending_amount__c',
        'Current_FY_Structured_Finance_amount__c',
        'Current_FY_Rates_amount__c',
        'Current_FY_GTF_amount__c',
        'Current_FY_Working_Capital_amount__c',
        'Current_FY_Str_Trade_Finance_amount__c'
    };

    // ── Cross Sell rows (8) ────────────────────────────────────────────────
    private static final List<String> XSELL_LABELS = new List<String>{
        'ECM', 'M&A', 'Security services', 'Client Resources',
        'DCM', 'FX / CCS', 'Cash Management', 'Credit / Equity'
    };
    private static final List<String> XSELL_FIELDS = new List<String>{
        'Current_FY_ECM_M_A_Amount__c',
        'Current_FY_M_A_amount__c',
        'Current_FY_Securities_Services_amount__c',
        'Current_FY_Client_Resources_amount__c',
        'Current_FY_DCM_amount__c',
        'Current_FY_FX_CCS_amount__c',
        'Current_FY_Cash_Management_amount__c',
        'Current_FY_Credit_Equity_amount__c'
    };

    // ── Styles ─────────────────────────────────────────────────────────────
    // Dark navy: table header row and GLOBAL country/divisa/summary-label cells
    private static final String HEADER_CELL       = 'padding: 6px 8px; background-color: #004481; color: white; font-weight: bold; text-align: center; border: 1px solid #d8dfe7;';
    private static final String DARK_CELL         = 'padding: 6px 8px; background-color: #004481; color: white; font-weight: bold; text-align: center; border: 1px solid #d8dfe7; vertical-align: middle;';
    private static final String TOTAL_LABEL       = 'padding: 6px 8px; background-color: #004481; color: white; font-weight: bold; text-align: center; border: 1px solid #d8dfe7; vertical-align: middle;';
    // Non-GLOBAL body: label cells (Xsell/No Xsell col and product col)
    private static final String LIGHT_CELL        = 'padding: 6px 8px; color: #004481; border: 1px solid #004481; vertical-align: middle;';
    // White value cells (non-GLOBAL rows and GLOBAL summary rows)
    private static final String VALUE_CELL        = 'padding: 6px 8px; color: #004481; border: 1px solid #004481; text-align: right;';
    // Light-grey label cells for non-GLOBAL body rows cols 1-3 (Country, Divisa, Xsell/No Xsell)
    private static final String NON_GLOBAL_GREY_CELL = 'padding: 6px 8px; background-color: #e0e0e0; color: #004481; font-weight: bold; text-align: center; border: 1px solid #9aaab8; vertical-align: middle;';
    // Light-blue label cells for GLOBAL body rows (No Cross Sell / Cross Sell section — cols 3 and 4 only; value cols stay white)
    private static final String GLOBAL_BODY_CELL  = 'padding: 6px 8px; background-color: #cce5ff; color: #004481; font-weight: bold; text-align: center; border: 1px solid #004481; vertical-align: middle;';
    // White value cells for GLOBAL summary rows (EXPECTED TOTAL, TOTAL REVENUES, etc.)
    private static final String GLOBAL_TOTAL_VALUE = 'padding: 6px 8px; background-color: white; color: #004481; font-weight: bold; border: 1px solid #004481; text-align: right;';

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null) {
            return '<div>Opportunity data not provided</div>';
        }
        try {
            Date referenceDate = (data.opportunity != null && data.opportunity.CloseDate != null)
                ? data.opportunity.CloseDate
                : Date.today();
            Integer month = referenceDate.month();
            Integer year = referenceDate.year();
            Integer baseYear = month >= 10 ? year - 1 : year - 2;
            List<Integer> years = new List<Integer>{
                baseYear,
                baseYear + 1,
                baseYear + 2,
                baseYear + 3,
                baseYear + 4
            };

            Map<String, List<DMT_Opportunity_Business_Plan__c>> byGeo = groupByGeography(data.businessPlanRecords);

            if (byGeo.isEmpty()) {
                return '<div><h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold;">Cross Selling</h2>'
                     + '<p style="color: #666;">No Business Plan records found.</p></div>';
            }

            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold;">Cross Selling</h2>'
                + '<table style="width:100%; border-collapse: collapse; table-layout: fixed; font-size: 8px;">'
                + renderTableHeader(years);

            // Non-GLOBAL geographies first (only if active)
            for (String geo : byGeo.keySet()) {
                if (geo == 'GLOBAL') continue;
                if (!isGeoActive(byGeo.get(geo))) continue;
                html += renderNonGlobalRows(geo, byGeo.get(geo), years, data.taxonomyH007BPMap);
            }

            // GLOBAL always last
            if (byGeo.containsKey('GLOBAL')) {
                html += renderGlobalRows(byGeo.get('GLOBAL'), years, data.taxonomyH007BPMap);
            }

            html += '</table></div>';
            return html;

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppXSellGeographies renderHtml: ' + e.getMessage() + ' line ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    // ── Header ────────────────────────────────────────────────────────────

    private String renderTableHeader(List<Integer> years) {
        String html = '<thead>'
            + '<tr>'
            + '<th rowspan="2" style="' + HEADER_CELL + ' width: 10%;">Country</th>'
            + '<th rowspan="2" style="' + HEADER_CELL + ' width: 8%;">Divisa</th>'
            + '<th rowspan="2" style="' + HEADER_CELL + ' width: 12%;">Xsell / No Xsell</th>'
            + '<th rowspan="2" style="' + HEADER_CELL + ' width: 24%;">Product</th>';

        for (Integer yr : years) {
            html += '<th style="' + HEADER_CELL + '">' + yr + '</th>';
        }
        html += '</tr>';//<tr>
/*         for (Integer i = 0; i < years.size(); i++) {
            html += '<th style="' + HEADER_CELL + '">Incomes</th>';
        } */
        html += '</thead>';//</tr>
        return html;
    }

    // ── Non-GLOBAL geography block (15 rows) ──────────────────────────────

    private String renderNonGlobalRows(String geoCode, List<DMT_Opportunity_Business_Plan__c> records, List<Integer> years, Map<String, String> taxonomyMap) {
        String geoLabel    = resolveLabel(geoCode, taxonomyMap);
        String currencyCode = getCurrency(records);
        Map<Integer, DMT_Opportunity_Business_Plan__c> byYear = buildYearMap(records);

        String html = '<tbody style="page-break-inside: avoid;">';
        Integer totalRows = NO_XSELL_LABELS.size() + XSELL_LABELS.size() + 1; // 15

        // ── No Cross Sell rows (6) ──
        for (Integer i = 0; i < NO_XSELL_LABELS.size(); i++) {
            html += '<tr>';
            if (i == 0) {
                html += '<td rowspan="' + totalRows + '" style="' + NON_GLOBAL_GREY_CELL + '">' + geoLabel + '</td>'
                      + '<td rowspan="' + totalRows + '" style="' + NON_GLOBAL_GREY_CELL + '">' + currencyCode + '</td>'
                      + '<td rowspan="' + NO_XSELL_LABELS.size() + '" style="' + NON_GLOBAL_GREY_CELL + '">No Cross Sell</td>';
            }
            html += '<td style="' + LIGHT_CELL + '">' + NO_XSELL_LABELS[i] + '</td>';
            html += yearValueCells(byYear, years, NO_XSELL_FIELDS[i], VALUE_CELL);
            html += '</tr>';
        }

        // ── Cross Sell rows (8) + SUBTOTAL (1) = 9 ──
        Integer xSellRowspan = XSELL_LABELS.size() + 1; // 9
        for (Integer i = 0; i < XSELL_LABELS.size(); i++) {
            html += '<tr>';
            if (i == 0) {
                html += '<td rowspan="' + xSellRowspan + '" style="' + NON_GLOBAL_GREY_CELL + '">Cross Sell</td>';
            }
            html += '<td style="' + LIGHT_CELL + '">' + XSELL_LABELS[i] + '</td>';
            html += yearValueCells(byYear, years, XSELL_FIELDS[i], VALUE_CELL);
            html += '</tr>';
        }

        // ── SUBTOTAL (white value cells matching the rest of the non-GLOBAL block) ──
        html += '<tr>'
            + '<td style="' + LIGHT_CELL + ' font-weight: bold;">SUBTOTAL</td>'
            + yearValueCells(byYear, years, 'Current_FY_Total_X_Sell_amount__c', VALUE_CELL)
            + '</tr>';

        html += '</tbody>';
        return html;
    }

    // ── GLOBAL block (19 rows) ────────────────────────────────────────────

    private String renderGlobalRows(List<DMT_Opportunity_Business_Plan__c> records, List<Integer> years, Map<String, String> taxonomyMap) {
        String geoLabel    = resolveLabel('GLOBAL', taxonomyMap);
        String currencyCode = getCurrency(records);
        Map<Integer, DMT_Opportunity_Business_Plan__c> byYear = buildYearMap(records);

        // DMT_Xsell_Cost_to_Income__c is a per-BP scalar (not year-columnar); take first non-null value
        Decimal xsellCti = null;
        for (DMT_Opportunity_Business_Plan__c rec : records) {
            if (rec.DMT_Xsell_Cost_to_Income__c != null) { xsellCti = rec.DMT_Xsell_Cost_to_Income__c; break; }
        }

        Integer totalRows = NO_XSELL_LABELS.size() + XSELL_LABELS.size() + 5; // 19

        String html = '<tbody style="page-break-inside: avoid;">';

        // ── No Cross Sell rows (6) — light-blue body cells ──
        for (Integer i = 0; i < NO_XSELL_LABELS.size(); i++) {
            html += '<tr>';
            if (i == 0) {
                html += '<td rowspan="' + totalRows + '" style="' + DARK_CELL + '">' + geoLabel + '</td>'
                      + '<td rowspan="' + totalRows + '" style="' + DARK_CELL + '">' + currencyCode + '</td>'
                      + '<td rowspan="' + NO_XSELL_LABELS.size() + '" style="' + GLOBAL_BODY_CELL + '">No Cross Sell</td>';
            }
            html += '<td style="' + GLOBAL_BODY_CELL + '">' + NO_XSELL_LABELS[i] + '</td>';
            html += yearValueCells(byYear, years, NO_XSELL_FIELDS[i], VALUE_CELL);
            html += '</tr>';
        }

        // ── Cross Sell rows (8) — light-blue body cells ──
        for (Integer i = 0; i < XSELL_LABELS.size(); i++) {
            html += '<tr>';
            if (i == 0) {
                html += '<td rowspan="' + XSELL_LABELS.size() + '" style="' + GLOBAL_BODY_CELL + '">Cross Sell</td>';
            }
            html += '<td style="' + GLOBAL_BODY_CELL + '">' + XSELL_LABELS[i] + '</td>';
            html += yearValueCells(byYear, years, XSELL_FIELDS[i], VALUE_CELL);
            html += '</tr>';
        }

        // ── EXPECTED TOTAL NO XSELL (row 15) ──
        html += '<tr>'
            + '<td style="' + TOTAL_LABEL + '">No Cross Sell</td>'
            + '<td style="' + TOTAL_LABEL + '">EXPECTED TOTAL NO XSELL</td>'
            + yearValueCells(byYear, years, 'Current_FY_Total_Non_X_Sell_amount__c', GLOBAL_TOTAL_VALUE)
            + '</tr>';

        // ── EXPECTED TOTAL XSELL (row 16) ──
        html += '<tr>'
            + '<td style="' + TOTAL_LABEL + '">Cross Sell</td>'
            + '<td style="' + TOTAL_LABEL + '">EXPECTED TOTAL XSELL</td>'
            + yearValueCells(byYear, years, 'Current_FY_Total_X_Sell_amount__c', GLOBAL_TOTAL_VALUE)
            + '</tr>';

        // ── TOTAL REVENUES (row 17, cols 3+4 merged) ──
        html += '<tr>'
            + '<td colspan="2" style="' + TOTAL_LABEL + '">TOTAL REVENUES</td>'
            + yearValueCells(byYear, years, 'Current_FY_Total_Revenues_amount__c', GLOBAL_TOTAL_VALUE)
            + '</tr>';

        // ── EXPECTED XSELL OPEX EUR (row 18, cols 3+4 merged) ──
        html += '<tr>'
            + '<td colspan="2" style="' + TOTAL_LABEL + '">EXPECTED XSELL OPEX (EUR)</td>'
            + yearValueCells(byYear, years, 'Current_FY_Child_X_Sell_amount__c', GLOBAL_TOTAL_VALUE)
            + '</tr>';

        // ── GLOBAL NET INCOME (row 19, cols 3+4 merged) ──
        // IF TEMPORARY: business requested Xsell Cost to Income in col 1 only, other cols blank.
        // IF To revert: replace globalNetIncomeFirstColOnly(xsellCti, years) with globalNetIncomeValueCells(byYear, years)
        html += '<tr>'
            + '<td colspan="2" style="' + TOTAL_LABEL + '">GLOBAL NET INCOME</td>'
            + globalNetIncomeFirstColOnly(xsellCti, years)
            + '</tr>';

        html += '</tbody>';
        return html;
    }

    // ====================================================================================================
    // HELPERS
    // ====================================================================================================

    private Map<String, List<DMT_Opportunity_Business_Plan__c>> groupByGeography(List<DMT_Opportunity_Business_Plan__c> records) {
        Map<String, List<DMT_Opportunity_Business_Plan__c>> result = new Map<String, List<DMT_Opportunity_Business_Plan__c>>();
        if (records == null || records.isEmpty()) return result;
        for (DMT_Opportunity_Business_Plan__c rec : records) {
            String geo = String.isBlank(rec.DMT_Booking_Geography__c) ? 'GLOBAL' : rec.DMT_Booking_Geography__c;
            if (!result.containsKey(geo)) result.put(geo, new List<DMT_Opportunity_Business_Plan__c>());
            result.get(geo).add(rec);
        }
        return result;
    }

    private Boolean isGeoActive(List<DMT_Opportunity_Business_Plan__c> records) {
        for (DMT_Opportunity_Business_Plan__c rec : records) {
            if (rec.DMT_Active__c == true) return true;
        }
        return false;
    }

    private Map<Integer, DMT_Opportunity_Business_Plan__c> buildYearMap(List<DMT_Opportunity_Business_Plan__c> records) {
        Map<Integer, DMT_Opportunity_Business_Plan__c> result = new Map<Integer, DMT_Opportunity_Business_Plan__c>();
        for (DMT_Opportunity_Business_Plan__c rec : records) {
            if (rec.DMT_Year__c != null) {
                result.put(Integer.valueOf(rec.DMT_Year__c), rec);
            }
        }
        return result;
    }

    private String resolveLabel(String geoCode, Map<String, String> taxonomyMap) {
        return (taxonomyMap != null && taxonomyMap.containsKey(geoCode)) ? taxonomyMap.get(geoCode) : geoCode;
    }

    private String getCurrency(List<DMT_Opportunity_Business_Plan__c> records) {
        return records.isEmpty() ? '' : DMT_FormattingUtils.checkNull(records[0].DMT_Currency__c);
    }

    private String yearValueCells(Map<Integer, DMT_Opportunity_Business_Plan__c> byYear, List<Integer> years, String field, String cellStyle) {
        String html = '';
        for (Integer yr : years) {
            DMT_Opportunity_Business_Plan__c rec = byYear.get(yr);
            Object val = (rec != null) ? rec.get(field) : null;
            html += '<td style="' + cellStyle + '">' + DMT_FormattingUtils.formatDecimalEs(DMT_FormattingUtils.checkNull(val), 2) + '</td>';
        }
        return html;
    }

    // IF TEMPORARY: business requested Xsell Cost to Income (DMT_Xsell_Cost_to_Income__c from oppClient)
    // in the first column only; remaining columns are blank. Revert by swapping the call site back to
    // globalNetIncomeValueCells (commented below) once the correct formula is confirmed.
    private String globalNetIncomeFirstColOnly(Decimal xsellCti, List<Integer> years) {
        String html = '';
        for (Integer i = 0; i < years.size(); i++) {
            String cellValue = (i == 0) ? DMT_FormattingUtils.formatDecimalEs(DMT_FormattingUtils.checkNull(xsellCti), 2) : '';
            html += '<td style="' + GLOBAL_TOTAL_VALUE + '">' + cellValue + '</td>';
        }
        return html;
    }

    // ====================================================================================================
    // !! RESERVED — GLOBAL NET INCOME original formula (commented out 2026-07-07 per business request) !!
    // Formula: TOTAL REVENUES - EXPECTED XSELL OPEX (EUR)
    //   → Current_FY_Total_Revenues_amount__c - Current_FY_Child_X_Sell_amount__c
    // IF To revert: uncomment this method and replace globalNetIncomeFirstColOnly(xsellCti, years)
    // with globalNetIncomeValueCells(byYear, years) in renderGlobalRows.
    // ====================================================================================================
    // private String globalNetIncomeValueCells(Map<Integer, DMT_Opportunity_Business_Plan__c> byYear, List<Integer> years) {
    //     String html = '';
    //     for (Integer yr : years) {
    //         DMT_Opportunity_Business_Plan__c rec = byYear.get(yr);
    //         String cellValue;
    //         if (rec != null) {
    //             Decimal revenues = rec.Current_FY_Total_Revenues_amount__c != null ? rec.Current_FY_Total_Revenues_amount__c : 0;
    //             Decimal opex     = rec.Current_FY_Child_X_Sell_amount__c   != null ? rec.Current_FY_Child_X_Sell_amount__c   : 0;
    //             cellValue = DMT_FormattingUtils.formatDecimalEs(DMT_FormattingUtils.checkNull(revenues - opex), 2);
    //         } else {
    //             cellValue = DMT_FormattingUtils.checkNull(null);
    //         }
    //         html += '<td style="' + GLOBAL_TOTAL_VALUE + '">' + cellValue + '</td>';
    //     }
    //     return html;
    // }

    /* public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        return new Map<String, Object>();
    } */
}