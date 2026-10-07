/**
 * Renderer for NBC Basic Requirements section (Opportunity context, GTB).
 */
public without sharing class DMT_NBC_OppBasicRequirementRenderer_GTB implements DMT_ViewRenderer, DMT_FieldTrackableRenderer, DMT_MultiObjectFieldTrackableRenderer, DMT_CalloutTrackableRenderer {

    // CIBGLOBALD-4117 - getTrackedFields() = buildRenderFields()'s own field names (what gets
    // rendered), plus, immediately below the loop, any fields that might not be rendered. If this
    // renderer doesn't use buildRenderFields(), just list the field API names directly instead.
    public List<String> getTrackedFields(SObject record) {
        return new List<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'};
    }

    // CIBGLOBALD-4117 - mirrors BasicRequirementData's own field reads below. The featuresList
    // profitability figures (rorc/raroec/etc.) are tracked separately via this renderer's own
    // DMT_CalloutTrackableRenderer methods below. Folds getTrackedFields() in under 'Opportunity'
    // here too - see the identical note on the IB&F sibling.
    public Map<String, List<String>> getTrackedFieldsByObject(SObject record) {
        return new Map<String, List<String>>{
            'Opportunity' => getTrackedFields(record),
            'DMT_Opportunity_Client__c' => new List<String>{
                'DMT_Clients_Global_RORC_CIB_Past_FY__c', 'DMT_Client_RORC_YTD__c',
                'DMT_CDD_Clients_Global_Rorc_Last_FY__c', 'DMT_Exception_Pool__c'
            }
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
                'NBC Basic Requeriment', 'opportunityClient', 'DMT_Opportunity_Client__c',
                'DMT_MDE_Opportunity__c', 'Id'
            )
        };
    }

    public String getCalloutCacheKey(SObject record) {
        return record.Id;
    }

    // CIBGLOBALD-4117 - not a real HTTP callout: reuses this interface's generic derived-value diff
    // machinery. Same source/reasoning as the IB&F sub-renderer's own fetchLiveTrackedValues() - see
    // that file.
    public Map<String, Object> fetchLiveTrackedValues(SObject record) {
        Map<String, Object> values = new Map<String, Object>();
        for (Map<String, Object> feature : DMT_ViewController.getFeatures(record.Id)) {
            if (feature == null || feature.get('profitability') == null) {
                continue;
            }
            Map<String, Object> profitability = (Map<String, Object>) feature.get('profitability');
            Map<String, Object> audit = (Map<String, Object>) profitability.get('audit');
            if (audit != null) {
                values.put('rorcThreshold', audit.get('rorcThreshold'));
                values.put('raroecThreshold', audit.get('raroecThreshold'));
            }
            List<Object> results = (List<Object>) profitability.get('results');
            if (results == null) {
                continue;
            }
            for (Object resultObj : results) {
                Map<String, Object> row = (Map<String, Object>) resultObj;
                if (row.get('productId') == null) {
                    values.put('rorc', row.get('rorc'));
                    values.put('raroec', row.get('raroec'));
                    values.put('rorcProspected', row.get('rorcProspected'));
                    values.put('clientRorc', row.get('clientRorc'));
                    values.put('incomes12Months', row.get('incomes12Months'));
                    break;
                }
            }
            break;
        }
        return values;
    }

    private class ProfitabilityContext {
        Map<String, Object> summary = new Map<String, Object>();
        Object rorcThreshold;
        Object raroecThreshold;
    }

    private class TableStyles {
        String sThLeft = 'border-bottom: 1px solid #004481; font-weight: normal; color: #004481; vertical-align: bottom; font-size: 9px; text-align: left; padding-bottom: 2px;';
        String sThCenter = 'border-bottom: 1px solid #004481; font-weight: normal; color: #004481; vertical-align: bottom; font-size: 9px; text-align: center; padding-bottom: 2px;';
        String sTdLeft = 'vertical-align: top; color: #004481; font-size: 9px; text-align: left; padding-top: 8px;';
        String sTdCenter = 'vertical-align: top; color: #004481; font-size: 9px; text-align: center; padding-top: 8px;';
        String sSubLabel = 'font-size: 9px; margin-bottom: 2px; display: block; color: #004481; text-align: center;';
        String sSubTdRight = 'width: 50%; text-align: right; padding-right: 12px; color: #004481; font-size: 9px; vertical-align: top;';
        String sSubTdLeft = 'width: 50%; text-align: left; padding-left: 12px; color: #004481; font-size: 9px; vertical-align: top;';
        String sSubLabelRight = 'font-size: 9px; margin-bottom: 2px; display: block; color: #004481; text-align: right;';
        String sSubLabelLeft = 'font-size: 9px; margin-bottom: 2px; display: block; color: #004481; text-align: left;';
    }

    private class BasicRequirementData {
        public String rorcRaroecText = '';
        public String clientRorcPast = '';
        public String clientRorcYtd = '';
        public String rorcProspective = '';
        public String clientCddAvg6M = '';
        public String dealRevenues = '';
        public String exceptionPool = '';
        public Integer currentYear;

        /**
         * Centralizes and formats all values required by the HTML template.
         * @param data LineDataWrapper with opportunity/client context.
         */
        public BasicRequirementData(DMT_ViewController.LineDataWrapper data) {
            this.currentYear = Date.today().year();

            try {
                ProfitabilityContext profitabilityContext = DMT_NBC_OppBasicRequirementRenderer_GTB.getProfitabilityContext(data);

                String dealRorc = '';
                String dealRaroec = '';

                if (!profitabilityContext.summary.isEmpty()) {
                    dealRorc = DMT_NBC_OppBasicRequirementRenderer_GTB.formatProfitabilityMetric(profitabilityContext.summary.get('rorc'), profitabilityContext.rorcThreshold);
                    dealRaroec = DMT_NBC_OppBasicRequirementRenderer_GTB.formatProfitabilityMetric(profitabilityContext.summary.get('raroec'), profitabilityContext.raroecThreshold);
                    this.rorcProspective = DMT_FormattingUtils.formatPercent(profitabilityContext.summary.get('rorcProspected'));
                    this.dealRevenues = DMT_FormattingUtils.formatProfitabilityDecimal(profitabilityContext.summary.get('incomes12Months'), 2);
                }

                this.rorcRaroecText = (String.isNotBlank(dealRorc) || String.isNotBlank(dealRaroec)) ? dealRorc + ' / ' + dealRaroec : '';
                this.clientRorcPast = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Clients_Global_RORC_CIB_Past_FY__c);
                this.clientRorcYtd = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_RORC_YTD__c);
                this.clientCddAvg6M = DMT_FormattingUtils.checkNull(data.oppClient.DMT_CDD_Clients_Global_Rorc_Last_FY__c);
                this.exceptionPool = DMT_FormattingUtils.checkNull(data.oppClient.DMT_Exception_Pool__c);
            } catch (Exception e) {
                System.debug('Error in DMT_NBC_OppBasicRequirementRenderer_GTB BasicRequirementData, ' + e.getMessage() + ' ' + e.getLineNumber());
                this.rorcRaroecText = '';
                this.clientRorcPast = '';
                this.clientRorcYtd = '';
                this.rorcProspective = '';
                this.clientCddAvg6M = '';
                this.dealRevenues = '';
                this.exceptionPool = '';
            }
        }
    }

    private static ProfitabilityContext getProfitabilityContext(DMT_ViewController.LineDataWrapper data) {
        ProfitabilityContext context = new ProfitabilityContext();
        if (data == null || data.featuresList == null || data.featuresList.isEmpty()) {
            return context;
        }

        Map<String, Object> feature = getProfitabilityFeature(data.featuresList);

        if (feature == null) {
            return context;
        }

        Map<String, Object> profitability = (Map<String, Object>) feature.get('profitability');
        Map<String, Object> audit = getNestedMap(profitability, 'audit');
        context.rorcThreshold = audit.get('rorcThreshold');
        context.raroecThreshold = audit.get('raroecThreshold');

        List<Object> results = profitability.containsKey('results') ? (List<Object>) profitability.get('results') : null;
        if (results == null || results.isEmpty()) {
            return context;
        }

        context.summary = findSummaryRecord(results);

        return context;
    }

    private static Map<String, Object> getProfitabilityFeature(List<Map<String, Object>> featuresList) {
        for (Map<String, Object> item : featuresList) {
            if (item != null && item.containsKey('profitability') && item.get('profitability') != null) {
                return item;
            }
        }
        return null;
    }

    private static Map<String, Object> getNestedMap(Map<String, Object> source, String key) {
        if (source == null || String.isBlank(key) || !source.containsKey(key) || source.get(key) == null) {
            return new Map<String, Object>();
        }
        return (Map<String, Object>) source.get(key);
    }

    private static Map<String, Object> findSummaryRecord(List<Object> results) {
        for (Object rec : results) {
            Map<String, Object> summary = (Map<String, Object>) rec;
            if (!summary.containsKey('productId') || summary.get('productId') == null) {
                return summary;
            }
        }
        return new Map<String, Object>();
    }

    private static String formatProfitabilityMetric(Object value, Object thresholdValue) {
        Decimal valueDecimal = normalizePercentValue(value);
        Decimal thresholdDecimal = normalizePercentValue(thresholdValue);
            String formattedValue = formatNormalizedPercent(valueDecimal == null ? null : valueDecimal * 100);
        if (thresholdDecimal == null) {
            return formattedValue;
        }

        String comparisonSign = valueDecimal == null ? '<'
            : valueDecimal > thresholdDecimal ? '>'
            : valueDecimal < thresholdDecimal ? '<'
            : '=';
        return formattedValue + ' ' + comparisonSign + ' ' + formatNormalizedPercent(thresholdDecimal);
    }

    private static Decimal normalizePercentValue(Object val) {
        Decimal decimalValue = toDecimalOrNull(val);
        if (decimalValue == null) {
            return null;
        }
        return decimalValue.abs() <= 1 ? decimalValue * 100 : decimalValue;
    }

    private static String formatNormalizedPercent(Decimal val) {
        return val == null ? '0.00 %' : val.setScale(2) + ' %';
    }

    private static Decimal toDecimalOrNull(Object val) {
        if (val == null) {
            return null;
        }

        try {
            return Decimal.valueOf(String.valueOf(val));
        } catch (Exception e) {
            return null;
        }
    }

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    /**
     * Builds HTML content for Basic Requirements section.
     * @param data LineDataWrapper with opportunity/client context.
     * @return HTML content for section rendering.
     */
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.opportunity == null || data.oppClient == null ||
            (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            if (Test.isRunningTest() && data.forceException) {
                throw new AuraHandledException('Forced exception for test');
            }

            BasicRequirementData vals = new BasicRequirementData(data);
            TableStyles styles = new TableStyles();
            Boolean isLocal = data.opportunity.DMT_Threshold_Type__c == 'Local';

            return renderGTBHtml(vals, styles, isLocal);

        } catch (Exception e) {
            System.debug('Error in DMT_NBC_OppBasicRequirementRenderer_GTB renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    // Local additionally hides RORC Prospective CDD, Client CDD Avge 6M, Deal Revenues Next 12m
    // and Exception Pool, leaving only Standalone RORC/RAROEC and Client's RORC CIB.
    private String renderGTBHtml(BasicRequirementData vals, TableStyles styles, Boolean isLocal) {
        String html = '<div style="font-family: Arial, sans-serif; font-size: 9px; page-break-inside: avoid; margin-bottom: 0px;">'
            + '<h2 style="font-size: 10px; color: #004481; margin-bottom: 10px; font-weight: bold; text-transform: uppercase;">BASIC REQUIREMENTS*</h2>'
            + '<h3 style="font-size: 9px; color: #004481; margin-bottom: 8px; font-weight: bold;">Profitability</h3>'
            + '<table style="width:100%; border-collapse: collapse;">'
            + '<tr>'
            + '<td style="width: 28%; ' + styles.sThLeft + '">Standalone RORC / RAROEC</td>'
            + '<td style="width: 34%; ' + styles.sThCenter + '">Client\'s RORC CIB</td>'
            + (isLocal ? '' : '<td style="' + styles.sThLeft + '">RORC Prospective CDD</td>')
            + '</tr>'
            + '<tr>'
            + '<td style="' + styles.sTdLeft + '">' + vals.rorcRaroecText + '</td>'
            + '<td style="padding-top: 4px; vertical-align: top;">'
            + '<table style="width: 100%; border-collapse: collapse;"><tr>'
            + '<td style="' + styles.sSubTdRight + '"><span style="' + styles.sSubLabelRight + '">FY' + (vals.currentYear - 1) + '</span>' + (String.isNotBlank(vals.clientRorcPast) ? vals.clientRorcPast + ' %' : '') + '</td>'
            + '<td style="' + styles.sSubTdLeft + '"><span style="' + styles.sSubLabelLeft + '">YTD' + vals.currentYear + '</span>' + (String.isNotBlank(vals.clientRorcYtd) ? vals.clientRorcYtd + ' %' : '') + '</td>'
            + '</tr></table>'
            + '</td>'
            + (isLocal ? '' : '<td style="' + styles.sTdLeft + '">' + vals.rorcProspective + '</td>')
            + '</tr>';

        if (!isLocal) {
            html += '<tr><td colspan="3" style="padding-top: 10px;"></td></tr>'
                + '<tr>'
                + '<td style="' + styles.sThLeft  + '">Client CDD Avge 6M</td>'
                + '<td style="' + styles.sThCenter + '">Deal Revenues Next 12m</td>'
                + '<td colspan="2" style="' + styles.sThLeft + '">Exception Pool</td>'
                + '</tr>'
                + '<tr>'
                + '<td style="' + styles.sTdLeft  + '">' + (String.isNotBlank(vals.clientCddAvg6M) ? vals.clientCddAvg6M + ' %' : '') + '</td>'
                + '<td style="' + styles.sTdCenter + '">' + (String.isNotBlank(vals.dealRevenues) ? vals.dealRevenues + ' %' : '') + '</td>'
                + '<td colspan="2" style="' + styles.sTdLeft + '">' + vals.exceptionPool + '</td>'
                + '</tr>'
                + '<tr><td colspan="3" style="padding-top: 10px;"></td></tr>'
                + '<tr>'
                + '<td></td>'
                + '</tr>';
        }

        html += '</table>'
            + '</div>';
        return html;
    }
}