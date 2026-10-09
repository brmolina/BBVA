public with sharing class DMT_OpportunityProductsController {

    // Session-level cache to avoid re-querying the same product catalog
    private static Map<String, List<Map<String, String>>> cacheMap = new Map<String, List<Map<String, String>>>();

    private static final Map<String, Map<String, String>> ATTR_VALUE_MAPPING = new Map<String, Map<String, String>>{
        'LC'  => new Map<String, String>{'label' => 'Committed Line',   'value' => 'COMMITTED'},
        'LNC' => new Map<String, String>{'label' => 'Uncommitted Line', 'value' => 'UNCOMMITTED'},
        'OPP' => new Map<String, String>{'label' => 'Opportunity',      'value' => 'PENDING FORMALIZATION'}
    };

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
        }
    };

        // ─── Drawn / Undrawn restriction (CIBGLOBALD-4333) ────────────────────────
        private static final String DRAWN_UNDRAWN_CATALOG = 'D744';
        private static final String DRAWN_UNDRAWN_FIELD   = 'gf_catalog_atrb_val12_name__c';
        private static final String DRAWN_ATTR_VALUE      = 'DRAWN';
        private static final String UNDRAWN_ATTR_VALUE    = 'UNDRAWN';
        @TestVisible private static final String MODE_UNDRAWN = 'UNDRAWN';
        
    // ─── Aura: Query methods ──────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityLineItemsByOpportunityId(Id opportunityId) {
        if (opportunityId == null) {
            return new List<OpportunityLineItem>();
        }
        try {
            return DMT_Opportunity_Selector.getOpportunityLineItems(opportunityId);
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getOpportunityLineItemsByOpportunityId', 'DMT', '');
            throw new AuraHandledException('Error fetching Opportunity Line Items: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static OpportunityLineItem getOpportunityLineItemData(Id opportunityLineItemId) {
        if (opportunityLineItemId == null) {
            throw new IllegalArgumentException('opportunityLineItemId is required');
        }
        try {
            return getOpportunityLineItemDataInternal(opportunityLineItemId);
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getOpportunityLineItemData', 'DMT', '');
            throw new AuraHandledException('Error fetching Opportunity Line Item data: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static OpportunityLineItem getOpportunityLineItemDataFresh(Id opportunityLineItemId) {
        if (opportunityLineItemId == null) {
            throw new IllegalArgumentException('opportunityLineItemId is required');
        }
        try {
            return getOpportunityLineItemDataInternal(opportunityLineItemId);
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getOpportunityLineItemDataFresh', 'DMT', '');
            throw new AuraHandledException('Error fetching fresh Opportunity Line Item data: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DMT_Opportunity_Mitigant__c> getMitigantsData(Id opportunityLineItemId) {
        if (opportunityLineItemId == null) {
            throw new IllegalArgumentException('opportunityLineItemId is required');
        }
        try {
            return [
                SELECT Id, Name, DMT_Opportunity_Product__c,
                       AVC_Check__c, SCRA__c, Commercial_Percentage__c, Political_Percentage__c,
                       Internal_Rating__c, External_Rating__c, Liquidation_Period__c,
                       Mitigant_Type__c, DMT_Currency__c, Counterpart__c, Mitigant_Currency__c,
                       DMT_Country_Guarantor__c, Garantor_European_ECA__c, DMT_Scoring__c,
                       European_Bank_Check__c, End_Date__c,
                       CurrencyIsoCode, DMT_Guarantor_Display__c, DMT_Guarantor_Account__c,
                       DMT_Guarantor_Account__r.Name, DMT_Guarantor_Account__r.g_customer_id__c
                FROM DMT_Opportunity_Mitigant__c
                WHERE DMT_Opportunity_Product__c = :opportunityLineItemId
                ORDER BY CreatedDate ASC
            ];
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getMitigantsData', 'DMT', '');
            throw new AuraHandledException('Error fetching Mitigants data: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<DMT_Underlying__c> getUnderlyingsData(Id opportunityLineItemId) {
        if (opportunityLineItemId == null) {
            throw new IllegalArgumentException('opportunityLineItemId is required');
        }
        try {
            return [
                SELECT Id, Name, DMT_Underlying_Type__c,
                       DMT_Max_Amount__c, DMT_Max_Term__c,
                       DMT_Other_restrictions__c,
                       DMT_Drawn_Reference_Amount__c,
                       DMT_Undrawn_Reference_Amount__c,
                       DMT_Term__c,
                       DMT_Drawn_Speed__c,
                       DMT_Undrawn_Spread__c,
                       DMT_Upfront_Fees__c,
                       DMT_Upfront_Fees_amount__c,
                       DMT_Amortization_Type__c,
                       DMT_Interest_Payment_Frequency__c,
                       DMT_Currency__c,
                       DMT_Opportunity_Product__c
                FROM DMT_Underlying__c
                WHERE DMT_Opportunity_Product__c = :opportunityLineItemId
                ORDER BY CreatedDate ASC
            ];
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getUnderlyingsData', 'DMT', '');
            throw new AuraHandledException('Error fetching Underlyings data: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Map<String, String>> getUnderlyingOptions(Id opportunityLineItemId) {
        if (opportunityLineItemId == null) {
            throw new IllegalArgumentException('opportunityLineItemId is required');
        }

        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            Map<String, Object> productContext = getUnderlyingSourceContext(opportunityLineItemId);
            String sourceProductCode = (String) productContext.get('sourceProductCode');
            String product2Code = (String) productContext.get('product2Code');
            String productName = (String) productContext.get('productName');
            Id taxonomyValueId = (Id) productContext.get('taxonomyValueId');


            if (String.isBlank(sourceProductCode) && String.isBlank(product2Code) && String.isBlank(productName) && taxonomyValueId == null) {
                return options;
            }

            Set<String> sourceKeys = new Set<String>();
            if (String.isNotBlank(sourceProductCode)) {
                sourceKeys.add(sourceProductCode.trim());
            }
            if (String.isNotBlank(product2Code)) {
                sourceKeys.add(product2Code.trim());
            }
            if (String.isNotBlank(productName)) {
                sourceKeys.add(productName.trim());
            }

            List<DMT_Taxonomy_Values__c> sourceRows = new List<DMT_Taxonomy_Values__c>();
            if (taxonomyValueId != null) {
                sourceRows = [
                    SELECT Id, DMT_Name__c, DMT_Name_EN__c, DMT_Value__c, DMT_Key__c,
                           gf_catalog_atrb_val10_name__c, gf_catalog_atrb_val9_name__c,
                           gf_catalog_atrb_val8_name__c, gf_catalog_atrb_val7_name__c,
                           gf_catalog_atrb_val6_name__c, gf_catalog_atrb_val5_name__c,
                           gf_catalog_atrb_val4_name__c, gf_catalog_atrb_val3_name__c,
                           gf_catalog_atrb_val2_name__c, gf_catalog_atrb_val1_name_c__c
                    FROM DMT_Taxonomy_Values__c
                    WHERE DMT_Catalog__c = 'D744'
                      AND DMT_Active__c = true
                      AND Id = :taxonomyValueId
                    WITH SYSTEM_MODE
                ];

                if (sourceRows.isEmpty()) {
                    sourceRows = [
                        SELECT Id, DMT_Name__c, DMT_Name_EN__c, DMT_Value__c, DMT_Key__c,
                               gf_catalog_atrb_val10_name__c, gf_catalog_atrb_val9_name__c,
                               gf_catalog_atrb_val8_name__c, gf_catalog_atrb_val7_name__c,
                               gf_catalog_atrb_val6_name__c, gf_catalog_atrb_val5_name__c,
                               gf_catalog_atrb_val4_name__c, gf_catalog_atrb_val3_name__c,
                               gf_catalog_atrb_val2_name__c, gf_catalog_atrb_val1_name_c__c
                        FROM DMT_Taxonomy_Values__c
                        WHERE DMT_Catalog__c = 'D744'
                          AND Id = :taxonomyValueId
                        WITH SYSTEM_MODE
                    ];
                }
            }

            if (sourceRows.isEmpty()) {
                sourceRows = [
                    SELECT Id, DMT_Name__c, DMT_Name_EN__c, DMT_Value__c, DMT_Key__c,
                           gf_catalog_atrb_val10_name__c, gf_catalog_atrb_val9_name__c,
                           gf_catalog_atrb_val8_name__c, gf_catalog_atrb_val7_name__c,
                           gf_catalog_atrb_val6_name__c, gf_catalog_atrb_val5_name__c,
                           gf_catalog_atrb_val4_name__c, gf_catalog_atrb_val3_name__c,
                           gf_catalog_atrb_val2_name__c, gf_catalog_atrb_val1_name_c__c
                    FROM DMT_Taxonomy_Values__c
                    WHERE DMT_Catalog__c = 'D744'
                      AND DMT_Active__c = true
                      AND (
                          DMT_Name__c IN :sourceKeys
                          OR DMT_Name_EN__c IN :sourceKeys
                          OR DMT_Value__c IN :sourceKeys
                          OR DMT_Key__c IN :sourceKeys
                          OR gf_catalog_atrb_val1_name_c__c IN :sourceKeys
                      )
                    WITH SYSTEM_MODE
                ];
            }

            if (sourceRows.isEmpty()) {
                sourceRows = [
                    SELECT Id, DMT_Name__c, DMT_Name_EN__c, DMT_Value__c, DMT_Key__c,
                           gf_catalog_atrb_val10_name__c, gf_catalog_atrb_val9_name__c,
                           gf_catalog_atrb_val8_name__c, gf_catalog_atrb_val7_name__c,
                           gf_catalog_atrb_val6_name__c, gf_catalog_atrb_val5_name__c,
                           gf_catalog_atrb_val4_name__c, gf_catalog_atrb_val3_name__c,
                           gf_catalog_atrb_val2_name__c, gf_catalog_atrb_val1_name_c__c
                    FROM DMT_Taxonomy_Values__c
                    WHERE DMT_Catalog__c = 'D744'
                      AND (
                          DMT_Name__c IN :sourceKeys
                          OR DMT_Name_EN__c IN :sourceKeys
                          OR DMT_Value__c IN :sourceKeys
                          OR DMT_Key__c IN :sourceKeys
                          OR gf_catalog_atrb_val1_name_c__c IN :sourceKeys
                      )
                    WITH SYSTEM_MODE
                ];
            }


            if (sourceRows.isEmpty()) {
                return options;
            }

            Set<String> taxonomyValues = new Set<String>();
            Set<String> fallbackTaxonomyValues = new Set<String>();
            Boolean includeAllUnderlyingsByU = false;
            for (DMT_Taxonomy_Values__c sourceRow : sourceRows) {

                if (String.isNotBlank(sourceRow.gf_catalog_atrb_val9_name__c)) {
                    for (String token : sourceRow.gf_catalog_atrb_val9_name__c.split('[,;|/]')) {
                        String trimmedToken = token != null ? token.trim() : null;
                        if (String.isNotBlank(trimmedToken) && trimmedToken.toUpperCase() == 'ALL') {
                            includeAllUnderlyingsByU = true;
                            break;
                        }
                    }
                }

                String rawList = sourceRow.gf_catalog_atrb_val9_name__c;
                if (String.isNotBlank(rawList)) {
                    for (String token : rawList.split('[,;|/]')) {
                        String trimmed = token != null ? token.trim() : null;
                        if (String.isNotBlank(trimmed) && trimmed.toUpperCase() != 'ALL') {
                            taxonomyValues.add(trimmed);
                        }
                    }
                }

                // Some legacy D744 rows store related products in attr1.
                // Use it only as fallback to avoid prioritizing non-business labels.
                String rawFallbackList = sourceRow.gf_catalog_atrb_val1_name_c__c;
                if (String.isNotBlank(rawFallbackList)) {
                    for (String token : rawFallbackList.split('[,;|/]')) {
                        String trimmed = token != null ? token.trim() : null;
                        if (String.isNotBlank(trimmed)) {
                            fallbackTaxonomyValues.add(trimmed);
                        }
                    }
                }
            }

            if (taxonomyValues.isEmpty() && !includeAllUnderlyingsByU) {
                return options;
            }

            List<DMT_Taxonomy_Values__c> optionRows = [
                SELECT DMT_Value__c, DMT_Key__c, DMT_Name__c, DMT_Name_EN__c
                FROM DMT_Taxonomy_Values__c
                WHERE DMT_Catalog__c = 'D744'
                  AND DMT_Active__c = true
                  AND DMT_Value__c IN :taxonomyValues
                WITH SYSTEM_MODE
                ORDER BY DMT_Name_EN__c ASC
            ];


            if (optionRows.isEmpty()) {
                optionRows = [
                    SELECT DMT_Value__c, DMT_Key__c, DMT_Name__c, DMT_Name_EN__c
                    FROM DMT_Taxonomy_Values__c
                    WHERE DMT_Catalog__c = 'D744'
                      AND DMT_Active__c = true
                      AND DMT_Key__c IN :taxonomyValues
                    WITH SYSTEM_MODE
                    ORDER BY DMT_Name_EN__c ASC
                ];
            }

            if (optionRows.isEmpty()) {
                optionRows = [
                    SELECT DMT_Value__c, DMT_Key__c, DMT_Name__c, DMT_Name_EN__c
                    FROM DMT_Taxonomy_Values__c
                    WHERE DMT_Catalog__c = 'D744'
                      AND (DMT_Value__c IN :taxonomyValues OR DMT_Key__c IN :taxonomyValues)
                    WITH SYSTEM_MODE
                    ORDER BY DMT_Name_EN__c ASC
                ];
            }

            if (optionRows.isEmpty() && !fallbackTaxonomyValues.isEmpty()) {
                optionRows = [
                    SELECT DMT_Value__c, DMT_Key__c, DMT_Name__c, DMT_Name_EN__c
                    FROM DMT_Taxonomy_Values__c
                    WHERE DMT_Catalog__c = 'D744'
                      AND DMT_Active__c = true
                      AND (
                          DMT_Value__c IN :fallbackTaxonomyValues
                          OR DMT_Key__c IN :fallbackTaxonomyValues
                          OR DMT_Name__c IN :fallbackTaxonomyValues
                          OR DMT_Name_EN__c IN :fallbackTaxonomyValues
                      )
                    WITH SYSTEM_MODE
                    ORDER BY DMT_Name_EN__c ASC
                ];

                if (optionRows.isEmpty()) {
                    optionRows = [
                        SELECT DMT_Value__c, DMT_Key__c, DMT_Name__c, DMT_Name_EN__c
                        FROM DMT_Taxonomy_Values__c
                        WHERE DMT_Catalog__c = 'D744'
                          AND (
                              DMT_Value__c IN :fallbackTaxonomyValues
                              OR DMT_Key__c IN :fallbackTaxonomyValues
                              OR DMT_Name__c IN :fallbackTaxonomyValues
                              OR DMT_Name_EN__c IN :fallbackTaxonomyValues
                          )
                        WITH SYSTEM_MODE
                        ORDER BY DMT_Name_EN__c ASC
                    ];
                }
            }

            // Special business case:
            // If attr9 contains ALL, include every active D744 product whose attr7 contains U.
            if (includeAllUnderlyingsByU) {
                List<DMT_Taxonomy_Values__c> allUProducts = [
                    SELECT DMT_Value__c, DMT_Key__c, DMT_Name__c, DMT_Name_EN__c
                    FROM DMT_Taxonomy_Values__c
                    WHERE DMT_Catalog__c = 'D744'
                      AND DMT_Active__c = true
                      AND gf_catalog_atrb_val7_name__c LIKE '%U%'
                    WITH SYSTEM_MODE
                    ORDER BY DMT_Name_EN__c ASC
                ];

                if (allUProducts.isEmpty()) {
                    allUProducts = [
                        SELECT DMT_Value__c, DMT_Key__c, DMT_Name__c, DMT_Name_EN__c
                        FROM DMT_Taxonomy_Values__c
                        WHERE DMT_Catalog__c = 'D744'
                          AND gf_catalog_atrb_val7_name__c LIKE '%U%'
                        WITH SYSTEM_MODE
                        ORDER BY DMT_Name_EN__c ASC
                    ];
                }

                optionRows.addAll(allUProducts);
            }

            Set<String> seenValues = new Set<String>();
            for (DMT_Taxonomy_Values__c rec : optionRows) {
                String selectedUnderlying = String.isBlank(rec.DMT_Value__c)
                    ? (String.isBlank(rec.DMT_Key__c) ? rec.DMT_Name__c : rec.DMT_Key__c)
                    : rec.DMT_Value__c;
                if (String.isBlank(selectedUnderlying) || seenValues.contains(selectedUnderlying)) {
                    continue;
                }
                String displayLabel = String.isBlank(rec.DMT_Name_EN__c)
                    ? (String.isBlank(rec.DMT_Name__c) ? selectedUnderlying : rec.DMT_Name__c)
                    : rec.DMT_Name_EN__c;
                seenValues.add(selectedUnderlying);
                options.add(new Map<String, String>{
                    'label' => displayLabel,
                    'value' => selectedUnderlying
                });
            }

            // CIBGLOBALD-4333: modo Drawn/Undrawn de cada underlying según taxonomy
            Set<String> optionValues = new Set<String>();
            for (Map<String, String> opt : options) {
                optionValues.add(opt.get('value'));
            }
            Map<String, String> modesByValue = getDrawnUndrawnModes(optionValues, 'DMT_Value__c');
            for (Map<String, String> opt : options) {
                String mode = modesByValue.get(opt.get('value'));
                opt.put('drawnUndrawnMode', mode == null ? '' : mode);
            }
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getUnderlyingOptions', 'DMT', '');
            throw new AuraHandledException('Error fetching Underlying options: ' + e.getMessage());
        }

        return options;
    }

    private static Map<String, Object> getUnderlyingSourceContext(Id opportunityLineItemId) {
        String soql =
            'SELECT ProductCode, Product2.Name, Product2.ProductCode, Product2.DMT_Taxonomy_Value__c';

        Map<String, Schema.SObjectField> oliFields = OpportunityLineItem.SObjectType.getDescribe().fields.getMap();
        Boolean hasGlobalProductField = oliFields.containsKey('DMT_Global_Product__c'.toLowerCase());
        if (hasGlobalProductField) {
            soql += ', DMT_Global_Product__c';
        }

        soql += ' FROM OpportunityLineItem WHERE Id = :opportunityLineItemId WITH SYSTEM_MODE LIMIT 1';

        OpportunityLineItem oli = Database.query(soql);
        String sourceProductCode = oli.ProductCode;
        String product2Code = oli.Product2 != null ? oli.Product2.ProductCode : null;
        String productName = oli.Product2 != null ? oli.Product2.Name : null;
        Id taxonomyValueId = null;
        if (hasGlobalProductField) {
            taxonomyValueId = (Id) oli.get('DMT_Global_Product__c');
        }
        if (taxonomyValueId == null && oli.Product2 != null) {
            taxonomyValueId = oli.Product2.DMT_Taxonomy_Value__c;
        }

        return new Map<String, Object>{
                    'sourceProductCode' => sourceProductCode,
                    'product2Code' => product2Code,
                    'productName' => productName,
                    'taxonomyValueId' => taxonomyValueId
                };
            }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRiskTypeOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            Set<String> validValueIds = new Set<String>();
            for (DMT_Taxonomy_Hierarchy__c h : [
                SELECT gf_hierarchy_node_value_id__c
                FROM DMT_Taxonomy_Hierarchy__c
                WHERE g_hierarchy_node_catalog_id__c = 'B444'
            ]) {
                validValueIds.add(h.gf_hierarchy_node_value_id__c);
            }

            List<DMT_Taxonomy_Values__c> records = [
                SELECT DMT_Name_EN__c, DMT_Value__c
                FROM DMT_Taxonomy_Values__c
                WHERE DMT_Catalog__c = 'B444'
                  AND DMT_Value__c IN :validValueIds
                  AND DMT_Active__c = true
                  AND gf_catalog_atrb_val1_name_c__c LIKE '%TO%'
            ];

            for (DMT_Taxonomy_Values__c rec : records) {
                options.add(new Map<String, String>{
                    'label' => rec.DMT_Name_EN__c,
                    'value' => rec.DMT_Value__c
                });
            }
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getRiskTypeOptions', 'DMT', '');
            throw new AuraHandledException('Error fetching Risk Type options: ' + e.getMessage());
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getProductLineTypeOptions(String productName, String productCode) {
        if (String.isBlank(productName) || String.isBlank(productCode)) {
            return new List<Map<String, String>>();
        }

        String cacheKey = productName + '_' + productCode;
        if (cacheMap.containsKey(cacheKey)) {
            return cacheMap.get(cacheKey);
        }

        List<Map<String, String>> options = new List<Map<String, String>>();
        //try {
            List<DMT_Taxonomy_Values__c> records = [
                SELECT gf_catalog_atrb_val7_name__c
                FROM DMT_Taxonomy_Values__c
                WHERE DMT_Catalog__c = 'D744'
                  AND DMT_Name_EN__c = :productName
                  AND gf_catalog_atrb_val1_name_c__c = :productCode
                  AND gf_catalog_atrb_val5_name__c LIKE '%TO%'
                  AND gf_catalog_atrb_val7_name__c != null
            ];

            Set<String> addedValues = new Set<String>();
            for (DMT_Taxonomy_Values__c rec : records) {
                String attrValue = rec.gf_catalog_atrb_val7_name__c;
                for (String key : ATTR_VALUE_MAPPING.keySet()) {
                    if (attrValue.contains(key)) {
                        Map<String, String> optionConfig = ATTR_VALUE_MAPPING.get(key);
                        String optionValue = optionConfig.get('value');
                        if (!addedValues.contains(optionValue)) {
                            options.add(new Map<String, String>{
                                'label' => optionConfig.get('label'),
                                'value' => optionValue
                            });
                            addedValues.add(optionValue);
                        }
                    }
                }
            }
            cacheMap.put(cacheKey, options);
        /* } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getProductLineTypeOptions', 'DMT', '');
            throw new AuraHandledException('Error fetching Product Line Type options: ' + e.getMessage());
        } */
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getTaxonomyCatalogValues() {
        Map<String, List<Map<String, String>>> catalogMap = new Map<String, List<Map<String, String>>>();
        try {
            Set<String> catalogCodes = CATALOG_FIELD_MAPPING.keySet();

            List<DMT_Taxonomy_Values__c> allRecords = [
                SELECT Id, DMT_Value__c, DMT_Name_EN__c, gf_catalog_atrb_val1_name_c__c, DMT_Catalog__c
                FROM DMT_Taxonomy_Values__c
                WHERE DMT_Catalog__c IN :catalogCodes
                  AND DMT_Active__c = true
            ];

            // Group records by catalog code to avoid multiple iterations
            Map<String, List<DMT_Taxonomy_Values__c>> recordsByCode = new Map<String, List<DMT_Taxonomy_Values__c>>();
            for (DMT_Taxonomy_Values__c rec : allRecords) {
                if (!recordsByCode.containsKey(rec.DMT_Catalog__c)) {
                    recordsByCode.put(rec.DMT_Catalog__c, new List<DMT_Taxonomy_Values__c>());
                }
                recordsByCode.get(rec.DMT_Catalog__c).add(rec);
            }

            for (String catalogCode : catalogCodes) {
                List<Map<String, String>> values = new List<Map<String, String>>();
                List<DMT_Taxonomy_Values__c> records = recordsByCode.get(catalogCode);

                if (records != null && !records.isEmpty()) {
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
                    Set<String> seenKeys = new Set<String>();
                    for (DMT_Taxonomy_Values__c rec : records) {
                        String label = getFieldValue(rec, labelFieldName);
                        String value = getFieldValue(rec, valueFieldName);
                        // For C264, skip duplicates based on DMT_Value__c
                        if (catalogCode == 'C264') {
                            if (seenKeys.contains(value)) {
                                continue;
                            }
                            seenKeys.add(value);
                        }
                        values.add(new Map<String, String>{
                            'label' => label,
                            'value' => value
                        });
                    }
                    catalogMap.put(catalogCode, values);
                }
            }
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getTaxonomyCatalogValues', 'DMT', '');
            throw new AuraHandledException('Error fetching Taxonomy Catalog Values: ' + e.getMessage());
        }
        return catalogMap;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getGuarantorFieldConfiguration() {
        Map<String, Object> config = new Map<String, Object>();
        try {
            config.put('catalogValues', getTaxonomyCatalogValues());
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getGuarantorFieldConfiguration', 'DMT', '');
            throw new AuraHandledException('Error fetching guarantor config: ' + e.getMessage());
        }
        return config;
    }

    // ─── Aura: DML operations ─────────────────────────────────────────────────

    @AuraEnabled
    public static Map<String, Object> createProductsOpportunity(List<Object> products, Object opportunityId, String contextCode) {
        try {
            return DMT_Opportunity_Utils.createProductsOpportunity(products, opportunityId, contextCode);
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'createProductsOpportunity', 'DMT', '');
            throw new AuraHandledException('Error creating products: ' + e.getMessage());
        }
    }

    public static Map<String, Object> createProductsOpportunity(List<Object> products, Object opportunityId) {
        return createProductsOpportunity(products, opportunityId, null);
    }

    @AuraEnabled
    public static Boolean deleteOpportunityLineItem(Id opportunityLineItemId) {
        if (opportunityLineItemId == null) {
            throw new IllegalArgumentException('opportunityLineItemId is required');
        }
        try {
            OpportunityLineItem oliToDelete = [
                SELECT Id, OpportunityId
                FROM OpportunityLineItem
                WHERE Id = :opportunityLineItemId
                LIMIT 1
            ];
            delete oliToDelete;
            markPassportAsObsolete(oliToDelete.OpportunityId);
            return true;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'deleteOpportunityLineItem', 'DMT', '');
            throw new AuraHandledException('Error deleting Opportunity Line Item: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> cloneOpportunityLineItem(Id opportunityLineItemId) {
        if (opportunityLineItemId == null) {
            throw new IllegalArgumentException('opportunityLineItemId is required');
        }
        // Savepoint to roll back everything if any part of the clone fails
        Savepoint sp = Database.setSavepoint();
        try {
            OpportunityLineItem sourceLineItem = getOpportunityLineItemById(opportunityLineItemId);
            OpportunityLineItem clonedLineItem = sourceLineItem.clone(false, true, false, false);
            insert clonedLineItem;

            cloneOpportunityLineItemTenors(opportunityLineItemId, clonedLineItem.Id);
            cloneOpportunityLineItemMitigants(opportunityLineItemId, clonedLineItem.Id);
            cloneOpportunityLineItemUnderlyings(opportunityLineItemId, clonedLineItem.Id);
            markPassportAsObsolete(sourceLineItem.OpportunityId);

            return new Map<String, Object>{
                'clonedOpportunityLineItemId' => clonedLineItem.Id
            };
        } catch (Exception ex) {
            Database.rollback(sp);
            DES_Exception_Utils.logException(ex,'DMT_OpportunityProductsController', 'cloneOpportunityLineItem', 'DMT', '');
            throw new AuraHandledException('Error cloning Opportunity Line Item: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> validateTenors(
        List<Object> rawTenors,
        Date initialDate,
        Date maturityDate
    ) {
        if (rawTenors == null || rawTenors.isEmpty()) {
            throw new IllegalArgumentException('rawTenors is required');
        }
        return DMT_Opportunity_Utils.validateTenorsFromRaw(rawTenors, initialDate, maturityDate);
    }

    @AuraEnabled
    public static Map<String, Object> saveOpportunityProduct(
        Map<String, Object>  recordFields,
        List<Object>         tenorsToUpsert,
        List<Id>             tenorsToDelete,
        List<Object>         mitigantsToUpsert,
        List<Id>             mitigantsToDelete,
        List<Object>         underlyingsToUpsert,
        List<Id>             underlyingsToDelete,
        Date                 initialDate,
        Date                 maturityDate,
        String               oppId
    ) {
        Map<String, Object> result = new Map<String, Object>();
        Savepoint sp = Database.setSavepoint();
        try {

            // Convert Aura's internal map type to proper Map<String,Object>
            List<Map<String, Object>> tenorMaps = toTypedMaps(tenorsToUpsert);
            List<Map<String, Object>> mitigantMaps = toTypedMaps(mitigantsToUpsert);

            // 1. Validate tenors before any DML
            if (!tenorMaps.isEmpty()) {
                List<Object> rawTenors = new List<Object>();
                for (Map<String, Object> m : tenorMaps) { rawTenors.add(m); }
                Map<String, Object> validation = DMT_Opportunity_Utils.validateTenorsFromRaw(
                    rawTenors, initialDate, maturityDate
                );
                if (validation.get('validationPassed') != true) {
                    result.put('success', false);
                    result.put('errorMessage', validation.get('errorMessage'));
                    result.put('error', validation);
                    result.put('stage', 'tenorValidation');
                    return result;
                }
            }

            // 2. Validate mitigants before any DML
            if (!mitigantMaps.isEmpty()) {
                List<Object> rawMitigants = new List<Object>();
                for (Map<String, Object> m : mitigantMaps) { rawMitigants.add(m); }
                Map<String, Object> mitigantValidation = DMT_Opportunity_Utils.validateRealGuaratorsFromRaw(
                    rawMitigants
                );
                if (mitigantValidation.get('validationPassed') != true) {
                    result.put('success', false);
                    result.put('errorMessage', mitigantValidation.get('errorMessage'));
                    result.put('error', mitigantValidation);
                    result.put('stage', 'mitigantValidation');
                    return result;
                }
            }

            // 3. Update the main OLI record
            if (recordFields != null && recordFields.containsKey('Id') && recordFields.size() > 1) {
                Id recordId = (Id) recordFields.get('Id');
                OpportunityLineItem oli = new OpportunityLineItem(Id = recordId);
                OpportunityLineItem existingOli = [
                    SELECT DMT_Commitment_Line_Amount__c, bbva_prtcp_tranche_amount__c, DMT_NewMoney_BBVA__c,
                           g_currency_id__c, Opportunity.DMT_CurrencyText__c
                    FROM OpportunityLineItem
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                Map<String, Schema.DisplayType> oliTypes = buildTypeMap(OpportunityLineItem.SObjectType);
                for (String key : recordFields.keySet()) {
                    if (key == 'Id') continue;
                    oli.put(key, castValue(oliTypes, key, recordFields.get(key)));
                }
                // Apply currency conversion to amount fields using the OLI currency.
                String currency4Oli = null;
                if (recordFields.containsKey('g_currency_id__c') && recordFields.get('g_currency_id__c') != null
                    && String.isNotBlank(String.valueOf(recordFields.get('g_currency_id__c')))) {
                    currency4Oli = String.valueOf(recordFields.get('g_currency_id__c'));
                } else {
                    OpportunityLineItem oliCur = [
                        SELECT g_currency_id__c, Opportunity.DMT_CurrencyText__c
                        FROM OpportunityLineItem WHERE Id = :recordId LIMIT 1
                    ];
                    currency4Oli = String.isNotBlank(oliCur.g_currency_id__c)
                        ? oliCur.g_currency_id__c
                        : oliCur.Opportunity.DMT_CurrencyText__c;
                }
                if (String.isNotBlank(currency4Oli)) {
                    if (oli.DMT_Deal_amount__c != null) {
                        oli.DMT_Deal_amount__c = DMT_Currency_Conversion_Utils.convertToStorage(currency4Oli, oli.DMT_Deal_amount__c);
                    }
                    if (oli.DMT_Commitment_Line_Amount__c != null) {
                        oli.DMT_Commitment_Line_Amount__c = DMT_Currency_Conversion_Utils.convertToStorage(currency4Oli, oli.DMT_Commitment_Line_Amount__c);
                    }
                    if (oli.bbva_prtcp_tranche_amount__c != null) {
                        oli.bbva_prtcp_tranche_amount__c = DMT_Currency_Conversion_Utils.convertToStorage(currency4Oli, oli.bbva_prtcp_tranche_amount__c);
                    }
                    if (oli.DMT_NewMoney_BBVA__c != null) {
                        oli.DMT_NewMoney_BBVA__c = DMT_Currency_Conversion_Utils.convertToStorage(currency4Oli, oli.DMT_NewMoney_BBVA__c);
                    }
                    if (oli.syndicated_loan_drawn_amount__c != null) {
                        oli.syndicated_loan_drawn_amount__c = DMT_Currency_Conversion_Utils.convertToStorage(currency4Oli, oli.syndicated_loan_drawn_amount__c);
                    }

                    Decimal bbvaCommitment = oli.bbva_prtcp_tranche_amount__c;
                    if (bbvaCommitment == null) bbvaCommitment = existingOli.bbva_prtcp_tranche_amount__c;
                    if (bbvaCommitment == null) bbvaCommitment = oli.DMT_Commitment_Line_Amount__c;
                    if (bbvaCommitment == null) bbvaCommitment = existingOli.DMT_Commitment_Line_Amount__c;

                    Decimal newMoney = oli.DMT_NewMoney_BBVA__c;
                    if (newMoney == null) newMoney = existingOli.DMT_NewMoney_BBVA__c;
                    if (newMoney == null) newMoney = bbvaCommitment;

                    if (bbvaCommitment != null && newMoney != null) {
                        oli.DMT_OldMoney_BBVA__c = DMT_Currency_Conversion_Utils.convertToStorage(currency4Oli, bbvaCommitment - newMoney);
                    }
                }
                update oli;
            }

            // 4. Upsert tenors
            if (!tenorMaps.isEmpty()) {
                // Get the OLI currency for amount conversion
                String oliCurrency = null;
                if (recordFields != null && recordFields.containsKey('Id')) {
                    if (recordFields.containsKey('g_currency_id__c') && recordFields.get('g_currency_id__c') != null
                        && String.isNotBlank(String.valueOf(recordFields.get('g_currency_id__c')))) {
                        oliCurrency = String.valueOf(recordFields.get('g_currency_id__c'));
                    } else {
                        Id oliId = (Id) recordFields.get('Id');
                        OpportunityLineItem oliForCurrency = [
                            SELECT g_currency_id__c, Opportunity.DMT_CurrencyText__c
                            FROM OpportunityLineItem WHERE Id = :oliId LIMIT 1
                        ];
                        oliCurrency = String.isNotBlank(oliForCurrency.g_currency_id__c)
                            ? oliForCurrency.g_currency_id__c
                            : oliForCurrency.Opportunity.DMT_CurrencyText__c;
                    }
                }

                Id parentOliId = (Id) recordFields.get('Id');
                List<DMT_Opportunity_Tenor__c> toUpsert = new List<DMT_Opportunity_Tenor__c>();
                Map<String, Schema.DisplayType> tenorTypes = buildTypeMap(DMT_Opportunity_Tenor__c.SObjectType);
                for (Map<String, Object> t : tenorMaps) {
                    DMT_Opportunity_Tenor__c tenor = new DMT_Opportunity_Tenor__c();
                    for (String key : t.keySet()) {
                        if (key == 'Id') {
                            if (t.get(key) != null && String.isNotBlank(String.valueOf(t.get(key)))) {
                                tenor.Id = (Id) t.get(key);
                            }
                        } else {
                            tenor.put(key, castValue(tenorTypes, key, t.get(key)));
                        }
                    }
                    // Apply currency conversion to nominal amount fields
                    if (String.isNotBlank(oliCurrency)) {
                        if (tenor.gj_nominal_amount_db__c != null) {
                            tenor.gj_nominal_amount_db__c = DMT_Currency_Conversion_Utils.convertToStorage(oliCurrency, tenor.gj_nominal_amount_db__c);
                        }
                        if (tenor.gf_nominal_amount_fb__c != null) {
                            tenor.gf_nominal_amount_fb__c = DMT_Currency_Conversion_Utils.convertToStorage(oliCurrency, tenor.gf_nominal_amount_fb__c);
                        }
                    }
                    if (parentOliId != null) {
                        tenor.DMT_Opportunity_Product__c = parentOliId;
                    }
                    toUpsert.add(tenor);
                }
                upsert toUpsert;

                if (recordFields != null && recordFields.containsKey('Id')) {
                    Id oliId = (Id) recordFields.get('Id');
                    OpportunityLineItem oliForRecalc = [
                        SELECT g_currency_id__c, Opportunity.DMT_CurrencyText__c, DMT_NewMoney_BBVA__c
                        FROM OpportunityLineItem
                        WHERE Id = :oliId
                        LIMIT 1
                    ];

                    Map<String, Object> tenorSource = tenorMaps[0];
                    Decimal drawnAmount = 0;
                    Decimal undrawnAmount = 0;

                    if (tenorSource.get('gj_nominal_amount_db__c') != null && String.isNotBlank(String.valueOf(tenorSource.get('gj_nominal_amount_db__c')))) {
                        drawnAmount = Decimal.valueOf(String.valueOf(tenorSource.get('gj_nominal_amount_db__c')));
                    }
                    if (tenorSource.get('gf_nominal_amount_fb__c') != null && String.isNotBlank(String.valueOf(tenorSource.get('gf_nominal_amount_fb__c')))) {
                        undrawnAmount = Decimal.valueOf(String.valueOf(tenorSource.get('gf_nominal_amount_fb__c')));
                    }

                    String currency4Oli = String.isNotBlank(oliForRecalc.g_currency_id__c) ? oliForRecalc.g_currency_id__c : oliForRecalc.Opportunity.DMT_CurrencyText__c;
                    Decimal bbvaCommitmentDisplay = drawnAmount + undrawnAmount;
                    Decimal bbvaCommitmentStorage = String.isNotBlank(currency4Oli) ? DMT_Currency_Conversion_Utils.convertToStorage(currency4Oli, bbvaCommitmentDisplay) : bbvaCommitmentDisplay;
                    Decimal newMoney = oliForRecalc.DMT_NewMoney_BBVA__c == null ? bbvaCommitmentStorage : oliForRecalc.DMT_NewMoney_BBVA__c;
                    update new OpportunityLineItem(
                        Id = oliId,
                        bbva_prtcp_tranche_amount__c = bbvaCommitmentStorage,
                        DMT_OldMoney_BBVA__c = bbvaCommitmentStorage - newMoney
                    );
                }
            }

            // 5. Delete tenors
            if (tenorsToDelete != null && !tenorsToDelete.isEmpty()) {
                List<DMT_Opportunity_Tenor__c> tenorsForDelete = new List<DMT_Opportunity_Tenor__c>();
                for (Id tId : tenorsToDelete) {
                    tenorsForDelete.add(new DMT_Opportunity_Tenor__c(Id = tId));
                }
                delete tenorsForDelete;
            }

            // 6. Upsert mitigants
            if (!mitigantMaps.isEmpty()) {
                List<DMT_Opportunity_Mitigant__c> toUpsert = new List<DMT_Opportunity_Mitigant__c>();
                Map<String, Schema.DisplayType> mitTypes = buildTypeMap(DMT_Opportunity_Mitigant__c.SObjectType);
                for (Map<String, Object> m : mitigantMaps) {
                    DMT_Opportunity_Mitigant__c mit = new DMT_Opportunity_Mitigant__c();
                    for (String key : m.keySet()) {
                        if (key == 'Id') {
                            if (m.get(key) != null && String.isNotBlank(String.valueOf(m.get(key)))) {
                                mit.Id = (Id) m.get(key);
                            }
                        } else {
                            mit.put(key, castValue(mitTypes, key, m.get(key)));
                        }
                    }
                    toUpsert.add(mit);
                }
                upsert toUpsert;
            }

            // 7. Delete mitigants
            if (mitigantsToDelete != null && !mitigantsToDelete.isEmpty()) {
                List<DMT_Opportunity_Mitigant__c> mitigantsForDelete = new List<DMT_Opportunity_Mitigant__c>();
                for (Id mId : mitigantsToDelete) {
                    mitigantsForDelete.add(new DMT_Opportunity_Mitigant__c(Id = mId));
                }
                delete mitigantsForDelete;
            }
            
            // 8. Upsert underlyings
            if (underlyingsToUpsert != null && !underlyingsToUpsert.isEmpty()) {
                List<Map<String, Object>> underlyingMaps = toTypedMaps(underlyingsToUpsert);
                List<DMT_Underlying__c> toUpsert = new List<DMT_Underlying__c>();
                Map<String, Schema.DisplayType> underlyingTypes = buildTypeMap(DMT_Underlying__c.SObjectType);
                for (Map<String, Object> u : underlyingMaps) {
                    DMT_Underlying__c underlying = new DMT_Underlying__c();
                    for (String key : u.keySet()) {
                        if (key == 'Id') {
                            if (u.get(key) != null && String.isNotBlank(String.valueOf(u.get(key)))) {
                                underlying.Id = (Id) u.get(key);
                            }
                        } else if (key == 'Name') {
                            underlying.Name = String.valueOf(u.get(key));
                        } else {
                            underlying.put(key, castValue(underlyingTypes, key, u.get(key)));
                        }
                    }
                    toUpsert.add(underlying);
                }
                upsert toUpsert;
            }

            // 9. Delete underlyings
            if (underlyingsToDelete != null && !underlyingsToDelete.isEmpty()) {
                List<DMT_Underlying__c> underlyingsForDelete = new List<DMT_Underlying__c>();
                for (Id uId : underlyingsToDelete) {
                    underlyingsForDelete.add(new DMT_Underlying__c(Id = uId));
                }
                delete underlyingsForDelete;
            }
            
            // 10. update passport
            if(oppId != null && oppId != '') {
                List<Passport__c> passports = [SELECT Id, DMT_Is_Obsoleted_Passport_Save__c FROM Passport__c WHERE Opportunity__c =:oppId LIMIT 1];

                if (!passports.isEmpty()) {
                    passports[0].DMT_Is_Obsoleted_Passport_Save__c = true;
                    update passports[0];
                }
            }
            result.put('success', true);
            return result;

        } catch (Exception e) {

            Database.rollback(sp);
            
            System.debug('ERROR MESSAGE: ' + e.getMessage());
            System.debug('STACK TRACE: ' + e.getStackTraceString());
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'saveOpportunityProduct', 'DMT', '');
            throw new AuraHandledException('Error saving record: ' + e.getMessage());
            
        }
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    private static OpportunityLineItem getOpportunityLineItemDataInternal(Id opportunityLineItemId) {
        OpportunityLineItem oli = getOpportunityLineItemById(opportunityLineItemId);
        oli.g_currency_id__c = String.isBlank(oli.g_currency_id__c)
            ? oli.Opportunity.DMT_CurrencyText__c
            : oli.g_currency_id__c;

        if (String.isBlank(oli.g_currency_id__c)) {
            return oli;
        }

        if (oli.DMT_Deal_amount__c != null) {
            oli.DMT_Deal_amount__c = DMT_Currency_Conversion_Utils.convertToDisplay(oli.g_currency_id__c, oli.DMT_Deal_amount__c);
        }
        if (oli.DMT_Commitment_Line_Amount__c != null) {
            oli.DMT_Commitment_Line_Amount__c = DMT_Currency_Conversion_Utils.convertToDisplay(oli.g_currency_id__c, oli.DMT_Commitment_Line_Amount__c);
        }
        if (oli.bbva_prtcp_tranche_amount__c != null) {
            oli.bbva_prtcp_tranche_amount__c = DMT_Currency_Conversion_Utils.convertToDisplay(oli.g_currency_id__c, oli.bbva_prtcp_tranche_amount__c);
        }
        if (oli.DMT_NewMoney_BBVA__c != null) {
            oli.DMT_NewMoney_BBVA__c = DMT_Currency_Conversion_Utils.convertToDisplay(oli.g_currency_id__c, oli.DMT_NewMoney_BBVA__c);
        }
        if (oli.syndicated_loan_drawn_amount__c != null) {
            oli.syndicated_loan_drawn_amount__c = DMT_Currency_Conversion_Utils.convertToDisplay(oli.g_currency_id__c, oli.syndicated_loan_drawn_amount__c);
        }
        if (oli.DMT_OldMoney_BBVA__c != null) {
            oli.DMT_OldMoney_BBVA__c = DMT_Currency_Conversion_Utils.convertToDisplay(oli.g_currency_id__c, oli.DMT_OldMoney_BBVA__c);
        }

        return oli;
    }

    private static OpportunityLineItem getOpportunityLineItemById(Id opportunityLineItemId) {
        return [
            SELECT Id, OpportunityId, DMT_TXT_ProductNameOLI__c,
                   gf_initial_date__c, gf_maturity_date__c, DMT_Risk_Type__c,
                   DMT_Line_Type__c, DMT_Line_Tenor__c, DMT_Use_of_Proceeds__c,
                   DMT_TXT_Comentarios__c, DMT_Line_Oneoffdeal__c, DMT_Line_LC_LNC__c, g_line_commitment_level_type__c,
                   loan_purpose_desc__c, gf_amortization_type__c, gf_payment_frequency__c,
                   DMT_RateType__c, DMT_bullet_amortization_indicator__c,
                   DMT_PricingGrid_OR_StepUps__c, DMT_balloon_amortization_indicator__c,
                   DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, gf_accrual_fees_bp__c,
                   DMT_Extension_Duration_Fees__c, DMT_Expected_Drawn__c,
                   DMT_Reference_Upfront_Fees__c,
                   syndicated_loan_drawn_amount__c, DMT_Line_Amount__c, DMT_Commitment_Line_Amount__c, DMT_Line_Currency__c, g_currency_id__c, Life_Funding_Type__c,
                   PricebookEntryId, Product2Id, Quantity, TotalPrice, Name, ProductCode,
                   g_product_id__c, g_branch_id__c, gf_payment_type__c,
                   gf_country_rating__c, gf_country_risk__c,
                   gf_funding_cost_db__c, gf_funding_cost_fb__c,
                   gf_green_bonus__c, gf_social_bond__c, Funding_Curve__c,
                   deal_total_amount__c, DMT_Deal_Amount_Tenors__c, DMT_Deal_amount__c,
                   entity_role_type__c, DMT_TXT_Commitment_Fees__c, DMT_Utilisation_Fee__c, DMT_TXT_Extension_Duration_Fees__c, DMT_TXT_Other_Fees_Accrual__c, DMT_TXT_Other_Fees_NonAccrual__c,
                   DMT_Sub_Limit__c,
                   bbva_prtcp_tranche_amount__c, undrawn_fee_next_12m_per__c,
                   DMT_Liquidity_Fee__c,DES_Commitment_Fees__c,DES_Other_Fees__c,
                   DMT_Sustainable_Deal_Subtype__c, DMT_PER_Sustainability_Percentage__c,
                   DMT_Sustainability_bonus_eligible__c, DMT_Sustainability_deal_value_criteria__c,
                   DMT_sustainable_deal_value__c, DMT_sustainable_deal_assessment__c,
                   DMT_ExpectedFinal_Take__c,
                   Opportunity.DMT_CurrencyText__c, Opportunity.DMT_Entity__c, Opportunity.DMT_DATE_Initial_Date__c,
                   Opportunity.DMT_Parent_Opportunity__c,
                   (SELECT Id, Name, CurrencyIsoCode, gf_spread_db__c, gf_spread_fb__c,
                           gj_nominal_amount_db__c, gf_nominal_amount_fb__c, gf_tenor_date__c,
                           gf_accrual_fees_bp__c, gf_non_accrual_fees_bp__c
                    FROM Opportunity_Tenors__r
                    ORDER BY CreatedDate ASC)
            FROM OpportunityLineItem
            WHERE Id = :opportunityLineItemId
            LIMIT 1
        ];
    }
    @AuraEnabled
    public static List<DMT_Opportunity_Mitigant__c> saveMitigants(
        Id opportunityLineItemId,
        List<Object> mitigantsToUpsert,
        List<Id> mitigantsToDelete
    ) {
        if (opportunityLineItemId == null) {
            throw new IllegalArgumentException('opportunityLineItemId is required');
        }
        Savepoint sp = Database.setSavepoint();
        try {
            List<Map<String, Object>> mitigantMaps = toTypedMaps(mitigantsToUpsert);

            // Validate mitigants before any DML
            if (!mitigantMaps.isEmpty()) {
                List<Object> rawMitigants = new List<Object>();
                for (Map<String, Object> m : mitigantMaps) { rawMitigants.add(m); }
                Map<String, Object> mitigantValidation = DMT_Opportunity_Utils.validateRealGuaratorsFromRaw(rawMitigants);
                if (mitigantValidation.get('validationPassed') != true) {
                    throw new AuraHandledException(String.valueOf(mitigantValidation.get('errorMessage')));
                }
            }

            // Upsert mitigants
            if (!mitigantMaps.isEmpty()) {
                List<DMT_Opportunity_Mitigant__c> toUpsert = new List<DMT_Opportunity_Mitigant__c>();
                Map<String, Schema.DisplayType> mitTypes = buildTypeMap(DMT_Opportunity_Mitigant__c.SObjectType);
                for (Map<String, Object> m : mitigantMaps) {
                    DMT_Opportunity_Mitigant__c mit = new DMT_Opportunity_Mitigant__c();
                    for (String key : m.keySet()) {
                        if (key == 'Id') {
                            if (m.get(key) != null && String.isNotBlank(String.valueOf(m.get(key)))) {
                                mit.Id = (Id) m.get(key);
                            }
                        } else {
                            mit.put(key, castValue(mitTypes, key, m.get(key)));
                        }
                    }
                    toUpsert.add(mit);
                }
                upsert toUpsert;
            }

            // Delete mitigants
            if (mitigantsToDelete != null && !mitigantsToDelete.isEmpty()) {
                List<DMT_Opportunity_Mitigant__c> mitigantsForDelete = new List<DMT_Opportunity_Mitigant__c>();
                for (Id mId : mitigantsToDelete) {
                    mitigantsForDelete.add(new DMT_Opportunity_Mitigant__c(Id = mId));
                }
                delete mitigantsForDelete;
            }

            return getMitigantsData(opportunityLineItemId);
        } catch (Exception e) {
            Database.rollback(sp);
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'saveMitigants', 'DMT', '');
            throw new AuraHandledException('Error saving Collateral Guarantees: ' + e.getMessage());
        }
    }


    private static Set<Id> cloneOpportunityLineItemTenors(Id sourceLineItemId, Id clonedLineItemId) {
        List<DMT_Opportunity_Tenor__c> sourceTenors = [
            SELECT Name, CurrencyIsoCode, gf_spread_db__c, gf_spread_fb__c,
                   gj_nominal_amount_db__c, gf_nominal_amount_fb__c, gf_tenor_date__c,
                   gf_accrual_fees_bp__c, gf_non_accrual_fees_bp__c
            FROM DMT_Opportunity_Tenor__c
            WHERE DMT_Opportunity_Product__c = :sourceLineItemId
        ];

        List<DMT_Opportunity_Tenor__c> clonedTenors = new List<DMT_Opportunity_Tenor__c>();
        for (DMT_Opportunity_Tenor__c t : sourceTenors) {
            DMT_Opportunity_Tenor__c cloned = t.clone(false, true, false, false);
            cloned.DMT_Opportunity_Product__c = clonedLineItemId;
            clonedTenors.add(cloned);
        }

        Set<Id> ids = new Set<Id>();
        if (!clonedTenors.isEmpty()) {
            insert clonedTenors;
            for (DMT_Opportunity_Tenor__c t : clonedTenors) {
                ids.add(t.Id);
            }
        }
        return ids;
    }

    private static Set<Id> cloneOpportunityLineItemMitigants(Id sourceLineItemId, Id clonedLineItemId) {
        List<DMT_Opportunity_Mitigant__c> sourceMitigants = [
            SELECT CurrencyIsoCode, DMT_Currency__c, Mitigant_Type__c, Counterpart__c,
                   Garantor_European_ECA__c, European_Bank_Check__c, AVC_Check__c,
                   Political_Percentage__c, Commercial_Percentage__c,
                   Rating_Long_Scale__c, External_Rating__c, Internal_Rating__c,
                   SCRA__c, End_Date__c,
                   Liquidation_Period__c, Mitigant_Currency__c,
                   DMT_Country_Guarantor__c, DMT_Scoring__c
            FROM DMT_Opportunity_Mitigant__c
            WHERE DMT_Opportunity_Product__c = :sourceLineItemId
        ];

        List<DMT_Opportunity_Mitigant__c> clonedMitigants = new List<DMT_Opportunity_Mitigant__c>();
        for (DMT_Opportunity_Mitigant__c m : sourceMitigants) {
            DMT_Opportunity_Mitigant__c cloned = m.clone(false, true, false, false);
            cloned.DMT_Opportunity_Product__c = clonedLineItemId;
            clonedMitigants.add(cloned);
        }

        Set<Id> ids = new Set<Id>();
        if (!clonedMitigants.isEmpty()) {
            insert clonedMitigants;
            for (DMT_Opportunity_Mitigant__c m : clonedMitigants) {
                ids.add(m.Id);
            }
        }
        return ids;
    }

    private static Set<Id> cloneOpportunityLineItemUnderlyings(Id sourceLineItemId, Id clonedLineItemId) {
        List<DMT_Underlying__c> sourceUnderlyings = [
            SELECT Name, DMT_Underlying_Type__c,
                   DMT_Max_Amount__c, DMT_Max_Term__c,
                   DMT_Other_restrictions__c,
                   DMT_Drawn_Reference_Amount__c,
                   DMT_Undrawn_Reference_Amount__c,
                   DMT_Term__c,
                   DMT_Drawn_Speed__c,
                   DMT_Undrawn_Spread__c,
                   DMT_Upfront_Fees__c,
                   DMT_Upfront_Fees_amount__c,
                   DMT_Amortization_Type__c,
                   DMT_Interest_Payment_Frequency__c,
                   DMT_Currency__c
            FROM DMT_Underlying__c
            WHERE DMT_Opportunity_Product__c = :sourceLineItemId
        ];

        List<DMT_Underlying__c> clonedUnderlyings = new List<DMT_Underlying__c>();
        for (DMT_Underlying__c u : sourceUnderlyings) {
            DMT_Underlying__c cloned = u.clone(false, true, false, false);
            cloned.DMT_Opportunity_Product__c = clonedLineItemId;
            clonedUnderlyings.add(cloned);
        }

        Set<Id> ids = new Set<Id>();
        if (!clonedUnderlyings.isEmpty()) {
            insert clonedUnderlyings;
            for (DMT_Underlying__c u : clonedUnderlyings) {
                ids.add(u.Id);
            }
        }
        return ids;
    }

    private static Passport__c markPassportAsObsolete(Id opportunityId) {
        List<Passport__c> existing = [
            SELECT Id FROM Passport__c
            WHERE Opportunity__c = :opportunityId
            LIMIT 1
        ];
        Passport__c passport;
        if (!existing.isEmpty()) {
            passport = existing[0];
            passport.DMT_Is_Obsoleted_Passport_Save__c = true;
            update passport;
        } else {
            passport = new Passport__c(
                Opportunity__c = opportunityId,
                DMT_Is_Obsoleted_Passport_Save__c = true
            );
            insert passport;
        }
        return passport;
    }

    private static String getFieldValue(DMT_Taxonomy_Values__c record, String fieldName) {
        if (fieldName == null || record == null) return '';
        Object value = record.get(fieldName);
        return value != null ? String.valueOf(value) : '';
    }

    /**
     * Converts a List<Object> from Aura (whose elements are Map<ANY,ANY>) to
     * proper List<Map<String, Object>>.  Also prevents Long overflow by quoting
     * integer literals with 19+ digits so they are parsed as String instead.
     */
    private static List<Map<String, Object>> toTypedMaps(List<Object> rawList) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        if (rawList == null || rawList.isEmpty()) {
            return result;
        }
        for (Object obj : rawList) {
            String jsonStr = JSON.serialize(obj);
            // Quote bare integer literals >= 19 digits to avoid Long overflow
            jsonStr = jsonStr.replaceAll(':(\\d{19,})([,}\\]])', ':"$1"$2');
            result.add((Map<String, Object>) JSON.deserializeUntyped(jsonStr));
        }
        return result;
    }

    private static Map<String, Schema.DisplayType> buildTypeMap(Schema.SObjectType sot) {
        Map<String, Schema.DisplayType> types = new Map<String, Schema.DisplayType>();
        Map<String, Schema.SObjectField> fields = sot.getDescribe().fields.getMap();
        for (String f : fields.keySet()) {
            types.put(f, fields.get(f).getDescribe().getType());
        }
        return types;
    }

    private static Object castValue(Map<String, Schema.DisplayType> typeMap, String fieldName, Object rawValue) {
        if (rawValue == null) return null;
        Schema.DisplayType dt = typeMap.get(fieldName.toLowerCase());
        if (dt == null) return rawValue;
        String strVal = String.valueOf(rawValue);
        if (String.isBlank(strVal)) return null;
        try {
            if (dt == Schema.DisplayType.DATE) {
                return Date.valueOf(strVal);
            }
            if (dt == Schema.DisplayType.DATETIME) {
                // Normalize ISO format with T/Z coming from the client
                String normalized = strVal.contains('T')
                    ? strVal.replace('T', ' ').replace('Z', '').substringBefore('.')
                    : strVal + ' 00:00:00';
                return Datetime.valueOf(normalized);
            }
            if (dt == Schema.DisplayType.BOOLEAN) {
                return Boolean.valueOf(strVal);
            }
            if (dt == Schema.DisplayType.DOUBLE   ||
                dt == Schema.DisplayType.CURRENCY  ||
                dt == Schema.DisplayType.PERCENT) {
                return Decimal.valueOf(strVal);
            }
            if (dt == Schema.DisplayType.INTEGER) {
                return Integer.valueOf(strVal);
            }
            return rawValue;
        } catch (Exception ex) {
            throw new AuraHandledException(
                'Invalid value for field "' + fieldName + '": ' + strVal + ' (expected ' + dt.name() + ')'
            );
        }
    }

    /**
     * CIBGLOBALD-4333
     * Devuelve, para cada clave, el modo Drawn/Undrawn del producto en taxonomy:
     * MODE_DRAWN, MODE_UNDRAWN o '' (sin restricción).
     * Query dinámica para que compile aunque el campo del atributo aún no exista.
     */
    @TestVisible
    private static Map<String, String> getDrawnUndrawnModes(Set<String> keys, String keyField) {
        Map<String, String> modes = new Map<String, String>();
        if (keys == null || keys.isEmpty()) {
            return modes;
        }
        Map<String, Schema.SObjectField> fieldMap = DMT_Taxonomy_Values__c.SObjectType.getDescribe().fields.getMap();
        if (!fieldMap.containsKey(DRAWN_UNDRAWN_FIELD.toLowerCase())) {
            return modes;
        }

        String soql = 'SELECT ' + keyField + ', ' + DRAWN_UNDRAWN_FIELD
                    + ' FROM DMT_Taxonomy_Values__c'
                    + ' WHERE DMT_Catalog__c = :catalog AND ' + keyField + ' IN :keys';
        Map<String, Object> binds = new Map<String, Object>{
            'catalog' => DRAWN_UNDRAWN_CATALOG,
            'keys'    => keys
        };

        for (SObject rec : Database.queryWithBinds(soql, binds, AccessLevel.SYSTEM_MODE)) {
            Object rawKey = rec.get(keyField);
            if (rawKey == null) {
                continue;
            }
            String key = String.valueOf(rawKey);
            String mode = toDrawnUndrawnMode(rec.get(DRAWN_UNDRAWN_FIELD));
            if (!modes.containsKey(key) || String.isBlank(modes.get(key))) {
                modes.put(key, mode);
            }
        }
        return modes;
    }

    @TestVisible
    private static String toDrawnUndrawnMode(Object rawValue) {
        if (rawValue == null) {
            return '';
        }
        Set<String> tokens = new Set<String>();
        for (String token : String.valueOf(rawValue).split('[,;|/]')) {
            if (String.isNotBlank(token)) {
                tokens.add(token.trim().toUpperCase());
            }
        }
        // Solo UNDRAWN, se bloquean los campos Drawn. Cualquier otro caso, todo editable.
        if (tokens.contains(UNDRAWN_ATTR_VALUE) && !tokens.contains(DRAWN_ATTR_VALUE)) {
            return MODE_UNDRAWN;
        }
        return '';
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
                Decimal numA = String.isBlank(valA) ? 0 : Decimal.valueOf(valA);
                Decimal numB = String.isBlank(valB) ? 0 : Decimal.valueOf(valB);
                result = numA < numB ? -1 : (numA > numB ? 1 : 0);
            } else {
                result = valA.compareTo(valB);
            }
            return descending ? -result : result;
        }
    }
}