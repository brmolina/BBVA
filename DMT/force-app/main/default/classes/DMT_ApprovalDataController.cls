/**
 * @description Controller for the dmt_opp_approval_details LWC.
 *              Retrieves data from DMT_Opportunity_Client__c + Account (Group) for overrides.
 *              Saves changes to DMT_Opportunity_Client__c.
 */
public with sharing class DMT_ApprovalDataController {
    // Field and sort configuration for each taxonomy catalog
    private static final Map<String, Map<String, String>> CATALOG_FIELD_MAPPING = new Map<String, Map<String, String>>{
        'C264' => new Map<String, String>{
            'labelField'   => 'DMT_Value__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'DMT_Value__c',
            'orderByType'  => 'ASC'
        },
        'H007' => new Map<String, String>{
            'labelField'   => 'DMT_Name_EN__c',
            'valueField'   => 'DMT_Value__c',
            'orderBy'      => 'DMT_Name_EN__c',
            'orderByType'  => 'ASC'
        }
    };
    // ─── READ ─────────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getApprovalData(Id opportunityId) {
        if (opportunityId == null) {
            throw new IllegalArgumentException('opportunityId is required');
        }
        try {
            Map<String, Object> response = new Map<String, Object>();

            // 1. Get DMT_Opportunity_Client__c (main editable data)
            DMT_Opportunity_Client__c oppClient = getOpportunityClient(opportunityId);
            response.put('opportunityClient', oppClient);
            response.put('opportunityClientId', oppClient?.Id);
            // 2. Get Group comparison data via comparisonAccount resolution (replicates RAGetComparisonAccount in IP)
            // Mirrors OIP flow: DMGetGroupOrSubsidiary → accountMainHolder → RAGetComparisonAccount
            // resolveMainHolderAccountId resolves Custom_Association_Opportunity__c → g_customer_id__c → Account
            // with fallback to Opportunity.AccountId when no custom association exists
            Map<String, Object> mainHolderResult = DMT_Passport_Helper.resolveMainHolderAccountId(opportunityId);
            Id accountForComparison = (Id) mainHolderResult.get('AccountId');

            if (accountForComparison != null) {
                Id comparisonAccountId = resolveComparisonAccountId(accountForComparison);
                if (comparisonAccountId != null) {
                    Map<String, Object> groupData = getGroupComparisonData(comparisonAccountId);
                    if (groupData != null) {
                        response.put('groupComparisonData', groupData);
                        response.put('groupId', groupData.get('Id'));
                    }
                }
            }

            // 3. Get Global Structure records (for dmt_table_global_structure)
            List<DMT_Global_Structure__c> globalStructure = getGlobalStructure(opportunityId);
            response.put('globalStructure', globalStructure);

            // 4. Get Banking Pool records (for dmt_bankingpool_table)
            List<DMT_Banking_Pool_Structure__c> bankingPool = getBankingPool(opportunityId);
            response.put('bankingPool', bankingPool);

            // 5. Get Opportunity SPPI fields (editable in Deal section)
            List<Opportunity> oppList = [
                SELECT DMT_SPPI_File_Uploaded__c, DMT_SPPI_Status__c, DMT_SPPI_User__c,DMT_CurrencyText__c
                FROM Opportunity
                WHERE Id = :opportunityId
                WITH USER_MODE
                LIMIT 1
            ];
            if (!oppList.isEmpty()) {
                Opportunity opp = oppList[0];
                response.put('opportunityData', new Map<String, Object>{
                    'DMT_SPPI_File_Uploaded__c' => opp.DMT_SPPI_File_Uploaded__c,
                    'DMT_SPPI_Status__c'        => opp.DMT_SPPI_Status__c,
                    'DMT_SPPI_User__c'          => opp.DMT_SPPI_User__c,
                    'DMT_CurrencyText__c'       => opp.DMT_CurrencyText__c
                });
            }

            return response;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_ApprovalDataController', 'getApprovalData', 'DMT', '');
            throw new AuraHandledException('Error fetching Approval data: ' + e.getMessage());
        }
    }

    // ─── WRITE ────────────────────────────────────────────────────────────────

    @AuraEnabled
    public static Map<String, Object> saveApprovalData(
        Map<String, Object> recordFields,
        Id opportunityClientId,
        String bpChangesJson,
        Id opportunityId,
        Map<String, Object> opportunityFields
    ) {
        Map<String, Object> result = new Map<String, Object>();
        Savepoint sp = Database.setSavepoint();
        try {
            
            updateOpportunityFields(opportunityId, opportunityFields);
            updateOpportunityClient(opportunityClientId, recordFields);
            upsertBusinessPlans(bpChangesJson);
            result.put('success', true);
            return result;
        } catch (Exception e) {
            Database.rollback(sp);
            DES_Exception_Utils.logException(e, 'DMT_ApprovalDataController', 'saveApprovalData', 'DMT', '');
            throw new AuraHandledException('Error saving approval data: ' + e.getMessage());
        }
    }

    private static void updateOpportunityFields(Id opportunityId, Map<String, Object> opportunityFields) {
        if (opportunityId == null || opportunityFields == null || opportunityFields.isEmpty()) return;
        Opportunity opp = new Opportunity(Id = opportunityId);
        Map<String, Schema.DisplayType> oppTypeMap = buildTypeMap(Opportunity.SObjectType);
        for (String key : opportunityFields.keySet()) {
            if (key == 'Id') continue;
            opp.put(key, castValue(oppTypeMap, key, opportunityFields.get(key)));
        }
        Database.update(opp, AccessLevel.USER_MODE);
    }

    private static void updateOpportunityClient(Id opportunityClientId, Map<String, Object> recordFields) {
        if (opportunityClientId == null || recordFields == null || recordFields.isEmpty()) return;
        DMT_Opportunity_Client__c oppClient = new DMT_Opportunity_Client__c(Id = opportunityClientId);
        Map<String, Schema.DisplayType> typeMap = buildTypeMap(DMT_Opportunity_Client__c.SObjectType);
        for (String key : recordFields.keySet()) {
            if (key == 'Id') continue;
            oppClient.put(key, castValue(typeMap, key, recordFields.get(key)));
        }
        Database.update(oppClient, AccessLevel.USER_MODE);
    }

    private static void upsertBusinessPlans(String bpChangesJson) {
        if (String.isBlank(bpChangesJson)) return;
        try {
            List<DMT_Opportunity_Business_Plan__c> bpRecords =
                (List<DMT_Opportunity_Business_Plan__c>) JSON.deserialize(
                    bpChangesJson, List<DMT_Opportunity_Business_Plan__c>.class
                );
            if (!bpRecords.isEmpty()) {
                Database.upsert(bpRecords, AccessLevel.USER_MODE);
            }
        } catch (System.JSONException je) {
            throw new AuraHandledException('Invalid business plan data: ' + je.getMessage());
        }
    }

    // ─── Comparison Account resolution (replicates RAGetComparisonAccount from IP) ─

    private static Id resolveComparisonAccountId(Id oppAccountId) {
        Map<String, Object> inputMap = new Map<String, Object>{ 'oppAccountId' => oppAccountId };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> result = DMT_Opportunity_Utils.getComparisonAccount(inputMap, outMap, options);
        if (result.get('foundComparisonAccount') == true) {
            return (Id) result.get('comparisonAccountId');
        }
        return null;
    }

    // ─── Private queries ──────────────────────────────────────────────────────

    private static DMT_Opportunity_Client__c getOpportunityClient(Id opportunityId) {
        List<DMT_Opportunity_Client__c> results = [
            SELECT Id,
                   DMT_MDE_Opportunity__c, DMT_MDE_Opportunity__r.AccountId,DMT_MDE_Opportunity__r.StageName,DMT_MDE_Opportunity__r.CloseDate,DMT_MDE_Opportunity__r.IsClosed,
                   /*Deal*/
                   DMT_History_Deal__c,DMT_Commitment_Deadline__c,
                   DMT_Description_Issues__c,DMT_Purpose__c,
                   DMT_Opp_Threats_Related_Deal__c,
                   /* Client Tier*/
                   DMT_Target__c,DMT_Current__c,DMT_Tiering_Action__c,DMT_Exception_Pool__c,
                   /* other aspects */
                   DMT_Other_Relevant_Issues__c,DMT_Security_Package__c,DMT_Rating_Scenarios__c,DMT_Applicable_Jurisdiction__c,
                   /* Client Info */
                   Other_Relevant_Ratios_desc__c, Geographical_Footprint_desc__c,
                   Relationship_Status_desc__c, Industry_Overview_desc__c,
                   Qualitative_Assesment_of_X_Sell_Rev_desc__c,
                   /* Sustainable Finance */
                   DMT_comments__c,DMT_KPI_Margin_Adjustment__c,
                   DMT_Infrastructure_Supporting_Factor__c,
                   DMT_Equator_Principles_Category__c,
                   DMT_equator_Principles__c,
                   DMT_Sustainable_Deal__c,
                   /* Risk */
                   DMT_Asset_Allocation_limit__c,DMT_Financial_Program_limit__c,
                   /* Client Profitability */
                   DMT_Client_RWA__c,DMT_Client_Net_Incomes__c,DMT_Client_RORC_YTD__c,
                     DMT_CDD_Clients_Global_Rorc_Last_FY__c,DMT_Clients_Global_RORC_CIB_Past_FY__c,
                   /* Deal - Other Aspects */
                   DMT_SourceAndUses__c, DMT_Competition_Deal__c,DMT_Xsell_Cost_to_Income__c,
                   /* Currency */
                   DMT_Currency__c,cstk_sust_indicators_comments__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opportunityId
            WITH USER_MODE
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    private static Map<String, Object> getGroupComparisonData(Id accountId) {
        // 1. Query Account for non-cstk fields
        List<Account> groups = [
            SELECT Id,
                   Other_Relevant_Ratios_desc__c, Geographical_Footprint_desc__c,
                   Relationship_Status_desc__c, Industry_Overview_desc__c,
                   cstk_sust_indicators_comments__c,
                   DMT_Currency__c,Name
            FROM Account
            WHERE Id = :accountId
            WITH USER_MODE
            LIMIT 1
        ];
        if (groups.isEmpty()) return null;

        Account grp = groups[0];
        Map<String, Object> comparison = new Map<String, Object>();
        comparison.put('Id', grp.Id);
        comparison.put('Other_Relevant_Ratios_desc__c', grp.Other_Relevant_Ratios_desc__c);
        comparison.put('Geographical_Footprint_desc__c', grp.Geographical_Footprint_desc__c);
        comparison.put('Relationship_Status_desc__c', grp.Relationship_Status_desc__c);
        comparison.put('Industry_Overview_desc__c', grp.Industry_Overview_desc__c);
        comparison.put('cstk_sust_indicators_comments__c', grp.cstk_sust_indicators_comments__c);
        comparison.put('DMT_Currency__c', grp.DMT_Currency__c);
        comparison.put('Name', grp.Name);
    
        return comparison;
    }

    public static List<DMT_Global_Structure__c> getGlobalStructure(Id opportunityId) {
        return [
            SELECT Id, Name, DMT_Funds__c, DMT_Type__c
            FROM DMT_Global_Structure__c
            WHERE DMT_Opportunity__c = :opportunityId
            WITH USER_MODE
            ORDER BY DMT_Type__c, Name
        ];
    }

    public static List<DMT_Banking_Pool_Structure__c> getBankingPool(Id opportunityId) {
        return [
            SELECT Id, Name, DMT_Ticket__c, DMT_Fees__c, DMT_Margin__c, DMT_N_Banks__c
            FROM DMT_Banking_Pool_Structure__c
            WHERE DMT_Opportunity__c = :opportunityId
            WITH USER_MODE
            ORDER BY Name
        ];
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

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
            DES_Exception_Utils.logException(e, 'DMT_ApprovalDataController', 'getTaxonomyCatalogValues', 'DMT', '');
            throw new AuraHandledException('Error fetching Taxonomy Catalog Values: ' + e.getMessage());
        }
        return catalogMap;
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
    private static String getFieldValue(DMT_Taxonomy_Values__c record, String fieldName) {
        if (fieldName == null || record == null) return '';
        Object value = record.get(fieldName);
        return value != null ? String.valueOf(value) : '';
    }
}