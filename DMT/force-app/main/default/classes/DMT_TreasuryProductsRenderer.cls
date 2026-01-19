public with sharing class DMT_TreasuryProductsRenderer implements DMT_ViewRenderer {
    public String renderHtml(DMT_ViewController.LineDataWrapper data) {
        if (data == null || data.line == null || data.lineProductList == null) {
            return '';
        }
        List<DMT_Risk_Line_Term__c> riskLineDerivatesList = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> riskLineDeposList = new List<DMT_Risk_Line_Term__c>();
        List<DMT_Risk_Line_Term__c> riskLineEquitiesList = new List<DMT_Risk_Line_Term__c>();
        System.debug('DMT_TreasuryProductsRenderer renderHtml data, '+ JSON.serialize(data));
        for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
            if (riskLine.DMT_Risk_Type__c == 'Derivatives') {
                riskLineDerivatesList.add(riskLine);
            } else if (riskLine.DMT_Risk_Type__c == 'Depos') {
                riskLineDeposList.add(riskLine);
            } else if (riskLine.DMT_Risk_Type__c == 'Equities') {
                riskLineEquitiesList.add(riskLine);
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
            + '<tr>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Repos line total(Financing Framework):</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Repos_Limit__c) + '</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Repos line no-flow (&gt;1Y nominal):</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.checkNull(data.line.Repos_Limit_6M__c) + '</td>'
            + '</tr>'
            + '<tr>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>First Breakclause:</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(data.line.First_Breakclause__c)) + '</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>First Breakclause Date:</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.changeDateFormat(DMT_FormattingUtils.checkNull(data.line.First_Breakclause_Date__c)) + '</td>'
            + '</tr>'
            + '<tr>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>ISDA Waiver:</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">'
            + '<div class="checkbox">' + (data.line.Waiver__c ? '&#10003;' : '') + '</div>'
            + '</td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;"><strong>Breakclause Frequency:</strong></td>'
            + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(data.line.Breakclause_Frequency__c)) + '</td>'
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
                    + '<table class="style-table" style="width:100%; border-collapse: collapse;">'
                    + '<tr>'
                    + '<td colspan="3" style="padding: 8px; text-align: center; border-bottom: 1px solid #ccc; background-color: rgb(174, 174, 174); font-size: 16px;"><strong>EQUITIES WWR RISK LINE</strong></td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>INIT TERM</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>END TERM</strong></td>'
                    + '<td style="padding: 8px; border-bottom: 1px solid #ccc; background-color: #F3F3F3;"><strong>AMOUNT</strong></td>'
                    + '</tr>';
                for (DMT_Risk_Line_Term__c riskLineEquities : riskLineEquitiesList) {
                    table += '<tr>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineEquities.DMT_Init_Term__c)) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineEquities.DMT_End_Term__c)) + '</td>'
                        + '<td style="padding: 8px; border-bottom: 1px solid #ccc;">' + DMT_FormattingUtils.formatCurrencyAmount(riskLineEquities.DMT_Amount__c, data.line.CurrencyIsoCode) + '</td>'
                        + '</tr>';
                }
                table += '</table></div>&nbsp;</br>';
            }
        }
        return table;
    }

    public Map<String, Object> renderPdfJson(DMT_ViewController.LineDataWrapper data) {

        if (data == null || data.line == null || data.lineProductList == null) {
            return new Map<String, Object>();
        }

        List<Object> titleSection = new List<Object>();
        List<DMT_Risk_Line_Term__c > riskLineDerivatesList = new List<DMT_Risk_Line_Term__c >();
        List<DMT_Risk_Line_Term__c > riskLineDeposList = new List<DMT_Risk_Line_Term__c >();
        List<DMT_Risk_Line_Term__c > riskLineEquitiesList = new List<DMT_Risk_Line_Term__c >();
        System.debug('DMT_TreasuryProductsRenderer renderPdfJson data, '+ JSON.serialize(data));
        if(!data.riskLineList.isEmpty()){
            for (DMT_Risk_Line_Term__c riskLine : data.riskLineList) {
                if(riskLine.DMT_Risk_Type__c == 'Derivatives'){
                    riskLineDerivatesList.add(riskLine);
                }else if(riskLine.DMT_Risk_Type__c == 'Depos'){
                    riskLineDeposList.add(riskLine);
                }else if (riskLine.DMT_Risk_Type__c == 'Equities'){
                    riskLineEquitiesList.add(riskLine);
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
            name.add('First Breakclause:');
            value.add(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(data.line.First_Breakclause__c)));
            name.add('ISDA Waiver:');
            value.add((data.line.Waiver__c ? 'Yes' : 'No'));
            name.add('Free Delivery (FD) Amount (Units EUR):');
            value.add(DMT_FormattingUtils.formatCurrencyAmount(data.line.FD_Amount__c, data.line.CurrencyIsoCode));
            name.add('Breakclause Frequency:');
            value.add(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(data.line.Breakclause_Frequency__c)));   
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
        //CREATE TABLE SECTION DEPOS RISK LINE (ONLY FOR FINANCIAL INSTITUTIONS)
        Boolean hasDepos = false;
        for (DMT_Risk_Line_Term__c riskLineDepos : riskLineDeposList) {
            if (riskLineDepos.DMT_Amount__c != null && riskLineDepos.DMT_Amount__c > 0) {
                hasDepos = true;
                break;
            }
        }
        if(hasDepos){
            Map<String, Object> tableComponentDepos = new Map<String, Object>();
            List<List<String>> headersDepos = new List<List<String>>();
            List<String> listHeadersDepos = new List<String>{'INIT TERM', 'END TERM', 'AMOUNT'}; 
            headersDepos.add(listHeadersDepos);    
            List<List<String>> bodyDepos = new List<List<String>>();
            for (DMT_Risk_Line_Term__c riskLineDepos : riskLineDeposList) {
                if (riskLineDepos.DMT_Amount__c != null && riskLineDepos.DMT_Amount__c > 0) {
                    List<String> row = new List<String>();
                    row.add(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDepos?.DMT_Init_Term__c)));
                    row.add(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineDepos?.DMT_End_Term__c)));
                    row.add(DMT_FormattingUtils.formatCurrencyAmount(riskLineDepos.DMT_Amount__c, data.line.CurrencyIsoCode));
                    bodyDepos.add(row);
                }
            }       
            
            contentListProduct.add(pageBreak);

            titleSection = DMT_Create_Pdf_Controller.createTitleSection('DEPOS RISK LINE (ONLY FOR FINANCIAL INSTITUTIONS)');
            contentListProduct.add(titleSection[0]);
            contentListProduct.add(titleSection[1]);
            tableComponentDepos.put('margin',marginTable);
            tableComponentDepos.put('headStyles', headStyles);
            tableComponentDepos.put('style', stylesTable);
            tableComponentDepos.put('body', bodyDepos);
            tableComponentDepos.put('head', headersDepos);
            tableComponentDepos.put('type', 'table');
            contentListProduct.add(tableComponentDepos);
        }
        //CREATE TABLE SECTION EQUITIES WWR RISK LINE
        Boolean hasEquities = false;
        for (DMT_Risk_Line_Term__c riskLineEquities : riskLineEquitiesList) {
            if (riskLineEquities.DMT_Amount__c != null && riskLineEquities.DMT_Amount__c > 0) {
                hasEquities = true;
                break;
            }
        }
        if(hasEquities){
            Map<String, Object> tableComponentEquities = new Map<String, Object>();
            List<List<String>> headersEquities = new List<List<String>>();
            List<String> listheadersEquities = new List<String>{'INIT TERM', 'END TERM', 'AMOUNT'};
            headersEquities.add(listheadersEquities);     
            List<List<String>> bodyEquities = new List<List<String>>();
            for (DMT_Risk_Line_Term__c riskLineEquities : riskLineEquitiesList) {
                if (riskLineEquities.DMT_Amount__c != null && riskLineEquities.DMT_Amount__c > 0) {
                    List<String> row = new List<String>();
                    row.add(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineEquities?.DMT_Init_Term__c)));
                    row.add(DMT_FormattingUtils.traductorDate(DMT_FormattingUtils.checkNull(riskLineEquities?.DMT_End_Term__c)));
                    row.add(DMT_FormattingUtils.formatCurrencyAmount(riskLineEquities?.DMT_Amount__c, data.line.CurrencyIsoCode));
                    bodyEquities.add(row);
                }
            }
            
            contentListProduct.add(pageBreak);

            titleSection = DMT_Create_Pdf_Controller.createTitleSection('EQUITIES WWR RISK LINE');
            contentListProduct.add(titleSection[0]);
            contentListProduct.add(titleSection[1]);
            tableComponentEquities.put('margin',marginTable);
            tableComponentEquities.put('headStyles', headStyles);
            tableComponentEquities.put('style', stylesTable);
            tableComponentEquities.put('body', bodyEquities);
            tableComponentEquities.put('head', headersEquities);
            tableComponentEquities.put('type', 'table');
            contentListProduct.add(tableComponentEquities);
        }

        //CREATE TABLE SECTION PRODUCTS
        componentProduct.put('content', contentListProduct);
        componentProduct.put('name', 'PRODUCTS');
               
        return componentProduct;
    }
}