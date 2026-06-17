/**
 * @description Service class for the Opportunity Info Tab LWC.
 * Mirrors the OmniStudio payload keys while reading/writing the real Salesforce fields.
 */
public with sharing class OpportunityInfoTabService {
    private static final String STATUS_OK = 'OK';
    private static final Integer BOOKING_SUFFIX_START = 6;
    private static final Integer BOOKING_SUFFIX_LENGTH = 9;

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOpportunityInfo(String recordId) {
        try {
            ensureOpportunityReadable();
            Opportunity opp = loadOpportunity(recordId);
            Map<String, Object> response = buildOpportunityResponse(opp, recordId);
            response.put('error', STATUS_OK);
            return response;
        } catch(Exception e) {
            return errorResponse(e);
        }
    }

    @AuraEnabled
    public static Map<String, Object> saveOpportunityInfo(Map<String, Object> opportunityData) {
        try {
            ensureOpportunityUpdateable();

            String recordId = getString(opportunityData, 'Id');
            if(String.isBlank(recordId)) {
                throw new AuraHandledException('Opportunity Id is required');
            }

            validateRequiredFields(opportunityData);

            Date initialDate = parseDateValue(opportunityData.get('DMT_DATE_Initial_Date__c'));
            Date maturityDate = parseDateValue(opportunityData.get('MaturityDate'));
            validateDates(initialDate, maturityDate);

            Opportunity opp = new Opportunity(Id = recordId);
            applyOpportunityUpdates(opp, opportunityData, initialDate, maturityDate);
            update opp;

            handleXSellOperations(recordId, opportunityData);
            return getOpportunityInfo(recordId);
        } catch(Exception e) {
            return errorResponse(e);
        }
    }

    private static Opportunity loadOpportunity(String recordId) {
        String query =
            'SELECT Id, Name, StageName, Amount, CurrencyIsoCode, ' +
            'DMT_DATE_Initial_Date__c, DMT_DATE_Maturity_Date__c, DMT_CUR_Notional_Amount__c, ' +
            'DMT_CurrencyText__c, DMT_Product_Area__c, DMT_Capital_Action__c, ' +
            'DMT_ContingentCommitments__c, DMT_Confidential__c, DMT_Tenor__c, ' +
            'Entific__c, DMT_Entity__c, DMT_branch_id_c__c ' +
            'FROM Opportunity WHERE Id = :recordId LIMIT 1';
        return Database.query(query);
    }

    private static Map<String, Object> buildOpportunityResponse(Opportunity opp, String recordId) {
        Map<String, Object> response = new Map<String, Object>();
        List<Map<String, Object>> oppXSell = fetchOppXSellData(recordId);
        String payloadCurrency = (String) opp.get('DMT_CurrencyText__c');

        response.put('Id', opp.Id);
        response.put('Name', opp.Name);
        response.put('StageName', opp.StageName);
        response.put('Amount', opp.Amount);
        response.put('CurrencyIsoCode', opp.CurrencyIsoCode);
        response.put('Entific', (String) opp.get('Entific__c'));
        response.put('EntityName', (String) opp.get('DMT_Entity__c'));
        response.put('DMT_DATE_Initial_Date__c', (Date) opp.get('DMT_DATE_Initial_Date__c'));
        response.put('MaturityDate', (Date) opp.get('DMT_DATE_Maturity_Date__c'));
        response.put('NotionalAmount', (Decimal) opp.get('DMT_CUR_Notional_Amount__c'));
        response.put('NotionalAmountValue', (Decimal) opp.get('DMT_CUR_Notional_Amount__c'));
        response.put('DMT_Currency__c', payloadCurrency);
        response.put('DMT_Product_Area__c', (String) opp.get('DMT_Product_Area__c'));
        response.put('DMT_Capital_Action__c', normalizeStringValue(opp.get('DMT_Capital_Action__c')));
        response.put('DMT_ContingentCommitments__c', normalizeStringValue(opp.get('DMT_ContingentCommitments__c')));
        response.put('BookingName', buildBookingName(
            (String) opp.get('DMT_Entity__c'),
            (String) opp.get('Entific__c'),
            (String) opp.get('DMT_branch_id_c__c')
        ));
        response.put('confidential', (Boolean) opp.get('DMT_Confidential__c'));
        response.put('DMT_Tenor__c', (String) opp.get('DMT_Tenor__c'));
        response.put('todayDateFormatted', String.valueOf(System.today()));
        response.put('isReadOnlyUser', !Schema.sObjectType.Opportunity.isUpdateable());
        response.put('OppXSell', oppXSell);
        response.put('defaultCurrency', resolveDefaultCurrency(oppXSell, payloadCurrency, opp.CurrencyIsoCode));
        response.put('catalogOptions', fetchCatalogOptions());
        response.put('columnsInfo', new List<Map<String, String>>{
            new Map<String, String>{ 'fieldName' => 'Year__c', 'label' => 'YEAR' },
            new Map<String, String>{ 'fieldName' => 'g_notional_amount__c', 'label' => 'NOTIONAL AMOUNT' }
        });
        return response;
    }

    private static void applyOpportunityUpdates(
        Opportunity opp,
        Map<String, Object> opportunityData,
        Date initialDate,
        Date maturityDate
    ) {
        putStringField(opp, 'Name', getString(opportunityData, 'Name'));
        putDateField(opp, 'DMT_DATE_Initial_Date__c', initialDate, opportunityData.containsKey('DMT_DATE_Initial_Date__c'));
        putDateField(opp, 'DMT_DATE_Maturity_Date__c', maturityDate, opportunityData.containsKey('MaturityDate'));
        putStringField(opp, 'DMT_CurrencyText__c', getString(opportunityData, 'DMT_Currency__c'));
        putDecimalField(opp, 'DMT_CUR_Notional_Amount__c', toDecimal(opportunityData.get('NotionalAmountValue')));
        putStringField(opp, 'DMT_Product_Area__c', getString(opportunityData, 'DMT_Product_Area__c'));
        putStringField(opp, 'DMT_Capital_Action__c', getString(opportunityData, 'DMT_Capital_Action__c'));
        putStringField(opp, 'DMT_ContingentCommitments__c', getString(opportunityData, 'DMT_ContingentCommitments__c'));
        putStringField(opp, 'DMT_branch_id_c__c', getString(opportunityData, 'BookingName'));
        putStringField(opp, 'DMT_Entity__c', getString(opportunityData, 'EntityName'));
        putStringField(opp, 'Entific__c', getString(opportunityData, 'Entific'));
        putBooleanField(opp, 'DMT_Confidential__c', toBoolean(opportunityData.get('confidential')));
    }

    private static void validateRequiredFields(Map<String, Object> opportunityData) {
        List<String> requiredFields = new List<String>{ 'Name', 'DMT_Currency__c', 'DMT_Product_Area__c' };
        for(String fieldName : requiredFields) {
            if(String.isBlank(getString(opportunityData, fieldName))) {
                throw new AuraHandledException('Required field missing: ' + fieldName);
            }
        }
    }

    private static void validateDates(Date initialDate, Date maturityDate) {
        if(initialDate != null && initialDate < System.today()) {
            throw new AuraHandledException('The initial date cannot be less than today');
        }
        if(initialDate != null && maturityDate != null && maturityDate <= initialDate) {
            throw new AuraHandledException('The Maturity Date cannot be less than the initial date');
        }
    }

    private static Date parseDateValue(Object rawValue) {
        if(rawValue == null) {
            return null;
        }
        if(rawValue instanceof Date) {
            return (Date) rawValue;
        }
        String dateValue = String.valueOf(rawValue);
        if(String.isBlank(dateValue)) {
            return null;
        }
        try {
            return Date.valueOf(dateValue);
        } catch(Exception e) {
            throw new AuraHandledException('Invalid date format: ' + dateValue);
        }
    }

    private static List<Map<String, Object>> fetchOppXSellData(String recordId) {
        ensureXSellReadable();

        List<Map<String, Object>> xSellList = new List<Map<String, Object>>();
        for(DMT_X_Sell__c record : [
            SELECT Id, Year__c, g_notional_amount__c, DMT_Currency__c, Opportunity__c
            FROM DMT_X_Sell__c
            WHERE Opportunity__c = :recordId
            ORDER BY Year__c ASC
            LIMIT 1000
        ]) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('Id', record.Id);
            row.put('updateKeyId', record.Id);
            row.put('Year__c', record.Year__c);
            row.put('g_notional_amount__c', record.g_notional_amount__c);
            row.put('g_currency__c', record.DMT_Currency__c);
            row.put('opportunity', record.Opportunity__c);
            row.put('tabletype', 'Derivatives');
            row.put('initRead', true);
            row.put('buttonDisabled', false);
            row.put('deleteDisabled', false);
            row.put('pickDisabled', true);
            xSellList.add(row);
        }
        return xSellList;
    }

    private static void handleXSellOperations(String opportunityId, Map<String, Object> operationData) {
        if(operationData == null) {
            return;
        }

        deleteXSellRows(opportunityId, operationData.get('OppXSellDelete'));
        upsertXSellRows(opportunityId, operationData.get('OppXSell'), getString(operationData, 'defaultCurrency'));
    }

    private static void deleteXSellRows(String opportunityId, Object rowsToDelete) {
        List<String> idsToDelete = toStringList(rowsToDelete);
        if(idsToDelete.isEmpty()) {
            return;
        }

        ensureXSellDeletable();
        List<DMT_X_Sell__c> recordsToDelete = [
            SELECT Id
            FROM DMT_X_Sell__c
            WHERE Opportunity__c = :opportunityId
            AND Id IN :idsToDelete
        ];
        if(!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
        }
    }

    private static void upsertXSellRows(String opportunityId, Object rawRows, String defaultCurrency) {
        List<Object> rows = toObjectList(rawRows);
        if(rows.isEmpty()) {
            return;
        }

        ensureXSellUpsertable();
        List<DMT_X_Sell__c> recordsToUpsert = new List<DMT_X_Sell__c>();

        for(Object rowObject : rows) {
            Map<String, Object> row = (Map<String, Object>) rowObject;
            DMT_X_Sell__c record = new DMT_X_Sell__c();
            String updateKeyId = getString(row, 'updateKeyId');
            if(isSalesforceId(updateKeyId)) {
                record.Id = updateKeyId;
            }

            record.put('Opportunity__c', opportunityId);
            putStringField(record, 'Year__c', getString(row, 'Year__c'));
            putDecimalField(record, 'g_notional_amount__c', toDecimal(row.get('g_notional_amount__c')));
            putStringField(record, 'DMT_Currency__c', firstNonBlank(getString(row, 'g_currency__c'), defaultCurrency));
            recordsToUpsert.add(record);
        }

        if(!recordsToUpsert.isEmpty()) {
            upsert recordsToUpsert;
        }
    }

    private static Map<String, Object> fetchCatalogOptions() {
        Map<String, Object> catalogOptions = new Map<String, Object>();
        List<Map<String, String>> currencyOptions = new List<Map<String, String>>();

        for(Schema.PicklistEntry entry : Schema.SObjectType.Opportunity.fields.CurrencyIsoCode.getPicklistValues()) {
            if(entry.isActive()) {
                currencyOptions.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }

        catalogOptions.put('taxoC264', currencyOptions);
        return catalogOptions;
    }

    private static void ensureOpportunityReadable() {
        if(!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new AuraHandledException('Current user cannot read Opportunity');
        }
    }

    private static void ensureOpportunityUpdateable() {
        if(!Schema.sObjectType.Opportunity.isUpdateable()) {
            throw new AuraHandledException('Current user cannot update Opportunity');
        }
    }

    private static void ensureXSellReadable() {
        if(!Schema.sObjectType.DMT_X_Sell__c.isAccessible()) {
            throw new AuraHandledException('Current user cannot read DMT_X_Sell__c');
        }
    }

    private static void ensureXSellUpsertable() {
        if(!Schema.sObjectType.DMT_X_Sell__c.isCreateable() && !Schema.sObjectType.DMT_X_Sell__c.isUpdateable()) {
            throw new AuraHandledException('Current user cannot save DMT_X_Sell__c');
        }
    }

    private static void ensureXSellDeletable() {
        if(!Schema.sObjectType.DMT_X_Sell__c.isDeletable()) {
            throw new AuraHandledException('Current user cannot delete DMT_X_Sell__c');
        }
    }

    private static String resolveDefaultCurrency(List<Map<String, Object>> oppXSell, String payloadCurrency, String isoCurrency) {
        if(!oppXSell.isEmpty()) {
            String xSellCurrency = getString(oppXSell[0], 'g_currency__c');
            if(!String.isBlank(xSellCurrency)) {
                return xSellCurrency;
            }
        }
        return firstNonBlank(payloadCurrency, isoCurrency);
    }

    private static String buildBookingName(String entityName, String entific, String branchId) {
        String suffix = extractBookingSuffix(branchId);
        String bookingTail = firstNonBlank(suffix, entific, branchId);
        if(String.isBlank(entityName)) {
            return bookingTail;
        }
        return entityName + '-' + bookingTail;
    }

    private static String extractBookingSuffix(String branchId) {
        if(String.isBlank(branchId) || branchId.length() <= BOOKING_SUFFIX_START) {
            return null;
        }
        Integer endIndex = Math.min(branchId.length(), BOOKING_SUFFIX_START + BOOKING_SUFFIX_LENGTH);
        return branchId.substring(BOOKING_SUFFIX_START, endIndex);
    }

    private static String normalizeStringValue(Object value) {
        return value == null ? '' : String.valueOf(value);
    }

    private static void putStringField(SObject record, String fieldName, String value) {
        if(value != null) {
            record.put(fieldName, value);
        }
    }

    private static void putDateField(SObject record, String fieldName, Date value, Boolean wasProvided) {
        if(wasProvided && value != null) {
            record.put(fieldName, value);
        }
    }

    private static void putDecimalField(SObject record, String fieldName, Decimal value) {
        if(value != null) {
            record.put(fieldName, value);
        }
    }

    private static void putBooleanField(SObject record, String fieldName, Boolean value) {
        if(value != null) {
            record.put(fieldName, value);
        }
    }

    private static Decimal toDecimal(Object value) {
        if(value == null || String.isBlank(String.valueOf(value))) {
            return null;
        }
        return Decimal.valueOf(String.valueOf(value));
    }

    private static Boolean toBoolean(Object value) {
        if(value == null) {
            return null;
        }
        if(value instanceof Boolean) {
            return (Boolean) value;
        }
        return String.valueOf(value).toLowerCase() == 'true';
    }

    private static String getString(Map<String, Object> values, String key) {
        if(values == null || !values.containsKey(key) || values.get(key) == null) {
            return null;
        }
        return String.valueOf(values.get(key));
    }

    private static String firstNonBlank(String firstValue, String secondValue) {
        return String.isBlank(firstValue) ? secondValue : firstValue;
    }

    private static String firstNonBlank(String firstValue, String secondValue, String thirdValue) {
        return firstNonBlank(firstValue, firstNonBlank(secondValue, thirdValue));
    }

    private static List<String> toStringList(Object rawValue) {
        List<String> results = new List<String>();
        for(Object entry : toObjectList(rawValue)) {
            String value = String.valueOf(entry);
            if(!String.isBlank(value)) {
                results.add(value);
            }
        }
        return results;
    }

    private static List<Object> toObjectList(Object rawValue) {
        if(rawValue == null) {
            return new List<Object>();
        }
        return (List<Object>) JSON.deserializeUntyped(JSON.serialize(rawValue));
    }

    private static Boolean isSalesforceId(String value) {
        return !String.isBlank(value) && (value.length() == 15 || value.length() == 18);
    }

    private static Map<String, Object> errorResponse(Exception e) {
        System.debug(LoggingLevel.ERROR, 'OpportunityInfoTabService error: ' + e.getMessage());
        return new Map<String, Object>{
            'error' => 'ERROR: ' + e.getMessage()
        };
    }
}