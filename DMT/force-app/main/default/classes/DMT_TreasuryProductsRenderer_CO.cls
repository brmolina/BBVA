public with sharing class DMT_TreasuryProductsRenderer_CO implements DMT_ViewRenderer {
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

        List<Object> titleSection = new List<Object>();
        List<DMT_Risk_Line_Term__c> riskLineDerivatesList = new List<DMT_Risk_Line_Term__c >();
        List<DMT_Risk_Line_Term__c> riskLineSingularList = new List<DMT_Risk_Line_Term__c>();
        System.debug('DMT_TreasuryProductsRenderer_CO renderPdfJson data, '+ JSON.serialize(data));
        if(!data.riskLineList.isEmpty()){
            for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
                if(riskLine.DMT_Risk_Type__c == 'Derivatives' && riskLine.DMT_Singular__c == false){
                    riskLineDerivatesList.add(riskLine);
                }
                if (riskLine.DMT_Risk_Type__c == 'Derivatives' && riskLine.DMT_Singular__c == true){
                    riskLineSingularList.add(riskLine);
                }
            }
        }
        List<Object> contentListProduct= new List<Object>();
        Map<String, Object> componentProduct = new Map<String, Object>();

        // Add a page break before
        Map<String, Object> pageBreak = new Map<String, Object>{
            'type' => 'pageBreak',
            'threshold' => 30
        };
        
        contentListProduct.add(pageBreak);

        //TITLE PROECESS DARA
        contentListProduct.add(DMT_Create_Pdf_Controller.createTitle('PRODUCTS'));
        //CREATE COMPONENT TEXT PRODUCT
        Map<String, Object> textProduct = new Map<String, Object>();
        List<String> name = new List<String>();
        List<String> value = new List<String>();   
            name.add('Delivery vs Payment (DvP) Amount:');
            value.add(DMT_FormattingUtils.formatCurrencyAmount(data.line.DvP_Amount__c, data.line.currencyIsoCode));
            name.add('Free Delivery (FD) Amount (Units EUR):');
            value.add(DMT_FormattingUtils.formatCurrencyAmount(data.line.FD_Amount__c, data.line.CurrencyIsoCode));
        //Table than create the text content
        textProduct = DMT_Create_Pdf_Controller.createListText(name, value, '');
        contentListProduct.add(textProduct);
        //CREATE COMPONENT TEXT PRODUCT LONG
        List<String> nameLong = new List<String>();
        List<String> valueLong = new List<String>();
            nameLong.add('Additional Products:');
            valueLong.add(DMT_FormattingUtils.checkNull(data.line.DMT_Additional_Restrictions__c));
        contentListProduct.add(DMT_Create_Pdf_Controller.createListText(nameLong, valueLong, 'ONE'));

        //TABLE STYLE
        Map<String, Object> stylesTable = new Map<String, Object>();
            stylesTable.put('fontSize', 8);
        Map<String, Object> marginTable = new Map<String, Object>();
            marginTable.put('top', 0);
            marginTable.put('bottom',1);
        Map<String, Object> lineWidthItem = new Map<String, Object>();
            lineWidthItem.put('bottom',0.1);
            stylesTable.put('lineWidth',lineWidthItem);
        Map<String, Object> headStyles= new Map<String, Object>();
            headStyles.put('fontSize', 8);
        //CREATE TABLE SECTION COUNTERPARTY RISK (DERIVATIVES RISK LINE)
        Map<String, Object> tableComponentCounteparty = new Map<String, Object>();
        List<List<String>> headersCounteparty = new List<List<String>>();
        List<String> listHeadersCounteparty = new List<String>{'INIT TERM', 'END TERM', 'AMOUNT'};
        headersCounteparty.add(listHeadersCounteparty);     
        List<List<String>> bodyCounteparty = new List<List<String>>();
        for (DMT_Risk_Line_Term__c riskLineDerivate : riskLineDerivatesList) {
                List<String> row = new List<String>();
                row.add(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDerivate?.DMT_Init_Term__c)));
                row.add(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDerivate?.DMT_End_Term__c)));
                row.add(DMT_FormattingUtils.formatCurrencyAmount(riskLineDerivate?.DMT_Amount__c, data.line.CurrencyIsoCode));
                bodyCounteparty.add(row);
        }
        
        contentListProduct.add(pageBreak);

        titleSection = DMT_Create_Pdf_Controller.createTitleSection('COUNTERPARTY RISK (DERIVATIVES RISK LINE)');
        contentListProduct.add(titleSection[0]);
        contentListProduct.add(titleSection[1]);
        tableComponentCounteparty.put('margin',marginTable);
        tableComponentCounteparty.put('headStyles', headStyles);
        tableComponentCounteparty.put('style', stylesTable);
        tableComponentCounteparty.put('body', bodyCounteparty);
        tableComponentCounteparty.put('head', headersCounteparty);
        tableComponentCounteparty.put('type', 'table');
        contentListProduct.add(tableComponentCounteparty);
        //CREATE TABLE SECTION ONE-OFF TRANSACTION
            Map<String, Object> tableComponentSingular = new Map<String, Object>();
            List<List<String>> headersSingular = new List<List<String>>{new List<String>{'TRANSACTION', 'AMOUNT', 'TERM', 'MAX DATE', 'ACTIVE'}};
            List<List<String>> bodySingular = new List<List<String>>();
            for (DMT_Risk_Line_Term__c riskLine : riskLineSingularList) {
                List<String> row = new List<String>{
                    DMT_FormattingUtils.checkNull(riskLine.DMT_Singular_Operation__c),
                    DMT_FormattingUtils.formatCurrencyAmount(riskLine.DMT_Amount__c, riskLine.CurrencyIsoCode),
                    DMT_FormattingUtils.checkNull(riskLine.DMT_Term__c),
                    DMT_FormattingUtils.changeDateFormat(DMT_FormattingUtils.checkNull(riskLine.DMT_Max_Date__c)),
                    riskLine.DMT_Singular_Active__c ? 'Yes' : 'No'
                };
                bodySingular.add(row);
            }
            tableComponentSingular.put('type', 'table');
            tableComponentSingular.put('head', headersSingular);
            tableComponentSingular.put('body', bodySingular);
            tableComponentSingular.put('style', stylesTable);
            tableComponentSingular.put('headStyles', headStyles);
            tableComponentSingular.put('margin', stylesTable.get('margin'));
            
            contentListProduct.add(pageBreak);
            titleSection = DMT_Create_Pdf_Controller.createTitleSection('ONE-OFF-TRANSACTION');
            contentListProduct.add(titleSection[0]);
            contentListProduct.add(titleSection[1]);
            contentListProduct.add(tableComponentSingular);
        //CREATE TABLE SECTION OPERATIONAL RESTRICTIONS
        List<List<String>> headersRestrictions = new List<List<String>>();
        List<String> listHeadersRestrictions  = new List<String>{'PRODUCT GROUP', 'DERIVATIVES LINE', 'MATURITY TERM', 'FD LINE: (0 '+DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode)+')', 'DVP LINE: (0 '+DMT_FormattingUtils.checkNull(data.line.CurrencyIsoCode)+')'};     
        headersRestrictions.add(listHeadersRestrictions);
        Map<String, Object> tableComponentRestrictions = new Map<String, Object>();
        List<List<String>> bodyRestrictions  = new List<List<String>>();
        for (DMT_Line_Product_Item__c lineProduct : data.lineProductList) {
                List<String> row = new List<String>();
                row.add(DMT_FormattingUtils.checkNull(lineProduct?.Name));
                row.add(lineProduct?.DMT_DerivativeRestriction__c ? '3' : '');
                row.add(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(lineProduct?.Max_Tenor_WC__c)));
                row.add(lineProduct?.DMT_FDRestriction__c ? '3' : '');
                row.add(lineProduct?.DMT_DVPRestriction__c ? '3' : '');
                bodyRestrictions.add(row);
        } 
        Map<String, Object> columnStyles= new Map<String, Object>();
        Map<String, Object> column4= new Map<String, Object>();
            column4.put('halign', 'center');
            column4.put('font', 'Zapfdingbats');
            columnStyles.put('4', column4);
        Map<String, Object> column3= new Map<String, Object>();
            column3.put('halign', 'center');
            column3.put('font', 'Zapfdingbats');
            columnStyles.put('3', column3);
        Map<String, Object> column2= new Map<String, Object>();
            column2.put('halign', 'left');
            columnStyles.put('2', column2);
        Map<String, Object> column1= new Map<String, Object>();
            column1.put('halign', 'center');
            column1.put('font', 'Zapfdingbats');
            columnStyles.put('1', column1);
        Map<String, Object> column0= new Map<String, Object>();
            column0.put('halign', 'left');
            columnStyles.put('0', column0);
        
        contentListProduct.add(pageBreak);
        
        titleSection = DMT_Create_Pdf_Controller.createTitleSection('OPERATIONAL RESTRICTIONS');
        contentListProduct.add(titleSection[0]);
        contentListProduct.add(titleSection[1]);
        tableComponentRestrictions.put('margin',marginTable);
        tableComponentRestrictions.put('columnStyles', columnStyles);
        tableComponentRestrictions.put('headStyles', headStyles);
        tableComponentRestrictions.put('style', stylesTable);
        tableComponentRestrictions.put('body', bodyRestrictions );
        tableComponentRestrictions.put('head', headersRestrictions );
        tableComponentRestrictions.put('type', 'table');
        contentListProduct.add(tableComponentRestrictions);

        //CREATE TABLE SECTION PRODUCTS
        componentProduct.put('content', contentListProduct);
        componentProduct.put('name', 'PRODUCTS');
               
        return componentProduct;
    }
}