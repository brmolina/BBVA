// Renderer for the Mexico Treasury Settlement layout.
// CIBGLOBALD-4117: self-contained tracking, same as every other renderer - DMT_ProductsRenderer
// resolves to this class only when the Line is Treasury + Booking_Geography__c = 'MX', so these
// methods report exactly what this variant itself reads, nothing unioned in from a sibling.
public without sharing class DMT_TreasuryProductsRenderer_MX implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{
            'CurrencyIsoCode', 'FD_Amount__c', 'DvP_Amount__c', 'DMT_Additional_Restrictions__c',
            'DMT_Comments__c',
            // Not displayed directly, but decides whether this variant (vs default/CO/PE) is the
            // one DMT_ProductsRenderer.resolveRenderer() picks - a geography change is itself worth
            // a fresh review.
            'Booking_Geography__c'
        };
    }

    // CIBGLOBALD-4117 - mirrors renderHtml's field reads below. Folds getTrackedFields() in under
    // 'DMT_Line__c' here too - DMT_ApprovalChangeStep_Handler.resolveTrackedFieldsForItems uses
    // getTrackedFieldsByObject() exclusively the instant it's non-empty, never falling back to
    // getTrackedFields() on its own, so this renderer has to self-include its own switch field to
    // stay complete.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'DMT_Line__c' => getTrackedFields(record),
            'DMT_Risk_Line_Term__c' => new List<String>{
                'DMT_Risk_Type__c', 'DMT_Amount__c', 'DMT_Init_Term__c', 'DMT_End_Term__c'
            },
            'DMT_Line_Product_Item__c' => new List<String>{
                'Name', 'DMT_DerivativeRestriction__c', 'Max_Tenor_WC__c',
                'DMT_FDRestriction__c', 'DMT_DVPRestriction__c',
                // Not displayed directly, but matches each product against
                // DMT_OperationalRestrictionsTRSR__mdt (Entific__c = 'MX') to decide which
                // restriction section/row it appears in - a code change can move a product to a
                // different section entirely, same reasoning as Booking_Geography__c above.
                'Product_Code_Value__c'
            }
        };
    }

    // CIBGLOBALD-4117 - ChildSection(componentName, snapshotSectionKey, childObjectApiName,
    // childLookupField, parentValueField[, orderBy]):
    //   componentName       - this component's display name, matching its DMT_Items__c row
    //                         ('Products'); shows up in logs/labels, not used for lookups.
    //   snapshotSectionKey  - the key this section's rows are stored under in the frozen JSON
    //                         snapshot. Must match DMT_TreasuryProductsRenderer's own keys
    //                         ('riskLineList'/'lineProductItemList') since only one Treasury
    //                         geography variant is ever active per record - this is a switch, not a
    //                         union of simultaneous components.
    //   childObjectApiName  - the SObject to query for this section's rows. Must match a key in
    //                         this renderer's own getTrackedFieldsByObject() map, or nothing gets
    //                         queried/compared for it.
    //   childLookupField    - the field ON childObjectApiName that points back to the parent record.
    //   parentValueField    - the field ON THE PARENT (Line) whose value is matched against
    //                         childLookupField - 'Id' for both sections here.
    //   orderBy (optional)  - ORDER BY clause for the child query, when row order matters for the
    //                         comparison.
    public List<DMT_ApprovalChangeStep_Helper.ChildSection> getChildSections(SObject record) {
        return new List<DMT_ApprovalChangeStep_Helper.ChildSection>{
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Products', 'riskLineList', 'DMT_Risk_Line_Term__c', 'DMT_Line__c', 'Id', 'DMT_Init_Term__c ASC'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Products', 'lineProductItemList', 'DMT_Line_Product_Item__c', 'Line__c', 'Id', 'Name ASC'
            )
        };
    }

    @TestVisible
    private class RestrictionRow {
        DMT_Line_Product_Item__c product;
        DMT_OperationalRestrictionsTRSR__mdt configuration;

        RestrictionRow(
            DMT_Line_Product_Item__c product,
            DMT_OperationalRestrictionsTRSR__mdt configuration
        ) {
            this.product = product;
            this.configuration = configuration;
        }
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line == null || data.lineProductList == null) {
            return '';
        }

        String currencyCode = DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode);
        String fdAmount = DMT_FormattingUtils.formatCurrencyAmount(data.line.FD_Amount__c, data.line.CurrencyIsoCode);
        String dvpAmount = DMT_FormattingUtils.formatCurrencyAmount(data.line.DvP_Amount__c, data.line.CurrencyIsoCode);
        if (String.isBlank(fdAmount)) {
            fdAmount = '0 ' + currencyCode;
        }
        if (String.isBlank(dvpAmount)) {
            dvpAmount = '0 ' + currencyCode;
        }

        String html = renderSummary(data);
        html += renderRiskTable('COUNTERPARTY RISK (DERIVATIVES RISK LINE)', data.riskLineList, 'Derivatives', data.line.CurrencyIsoCode);

        if (!data.lineProductList.isEmpty()) {
            List<DMT_OperationalRestrictionsTRSR__mdt> configurations = [
                SELECT DMT_Operational_Restrictions_Name__c, Product_Group__c,
                       DMT_Derivatives_layout2__c, DMT_Depos_layout2__c, DMT_Repos_layout2__c,
                       DERIVATIVES_Disabled__c, FD_Disabled__c, DVP_Disabled__c,
                       MaturityTerm_Disabled__c, OrderRestriction__c
                FROM DMT_OperationalRestrictionsTRSR__mdt
                WHERE Entific__c = 'MX' AND isActive__c = true
                ORDER BY OrderRestriction__c ASC
            ];
            html += renderRestrictionTables(data.lineProductList, configurations, fdAmount, dvpAmount);
        }

        html += renderRiskTable('DEPOS RISK LINE (ONLY FOR FINANCIAL INSTITUTIONS)', data.riskLineList, 'Depos', data.line.CurrencyIsoCode);
        html += renderRiskTable('REPOS RISK LINE', data.riskLineList, 'Repos', data.line.CurrencyIsoCode);
        return html;
    }

    private static String renderSummary(DMT_ViewController.LineDataWrapper data) {
        String dvpAmount = DMT_FormattingUtils.formatCurrencyAmount(data.line.DvP_Amount__c, data.line.CurrencyIsoCode);
        String fdAmount = DMT_FormattingUtils.formatCurrencyAmount(data.line.FD_Amount__c, data.line.CurrencyIsoCode);
        return '<div>'
            + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">PRODUCTS</h2>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + summaryCell('Delivery versus Payment (DvP) Amount:', dvpAmount)
            + summaryCell('Free Delivery (FD) Amount:', fdAmount)
            + summaryCell('Additional Products:', DMT_FormattingUtils.checkNull(data.line.DMT_Additional_Restrictions__c))
            + summaryCell('Comments:', DMT_FormattingUtils.checkNull(data.line.DMT_Comments__c))
            + '</table></div>&nbsp;</br>';
    }

    private static String summaryCell(String label, String value) {
        return '<tr data-dmt-row="field">'
            + '<td data-dmt-label="' + label + '" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>' + label + '</strong></td>'
            + '<td data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + value + '</td>'
            + '</tr>';
    }

    @TestVisible
    private static String renderRestrictionTables(
        List<DMT_Line_Product_Item__c> products,
        List<DMT_OperationalRestrictionsTRSR__mdt> configurations,
        String fdAmount,
        String dvpAmount
    ) {
        Map<String, DMT_Line_Product_Item__c> productsByCode = new Map<String, DMT_Line_Product_Item__c>();
        for (DMT_Line_Product_Item__c product : products) {
            if (String.isNotBlank(product.Product_Code_Value__c)) {
                productsByCode.put(product.Product_Code_Value__c.trim().toUpperCase(), product);
            }
        }

        Map<String, List<RestrictionRow>> rowsBySection = new Map<String, List<RestrictionRow>>{
            'DERIVATIVES RESTRICTIONS' => new List<RestrictionRow>(),
            'DEPOS RESTRICTIONS' => new List<RestrictionRow>(),
            'REPOS RESTRICTIONS' => new List<RestrictionRow>()
        };

        for (DMT_OperationalRestrictionsTRSR__mdt configuration : configurations) {
            String productCode = configuration.DMT_Operational_Restrictions_Name__c;
            DMT_Line_Product_Item__c product = String.isBlank(productCode)
                ? null
                : productsByCode.get(productCode.trim().toUpperCase());
            if (product == null) {
                continue;
            }
            RestrictionRow row = new RestrictionRow(product, configuration);
            if (configuration.DMT_Derivatives_layout2__c == true) {
                rowsBySection.get('DERIVATIVES RESTRICTIONS').add(row);
            }
            if (configuration.DMT_Depos_layout2__c == true) {
                rowsBySection.get('DEPOS RESTRICTIONS').add(row);
            }
            if (configuration.DMT_Repos_layout2__c == true) {
                rowsBySection.get('REPOS RESTRICTIONS').add(row);
            }
        }

        String html = '';
        for (String section : new List<String>{'DERIVATIVES RESTRICTIONS', 'DEPOS RESTRICTIONS', 'REPOS RESTRICTIONS'}) {
            html += renderRestrictionSection(section, rowsBySection.get(section), fdAmount, dvpAmount);
        }
        return html;
    }

    private static String renderRestrictionSection(
        String title,
        List<RestrictionRow> rows,
        String fdAmount,
        String dvpAmount
    ) {
        if (rows == null || rows.isEmpty()) {
            return '';
        }

        Boolean showMaturity = false;
        Boolean showFd = false;
        Boolean showDvp = false;
        for (RestrictionRow row : rows) {
            showMaturity = showMaturity || row.configuration.MaturityTerm_Disabled__c != true;
            showFd = showFd || row.configuration.FD_Disabled__c != true;
            showDvp = showDvp || row.configuration.DVP_Disabled__c != true;
        }
        Integer columns = 2 + (showMaturity ? 1 : 0) + (showFd ? 1 : 0) + (showDvp ? 1 : 0);
        String html = '<div><table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr data-dmt-table-title="true"><td colspan="' + columns + '" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + title + '</strong></td></tr>'
            + '<tr data-dmt-table-header="true">'
            + headerCell('PRODUCT GROUP')
            + headerCell('DERIVATIVES LINE')
            + (showMaturity ? headerCell('MATURITY TERM') : '')
            + (showFd ? headerCell('FD LINE: (' + fdAmount + ')') : '')
            + (showDvp ? headerCell('DVP LINE: (' + dvpAmount + ')') : '')
            + '</tr>';

        for (RestrictionRow row : rows) {
            DMT_Line_Product_Item__c product = row.product;
            html += '<tr data-dmt-table-row="true">'
                + dataCell(DMT_FormattingUtils.checkNull(product.Name))
                + checkboxCell(product.DMT_DerivativeRestriction__c)
                + (showMaturity ? dataCell(formatMaturityTerm(product.Max_Tenor_WC__c)) : '')
                + (showFd ? checkboxCell(product.DMT_FDRestriction__c) : '')
                + (showDvp ? checkboxCell(product.DMT_DVPRestriction__c) : '')
                + '</tr>';
        }
        return html + '</table></div>&nbsp;</br>';
    }

    private static String headerCell(String value) {
        return '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>' + value + '</strong></td>';
    }

    private static String dataCell(String value) {
        return '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + value + '</td>';
    }

    private static String checkboxCell(Boolean checked) {
        return dataCell('<div style="display: inline-block; width: 12px; height: 12px; border: 1px solid #999; text-align: center; vertical-align: middle; line-height: 12px; font-family: Arial Unicode MS, Arial, sans-serif; font-size: 10px; color: #333; font-weight: bold;">' + (checked == true ? '&#10003;' : '') + '</div>');
    }

    private static String renderRiskTable(String title, List<DMT_Risk_Line_Term__c> riskLines, String riskType, String currencyIsoCode) {
        List<DMT_Risk_Line_Term__c> matchingLines = new List<DMT_Risk_Line_Term__c>();
        for (DMT_Risk_Line_Term__c riskLine : riskLines) {
            if (riskLine.DMT_Risk_Type__c == riskType && riskLine.DMT_Amount__c != null && riskLine.DMT_Amount__c > 0) {
                matchingLines.add(riskLine);
            }
        }
        if (matchingLines.isEmpty()) {
            return '';
        }

        String html = '<div><table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr data-dmt-table-title="true"><td colspan="3" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>' + title + '</strong></td></tr>'
            + '<tr data-dmt-table-header="true">'
            + headerCell('INIT TERM') + headerCell('END TERM') + headerCell('AMOUNT') + '</tr>';
        for (DMT_Risk_Line_Term__c riskLine : matchingLines) {
            html += '<tr data-dmt-table-row="true">'
                + dataCell(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLine.DMT_Init_Term__c)))
                + dataCell(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLine.DMT_End_Term__c)))
                + dataCell(DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, currencyIsoCode))
                + '</tr>';
        }
        return html + '</table></div>&nbsp;</br>';
    }

    private static String formatMaturityTerm(Object tenorValue) {
        String rawValue = DMT_FormattingUtils.checkNull(tenorValue);
        if (String.isBlank(rawValue)) {
            return '';
        }
        String translatedValue = DMT_FormattingUtils.traductorDate(rawValue);
        return String.isBlank(translatedValue) ? rawValue : translatedValue.trim();
    }
}