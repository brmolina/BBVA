public with sharing class DMT_TreasuryProductsRenderer_PE implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line == null || data.lineProductList == null) {
            return '';
        }
        List<DMT_Risk_Line_Term__c> riskLineDerivatesList = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> riskLineDeposList = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> riskLineSingularList = new List<DMT_Risk_Line_Term__c>();
        System.debug('DMT_TreasuryProductsRenderer_CO renderHtml data, '+ JSON.serialize(data));
        for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
            if (riskLine.DMT_Risk_Type__c == 'Derivatives' && riskLine.DMT_Singular__c == false) {
                riskLineDerivatesList.add(riskLine);
            } else if (riskLine.DMT_Risk_Type__c == 'Derivatives' && riskLine.DMT_Singular__c == true){
                riskLineSingularList.add(riskLine);
            }  else if (riskLine.DMT_Risk_Type__c == 'Depos') {
                riskLineDeposList.add(riskLine);
            }
        }
        String table = '<div>'
            + '<h2 style="font-size: 18px; color: #004481; margin-bottom: 10px; font-weight: bold">PRODUCTS</h2>'
            + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
            + '<tr>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Delivery versus Payment (DvP) Amount:</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(data.line.DvP_Amount__c, data.line.CurrencyIsoCode) + '</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Free Delivery (FD) Amount:</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(data.line.FD_Amount__c, data.line.CurrencyIsoCode) + '</td>'
            + '</tr>'
            + '</table>'
            + '</div>'
            + '&nbsp;</br>';

        if (!riskLineDerivatesList.isEmpty()) {
            table += '<div>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                + '<td colspan="3" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>COUNTERPARTY RISK (DERIVATIVES RISK LINE)</strong></td>'
                + '</tr>'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>INIT TERM</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>END TERM</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>AMOUNT</strong></td>'
                + '</tr>';
            for (DMT_Risk_Line_Term__c riskLineDerivate : riskLineDerivatesList) {
                table += '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDerivate.DMT_Init_Term__c)) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDerivate.DMT_End_Term__c)) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(riskLineDerivate.DMT_Amount__c, data.line.CurrencyIsoCode) + '</td>'
                    + '</tr>';
            }
            table += '</table></div>&nbsp;</br>';
        }

        table += '<div>'
        + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
        + '<tr>'
        + '<td colspan="5" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>ONE-OFF-TRANSACTION</strong></td>'
        + '</tr>'
        + '<tr>'
        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TRANSACTION</strong></td>'
        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>AMOUNT</strong></td>'
        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>TERM</strong></td>'
        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>MAX DATE</strong></td>'
        + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>ACTIVE</strong></td>'
        + '</tr>';
        if (!riskLineSingularList.isEmpty()) {
            for (DMT_Risk_Line_Term__c riskLine : riskLineSingularList) {
                System.debug('DMT_TreasuryPrductsRenderer_CO renderHtml riskLine.DMT_Max_Date__c, '+ riskLine.DMT_Max_Date__c);
                System.debug('DMT_TreasuryPrductsRenderer_CO renderHtml DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c), '+ DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c));
                System.debug('DMT_TreasuryPrductsRenderer_CO renderHtml DMT_FormattingUtils.changeDateFormat(DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c)), '+ DMT_FormattingUtils.changeDateFormat(DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c)));
                String active = riskLine.DMT_Singular_Active__c ? 'Yes' : 'No';
                table += '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(riskLine.DMT_Singular_Operation__c) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, riskLine.CurrencyIsoCode) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(riskLine.DMT_Term__c) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.changeDateFormat(DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c)) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + active + '</td>'
                    + '</tr>';
            }
        }
        table += '</table></div>&nbsp;</br>';

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
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                    + '<td colspan="3" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>DEPOS RISK LINE (ONLY FOR FINANCIAL INSTITUTIONS)</strong></td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>INIT TERM</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>END TERM</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>AMOUNT</strong></td>'
                    + '</tr>';
                for (DMT_Risk_Line_Term__c riskLineDepos : riskLineDeposList) {
                    table += '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDepos.DMT_Init_Term__c)) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDepos.DMT_End_Term__c)) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(riskLineDepos.DMT_Amount__c, data.line.CurrencyIsoCode) + '</td>'
                        + '</tr>';
                }
                table += '</table></div>&nbsp;</br>';
            }
        }

        if (!data.lineProductList.isEmpty()) {
            table += '<div>'
                + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                + '<tr>'
                + '<td colspan="5" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>OPERATIONAL RESTRICTIONS</strong></td>'
                + '</tr>'
                + '<tr>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>PRODUCT GROUP</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DERIVATIVES LINE</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>MATURITY TERM</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>FD LINE: (0 ' + DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode) + ')</strong></td>'
                + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>DVP LINE: (0 ' + DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode) + ')</strong></td>'
                + '</tr>';
            for (DMT_Line_Product_Item__c lineProduct : data.lineProductList) {
                table += '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(lineProduct.Name) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><div class="checkbox">' + (lineProduct.DMT_DerivativeRestriction__c ? '&#10003;' : '') + '</div></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(lineProduct.Max_Tenor_WC__c)) + '</td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><div class="checkbox">' + (lineProduct.DMT_FDRestriction__c ? '&#10003;' : '') + '</div></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><div class="checkbox">' + (lineProduct.DMT_DVPRestriction__c ? '&#10003;' : '') + '</div></td>'
                    + '</tr>';
            }
            table += '</table></div>&nbsp;</br>';
        }
        return table;
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line == null || data.lineProductList == null) {
            return new Map<String, Object>();
        }

        Map<String, List<DMT_Risk_Line_Term__c>> sortedRiskLines = sortRiskLines(data.riskLineList);
        List<DMT_Risk_Line_Term__c> riskLineDerivatesList = sortedRiskLines.get('DerivativesNonSingular');
        List<DMT_Risk_Line_Term__c> riskLineSingularList = sortedRiskLines.get('DerivativesSingular');
        List<DMT_Risk_Line_Term__c> riskLineDeposList = sortedRiskLines.get('Depos');

        List<Object> contentListProduct = new List<Object>();
        Map<String, Object> pageBreak = createPageBreak();

        contentListProduct.add(pageBreak);
        contentListProduct.add(DMT_Create_Pdf_Controller.createTitle('PRODUCTS'));
        contentListProduct.addAll(createProductTexts(data));

        contentListProduct.add(pageBreak);
        addTitleSection(contentListProduct, 'COUNTERPARTY RISK (DERIVATIVES RISK LINE)');
        contentListProduct.add(createDerivativesTable(riskLineDerivatesList, data.line.CurrencyIsoCode));

        contentListProduct.add(pageBreak);
        addTitleSection(contentListProduct, 'ONE-OFF-TRANSACTION');
        contentListProduct.add(createSingularTable(riskLineSingularList));

        Boolean hasDepos = false;
        if (!riskLineDeposList.isEmpty() && hasPositiveDepos(riskLineDeposList)) {
            hasDepos = true;
        }
        if(hasDepos){
            contentListProduct.add(pageBreak);
            addTitleSection(contentListProduct, 'DEPOS RISK LINE (ONLY FOR FINANCIAL INSTITUTIONS)');
            contentListProduct.add(createDeposTable(riskLineDeposList, data.line.CurrencyIsoCode));
        }

        contentListProduct.add(pageBreak);
        addTitleSection(contentListProduct, 'OPERATIONAL RESTRICTIONS');
        contentListProduct.add(createRestrictionsTable(data.lineProductList, data.line.CurrencyIsoCode));

        Map<String, Object> componentProduct = new Map<String, Object>{
            'content' => contentListProduct,
            'name' => 'PRODUCTS'
        };

        return componentProduct;
    }

    private Map<String, List<DMT_Risk_Line_Term__c>> sortRiskLines(List<DMT_Risk_Line_Term__c> riskLineList) {
        List<DMT_Risk_Line_Term__c> derivativesNonSingular = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> derivativesSingular = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> depos = new List<DMT_Risk_Line_Term__c>();

        if (!riskLineList.isEmpty()) {
            for (DMT_Risk_Line_Term__c riskLine : riskLineList) {
                if (riskLine.DMT_Risk_Type__c == 'Derivatives' && riskLine.DMT_Singular__c == false) {
                    derivativesNonSingular.add(riskLine);
                } else if (riskLine.DMT_Risk_Type__c == 'Derivatives' && riskLine.DMT_Singular__c == true) {
                    derivativesSingular.add(riskLine);
                } else if (riskLine.DMT_Risk_Type__c == 'Depos') {
                    depos.add(riskLine);
                }
            }
        }

        return new Map<String, List<DMT_Risk_Line_Term__c>>{
            'DerivativesNonSingular' => derivativesNonSingular,
            'DerivativesSingular' => derivativesSingular,
            'Depos' => depos
        };
    }

    private Map<String, Object> createPageBreak() {
        return new Map<String, Object>{
            'type' => 'pageBreak',
            'threshold' => 30
        };
    }

    private List<Object> createProductTexts(DMT_ViewController.LineDataWrapper data) {
        List<Object> texts = new List<Object>();

        List<String> name = new List<String>{
            'Delivery vs Payment (DvP) Amount:',
            'Free Delivery (FD) Amount (Units EUR):'
        };
        List<String> value = new List<String>{
            DMT_FormattingUtils.formatCurrencyAmount(data.line.DvP_Amount__c, data.line.CurrencyIsoCode),
            DMT_FormattingUtils.formatCurrencyAmount(data.line.FD_Amount__c, data.line.CurrencyIsoCode)
        };
        texts.add(DMT_Create_Pdf_Controller.createListText(name, value, ''));

        return texts;
    }

    private void addTitleSection(List<Object> content, String title) {
        List<Object> titleSection = DMT_Create_Pdf_Controller.createTitleSection(title);
        content.add(titleSection[0]);
        content.add(titleSection[1]);
    }

    private Map<String, Object> createDerivativesTable(List<DMT_Risk_Line_Term__c> riskLines, String currencyValue) {
        List<List<String>> body = new List<List<String>>();
        for (DMT_Risk_Line_Term__c riskLine : riskLines) {
            List<String> row = new List<String>{
                DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLine.DMT_Init_Term__c)),
                DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLine.DMT_End_Term__c)),
                DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, currencyValue)
            };
            body.add(row);
        }

        return createTable(
            new List<List<String>>{new List<String>{'INIT TERM', 'END TERM', 'AMOUNT'}},
            body
        );
    }

    private Map<String, Object> createSingularTable(List<DMT_Risk_Line_Term__c> riskLines) {
        List<List<String>> body = new List<List<String>>();
        for (DMT_Risk_Line_Term__c riskLine : riskLines) {
            List<String> row = new List<String>{
                DMT_FormattingUtils.checkNull(riskLine.DMT_Singular_Operation__c),
                DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, riskLine.CurrencyIsoCode),
                DMT_FormattingUtils.checkNull(riskLine.DMT_Term__c),
                DMT_FormattingUtils.changeDateFormat(DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c)),
                riskLine.DMT_Singular_Active__c ? 'Yes' : 'No'
            };
            body.add(row);
        }

        return createTable(
            new List<List<String>>{new List<String>{'TRANSACTION', 'AMOUNT', 'TERM', 'MAX DATE', 'ACTIVE'}},
            body
        );
    }

    private Boolean hasPositiveDepos(List<DMT_Risk_Line_Term__c> riskLines) {
        for (DMT_Risk_Line_Term__c riskLine : riskLines) {
            if (riskLine.DMT_Amount__c != null && riskLine.DMT_Amount__c > 0) {
                return true;
            }
        }
        return false;
    }

    private Map<String, Object> createDeposTable(List<DMT_Risk_Line_Term__c> riskLines, String currencyValue) {
        List<List<String>> body = new List<List<String>>();
        for (DMT_Risk_Line_Term__c riskLine : riskLines) {
            List<String> row = new List<String>{
                DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLine.DMT_Init_Term__c)),
                DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLine.DMT_End_Term__c)),
                DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, currencyValue)
            };
            body.add(row);
        }

        return createTable(
            new List<List<String>>{new List<String>{'INIT TERM', 'END TERM', 'AMOUNT'}},
            body
        );
    }

    private Map<String, Object> createRestrictionsTable(List<DMT_Line_Product_Item__c> lineProducts, String currencyValue) {
        List<List<String>> body = new List<List<String>>();
        for (DMT_Line_Product_Item__c lineProduct : lineProducts) {
            List<String> row = new List<String>{
                DMT_FormattingUtils.checkNull(lineProduct.Name),
                lineProduct.DMT_DerivativeRestriction__c ? '3' : '',
                DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(lineProduct.Max_Tenor_WC__c)),
                lineProduct.DMT_FDRestriction__c ? '3' : '',
                lineProduct.DMT_DVPRestriction__c ? '3' : ''
            };
            body.add(row);
        }

        Map<String, Object> table = createTable(
            new List<List<String>>{new List<String>{'PRODUCT GROUP', 'DERIVATIVES LINE', 'MATURITY TERM', 'FD LINE: (0 ' + DMT_FormattingUtils.checkNull(currencyValue) + ')', 'DVP LINE: (0 ' + DMT_FormattingUtils.checkNull(currencyValue) + ')'}},
            body
        );

        Map<String, Object> columnStyles = new Map<String, Object>{
            '0' => new Map<String, Object>{'halign' => 'left'},
            '1' => new Map<String, Object>{'halign' => 'center', 'font' => 'Zapfdingbats'},
            '2' => new Map<String, Object>{'halign' => 'left'},
            '3' => new Map<String, Object>{'halign' => 'center', 'font' => 'Zapfdingbats'},
            '4' => new Map<String, Object>{'halign' => 'center', 'font' => 'Zapfdingbats'}
        };
        table.put('columnStyles', columnStyles);

        return table;
    }

    private Map<String, Object> createTable(List<List<String>> headers, List<List<String>> body) {
        Map<String, Object> table = new Map<String, Object>{
            'type' => 'table',
            'head' => headers,
            'body' => body,
            'style' => getTableStyles(),
            'headStyles' => getHeadStyles(),
            'margin' => getMarginTable()
        };
        return table;
    }

    private Map<String, Object> getTableStyles() {
        Map<String, Object> styles = new Map<String, Object>{
            'fontSize' => 8,
            'lineWidth' => new Map<String, Object>{'bottom' => 0.1}
        };
        return styles;
    }

    private Map<String, Object> getHeadStyles() {
        return new Map<String, Object>{'fontSize' => 8};
    }

    private Map<String, Object> getMarginTable() {
        return new Map<String, Object>{
            'top' => 0,
            'bottom' => 1
        };
    }
}