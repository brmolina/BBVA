public with sharing class DMT_ProductSanctionMigrationController {
    private static final String WARRANTY_FIELD_KEY = 'DMT_Warranty__c.g_limits_grid_guarantee_type__c';
    private static final String CURRENCY_PROVISION_FIELD_KEY = 'DMT_Currency_Provision__c.g_currency_id__c';
    private static final String OTHER_PRODUCTS_LINE_TYPE = 'Line (Other Products)';

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    private class RelatedFieldTarget {
        private String objectApiName;
        private String valueFieldApi;
        private String fieldKey;
    }

    public class FieldConfig {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public Boolean viewDisabled;
        @AuraEnabled public Boolean editDisabled;
        @AuraEnabled public String dataType;
        @AuraEnabled public String lineType;
        @AuraEnabled public String templateSubtype;
        @AuraEnabled public String dependsOnField;
        @AuraEnabled public String section;
        @AuraEnabled public Decimal sectionOrder;
        @AuraEnabled public Decimal fieldOrder;
        @AuraEnabled public String displayLabel;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public String helpText;
        @AuraEnabled public String visibilityRule;
        @AuraEnabled public String optionsJson;
        @AuraEnabled public String taxonomyCatalog;
        @AuraEnabled public String taxonomyFilterRule;
        @AuraEnabled public List<PicklistOption> picklistOptions;
    }

    public class RiskRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public String initTerm;
        @AuraEnabled public String endTerm;
        @AuraEnabled public String riskType;
        @AuraEnabled public Id productId;
        @AuraEnabled public String lastLevelId;
        @AuraEnabled public String priority;
        @AuraEnabled public String operationType;
    }

    public class DataResponse {
        @AuraEnabled public Id lineId;
        @AuraEnabled public String lineBusinessId;
        @AuraEnabled public String lineName;
        @AuraEnabled public String lineStatus;
        @AuraEnabled public String lineType;
        @AuraEnabled public String lineClientType;
        @AuraEnabled public Id lineClientId;
        @AuraEnabled public String lineGroupCode;
        @AuraEnabled public Id lineGroupAccount;
        @AuraEnabled public String entific;
        @AuraEnabled public Boolean access;
        @AuraEnabled public Boolean hasGodAccess;
        @AuraEnabled public List<RiskRow> risks;
        @AuraEnabled public List<FieldConfig> fieldConfigs;
    }

    public class CloneResponse {
        @AuraEnabled public Id clonedRiskId;
        @AuraEnabled public String errorMessage;
    }

    public class SaveResponse {
        @AuraEnabled public Integer upsertedCount;
        @AuraEnabled public Integer deletedCount;
        @AuraEnabled public List<RiskRow> risks;
    }

    public class AddProductsResponse {
        @AuraEnabled public Integer createdCount;
    }

    private class LineAccessResult {
        private Boolean canEdit = false;
        private Boolean hasGodAccess = false;
    }

    @AuraEnabled(cacheable=true)
    public static DataResponse getData(Id lineId) {
        if (lineId == null) {
            throw new AuraHandledException('lineId is required');
        }

        DMT_Line__c line = [
            SELECT Id, OwnerId, Line_Id__c, Name, Status__c, Closed__c, DMT_line_template_type__c,
                   DMT_Client_Entific__c, DMT_Entity__c, Client_Type__c, Client__c, RecordType.Name
            FROM DMT_Line__c
            WHERE Id = :lineId
            LIMIT 1
        ];

        DataResponse response = new DataResponse();
        response.lineId     = line.Id;
        response.lineBusinessId = line.Line_Id__c;
        response.lineName   = line.Name;
        response.lineStatus = line.Status__c;
        response.lineType   = line.RecordType?.Name;
        response.lineClientType = line.Client_Type__c;
        response.lineClientId = line.Client__c;
        response.lineGroupAccount = line.Client__c;
        if (line.Client__c != null) {
            Account lineClient = [
                SELECT Id, DES_Group_Code__c
                FROM Account
                WHERE Id = :line.Client__c
                LIMIT 1
            ];
            response.lineGroupCode = lineClient.DES_Group_Code__c;
        }
        response.entific    = line.DMT_Client_Entific__c;
        LineAccessResult accessResult = resolveLineAccess(line);
        response.access       = accessResult.canEdit;
        response.hasGodAccess = accessResult.hasGodAccess;
        response.risks        = fetchRisks(line.Id);
        response.fieldConfigs = fetchFieldConfigs(line);
        return response;
    }

    @AuraEnabled
    public static SaveResponse saveData(Id lineId, List<RiskRow> upserts, List<Id> deleteIds) {
        if (lineId == null) {
            throw new AuraHandledException('lineId is required');
        }
        ensureLineEditable(lineId);

        SaveResponse response = new SaveResponse();
        response.upsertedCount = 0;
        response.deletedCount = 0;

        List<DMT_Risk_Line_Term__c> toUpsert = new List<DMT_Risk_Line_Term__c>();
        if (upserts != null) {
            for (RiskRow row : upserts) {
                if (row == null) {
                    continue;
                }

                DMT_Risk_Line_Term__c rec = new DMT_Risk_Line_Term__c();
                if (row.id != null) {
                    rec.Id = row.id;
                } else {
                    rec.DMT_Line__c = lineId;
                }
                rec.Name = row.name;
                rec.DMT_Amount__c = row.amount;
                rec.CurrencyIsoCode = row.currencyIsoCode;
                rec.DMT_Init_Term__c = row.initTerm;
                rec.DMT_End_Term__c = row.endTerm;
                rec.DMT_Risk_Type__c = row.riskType;
                rec.DMT_Product__c = row.productId;
                rec.DMT_LastLevelId__c = row.lastLevelId;
                rec.gf_group_priority_line_id__c = row.priority;
                toUpsert.add(rec);
            }
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert;
            response.upsertedCount = toUpsert.size();
        }

        if (deleteIds != null && !deleteIds.isEmpty()) {
            List<DMT_Risk_Line_Term__c> toDelete = [
                SELECT Id, gf_group_priority_line_id__c, DMT_Line__c, DMT_Line__r.Line_Id__c, DMT_Line__r.RecordType.Name
                FROM DMT_Risk_Line_Term__c
                WHERE Id IN :deleteIds
                AND DMT_Line__c = :lineId
            ];
            if (!toDelete.isEmpty()) {
                deleteProductCustomAssociations(toDelete);
                delete toDelete;
                response.deletedCount = toDelete.size();
            }
        }

        if (response.deletedCount > 0) {
            resequenceRiskPriorities(lineId);
        }

        response.risks = fetchRisks(lineId);
        return response;
    }

    @AuraEnabled
    public static CloneResponse cloneRisk(Id riskId, Id lineId) {
        if (riskId == null || lineId == null) {
            throw new AuraHandledException('riskId and lineId are required');
        }
        ensureLineEditable(lineId);
        CloneResponse response = new CloneResponse();
        List<String> cloneFields = buildCloneFieldList(DMT_Risk_Line_Term__c.SObjectType.getDescribe());
        String queryText = 'SELECT ' + String.join(cloneFields, ',')
            + ' FROM DMT_Risk_Line_Term__c WHERE Id = :riskId AND DMT_Line__c = :lineId LIMIT 1';
        DMT_Risk_Line_Term__c source = (DMT_Risk_Line_Term__c) Database.query(queryText);
        String sourcePriority = cloneFields.contains('gf_group_priority_line_id__c')
            ? String.valueOf(source.get('gf_group_priority_line_id__c'))
            : null;
        DMT_Risk_Line_Term__c cloned = source.clone(false, true, false, false);
        cloned.DMT_Line__c = lineId;
        if (cloneFields.contains('Name') && source.get('Name') != null) {
            cloned.put('Name', 'Copy of ' + String.valueOf(source.get('Name')));
        }
        String clonedPriority = formatPriority(nextRiskPriority(lineId));
        cloned.gf_group_priority_line_id__c = clonedPriority;
        if (Schema.SObjectType.DMT_Risk_Line_Term__c.fields.getMap().containsKey('DMT_RiskLineTermId__c')) {
            cloned.put('DMT_RiskLineTermId__c', null);
        }
        insert cloned;
        cloneRelatedRecords('DMT_Warranty__c', riskId, cloned.Id, clonedPriority);
        cloneRelatedRecords('DMT_Currency_Provision__c', riskId, cloned.Id, clonedPriority);
        cloneProductCustomAssociation(lineId, sourcePriority, clonedPriority);
        response.clonedRiskId = cloned.Id;
        return response;
    }

    private static List<String> buildCloneFieldList(Schema.DescribeSObjectResult describeResult) {
        List<String> fields = new List<String>{ 'Id' };
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
            if (fieldName == 'Id' || !dfr.isAccessible() || !dfr.isCreateable() || dfr.isCalculated() || dfr.isAutoNumber()) {
                continue;
            }
            fields.add(fieldName);
        }
        fields.sort();
        return fields;
    }

    private static void cloneRelatedRecords(String objectApiName, Id sourceRiskId, Id clonedRiskId, String clonedPriority) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        if (objectType == null) {
            return;
        }

        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        if (!fieldMap.containsKey('DMT_Risk_Line_Term__c')) {
            return;
        }

        List<String> fields = buildCloneFieldList(objectType.getDescribe());
        String queryText = 'SELECT ' + String.join(fields, ',')
            + ' FROM ' + objectApiName + ' WHERE DMT_Risk_Line_Term__c = :sourceRiskId';
        List<SObject> sourceRows = Database.query(queryText);
        if (sourceRows.isEmpty()) {
            return;
        }

        List<SObject> clonedRows = new List<SObject>();
        for (SObject sourceRow : sourceRows) {
            SObject clonedRow = sourceRow.clone(false, true, false, false);
            putIfFieldExists(clonedRow, fieldMap, 'DMT_Risk_Line_Term__c', clonedRiskId);
            putIfFieldExists(clonedRow, fieldMap, 'gf_group_priority_line_id__c', clonedPriority);
            clonedRows.add(clonedRow);
        }
        insert clonedRows;
    }

    @AuraEnabled
    public static void deleteRisk(Id riskId, Id lineId) {
        if (riskId == null || lineId == null) {
            throw new AuraHandledException('riskId and lineId are required');
        }
        ensureLineEditable(lineId);
        List<DMT_Risk_Line_Term__c> toDelete = [
            SELECT Id, gf_group_priority_line_id__c, DMT_Line__c, DMT_Line__r.Line_Id__c, DMT_Line__r.RecordType.Name
            FROM DMT_Risk_Line_Term__c
            WHERE Id = :riskId AND DMT_Line__c = :lineId
            LIMIT 1
        ];
        if (!toDelete.isEmpty()) {
            deleteProductCustomAssociations(toDelete);
            delete toDelete;
            resequenceRiskPriorities(lineId);
        }
    }

    // CIBGLOBALD-3779: parentProductName was added so the parent product selected in the Add
    // Product modal (dmt_multipleproducts_otherline, which already builds the parent/child tree)
    // gets persisted onto DMT_Commercial_Product_Description__c alongside the child product
    // reference already stored on DMT_Product__c — this mapping only happens here, at creation.
    @AuraEnabled
    public static AddProductsResponse addProducts(
        Id lineId,
        List<Id> productIds,
        String selectedTerms,
        String selectedCodes,
        String selectedName,
        String parentProductName,
        String operationType
    ) {
        if (lineId == null) {
            throw new AuraHandledException('lineId is required');
        }
        ensureLineEditable(lineId);
        if ((productIds == null || productIds.isEmpty()) && String.isBlank(selectedCodes)) {
            throw new AuraHandledException('productIds or selectedCodes is required');
        }

        List<String> termTokens = String.isBlank(selectedTerms)
            ? new List<String>()
            : selectedTerms.split(';');

        List<String> codeTokens = String.isBlank(selectedCodes)
            ? new List<String>()
            : selectedCodes.split(';');

        Map<String, Product2> productsByCode = new Map<String, Product2>();
        if (!codeTokens.isEmpty()) {
            for (Product2 productByCode : [
                SELECT Id, Name, ProductCode
                FROM Product2
                WHERE ProductCode IN :codeTokens
            ]) {
                productsByCode.put(productByCode.ProductCode, productByCode);
            }
        }

        List<Id> safeProductIds = productIds == null ? new List<Id>() : productIds;
        Map<Id, Product2> productsById = new Map<Id, Product2>([
            SELECT Id, Name, ProductCode
            FROM Product2
            WHERE Id IN :safeProductIds
        ]);

        Integer priority = [
            SELECT count()
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :lineId
        ];

        List<DMT_Risk_Line_Term__c> toInsert = new List<DMT_Risk_Line_Term__c>();

        // Prefer productIds when present: the catalog has duplicate Product2 records sharing the
        // same ProductCode, so resolving by code (productsByCode, built from a ProductCode IN
        // query that can return several rows per code) can silently link a different duplicate
        // than the one actually shown/selected in the tree. productIds is unambiguous. Callers
        // that only have a code (no id) still work via the fallback below.
        List<Product2> selectedProducts = new List<Product2>();
        if (!safeProductIds.isEmpty()) {
            for (Id productId : safeProductIds) {
                if (productsById.containsKey(productId)) {
                    selectedProducts.add(productsById.get(productId));
                }
            }
        } else if (!codeTokens.isEmpty()) {
            for (String code : codeTokens) {
                if (productsByCode.containsKey(code)) {
                    selectedProducts.add(productsByCode.get(code));
                }
            }
        }

        for (Integer idx = 0; idx < selectedProducts.size(); idx++) {
            Product2 product = selectedProducts[idx];
            String termValue = idx < termTokens.size() ? termTokens[idx] : null;

            priority++;
            DMT_Risk_Line_Term__c row = new DMT_Risk_Line_Term__c();
            row.DMT_Line__c = lineId;
            row.DMT_Product__c = product.Id;
            row.Name = (selectedProducts.size() == 1 && !String.isBlank(selectedName))
                ? selectedName
                : product.Name;
            row.DMT_Commercial_Product_Description__c = parentProductName;
            //row.DMT_Risk_Type__c = product.ProductCode;
            //row.g_expert_criteria_risk_type__c = product.ProductCode;
            row.DMT_Init_Term__c = '0';
            row.DMT_End_Term__c = termValue;
            row.gf_group_priority_line_id__c = priority > 9
                ? String.valueOf(priority)
                : '0' + String.valueOf(priority);
            applyProductHierarchyFromCode(row, product.ProductCode);
            putOperationType(row, operationType);
            toInsert.add(row);
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        AddProductsResponse response = new AddProductsResponse();
        response.createdCount = toInsert.size();
        resequenceRiskPriorities(lineId);
        return response;
    }

    private static Integer nextRiskPriority(Id lineId) {
        return [
            SELECT count()
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :lineId
        ] + 1;
    }

    private static String formatPriority(Integer priority) {
        if (priority == null) {
            return null;
        }
        return priority > 9 ? String.valueOf(priority) : '0' + String.valueOf(priority);
    }

    private static void putOperationType(DMT_Risk_Line_Term__c row, String operationType) {
        String normalizedType = operationType == 'OPP' ? 'OPP' : 'LIN';
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.DMT_Risk_Line_Term__c.fields.getMap();
        if (fieldMap.containsKey('dmt_operation_type__c')) {
            row.put('dmt_operation_type__c', normalizedType);
        } else if (fieldMap.containsKey('DMT_Operation_Type__c')) {
            row.put('DMT_Operation_Type__c', normalizedType);
        }
    }

    private static void applyProductHierarchyFromCode(DMT_Risk_Line_Term__c row, String rawCode) {
        if (row == null) {
            return;
        }

        row.g_global_product_family_id__c = null;
        row.g_global_product_subfamily_id__c = null;
        row.g_global_product_category_id__c = null;
        row.g_gbl_product_subcategory_id__c = null;
        row.g_global_product_id__c = null;

        String baseCode = String.isBlank(rawCode) ? null : rawCode.trim();
        if (String.isBlank(baseCode) || baseCode.length() != 10 || !Pattern.matches('^[0-9]+$', baseCode)) {
            return;
        }

        Integer level;
        if (baseCode.endsWith('00000000')) {
            level = 1;
        } else if (baseCode.endsWith('000000')) {
            level = 2;
        } else if (baseCode.endsWith('0000')) {
            level = 3;
        } else if (baseCode.endsWith('00')) {
            level = 4;
        } else {
            level = 5;
        }

        if (level >= 1) {
            row.g_global_product_family_id__c = baseCode.left(2) + '00000000';
        }
        if (level >= 2) {
            row.g_global_product_subfamily_id__c = baseCode.left(4) + '000000';
        }
        if (level >= 3) {
            row.g_global_product_category_id__c = baseCode.left(6) + '0000';
        }
        if (level >= 4) {
            row.g_gbl_product_subcategory_id__c = baseCode.left(8) + '00';
        }
        if (level == 5) {
            row.g_global_product_id__c = baseCode;
        }
    }

    private static void resequenceRiskPriorities(Id lineId) {
        if (lineId == null) {
            return;
        }

        List<DMT_Risk_Line_Term__c> relatedRisks = [
            SELECT Id, gf_group_priority_line_id__c, DMT_Line__r.Line_Id__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :lineId
            ORDER BY CreatedDate ASC
        ];

        if (relatedRisks.isEmpty()) {
            return;
        }

        Map<String, Schema.SObjectField> riskFieldMap = Schema.SObjectType.DMT_Risk_Line_Term__c.fields.getMap();
        Integer priority = 1;
        Map<String, String> productAssociationExternalIdRemaps = new Map<String, String>();
        for (DMT_Risk_Line_Term__c risk : relatedRisks) {
            String formattedPriority = formatPriority(priority);
            String previousPriority = risk.gf_group_priority_line_id__c;
            if (!String.isBlank(previousPriority) && previousPriority != formattedPriority) {
                String oldExternalId = buildProductAssociationExternalId(risk.DMT_Line__r.Line_Id__c, previousPriority);
                String newExternalId = buildProductAssociationExternalId(risk.DMT_Line__r.Line_Id__c, formattedPriority);
                if (!String.isBlank(oldExternalId) && !String.isBlank(newExternalId)) {
                    productAssociationExternalIdRemaps.put(oldExternalId, newExternalId);
                }
            }
            risk.gf_group_priority_line_id__c = formattedPriority;
            if (riskFieldMap.containsKey('DMT_RiskLineTermId__c')) {
                risk.put('DMT_RiskLineTermId__c', risk.DMT_Line__r.Line_Id__c + '_' + formattedPriority);
            }
            priority++;
        }
        update relatedRisks;

        Set<Id> riskIds = new Map<Id, DMT_Risk_Line_Term__c>(relatedRisks).keySet();

        List<DMT_Warranty__c> relatedWarranties = [
            SELECT Id, gf_group_priority_line_id__c, DMT_Risk_Line_Term__r.gf_group_priority_line_id__c
            FROM DMT_Warranty__c
            WHERE DMT_Risk_Line_Term__c IN :riskIds
        ];
        for (DMT_Warranty__c warranty : relatedWarranties) {
            warranty.gf_group_priority_line_id__c = warranty.DMT_Risk_Line_Term__r.gf_group_priority_line_id__c;
        }
        if (!relatedWarranties.isEmpty()) {
            update relatedWarranties;
        }

        List<DMT_Currency_Provision__c> relatedCurrencies = [
            SELECT Id, gf_group_priority_line_id__c, DMT_Risk_Line_Term__r.gf_group_priority_line_id__c
            FROM DMT_Currency_Provision__c
            WHERE DMT_Risk_Line_Term__c IN :riskIds
        ];
        for (DMT_Currency_Provision__c currencyRow : relatedCurrencies) {
            currencyRow.gf_group_priority_line_id__c = currencyRow.DMT_Risk_Line_Term__r.gf_group_priority_line_id__c;
        }
        if (!relatedCurrencies.isEmpty()) {
            update relatedCurrencies;
        }

        remapProductCustomAssociationExternalIds(productAssociationExternalIdRemaps);
    }

    private static String buildProductAssociationExternalId(String externalLineId, String priorityId) {
        if (String.isBlank(externalLineId) || String.isBlank(priorityId)) {
            return null;
        }
        return externalLineId + '_' + priorityId;
    }

    private static Boolean isOtherProductsLine(DMT_Line__c line) {
        return line != null && line.RecordType != null && line.RecordType.Name == OTHER_PRODUCTS_LINE_TYPE;
    }

    private static Boolean isOtherProductsLine(DMT_Risk_Line_Term__c risk) {
        return risk != null && risk.DMT_Line__r != null && risk.DMT_Line__r.RecordType != null
            && risk.DMT_Line__r.RecordType.Name == OTHER_PRODUCTS_LINE_TYPE;
    }

    private static void deleteProductCustomAssociations(List<DMT_Risk_Line_Term__c> risksToDelete) {
        Set<String> externalIds = new Set<String>();
        for (DMT_Risk_Line_Term__c risk : risksToDelete) {
            if (!isOtherProductsLine(risk)) {
                continue;
            }
            String externalId = buildProductAssociationExternalId(
                risk.DMT_Line__r.Line_Id__c,
                risk.gf_group_priority_line_id__c
            );
            if (!String.isBlank(externalId)) {
                externalIds.add(externalId);
            }
        }
        deleteProductCustomAssociationsByExternalIds(externalIds);
    }

    private static void deleteProductCustomAssociationsByExternalIds(Set<String> externalIds) {
        if (externalIds == null || externalIds.isEmpty()) {
            return;
        }

        List<Custom_Association__c> associations = [
            SELECT Id
            FROM Custom_Association__c
            WHERE gf_customer_group_id__c IN :externalIds
        ];
        if (associations.isEmpty()) {
            return;
        }

        Set<Id> associationIds = new Map<Id, Custom_Association__c>(associations).keySet();
        List<Custom_Association_Client__c> clients = [
            SELECT Id
            FROM Custom_Association_Client__c
            WHERE Custom_Association__c IN :associationIds
        ];
        if (!clients.isEmpty()) {
            delete clients;
        }
        delete associations;
    }

    private static void cloneProductCustomAssociation(Id lineId, String sourcePriority, String clonedPriority) {
        if (lineId == null || String.isBlank(sourcePriority) || String.isBlank(clonedPriority)) {
            return;
        }

        DMT_Line__c line = [
            SELECT Id, Line_Id__c, RecordType.Name
            FROM DMT_Line__c
            WHERE Id = :lineId
            LIMIT 1
        ];
        if (!isOtherProductsLine(line)) {
            return;
        }

        String sourceExternalId = buildProductAssociationExternalId(line.Line_Id__c, sourcePriority);
        String clonedExternalId = buildProductAssociationExternalId(line.Line_Id__c, clonedPriority);
        if (String.isBlank(sourceExternalId) || String.isBlank(clonedExternalId)) {
            return;
        }

        Schema.DescribeSObjectResult associationDescribe = Custom_Association__c.SObjectType.getDescribe();
        List<String> associationFields = buildCloneFieldList(associationDescribe);
        String associationQuery = 'SELECT ' + String.join(associationFields, ',')
            + ' FROM Custom_Association__c WHERE gf_customer_group_id__c = :sourceExternalId LIMIT 1';
        List<SObject> sourceAssociations = Database.query(associationQuery);
        if (sourceAssociations.isEmpty()) {
            return;
        }

        Map<String, Schema.SObjectField> associationFieldMap = associationDescribe.fields.getMap();
        SObject sourceAssociation = sourceAssociations[0];
        SObject clonedAssociation = sourceAssociation.clone(false, false, false, false);
        putIfFieldExists(clonedAssociation, associationFieldMap, 'DMT_Line__c', lineId);
        putIfFieldExists(clonedAssociation, associationFieldMap, 'gf_customer_group_id__c', clonedExternalId);
        insert clonedAssociation;

        Schema.DescribeSObjectResult clientDescribe = Custom_Association_Client__c.SObjectType.getDescribe();
        List<String> clientFields = buildCloneFieldList(clientDescribe);
        Id sourceAssociationId = (Id) sourceAssociation.get('Id');
        String clientQuery = 'SELECT ' + String.join(clientFields, ',')
            + ' FROM Custom_Association_Client__c WHERE Custom_Association__c = :sourceAssociationId';
        List<SObject> sourceClients = Database.query(clientQuery);
        if (sourceClients.isEmpty()) {
            return;
        }

        Map<String, Schema.SObjectField> clientFieldMap = clientDescribe.fields.getMap();
        List<SObject> clonedClients = new List<SObject>();
        for (SObject sourceClient : sourceClients) {
            SObject clonedClient = sourceClient.clone(false, false, false, false);
            putIfFieldExists(clonedClient, clientFieldMap, 'Custom_Association__c', clonedAssociation.Id);
            putIfFieldExists(clonedClient, clientFieldMap, 'gf_customer_group_id__c', clonedExternalId);
            clonedClients.add(clonedClient);
        }
        insert clonedClients;
    }

    private static void remapProductCustomAssociationExternalIds(Map<String, String> externalIdRemaps) {
        if (externalIdRemaps == null || externalIdRemaps.isEmpty()) {
            return;
        }

        Set<String> oldExternalIds = externalIdRemaps.keySet();
        List<Custom_Association__c> associations = [
            SELECT Id, gf_customer_group_id__c
            FROM Custom_Association__c
            WHERE gf_customer_group_id__c IN :oldExternalIds
        ];

        Map<Id, String> associationIdToNewExternalId = new Map<Id, String>();
        for (Custom_Association__c association : associations) {
            String newExternalId = externalIdRemaps.get(association.gf_customer_group_id__c);
            if (String.isBlank(newExternalId)) {
                continue;
            }
            associationIdToNewExternalId.put(association.Id, newExternalId);
            association.gf_customer_group_id__c = newExternalId;
        }
        if (!associations.isEmpty()) {
            update associations;
        }

        if (associationIdToNewExternalId.isEmpty()) {
            return;
        }

        List<Custom_Association_Client__c> clients = [
            SELECT Id, Custom_Association__c, gf_customer_group_id__c
            FROM Custom_Association_Client__c
            WHERE Custom_Association__c IN :associationIdToNewExternalId.keySet()
        ];
        for (Custom_Association_Client__c client : clients) {
            client.gf_customer_group_id__c = associationIdToNewExternalId.get(client.Custom_Association__c);
        }
        if (!clients.isEmpty()) {
            update clients;
        }
    }

    private static LineAccessResult resolveLineAccess(DMT_Line__c line) {
        LineAccessResult result = new LineAccessResult();
        if (line == null) {
            return result;
        }

        String statusValue = String.valueOf(line.Status__c);
        Boolean isDraft = statusValue == DMT_Constants.DRAFT;
        result.hasGodAccess = DMT_Utils.checkLineGodUser();
        if (isDraft && result.hasGodAccess) {
            result.canEdit = true;
            return result;
        }

        if (!DMT_Utils.hasWriteAccess()) {
            return result;
        }

        DMT_TeamMember__c member = getCurrentUserLineTeamMember(line.Id);
        Boolean hasTeamEditAccess = hasTeamEditAccess(member);
        if (isDraft) {
            result.canEdit = line.OwnerId == UserInfo.getUserId() || hasTeamEditAccess;
            return result;
        }

        Boolean canApprovalEdit = hasTeamEditAccess && member != null && member.DMT_ApprovalEdit__c == true;
        Boolean isApproval = statusValue == DMT_Constants.APPROVAL;
        Boolean isClosedWon = statusValue == DMT_Constants.CLOSED && String.valueOf(line.Closed__c) == DMT_Constants.WON;
        Boolean isReadyToCloseOp = statusValue == DMT_Constants.READYTOCLOSE
            && String.valueOf(line.DMT_line_template_type__c) == 'OP';
        result.canEdit = canApprovalEdit && (isApproval || isClosedWon || isReadyToCloseOp);
        return result;
    }

    private static DMT_TeamMember__c getCurrentUserLineTeamMember(Id lineId) {
        List<DMT_TeamMember__c> teamMembers = [
            SELECT Id, AccessLevel__c, DMT_ApprovalEdit__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :lineId AND User__c = :UserInfo.getUserId()
            LIMIT 1
        ];
        return teamMembers.isEmpty() ? null : teamMembers[0];
    }

    private static Boolean hasTeamEditAccess(DMT_TeamMember__c member) {
        if (member == null) {
            return false;
        }
        return member.AccessLevel__c == 'Edit' || member.AccessLevel__c == 'All';
    }

    private static void ensureLineEditable(Id lineId) {
        if (lineId == null) {
            throw new AuraHandledException('lineId is required');
        }

        DMT_Line__c line = [
            SELECT Id, OwnerId, Status__c, Closed__c, DMT_line_template_type__c
            FROM DMT_Line__c
            WHERE Id = :lineId
            LIMIT 1
        ];
        if (!resolveLineAccess(line).canEdit) {
            throw new AuraHandledException('This line cannot be edited with your current permissions and line status.');
        }
    }

    @AuraEnabled
    public static Map<String, List<String>> getRelatedSelections(Id riskId) {
        Map<String, List<String>> response = new Map<String, List<String>>{
            WARRANTY_FIELD_KEY => new List<String>(),
            CURRENCY_PROVISION_FIELD_KEY => new List<String>()
        };

        if (riskId == null) {
            return response;
        }

        for (DMT_Warranty__c row : [
            SELECT g_limits_grid_guarantee_type__c
            FROM DMT_Warranty__c
            WHERE DMT_Risk_Line_Term__c = :riskId
            ORDER BY CreatedDate ASC
        ]) {
            if (String.isBlank(row.g_limits_grid_guarantee_type__c)) {
                continue;
            }
            String value = row.g_limits_grid_guarantee_type__c.trim();
            if (!response.get(WARRANTY_FIELD_KEY).contains(value)) {
                response.get(WARRANTY_FIELD_KEY).add(value);
            }
        }

        for (DMT_Currency_Provision__c row : [
            SELECT g_currency_id__c
            FROM DMT_Currency_Provision__c
            WHERE DMT_Risk_Line_Term__c = :riskId
            ORDER BY CreatedDate ASC
        ]) {
            if (String.isBlank(row.g_currency_id__c)) {
                continue;
            }
            String value = row.g_currency_id__c.trim();
            if (!response.get(CURRENCY_PROVISION_FIELD_KEY).contains(value)) {
                response.get(CURRENCY_PROVISION_FIELD_KEY).add(value);
            }
        }

        return response;
    }

    @AuraEnabled
    public static void saveRelatedSelections(Id lineId, Id riskId, Map<String, Object> relatedValues) {
        if (riskId == null) {
            throw new AuraHandledException('riskId is required');
        }

        System.debug('=== SAVE_RELATED_SELECTIONS DEBUG ===');
        System.debug('riskId: ' + riskId + ', lineId: ' + lineId);
        System.debug('relatedValues keys: ' + (relatedValues == null ? null : relatedValues.keySet()));

        DMT_Risk_Line_Term__c riskRecord = [
            SELECT Id, DMT_Line__c, DMT_Line__r.Line_Id__c, gf_group_priority_line_id__c
            FROM DMT_Risk_Line_Term__c
            WHERE Id = :riskId
            LIMIT 1
        ];
        ensureLineEditable(riskRecord.DMT_Line__c);

        String lineBusinessId = riskRecord.DMT_Line__r == null ? null : riskRecord.DMT_Line__r.Line_Id__c;
        String riskPriority = riskRecord.gf_group_priority_line_id__c;

        Boolean hasWarrantyPayload = relatedValues != null && relatedValues.containsKey(WARRANTY_FIELD_KEY);
        Boolean hasCurrencyPayload = relatedValues != null && relatedValues.containsKey(CURRENCY_PROVISION_FIELD_KEY);
        List<String> warrantyValues = hasWarrantyPayload
            ? normalizeRelatedValues(relatedValues.get(WARRANTY_FIELD_KEY))
            : new List<String>();
        List<String> currencyProvisionValues = hasCurrencyPayload
            ? normalizeRelatedValues(relatedValues.get(CURRENCY_PROVISION_FIELD_KEY))
            : new List<String>();

        System.debug('hasWarrantyPayload: ' + hasWarrantyPayload + ', rawWarranty: '
            + (hasWarrantyPayload ? relatedValues.get(WARRANTY_FIELD_KEY) : null));
        System.debug('warrantyValues normalized (' + warrantyValues.size() + '): ' + warrantyValues);
        System.debug('hasCurrencyPayload: ' + hasCurrencyPayload + ', currencyValues normalized ('
            + currencyProvisionValues.size() + '): ' + currencyProvisionValues);

        if (hasWarrantyPayload) {
            List<DMT_Warranty__c> oldWarranties = [
                SELECT Id
                FROM DMT_Warranty__c
                WHERE DMT_Risk_Line_Term__c = :riskId
            ];
            if (!oldWarranties.isEmpty()) {
                delete oldWarranties;
            }
        }

        if (hasCurrencyPayload) {
            List<DMT_Currency_Provision__c> oldCurrencyRows = [
                SELECT Id
                FROM DMT_Currency_Provision__c
                WHERE DMT_Risk_Line_Term__c = :riskId
            ];
            if (!oldCurrencyRows.isEmpty()) {
                delete oldCurrencyRows;
            }
        }

        Map<String, Schema.SObjectField> warrantyFieldMap = Schema.SObjectType.DMT_Warranty__c.fields.getMap();
        Map<String, Schema.SObjectField> currencyProvisionFieldMap = Schema.SObjectType.DMT_Currency_Provision__c.fields.getMap();
        List<SObject> toInsert = new List<SObject>();

        if (hasWarrantyPayload) {
            for (String warrantyValue : warrantyValues) {
                SObject warrantyRecord = new DMT_Warranty__c();
                putIfFieldExists(warrantyRecord, warrantyFieldMap, 'DMT_Risk_Line_Term__c', riskId);
                putIfFieldExists(warrantyRecord, warrantyFieldMap, 'g_limits_grid_guarantee_type__c', warrantyValue);
                putIfFieldExists(warrantyRecord, warrantyFieldMap, 'gf_group_priority_line_id__c', riskPriority);
                putIfFieldExists(warrantyRecord, warrantyFieldMap, 'g_entific_id__c', 'HO');
                putIfFieldExists(warrantyRecord, warrantyFieldMap, 'gf_origin_application_type__c', '04');
                //putIfFieldExists(warrantyRecord, warrantyFieldMap, 'gf_group_line_id__c', lineBusinessId);
                putIfFieldExists(warrantyRecord, warrantyFieldMap, 'Name', warrantyValue);
                toInsert.add(warrantyRecord);
            }
            System.debug('Warranty records queued for insert: ' + warrantyValues.size());
        }

        if (hasCurrencyPayload) {
            for (String currencyValue : currencyProvisionValues) {
                SObject currencyProvisionRecord = new DMT_Currency_Provision__c();
                putIfFieldExists(currencyProvisionRecord, currencyProvisionFieldMap, 'DMT_Risk_Line_Term__c', riskId);
                putIfFieldExists(currencyProvisionRecord, currencyProvisionFieldMap, 'g_currency_id__c', currencyValue);
                putIfFieldExists(currencyProvisionRecord, currencyProvisionFieldMap, 'CurrencyIsoCode', currencyValue);
                putIfFieldExists(currencyProvisionRecord, currencyProvisionFieldMap, 'gf_group_priority_line_id__c', riskPriority);
                putIfFieldExists(currencyProvisionRecord, currencyProvisionFieldMap, 'g_entific_id__c', 'HO');
                putIfFieldExists(currencyProvisionRecord, currencyProvisionFieldMap, 'gf_origin_application_type__c', '04');
                //putIfFieldExists(currencyProvisionRecord, currencyProvisionFieldMap, 'gf_group_line_id__c', lineBusinessId);
                putIfFieldExists(currencyProvisionRecord, currencyProvisionFieldMap, 'Name', currencyValue);
                toInsert.add(currencyProvisionRecord);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
        System.debug('Total related records inserted: ' + toInsert.size());
        System.debug('=== END SAVE_RELATED_SELECTIONS DEBUG ===');
    }

    private static List<RiskRow> fetchRisks(Id lineId) {
        List<RiskRow> rows = new List<RiskRow>();
        Set<Id> riskIds = new Set<Id>();
        for (DMT_Risk_Line_Term__c rec : [
            SELECT Id, Name, DMT_Amount__c, CurrencyIsoCode, DMT_Init_Term__c,
                   DMT_End_Term__c, DMT_Risk_Type__c, DMT_Product__c,
                   DMT_LastLevelId__c, gf_group_priority_line_id__c, DMT_Operation_Type__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :lineId
            ORDER BY DMT_Init_Term__c ASC, CreatedDate ASC
        ]) {
            RiskRow row = new RiskRow();
            row.id = rec.Id;
            row.name = rec.Name;
            row.amount = rec.DMT_Amount__c;
            row.currencyIsoCode = rec.CurrencyIsoCode;
            row.initTerm = rec.DMT_Init_Term__c;
            row.endTerm = rec.DMT_End_Term__c;
            row.riskType = rec.DMT_Risk_Type__c;
            row.productId = rec.DMT_Product__c;
            row.lastLevelId = rec.DMT_LastLevelId__c;
            row.priority = rec.gf_group_priority_line_id__c;
            row.operationType = rec.DMT_Operation_Type__c;
            rows.add(row);
            riskIds.add(rec.Id);
        }

        return rows;
    }

    private static List<FieldConfig> fetchFieldConfigs(DMT_Line__c line) {
        String lineEntific = line.DMT_Client_Entific__c;
        String templateType = resolveTemplateType(line.RecordType?.Name);
        String lineSubtype = resolveLineSubtype(line.Id);

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.DMT_Risk_Line_Term__c.fields.getMap();
        Map<String, Schema.SObjectField> lineFieldMap = Schema.SObjectType.DMT_Line__c.fields.getMap();
        Map<String, String> lowerToFieldApi = new Map<String, String>();
        Map<String, String> lowerNoSuffixToFieldApi = new Map<String, String>();
        Map<String, String> lineLowerToFieldApi = new Map<String, String>();
        Map<String, String> lineLowerNoSuffixToFieldApi = new Map<String, String>();
        for (String apiName : fieldMap.keySet()) {
            String lowerApi = apiName.toLowerCase();
            lowerToFieldApi.put(lowerApi, apiName);
            String noSuffix = lowerApi.endsWith('__c')
                ? lowerApi.substring(0, lowerApi.length() - 3)
                : lowerApi;
            if (!lowerNoSuffixToFieldApi.containsKey(noSuffix)) {
                lowerNoSuffixToFieldApi.put(noSuffix, apiName);
            }
        }

        for (String apiName : lineFieldMap.keySet()) {
            String lowerApi = apiName.toLowerCase();
            lineLowerToFieldApi.put(lowerApi, apiName);
            String noSuffix = lowerApi.endsWith('__c')
                ? lowerApi.substring(0, lowerApi.length() - 3)
                : lowerApi;
            if (!lineLowerNoSuffixToFieldApi.containsKey(noSuffix)) {
                lineLowerNoSuffixToFieldApi.put(noSuffix, apiName);
            }
        }

        Map<String, FieldConfig> bestConfigByField = new Map<String, FieldConfig>();
        Map<String, Integer> bestScoreByField = new Map<String, Integer>();

          for (DMT_LineOtherTemplateConfig__mdt cfg : [
             SELECT FilterText__c, Field_View_Is_Disabled__c, Field_Edit_Is_Disabled__c,
                 LineType__c, TemplateSubtype__c, DependsOnField__c, Entific__c, isActive__c,
                 Section__c, SectionOrder__c, FieldOrder__c,
                 DisplayLabel__c, IsRequired__c, HelpText__c, VisibilityRule__c,
                 OptionsJson__c, TaxonomyCatalog__c, TaxonomyFilterRule__c,
                 DataType__c
            FROM DMT_LineOtherTemplateConfig__mdt
            WHERE isActive__c = true
              AND (Entific__c = :lineEntific OR Entific__c = null OR Entific__c = '')
              AND (LineType__c = :templateType OR LineType__c = null OR LineType__c = 'OL' OR LineType__c = 'OP')
        ]) {
            RelatedFieldTarget relatedTarget = resolveRelatedFieldTarget(cfg.FilterText__c);
            String fieldApi = relatedTarget == null
                ? resolveFieldApiName(
                    cfg.FilterText__c,
                    fieldMap,
                    lowerToFieldApi,
                    lowerNoSuffixToFieldApi
                )
                : relatedTarget.fieldKey;
            if (String.isBlank(fieldApi)) {
                continue;
            }

            Integer score = 0;
            if (cfg.Entific__c == lineEntific) {
                score += 2;
            }
            if (cfg.LineType__c == templateType) {
                score += 1;
            }
            if (cfg.TemplateSubtype__c == lineSubtype) {
                score += 1;
            }

            String configKey = fieldApi + '|' + String.valueOf(cfg.LineType__c) + '|' + String.valueOf(cfg.TemplateSubtype__c);
            if (bestScoreByField.containsKey(configKey) && bestScoreByField.get(configKey) > score) {
                continue;
            }

            Schema.DescribeFieldResult dfr = relatedTarget == null ? fieldMap.get(fieldApi).getDescribe() : null;
            FieldConfig item = new FieldConfig();
            item.fieldApiName = fieldApi;
            item.viewDisabled = cfg.Field_View_Is_Disabled__c;
            item.editDisabled = cfg.Field_Edit_Is_Disabled__c;
            item.dataType = String.isBlank(cfg.DataType__c)
                ? (relatedTarget == null ? String.valueOf(dfr.getType()) : 'multipicklist')
                : cfg.DataType__c;
            item.lineType = cfg.LineType__c;
            item.section = cfg.Section__c;
            item.sectionOrder = cfg.SectionOrder__c;
            item.fieldOrder = cfg.FieldOrder__c;
            item.displayLabel = cfg.DisplayLabel__c;
            item.isRequired = cfg.IsRequired__c;
            item.helpText = cfg.HelpText__c;
            item.visibilityRule = cfg.VisibilityRule__c;
            item.templateSubtype = cfg.TemplateSubtype__c;
            item.dependsOnField = cfg.DependsOnField__c;
            item.optionsJson = buildOptionsJson(
                cfg,
                line,
                fieldMap,
                lowerToFieldApi,
                lowerNoSuffixToFieldApi,
                lineFieldMap,
                lineLowerToFieldApi,
                lineLowerNoSuffixToFieldApi
            );
            item.taxonomyCatalog = cfg.TaxonomyCatalog__c;
            item.taxonomyFilterRule = cfg.TaxonomyFilterRule__c;
            item.picklistOptions = resolvePicklistOptions(cfg, line, fieldMap);

            if (relatedTarget == null
                && (dfr.getType() == Schema.DisplayType.Picklist || dfr.getType() == Schema.DisplayType.MultiPicklist)
                && (item.picklistOptions == null || item.picklistOptions.isEmpty())) {
                for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
                    if (!entry.isActive()) {
                        continue;
                    }
                    PicklistOption option = new PicklistOption();
                    option.label = entry.getLabel();
                    option.value = entry.getValue();
                    item.picklistOptions.add(option);
                }
            }

            bestScoreByField.put(configKey, score);
            bestConfigByField.put(configKey, item);
        }

        return new List<FieldConfig>(bestConfigByField.values());
    }

    private static List<PicklistOption> resolvePicklistOptions(
        DMT_LineOtherTemplateConfig__mdt cfg,
        DMT_Line__c line,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        if (String.isBlank(cfg.TaxonomyCatalog__c)) {
            return new List<PicklistOption>();
        }

        if (resolveRelatedFieldTarget(cfg.FilterText__c) != null) {
            return resolveTaxonomyOptions(cfg.TaxonomyCatalog__c, cfg.TaxonomyFilterRule__c);
        }

        if (!String.isBlank(cfg.DependsOnField__c)) {
            return resolveDependentTaxonomyOptions(cfg, line, fieldMap);
        }

        return resolveTaxonomyOptions(cfg.TaxonomyCatalog__c, cfg.TaxonomyFilterRule__c);
    }

    private static List<PicklistOption> resolveDependentTaxonomyOptions(
        DMT_LineOtherTemplateConfig__mdt cfg,
        DMT_Line__c line,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        return resolveTaxonomyOptions(cfg.TaxonomyCatalog__c, cfg.TaxonomyFilterRule__c);
    }

    private static List<PicklistOption> resolveTaxonomyOptions(String catalogId, String taxonomyFilterRule) {
        Map<String, TaxonomyValueWrapper> bestValuesByCode = new Map<String, TaxonomyValueWrapper>();
        Date todayDate = Date.today();

        for (DMT_Taxonomy_Values__c taxonomyValue : [
            SELECT Id, DMT_Name__c, DMT_Name_EN__c, DMT_Value__c, DMT_Cutoff_Date__c, CreatedDate,
                gf_catalog_atrb_val1_name_c__c,
                gf_catalog_atrb_val2_name__c,
                gf_catalog_atrb_val3_name__c,
                gf_catalog_atrb_val4_name__c,
                gf_catalog_atrb_val5_name__c,
                gf_catalog_atrb_val6_name__c,
                gf_catalog_atrb_val7_name__c,
                gf_catalog_atrb_val8_name__c,
                gf_catalog_atrb_val9_name__c,
                gf_catalog_atrb_val10_name__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c = :catalogId
        ]) {
            TaxonomyValueWrapper candidate = new TaxonomyValueWrapper(taxonomyValue);
            if (!candidate.matchesFilter(taxonomyFilterRule)) {
                continue;
            }
            if (!bestValuesByCode.containsKey(candidate.optionValueCode) || candidate.isCloserThan(bestValuesByCode.get(candidate.optionValueCode), todayDate)) {
                bestValuesByCode.put(candidate.optionValueCode, candidate);
            }
        }

        List<PicklistOption> result = new List<PicklistOption>();
        for (TaxonomyValueWrapper wrapper : bestValuesByCode.values()) {
            result.add(wrapper.toPicklistOption());
        }
        return result;
    }

    private static Map<String, List<PicklistOption>> buildTaxonomyDependencyMap(String catalogId, String taxonomyFilterRule) {
        Date todayDate = Date.today();
        Map<String, TaxonomyRelationshipWrapper> bestRelationships = new Map<String, TaxonomyRelationshipWrapper>();

        List<DMT_Taxonomy_Relationship__c> rels = [
            SELECT Id, DMT_Value_Catalog_Initial__c, DMT_Value_Catalog_Final__c,
                DMT_Cutoff_Date__c, CreatedDate,
                DMT_Initial_Taxonomy_Value__r.DMT_Name__c,
                DMT_Initial_Taxonomy_Value__r.DMT_Value__c,
                DMT_Final_Taxonomy_Value__r.DMT_Name__c,
                DMT_Final_Taxonomy_Value__r.DMT_Name_EN__c,
                DMT_Final_Taxonomy_Value__r.DMT_Value__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val1_name_c__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val2_name__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val3_name__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val4_name__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val5_name__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val6_name__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val7_name__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val8_name__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val9_name__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val10_name__c
            FROM DMT_Taxonomy_Relationship__c
            WHERE DMT_Id_Catalog__c = :catalogId
        ];
        System.debug('=== TAXONOMY_DEPENDENCY_MAP DEBUG ===');
        System.debug('catalogId: ' + catalogId);
        System.debug('Total taxonomy relationships found: ' + rels.size());

        for (DMT_Taxonomy_Relationship__c rel : rels) {
            TaxonomyRelationshipWrapper candidate = new TaxonomyRelationshipWrapper(rel);
            if (!candidate.matchesFilter(taxonomyFilterRule)) {
                System.debug('Relationship filtered out. initialCode: ' + candidate.initialValueCode + ', finalCode: ' + candidate.finalValueCode);
                continue;
            }
            String key = candidate.relationshipKey();
            if (!bestRelationships.containsKey(key) || candidate.isCloserThan(bestRelationships.get(key), todayDate)) {
                bestRelationships.put(key, candidate);
            }
        }

        System.debug('Total relationships after filtering: ' + bestRelationships.size());
        Map<String, List<PicklistOption>> optionsByValue = new Map<String, List<PicklistOption>>();
        for (TaxonomyRelationshipWrapper wrapper : bestRelationships.values()) {
            if (!optionsByValue.containsKey(wrapper.initialValueCode)) {
                optionsByValue.put(wrapper.initialValueCode, new List<PicklistOption>());
            }
            optionsByValue.get(wrapper.initialValueCode).add(wrapper.toPicklistOption());
            System.debug('Added option for initialCode ' + wrapper.initialValueCode + ': ' + wrapper.toPicklistOption().label);
        }

        System.debug('optionsByValue keys: ' + optionsByValue.keySet());
        for (String keyValue : optionsByValue.keySet()) {
            System.debug('Key: ' + keyValue + ' has ' + optionsByValue.get(keyValue).size() + ' options');
        }
        System.debug('=== END TAXONOMY_DEPENDENCY_MAP ===');
        return optionsByValue;
    }

    private static String buildOptionsJson(
        DMT_LineOtherTemplateConfig__mdt cfg,
        DMT_Line__c line,
        Map<String, Schema.SObjectField> fieldMap,
        Map<String, String> lowerToFieldApi,
        Map<String, String> lowerNoSuffixToFieldApi,
        Map<String, Schema.SObjectField> lineFieldMap,
        Map<String, String> lineLowerToFieldApi,
        Map<String, String> lineLowerNoSuffixToFieldApi
    ) {
        if (String.isBlank(cfg.TaxonomyCatalog__c)) {
            return cfg.OptionsJson__c;
        }

        if (resolveRelatedFieldTarget(cfg.FilterText__c) != null) {
            return JSON.serialize(resolveTaxonomyOptions(cfg.TaxonomyCatalog__c, cfg.TaxonomyFilterRule__c));
        }

        if (String.isBlank(cfg.DependsOnField__c)) {
            return JSON.serialize(resolveTaxonomyOptions(cfg.TaxonomyCatalog__c, cfg.TaxonomyFilterRule__c));
        }

        String controllerFieldApi = resolveFieldApiName(
            cfg.DependsOnField__c,
            fieldMap,
            lowerToFieldApi,
            lowerNoSuffixToFieldApi
        );

        Boolean controllerFromLine = false;
        if (String.isBlank(controllerFieldApi)) {
            controllerFieldApi = resolveFieldApiName(
                cfg.DependsOnField__c,
                lineFieldMap,
                lineLowerToFieldApi,
                lineLowerNoSuffixToFieldApi
            );
            controllerFromLine = !String.isBlank(controllerFieldApi);
        }

        Object controllerRawValue = null;
        if (line != null && !String.isBlank(controllerFieldApi)) {
            if (controllerFromLine && lineFieldMap.containsKey(controllerFieldApi)) {
                controllerRawValue = line.get(controllerFieldApi);
                System.debug('=== BUILD_OPTIONS_JSON DEBUG ===');
                System.debug('controllerFieldApi: ' + controllerFieldApi);
                System.debug('controllerRawValue: ' + controllerRawValue);
            }
        }

        Map<String, List<PicklistOption>> dependencyMap = buildTaxonomyDependencyMap(cfg.TaxonomyCatalog__c, cfg.TaxonomyFilterRule__c);
        String finalControllerValue = controllerRawValue == null ? null : String.valueOf(controllerRawValue);
        Map<String, Object> payload = new Map<String, Object>{
            'type' => 'taxonomyDependency',
            'dependsOnField' => cfg.DependsOnField__c,
            'controllerValue' => finalControllerValue,
            'defaultOptions' => resolveTaxonomyOptions(cfg.TaxonomyCatalog__c, cfg.TaxonomyFilterRule__c),
            'optionsByValue' => dependencyMap,
            'taxonomyFilterRule' => cfg.TaxonomyFilterRule__c
        };
        System.debug('DependsOnField catalog: ' + cfg.TaxonomyCatalog__c);
        System.debug('Final payload controllerValue: ' + finalControllerValue);
        System.debug('optionsByValue size: ' + dependencyMap.size());
        System.debug('optionsByValue keys: ' + dependencyMap.keySet());
        if (String.isNotBlank(finalControllerValue)) {
            System.debug('Options for controllerValue "' + finalControllerValue + '": ' + (dependencyMap.containsKey(finalControllerValue) ? String.valueOf(dependencyMap.get(finalControllerValue).size()) : 'NOT FOUND'));
        }
        System.debug('=== END BUILD_OPTIONS_JSON ===');
        return JSON.serialize(payload);
    }

    private static String resolveLineSubtype(Id lineId) {
        if (lineId == null) {
            return null;
        }

        List<DMT_Risk_Line_Term__c> rows = [
            SELECT DMT_Operation_Type__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_Line__c = :lineId
              AND DMT_Operation_Type__c != null
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (rows.isEmpty()) {
            return null;
        }

        String operationType = rows[0].DMT_Operation_Type__c;
        if (String.isNotBlank(operationType)) {
            return operationType.trim();
        }

        return null;
    }

    private static RelatedFieldTarget resolveRelatedFieldTarget(String rawFieldApi) {
        if (String.isBlank(rawFieldApi)) {
            return null;
        }

        String candidate = rawFieldApi.trim();
        String lowerCandidate = candidate.toLowerCase();

        if (lowerCandidate == 'dmt_warranty__c.g_limits_grid_guarantee_type__c'
            || lowerCandidate == 'g_limits_grid_guarantee_type__c') {
            RelatedFieldTarget result = new RelatedFieldTarget();
            result.objectApiName = 'DMT_Warranty__c';
            result.valueFieldApi = 'g_limits_grid_guarantee_type__c';
            result.fieldKey = WARRANTY_FIELD_KEY;
            return result;
        }

        if (lowerCandidate == 'dmt_currency_provision__c.g_currency_id__c'
            || lowerCandidate == 'g_currency_id__c') {
            RelatedFieldTarget result = new RelatedFieldTarget();
            result.objectApiName = 'DMT_Currency_Provision__c';
            result.valueFieldApi = 'g_currency_id__c';
            result.fieldKey = CURRENCY_PROVISION_FIELD_KEY;
            return result;
        }

        return null;
    }

    private static List<String> normalizeRelatedValues(Object rawValues) {
        List<String> normalizedValues = new List<String>();
        if (rawValues == null) {
            return normalizedValues;
        }

        if (rawValues instanceof List<Object>) {
            for (Object item : (List<Object>)rawValues) {
                String value = item == null ? null : String.valueOf(item).trim();
                if (String.isBlank(value) || normalizedValues.contains(value)) {
                    continue;
                }
                normalizedValues.add(value);
            }
            return normalizedValues;
        }

        String candidate = String.valueOf(rawValues).trim();
        if (candidate == '') {
            return normalizedValues;
        }

        for (String token : candidate.split(';')) {
            String value = token == null ? null : token.trim();
            if (String.isBlank(value) || normalizedValues.contains(value)) {
                continue;
            }
            normalizedValues.add(value);
        }
        return normalizedValues;
    }

    private static void putIfFieldExists(
        SObject record,
        Map<String, Schema.SObjectField> fieldMap,
        String fieldApi,
        Object value
    ) {
        if (record == null || fieldMap == null || String.isBlank(fieldApi) || !fieldMap.containsKey(fieldApi)) {
            return;
        }
        record.put(fieldApi, value);
    }

    private class TaxonomyValueWrapper {
        private final String valueCode;
        private final String optionValueCode;
        private final String name;
        private final String nameEn;
        private final String label;
        private final Date cutoffDate;
        private final Datetime createdDate;
        private final Map<String, Object> filterValues;

        private TaxonomyValueWrapper(DMT_Taxonomy_Values__c record) {
            this.valueCode = record.DMT_Value__c;
            this.optionValueCode = resolveTaxonomyOptionValue(record);
            this.name = record.DMT_Name__c;
            this.nameEn = record.DMT_Name_EN__c;
            this.label = String.isNotBlank(record.DMT_Name_EN__c) ? record.DMT_Name_EN__c : record.DMT_Name__c;
            this.cutoffDate = record.DMT_Cutoff_Date__c;
            this.createdDate = record.CreatedDate;
            this.filterValues = buildTaxonomyFilterValues(record);
        }

        private Boolean isCloserThan(TaxonomyValueWrapper other, Date todayDate) {
            if (other == null) {
                return true;
            }
            Integer thisDistance = distanceToToday(this.cutoffDate, todayDate);
            Integer otherDistance = distanceToToday(other.cutoffDate, todayDate);
            if (thisDistance != otherDistance) {
                return thisDistance < otherDistance;
            }
            return this.createdDate != null && (other.createdDate == null || this.createdDate.getTime() > other.createdDate.getTime());
        }

        private PicklistOption toPicklistOption() {
            PicklistOption option = new PicklistOption();
            option.label = this.label;
            option.value = this.optionValueCode;
            return option;
        }

        private Boolean matchesFilter(String taxonomyFilterRule) {
            if (String.isBlank(taxonomyFilterRule)) {
                return true;
            }
            return matchesRuleAgainstValues(taxonomyFilterRule, this.filterValues);
        }
    }

    private class TaxonomyRelationshipWrapper {
        private final String initialValueCode;
        private final String finalValueCode;
        private final String label;
        private final Date cutoffDate;
        private final Datetime createdDate;
        private final Map<String, Object> filterValues;

        private TaxonomyRelationshipWrapper(DMT_Taxonomy_Relationship__c record) {
            this.initialValueCode = record.DMT_Value_Catalog_Initial__c;
            this.finalValueCode = String.isNotBlank(record.DMT_Final_Taxonomy_Value__r?.DMT_Value__c)
                ? record.DMT_Final_Taxonomy_Value__r.DMT_Value__c
                : record.DMT_Value_Catalog_Final__c;
            this.label = String.isNotBlank(record.DMT_Final_Taxonomy_Value__r?.DMT_Name_EN__c)
                ? record.DMT_Final_Taxonomy_Value__r.DMT_Name_EN__c
                : record.DMT_Final_Taxonomy_Value__r?.DMT_Name__c;
            this.cutoffDate = record.DMT_Cutoff_Date__c;
            this.createdDate = record.CreatedDate;
            this.filterValues = buildTaxonomyFilterValues(record.DMT_Final_Taxonomy_Value__r);
            this.filterValues.put('DMT_Value__c', this.finalValueCode);
            this.filterValues.put('DMT_Name__c', this.label);
            this.filterValues.put('DMT_Cutoff_Date__c', this.cutoffDate);
        }

        private String relationshipKey() {
            return String.join(new List<String>{ this.initialValueCode, this.finalValueCode }, '|');
        }

        private Boolean isCloserThan(TaxonomyRelationshipWrapper other, Date todayDate) {
            if (other == null) {
                return true;
            }
            Integer thisDistance = distanceToToday(this.cutoffDate, todayDate);
            Integer otherDistance = distanceToToday(other.cutoffDate, todayDate);
            if (thisDistance != otherDistance) {
                return thisDistance < otherDistance;
            }
            return this.createdDate != null && (other.createdDate == null || this.createdDate.getTime() > other.createdDate.getTime());
        }

        private PicklistOption toPicklistOption() {
            PicklistOption option = new PicklistOption();
            option.value = this.finalValueCode;
            option.label = this.label;
            return option;
        }

        private Boolean matchesFilter(String taxonomyFilterRule) {
            if (String.isBlank(taxonomyFilterRule)) {
                return true;
            }
            return matchesRuleAgainstValues(taxonomyFilterRule, this.filterValues);
        }
    }

    @TestVisible
    private static Map<String, Object> buildTaxonomyFilterValues(DMT_Taxonomy_Values__c record) {
        Map<String, Object> valuesByField = new Map<String, Object>{
            'DMT_Value__c' => record?.DMT_Value__c,
            'DMT_Name__c' => record?.DMT_Name__c,
            'DMT_Name_EN__c' => record?.DMT_Name_EN__c,
            'DMT_Cutoff_Date__c' => record?.DMT_Cutoff_Date__c
        };

        putTaxonomyAttribute(valuesByField, 'val1', 'gf_catalog_atrb_val1_name_c__c', record?.gf_catalog_atrb_val1_name_c__c);
        putTaxonomyAttribute(valuesByField, 'val2', 'gf_catalog_atrb_val2_name__c', record?.gf_catalog_atrb_val2_name__c);
        putTaxonomyAttribute(valuesByField, 'val3', 'gf_catalog_atrb_val3_name__c', record?.gf_catalog_atrb_val3_name__c);
        putTaxonomyAttribute(valuesByField, 'val4', 'gf_catalog_atrb_val4_name__c', record?.gf_catalog_atrb_val4_name__c);
        putTaxonomyAttribute(valuesByField, 'val5', 'gf_catalog_atrb_val5_name__c', record?.gf_catalog_atrb_val5_name__c);
        putTaxonomyAttribute(valuesByField, 'val6', 'gf_catalog_atrb_val6_name__c', record?.gf_catalog_atrb_val6_name__c);
        putTaxonomyAttribute(valuesByField, 'val7', 'gf_catalog_atrb_val7_name__c', record?.gf_catalog_atrb_val7_name__c);
        putTaxonomyAttribute(valuesByField, 'val8', 'gf_catalog_atrb_val8_name__c', record?.gf_catalog_atrb_val8_name__c);
        putTaxonomyAttribute(valuesByField, 'val9', 'gf_catalog_atrb_val9_name__c', record?.gf_catalog_atrb_val9_name__c);
        putTaxonomyAttribute(valuesByField, 'val10', 'gf_catalog_atrb_val10_name__c', record?.gf_catalog_atrb_val10_name__c);
        return valuesByField;
    }

    @TestVisible
    private static String resolveTaxonomyOptionValue(DMT_Taxonomy_Values__c record) {
        String valueCode = record?.DMT_Value__c;
        String typeValue = record?.gf_catalog_atrb_val4_name__c;
        String categoryCode = record?.gf_catalog_atrb_val1_name_c__c;

        if (!String.isBlank(typeValue)
            && typeValue.trim().equalsIgnoreCase('Category')
            && !String.isBlank(categoryCode)) {
            return categoryCode.trim();
        }

        return valueCode;
    }

    private static void putTaxonomyAttribute(Map<String, Object> valuesByField, String alias, String fieldApi, Object value) {
        valuesByField.put(alias, value);
        valuesByField.put(alias.toUpperCase(), value);
        valuesByField.put(fieldApi, value);
    }

    private static Integer distanceToToday(Date candidateDate, Date todayDate) {
        if (candidateDate == null) {
            return Integer.valueOf(2147483647);
        }
        return Math.abs(todayDate.daysBetween(candidateDate));
    }

    @TestVisible
    private static Boolean matchesRuleAgainstValues(String rule, Map<String, Object> valuesByField) {
        String normalizedRule = rule == null ? '' : rule.trim();
        if (normalizedRule == '') {
            return true;
        }

        List<String> disjunctionClauses = normalizedRule.split('\\s*\\|\\|\\s*');
        for (String clause : disjunctionClauses) {
            Boolean clauseMatches = true;
            List<String> andConditions = clause.split('\\s*&&\\s*');
            for (String conditionRaw : andConditions) {
                if (!evaluateTaxonomyCondition(conditionRaw, valuesByField)) {
                    clauseMatches = false;
                    break;
                }
            }
            if (clauseMatches) {
                return true;
            }
        }
        return false;
    }

    private static Boolean evaluateTaxonomyCondition(String conditionRaw, Map<String, Object> valuesByField) {
        String condition = conditionRaw == null ? '' : conditionRaw.trim();
        if (condition == '') {
            return false;
        }

        Integer notContainsPos = condition.toLowerCase().indexOf(' not contains ');
        if (notContainsPos > 0) {
            String fieldName = condition.substring(0, notContainsPos).trim();
            String rhs = condition.substring(notContainsPos + ' not contains '.length()).trim();
            String leftValue = normalizeTaxonomyLiteral(valuesByField.get(fieldName)).toLowerCase();
            String rightValue = normalizeTaxonomyLiteral(parseTaxonomyLiteral(rhs)).toLowerCase();
            return !leftValue.contains(rightValue);
        }

        Integer containsPos = condition.toLowerCase().indexOf(' contains ');
        if (containsPos > 0) {
            String fieldName = condition.substring(0, containsPos).trim();
            String rhs = condition.substring(containsPos + ' contains '.length()).trim();
            String leftValue = normalizeTaxonomyLiteral(valuesByField.get(fieldName)).toLowerCase();
            String rightValue = normalizeTaxonomyLiteral(parseTaxonomyLiteral(rhs)).toLowerCase();
            return leftValue.contains(rightValue);
        }

        Integer notInPos = condition.toLowerCase().indexOf(' not in ');
        if (notInPos > 0) {
            String fieldName = condition.substring(0, notInPos).trim();
            String rhs = condition.substring(notInPos + ' not in '.length()).trim();
            List<String> rhsValues = parseListLiteral(rhs);
            String leftValue = normalizeTaxonomyLiteral(valuesByField.get(fieldName));
            return !rhsValues.contains(leftValue);
        }

        Integer inPos = condition.toLowerCase().indexOf(' in ');
        if (inPos > 0) {
            String fieldName = condition.substring(0, inPos).trim();
            String rhs = condition.substring(inPos + ' in '.length()).trim();
            List<String> rhsValues = parseListLiteral(rhs);
            String leftValue = normalizeTaxonomyLiteral(valuesByField.get(fieldName));
            return rhsValues.contains(leftValue);
        }

        Integer eqPos = condition.indexOf('==');
        if (eqPos > 0) {
            String fieldName = condition.substring(0, eqPos).trim();
            String rhs = condition.substring(eqPos + 2).trim();
            String leftValue = normalizeTaxonomyLiteral(valuesByField.get(fieldName));
            String rightValue = normalizeTaxonomyLiteral(parseTaxonomyLiteral(rhs));
            return leftValue == rightValue;
        }

        Integer neqPos = condition.indexOf('!=');
        if (neqPos > 0) {
            String fieldName = condition.substring(0, neqPos).trim();
            String rhs = condition.substring(neqPos + 2).trim();
            String leftValue = normalizeTaxonomyLiteral(valuesByField.get(fieldName));
            String rightValue = normalizeTaxonomyLiteral(parseTaxonomyLiteral(rhs));
            return leftValue != rightValue;
        }

        return false;
    }

    private static List<String> parseListLiteral(String rhs) {
        String raw = rhs == null ? '' : rhs.trim();
        if (raw.startsWith('[') && raw.endsWith(']')) {
            raw = raw.substring(1, raw.length() - 1);
        }

        List<String> values = new List<String>();
        if (raw == '') {
            return values;
        }

        for (String item : raw.split(',')) {
            String normalized = normalizeTaxonomyLiteral(parseTaxonomyLiteral(item));
            if (normalized != '') {
                values.add(normalized);
            }
        }
        return values;
    }

    @TestVisible
    private static Object parseTaxonomyLiteral(String rawValue) {
        String value = rawValue == null ? '' : rawValue.trim();
        if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith('\'') && value.endsWith('\''))) {
            return value.substring(1, value.length() - 1);
        }
        if (value.equalsIgnoreCase('true') || value.equalsIgnoreCase('false')) {
            return value.toLowerCase() == 'true';
        }
        if (Pattern.matches('^-?\\d+(\\.\\d+)?$', value)) {
            return Decimal.valueOf(value);
        }
        return value;
    }

    private static String normalizeTaxonomyLiteral(Object value) {
        if (value == null) {
            return '';
        }
        if (value instanceof Boolean) {
            return (Boolean)value ? 'true' : 'false';
        }
        return String.valueOf(value).trim();
    }

    @TestVisible
    private static Decimal toDecimalValue(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Decimal) {
            return (Decimal)value;
        }
        if (value instanceof Integer) {
            return Decimal.valueOf((Integer)value);
        }
        if (value instanceof Long) {
            return Decimal.valueOf(String.valueOf(value));
        }
        if (value instanceof Date) {
            Date dateValue = (Date)value;
            return Decimal.valueOf(String.valueOf(dateValue.daysBetween(Date.newInstance(1970, 1, 1))));
        }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception ex) {
            return null;
        }
    }

    @TestVisible
    private static String resolveFieldApiName(
        String rawFieldApi,
        Map<String, Schema.SObjectField> fieldMap,
        Map<String, String> lowerToFieldApi,
        Map<String, String> lowerNoSuffixToFieldApi
    ) {
        if (String.isBlank(rawFieldApi)) {
            return null;
        }

        String candidate = rawFieldApi.trim();
        if (candidate.contains('.')) {
            List<String> parts = candidate.split('\\.');
            candidate = parts[parts.size() - 1];
        }

        if (fieldMap.containsKey(candidate)) {
            return candidate;
        }

        String lowerCandidate = candidate.toLowerCase();
        if (lowerToFieldApi.containsKey(lowerCandidate)) {
            return lowerToFieldApi.get(lowerCandidate);
        }

        if (!lowerCandidate.endsWith('__c')) {
            String withSuffix = lowerCandidate + '__c';
            if (lowerToFieldApi.containsKey(withSuffix)) {
                return lowerToFieldApi.get(withSuffix);
            }
        }

        String noSuffixCandidate = lowerCandidate.endsWith('__c')
            ? lowerCandidate.substring(0, lowerCandidate.length() - 3)
            : lowerCandidate;
        if (lowerNoSuffixToFieldApi.containsKey(noSuffixCandidate)) {
            return lowerNoSuffixToFieldApi.get(noSuffixCandidate);
        }

        return null;
    }

    // CIBGLOBALD-3779: added the 'SANCTION' bucket so the Sanction record type (RecordType.Name
    // label "Approval") can get its own DMT_LineOtherTemplateConfig__mdt field labels/visibility,
    // without affecting Settlement/TreasurySettlement, which still fall through to 'OP'.
    @TestVisible
    private static String resolveTemplateType(String lineRecordTypeName) {
        String normalized = String.valueOf(lineRecordTypeName).toLowerCase();
        if (normalized.contains('other')) {
            return 'OL';
        }
        if (normalized == 'approval') {
            return 'SANCTION';
        }
        return 'OP';
    }

    @TestVisible
    private static List<FieldConfig> getDefaultFieldConfigs(Map<String, Schema.SObjectField> fieldMap) {
        List<String> defaults = new List<String>{
            'Name',
            'DMT_Product_Name__c',
            'DMT_Risk_Type__c',
            'DMT_Amount__c',
            'CurrencyIsoCode',
            'DMT_Init_Term__c',
            'DMT_End_Term__c',
            'gf_group_priority_line_id__c'
        };
        List<FieldConfig> result = new List<FieldConfig>();

        for (String fieldApi : defaults) {
            if (!fieldMap.containsKey(fieldApi)) {
                continue;
            }
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldApi).getDescribe();
            FieldConfig item = new FieldConfig();
            item.fieldApiName = fieldApi;
            item.viewDisabled = false;
            item.editDisabled = false;
            item.dataType = String.valueOf(dfr.getType());
            item.section = 'GENERAL';
            item.sectionOrder = 1;
            item.fieldOrder = result.size() + 1;
            item.displayLabel = dfr.getLabel();
            item.isRequired = false;
            item.templateSubtype = null;
            item.dependsOnField = null;
            item.optionsJson = null;
            item.taxonomyCatalog = null;
            item.picklistOptions = new List<PicklistOption>();
            result.add(item);
        }

        return result;
    }
}