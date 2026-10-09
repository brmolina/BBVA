/**
 * Controller for the dmtRiskTablesLine LWC.
 * Replaces Integration Procedures LINE_GetRiskLineTerm, LINE_GetRiskLineForm,
 * LINE_productsTreasuryCreation and LINE_SetRiskLineForm with native Apex.
 */
public with sharing class DMT_RiskTablesLineController {

    private static final String RISK_TYPE_DERIVATIVES = 'Derivatives';
    private static final String RISK_TYPE_DEPOS = 'Depos';
    private static final String RISK_TYPE_REPOS = 'Repos';
    private static final String RISK_TYPE_EQUITIES = 'Equities';
    private static final String RISK_TYPE_SINGULAR = 'Singular';
    private static final String RISK_TYPE_RESTRIC = 'Restric';
    private static Map<String, Product2> riskProductsByType;

    // ─── Inner classes for structured response ────────────────────────────────
    public class RiskTableRow {
        @AuraEnabled public String Id;
        @AuraEnabled public String initTerm;
        @AuraEnabled public String endTerm;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String tabletype;
        @AuraEnabled public Boolean isDisabled;
        @AuraEnabled public String line;
        @AuraEnabled public String currency_x;
        @AuraEnabled public Id parentProductId;
        @AuraEnabled public Decimal parentAmount;
        @AuraEnabled public String parentEndTerm;
        @AuraEnabled public String parentCurrency;
        @AuraEnabled public String priority;
    }

    public class SingularRow {
        @AuraEnabled public String Id;
        @AuraEnabled public String operationName;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Decimal dvpAmount;
        @AuraEnabled public Decimal fdAmount;
        @AuraEnabled public String initTerm;
        @AuraEnabled public String endTerm;
        @AuraEnabled public Date maxDate;
        @AuraEnabled public Boolean active;
        @AuraEnabled public String product;
        @AuraEnabled public String tabletype;
        @AuraEnabled public String line;
        @AuraEnabled public String currency_x;
        @AuraEnabled public Boolean isDisabled;
        @AuraEnabled public String priority;
    }

    public class DataResponse {
        // Line metadata
        @AuraEnabled public String bookingGeography;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public String currency_x;
        @AuraEnabled public String conversionLabel;
        @AuraEnabled public String currencyLabel;
        @AuraEnabled public String lineStatus;
        @AuraEnabled public Boolean isReadOnlyUser;
        @AuraEnabled public Boolean showSingular;

        // Form fields
        @AuraEnabled public Decimal dvpAmount;
        @AuraEnabled public Decimal fdAmount;
        @AuraEnabled public String firstBreakclause;
        @AuraEnabled public String breakclauseFrequency;
        @AuraEnabled public Boolean waiver;
        @AuraEnabled public String mitigantComments;
        @AuraEnabled public String additionalRestrictions;
        @AuraEnabled public String comments;
        @AuraEnabled public List<PicklistOption> firstBreakOptions;
        @AuraEnabled public List<PicklistOption> breakFrequencyOptions;

        // Tables
        @AuraEnabled public List<RiskTableRow> derivatives;
        @AuraEnabled public List<RiskTableRow> depos;
        @AuraEnabled public List<RiskTableRow> repos;
        @AuraEnabled public List<RiskTableRow> equities;
        @AuraEnabled public Decimal derivativesTotalAmount;
        @AuraEnabled public Decimal deposTotalAmount;
        @AuraEnabled public Decimal equitiesTotalAmount;
        @AuraEnabled public Decimal reposTotalAmount;
        @AuraEnabled public List<SingularRow> singularCon;
        @AuraEnabled public List<Object> tableRestric;
        @AuraEnabled public List<Object> tableDeposProducts;
        @AuraEnabled public List<Object> tableReposProducts;    
        @AuraEnabled public List<Object> tableDerivativesProducts;
        @AuraEnabled public List<Object> maxTenorOptions;
        @AuraEnabled public Decimal fdAmountRestric;
        @AuraEnabled public Decimal dvpAmountRestric;

        // Main borrower country code for PE FX logic
        @AuraEnabled public String mainBorrowerCountryIfoId;

        // Columns for copy/paste
        @AuraEnabled public List<CopyPasteColumn> columnsCopy;
        @AuraEnabled public List<CopyPasteColumn> columnsCopyTransaction;
        @AuraEnabled public List<CopyPasteColumn> restricCopy;
    }

    public class CopyPasteColumn {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean editable;

        public CopyPasteColumn(String fieldName, String label, Boolean editable) {
            this.fieldName = fieldName;
            this.label = label;
            this.editable = editable;
        }
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    // ─── getData ──────────────────────────────────────────────────────────────
    @AuraEnabled
    public static DataResponse getData(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('recordId is required');
        }

        DMT_Line__c line = [
            SELECT Id, OwnerId, Status__c, Closed__c, DMT_line_template_type__c,
                   Booking_Geography__c, CurrencyIsoCode, DvP_Amount__c, FD_Amount__c,
                   First_Breakclause__c, Breakclause_Frequency__c, Waiver__c,
                   DMT_Mitigant_Agreement_comments__c, DMT_DerivativesAmount__c,
                   DMT_Additional_Restrictions__c, DMT_Comments__c,
                   DMT_Parent_Line__c, DMT_Parent_Line__r.CurrencyIsoCode,
                   Custom_Association__c, Custom_Association__r.g_customer_id__c
            FROM DMT_Line__c
            WHERE Id = :recordId
            WITH USER_MODE
            LIMIT 1
        ];

        DataResponse response = new DataResponse();

        // Line metadata
        response.bookingGeography = line.Booking_Geography__c;
        response.currencyIsoCode = line.CurrencyIsoCode;
        response.currency_x = line.CurrencyIsoCode;
        response.conversionLabel = '(' + DMT_Currency_Conversion_Utils.getCurrencyLabel(line.CurrencyIsoCode) + ')';
        response.currencyLabel = DMT_Currency_Conversion_Utils.getCurrencyLabel(line.CurrencyIsoCode);
        response.lineStatus = line.Status__c;
        response.showSingular = line.Booking_Geography__c != null;

        // Access control
        response.isReadOnlyUser = !resolveCanEdit(line);

        // Form fields (apply convertToDisplay for currency amounts)
        response.dvpAmount = DMT_Currency_Conversion_Utils.convertToDisplay(line.CurrencyIsoCode, line.DvP_Amount__c);
        response.fdAmount = DMT_Currency_Conversion_Utils.convertToDisplay(line.CurrencyIsoCode, line.FD_Amount__c);
        response.firstBreakclause = line.First_Breakclause__c;
        response.breakclauseFrequency = line.Breakclause_Frequency__c;
        response.waiver = line.Waiver__c;
        response.mitigantComments = line.DMT_Mitigant_Agreement_comments__c;
        response.additionalRestrictions = line.DMT_Additional_Restrictions__c;
        response.comments = line.DMT_Comments__c;

        // Picklist options
        response.firstBreakOptions = getPicklistOptions('DMT_Line__c', 'First_Breakclause__c');
        response.breakFrequencyOptions = getPicklistOptions('DMT_Line__c', 'Breakclause_Frequency__c');

        // Risk Line Terms
        List<DMT_Risk_Line_Term__c> allTerms = [
            SELECT Id, DMT_Init_Term__c, DMT_End_Term__c, DMT_Amount__c, DMT_Risk_Type__c,
                   CurrencyIsoCode, gf_group_priority_line_id__c,
                   DMT_Parent_Product__c, DMT_Parent_Product__r.DMT_Amount__c,
                   DMT_Parent_Product__r.DMT_End_Term__c, DMT_Parent_Product__r.CurrencyIsoCode,
                   DMT_Singular_Operation__c, DMT_Singular_DvP__c, DMT_Singular_FD__c,
                   DMT_Singular__c, DMT_Max_Date__c, DMT_Singular_Active__c,
                   DMT_Product__c, DMT_Product__r.Name
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :recordId
            WITH USER_MODE
            ORDER BY gf_group_priority_line_id__c ASC NULLS LAST
        ];

        String lineCurrency = line.CurrencyIsoCode;

        response.derivatives = new List<RiskTableRow>();
        response.depos = new List<RiskTableRow>();
        response.equities = new List<RiskTableRow>();
        response.repos = new List<RiskTableRow>();
        response.singularCon = new List<SingularRow>();
        response.fdAmountRestric = DMT_Currency_Conversion_Utils.convertToDisplay(lineCurrency, line.FD_Amount__c);
        response.dvpAmountRestric = DMT_Currency_Conversion_Utils.convertToDisplay(lineCurrency, line.DvP_Amount__c);

        // Main borrower's country code for PE FX restrictions
        response.mainBorrowerCountryIfoId = resolveMainBorrowerCountry(line);

        for (DMT_Risk_Line_Term__c term : allTerms) {
            String riskType = term.DMT_Risk_Type__c;

            if (riskType == RISK_TYPE_DERIVATIVES) {
                response.derivatives.add(buildRiskRow(term, RISK_TYPE_DERIVATIVES, recordId, lineCurrency));
            } else if (riskType == RISK_TYPE_DEPOS) {
                response.depos.add(buildRiskRow(term, RISK_TYPE_DEPOS, recordId, lineCurrency));
            } else if (riskType == RISK_TYPE_EQUITIES) {
                response.equities.add(buildRiskRow(term, RISK_TYPE_EQUITIES, recordId, lineCurrency));
            } else if (riskType == RISK_TYPE_REPOS) {
                response.repos.add(buildRiskRow(term, RISK_TYPE_REPOS, recordId, lineCurrency));
            } else if (riskType == RISK_TYPE_SINGULAR) {
                response.singularCon.add(buildSingularRow(term, recordId, lineCurrency));
            }
        }

        // The editable total is stored in the first derivatives term. The line Summary
        // can include other qualifying terms and is therefore only a fallback here.
        response.derivativesTotalAmount = !response.derivatives.isEmpty()
            ? response.derivatives[0].amount
            : DMT_Currency_Conversion_Utils.convertToDisplay(lineCurrency, line.DMT_DerivativesAmount__c);
        response.deposTotalAmount = !response.depos.isEmpty() ? response.depos[0].amount : 0;
        response.equitiesTotalAmount = !response.equities.isEmpty() ? response.equities[0].amount : 0;
        response.reposTotalAmount = !response.repos.isEmpty() ? response.repos[0].amount : 0;

        // Product restrictions from custom metadata
        response.tableRestric = buildTableRestric(recordId, line.Booking_Geography__c, false, false, false);
        response.tableDerivativesProducts = buildTableRestric(recordId, line.Booking_Geography__c, true, false, false);
        response.tableDeposProducts = buildTableRestric(recordId, line.Booking_Geography__c, false, true, false);
        response.tableReposProducts = buildTableRestric(recordId, line.Booking_Geography__c, false, false, true);
        response.maxTenorOptions = getMaxTenorOptions();

        // Columns for copy/paste
        response.columnsCopy = new List<CopyPasteColumn>{
            new CopyPasteColumn('initTerm', 'INIT TERM', true),
            new CopyPasteColumn('endTerm', 'END TERM', true),
            new CopyPasteColumn('amount', 'AMOUNT', true)
        };
        response.columnsCopyTransaction = new List<CopyPasteColumn>{
            new CopyPasteColumn('operationName', 'TRANSACTION', true),
            new CopyPasteColumn('amount', 'DERIVATIVES AMOUNT', true),
            new CopyPasteColumn('dvpAmount', 'DVP AMOUNT', true),
            new CopyPasteColumn('fdAmount', 'FD AMOUNT', true),
            new CopyPasteColumn('maxDate', 'MAX DATE', true)
        };
        response.restricCopy = new List<CopyPasteColumn>{
            new CopyPasteColumn('product', 'PRODUCT', false),
            new CopyPasteColumn('initTerm', 'INIT TERM', true),
            new CopyPasteColumn('endTerm', 'END TERM', true),
            new CopyPasteColumn('dvpAmount', 'DVP AMOUNT', true),
            new CopyPasteColumn('fdAmount', 'FD AMOUNT', true)
        };

        return response;
    }

    // ─── saveProducts ─────────────────────────────────────────────────────────
    @AuraEnabled
    public static Map<String, Object> saveProducts(
        Id recordId,
        String derivatives,
        String depos,
        String equities,
        String repos,
        String tableRestric,
        String tableDerivativesProducts,
        String tableDeposProducts,
        String tableReposProducts,
        String singularCon,
        Decimal dvpAmount,
        Decimal fdAmount,
        String firstBreakclause,
        String breakclauseFrequency,
        Boolean waiver,
        String mitigantComments,
        String additionalRestrictions,
        String comments,
        Decimal derivativesTotalAmount
    ) {
        System.debug('Saving products for recordId: ' + recordId);
        System.debug('Derivatives: ' + derivatives);
        System.debug('Depos: ' + depos);
        System.debug('Equities: ' + equities);
        System.debug('Repos: ' + repos);
        System.debug('Table Restric: ' + tableRestric);
        System.debug('Table Derivatives Products: ' + tableDerivativesProducts);
        System.debug('Table Depos Products: ' + tableDeposProducts);
        System.debug('Table Repos Products: ' + tableReposProducts);
        System.debug('Singular Con: ' + singularCon);
        System.debug('DVP Amount: ' + dvpAmount);
        System.debug('FD Amount: ' + fdAmount);
        System.debug('First Breakclause: ' + firstBreakclause);
        System.debug('Breakclause Frequency: ' + breakclauseFrequency);
        System.debug('Waiver: ' + waiver);
        System.debug('Mitigant Comments: ' + mitigantComments);
        System.debug('Additional Restrictions: ' + additionalRestrictions);
        System.debug('Comments: ' + comments);
        Map<String, Object> result = new Map<String, Object>();

        if (recordId == null) {
            throw new AuraHandledException('recordId is required');
        }

        // Verify edit access
        DMT_Line__c line = [
            SELECT Id, OwnerId, Status__c, Closed__c, DMT_line_template_type__c, CurrencyIsoCode,
                   Booking_Geography__c
            FROM DMT_Line__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        if (!resolveCanEdit(line)) {
            throw new AuraHandledException('This line cannot be edited with your current permissions.');
        }

        String lineCurrency = line.CurrencyIsoCode;

        try {
            // 1. Update form fields on DMT_Line__c (convert display values back to storage)
            DMT_Line__c lineUpdate = new DMT_Line__c(Id = recordId);
            lineUpdate.DvP_Amount__c = DMT_Currency_Conversion_Utils.convertToStorage(lineCurrency, dvpAmount);
            lineUpdate.FD_Amount__c = DMT_Currency_Conversion_Utils.convertToStorage(lineCurrency, fdAmount);
            lineUpdate.First_Breakclause__c = firstBreakclause;
            lineUpdate.Breakclause_Frequency__c = breakclauseFrequency;
            lineUpdate.Waiver__c = waiver;
            lineUpdate.DMT_Mitigant_Agreement_comments__c = mitigantComments;
            lineUpdate.DMT_Additional_Restrictions__c = additionalRestrictions;
            lineUpdate.DMT_Comments__c = comments;
            update lineUpdate;

            // 2. Process risk table rows (upsert/delete)
            processRiskTableRows(
                recordId,
                applyDerivativesTotal(derivatives, derivativesTotalAmount),
                RISK_TYPE_DERIVATIVES,
                lineCurrency
            );
            processRiskTableRows(recordId, depos, RISK_TYPE_DEPOS, lineCurrency);
            processRiskTableRows(recordId, equities, RISK_TYPE_EQUITIES, lineCurrency);
            processRiskTableRows(recordId, repos, RISK_TYPE_REPOS, lineCurrency);

            // 3. Process singular treasury
            if (String.isNotBlank(singularCon)) {
                processRiskTableRows(recordId, singularCon, RISK_TYPE_SINGULAR, lineCurrency);
            }

            // 4. Process operational restrictions (DMT_Line_Product_Item__c)
            if (String.isNotBlank(tableRestric)) {
                processTableRestricRows(recordId, tableRestric, line.Booking_Geography__c, false, false, false);
            }
            if (String.isNotBlank(tableDerivativesProducts)) {
                processTableRestricRows(recordId, tableDerivativesProducts, line.Booking_Geography__c, true, false, false);
            }
            if (String.isNotBlank(tableDeposProducts)) {
                processTableRestricRows(recordId, tableDeposProducts, line.Booking_Geography__c, false, true, false);
            }
            if (String.isNotBlank(tableReposProducts)) {
                processTableRestricRows(recordId, tableReposProducts, line.Booking_Geography__c, false, false, true);
            }
            cleanupStaleProductItems(recordId, line.Booking_Geography__c);

            result.put('error', 'OK');
        } catch (DmlException dmlEx) {
            result.put('error', 'DML_ERROR');
            result.put('message', dmlEx.getDmlMessage(0));
        } catch (Exception e) {
            result.put('error', 'ERROR');
            result.put('message', e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static void updateRiskLineTermAmount(Id riskLineTermId, Decimal amount) {
        if (riskLineTermId == null) {
            throw new AuraHandledException('riskLineTermId is required');
        }

        DMT_Risk_Line_Term__c term = [
            SELECT Id, DMT_Line__c, DMT_Line__r.CurrencyIsoCode, DMT_Risk_Type__c
            FROM DMT_Risk_Line_Term__c
            WHERE Id = :riskLineTermId
            WITH USER_MODE
            LIMIT 1
        ];

        DMT_Line__c line = [
            SELECT Id, OwnerId, Status__c, Closed__c, DMT_line_template_type__c, CurrencyIsoCode
            FROM DMT_Line__c
            WHERE Id = :term.DMT_Line__c
            WITH USER_MODE
            LIMIT 1
        ];
        if (!resolveCanEdit(line)) {
            throw new AuraHandledException('This line cannot be edited with your current permissions.');
        }

        term.CurrencyIsoCode = line.CurrencyIsoCode;
        Product2 riskProduct = getRiskProduct(term.DMT_Risk_Type__c);
        if (riskProduct != null) {
            term.DMT_Product__c = riskProduct.Id;
            term.g_global_product_family_id__c = riskProduct.DMT_Product_family__c;
            term.g_global_product_subfamily_id__c = riskProduct.DMT_Product_Subfamily__c;
            term.g_global_product_category_id__c = riskProduct.DMT_Product_category__c;
            term.g_gbl_product_subcategory_id__c = riskProduct.DMT_Product_Subcategory__c;
            term.g_global_product_id__c = riskProduct.DMT_Global_Product_Id__c;
        }
        term.DMT_Amount__c = DMT_Currency_Conversion_Utils.convertToStorage(
            line.CurrencyIsoCode,
            amount
        );
        update term;
    }

    // ─── Private Helpers ──────────────────────────────────────────────────────

    private static RiskTableRow buildRiskRow(DMT_Risk_Line_Term__c term, String tableType, Id lineId, String lineCurrency) {
        RiskTableRow row = new RiskTableRow();
        row.Id = String.valueOf(term.Id);
        row.initTerm = term.DMT_Init_Term__c != null ? term.DMT_Init_Term__c : '';
        row.endTerm = term.DMT_End_Term__c != null ? term.DMT_End_Term__c : '';
        row.amount = DMT_Currency_Conversion_Utils.convertToDisplay(lineCurrency, term.DMT_Amount__c);
        row.tabletype = tableType;
        row.isDisabled = false;
        row.line = String.valueOf(lineId);
        row.currency_x = lineCurrency;
        row.priority = term.gf_group_priority_line_id__c;
        row.parentProductId = term.DMT_Parent_Product__c;
        if (term.DMT_Parent_Product__c != null) {
            row.parentAmount = DMT_Currency_Conversion_Utils.convertToDisplay(lineCurrency, term.DMT_Parent_Product__r.DMT_Amount__c);
            row.parentEndTerm = term.DMT_Parent_Product__r.DMT_End_Term__c;
            row.parentCurrency = term.DMT_Parent_Product__r.CurrencyIsoCode;
            row.isDisabled = true;
        }
        return row;
    }

    private static SingularRow buildSingularRow(DMT_Risk_Line_Term__c term, Id lineId, String lineCurrency) {
        SingularRow row = new SingularRow();
        row.Id = String.valueOf(term.Id);
        row.operationName = term.DMT_Singular_Operation__c;
        row.amount = DMT_Currency_Conversion_Utils.convertToDisplay(lineCurrency, term.DMT_Amount__c);
        row.dvpAmount = DMT_Currency_Conversion_Utils.convertToDisplay(lineCurrency, term.DMT_Singular_DvP__c);
        row.fdAmount = DMT_Currency_Conversion_Utils.convertToDisplay(lineCurrency, term.DMT_Singular_FD__c);
        row.initTerm = term.DMT_Init_Term__c != null ? term.DMT_Init_Term__c : '';
        row.endTerm = term.DMT_End_Term__c != null ? term.DMT_End_Term__c : '';
        row.maxDate = term.DMT_Max_Date__c;
        row.active = term.DMT_Singular_Active__c;
        row.product = term.DMT_Product__r?.Name;
        row.tabletype = RISK_TYPE_SINGULAR;
        row.line = String.valueOf(lineId);
        row.currency_x = lineCurrency;
        row.isDisabled = false;
        row.priority = term.gf_group_priority_line_id__c;
        return row;
    }

    private static String applyDerivativesTotal(String rowsJson, Decimal totalAmount) {
        if (String.isBlank(rowsJson) || totalAmount == null) {
            return rowsJson;
        }

        List<Object> rawRows = (List<Object>) JSON.deserializeUntyped(rowsJson);
        if (!rawRows.isEmpty()) {
            Map<String, Object> firstRow = (Map<String, Object>) rawRows[0];
            firstRow.put('amount', totalAmount);
        }
        return JSON.serialize(rawRows);
    }

    private static void processRiskTableRows(Id lineId, String rowsJson, String riskType, String lineCurrency) {
        if (String.isBlank(rowsJson)) {
            return;
        }
        System.debug('Processing risk table rows for lineId: ' + lineId + ', riskType: ' + riskType + ', rowsJson: ' + JSON.serializePretty(rowsJson));
        List<Object> rawRows = (List<Object>) JSON.deserializeUntyped(rowsJson);
        Set<Id> incomingIds = new Set<Id>();
        List<DMT_Risk_Line_Term__c> toUpsert = new List<DMT_Risk_Line_Term__c>();

        for (Object rawRow : rawRows) {
            Map<String, Object> rowMap = (Map<String, Object>) rawRow;
            Decimal displayAmount = rowMap.get('amount') != null ? Decimal.valueOf(String.valueOf(rowMap.get('amount'))) : null;

            if (riskType != RISK_TYPE_SINGULAR && displayAmount == null) {
                continue;
            }

            DMT_Risk_Line_Term__c rec = new DMT_Risk_Line_Term__c();
            // Child component uses 'Id' (capital I)
            String rowId = rowMap.containsKey('Id') ? String.valueOf(rowMap.get('Id')) : (String) rowMap.get('id');
            if (String.isNotBlank(rowId) && rowId.length() == 18) {
                try {
                    rec.Id = (Id) rowId;
                    incomingIds.add(rec.Id);
                } catch (Exception e) {
                    // New row with non-Id value, skip
                }
            }else{
                rec.DMT_Line__c = lineId;
            }
            System.debug('rec line 417 lineId: '+lineId+ 'riskType: '+riskType+' rowsJson: '+ JSON.serializePretty(rowsJson));
            
            rec.CurrencyIsoCode = lineCurrency;
            Product2 riskProduct = getRiskProduct(riskType);
            if (riskProduct != null) {
                rec.DMT_Product__c = riskProduct.Id;
                rec.g_global_product_family_id__c = riskProduct.DMT_Product_family__c;
                rec.g_global_product_subfamily_id__c = riskProduct.DMT_Product_Subfamily__c;
                rec.g_global_product_category_id__c = riskProduct.DMT_Product_category__c;
                rec.g_gbl_product_subcategory_id__c = riskProduct.DMT_Product_Subcategory__c;
                rec.g_global_product_id__c = riskProduct.DMT_Global_Product_Id__c;
            }
            rec.DMT_Risk_Type__c = riskType;
            rec.DMT_Singular__c = false;
            rec.DMT_Init_Term__c = (String) rowMap.get('initTerm');
            rec.DMT_End_Term__c = (String) rowMap.get('endTerm');
            rec.DMT_Amount__c = DMT_Currency_Conversion_Utils.convertToStorage(lineCurrency, displayAmount);

            if (riskType == RISK_TYPE_SINGULAR) {
                rec.DMT_Singular__c = true;
                rec.DMT_Singular_Operation__c = (String) rowMap.get('operationName');
                Decimal dvp = rowMap.get('dvpAmount') != null ? Decimal.valueOf(String.valueOf(rowMap.get('dvpAmount'))) : null;
                Decimal fd = rowMap.get('fdAmount') != null ? Decimal.valueOf(String.valueOf(rowMap.get('fdAmount'))) : null;
                rec.DMT_Singular_DvP__c = DMT_Currency_Conversion_Utils.convertToStorage(lineCurrency, dvp);
                rec.DMT_Singular_FD__c = DMT_Currency_Conversion_Utils.convertToStorage(lineCurrency, fd);
                rec.DMT_Max_Date__c = parseDate(rowMap.get('maxDate'));
            }

            toUpsert.add(rec);
        }

        // Delete rows that were removed from the table
        List<DMT_Risk_Line_Term__c> existingRows = [
            SELECT Id
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :lineId AND DMT_Risk_Type__c = :riskType
        ];

        List<DMT_Risk_Line_Term__c> toDelete = new List<DMT_Risk_Line_Term__c>();
        for (DMT_Risk_Line_Term__c existing : existingRows) {
            if (!incomingIds.contains(existing.Id)) {
                toDelete.add(existing);
            }
        }

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
        if (!toUpsert.isEmpty()) {
            System.debug('toUpsert: '+toUpsert);
            upsert toUpsert;
        }
    }

    private static Product2 getRiskProduct(String riskType) {
        if (riskProductsByType == null) {
            riskProductsByType = new Map<String, Product2>();
            Map<String, String> productCodesByRiskType = new Map<String, String>{
                RISK_TYPE_DERIVATIVES => DMT_Constants.PRODUCT_DERI,
                RISK_TYPE_SINGULAR => DMT_Constants.PRODUCT_DERI,
                RISK_TYPE_DEPOS => DMT_Constants.PRODUCT_DEPO,
                RISK_TYPE_EQUITIES => DMT_Constants.PRODUCT_EQUI,
                RISK_TYPE_REPOS => DMT_Constants.PRODUCT_REPO
            };

            Set<String> productCodes = new Set<String>(productCodesByRiskType.values());
            for (Product2 product : [
                  SELECT Id, ProductCode, DMT_Product_family__c, DMT_Product_Subfamily__c,
                      DMT_Product_category__c, DMT_Product_Subcategory__c, DMT_Global_Product_Id__c
                FROM Product2
                  WHERE ProductCode IN :productCodes AND Family = 'DMT Lines'
            ]) {
                for (String type : productCodesByRiskType.keySet()) {
                    if (productCodesByRiskType.get(type) == product.ProductCode) {
                        riskProductsByType.put(type, product);
                    }
                }
            }
        }
        return riskProductsByType.get(riskType);
    }

    private static List<PicklistOption> getMaxTenorOptions() {
        return new List<PicklistOption>{
            new PicklistOption('', ''),
            new PicklistOption('0D', '0'),
            new PicklistOption('2D', '2'),
            new PicklistOption('3D', '3'),
            new PicklistOption('4D', '4'),
            new PicklistOption('7D', '7'),
            new PicklistOption('10D', '10'),
            new PicklistOption('15D', '15'),
            new PicklistOption('20D', '20'),
            new PicklistOption('1M', '30'),
            new PicklistOption('45D', '45'),
            new PicklistOption('2M', '60'),
            new PicklistOption('3M', '90'),
            new PicklistOption('4M', '120'),
            new PicklistOption('5M', '150'),
            new PicklistOption('6M', '180'),
            new PicklistOption('9M', '270'),
            new PicklistOption('1Y', '365'),
            new PicklistOption('18M', '548'),
            new PicklistOption('2Y', '730'),
            new PicklistOption('3Y', '1095'),
            new PicklistOption('4Y', '1460'),
            new PicklistOption('5Y', '1825'),
            new PicklistOption('6Y', '2190'),
            new PicklistOption('7Y', '2555'),
            new PicklistOption('8Y', '2920'),
            new PicklistOption('9Y', '3285'),
            new PicklistOption('10Y', '3650'),
            new PicklistOption('11Y', '4015'),
            new PicklistOption('12Y', '4380'),
            new PicklistOption('13Y', '4745'),
            new PicklistOption('14Y', '5110'),
            new PicklistOption('15Y', '5475'),
            new PicklistOption('16Y', '5840'),
            new PicklistOption('17Y', '6205'),
            new PicklistOption('18Y', '6570'),
            new PicklistOption('19Y', '6935'),
            new PicklistOption('20Y', '7300'),
            new PicklistOption('21Y', '7665'),
            new PicklistOption('22Y', '8030'),
            new PicklistOption('25Y', '9125'),
            new PicklistOption('27Y', '9855'),
            new PicklistOption('30Y', '10950'),
            new PicklistOption('32Y', '11680'),
            new PicklistOption('35Y', '12775'),
            new PicklistOption('37Y', '13505'),
            new PicklistOption('40Y', '14600'),
            new PicklistOption('42Y', '15330'),
            new PicklistOption('45Y', '16425')
        };
    }

    private static List<Map<String, Object>> buildTableRestric(Id recordId, String bookingGeography, boolean DMT_Derivatives_layout2, boolean DMT_Depos_layout2, boolean DMT_Repos_layout2) {
        String geography = normalizeGeography(bookingGeography);

        List<DMT_Line_Product_Item__c> lpis = [
            SELECT Id, Name, Product_Code_Value__c, Max_Tenor_WC__c, Max_Tenor_WOC__c,
                   DMT_DerivativeRestriction__c, DMT_FDRestriction__c, DMT_DVPRestriction__c
            FROM DMT_Line_Product_Item__c
            WHERE Line__c = :recordId
            WITH USER_MODE
        ];
        Map<String, DMT_Line_Product_Item__c> lpiMap = new Map<String, DMT_Line_Product_Item__c>();
        for (DMT_Line_Product_Item__c lpi : lpis) {
            if (String.isNotBlank(lpi.Product_Code_Value__c)) {
                lpiMap.put(lpi.Product_Code_Value__c.trim().toUpperCase(), lpi);
            }
        }

        List<DMT_OperationalRestrictionsTRSR__mdt> opRestrics = [
            SELECT MasterLabel, DeveloperName, Product_Group__c, DMT_Operational_Restrictions_Name__c,
                   Description__c, OrderRestriction__c, DERIVATIVES_Editable__c, FD_Editable__c,
                   DVP_Editable__c, DERIVATIVES_Disabled__c, FD_Disabled__c, DVP_Disabled__c,
                   MaturityTerm_Disabled__c, FD_dependent_Derivatives__c, DVP_dependent_Derivatives__c,
                   Apply_Validations_FD__c, Apply_Validations_DVP__c
            FROM DMT_OperationalRestrictionsTRSR__mdt
            WHERE Entific__c = :geography AND isActive__c = true  AND (
                DMT_Derivatives_layout2__c = :DMT_Derivatives_layout2 AND
                DMT_Depos_layout2__c = :DMT_Depos_layout2 AND
                DMT_Repos_layout2__c = :DMT_Repos_layout2
            )
            WITH USER_MODE
            ORDER BY OrderRestriction__c ASC
        ];

        List<Map<String, Object>> tableRestricRows = new List<Map<String, Object>>();
        Integer idx = 1;
        for (DMT_OperationalRestrictionsTRSR__mdt mdt : opRestrics) {
            String prodCode = mdt.DMT_Operational_Restrictions_Name__c;
            DMT_Line_Product_Item__c existingLpi = String.isBlank(prodCode)
                ? null
                : lpiMap.get(prodCode.trim().toUpperCase());

            Map<String, Object> row = new Map<String, Object>();
            row.put('Id', existingLpi != null ? String.valueOf(existingLpi.Id) : String.valueOf(idx++));
            row.put('products', mdt.Product_Group__c);
            row.put('productsValue', prodCode);
            row.put('title', mdt.Description__c);
            row.put('derivativesLine', existingLpi != null ? existingLpi.DMT_DerivativeRestriction__c : false);
            row.put('derivativesEdit', mdt.DERIVATIVES_Editable__c);
            row.put('maxTerm', existingLpi != null && existingLpi.Max_Tenor_WC__c != null ? existingLpi.Max_Tenor_WC__c : '');
            row.put('lineFD', existingLpi != null ? existingLpi.DMT_FDRestriction__c : false);
            row.put('FDEdit', mdt.FD_Editable__c);
            row.put('lineDVP', existingLpi != null ? existingLpi.DMT_DVPRestriction__c : false);
            row.put('DVPEdit', mdt.DVP_Editable__c);
            row.put('isDisabled', false);
            row.put('DerivativesDisabled', mdt.DERIVATIVES_Disabled__c);
            row.put('FDDisabled', mdt.FD_Disabled__c);
            row.put('DVPDisabled', mdt.DVP_Disabled__c);
            row.put('MTDisabled', mdt.MaturityTerm_Disabled__c);
            row.put('FDdependentDerivatives', mdt.FD_dependent_Derivatives__c);
            row.put('DVPdependentDerivatives', mdt.DVP_dependent_Derivatives__c);
            row.put('applyValidationsFD', mdt.Apply_Validations_FD__c);
            row.put('applyValidationsDVP', mdt.Apply_Validations_DVP__c);
            row.put('deriVisible', '');
            row.put('setAttentionFD', '');
            row.put('setAttentionDVP', '');

            tableRestricRows.add(row);
        }
        return tableRestricRows;
    }

    private static void processTableRestricRows(Id lineId, String tableRestricJson, String bookingGeography, Boolean DMT_Derivatives_layout2, Boolean DMT_Depos_layout2, Boolean DMT_Repos_layout2) {
        if (String.isBlank(tableRestricJson)) return;

        List<Object> rawRows = (List<Object>) JSON.deserializeUntyped(tableRestricJson);

        // Only restrictions defined in the MDT for this geography may be persisted.
        Set<String> allowedCodes = getGeographyProductCodes(bookingGeography, DMT_Derivatives_layout2, DMT_Depos_layout2, DMT_Repos_layout2);

        Map<String, DMT_Line_Product_Item__c> existingByProdCode = new Map<String, DMT_Line_Product_Item__c>();
        for (DMT_Line_Product_Item__c existing : [
            SELECT Id, Product_Code_Value__c
            FROM DMT_Line_Product_Item__c
            WHERE Line__c = :lineId
        ]) {
            String code = String.isBlank(existing.Product_Code_Value__c)
                ? null
                : existing.Product_Code_Value__c.trim().toUpperCase();
            if (code != null) {
                existingByProdCode.put(code, existing);
            }
        }

        Map<String, DMT_Line_Product_Item__c> toUpsertByCode = new Map<String, DMT_Line_Product_Item__c>();

        for (Object obj : rawRows) {
            Map<String, Object> row = (Map<String, Object>) obj;
            String prodValue = (String) row.get('productsValue');
            if (String.isBlank(prodValue)) {
                // Placeholder row added in the UI without a product: nothing to persist.
                continue;
            }
            String code = prodValue.trim().toUpperCase();
            if (!allowedCodes.isEmpty() && !allowedCodes.contains(code)) {
                continue;
            }

            Boolean derivativesLine = parseBoolean(row.get('derivativesLine'));
            Boolean lineFD = parseBoolean(row.get('lineFD'));
            Boolean lineDVP = parseBoolean(row.get('lineDVP'));
            String maxTerm = (String) row.get('maxTerm');

            DMT_Line_Product_Item__c item = new DMT_Line_Product_Item__c();
            if (existingByProdCode.containsKey(code)) {
                item.Id = existingByProdCode.get(code).Id;
            } else {
                item.Line__c = lineId;
                item.Name = row.get('products') != null ? (String) row.get('products') : prodValue;
            }
            item.Product_Code_Value__c = prodValue;
            item.DMT_DerivativeRestriction__c = derivativesLine;
            item.DMT_FDRestriction__c = lineFD;
            item.DMT_DVPRestriction__c = lineDVP;
            item.Max_Tenor_WC__c = maxTerm != null ? maxTerm : '';

            toUpsertByCode.put(code, item);
        }

        if (!toUpsertByCode.isEmpty()) {
            System.debug('toUpsertByCode: '+toUpsertByCode.values());
            upsert toUpsertByCode.values();
        }
    }

    private static void cleanupStaleProductItems(Id lineId, String bookingGeography) {
        Set<String> validCodes = new Set<String>();
        validCodes.addAll(getGeographyProductCodes(bookingGeography, false, false, false));
        validCodes.addAll(getGeographyProductCodes(bookingGeography, true, false, false));
        validCodes.addAll(getGeographyProductCodes(bookingGeography, false, true, false));
        validCodes.addAll(getGeographyProductCodes(bookingGeography, false, false, true));

        List<DMT_Line_Product_Item__c> staleItems = new List<DMT_Line_Product_Item__c>();
        for (DMT_Line_Product_Item__c existing : [
            SELECT Id, Product_Code_Value__c
            FROM DMT_Line_Product_Item__c
            WHERE Line__c = :lineId
        ]) {
            String code = String.isBlank(existing.Product_Code_Value__c)
                ? null
                : existing.Product_Code_Value__c.trim().toUpperCase();
            if (code == null || (!validCodes.isEmpty() && !validCodes.contains(code))) {
                staleItems.add(existing);
            }
        }

        if (!staleItems.isEmpty()) {
            delete staleItems;
        }
    }

    private static Set<String> getGeographyProductCodes(String bookingGeography, Boolean DMT_Derivatives_layout2, Boolean DMT_Depos_layout2, Boolean DMT_Repos_layout2) {
        Set<String> codes = new Set<String>();
        String geography = normalizeGeography(bookingGeography);
        if (String.isBlank(geography)) {
            return codes;
        }
        for (DMT_OperationalRestrictionsTRSR__mdt mdt : [
            SELECT DMT_Operational_Restrictions_Name__c
            FROM DMT_OperationalRestrictionsTRSR__mdt
            WHERE Entific__c = :geography AND isActive__c = true AND (
                DMT_Derivatives_layout2__c = :DMT_Derivatives_layout2 AND
                DMT_Depos_layout2__c = :DMT_Depos_layout2 AND
                DMT_Repos_layout2__c = :DMT_Repos_layout2
            )
        ]) {
            if (String.isNotBlank(mdt.DMT_Operational_Restrictions_Name__c)) {
                codes.add(mdt.DMT_Operational_Restrictions_Name__c.trim().toUpperCase());
            }
        }
        return codes;
    }

    private static String normalizeGeography(String bookingGeography) {
        return String.isBlank(bookingGeography) ? '' : bookingGeography.trim().toUpperCase();
    }

    private static Boolean parseBoolean(Object val) {
        if (val == null) return false;
        if (val instanceof Boolean) return (Boolean) val;
        return String.valueOf(val).equalsIgnoreCase('true');
    }

    // The datatable sends ISO strings ('yyyy-MM-dd' or a full ISO timestamp).
    private static Date parseDate(Object val) {
        if (val == null) return null;
        String raw = String.valueOf(val).trim();
        if (String.isBlank(raw)) return null;
        try {
            return Date.valueOf(raw.substringBefore('T').replace('/', '-'));
        } catch (Exception e) {
            return null;
        }
    }

    private static Boolean resolveCanEdit(DMT_Line__c line) {
        if (line == null) {
            return false;
        }

        String statusValue = line.Status__c;
        Boolean isDraft = statusValue == DMT_Constants.DRAFT;
        Boolean hasGodAccess = DMT_Utils.checkLineGodUser();

        if (isDraft && hasGodAccess) {
            return true;
        }
        if (!DMT_Utils.hasWriteAccess()) {
            return false;
        }

        List<DMT_TeamMember__c> teamMembers = [
            SELECT Id, AccessLevel__c, DMT_ApprovalEdit__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :line.Id AND User__c = :UserInfo.getUserId()
            LIMIT 1
        ];
        DMT_TeamMember__c member = teamMembers.isEmpty() ? null : teamMembers[0];
        Boolean hasTeamEditAccess = member != null && (member.AccessLevel__c == 'Edit' || member.AccessLevel__c == 'All');

        if (isDraft) {
            return line.OwnerId == UserInfo.getUserId() || hasTeamEditAccess;
        }

        Boolean canApprovalEdit = hasTeamEditAccess && member.DMT_ApprovalEdit__c == true;
        Boolean isApproval = statusValue == DMT_Constants.APPROVAL;
        Boolean isClosedWon = statusValue == DMT_Constants.CLOSED && line.Closed__c == DMT_Constants.WON;
        Boolean isReadyToCloseOp = statusValue == DMT_Constants.READYTOCLOSE
            && line.DMT_line_template_type__c == 'OP';

        return canApprovalEdit && (isApproval || isClosedWon || isReadyToCloseOp);
    }

    private static String resolveMainBorrowerCountry(DMT_Line__c line) {
        if (line.Custom_Association__c == null) {
            return '';
        }
        String mainHolderAlpha = line.Custom_Association__r.g_customer_id__c;
        if (String.isBlank(mainHolderAlpha)) {
            return '';
        }
        List<Custom_Association_Client__c> clients = [
            SELECT g_entific_Id__c
            FROM Custom_Association_Client__c
            WHERE Custom_Association__c = :line.Custom_Association__c
              AND Alpha_Code_Client__c = :mainHolderAlpha
            LIMIT 1
        ];
        if (clients.isEmpty() || String.isBlank(clients[0].g_entific_Id__c)) {
            return '';
        }
        return clients[0].g_entific_Id__c;
    }

    private static List<PicklistOption> getPicklistOptions(String objectName, String fieldName) {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldDesc = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fields.getMap()
            .get(fieldName)
            .getDescribe();
        options.add(new PicklistOption('', null));
        for (Schema.PicklistEntry entry : fieldDesc.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
            }
        }
        return options;
    }
}