public without sharing class DMT_OppProfitabilityRenderer implements DMT_ViewRenderer {

    private static final String CELL_STYLE = 'padding: 8px; border-bottom: 1px solid #ccc; word-break:break-word; font-size: 6px';
    private static final String HEADER_CELL_STYLE = 'padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3; word-break:normal; font-size: 6px';
    // ID cells break anywhere so long Salesforce Ids do not overlap the next column in the PDF.
    private static final String ID_CELL_STYLE = 'border-bottom: 1px solid #ccc; word-wrap:break-word; word-break:break-all; font-size: 6px';
    private static final String EMPTY_VALUE = '—';

    /**
     * CIBGLOBALD-4713 - One table row, with the same data, deduplication, order and formats as the former
     * Profitability modal (dmt_profitability_chart: normalizeProfitabilityResults, processProfitabilityData,
     * buildOrderedRows), which is the reference for this renderer.
     */
    private class ProfitabilityRow {
        Map<String, Object> result;
        Boolean isOpportunity = false;
        String productId;
        String underlyingId;
        Integer sourceIndex;
        Integer underlyingOrderIndex;
        String id = '';
        String initialDate = EMPTY_VALUE;
        String maturityDate = EMPTY_VALUE;
        String rowCurrency = '';
        String amountCurrency = '';
        String nominalDb = EMPTY_VALUE;
        String nominalFb = EMPTY_VALUE;
        Decimal nominalDbValue;
        Decimal nominalFbValue;
    }

    /**
     * Renders HTML for the Opportunity Profitability feature.
     * @param data The LineDataWrapper containing featuresList.
     * @return HTML string for rendering in the UI.
     */
    public static String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.featuresList == null || data.featuresList.isEmpty()) {
            return '<div>Features data not provided.</div>';
        }
        if (data.opportunity.getPopulatedFieldsAsMap().isEmpty() || data.opportunity.OpportunityLineItems.isEmpty()) {
            return '<div>Opportunity or OpportunityLineItems data not provided.</div>';
        }
        Map<String, Object> feature = getProfitabilityFeature(data.featuresList);
        if (feature.isEmpty() || !feature.containsKey('profitability')) {
            return '<div>Profitability data not provided.</div>';
        }
        Map<String, Object> profitability = (Map<String, Object>)feature.get('profitability');
        List<Object> results = (List<Object>)profitability.get('results');
        Map<String, Object> audit = profitability.containsKey('audit') && profitability.get('audit') != null ? (Map<String, Object>) profitability.get('audit') : new Map<String, Object>();

        if (results == null || results.isEmpty()) {
            return '<div class="error-message">no Profitability results found.</div>';
        }
        try {
            List<ProfitabilityRow> rows = buildRows(results, data);
            // CIBGLOBALD-4713 - 'External RWA 1Y' column only when the Profitability modal requested the
            // External RWA service and it returned values (same rule as the former modal code).
            Boolean showExternalRwa = data.profitabilityAprsByProductId != null && !data.profitabilityAprsByProductId.isEmpty();

            String html = '';
            html += '<div>' + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Profitability Engine</h2>' + '<div class="slds-scope">';
            html += renderHeaderMetrics(results, audit);

            html += '<div>'
                + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Summary</h3>'
                + '<div data-dmt-table-block="summary" style="width:100%;">'
                + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout:fixed; word-break:break-word;">'
                + renderHeaderRow(new List<String>{
                    'ID', 'Initial Date', 'Maturity Date', 'Average Life', 'Tenor', 'Allin Drawn', 'Allin Undrawn',
                    'Spread Drawn', 'Spread Undrawn', 'Fees Drawn', 'Fees Undrawn', 'FC Drawn', 'FC Undrawn',
                    'Country Risk Drawn', 'Country Risk Undrawn', 'Expected Loss', 'Tax Rate', 'FD', 'Incomes 12 months'
                });
            for (ProfitabilityRow row : rows) {
                Map<String, Object> r = row.result;
                html += renderRow(row, new List<String>{
                    row.initialDate,
                    row.maturityDate,
                    formatYears(r.get('averageLife')),
                    formatYears(r.get('term')),
                    formatBps(r.get('allInDb')),
                    formatBps(r.get('allInFb')),
                    formatBps(r.get('spreadDbPbs')),
                    formatBps(r.get('spreadFbPbs')),
                    formatBps(r.get('feesDbPbs')),
                    formatBps(r.get('feesFbPbs')),
                    formatBps(r.get('fundingDbPbs')),
                    formatBps(r.get('fundingFbPbs')),
                    formatBps(r.get('countryRiskProvisionDbPbs')),
                    formatBps(r.get('countryRiskProvisionFbPbs')),
                    formatBps(r.get('expectedLossPbs')),
                    formatPercentOfWhole(r.get('taxRate')),
                    formatThousands(isTruthy(r.get('franchiseDeal')) ? r.get('franchiseDeal') : 0) + ' ' + row.amountCurrency,
                    formatAmountWithCurrencyMax2(r.get('incomes12Months'), row.amountCurrency)
                });
            }
            html += '</table></div>'
                + '&nbsp;</br>'
                + getExternalRwaActionMarker(data)
                + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Regulatory Capital</h3>'
                + '<div data-dmt-table-block="regulatory" style="width:100%;">'
                + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout:fixed; word-break:break-word;">';
            List<String> regulatoryHeaders = new List<String>{ 'ID', 'Notional Drawn', 'Notional Undrawn', 'EAD reg', 'CCF reg', 'LGD reg', 'NetIncome Reg', 'RWA reg' };
            if (showExternalRwa) {
                regulatoryHeaders.add('External RWA 1Y');
            }
            regulatoryHeaders.addAll(new List<String>{ 'Regulatory Capital', 'RORC CDD', 'RORC' });
            html += renderHeaderRow(regulatoryHeaders);
            for (ProfitabilityRow row : rows) {
                Map<String, Object> r = row.result;
                List<String> cells = new List<String>{
                    row.nominalDb,
                    row.nominalFb,
                    formatThousands(r.get('regulatoryEad')) + ' ' + row.amountCurrency,
                    formatPercentOfWhole(r.get('regulatoryCcf')),
                    formatPercentOfWhole(r.get('regulatoryLgd')),
                    formatAmountWithCurrencyMax2(firstValue(r, 'BDIReg', 'bdiReg'), row.amountCurrency),
                    formatAmountWithCurrency(r.get('regulatoryApr'), row.amountCurrency)
                };
                if (showExternalRwa) {
                    cells.add(getExternalRwaCell(row, data));
                }
                cells.addAll(new List<String>{
                    formatAmountWithCurrency(r.get('regulatoryCapital'), row.amountCurrency),
                    formatPercent(r.get('rorcProspected')),
                    formatPercent(r.get('rorc'))
                });
                html += renderRow(row, cells);
            }
            html += '</table></div>'
                + '&nbsp;</br>'
                + '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Economic Capital</h3>'
                + '<div data-dmt-table-block="economic" style="width:100%;">'
                + '<table class="style-table" style="width:100%; border-collapse: collapse; table-layout:fixed; word-break:break-word;">'
                + renderHeaderRow(new List<String>{
                    'ID', 'Notional Drawn', 'Notional Undrawn', 'EAD eco', 'CCF eco', 'LGD eco', 'NetIncome Eco', 'RWA eco', 'Economic Capital', 'RAROEC'
                });
            for (ProfitabilityRow row : rows) {
                Map<String, Object> r = row.result;
                html += renderRow(row, new List<String>{
                    row.nominalDb,
                    row.nominalFb,
                    formatThousands(r.get('economicEad')) + ' ' + row.amountCurrency,
                    formatPercentOfWhole(r.get('economicCcf')),
                    formatPercentOfWhole(r.get('economicLgd')),
                    formatAmountWithCurrencyMax2(firstValue(r, 'BDIEco', 'bdiEco'), row.amountCurrency),
                    formatAmountWithCurrency(r.get('economicApr'), row.amountCurrency),
                    formatAmountWithCurrency(r.get('economicCapital'), row.amountCurrency),
                    formatPercent(r.get('raroec'))
                });
            }
            html += '</table></div>'
                + '&nbsp;</br>'
                + '</div>'
                + '</div>';

            Boolean hasProfitabilityVisual = false;
            if (data.isImg64 == true && !data.itemImgBase64.isEmpty() && data.itemImgBase64.size() > 0) {
                Integer j = data.itemImgBase64.size() <= 3 ? 0 : -1;
                if (j >= 0 && j < data.itemImgBase64.size()) {
                    String raw = normalizeImageBase64(data.itemImgBase64[j]?.imgB64);
                    String dataUri = toImageDataUri(raw);
                    if (String.isNotBlank(dataUri)) {
                        html += '<div style="margin-top: 24px;">'
                            + '<img alt="profitability" src="' + DMT_FormattingUtils.checkNull(dataUri) + '" style="width:100%;height:100%;object-fit:contain;"/>'
                            + '</div>';
                        hasProfitabilityVisual = true;
                    }
                }
            }

            if (!hasProfitabilityVisual) {
                DMT_ProfitabilityChartGenerator.ChartRequest profitabilityChartRequest =
                    DMT_ProfitabilityChartGenerator.buildChartRequest(profitability);
                String profitabilityChartHtml = DMT_ProfitabilityChartGenerator.getMixedChartHtml(profitabilityChartRequest);
                if (String.isNotBlank(profitabilityChartHtml)) {
                    html += '<div style="margin-top:24px; page-break-before:always; break-before:page; page-break-inside:avoid; break-inside:avoid;">' + profitabilityChartHtml + '</div>';
                }
            }

            return html;
        } catch (Exception e){
            System.debug('Error in DMT_OppProfitabilityRenderer renderHtml, '+ e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: '+e.getMessage()+' - '+e.getLineNumber()+'</div>';
        }
    }

    // CIBGLOBALD-4713 - Deal RORC / RAROEC lifetime lines as in the former modal: '>' only when the value is above the threshold.
    private static String renderHeaderMetrics(List<Object> results, Map<String, Object> audit) {
        Map<String, Object> summary = new Map<String, Object>();
        for (Object rec : results) {
            Map<String, Object> mapRec = (Map<String, Object>) rec;
            if (!isTruthy(mapRec.get('productId'))) {
                summary = mapRec;
                break;
            }
        }
        return '<div class="slds-m-vertical_medium">'
            + '<div class="slds-grid slds-wrap slds-m-top_small" style="font-size: 14px;">'
            + '<div class="slds-col slds-size_1-of-2 slds-p-bottom_small">'
            + '<strong>Deal RORC lifetime:</strong> ' + formatProfitabilityMetric(summary.get('rorc'), audit.get('rorcThreshold'))
            + '</div>'
            + '<div class="slds-col slds-size_1-of-2 slds-p-bottom_small">'
            + '<strong>Deal RAROEC lifetime:</strong> ' + formatProfitabilityMetric(summary.get('raroec'), audit.get('raroecThreshold'))
            + '</div>'
            + '<div class="slds-col slds-size_1-of-2 slds-p-bottom_small">'
            + '<strong>RORC Prospective CDD:</strong> ' + formatPercent(summary.get('rorcProspected'))
            + '</div>'
            + '<div class="slds-col slds-size_1-of-2 slds-p-bottom_small">'
            + '<strong>Global Expected RORC:</strong> ' + formatPercent(summary.get('clientRorc'))
            + '</div>'
            + '</div>'
            + '</div>';
    }

    private static String renderHeaderRow(List<String> labels) {
        String html = '<tr>';
        for (Integer i = 0; i < labels.size(); i++) {
            String width = i == 0 ? ' width: 14%;' : '';
            html += '<td style="' + HEADER_CELL_STYLE + ';' + width + '"><strong>' + labels[i] + '</strong></td>';
        }
        return html + '</tr>';
    }

    // CIBGLOBALD-4713 - data-dmt-row marks the Opportunity and underlying rows so the modal can apply the original row styles.
    private static String renderRow(ProfitabilityRow row, List<String> cells) {
        String rowType = row.isOpportunity ? 'opportunity' : (row.underlyingId != null ? 'underlying' : 'product');
        String rowStyle = row.isOpportunity ? 'background-color:#e6f0fa;' : '';
        String indent = row.underlyingId != null ? 'padding-left: 20px; ' : '';
        String html = '<tr data-dmt-row="' + rowType + '" style="' + rowStyle + '">'
            + '<td style="padding: 8px; ' + indent + ID_CELL_STYLE + '">' + DMT_FormattingUtils.checkNull(row.id) + '</td>';
        for (String cell : cells) {
            html += '<td style="' + CELL_STYLE + '">' + DMT_FormattingUtils.checkNull(cell) + '</td>';
        }
        return html + '</tr>';
    }

    /**
     * CIBGLOBALD-4713 - Builds the rows exactly like the former modal: keeps the first Opportunity row, the first
     * row per underlyingId and one row per productId (a later isLine row wins), computes dates, currencies and
     * nominals (underlying nominals summed into their product, product nominals summed into the Opportunity) and
     * orders them Opportunity, then each product followed by its underlyings (by underlying orderIndex).
     */
    private static List<ProfitabilityRow> buildRows(List<Object> rawResults, DMT_ViewController.LineDataWrapper data) {
        List<Map<String, Object>> results = normalizeResults(rawResults);

        Map<String, Map<String, Object>> productById = new Map<String, Map<String, Object>>();
        String oppInitialDate;
        String oppMaturityDate;
        String oppCurrency = '';
        Boolean hasOpportunityDates = false;
        for (Map<String, Object> detail : data.profitabilityProductDetailsList) {
            String key = detail.get('gf_group_priority_opportunity_id__c') != null ? String.valueOf(detail.get('gf_group_priority_opportunity_id__c')) : null;
            if (key != null) {
                productById.put(key, detail);
            }
            if (!hasOpportunityDates && detail.get('OppInitialDate') != null && detail.get('OppMaturityDate') != null) {
                hasOpportunityDates = true;
                oppInitialDate = formatDate(detail.get('OppInitialDate'));
                oppMaturityDate = formatDate(detail.get('OppMaturityDate'));
                oppCurrency = detail.get('OppCurrency') != null ? String.valueOf(detail.get('OppCurrency')) : '';
            }
        }

        List<String> underlyingIds = new List<String>();
        for (Map<String, Object> r : results) {
            if (isTruthy(r.get('underlyingId'))) {
                underlyingIds.add(String.valueOf(r.get('underlyingId')));
            }
        }
        Map<String, Map<String, Object>> underlyingDetails = new Map<String, Map<String, Object>>();
        if (!underlyingIds.isEmpty()) {
            try {
                underlyingDetails = DMT_Profitability_utils.getUnderlyingDetailsByIds(underlyingIds);
            } catch (Exception e) {
                // Same as the modal when the call fails: underlying rows show their raw Id and no nominals.
                System.debug(LoggingLevel.WARN, 'Error resolving underlyings: ' + e.getMessage());
            }
        }

        ProfitabilityRow opportunityRow;
        List<ProfitabilityRow> productRows = new List<ProfitabilityRow>();
        List<ProfitabilityRow> underlyingRows = new List<ProfitabilityRow>();
        for (Integer index = 0; index < results.size(); index++) {
            Map<String, Object> r = results[index];
            ProfitabilityRow row = new ProfitabilityRow();
            row.result = r;
            row.sourceIndex = index;
            row.rowCurrency = oppCurrency;
            row.amountCurrency = oppCurrency;

            if (!isTruthy(r.get('productId'))) {
                row.isOpportunity = true;
                row.id = data.opportunity.Name;
                if (hasOpportunityDates) {
                    row.initialDate = String.isBlank(oppInitialDate) ? EMPTY_VALUE : oppInitialDate;
                    row.maturityDate = String.isBlank(oppMaturityDate) ? EMPTY_VALUE : oppMaturityDate;
                }
                opportunityRow = row;
                continue;
            }

            row.productId = String.valueOf(r.get('productId'));
            Map<String, Object> product = productById.get(row.productId);
            String productCurrency = product != null && product.get('Currency') != null ? String.valueOf(product.get('Currency')) : '';
            row.id = product != null && product.get('Name') != null ? String.valueOf(product.get('Name')) : row.productId;
            row.initialDate = product != null && product.get('InitialDate') != null ? formatDate(product.get('InitialDate')) : EMPTY_VALUE;
            row.maturityDate = product != null && product.get('MaturityDate') != null ? formatDate(product.get('MaturityDate')) : EMPTY_VALUE;
            row.rowCurrency = String.isNotBlank(productCurrency) ? productCurrency : oppCurrency;
            row.amountCurrency = productCurrency;

            if (isTruthy(r.get('underlyingId'))) {
                row.underlyingId = String.valueOf(r.get('underlyingId'));
                Map<String, Object> underlying = underlyingDetails.get(row.underlyingId);
                row.id = underlying != null && underlying.get('Name') != null ? String.valueOf(underlying.get('Name')) : row.underlyingId;
                if (underlying != null) {
                    String nominalCurrency = String.isNotBlank(productCurrency) ? productCurrency : row.rowCurrency;
                    row.nominalDb = formatThousands(underlying.get('nominalDb')) + ' ' + nominalCurrency;
                    row.nominalFb = formatThousands(underlying.get('nominalFb')) + ' ' + nominalCurrency;
                    row.nominalDbValue = toNumberOrZero(underlying.get('nominalDb'));
                    row.nominalFbValue = toNumberOrZero(underlying.get('nominalFb'));
                    Object orderIndex = underlying.get('orderIndex');
                    row.underlyingOrderIndex = orderIndex != null ? Integer.valueOf(orderIndex) : null;
                }
                underlyingRows.add(row);
            } else {
                Map<String, Object> nominals = data.profitabilityNominalAmountsMap != null ? data.profitabilityNominalAmountsMap.get(row.productId) : null;
                if (nominals != null) {
                    row.nominalDb = formatThousands(nominals.get('nominalDb')) + ' ' + productCurrency;
                    row.nominalFb = formatThousands(nominals.get('nominalFb')) + ' ' + productCurrency;
                    row.nominalDbValue = toNumberOrZero(nominals.get('nominalDb'));
                    row.nominalFbValue = toNumberOrZero(nominals.get('nominalFb'));
                }
                productRows.add(row);
            }
        }

        // Products with underlyings show the sum of their underlyings' nominals.
        Map<String, List<ProfitabilityRow>> underlyingsByProduct = new Map<String, List<ProfitabilityRow>>();
        for (ProfitabilityRow underlyingRow : underlyingRows) {
            if (!underlyingsByProduct.containsKey(underlyingRow.productId)) {
                underlyingsByProduct.put(underlyingRow.productId, new List<ProfitabilityRow>());
            }
            underlyingsByProduct.get(underlyingRow.productId).add(underlyingRow);
        }
        for (ProfitabilityRow productRow : productRows) {
            List<ProfitabilityRow> children = underlyingsByProduct.get(productRow.productId);
            if (children == null) {
                continue;
            }
            Decimal sumDb = 0;
            Decimal sumFb = 0;
            Boolean hasDb = false;
            Boolean hasFb = false;
            for (ProfitabilityRow child : children) {
                if (child.nominalDbValue != null) {
                    sumDb += child.nominalDbValue;
                    hasDb = true;
                }
                if (child.nominalFbValue != null) {
                    sumFb += child.nominalFbValue;
                    hasFb = true;
                }
            }
            productRow.nominalDb = hasDb ? formatAmountWithCurrency(sumDb, productRow.rowCurrency) : EMPTY_VALUE;
            productRow.nominalFb = hasFb ? formatAmountWithCurrency(sumFb, productRow.rowCurrency) : EMPTY_VALUE;
            productRow.nominalDbValue = hasDb ? sumDb : null;
            productRow.nominalFbValue = hasFb ? sumFb : null;
        }

        // The Opportunity row shows the sum of the product rows.
        if (opportunityRow != null) {
            Decimal totalDb = 0;
            Decimal totalFb = 0;
            for (ProfitabilityRow productRow : productRows) {
                totalDb += productRow.nominalDbValue != null ? productRow.nominalDbValue : 0;
                totalFb += productRow.nominalFbValue != null ? productRow.nominalFbValue : 0;
            }
            opportunityRow.nominalDb = formatThousands(totalDb) + ' ' + oppCurrency;
            opportunityRow.nominalFb = formatThousands(totalFb) + ' ' + oppCurrency;
        }

        return orderRows(opportunityRow, productRows, underlyingRows);
    }

    private static List<Map<String, Object>> normalizeResults(List<Object> results) {
        Integer opportunityIndex;
        Map<String, Integer> productIndexById = new Map<String, Integer>();
        Set<String> seenUnderlyings = new Set<String>();
        Set<Integer> selected = new Set<Integer>();
        for (Integer i = 0; i < results.size(); i++) {
            Map<String, Object> r = (Map<String, Object>) results[i];
            if (!isTruthy(r.get('productId'))) {
                if (opportunityIndex == null) {
                    opportunityIndex = i;
                }
                continue;
            }
            if (isTruthy(r.get('underlyingId'))) {
                String underlyingId = String.valueOf(r.get('underlyingId'));
                if (!seenUnderlyings.contains(underlyingId)) {
                    seenUnderlyings.add(underlyingId);
                    selected.add(i);
                }
                continue;
            }
            String productId = String.valueOf(r.get('productId'));
            Integer currentIndex = productIndexById.get(productId);
            if (currentIndex == null) {
                productIndexById.put(productId, i);
                continue;
            }
            Map<String, Object> current = (Map<String, Object>) results[currentIndex];
            if (current.get('isLine') != true && r.get('isLine') == true) {
                productIndexById.put(productId, i);
            }
        }
        if (opportunityIndex != null) {
            selected.add(opportunityIndex);
        }
        selected.addAll(productIndexById.values());

        List<Map<String, Object>> normalized = new List<Map<String, Object>>();
        for (Integer i = 0; i < results.size(); i++) {
            if (selected.contains(i)) {
                normalized.add((Map<String, Object>) results[i]);
            }
        }
        return normalized;
    }

    private static List<ProfitabilityRow> orderRows(ProfitabilityRow opportunityRow, List<ProfitabilityRow> productRows, List<ProfitabilityRow> underlyingRows) {
        List<ProfitabilityRow> ordered = new List<ProfitabilityRow>();
        if (opportunityRow != null) {
            ordered.add(opportunityRow);
        }
        List<String> parentOrder = new List<String>();
        Map<String, List<ProfitabilityRow>> childrenByProduct = new Map<String, List<ProfitabilityRow>>();
        for (ProfitabilityRow underlyingRow : sortUnderlyings(underlyingRows)) {
            if (!childrenByProduct.containsKey(underlyingRow.productId)) {
                childrenByProduct.put(underlyingRow.productId, new List<ProfitabilityRow>());
                parentOrder.add(underlyingRow.productId);
            }
            childrenByProduct.get(underlyingRow.productId).add(underlyingRow);
        }
        Set<String> placed = new Set<String>();
        for (ProfitabilityRow productRow : productRows) {
            ordered.add(productRow);
            if (childrenByProduct.containsKey(productRow.productId) && !placed.contains(productRow.productId)) {
                ordered.addAll(childrenByProduct.get(productRow.productId));
                placed.add(productRow.productId);
            }
        }
        // Underlyings whose product row is not present go last, as in the modal.
        for (String productId : parentOrder) {
            if (!placed.contains(productId)) {
                ordered.addAll(childrenByProduct.get(productId));
            }
        }
        return ordered;
    }

    // Stable insertion sort with the modal comparator: by orderIndex when both rows have it, otherwise by source order.
    private static List<ProfitabilityRow> sortUnderlyings(List<ProfitabilityRow> rows) {
        List<ProfitabilityRow> sorted = new List<ProfitabilityRow>(rows);
        for (Integer i = 1; i < sorted.size(); i++) {
            ProfitabilityRow current = sorted[i];
            Integer j = i - 1;
            while (j >= 0 && compareUnderlyings(sorted[j], current) > 0) {
                sorted[j + 1] = sorted[j];
                j--;
            }
            sorted[j + 1] = current;
        }
        return sorted;
    }

    private static Integer compareUnderlyings(ProfitabilityRow a, ProfitabilityRow b) {
        if (a.underlyingOrderIndex != null && b.underlyingOrderIndex != null) {
            return a.underlyingOrderIndex - b.underlyingOrderIndex;
        }
        return a.sourceIndex - b.sourceIndex;
    }

    // ---- Formats of the former modal (dmt_profitability_chart.js), es-ES numbers ----

    // formatThousands: es-ES, exactly 2 decimals, '' when empty.
    private static String formatThousands(Object value) {
        Decimal decValue = toDecimal(value);
        return decValue == null ? '' : formatEs(decValue, 2, 2);
    }

    // formatAmountWithCurrency: formatThousands + currency, '' when empty.
    private static String formatAmountWithCurrency(Object value, String currencyCode) {
        String formatted = formatThousands(value);
        return String.isBlank(formatted) ? '' : (formatted + ' ' + (currencyCode == null ? '' : currencyCode)).trim();
    }

    // formatAmountWithCurrencyMax2: scientific notation below 0.01, otherwise es-ES with up to 2 decimals.
    private static String formatAmountWithCurrencyMax2(Object value, String currencyCode) {
        Decimal decValue = toDecimal(value);
        if (decValue == null) {
            return '';
        }
        Decimal absValue = decValue.abs();
        String formatted = absValue > 0 && absValue < 0.01 ? toExponential2(decValue) : formatEs(decValue, 0, 2);
        return (formatted + ' ' + (currencyCode == null ? '' : currencyCode)).trim();
    }

    // formatPercent: value x 100 with 2 decimals, '' when not a number.
    private static String formatPercent(Object value) {
        Decimal decValue = toDecimal(value);
        return decValue == null ? '' : formatFixed(decValue * 100, 2) + ' %';
    }

    // formatPercent(value / 100) of the modal: an empty value counts as 0.
    private static String formatPercentOfWhole(Object value) {
        Decimal decValue = toDecimal(value);
        return formatFixed(decValue == null ? 0 : decValue, 2) + ' %';
    }

    // formatBps: an empty value counts as 0, no decimals.
    private static String formatBps(Object value) {
        Decimal decValue = toDecimal(value);
        return formatFixed(decValue == null ? 0 : decValue, 0) + ' bps';
    }

    // Average Life / Tenor: 2 decimals and the 'y' suffix, '' when empty.
    private static String formatYears(Object value) {
        Decimal decValue = toDecimal(value);
        return decValue == null ? '' : formatFixed(decValue, 2) + 'y';
    }

    private static String formatProfitabilityMetric(Object value, Object thresholdValue) {
        Decimal valueDecimal = toDecimal(value);
        Decimal thresholdDecimal = toDecimal(thresholdValue);
        String comparisonSign = valueDecimal != null && thresholdDecimal != null && thresholdDecimal < valueDecimal ? '&gt;' : '&lt;';
        return formatPercent(value) + ' ' + comparisonSign + ' ' + formatPercent(thresholdValue);
    }

    // Number.toFixed: '.' as decimal separator, no grouping, rounding half away from zero.
    private static String formatFixed(Decimal value, Integer scale) {
        Decimal rounded = value.setScale(scale, RoundingMode.HALF_UP);
        String text = rounded.abs().toPlainString();
        return (value < 0 ? '-' : '') + text;
    }

    // toLocaleString('es-ES'): ',' decimals, '.' grouping from 5 integer digits.
    private static String formatEs(Decimal value, Integer minDecimals, Integer maxDecimals) {
        Decimal rounded = value.setScale(maxDecimals, RoundingMode.HALF_UP);
        String text = rounded.abs().toPlainString();
        String integerPart = text.substringBefore('.');
        String decimals = text.contains('.') ? text.substringAfter('.') : '';
        while (decimals.length() > minDecimals && decimals.endsWith('0')) {
            decimals = decimals.left(decimals.length() - 1);
        }
        if (integerPart.length() >= 5) {
            String grouped = '';
            Integer count = 0;
            for (Integer i = integerPart.length() - 1; i >= 0; i--) {
                grouped = integerPart.substring(i, i + 1) + grouped;
                count++;
                if (count == 3 && i > 0) {
                    grouped = '.' + grouped;
                    count = 0;
                }
            }
            integerPart = grouped;
        }
        String sign = value < 0 ? '-' : '';
        return sign + integerPart + (decimals.length() > 0 ? ',' + decimals : '');
    }

    // Number.toExponential(2), e.g. -4.47e-4.
    private static String toExponential2(Decimal value) {
        Decimal mantissa = value.abs();
        Integer exponent = 0;
        while (mantissa < 1) {
            mantissa *= 10;
            exponent--;
        }
        while (mantissa >= 10) {
            mantissa /= 10;
            exponent++;
        }
        mantissa = mantissa.setScale(2, RoundingMode.HALF_UP);
        if (mantissa >= 10) {
            mantissa = (mantissa / 10).setScale(2, RoundingMode.HALF_UP);
            exponent++;
        }
        return (value < 0 ? '-' : '') + mantissa.toPlainString() + 'e' + (exponent < 0 ? '-' : '+') + Math.abs(exponent);
    }

    private static String formatDate(Object value) {
        if (value == null) {
            return '';
        }
        if (value instanceof Date) {
            return String.valueOf((Date) value);
        }
        return String.valueOf(value);
    }

    private static Object firstValue(Map<String, Object> row, String key, String fallbackKey) {
        return row.get(key) != null ? row.get(key) : row.get(fallbackKey);
    }

    private static Boolean isTruthy(Object value) {
        if (value == null) {
            return false;
        }
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        if (value instanceof Decimal || value instanceof Integer || value instanceof Long || value instanceof Double) {
            return toDecimal(value) != 0;
        }
        return String.isNotBlank(String.valueOf(value));
    }

    private static Decimal toNumberOrZero(Object value) {
        Decimal decValue = toDecimal(value);
        return decValue == null ? 0 : decValue;
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
        }
    }

    private static String normalizeImageBase64(String raw) {
        if (raw == null) {
            return null;
        }
        return raw.replaceAll('\\s+', '');
    }

    private static String toImageDataUri(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String cleaned = raw.trim();
        if (cleaned.toLowerCase().startsWith('data:')) {
            return cleaned;
        }
        String lower = cleaned.toLowerCase();
        String mime = 'image/jpeg';
        if (lower.startsWith('ivborw0kggo')) {
            mime = 'image/png';
        } else if (lower.startsWith('r0lgod')) {
            mime = 'image/gif';
        }
        return 'data:' + mime + ';base64,' + cleaned;
    }

    /**
     * CIBGLOBALD-4713 - Empty marker where the Profitability modal (LWC dmt_profitability_view) inserts
     * its 'External RWA calculate' button. Only emitted when the modal asks for it
     * (data.profitabilityShowRwaAction, set by DMT_Profitability_utils.renderProfitabilityHtml); the NBC
     * views, the case task modal and the snapshots never get it. The modal removes it before the PDF.
     * data-enabled follows the Opportunity branch (DMT_Profitability_utils.getRwaRegLinkInfo).
     */
    private static String getExternalRwaActionMarker(DMT_ViewController.LineDataWrapper data) {
        if (data.profitabilityShowRwaAction != true) {
            return '';
        }
        Boolean enabled = data.profitabilityRwaLinkInfo != null && data.profitabilityRwaLinkInfo.get('enabled') == true;
        return '<div data-dmt-action="external-rwa" data-enabled="' + enabled + '"></div>';
    }

    /**
     * CIBGLOBALD-4713 - 'External RWA 1Y' cell of the Regulatory Capital table: the value returned by the
     * External RWA service for the row's productId (data.profitabilityAprsByProductId), linked to the RWA
     * calculator when the Opportunity branch has the link enabled (data.profitabilityRwaLinkInfo).
     * Same value and link as the former modal code (dmt_profitability_chart).
     */
    private static String getExternalRwaCell(ProfitabilityRow row, DMT_ViewController.LineDataWrapper data) {
        if (row.isOpportunity) {
            return '';
        }
        String formattedValue = formatAmountWithCurrency(data.profitabilityAprsByProductId.get(row.productId), row.rowCurrency);
        Map<String, Object> linkInfo = data.profitabilityRwaLinkInfo;
        if (String.isBlank(formattedValue) || linkInfo == null || linkInfo.get('enabled') != true) {
            return formattedValue;
        }
        String explanationId = String.valueOf(linkInfo.get('explanationId')) + '_' + row.productId;
        String country = linkInfo.get('entific') != null ? String.valueOf(linkInfo.get('entific')) : '';
        String url = String.valueOf(linkInfo.get('baseUrl'))
            + '?explanationId=' + EncodingUtil.urlEncode(explanationId, 'UTF-8')
            + '&amp;applicationId=2&amp;country=' + EncodingUtil.urlEncode(country, 'UTF-8');
        return '<a href="' + url + '" target="_blank" rel="noopener noreferrer">' + formattedValue + '</a>';
    }

    // Helper to extract the profitability feature from featuresList
    private static Map<String, Object> getProfitabilityFeature(List<Object> featuresList) {
        for (Object obj : featuresList) {
            Map<String, Object> feature = (Map<String, Object>)obj;
            if (feature != null && feature.containsKey('profitability')) {
                return feature;
            }
        }
        return new Map<String, Object>();
    }
}
