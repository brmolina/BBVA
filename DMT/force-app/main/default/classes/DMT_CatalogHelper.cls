public with sharing class DMT_CatalogHelper {

    // Session-level cache to avoid re-querying the same product catalog
    private static Map<String, List<Map<String, String>>> cacheMap = new Map<String, List<Map<String, String>>>();
    private static Map<String, List<Map<String, String>>> allCatalogsCache = null;

    // Field and sort configuration for each taxonomy catalog
    private static final Map<String, Map<String, String>> CATALOG_FIELD_MAPPING = new Map<String, Map<String, String>>{
        'C264' => new Map<String, String>{
            'labelField'   => 'DMT_Value__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'DMT_Value__c',
            'orderByType'  => 'ASC'
        },
        'C245' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'DMT_Name_EN__c',
            'orderByType'  => 'ASC'
        },
        'C204' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'gf_catalog_atrb_val1_name_c__c',
            'orderByType'  => 'ASC',
            'customType'   => 'textNumeric'
        },
        'E895' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'DMT_Name_EN__c',
            'orderByType'  => 'ASC'
        },
        'C009' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'gf_catalog_atrb_val1_name_c__c',
            'orderByType'  => 'ASC',
            'customType'   => 'textNumeric'
        },
        'D971' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'DMT_Name_EN__c',
            'orderByType'  => 'ASC'
        },
        'C519' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'gf_catalog_atrb_val1_name_c__c',
            'orderByType'  => 'ASC',
            'customType'   => 'textNumeric'
        },
        'C090' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'gf_catalog_atrb_val1_name_c__c',
            'orderByType'  => 'ASC',
            'customType'   => 'textNumeric'
        },
        'C087' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'gf_catalog_atrb_val1_name_c__c',
            'orderByType'  => 'ASC',
            'customType'   => 'textNumeric'
        },
        'C162' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'DMT_Name_EN__c',
            'orderByType'  => 'ASC'
        },
        'C164' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'DMT_Name_EN__c',
            'orderByType'  => 'ASC'
        },
        'C039' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'DMT_Name_EN__c',
            'orderByType'  => 'ASC'
        }
    };

    /**
     * Returns all catalog values grouped by catalog code.
     */
     @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getAllTaxonomyCatalogValues() {
        if (allCatalogsCache != null) {
            return allCatalogsCache;
        }
        Map<String, List<Map<String, String>>> catalogMap = new Map<String, List<Map<String, String>>>();
        Set<String> catalogCodes = CATALOG_FIELD_MAPPING.keySet();

        List<DMT_Taxonomy_Values__c> allRecords = [
            SELECT Id, DMT_Value__c, DMT_Name_EN__c, gf_catalog_atrb_val1_name_c__c, DMT_Catalog__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c IN :catalogCodes
              AND DMT_Active__c = true order by DMT_Name_EN__c
        ];

        Map<String, List<DMT_Taxonomy_Values__c>> recordsByCode = new Map<String, List<DMT_Taxonomy_Values__c>>();
        for (DMT_Taxonomy_Values__c rec : allRecords) {
            if (!recordsByCode.containsKey(rec.DMT_Catalog__c)) {
                recordsByCode.put(rec.DMT_Catalog__c, new List<DMT_Taxonomy_Values__c>());
            }
            recordsByCode.get(rec.DMT_Catalog__c).add(rec);
        }

        for (String catalogCode : catalogCodes) {
            List<Map<String, String>> values = buildCatalogValues(catalogCode, recordsByCode.get(catalogCode));
            if (values != null) {
                catalogMap.put(catalogCode, values);
                cacheMap.put(catalogCode, values);
            }
        }

        allCatalogsCache = catalogMap;
        return allCatalogsCache;
    }

    /**
     * Returns the values for a single catalog code, or null if the code is not configured
     * or has no active records.
     */
     @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTaxonomyCatalogValuesByCode(String catalogCode) {
        if (String.isBlank(catalogCode) || !CATALOG_FIELD_MAPPING.containsKey(catalogCode)) {
            return null;
        }
        if (cacheMap.containsKey(catalogCode)) {
            return cacheMap.get(catalogCode);
        }

        List<DMT_Taxonomy_Values__c> records = [
            SELECT Id, DMT_Value__c, DMT_Name_EN__c, gf_catalog_atrb_val1_name_c__c, DMT_Catalog__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c = :catalogCode
              AND DMT_Active__c = true
        ];

        List<Map<String, String>> values = buildCatalogValues(catalogCode, records);
        if (values != null) {
            cacheMap.put(catalogCode, values);
        }
        return values;
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    private static List<Map<String, String>> buildCatalogValues(String catalogCode, List<DMT_Taxonomy_Values__c> records) {
        if (records == null || records.isEmpty()) {
            return null;
        }

        Map<String, String> fieldConfig = CATALOG_FIELD_MAPPING.get(catalogCode);
        String labelFieldName = fieldConfig.get('labelField');
        String valueFieldName = fieldConfig.get('valueField');
        String orderByField   = fieldConfig.get('orderBy');
        String orderByType    = fieldConfig.get('orderByType');
        String customType     = fieldConfig.get('customType');

        if (String.isNotBlank(orderByField)) {
            Boolean descending = 'DESC'.equalsIgnoreCase(orderByType);
            Boolean numeric    = 'textNumeric'.equalsIgnoreCase(customType);
            records.sort(new TaxonomyValueComparator(orderByField, descending, numeric));
        }

        List<Map<String, String>> values = new List<Map<String, String>>();
        for (DMT_Taxonomy_Values__c rec : records) {
            values.add(new Map<String, String>{
                'label' => getFieldValue(rec, labelFieldName),
                'value' => getFieldValue(rec, valueFieldName)
            });
        }
        return values;
    }

    private static String getFieldValue(DMT_Taxonomy_Values__c record, String fieldName) {
        if (fieldName == null || record == null) return '';
        Object value = record.get(fieldName);
        return value != null ? String.valueOf(value) : '';
    }

    // ─── Taxonomy sort comparator ─────────────────────────────────────────────

    private class TaxonomyValueComparator implements Comparator<DMT_Taxonomy_Values__c> {
        private String  fieldName;
        private Boolean descending;
        private Boolean numeric;

        public TaxonomyValueComparator(String fieldName, Boolean descending, Boolean numeric) {
            this.fieldName  = fieldName;
            this.descending = descending;
            this.numeric    = numeric;
        }

        public Integer compare(DMT_Taxonomy_Values__c a, DMT_Taxonomy_Values__c b) {
            String valA = a.get(fieldName) != null ? String.valueOf(a.get(fieldName)) : '';
            String valB = b.get(fieldName) != null ? String.valueOf(b.get(fieldName)) : '';
            Integer result;
            if (numeric) {
                Decimal numA = parseDecimalOrMax(valA);
                Decimal numB = parseDecimalOrMax(valB);
                result = numA < numB ? -1 : (numA > numB ? 1 : 0);
            } else {
                result = valA.compareTo(valB);
            }
            return descending ? -result : result;
        }

        private Decimal parseDecimalOrMax(String val) {
            if (String.isBlank(val)) return 999999999;
            try {
                return Decimal.valueOf(val);
            } catch (Exception e) {
                return 999999999;
            }
        }
    }
}