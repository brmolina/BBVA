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
            OpportunityLineItem oli = getOpportunityLineItemById(opportunityLineItemId);
            // If the OLI has no currency set, fall back to the Opportunity currency
            oli.g_currency_id__c = String.isBlank(oli.g_currency_id__c)
                ? oli.Opportunity.DMT_CurrencyText__c
                : oli.g_currency_id__c;
            return oli;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getOpportunityLineItemData', 'DMT', '');
            throw new AuraHandledException('Error fetching Opportunity Line Item data: ' + e.getMessage());
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
                       European_Bank_Check__c, End_Date__c, DMT_Local_Client__c,
                       CurrencyIsoCode, DMT_Guarantor_Display__c
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
        try {
            List<DMT_Taxonomy_Values__c> records = [
                SELECT gf_catalog_atrb_val7_name__c
                FROM DMT_Taxonomy_Values__c
                WHERE DMT_Catalog__c = 'D744'
                  AND DMT_Name_EN__c = :productName
                  AND gf_catalog_atrb_val1_name_c__c = :productCode
                  AND gf_catalog_atrb_val5_name__c LIKE '%TO%'
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
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'getProductLineTypeOptions', 'DMT', '');
            throw new AuraHandledException('Error fetching Product Line Type options: ' + e.getMessage());
        }
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

                    for (DMT_Taxonomy_Values__c rec : records) {
                        values.add(new Map<String, String>{
                            'label' => getFieldValue(rec, labelFieldName),
                            'value' => getFieldValue(rec, valueFieldName)
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
    public static Map<String, Object> createProductsOpportunity(List<Object> products, Object opportunityId) {
        try {
            return DMT_Opportunity_Utils.createProductsOpportunity(products, opportunityId);
        } catch (Exception e) {
            DES_Exception_Utils.logException(e,'DMT_OpportunityProductsController', 'createProductsOpportunity', 'DMT', '');
            throw new AuraHandledException('Error creating products: ' + e.getMessage());
        }
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
                Map<String, Schema.DisplayType> oliTypes = buildTypeMap(OpportunityLineItem.SObjectType);
                for (String key : recordFields.keySet()) {
                    if (key == 'Id') continue;
                    oli.put(key, castValue(oliTypes, key, recordFields.get(key)));
                }
                update oli;
            }

            // 4. Upsert tenors
            if (!tenorMaps.isEmpty()) {
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
                    toUpsert.add(tenor);
                }
                upsert toUpsert;
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
            
            // 8. update passport
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

    private static OpportunityLineItem getOpportunityLineItemById(Id opportunityLineItemId) {
        return [
            SELECT Id, OpportunityId, DMT_TXT_ProductNameOLI__c,
                   gf_initial_date__c, gf_maturity_date__c, DMT_Risk_Type__c,
                   DMT_TXT_Comentarios__c, g_line_commitment_level_type__c,
                   loan_purpose_desc__c, gf_amortization_type__c, gf_payment_frequency__c,
                   DMT_RateType__c, DMT_bullet_amortization_indicator__c,
                   DMT_PricingGrid_OR_StepUps__c, DMT_balloon_amortization_indicator__c,
                   DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, gf_accrual_fees_bp__c,
                   DMT_Extension_Duration_Fees__c, DMT_Expected_Drawn__c,
                   syndicated_loan_drawn_amount__c, g_currency_id__c, Life_Funding_Type__c,
                   PricebookEntryId, Product2Id, Quantity, TotalPrice, Name, ProductCode,
                   g_product_id__c, g_branch_id__c, gf_payment_type__c,
                   gf_country_rating__c, gf_country_risk__c,
                   gf_funding_cost_db__c, gf_funding_cost_fb__c,
                   gf_green_bonus__c, gf_social_bond__c, Funding_Curve__c,
                   deal_total_amount__c, DMT_Deal_Amount_Tenors__c, DMT_Deal_amount__c,
                   bbva_prtcp_tranche_amount__c, undrawn_fee_next_12m_per__c,
                   DMT_Liquidity_Fee__c, DES_Commitment_Fees__c, DES_Other_Fees__c,
                   DMT_Sustainable_Deal_Subtype__c, DMT_PER_Sustainability_Percentage__c,
                   DMT_Sustainability_bonus_eligible__c, DMT_Sustainability_deal_value_criteria__c,
                   DMT_sustainable_deal_value__c, DMT_sustainable_deal_assessment__c,
                   DMT_ExpectedFinal_Take__c,
                   Opportunity.DMT_CurrencyText__c, Opportunity.DMT_Entity__c, Opportunity.DMT_DATE_Initial_Date__c
            FROM OpportunityLineItem
            WHERE Id = :opportunityLineItemId
            LIMIT 1
        ];
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
                   DMT_Local_Client__c, Political_Percentage__c, Commercial_Percentage__c,
                   Rating_Long_Scale__c, External_Rating__c, Internal_Rating__c,
                   SCRA__c, End_Date__c
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