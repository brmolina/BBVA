public with sharing class DMT_TaxonomyMultipleProducts {
    private static final String LOG_PREFIX = '[DMT_TaxonomyMultipleProducts]';

    @AuraEnabled(cacheable=true)
    public static List<dmt_taxonomy_values__c> getTaxonomy(Id recordId) {
        DMT_Line__c line = [SELECT Booking_Geography__c FROM DMT_Line__c WHERE Id =: recordId LIMIT 1];
        List <String> listOfCatalogs = new List<String>();
        List<DMT_Taxonomy_Map__mdt> taxonomyMap = [SELECT Id, DMT_Catalog__c FROM DMT_Taxonomy_Map__mdt WHERE DMT_Operation_Type__c = 'OtherProducts' AND DMT_Object__c = 'Product2'];
        for(DMT_Taxonomy_Map__mdt taxono : taxonomyMap){
            listOfCatalogs.add(taxono.DMT_Catalog__c);
        }
        return [
            SELECT Id, dmt_value__c, dmt_name__c, gf_catalog_atrb_val1_name_c__c, DMT_Name_EN__c, DMT_Catalog__c, DMT_External_Id__c, gf_catalog_atrb_val2_name__c, gf_catalog_atrb_val3_name__c
            FROM dmt_taxonomy_values__c
            WHERE DMT_Catalog__c IN :listOfCatalogs AND DMT_Entific__c =:line.Booking_Geography__c order by gf_catalog_atrb_val2_name__c
        ];
    }

    // Modificación para añadir compatibilidad con Opportunity
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductsDMTByContext(Id recordId, String contextCode) {
        logStep('getProductsDMTByContext.start', new Map<String, Object>{
            'recordId' => recordId,
            'contextCode' => contextCode
        });

        // Detectar el tipo de objeto a partir del prefijo del Id
        String prefix = String.valueOf(recordId).substring(0, 3);
        Schema.SObjectType sObjectType = null;

        // Mapear prefijos a objetos
        Map<String, Schema.SObjectType> tokenMap = Schema.getGlobalDescribe();
        for (Schema.SObjectType objType : tokenMap.values()) {
            try {
                String objPrefix = objType.getDescribe().getKeyPrefix();

                if (prefix.equals(objPrefix)) {
                    sObjectType = objType;
                    break;
                }
            } catch (Exception e) {
                // Ignorar tipos sin prefijo
            }
        }

        logStep('getProductsDMTByContext.objectType', new Map<String, Object>{
            'sObjectType' => sObjectType == null ? null : String.valueOf(sObjectType)
        });

        if (sObjectType == Opportunity.SObjectType) {
            List<Opportunity> opp = DMT_Passport_Selector.getOpportunity(recordId);
            List<Product2> products = [
                SELECT Id, Name, ProductCode, Family, DMT_Product_family__c, DMT_Product_Subfamily__c,
                    DMT_Product_category__c, DMT_Product_Subcategory__c, DMT_Global_Product_Id__c,
                    DMT_Classification_Level__c, DMT_CatalogTaxonomy__c, DMT_Taxonomy_Value__c,
                    DMT_Taxonomy_Value__r.gf_catalog_atrb_val1_name_c__c,
                    DMT_Taxonomy_Value__r.gf_catalog_atrb_val2_name__c,
                    DMT_Taxonomy_Value__r.gf_catalog_atrb_val3_name__c,
                    DMT_Taxonomy_Value__r.gf_catalog_atrb_val7_name__c,
                    DMT_Product_Template__c, Parent_Product__c
                FROM Product2
                WHERE Family = 'DMT Lines'
                    AND IsActive = true
                    AND DMT_Entific__c =: opp[0].Entific__c
                    AND DMT_Product_Template__c INCLUDES ('OP','TO','OL')
                    AND DMT_Taxonomy_Value__r.gf_catalog_atrb_val4_name__c = 'Product'
                ORDER BY Name
            ];
            logStep('getProductsDMTByContext.opportunity.query', new Map<String, Object>{
                'entific' => opp.isEmpty() ? null : opp[0].Entific__c,
                'templateFilter' => 'OP;TO;OL',
                'contextCode' => contextCode,
                'productsBeforeContextFilter' => products.size()
            });
            products = filterProductsByContext(products, contextCode);
            logStep('getProductsDMTByContext.opportunity.filtered', new Map<String, Object>{
                'productsAfterContextFilter' => products.size(),
                'allowedTokens' => resolveAllowedContextTokens(contextCode)
            });
            for (Product2 p : products) {
                p.HelpText = 'OP_CONTEXT';
            }
            return products;

        } else if (sObjectType == DMT_Line__c.SObjectType) {
            DMT_Line__c line = DMT_Passport_Selector.getLine(recordId);
            String template = line.DMT_line_template_type__c;
            List<Product2> products = [
                SELECT Id, Name, ProductCode, Family, DMT_Product_family__c, DMT_Product_Subfamily__c, DMT_Product_category__c,
                DMT_Product_Subcategory__c, DMT_Global_Product_Id__c, DMT_Classification_Level__c, DMT_CatalogTaxonomy__c,
                DMT_Taxonomy_Value__c, DMT_Taxonomy_Value__r.gf_catalog_atrb_val1_name_c__c, DMT_Taxonomy_Value__r.gf_catalog_atrb_val2_name__c, DMT_Taxonomy_Value__r.gf_catalog_atrb_val3_name__c, DMT_Taxonomy_Value__r.gf_catalog_atrb_val7_name__c, DMT_Product_Template__c, Parent_Product__c
                FROM Product2
                WHERE Family = 'DMT Lines'
                    AND DMT_Entific__c =: line.Booking_Geography__c
                    AND IsActive =: true
                    AND DMT_Taxonomy_Value__r.gf_catalog_atrb_val4_name__c = 'Product'
                ORDER BY Name
            ];

            List<Product2> parentTemplateProducts = new List<Product2>();
            for (Product2 product : products) {
                if (matchesTemplate(product.DMT_Product_Template__c, template)) {
                    parentTemplateProducts.add(product);
                }
            }

			system.debug('size'+parentTemplateProducts.size());
            logStep('getProductsDMTByContext.line.query', new Map<String, Object>{
                'booking' => line.Booking_Geography__c,
                'templateFilter' => template,
                'contextCode' => contextCode,
                'productsBeforeContextFilter' => parentTemplateProducts.size(),
                'productsQueried' => products.size()
            });

            List<Product2> filteredParentProducts = new List<Product2>();
            if (String.isBlank(contextCode)) {
                filteredParentProducts.addAll(parentTemplateProducts);
            } else {
                Set<String> allowedTokens = resolveAllowedContextTokens(contextCode);
                for (Product2 parentProduct : parentTemplateProducts) {
                    if (matchesAnyContextToken(parentProduct.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val7_name__c, allowedTokens)) {
                        filteredParentProducts.add(parentProduct);
                    }
                }
            }

            Set<String> requiredChildCodes = new Set<String>();
            for (Product2 parentProduct : filteredParentProducts) {
                String childCodes = parentProduct.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val1_name_c__c;
                if (String.isBlank(childCodes)) {
                    continue;
                }
                for (String childCode : childCodes.split(',')) {
                    String normalized = String.valueOf(childCode).trim();
                    if (!String.isBlank(normalized)) {
                        requiredChildCodes.add(normalized);
                    }
                }
            }

            Map<Id, Product2> mergedById = new Map<Id, Product2>();
            for (Product2 parentProduct : filteredParentProducts) {
                mergedById.put(parentProduct.Id, parentProduct);
            }

            if (!requiredChildCodes.isEmpty()) {
                for (Product2 candidate : products) {
                    if (isLeafProduct(candidate)
                        && matchesAllowedProductCode(candidate.ProductCode, requiredChildCodes)) {
                        mergedById.put(candidate.Id, candidate);
                    }
                }
            }

            List<Product2> filteredProducts = mergedById.values();
            logStep('getProductsDMTByContext.line.filtered', new Map<String, Object>{
                'productsAfterContextFilter' => filteredProducts.size(),
                'parentsAfterContextFilter' => filteredParentProducts.size(),
                'requiredChildCodesCount' => requiredChildCodes.size(),
                'allowedTokens' => resolveAllowedContextTokens(contextCode)
            });
            return filteredProducts;
        } else {
            throw new AuraHandledException('El recordId no pertenece a Opportunity ni a DMT_Line__c');
        }
    }

    private static List<Product2> filterProductsByContext(List<Product2> products, String contextCode) {
        if (String.isBlank(contextCode)) {
            return products;
        }

        Set<String> allowedTokens = resolveAllowedContextTokens(contextCode);
        Set<String> allowedProductCodes = new Set<String>();

        for (Product2 product : products) {
            if (matchesAnyContextToken(product.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val7_name__c, allowedTokens)) {
                allowedProductCodes.addAll(resolveProductCodeTokens(product.ProductCode));
            }
        }

        List<Product2> filtered = new List<Product2>();
        for (Product2 product : products) {
            if (matchesAllowedProductCode(product.ProductCode, allowedProductCodes)
                || hasAllowedChild(product, allowedProductCodes)) {
                filtered.add(product);
            }
        }

        return filtered;
    }

    private static Set<String> resolveAllowedContextTokens(String contextCode) {
        Set<String> tokens = new Set<String>();
        if (String.isBlank(contextCode)) {
            return tokens;
        }

        for (String token : contextCode.split(',')) {
            String normalized = String.valueOf(token).trim().toUpperCase();
            if (normalized == 'OP' || normalized == 'OPP' || normalized == 'ONE_OFF') {
                tokens.add('OPP');
            } else if (normalized == 'L' || normalized == 'LC' || normalized == 'LNC' || normalized == 'TO' || normalized == 'LINE') {
                tokens.add('L');
            }
        }
        return tokens;
    }

    private static Boolean matchesAnyContextToken(String rawValue, Set<String> allowedTokens) {
        if (String.isBlank(rawValue)) {
            return false;
        }

        String normalizedValue = rawValue.toUpperCase();
        for (String token : allowedTokens) {
            if (normalizedValue.contains(token)) {
                return true;
            }
        }
        return false;
    }

    private static void logStep(String step, Object payload) {
        System.debug(LoggingLevel.WARN, LOG_PREFIX + '[' + step + '] ' + JSON.serialize(payload));
    }

    private static Boolean hasAllowedChild(Product2 product, Set<String> allowedProductCodes) {
        String childCodes = product.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val1_name_c__c;
        if (String.isBlank(childCodes)) {
            return false;
        }

        for (String childCode : childCodes.split(',')) {
            if (allowedProductCodes.contains(String.valueOf(childCode).trim())) {
                return true;
            }
        }
        return false;
    }

    private static Set<String> resolveProductCodeTokens(String rawProductCode) {
        Set<String> tokens = new Set<String>();
        if (String.isBlank(rawProductCode)) {
            return tokens;
        }

        for (String token : rawProductCode.split(',')) {
            String normalized = String.valueOf(token).trim();
            if (!String.isBlank(normalized)) {
                tokens.add(normalized);
            }
        }

        return tokens;
    }

    private static Boolean matchesAllowedProductCode(String productCodeRaw, Set<String> allowedProductCodes) {
        if (allowedProductCodes == null || allowedProductCodes.isEmpty()) {
            return false;
        }

        for (String code : resolveProductCodeTokens(productCodeRaw)) {
            if (allowedProductCodes.contains(code)) {
                return true;
            }
        }

        return false;
    }

    private static Boolean matchesTemplate(String rawTemplates, String expectedTemplate) {
        if (String.isBlank(rawTemplates) || String.isBlank(expectedTemplate)) {
            return false;
        }

        String expected = expectedTemplate.trim().toUpperCase();
        for (String token : rawTemplates.split(';')) {
            if (String.valueOf(token).trim().toUpperCase() == expected) {
                return true;
            }
        }
        return false;
    }

    private static Boolean isLeafProduct(Product2 product) {
        String sortOrder = String.valueOf(product.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val2_name__c);
        String manualIndent = String.valueOf(product.DMT_Taxonomy_Value__r?.gf_catalog_atrb_val3_name__c);
        if (sortOrder == null || manualIndent == null) {
            return false;
        }

        sortOrder = sortOrder.trim();
        manualIndent = manualIndent.trim().toUpperCase();
        return sortOrder == '99' && manualIndent == 'XX';
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductsByCategory(Id recordId) {
        // Detectar el tipo de objeto a partir del prefijo del Id
        String prefix = String.valueOf(recordId).substring(0, 3);
        Schema.SObjectType sObjectType = null;

        // Mapear prefijos a objetos
        Map<String, Schema.SObjectType> tokenMap = Schema.getGlobalDescribe();
        for (Schema.SObjectType objType : tokenMap.values()) {
            try {
                String objPrefix = objType.getDescribe().getKeyPrefix();

                if (prefix.equals(objPrefix)) {
                    sObjectType = objType;
                    break;
                }
            } catch (Exception e) {
                // Ignorar tipos sin prefijo
            }
        }
        if (sObjectType == DMT_Line__c.SObjectType) {
            DMT_Line__c line = DMT_Passport_Selector.getLine(recordId);
            String template = line.DMT_line_template_type__c;
            return [
                SELECT Id, Name, ProductCode
                FROM Product2
                WHERE Family = 'DMT Lines' AND DMT_Entific__c =: line.Booking_Geography__c AND DMT_Product_Template__c INCLUDES (:template) AND IsActive =: true AND DMT_Taxonomy_Value__r.gf_catalog_atrb_val4_name__c = 'Category' ORDER BY Name
            ];
        } else {
            throw new AuraHandledException('El recordId no pertenece a Opportunity ni a DMT_Line__c');
        }
    }

    @AuraEnabled
    public static void saveCategoryOtherLine(Id lineId, Id productId, String productName, String productCode, String maxTerm) {

        try {
            if(lineId != null && productId != null) {
            // Crear nuevo registro
            Integer riskSize = DMT_Passport_Selector.getRiskLineAll(lineId).size();
            DMT_Risk_Line_Term__c lineTerm = new DMT_Risk_Line_Term__c();
            lineTerm.DMT_Line__c = lineId;
            lineTerm.Name = productName;
            lineTerm.DMT_Init_Term__c = '0';
            lineTerm.DMT_End_Term__c = maxTerm;
            lineTerm.DMT_Product__c = productId;
            lineTerm.g_expert_criteria_risk_type__c = productCode;
            lineTerm.gf_group_priority_line_id__c = riskSize > 9 ? String.valueOf(riskSize + 1) : '0' + String.valueOf(riskSize + 1) ;

            insert lineTerm;
            }
        } catch (Exception e) {
            throw new AuraHandledException('An error occur while creating category: ' + e.getMessage());
        }

    }

      @AuraEnabled
    public static void saveSelectedClients(List<Object> selectedClients, Id groupAccount, String groupCode, String lineId, Id recordId, String booking, String mainHolderCustomerId, String priorityId) {

        String extId = lineId + '_' + priorityId;
        if (selectedClients == null || selectedClients.isEmpty()) {
            Custom_Association__c caToDelete = DMT_Passport_Selector.getCustomAssoById(extId);
            delete caToDelete;
        }else {

        // --- Crear el registro padre: Custom_Association__c ---
        Custom_Association__c association = new Custom_Association__c();
        association.Group__c = groupAccount;
        association.g_group_id__c = groupCode;
        association.gf_customer_group_id__c = extId;
        //association.gf_cutoff_date__c = Date.today();
        association.DMT_Line__c = recordId;
        //association.g_entific_id__c = booking;
        association.gf_origin_application_type__c = '04';
        association.g_customer_id__c = mainHolderCustomerId;

        upsert association gf_customer_group_id__c;
        // --- Crear los registros hijo: Custom_Association_Client__c ---
        List<Custom_Association_Client__c> clientRecords = new List<Custom_Association_Client__c>();
        Custom_Association__c customAsso = DMT_Passport_Selector.getCustomAssoById(extId);
        List<String> listIds = new List<String> {customAsso.Id};
        List<Custom_Association_Client__c> caClients = DMT_Passport_Selector.getLineClients(listIds);
        if (!caClients.isEmpty()) {
            delete caClients;
        }
        for (Object rawClient : selectedClients) {
            Map<Object, Object> client = (Map<Object, Object>) rawClient;
            String customerId = (String) client.get('customerId');

            Custom_Association_Client__c cac = new Custom_Association_Client__c();
            cac.Custom_Association__c = customAsso.Id;
            cac.Alpha_Code_Client__c = customerId;
            cac.g_customer_id__c = customerId;
            cac.g_entific_id__c = booking;
            cac.gf_customer_group_id__c = lineId + '_' + priorityId;
            //cac.gf_cutoff_date__c = Date.today();
            //cac.Alpha_Code__c = customerId;
            cac.gf_origin_application_type__c = '04';

            clientRecords.add(cac);
        }

        if (!clientRecords.isEmpty()) {
            insert clientRecords;
        }
        }

    }

    @InvocableMethod(label='Update Risk Line Terms'
                     description='Updates dmt_end_term__c based on days difference between today and dmt_max_date__c')
    public static void updateRiskLineTerms(List<List<dmt_risk_line_term__c>> risks) {
        List<Integer> PREDEFINED_TERMS = new List<Integer>{0,2,3,4,7,10,15,20,30,45,60,90,120,150,180,270,365,548,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300,7665,8030,9125,9855,10950,11680,12775,13505,14600,15330,16425};
        if (risks[0] == null || risks[0].isEmpty()) {
            return;
        }
        List<dmt_risk_line_term__c> riskToDelete = new List<dmt_risk_line_term__c>();
        List<dmt_risk_line_term__c> riskToUpdate = new List<dmt_risk_line_term__c>();
        List<List<dmt_risk_line_term__c>> listOfListClone = new List<List<dmt_risk_line_term__c>>();
        // 1. Obtener los registros que tienen fecha

        for ( List<dmt_risk_line_term__c> records: risks ) {
            if (records.isEmpty()) {
            return;
            }
            List <dmt_risk_line_term__c> listClone = new List <dmt_risk_line_term__c>();
            Date today = Date.today();
            List<dmt_risk_line_term__c> recordsToUpdate = new List<dmt_risk_line_term__c>();

            // 2. Procesar cada registro
            for (dmt_risk_line_term__c record : records) {
                try {
                    dmt_risk_line_term__c recordClone = record.clone(false, true);
                    // Calcular diferencia de días entre hoy y dmt_max_date__c
                    String closestTerm = null;
                    if( record.dmt_max_date__c != null) {
                        Integer daysDifference = today.daysBetween(record.dmt_max_date__c);

                        // Si la fecha es en el pasado, usar 0
                        if (daysDifference < 0) {
                            daysDifference = 0;
                        }

                        // Encontrar el término más cercano por arriba


                        for (Integer term : PREDEFINED_TERMS) {
                            if (term >= daysDifference) {
                                closestTerm = String.valueOf(term);
                                break;
                            }
                        }

                        // Si no encontramos (todos son menores), usar el último
                        if (closestTerm == null) {
                            closestTerm = String.valueOf(PREDEFINED_TERMS[PREDEFINED_TERMS.size() - 1]);
                        }
                        recordClone.dmt_end_term__c = closestTerm;
                        listClone.add(recordClone);
                        record.DMT_End_Term__c = closestTerm;
                        riskToUpdate.add(record);
                    } else {
                        if(recordClone.DMT_Risk_Type__c == DMT_Constants.RSK_SINGULAR || recordClone.DMT_Risk_Type__c == DMT_Constants.RSK_EQUITY || recordClone.DMT_Risk_Type__c == DMT_Constants.RSK_DEPOS) {
                            riskToDelete.add(record);
                        }

                        closestTerm = recordClone.DMT_End_Term__c;
                        recordClone.dmt_end_term__c = closestTerm;
                        listClone.add(recordClone);
                    }


                } catch (Exception e) {
                    System.debug('Error procesando registro ' + record.Id + ': ' + e.getMessage());
                    // Continuar con el siguiente registro
                }
            }
            listOfListClone.add(listClone);
        }
        List<List<dmt_risk_line_term__c>> risktoInsert = DMT_Line_Helper.singularTreasuryConsumption(listOfListClone);

        List<dmt_risk_line_term__c> listToInsert = new List<dmt_risk_line_term__c>();
        for ( List<dmt_risk_line_term__c> riskList: risktoInsert ) {
            for ( dmt_risk_line_term__c risk: riskList ) {
                listToInsert.add(risk.clone(false,true));
            }
        }
        // 3. Hacer UPDATE de todos los registros procesados
        if (!listToInsert.isEmpty()) {
            delete riskToDelete;
            insert listToInsert;
            update riskToUpdate;
        }
    }
}