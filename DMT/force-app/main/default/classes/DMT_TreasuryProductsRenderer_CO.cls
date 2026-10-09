// This renderer builds HTML directly. data-dmt-* attributes are added so
// htmlVersionNormalizer.js can use the tagged path for accurate field-level diff comparison.
// CIBGLOBALD-4117: self-contained tracking, same as every other renderer - DMT_ProductsRenderer
// resolves to this class only when the Line is Treasury + Booking_Geography__c = 'CO', so these
// methods report exactly what this variant itself reads, nothing unioned in from a sibling.
public without sharing class DMT_TreasuryProductsRenderer_CO implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{
            'DvP_Amount__c', 'CurrencyIsoCode', 'FD_Amount__c', 'DMT_Additional_Restrictions__c',
            'DMT_Comments__c',
            // Not displayed directly, but decides whether this variant (vs default/PE/MX) is the
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
                'DMT_Risk_Type__c', 'DMT_Singular__c', 'DMT_Init_Term__c', 'DMT_End_Term__c',
                'DMT_Amount__c', 'DMT_Singular_Operation__c', 'DMT_Singular_DvP__c',
                'DMT_Singular_FD__c', 'DMT_Term__c', 'DMT_Max_Date__c', 'DMT_Singular_Active__c',
                'CurrencyIsoCode'
            },
            'DMT_Line_Product_Item__c' => new List<String>{
                'Name', 'DMT_DerivativeRestriction__c', 'DMT_FDRestriction__c', 'DMT_DVPRestriction__c'
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

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line == null || data.lineProductList == null) {
            return '';
        }
        List<DMT_Risk_Line_Term__c> riskLineDerivatesList = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> riskLineSingularList = new List<DMT_Risk_Line_Term__c>();
        System.debug('DMT_TreasuryProductsRenderer_CO renderHtml data, '+ JSON.serialize(data));
        for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
            if (riskLine.DMT_Risk_Type__c == 'Derivatives' && riskLine.DMT_Singular__c == false) {
                riskLineDerivatesList.add(riskLine);
            }
            if (riskLine.DMT_Risk_Type__c == 'Derivatives' && riskLine.DMT_Singular__c == true){
                riskLineSingularList.add(riskLine);
            }
        }
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

        table += '<div>'
        + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
        + '<tr data-dmt-table-title="true">'
        + '<td colspan="7" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>ONE-OFF-TRANSACTION</strong></td>'
        + '</tr>'
        + '<tr data-dmt-table-header="true">'
        + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TRANSACTION</strong></td>'
        // CIBGLOBALD-4117 - editable DVP/FD columns on the live edit-side dmt_singular_treasury.js
        // table but never displayed here - found via a field-drift audit.
        + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DVP AMOUNT</strong></td>'
        + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FD AMOUNT</strong></td>'
        + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>AMOUNT</strong></td>'
        + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TERM</strong></td>'
        + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>MAX DATE</strong></td>'
        + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>ACTIVE</strong></td>'
        + '</tr>';
        if (!riskLineSingularList.isEmpty()) {
            for (DMT_Risk_Line_Term__c riskLine : riskLineSingularList) {
                System.debug('DMT_TreasuryPrductsRenderer_CO renderHtml riskLine.DMT_Max_Date__c, '+ riskLine.DMT_Max_Date__c);
                System.debug('DMT_TreasuryPrductsRenderer_CO renderHtml DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c), '+ DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c));
                System.debug('DMT_TreasuryPrductsRenderer_CO renderHtml DMT_FormattingUtils.changeDateFormat(DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c)), '+ DMT_FormattingUtils.changeDateFormat(DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c)));
                String active = riskLine.DMT_Singular_Active__c ? 'Yes' : 'No';
                table += '<tr data-dmt-table-row="true">'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(riskLine.DMT_Singular_Operation__c) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Singular_DvP__c, riskLine.CurrencyIsoCode) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Singular_FD__c, riskLine.CurrencyIsoCode) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, riskLine.CurrencyIsoCode) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(riskLine.DMT_Term__c) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.changeDateFormat(DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c)) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + active + '</td>'
                    + '</tr>';
            }
        }
        table += '</table></div>&nbsp;</br>';

        if (!data.lineProductList.isEmpty()) {
            table += '<div>'
                + '<table data-dmt-table="true" class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr data-dmt-table-title="true">'
                + '<td colspan="4" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>AVAILABLE PRODUCTS</strong></td>'
                + '</tr>'
                + '<tr data-dmt-table-header="true">'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>PRODUCT GROUP</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DERIVATIVES LINE</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FD LINE: (' + fdLineHeaderAmount + ')</strong></td>'
                + '<td data-dmt-header-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DVP LINE: (' + dvpLineHeaderAmount + ')</strong></td>'
                + '</tr>';
            for (DMT_Line_Product_Item__c lineProduct : data.lineProductList) {
                table += '<tr data-dmt-table-row="true">'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lineProduct.Name) + '</td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;"><div style="display: inline-block; width: 12px; height: 12px; border: 1px solid #999; text-align: center; vertical-align: middle; line-height: 12px; font-family: Arial Unicode MS, Arial, sans-serif; font-size: 10px; color: #333; font-weight: bold;">' + (lineProduct.DMT_DerivativeRestriction__c ? '&#10003;' : '') + '</div></td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;"><div style="display: inline-block; width: 12px; height: 12px; border: 1px solid #999; text-align: center; vertical-align: middle; line-height: 12px; font-family: Arial Unicode MS, Arial, sans-serif; font-size: 10px; color: #333; font-weight: bold;">' + (lineProduct.DMT_FDRestriction__c ? '&#10003;' : '') + '</div></td>'
                    + '<td data-dmt-cell="true" style="padding: 8px; border-bottom: 1px solid #ccc;"><div style="display: inline-block; width: 12px; height: 12px; border: 1px solid #999; text-align: center; vertical-align: middle; line-height: 12px; font-family: Arial Unicode MS, Arial, sans-serif; font-size: 10px; color: #333; font-weight: bold;">' + (lineProduct.DMT_DVPRestriction__c ? '&#10003;' : '') + '</div></td>'
                    + '</tr>';
            }
            table += '</table></div>&nbsp;</br>';
        }
        return table;
    }
}