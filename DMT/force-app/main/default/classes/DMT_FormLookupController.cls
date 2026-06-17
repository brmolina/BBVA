/**
 * DMT_FormLookupController
 *
 * Generic dynamic SOQL controller for dmt_custom_lookup.
 *
 * PERFORMANCE OPTIMISATIONS:
 *   1. Search uses 'term%' (no leading wildcard) on direct fields → index used
 *   2. Cross-object field paths split once per query, not per record
 *   3. getRecordLabel is cacheable=true → browser caches result
 *
 * Filter logic supports nested AND/OR groups.
 * Supported operators: LIKE, =, !=, <, <=, >, >=, IN
 * Default operator when omitted: LIKE
 * LIKE wildcards are the caller's responsibility — passed as-is after escaping.
 *
 * SECURITY:
 *   Field/object names validated against whitelist regex.
 *   Values escaped with String.escapeSingleQuotes().
 */
public without sharing class DMT_FormLookupController {

    private static final Pattern     SAFE_NAME = Pattern.compile('^[a-zA-Z][a-zA-Z0-9_.]*$');
    private static final Set<String> SAFE_OPS  = new Set<String>{
        'LIKE', '=', '!=', '<', '<=', '>', '>=', 'IN'
    };
    private static final Integer MAX_LIMIT = 20;

    // ─────────────────────────────────────────────────────────────────────────
    // searchRecords
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static List<Map<String, Object>> searchRecords(
        String       objectApiName,
        String       searchTerm,
        List<String> searchFields,
        String       filtersJson,
        List<String> returnFields,
        String       primaryField,
        Integer      recordLimit
    ) {
        if (String.isBlank(objectApiName))
            throw new AuraHandledException('objectApiName is required');
        if (searchFields == null || searchFields.isEmpty())
            throw new AuraHandledException('searchFields is required');
        if (returnFields == null || returnFields.isEmpty())
            throw new AuraHandledException('returnFields is required');
        if (String.isBlank(primaryField))
            throw new AuraHandledException('primaryField is required');

        validateName(objectApiName);
        validateName(primaryField);
        for (String f : searchFields) validateName(f);
        for (String f : returnFields) validateName(f);

        Integer lim = (recordLimit != null && recordLimit > 0)
            ? Math.min(recordLimit, MAX_LIMIT)
            : MAX_LIMIT;

        Set<String>  returnSet    = new Set<String>(returnFields);
        returnSet.add('Id');
        List<String> selectFields = new List<String>(returnSet);

        // Pre-split cross-object field paths once — not per record
        Map<String, List<String>> crossObjectParts = new Map<String, List<String>>();
        for (String f : selectFields) {
            if (f != 'Id' && f.contains('.')) {
                crossObjectParts.put(f, f.split('\\.'));
            }
        }

        // ── Build WHERE ───────────────────────────────────────────────────
        List<String> whereParts = new List<String>();

        Boolean hasSearch = String.isNotBlank(searchTerm);
        if (hasSearch) {
            String escaped = String.escapeSingleQuotes(searchTerm.trim());
            List<String> orParts = new List<String>();
            for (String f : searchFields) {
                // Cross-object fields can't use indexes — always wrap with %
                // Direct fields: use trailing wildcard only → index can be used
                if (f.contains('.')) {
                    orParts.add(f + ' LIKE \'%' + escaped + '%\'');
                } else {
                    orParts.add(f + ' LIKE \'' + escaped + '%\'');
                }
            }
            whereParts.add('(' + String.join(orParts, ' OR ') + ')');
        }

        // Parse filtersJson once
        if (!String.isBlank(filtersJson)) {
            Object parsed = JSON.deserializeUntyped(filtersJson);
            String filterClause = buildNode(parsed);
            if (!String.isBlank(filterClause)) {
                whereParts.add(filterClause);
            }
        }

        String whereClause = whereParts.isEmpty()
            ? ''
            : 'WHERE ' + String.join(whereParts, ' AND ');

        // ── Execute ───────────────────────────────────────────────────────
        String soql = 'SELECT ' + String.join(selectFields, ', ')
            + ' FROM '     + objectApiName
            + (String.isBlank(whereClause) ? '' : ' ' + whereClause)
            + ' ORDER BY ' + primaryField
            + ' LIMIT '    + lim;

        List<SObject> records;
        try {
            records = Database.query(soql);
        } catch (Exception e) {
            throw new AuraHandledException('Query error: ' + e.getMessage());
        }

        // ── Map results ───────────────────────────────────────────────────
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (SObject rec : records) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('id', String.valueOf(rec.Id));
            for (String fieldPath : selectFields) {
                if (fieldPath == 'Id') continue;
                if (crossObjectParts.containsKey(fieldPath)) {
                    row.put(fieldPath, getCrossObjectValue(rec, crossObjectParts.get(fieldPath)));
                } else {
                    row.put(fieldPath, rec.get(fieldPath));
                }
            }
            result.add(row);
        }
        return result;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Filter tree builder
    // ─────────────────────────────────────────────────────────────────────────

    private static String buildNode(Object node) {
        if (node instanceof List<Object>) {
            return buildGroup('AND', (List<Object>) node);
        }
        if (node instanceof Map<String, Object>) {
            Map<String, Object> m = (Map<String, Object>) node;
            if (m.containsKey('AND')) return buildGroup('AND', (List<Object>) m.get('AND'));
            if (m.containsKey('OR'))  return buildGroup('OR',  (List<Object>) m.get('OR'));
            return buildLeaf(m);
        }
        return '';
    }

    private static String buildGroup(String logicOp, List<Object> children) {
        if (children == null || children.isEmpty()) return '';
        List<String> parts = new List<String>();
        for (Object child : children) {
            String fragment = buildNode(child);
            if (!String.isBlank(fragment)) parts.add(fragment);
        }
        if (parts.isEmpty()) return '';
        return parts.size() == 1
            ? parts[0]
            : '(' + String.join(parts, ' ' + logicOp + ' ') + ')';
    }

    private static String buildLeaf(Map<String, Object> leaf) {
        String field    = (String) leaf.get('field');
        String operator = leaf.containsKey('operator')
            ? String.valueOf(leaf.get('operator')).toUpperCase()
            : 'LIKE';
        Object value    = leaf.get('value');

        if (String.isBlank(field) || value == null) return '';

        // Skip LIKE filters where the value is empty or only wildcards
        // — they would generate LIKE '%%' matching everything unintentionally
        if (operator == 'LIKE') {
            String rawVal = String.valueOf(value).replace('%', '').replace('_', '').trim();
            if (String.isBlank(rawVal)) return '';
        }

        validateName(field);
        if (!SAFE_OPS.contains(operator)) {
            throw new AuraHandledException('Unsupported operator: ' + operator);
        }

        if (operator == 'IN') {
            List<Object> rawList = (List<Object>) value;
            List<String> escaped = new List<String>();
            for (Object v : rawList) {
                escaped.add('\'' + String.escapeSingleQuotes(String.valueOf(v)) + '\'');
            }
            return field + ' IN (' + String.join(escaped, ', ') + ')';
        }

        String strValue = String.escapeSingleQuotes(String.valueOf(value));
        return field + ' ' + operator + ' \'' + strValue + '\'';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // getRecordLabel — cacheable so browser caches per recordId+field
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static String getRecordLabel(
        String objectApiName,
        String recordId,
        String labelField
    ) {
        if (String.isBlank(objectApiName)) throw new AuraHandledException('objectApiName is required');
        if (String.isBlank(recordId))      throw new AuraHandledException('recordId is required');
        if (String.isBlank(labelField))    throw new AuraHandledException('labelField is required');

        validateName(objectApiName);
        validateName(labelField);

        String soql = 'SELECT ' + labelField
            + ' FROM '   + objectApiName
            + ' WHERE Id = :recordId LIMIT 1';

        List<SObject> records;
        try {
            records = Database.query(soql);
        } catch (Exception e) {
            throw new AuraHandledException('Query error: ' + e.getMessage());
        }

        if (records.isEmpty()) return null;
        return String.valueOf(records[0].get(labelField));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static Object getCrossObjectValue(SObject rec, List<String> parts) {
        SObject current = rec;
        for (Integer i = 0; i < parts.size() - 1; i++) {
            if (current == null) return null;
            try { current = current.getSObject(parts[i]); }
            catch (Exception e) { return null; }
        }
        if (current == null) return null;
        try { return current.get(parts[parts.size() - 1]); }
        catch (Exception e) { return null; }
    }

    private static void validateName(String name) {
        if (String.isBlank(name) || !SAFE_NAME.matcher(name).matches()) {
            throw new AuraHandledException('Invalid field or object name: ' + name);
        }
    }
}