// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
// CIBGLOBALD-4117: Factory -> Delegator -> Renderer - this is the Treasury "default" geography
// renderer (anything that isn't CO/PE/MX, e.g. AR). Tracks only the fields it itself reads; it does
// NOT union in DMT_TreasuryProductsRenderer_CO/_PE/_MX's fields - DMT_ProductsRenderer.resolveRenderer
// picks exactly one of the four variants per record, and only that one's tracked fields apply, same
// as every NBC IBF/GTB pair.
public without sharing class DMT_TreasuryProductsRenderer implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    private static final Set<String> LINE_FIELDS = new Set<String>{
        'DvP_Amount__c', 'CurrencyIsoCode', 'FD_Amount__c', 'Repos_Limit__c', 'Repos_Limit_6M__c',
        'First_Breakclause__c', 'First_Breakclause_Date__c', 'Waiver__c', 'Breakclause_Frequency__c',
        // Not displayed directly, but decides which Treasury layout (this one, CO, PE, MX) is shown
        // - DMT_ProductsRenderer.resolveRenderer() needs this renderer to self-fold it in so a
        // geography change is itself worth a fresh review, same reasoning as every NBC delegator's
        // switch fields.
        'Booking_Geography__c',
        // CIBGLOBALD-4117 - editable textarea fields on the PRODUCTS tab's cfRiskTablesLine FlexCard
        // ('Additional Products'/'Comments', objectApiName DMT_Line__c) but untracked by any
        // Treasury-side component - Approval Process Data's Treasury renderer only tracks
        // DMT_Client_Use__c (Comments/Additional Restrictions are tracked there for OtherProducts
        // only). Found via a field-drift audit against the live edit-side FlexCard.
        'DMT_Additional_Restrictions__c', 'DMT_Comments__c'
    };

    private static final Set<String> RISK_LINE_TERM_FIELDS = new Set<String>{
        'DMT_Risk_Type__c', 'DMT_Init_Term__c', 'DMT_End_Term__c', 'DMT_Amount__c'
    };

    private static final Set<String> LINE_PRODUCT_ITEM_FIELDS = new Set<String>{
        'Name', 'DMT_DerivativeRestriction__c', 'Max_Tenor_WC__c',
        'DMT_FDRestriction__c', 'DMT_DVPRestriction__c'
    };

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>(LINE_FIELDS);
    }

    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'DMT_Line__c' => new List<String>(LINE_FIELDS),
            'DMT_Risk_Line_Term__c' => new List<String>(RISK_LINE_TERM_FIELDS),
            'DMT_Line_Product_Item__c' => new List<String>(LINE_PRODUCT_ITEM_FIELDS)
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
                'Products', 'riskLineList', 'DMT_Risk_Line_Term__c', 'DMT_Line__c', 'Id', 'DMT_Init_Term__c ASC'
            ),
            new DMT_ApprovalChangeStep_Helper.ChildSection(
                'Products', 'lineProductItemList', 'DMT_Line_Product_Item__c', 'Line__c', 'Id', 'Name ASC'
            )
        };
    }

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line == null || data.lineProductList == null) {
            return '';
        }
        List<DMT_Risk_Line_Term__c> riskLineDerivatesList = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> riskLineDeposList = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> riskLineEquitiesList = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> riskLineReposList = new List<DMT_Risk_Line_Term__c>();
        System.debug('DMT_TreasuryProductsRenderer renderHtml data, '+ JSON.serialize(data));
        for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
            if (riskLine.DMT_Risk_Type__c == 'Derivatives') {
                riskLineDerivatesList.add(riskLine);
            } else if (riskLine.DMT_Risk_Type__c == 'Depos') {
                riskLineDeposList.add(riskLine);
            } else if (riskLine.DMT_Risk_Type__c == 'Equities') {
                riskLineEquitiesList.add(riskLine);
            } else if (riskLine.DMT_Risk_Type__c == 'Repos') {
                riskLineReposList.add(riskLine);
            }
        }

        Boolean isAR = data.line.Booking_Geography__c == 'AR';
        String currencyCode = DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode);
        String fdLineHeaderAmount = DMT_FormattingUtils.formatCurrencyAmount(data.line.FD_Amount__c, data.line.CurrencyIsoCode);
        String dvpLineHeaderAmount = DMT_FormattingUtils.formatCurrencyAmount(data.line.DvP_Amount__c, data.line.CurrencyIsoCode);
        if (String.isBlank(fdLineHeaderAmount)) {
            fdLineHeaderAmount = '0 ' + currencyCode;
        }
        if (String.isBlank(dvpLineHeaderAmount)) {
            dvpLineHeaderAmount = '0 ' + currencyCode;
        }

        String table = '<div>'
            + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">PRODUCTS</h2>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr data-dmt-row="field">'
            + '<td data-dmt-pair="1" data-dmt-label="Delivery versus Payment (DvP) Amount:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Delivery versus Payment (DvP) Amount:</strong></td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(data.line.DvP_Amount__c, data.line.CurrencyIsoCode) + '</td>'
            + '<td data-dmt-pair="2" data-dmt-label="Free Delivery (FD) Amount:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Free Delivery (FD) Amount:</strong></td>'
            + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(data.line.FD_Amount__c, data.line.CurrencyIsoCode) + '</td>'
            + '</tr>'
            + '<tr data-dmt-row="field">'
            + '<td data-dmt-pair="1" data-dmt-label="Repos line total(Financing Framework):" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Repos line total(Financing Framework):</strong></td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Repos_Limit__c) + '</td>'
            + '<td data-dmt-pair="2" data-dmt-label="Repos line no-flow (&gt;1Y nominal):" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Repos line no-flow (&gt;1Y nominal):</strong></td>'
            + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Repos_Limit_6M__c) + '</td>'
            + '</tr>'
            + '<tr data-dmt-row="field">'
            + '<td data-dmt-pair="1" data-dmt-label="First Breakclause:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>First Breakclause:</strong></td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(data.line.First_Breakclause__c)) + '</td>'
            + '<td data-dmt-pair="2" data-dmt-label="First Breakclause Date:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>First Breakclause Date:</strong></td>'
            + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.changeDateFormat(DMT_FormattingUtils.checkNull(data.line.First_Breakclause_Date__c)) + '</td>'
            + '</tr>'
            + '<tr data-dmt-row="field">'
            + '<td data-dmt-pair="1" data-dmt-label="ISDA Waiver:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>ISDA Waiver:</strong></td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">'
            + '<div class="checkbox">' + (data.line.Waiver__c ? '&#10003;' : '') + '</div>'
            + '</td>'
            + '<td data-dmt-pair="2" data-dmt-label="Breakclause Frequency:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Breakclause Frequency:</strong></td>'
            + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(data.line.Breakclause_Frequency__c)) + '</td>'
            + '</tr>'
            // CIBGLOBALD-4117 - editable on the PRODUCTS tab's cfRiskTablesLine FlexCard
            // ('Additional Products'/'Comments') but never displayed here - found via a field-drift
            // audit against the live edit-side FlexCard.
            + '<tr data-dmt-row="field">'
            + '<td data-dmt-pair="1" data-dmt-label="Additional Products:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Additional Products:</strong></td>'
            + '<td data-dmt-pair="1" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.DMT_Additional_Restrictions__c) + '</td>'
            + '<td data-dmt-pair="2" data-dmt-label="Comments:" style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Comments:</strong></td>'
            + '<td data-dmt-pair="2" data-dmt-value="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.DMT_Comments__c) + '</td>'
            + '</tr>'
            + '</table>'
            + '</div>'
            + '&nbsp;</br>';

        if (!riskLineDerivatesList.isEmpty()) {
            table += '<div>'
                + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr data-dmt-table-title="true">'
                + '<td colspan="3" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>COUNTERPARTY RISK (DERIVATIVES RISK LINE)</strong></td>'
                + '</tr>'
                + '<tr data-dmt-table-header="true">'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>INIT TERM</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>END TERM</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>AMOUNT</strong></td>'
                + '</tr>';
            for (DMT_Risk_Line_Term__c riskLineDerivate : riskLineDerivatesList) {
                table += '<tr data-dmt-table-row="true">'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDerivate.DMT_Init_Term__c)) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDerivate.DMT_End_Term__c)) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(riskLineDerivate.DMT_Amount__c, data.line.CurrencyIsoCode) + '</td>'
                    + '</tr>';
            }
            table += '</table></div>&nbsp;</br>';
        }

        if (!data.lineProductList.isEmpty()) {
            table += '<div>'
                + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr data-dmt-table-title="true">'
                + '<td colspan="' + (isAR ? '4' : '5') + '" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>AVAILABLE PRODUCTS</strong></td>'
                + '</tr>'
                + '<tr data-dmt-table-header="true">'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>PRODUCT GROUP</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DERIVATIVES LINE</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>MATURITY TERM</strong></td>'
                + (isAR ? '' : '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FD LINE: (' + fdLineHeaderAmount + ')</strong></td>')
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DVP LINE: (' + dvpLineHeaderAmount + ')</strong></td>'
                + '</tr>';
            for (DMT_Line_Product_Item__c lineProduct : data.lineProductList) {
                table += '<tr data-dmt-table-row="true">'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lineProduct.Name) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;"><div style="display: inline-block; width: 12px; height: 12px; border: 1px solid #999; text-align: center; vertical-align: middle; line-height: 12px; font-family: Arial Unicode MS, Arial, sans-serif; font-size: 10px; color: #333; font-weight: bold;">' + (lineProduct.DMT_DerivativeRestriction__c ? '&#10003;' : '') + '</div></td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + formatMaturityTerm(lineProduct.Max_Tenor_WC__c) + '</td>'
                    + (isAR ? '' : '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;"><div style="display: inline-block; width: 12px; height: 12px; border: 1px solid #999; text-align: center; vertical-align: middle; line-height: 12px; font-family: Arial Unicode MS, Arial, sans-serif; font-size: 10px; color: #333; font-weight: bold;">' + (lineProduct.DMT_FDRestriction__c ? '&#10003;' : '') + '</div></td>')
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;"><div style="display: inline-block; width: 12px; height: 12px; border: 1px solid #999; text-align: center; vertical-align: middle; line-height: 12px; font-family: Arial Unicode MS, Arial, sans-serif; font-size: 10px; color: #333; font-weight: bold;">' + (lineProduct.DMT_DVPRestriction__c ? '&#10003;' : '') + '</div></td>'
                    + '</tr>';
            }
            table += '</table></div>&nbsp;</br>';
        }

        if (!riskLineDeposList.isEmpty()) {
            Boolean hasDepos = false;
            for (DMT_Risk_Line_Term__c riskLineDepos : riskLineDeposList) {
                if (riskLineDepos.DMT_Amount__c != null && riskLineDepos.DMT_Amount__c > 0) {
                    hasDepos = true;
                    break;
                }
            }
            if (hasDepos) {
                table += '<div>'
                    + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr data-dmt-table-title="true">'
                    + '<td colspan="3" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>DEPOS RISK LINE (ONLY FOR FINANCIAL INSTITUTIONS)</strong></td>'
                    + '</tr>'
                    + '<tr data-dmt-table-header="true">'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>INIT TERM</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>END TERM</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>AMOUNT</strong></td>'
                    + '</tr>';
                for (DMT_Risk_Line_Term__c riskLineDepos : riskLineDeposList) {
                    table += '<tr data-dmt-table-row="true">'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDepos.DMT_Init_Term__c)) + '</td>'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDepos.DMT_End_Term__c)) + '</td>'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(riskLineDepos.DMT_Amount__c, data.line.CurrencyIsoCode) + '</td>'
                        + '</tr>';
                }
                table += '</table></div>&nbsp;</br>';
            }
        }

        if (!riskLineEquitiesList.isEmpty()) {
            Boolean hasEquities = false;
            for (DMT_Risk_Line_Term__c riskLineEquities : riskLineEquitiesList) {
                if (riskLineEquities.DMT_Amount__c != null && riskLineEquities.DMT_Amount__c > 0) {
                    hasEquities = true;
                    break;
                }
            }
            if (hasEquities) {
                table += '<div>'
                    + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr data-dmt-table-title="true">'
                    + '<td colspan="3" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>EQUITIES WWR RISK LINE</strong></td>'
                    + '</tr>'
                    + '<tr data-dmt-table-header="true">'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>INIT TERM</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>END TERM</strong></td>'
                    + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>AMOUNT</strong></td>'
                    + '</tr>';
                for (DMT_Risk_Line_Term__c riskLineEquities : riskLineEquitiesList) {
                    table += '<tr data-dmt-table-row="true">'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineEquities.DMT_Init_Term__c)) + '</td>'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineEquities.DMT_End_Term__c)) + '</td>'
                        + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(riskLineEquities.DMT_Amount__c, data.line.CurrencyIsoCode) + '</td>'
                        + '</tr>';
                }
                table += '</table></div>&nbsp;</br>';
            }
        }

        return table;
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