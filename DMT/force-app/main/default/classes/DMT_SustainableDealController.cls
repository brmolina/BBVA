public with sharing class DMT_SustainableDealController {
    
    /**
     * @description get picklist values from OPLI field
     * @param fieldName
     * @return List<Map<String, String>> Picklist values with 'value' and 'label' keys
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValues(String fieldName) {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        try {
            Schema.DescribeFieldResult fieldResult = Schema.SObjectType.OpportunityLineItem.fields.getMap().get(fieldName).getDescribe();
            List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : entries) {
                Map<String, String> value = new Map<String, String>();
                value.put('value', entry.getValue());
                value.put('label', entry.getLabel());
                picklistValues.add(value);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error query picklist values: ' + e.getMessage());
        }
        return picklistValues;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getDependentPicklistValues(String controllingFieldValue) {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();

        try {
            Schema.DescribeFieldResult dependentFieldResult = Schema.SObjectType.OpportunityLineItem.fields.getMap().get('DMT_Sustainable_Deal_Subtype__c').getDescribe();

            List<Schema.PicklistEntry> dependentEntries = dependentFieldResult.getPicklistValues();

            // Map de valores válidos según el controlling field value
            Map<String, List<String>> validSubtypesByAssessment = new Map<String, List<String>>();
            validSubtypesByAssessment.put(DMT_Constants.DMT_SUSTAINABILITY_SUSTAINABLE_LOAN, new List<String>{DMT_Constants.DMT_SUSTAINABLE_GREEN, DMT_Constants.DMT_SUSTAINABLE_SOCIAL, DMT_Constants.DMT_SUSTAINABLE_GREEN_AND_SOCIAL});
            validSubtypesByAssessment.put(DMT_Constants.DMT_SUSTAINABILITY_USE_OF_PROCEEDS, new List<String>{DMT_Constants.DMT_SUSTAINABLE_GREEN, DMT_Constants.DMT_SUSTAINABLE_SOCIAL});
            validSubtypesByAssessment.put(DMT_Constants.DMT_SUSTAINABILITY_TRANSITION_FINANCE, new List<String>{ DMT_Constants.DMT_SUSTAINABLE_USE_OF_PROCEEDS_SUBTYPE, DMT_Constants.DMT_SUSTAINABLE_SSL_SUBTYPE });
            List<String> validValues = validSubtypesByAssessment.get(controllingFieldValue);
            if (validValues != null) {
                for (Schema.PicklistEntry entry : dependentEntries) {
                    if (validValues.contains(entry.getValue())) {
                        Map<String, String> value = new Map<String, String>();
                        value.put('value', entry.getValue());
                        value.put('label', entry.getLabel());
                        picklistValues.add(value);
                    }
                }
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error query dependent picklist values: ' + e.getMessage());
        }
        
        return picklistValues;
    }
    
    /**
     * @description get taxonomy catalog for assessments that resolve the catalog directly
     * from the assessment value, without depending on a subtype selection.
     * Covers: SSL ('4'), SSL Green ('3'), Chain Finance ('2'), Sustainable Loan ('5').
     * All map to the RBES catalog.
     */
    @AuraEnabled(cacheable=true)
    public static List<CatalogOption> getCatalogByAssessment(String assessmentValue) {
        List<CatalogOption> catalogOptions = new List<CatalogOption>();
        try {
            if (
                assessmentValue == DMT_Constants.DMT_SUSTAINABILITY_SSL ||
                assessmentValue == DMT_Constants.DMT_SUSTAINABILITY_SSL_GREEN ||
                assessmentValue == DMT_Constants.DMT_SUSTAINABILITY_CHAIN_FINANCE ||
                assessmentValue == DMT_Constants.DMT_SUSTAINABILITY_SUSTAINABLE_LOAN
            ) {
                catalogOptions = getCatalogFromDatabase(DMT_Constants.DMT_TAXO_CATALOG_RBES, null, false);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error getting catalog by assessment: ' + e.getMessage());
        }
        return catalogOptions;
    }

    /**
     * @description get taxonomy catalog for assessments that depend on a subtype selection.
     * Covers: Use of Proceeds ('6') — subtype drives which catalog is used:
     *   Green  → RBGR
     *   Social → RBSO
     */
    @AuraEnabled(cacheable=true)
    public static List<CatalogOption> getCatalogBySubtype(String subtypeValue, String greenFilter, Boolean enableGreenFilter) {
        List<CatalogOption> catalogOptions = new List<CatalogOption>();
        try {
            if (subtypeValue == DMT_Constants.DMT_SUSTAINABLE_GREEN) {
                catalogOptions = getCatalogFromDatabase(DMT_Constants.DMT_TAXO_CATALOG_RBGR, greenFilter, enableGreenFilter);
            } else if (subtypeValue == DMT_Constants.DMT_SUSTAINABLE_SOCIAL) {
                catalogOptions = getCatalogFromDatabase(DMT_Constants.DMT_TAXO_CATALOG_RBSO, greenFilter, enableGreenFilter);
            } else if (subtypeValue == DMT_Constants.DMT_SUSTAINABLE_USE_OF_PROCEEDS_SUBTYPE || subtypeValue == DMT_Constants.DMT_SUSTAINABLE_SSL_SUBTYPE){
                catalogOptions = getCatalogFromDatabase(DMT_Constants.DMT_TAXO_CATALOG_RBST, greenFilter, enableGreenFilter);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error getting catalog by subtype: ' + e.getMessage());
        }
        return catalogOptions;
    }
    
    /**
     * @description get catalog values from DMT_Taxonomy_Values__c
     * @param catalogValue catalog identifier to filter values
     * @return List<CatalogOption> catalog options with 'value' and 'label' fields
     */
    private static List<CatalogOption> getCatalogFromDatabase(String catalogValue, String greenFilter, Boolean enableGreenFilter) {
        List<CatalogOption> options = new List<CatalogOption>();
        Set<String> uniqueValues = new Set<String>();
        final String TXT_DELEGATED  = 'delegated';
        final String TXT_OTHER  = 'other';
        final String TXT_LABEL_TO_FILTER  = 'Delegated Label CIB';
        try {
                String dynamicSoql =
                    'SELECT Id, DMT_Value__c, DMT_Name_EN__c, gf_catalog_atrb_val1_name_c__c ' +
                    'FROM DMT_Taxonomy_Values__c ' +
                    'WHERE DMT_Active__c = true ' +
                    'AND DMT_Catalog__c = :catalogValue';
            if (enableGreenFilter && String.isNotBlank(greenFilter)) {
                // condicion en funcion del filtro: nos falta saber como van a marcar las delegated y las otras
                if(greenFilter.equals(TXT_DELEGATED)){
                    dynamicSoql +=' AND gf_catalog_atrb_val17_name__c =\''+TXT_LABEL_TO_FILTER+'\'';
                }else if(greenFilter.equals(TXT_OTHER)){
                    dynamicSoql +=' AND gf_catalog_atrb_val17_name__c != \''+TXT_LABEL_TO_FILTER+'\'';
                }
            }

                // Orden final opcional (lo tenías en tu ejemplo comentado)
                dynamicSoql += ' ORDER BY DMT_Name_EN__c ASC';

                //SOQL Injection Falso Positivo:los valores son enlazados a una variable
                List<DMT_Taxonomy_Values__c> taxonomyValues = Database.query(dynamicSoql);

            for (DMT_Taxonomy_Values__c taxonomy : taxonomyValues) {
                // Verificar si el valor ya existe
                if (!uniqueValues.contains(taxonomy.DMT_Value__c)) {
                    uniqueValues.add(taxonomy.DMT_Value__c);
                    options.add(new CatalogOption(
                        taxonomy.DMT_Value__c,
                        taxonomy.DMT_Value__c+' - '+taxonomy.DMT_Name_EN__c
                    ));
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error getting catalog ' + catalogValue + ': ' + e.getMessage());
        }
        
        return options;
    }
    
    public class CatalogOption {
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String label;
        
        public CatalogOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}