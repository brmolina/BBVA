public with sharing class DMT_TableTenors {

    public class TenorInitData {
        @AuraEnabled public List<DMT_Opportunity_Tenor__c> tenors;
        public TenorInitData() { this.tenors = new List<DMT_Opportunity_Tenor__c>(); }
    }

    @AuraEnabled
    public static TenorInitData getTenorsData(String oppLineItemId) {
        TenorInitData result = new TenorInitData();
        Boolean isGodMode = FeatureManagement.checkPermission('DMT_Line_God');
        AccessLevel dbMode = isGodMode ? AccessLevel.SYSTEM_MODE : AccessLevel.USER_MODE;

        OpportunityLineItem parentProduct = new OpportunityLineItem(); 
        
        // 1. QUERY PARENT (Safely)
        if (String.isNotBlank(oppLineItemId)) {
            try {
                // Validate ID format before querying to avoid "Invalid id" exception
                Id validId = Id.valueOf(oppLineItemId); 
                
                List<OpportunityLineItem> parents = Database.query(
                    'SELECT Id, gf_initial_date__c, gf_maturity_date__c, g_currency_id__c, gf_amortization_type__c ' +
                    'FROM OpportunityLineItem ' +
                    'WHERE Id = :validId LIMIT 1',
                    dbMode
                );
                
                if (!parents.isEmpty()) {
                    parentProduct = parents[0];
                }
            } catch (Exception e) {
                // Swallow invalid ID or query errors. Proceed with empty/dummy parent.
                System.debug('Skipping parent query: ' + e.getMessage());
            }
        }

        // 2. FETCH EXISTING TENORS
        List<DMT_Opportunity_Tenor__c> existingTenors = new List<DMT_Opportunity_Tenor__c>();
        
        if (parentProduct.Id != null) {
            String query = 'SELECT Id, gf_tenor_date__c, ' +
                           'gj_nominal_amount_db__c, gf_nominal_amount_fb__c, ' +
                           'gf_spread_db__c, gf_spread_fb__c, ' +
                           'gf_accrual_fees_bp__c, gf_non_accrual_fees_bp__c, ' +
                           'DMT_Opportunity_Product__r.g_currency_id__c ' +
                           'FROM DMT_Opportunity_Tenor__c ' +
                           'WHERE DMT_Opportunity_Product__c = :oppLineItemId ' +
                           'ORDER BY gf_tenor_date__c ASC, CreatedDate ASC';
            existingTenors = Database.query(query, dbMode);
        }

        // --- AUTO-CLEANUP ---
        if (!existingTenors.isEmpty()) {
            Map<Date, DMT_Opportunity_Tenor__c> uniqueMap = new Map<Date, DMT_Opportunity_Tenor__c>();
            List<DMT_Opportunity_Tenor__c> recordsToDelete = new List<DMT_Opportunity_Tenor__c>();
            List<DMT_Opportunity_Tenor__c> cleanList = new List<DMT_Opportunity_Tenor__c>();

            Boolean isStrictStructure = (parentProduct.gf_amortization_type__c != 'User-Defined');
            Date initDate = parentProduct.gf_initial_date__c;
            Date matDate = parentProduct.gf_maturity_date__c;

            for (DMT_Opportunity_Tenor__c t : existingTenors) {
                Boolean shouldDelete = false;

                // A. DUPLICATE CHECK 
                if (t.gf_tenor_date__c == null || uniqueMap.containsKey(t.gf_tenor_date__c)) {
                    shouldDelete = true;
                }
                // B. STRUCTURE CHECK
                else if (isStrictStructure && t.gf_tenor_date__c != initDate && t.gf_tenor_date__c != matDate) {
                    shouldDelete = true;
                }

                if (shouldDelete) {
                    recordsToDelete.add(t);
                } else {
                    uniqueMap.put(t.gf_tenor_date__c, t);
                    cleanList.add(t);
                }
            }

            if (!recordsToDelete.isEmpty()) {
                try {
                    Database.delete(recordsToDelete, dbMode);
                } catch (Exception e) {
                    System.debug('Error auto-cleaning rows: ' + e.getMessage());
                }
                existingTenors = cleanList;
            }
        }

        // 3. GENERATE PLACEHOLDERS (If Empty)
        if (existingTenors.isEmpty()) {
            result.tenors = generatePlaceholders(parentProduct, oppLineItemId);
        } else {
            result.tenors = existingTenors;
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean calculateReadOnlyStatus(Id opportunityId) {
        Integer psCount = [
            SELECT COUNT() FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'DMT_ReadOnly'
        ];
        if (psCount > 0) return true;

        List<OpportunityTeamMember> teamMember = [
            SELECT OpportunityAccessLevel FROM OpportunityTeamMember
            WHERE OpportunityId = :opportunityId AND UserId = :UserInfo.getUserId() LIMIT 1
        ];
        if (!teamMember.isEmpty() && teamMember[0].OpportunityAccessLevel == 'Read') {
            return true;
        }
        return !DMT_Utils.hasWriteAccess();
    }

    // [FIX] generatePlaceholders prevents assignment of Invalid IDs to Lookup Fields
    private static List<DMT_Opportunity_Tenor__c> generatePlaceholders(OpportunityLineItem product, String rawId) {
        List<DMT_Opportunity_Tenor__c> placeholders = new List<DMT_Opportunity_Tenor__c>();
        
        // Determine a safe ID to assign. 
        // If rawId is 'REC0', we cannot assign it to the Lookup field.
        String safeLookupId = null;
        if (product.Id != null) {
            safeLookupId = product.Id;
        } else if (String.isNotBlank(rawId)) {
            try {
                // Only use rawId if it passes ID validation
                Id checkFormat = Id.valueOf(rawId); 
                safeLookupId = rawId;
            } catch(Exception e) {
                // rawId is 'REC0' or invalid -> Leave safeLookupId as null
            }
        }

        // 1. Initial Row
        DMT_Opportunity_Tenor__c initRow = new DMT_Opportunity_Tenor__c();
        initRow.DMT_Opportunity_Product__c = safeLookupId; // Will be null if 'REC0'
        initRow.gf_tenor_date__c = product.gf_initial_date__c;
        initRow.CurrencyIsoCode = product.g_currency_id__c;
        initRow.gj_nominal_amount_db__c = 0; initRow.gf_nominal_amount_fb__c = 0;
        initRow.gf_spread_db__c = 0; initRow.gf_spread_fb__c = 0;
        initRow.gf_accrual_fees_bp__c = 0; initRow.gf_non_accrual_fees_bp__c = 0;
        placeholders.add(initRow);

        // 2. End Row
        if (product.gf_initial_date__c != product.gf_maturity_date__c || product.gf_initial_date__c == null) {
            DMT_Opportunity_Tenor__c endRow = new DMT_Opportunity_Tenor__c();
            endRow.DMT_Opportunity_Product__c = safeLookupId; // Will be null if 'REC0'
            endRow.gf_tenor_date__c = product.gf_maturity_date__c;
            endRow.CurrencyIsoCode = product.g_currency_id__c;
            endRow.gj_nominal_amount_db__c = 0; endRow.gf_nominal_amount_fb__c = 0;
            endRow.gf_spread_db__c = 0; endRow.gf_spread_fb__c = 0;
            endRow.gf_accrual_fees_bp__c = 0; endRow.gf_non_accrual_fees_bp__c = 0;
            placeholders.add(endRow);
        }
        return placeholders;
    }

    @AuraEnabled
    public static String syncTenors(String payload) {
        AccessLevel dbMode = FeatureManagement.checkPermission('DMT_Line_God') ? AccessLevel.SYSTEM_MODE : AccessLevel.USER_MODE;

        Map<String, Object> root;
        try {
            root = (Map<String, Object>) JSON.deserializeUntyped(payload);
        } catch (Exception e) {
            throw new AuraHandledException('Error: Invalid JSON payload.');
        }

        String oppLineItemId = (String) root.get('oppLineItemId');
        if (String.isBlank(oppLineItemId)) throw new AuraHandledException('Error: Missing Opportunity Line Item ID.');

        List<Object> rawTenorList = (List<Object>) root.get('tenorData');
        String parentCurrency = null;

        String existingQuery = 'SELECT Id, gf_tenor_date__c, DMT_Opportunity_Product__r.g_currency_id__c FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :oppLineItemId ORDER BY gf_tenor_date__c ASC, CreatedDate ASC';
        List<DMT_Opportunity_Tenor__c> existingTenors = Database.query(existingQuery, dbMode);

        if (!existingTenors.isEmpty()) {
            parentCurrency = existingTenors[0].DMT_Opportunity_Product__r.g_currency_id__c;
        } else {
             try {
                String pQuery = 'SELECT g_currency_id__c FROM OpportunityLineItem WHERE Id = :oppLineItemId LIMIT 1';
                OpportunityLineItem p = (OpportunityLineItem) Database.query(pQuery, dbMode);
                parentCurrency = p.g_currency_id__c;
             } catch(Exception e) { }
        }

        Map<Date, DMT_Opportunity_Tenor__c> existingMap = new Map<Date, DMT_Opportunity_Tenor__c>();
        List<DMT_Opportunity_Tenor__c> deleteList = new List<DMT_Opportunity_Tenor__c>();

        for (DMT_Opportunity_Tenor__c t : existingTenors) {
            // Null check for safety
            if (t.gf_tenor_date__c == null) {
                deleteList.add(t); // Corrupt data, delete
                continue;
            }

            if (existingMap.containsKey(t.gf_tenor_date__c)) {
                deleteList.add(t);
            } else {
                existingMap.put(t.gf_tenor_date__c, t);
            }
        }

        List<DMT_Opportunity_Tenor__c> upsertList = new List<DMT_Opportunity_Tenor__c>();
        Set<Date> payloadProcessedDates = new Set<Date>();

        if (rawTenorList != null) {
            for (Object rawRow : rawTenorList) {
                Map<String, Object> row = (Map<String, Object>) rawRow;
                String dateStr = (String) row.get('gf_tenor_date__c');
                if (String.isBlank(dateStr)) continue;

                Date tenorDate = Date.valueOf(dateStr);
                if (payloadProcessedDates.contains(tenorDate)) {
                    continue;
                }
                payloadProcessedDates.add(tenorDate);

                DMT_Opportunity_Tenor__c record;

                if (existingMap.containsKey(tenorDate)) {
                    record = existingMap.get(tenorDate);
                } else {
                    record = new DMT_Opportunity_Tenor__c();
                    record.DMT_Opportunity_Product__c = oppLineItemId;
                    record.gf_tenor_date__c = tenorDate;
                    if (parentCurrency != null) record.CurrencyIsoCode = parentCurrency;
                }

                record.gj_nominal_amount_db__c   = parseDecimal(row.get('gj_nominal_amount_db__c'));
                record.gf_nominal_amount_fb__c   = parseDecimal(row.get('gf_nominal_amount_fb__c'));
                record.gf_spread_db__c           = parseDecimal(row.get('gf_spread_db__c'));
                record.gf_spread_fb__c           = parseDecimal(row.get('gf_spread_fb__c'));
                record.gf_accrual_fees_bp__c     = parseDecimal(row.get('gf_accrual_fees_bp__c'));
                record.gf_non_accrual_fees_bp__c = parseDecimal(row.get('gf_non_accrual_fees_bp__c'));

                upsertList.add(record);
            }
        }

        for (Date d : existingMap.keySet()) {
            if (!payloadProcessedDates.contains(d)) {
                deleteList.add(existingMap.get(d));
            }
        }

        Savepoint sp = Database.setSavepoint();
        try {
            if (!deleteList.isEmpty()) Database.delete(deleteList, dbMode);
            if (!upsertList.isEmpty()) Database.upsert(upsertList, dbMode);
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error saving Tenors: ' + e.getMessage());
        }

        String finalQuery = 'SELECT Id, gf_tenor_date__c, gj_nominal_amount_db__c, gf_nominal_amount_fb__c, gf_spread_db__c, gf_spread_fb__c, gf_accrual_fees_bp__c, gf_non_accrual_fees_bp__c FROM DMT_Opportunity_Tenor__c WHERE DMT_Opportunity_Product__c = :oppLineItemId ORDER BY gf_tenor_date__c ASC';
        List<DMT_Opportunity_Tenor__c> finalTenors = Database.query(finalQuery, dbMode);
        return JSON.serialize(finalTenors);
    }

    private static Decimal parseDecimal(Object val) {
        if (val == null) return 0;
        if (val instanceof Decimal) return (Decimal) val;
        if (val instanceof Integer) return Decimal.valueOf((Integer) val);
        if (val instanceof String) {
            String s = ((String) val).trim();
            if (String.isBlank(s)) return 0;
            return Decimal.valueOf(s);
        }
        return 0;
    }
}