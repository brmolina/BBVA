public without sharing class DMT_OppOtherAspectRenderer implements DMT_ViewRenderer {

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

    // ====================================================================================================
    // HTML RENDERING
    // ====================================================================================================

    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || (data.opportunity.getPopulatedFieldsAsMap().isEmpty() && data.oppClient.getPopulatedFieldsAsMap().isEmpty())) {
            return '<div>Opportunity data not provided</div>';
        }

        try {
            String comparisonAccountName = data.oppAccountParentName;
            String html = '<div>'
                + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">Other Aspects' + (String.isNotBlank(comparisonAccountName) ? ' - ' + comparisonAccountName : '') + '</h2>';

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

            return html;
        } catch (Exception e) {
            System.debug('Error in DMT_OppOtherAspectRenderer renderHtml, ' + e.getMessage() + ' ' + e.getLineNumber());
            return '<div>Error: ' + e.getMessage() + ' - ' + e.getLineNumber() + '</div>';
        }
    }

    private String buildHtmlOtherAspects(DMT_ViewController.LineDataWrapper data) {
        return '<h3 style="font-size: 16px; color: #004481; margin-bottom: 10px;">Other Aspects</h3>'
            + DMT_FormattingUtils.tableRow1column('Applicable jurisdiction',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Applicable_Jurisdiction__c)) + '</br>'
            + DMT_FormattingUtils.tableRow1column('Security Package',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Security_Package__c)) + '</br>'
            + DMT_FormattingUtils.tableRow1column('Rating Scenarios',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Rating_Scenarios__c)) + '</br>'
            + DMT_FormattingUtils.tableRow1column('Other relevant issues',DMT_FormattingUtils.checkNull(data.oppClient.DMT_Other_Relevant_Issues__c)) + '</br>';
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
            html += '<tr><td style="padding: 8px; border-bottom: 1px solid #ccc;">' + getDisplayName(gs.Name, gs.Id) + '</td>'
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