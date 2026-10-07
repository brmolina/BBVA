/**
 * Shared data-prep and table-building logic for DMT_NBC_OppOtherAspectRenderer_IBF and
 * DMT_NBC_OppOtherAspectRenderer_GTB.
 *
 * NOTE: buildHtmlGTBAdditionalTable/createHtmlGTBRow/buildTextCheckboxWithFullLine, and the
 * hasFloorClause/floorClauseComment/cddStandaloneRorcRaroec/cddClientGlobalRorc/aaIndustry/
 * sourceAndUses fields (plus the ProfitabilityContext machinery that feeds cddStandaloneRorcRaroec)
 * were already unreferenced (commented out) before this OCP split — preserved as-is rather than
 * removed, since it looks like paused/in-progress work on a fuller GTB "Other Aspects" table.
 */
public with sharing class DMT_NBC_OtherAspectRendererHelper {

    public class ProfitabilityContext {
        public Map<String, Object> summary = new Map<String, Object>();
        public Object rorcThreshold;
        public Object raroecThreshold;
    }

    public class GlobalStructureData {
        public String debtLabel = 'Debt Funds (Mn)';
        public String equityLabel = 'Equity Funds (Mn)';
        public String usesLabel = 'Uses (Mn)';
        public Decimal debtSum = 0;
        public Decimal equitySum = 0;
        public Decimal usesSum = 0;
        public List<DMT_Global_Structure__c> debtRecords = new List<DMT_Global_Structure__c>();
        public List<DMT_Global_Structure__c> equityRecords = new List<DMT_Global_Structure__c>();
        public List<DMT_Global_Structure__c> usesRecords = new List<DMT_Global_Structure__c>();
    }

    public class OtherAspectData {
        public String applicableJurisdiction = '';
        public String securityPackage = '';
        public String ratingScenarios = '';
        public String otherRelevantIssues = '';
        public String competitionDeal = '';
        public String aaIndustry = '';
        public String hasFloorClause = '';
        public String floorClauseComment = '';
        public String cddStandaloneRorcRaroec = '';
        public String cddClientGlobalRorc = '';
        public Integer currentYear;
        public Boolean sourceAndUses = false;
        public GlobalStructureData globalStructure = new GlobalStructureData();
        public Map<String, DMT_Banking_Pool_Structure__c> bankingPoolTierMap = new Map<String, DMT_Banking_Pool_Structure__c>();

        public OtherAspectData(DMT_ViewController.LineDataWrapper data) {
            try {
                this.currentYear = Date.today().year();
                ProfitabilityContext profitabilityContext = DMT_NBC_OtherAspectRendererHelper.getProfitabilityContext(data);

                String dealRorc = '';
                String dealRaroec = '';

                if (!profitabilityContext.summary.isEmpty()) {
                    dealRorc = DMT_NBC_OtherAspectRendererHelper.formatProfitabilityMetric(profitabilityContext.summary.get('rorc'), profitabilityContext.rorcThreshold);
                    dealRaroec = DMT_NBC_OtherAspectRendererHelper.formatProfitabilityMetric(profitabilityContext.summary.get('raroec'), profitabilityContext.raroecThreshold);

                }
                this.applicableJurisdiction = data != null && data.oppClient != null ? DMT_FormattingUtils.checkNull(data.oppClient.DMT_Applicable_Jurisdiction__c) : '';
                this.securityPackage = data != null && data.oppClient != null ? DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Security_Package__c)) : '';
                this.ratingScenarios = data != null && data.oppClient != null ? DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Rating_Scenarios__c)) : '';
                this.otherRelevantIssues = data != null && data.oppClient != null ? DMT_FormattingUtils.toSafeMultilineHtml(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Other_Relevant_Issues__c)): '';
                this.competitionDeal = data != null && data.oppClient != null ? DMT_FormattingUtils.checkNull(data.oppClient.DMT_Competition_Deal__c) : '';
                this.aaIndustry = data != null && data.oppClient != null
                    ? DMT_FormattingUtils.checkNull(Util_Picklist.getLabelFromAPI('DMT_Opportunity_Client__c', 'DMT_Industry__c').get(data.oppClient.DMT_Industry__c))
                    : '';
                this.sourceAndUses = data != null && data.oppClient != null ? (data.oppClient.DMT_SourceAndUses__c == true) : false;
                this.hasFloorClause = '';
                this.floorClauseComment = '';
                this.cddStandaloneRorcRaroec = (String.isNotBlank(dealRorc) || String.isNotBlank(dealRaroec)) ? dealRorc + ' / ' + dealRaroec : '';
                this.cddClientGlobalRorc = 'FY' + (this.currentYear - 1) +' ' + (String.isNotBlank(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Clients_Global_RORC_CIB_Past_FY__c)) ? data.oppClient.DMT_Clients_Global_RORC_CIB_Past_FY__c + ' %' : '')+ ' & ' + 'YTD' + this.currentYear + ' ' +  (String.isNotBlank(DMT_FormattingUtils.checkNull(data.oppClient.DMT_Client_RORC_YTD__c)) ? data.oppClient.DMT_Client_RORC_YTD__c + ' %' : '');
                this.globalStructure = DMT_NBC_OtherAspectRendererHelper.buildGlobalStructuresData(data);
                this.bankingPoolTierMap = DMT_NBC_OtherAspectRendererHelper.buildBankingPoolTierMap(data);
            } catch (Exception e) {
                System.debug('Error in DMT_NBC_OtherAspectRendererHelper OtherAspectData, ' + e.getMessage() + ' ' + e.getLineNumber());
                this.globalStructure = new GlobalStructureData();
                this.bankingPoolTierMap = new Map<String, DMT_Banking_Pool_Structure__c>();
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
        Decimal thresholdDecimal = toDecimalOrNull(thresholdValue);
        String formattedValue = DMT_FormattingUtils.formatPercent(value);
        if (thresholdDecimal == null) {
            return formattedValue;
        }

        Decimal valueDecimal = toDecimalOrNull(value);
        String comparisonSign = valueDecimal == null ? '<'
            : valueDecimal > thresholdDecimal ? '>'
            : valueDecimal < thresholdDecimal ? '<'
            : '=';
        return formattedValue + ' ' + comparisonSign + ' ' + DMT_FormattingUtils.formatPercent(thresholdDecimal);
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
    // IBF-ONLY HTML BUILDERS
    // ====================================================================================================

    public static String buildHtmlOtherAspects(OtherAspectData vals) {
        String html = '<div style="margin-bottom: 15px; page-break-inside: avoid;">';

        html += '<table style="width: 100%; border-collapse: collapse; margin-bottom: 10px; table-layout: fixed;">'
             + '<tr>'
             + '<td style="width: 35%; padding: 4px 0; color: #004481; font-weight: bold; font-size: 10px;">Applicable jurisdiction</td>'
             + '<td style="width: 65%; padding: 4px 10px; background-color: #F4F4F4; color: #004481; font-size: 9px;">' + vals.applicableJurisdiction + '</td>'
             + '</tr>'
             + '</table>';

        html += createHtmlTextBox('Security Package', '', vals.securityPackage);
        html += createHtmlTextBox('Rating Scenarios', '', vals.ratingScenarios);
        html += createHtmlTextBox('Other relevant issues', '', vals.otherRelevantIssues);

        html += '</div>';
        return html;
    }

    public static String buildHtmlGlobalStructures(GlobalStructureData globalStructure) {
        String html = '<div style="margin-bottom: 15px; page-break-inside: avoid;">'
                    + '<div style="font-size: 13px; color: #004481; font-weight: bold; text-transform: uppercase; margin-bottom: 10px;">GLOBAL STRUCTURE OF THE DEAL</div>'
                    + '<table style="width: 100%; border-collapse: collapse; border: none; table-layout: fixed;">'
                    + '<tr>'
                    + '<td style="width: 48%; vertical-align: top;">';

        html += buildHtmlSubTable('Debt', globalStructure.debtLabel, globalStructure.debtRecords, globalStructure.debtSum, 4);
        html += '<div style="height: 10px;"></div>';
        html += buildHtmlSubTable('Equity', globalStructure.equityLabel, globalStructure.equityRecords, globalStructure.equitySum, 4);

        html += '</td>'
             + '<td style="width: 4%;"></td>'
             + '<td style="width: 48%; vertical-align: top;">';

        html += buildHtmlSubTable('', globalStructure.usesLabel, globalStructure.usesRecords, globalStructure.usesSum, 9);

        html += '</td></tr></table></div>';
        return html;
    }

    private static String buildHtmlSubTable(String sideLabel, String topLabel, List<DMT_Global_Structure__c> records, Decimal totalSum, Integer numRows) {
        String html = '<table style="width: 100%; border-collapse: collapse; border: none; table-layout: fixed;"><tr>';

        if (String.isNotBlank(sideLabel)) {
            html += '<td style="width: 15%; color: #004481; font-weight: bold; font-size: 10px; text-align: left; vertical-align: middle;">' + sideLabel + '</td>';
        }

        html += '<td style="width: ' + (String.isNotBlank(sideLabel) ? '85%' : '100%') + '; vertical-align: top;">'
             + '<div style="text-align: center; color: #004481; font-weight: bold; font-size: 10px; margin-bottom: 4px;">' + topLabel + '</div>'
             + '<table style="width: 100%; border-collapse: collapse; table-layout: fixed;">'
             + '<colgroup><col style="width: 70%;"><col style="width: 30%;"></colgroup>';

        String cellStyle = 'background-color: #F4F4F4; border: 1px solid #ffffff; padding: 4px 8px; color: #004481; font-size: 10px; text-align: right; height: 16px;';

        for (Integer i = 0; i < numRows; i++) {
            String name = '';
            String val = '';
            if (i < records.size()) {
                name = getDisplayName(records[i].Name, records[i].Id);
                val = String.valueOf(records[i].DMT_Funds__c != null ? records[i].DMT_Funds__c : 0);
            }
            html += '<tr>'
                 + '<td style="' + cellStyle + '">' + name + '</td>'
                 + '<td style="' + cellStyle + '">' + val + '</td>'
                 + '</tr>';
        }

        html += '<tr>'
             + '<td style="' + cellStyle + ' font-weight: bold; text-align: center;">Total</td>'
             + '<td style="' + cellStyle + ' font-weight: bold;">' + String.valueOf(totalSum != null ? totalSum : 0) + '</td>'
             + '</tr>'
             + '</table>'
             + '</td></tr></table>';

        return html;
    }

    public static String buildHtmlBankingPoolStructure(Map<String, DMT_Banking_Pool_Structure__c> tierMap) {
        List<String> tiers = new List<String>{ 'Tier 1', 'Tier 2', 'Tier 3', 'Tier 4 or above' };

        String html = '<div style="margin-bottom: 15px; font-family: Arial, sans-serif; page-break-inside: avoid;">'
            + '<div style="font-size: 13px; color: #004481; font-weight: bold; text-transform: uppercase; margin-bottom: 6px;">BANKING POOL STRUCTURE*</div>'
            + '<table style="width:100%; border-collapse: collapse; table-layout: fixed; border: none;">'
            + '<colgroup><col style="width: 15%;"><col style="width: 21.25%;"><col style="width: 21.25%;"><col style="width: 21.25%;"><col style="width: 21.25%;"></colgroup>'
            + '<tr>'
            + '<td style="border: none;"></td>'
            + '<td style="padding: 4px; border: none; color: #004481; font-weight: bold; font-size: 11px; text-align: center;">Ticket (Mn)</td>'
            + '<td style="padding: 4px; border: none; color: #004481; font-weight: bold; font-size: 11px; text-align: center;">Fees</td>'
            + '<td style="padding: 4px; border: none; color: #004481; font-weight: bold; font-size: 11px; text-align: center;">Margin</td>'
            + '<td style="padding: 4px; border: none; color: #004481; font-weight: bold; font-size: 11px; text-align: center;">Nº banks</td>'
            + '</tr>';

        for (String tier : tiers) {
            DMT_Banking_Pool_Structure__c row = tierMap.get(tier);

            String valTicket = DMT_FormattingUtils.checkNull(row != null ? row.DMT_Ticket__c : null);
            String valFees = DMT_FormattingUtils.checkNull(row != null ? row.DMT_Fees__c : null);
            String valMargin = DMT_FormattingUtils.checkNull(row != null ? row.DMT_Margin__c : null);
            String valBanks = DMT_FormattingUtils.checkNull(row != null ? row.DMT_N_Banks__c : null);

            html += '<tr>'
                + '<td style="padding: 4px 8px 4px 0; border: none; color: #004481; font-size: 11px; font-weight: bold; text-align: right;">' + tier + '</td>'
                + '<td style="padding: 4px 8px; background-color: #F4F4F4; border: 1px solid #ffffff; font-size: 11px; color: #004481; text-align: right;">' + valTicket + '</td>'
                + '<td style="padding: 4px 8px; background-color: #F4F4F4; border: 1px solid #ffffff; font-size: 11px; color: #004481; text-align: right;">' + valFees + '</td>'
                + '<td style="padding: 4px 8px; background-color: #F4F4F4; border: 1px solid #ffffff; font-size: 11px; color: #004481; text-align: right;">' + valMargin + '</td>'
                + '<td style="padding: 4px 8px; background-color: #F4F4F4; border: 1px solid #ffffff; font-size: 11px; color: #004481; text-align: right;">' + valBanks + '</td>'
                + '</tr>';
        }

        html += '</table></div>';
        return html;
    }

    private static GlobalStructureData buildGlobalStructuresData(DMT_ViewController.LineDataWrapper data) {
        GlobalStructureData globalStructure = new GlobalStructureData();

        if (data != null && data.opportunity != null && data.opportunity.Global_Structures__r != null && !data.opportunity.Global_Structures__r.isEmpty()) {
            Schema.DescribeFieldResult fieldResult = DMT_Global_Structure__c.DMT_Type__c.getDescribe();
            Map<String, String> apiToLabel = new Map<String, String>();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                apiToLabel.put(entry.getValue(), entry.getLabel());
            }
            globalStructure.debtLabel = apiToLabel.get('Funding Debt') != null ? apiToLabel.get('Funding Debt') : 'Debt Funds (Mn)';
            globalStructure.equityLabel = apiToLabel.get('Funding Equity') != null ? apiToLabel.get('Funding Equity') : 'Equity Funds (Mn)';
            globalStructure.usesLabel = apiToLabel.get('Uses') != null ? apiToLabel.get('Uses') : 'Uses (Mn)';

            for (DMT_Global_Structure__c gs : data.opportunity.Global_Structures__r) {
                Decimal funds = gs.DMT_Funds__c != null ? gs.DMT_Funds__c : 0;
                if (gs.DMT_Type__c == 'Funding Debt') {
                    globalStructure.debtRecords.add(gs);
                    globalStructure.debtSum += funds;
                } else if (gs.DMT_Type__c == 'Funding Equity') {
                    globalStructure.equityRecords.add(gs);
                    globalStructure.equitySum += funds;
                } else if (gs.DMT_Type__c == 'Uses') {
                    globalStructure.usesRecords.add(gs);
                    globalStructure.usesSum += funds;
                }
            }
        }

        return globalStructure;
    }

    private static Map<String, DMT_Banking_Pool_Structure__c> buildBankingPoolTierMap(DMT_ViewController.LineDataWrapper data) {
        Map<String, DMT_Banking_Pool_Structure__c> tierMap = new Map<String, DMT_Banking_Pool_Structure__c>();
        if (data == null || data.bankingPoolStructures == null) {
            return tierMap;
        }

        for (DMT_Banking_Pool_Structure__c row : data.bankingPoolStructures) {
            tierMap.put(row.Name, row);
        }

        return tierMap;
    }

    private static Boolean isTechnicalName(String value, Id recordId) {
        if (String.isBlank(value)) {
            return false;
        }

        String trimmedValue = value.trim();

        if (recordId != null && trimmedValue == String.valueOf(recordId)) {
            return true;
        }

        return Pattern.matches('^[a-zA-Z0-9]{15,18}$', trimmedValue);
    }

    private static String getDisplayName(String value, Id recordId) {
        return isTechnicalName(value, recordId) ? '' : DMT_FormattingUtils.checkNull(value);
    }

    public static String createHtmlTextBox(String title, String helper, String content) {
        return '<div style="margin-bottom: 10px;">'
             + '<div style="margin-bottom: 2px;">'
             + '<span style="color: #004481; font-weight: bold; font-size: 9px;">' + title + '</span>'
             + '<span style="color: #888888; font-style: italic; font-size: 8px; margin-left: 10px;">' + helper + '</span>'
             + '</div>'
             + '<div style="background-color: #F4F4F4; padding: 8px 10px; color: #004481; font-size: 9px; min-height: 15px; white-space: normal; word-wrap: break-word; overflow-wrap: anywhere; word-break: break-word;">'
             + content
             + '</div>'
             + '</div>';
    }

    // ====================================================================================================
    // GTB-ONLY HTML BUILDERS
    // ====================================================================================================

    public static String buildHtmlOtherAspectsGTB(OtherAspectData vals) {
        String html = '<div style="margin-bottom: 15px;">';

        html += '<div style="font-size: 10px; color: #004481; font-weight: bold; text-transform: uppercase; margin-bottom: 3px;">OTHER ASPECTS</div>';

        /*         html += buildHtmlGTBAdditionalTable(vals);

        html += buildTextCheckboxWithFullLine('Source and Uses', vals.sourceAndUses);
        html += createHtmlTextBox('Security Package', '', vals.securityPackage); */
        html += createHtmlTextBox('Other relevant issues', '', vals.otherRelevantIssues);

        html += '</div>';
        return html;
    }

    private static String buildHtmlGTBAdditionalTable(OtherAspectData vals) {
        String html = '<table style="width: 100%; border-collapse: separate; border-spacing: 0 3px; table-layout: fixed; margin-bottom: 10px;">'
            + '<colgroup>'
            + '<col style="width: 25%;">'
            + '<col style="width: 75%;">'
            + '</colgroup>'
            + createHtmlGTBRow('Has Floor Clause', vals.hasFloorClause)
            + createHtmlGTBRow('Floor Clause Comment', vals.floorClauseComment)
            + createHtmlGTBRow('AA Industry', vals.aaIndustry)
            + createHtmlGTBRow('CDD Standalone RORC/RAROEC', vals.cddStandaloneRorcRaroec)
            + createHtmlGTBRow('CDD Client\'s Global RORC FY25 & YTD26', vals.cddClientGlobalRorc)
            + '</table>';

        return html;
    }

    private static String createHtmlGTBRow(String label, String value) {
        String safeValue = String.isBlank(value) ? ' ' : value;
        return '<tr>'
            + '<td style="font-size: 8px;color: #004481; padding: 6px 10px 6px 20px; vertical-align: middle;">' + label + '</td>'
            + '<td style="font-size: 8px; background-color: #f2f2f2; color: #004481; padding: 6px 10px; vertical-align: middle;">' + safeValue + '</td>'
            + '</tr>';
    }

    private static String buildTextCheckboxWithFullLine(String label, Boolean checked) {
        String checkbox = checked
            ? '<span style="display:inline-block; width:12px; height:12px; border:1px solid #004481; color:#004481; text-align:center; line-height:12px; font-size:10px; font-weight:bold; vertical-align:middle; margin-left:10px;">&#10003;</span>'
            : '<span style="display:inline-block; width:12px; height:12px; border:1px solid #004481; vertical-align:middle; margin-left:10px;"></span>';

        return '<div style="width: 100%;">'
            + '<span style="color: #004481;font-size: 9px; font-weight: bold; vertical-align: middle;">' + label + '</span> '
            + checkbox
            + '<div style="width: 100%; border-top: 1px solid #004481; margin-top: 4px;"></div>'
            + '</div>';
    }
}