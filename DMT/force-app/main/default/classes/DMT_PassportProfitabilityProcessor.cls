public with sharing class DMT_PassportProfitabilityProcessor {

    private static Decimal safeToDecimal(Object value, Integer integerPart, Integer decimalPart) {
        if (value == null) return null;
        
        try {
            Decimal result;
            
            if (value instanceof Decimal) {
                result = (Decimal) value;
            } else if (value instanceof Integer) {
                result = Decimal.valueOf((Integer) value);
            } else if (value instanceof Long) {
                result = Decimal.valueOf((Long) value);
            } else if (value instanceof Double) {
                String stringValue = String.valueOf(value);
                result = Decimal.valueOf(stringValue);
            } else if (value instanceof String) {
                String stringValue = (String) value;
                if (String.isBlank(stringValue)) return null;
                stringValue = stringValue.trim().replace(',', '.');
                result = Decimal.valueOf(stringValue);
            } else {
                return null;
            }
            
            // Redondear a los decimales permitidos
            if (decimalPart > 0) {
                result = result.setScale(decimalPart, RoundingMode.HALF_UP);
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error convirtiendo a Decimal: ' + value + ' - ' + e.getMessage());
            return null;
        }
    }

    // Sobrecarga para usar valores por defecto
    private static Decimal safeToDecimal(Object value) {
        return safeToDecimal(value, 12, 6);
    }

    // ============================================================================
    // TYPE CONVERTERS
    // ============================================================================
    
    /** Number(12,6) – Allin Drawn / Allin Undrawn */
    private static Decimal toNumber12_6(Object value) {
        return safeToDecimal(value, 12, 6);
    }

    /** Currency(16,2) – EAD, Capital, FD, Net Income */
    private static Decimal toCurrency16_2(Object value) {
        return safeToDecimal(value, 16, 2);
    }

    /** Percent(14,4) – RORC, RAROEC */
    private static Decimal toPercent14_4(Object value) {
        return safeToDecimal(value, 14, 4);
    }

    /**
     * Localizes the Profitability Engine feature map inside a parsed passport JSON.
     * Returns null if not found.
     */
    private static Map<String, Object> findProfitabilityFeature(Map<String, Object> jsonData) {
        Map<String, Object> data = (Map<String, Object>) jsonData.get('data');
        if (data == null) return null;
        
        List<Object> features = (List<Object>) data.get('features');
        if (features == null) return null;
        
        for (Object feat : features) {
            Map<String, Object> feature = (Map<String, Object>) feat;
            String featureName = (String) feature.get('name');
            if (featureName == 'Profitability Engine') {
                return feature;
            }
        }
        return null;
    }

    // ============================================================================
    // MAIN PERSISTENCE METHOD
    // ============================================================================

    /**
     * Main entry point for batch migration and synchronous persistence.
     * Called from DMT_Passport_Helper.callPassportService() after passport save.
     * Persists 15 profitability fields: 14 shared (Opp + OLI) + 1 Opportunity-only
     */
    public static void updateProfitabilityFields(Id opportunityId, String bodyResponse) {
        if (String.isBlank(bodyResponse) || opportunityId == null) {
            return;
        }

        try {
            // Parse JSON
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(bodyResponse);
            Map<String, Object> profitabilityFeature = findProfitabilityFeature(jsonData);
            
            if (profitabilityFeature == null) {
                System.debug('Profitability Engine feature not found in JSON');
                return;
            }

            Map<String, Object> profitability = (Map<String, Object>) profitabilityFeature.get('profitability');
            if (profitability == null) return;

            List<Object> results = (List<Object>) profitability.get('results');
            if (results == null || results.isEmpty()) return;

            // Separate aggregate (no productId) from per-product results
            Map<String, Object> aggregateResult = null;
            List<Object> productResults = new List<Object>();

            for (Object resultObj : results) {
                Map<String, Object> result = (Map<String, Object>) resultObj;
                if (!result.containsKey('productId') || result.get('productId') == null) {
                    aggregateResult = result;
                } else {
                    productResults.add(result);
                }
            }

            // Build product map with deduplication (prioritize isLine=true)
            Map<String, Map<String, Object>> productMap = buildProductResultByProductId(productResults);

            // Fetch Opportunity and related OpportunityLineItems
            Opportunity opp = [
                SELECT Id, (SELECT Id, gf_group_priority_opportunity_id__c FROM OpportunityLineItems)
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            // Map OLI by product ID
            Map<String, OpportunityLineItem> oliByProductId = new Map<String, OpportunityLineItem>();
            for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                if (oli.gf_group_priority_opportunity_id__c != null) {
                    oliByProductId.put(oli.gf_group_priority_opportunity_id__c, oli);
                }
            }

            // Update Opportunity with aggregate result
            if (aggregateResult != null) {
                mapProfitabilityToOpportunity(opp, aggregateResult);
            }

            // Update OpportunityLineItems with product results
            List<OpportunityLineItem> oliToUpdate = new List<OpportunityLineItem>();
            for (String productId : productMap.keySet()) {
                if (oliByProductId.containsKey(productId)) {
                    OpportunityLineItem oli = oliByProductId.get(productId);
                    mapProfitabilityToLineItem(oli, productMap.get(productId));
                    oliToUpdate.add(oli);
                }
            }

            // Save changes
            update opp;
            if (!oliToUpdate.isEmpty()) {
                update oliToUpdate;
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in updateProfitabilityFields: ' + e.getMessage() + ' at ' + e.getStackTraceString());
        }
    }

    /**
     * Builds a map of product results by productId, deduplicating intelligently.
     * When same productId appears multiple times, prioritizes isLine=true result.
     */
    private static Map<String, Map<String, Object>> buildProductResultByProductId(List<Object> results) {
        Map<String, Map<String, Object>> productMap = new Map<String, Map<String, Object>>();

        for (Object resultObj : results) {
            Map<String, Object> result = (Map<String, Object>) resultObj;
            String productId = (String) result.get('productId');
            
            if (productId == null) continue;

            if (!productMap.containsKey(productId)) {
                productMap.put(productId, result);
            } else {
                // Check if we should replace existing result
                if (shouldReplaceProductResult(productMap.get(productId), result)) {
                    productMap.put(productId, result);
                }
            }
        }

        return productMap;
    }

    /**
     * Determines if newResult should replace existingResult.
     * Prioritizes isLine=true over isLine=false.
     */
    private static Boolean shouldReplaceProductResult(Map<String, Object> existing, Map<String, Object> newResult) {
        Boolean existingIsLine = isTrueValue(existing.get('isLine'));
        Boolean newIsLine = isTrueValue(newResult.get('isLine'));
        
        // If existing is isLine=true, don't replace
        if (existingIsLine && !newIsLine) {
            return false;
        }
        // If new is isLine=true and existing is not, replace
        if (newIsLine && !existingIsLine) {
            return true;
        }
        // Otherwise keep existing
        return false;
    }

    /**
     * Safely evaluates if a value represents true.
     */
    private static Boolean isTrueValue(Object value) {
        if (value == null) return false;
        if (value instanceof Boolean) return (Boolean) value;
        if (value instanceof String) return Boolean.valueOf((String) value);
        return false;
    }

    /**
     * Maps profitability result to Opportunity fields (15 fields total).
     * 14 shared with OpportunityLineItem + 1 Opportunity-only field
     */
    private static void mapProfitabilityToOpportunity(Opportunity opp, Map<String, Object> result) {
        // Shared fields with OLI (14)
        opp.DMT_Allin_Drawn__c = toNumber12_6(result.get('allInDb'));
        opp.DMT_Allin_Undrawn__c = toNumber12_6(result.get('allInFb'));
        opp.DMT_EAD_Eco__c = toCurrency16_2(result.get('economicEad'));
        opp.DMT_EAD_Reg__c = toCurrency16_2(result.get('regulatoryEad'));
        opp.DMT_Regulatory_Capital__c = toCurrency16_2(result.get('regulatoryCapital'));
        opp.DMT_Economic_Capital__c = toCurrency16_2(result.get('economicCapital'));
        opp.DMT_Franchise_Deal__c = toCurrency16_2(result.get('franchiseDeal'));
        opp.DMT_Net_Income_Eco__c = toCurrency16_2(result.get('bdiEco'));
        opp.DMT_Net_Income_Reg__c = toCurrency16_2(result.get('bdiReg'));
        opp.DMT_RORC__c = toPercent14_4(result.get('rorc'));
        opp.DMT_RAROEC__c = toPercent14_4(result.get('raroec'));
        opp.DMT_RWA_eco__c = toCurrency16_2(result.get('economicApr'));
        opp.DMT_RWA_reg__c = toCurrency16_2(result.get('regulatoryApr'));
        opp.DMT_RORC_CDD__c = toPercent14_4(result.get('rorcProspected'));

        // Opportunity-only field (1)
        opp.DMT_Global_Expected_RORC__c = toPercent14_4(result.get('clientRorc'));
    }

    /**
     * Maps profitability result to OpportunityLineItem fields (14 fields).
     * Same as Opportunity except no clientRorc (DMT_Global_Expected_RORC__c is Opportunity-only)
     * Note: Field capitalization differs (DMT_RWA_Eco__c vs DMT_RWA_eco__c for Opportunity)
     */
    private static void mapProfitabilityToLineItem(OpportunityLineItem oli, Map<String, Object> result) {
        // Shared fields (11)
        oli.DMT_Allin_Drawn__c = toNumber12_6(result.get('allInDb'));
        oli.DMT_Allin_Undrawn__c = toNumber12_6(result.get('allInFb'));
        oli.DMT_EAD_Eco__c = toCurrency16_2(result.get('economicEad'));
        oli.DMT_EAD_Reg__c = toCurrency16_2(result.get('regulatoryEad'));
        oli.DMT_Regulatory_Capital__c = toCurrency16_2(result.get('regulatoryCapital'));
        oli.DMT_Economic_Capital__c = toCurrency16_2(result.get('economicCapital'));
        oli.DMT_Franchise_Deal__c = toCurrency16_2(result.get('franchiseDeal'));
        oli.DMT_Net_Income_Eco__c = toCurrency16_2(result.get('bdiEco'));
        oli.DMT_Net_Income_Reg__c = toCurrency16_2(result.get('bdiReg'));
        oli.DMT_RORC__c = toPercent14_4(result.get('rorc'));
        oli.DMT_RAROEC__c = toPercent14_4(result.get('raroec'));

        // OpportunityLineItem-specific fields (3, note capital E/R)
        oli.DMT_RWA_Eco__c = toCurrency16_2(result.get('economicApr'));
        oli.DMT_RWA_Reg__c = toCurrency16_2(result.get('regulatoryApr'));
        oli.DMT_RORC_CDD__c = toPercent14_4(result.get('rorcProspected'));
        // Note: No clientRorc mapping for OpportunityLineItem (DMT_Global_Expected_RORC__c is Opportunity-only)
    }
    
    /**
     * Método invocable para Flow - Retorna solo valores agregados
     */
    @InvocableMethod(label='Obtener Profitability de Passport' description='Extrae valores RAROC y RORC del JSON de Passport')
    public static List<ProfitabilityResult> obtenerProfitability(List<ProfitabilityRequest> requests) {
        List<ProfitabilityResult> resultados = new List<ProfitabilityResult>();
        
        for(ProfitabilityRequest req : requests) {
            ProfitabilityResult res = new ProfitabilityResult();
            
            try {
                // Buscar Opportunity por Id
                Opportunity opp = [SELECT Id 
                                 FROM Opportunity 
                                 WHERE Id = :req.opportunityDMTId 
                                 LIMIT 1];
                
                // Buscar Passport asociado
                Passport__c passport = [SELECT Id, DMT_Passport_Save__c 
                                      FROM Passport__c 
                                      WHERE Opportunity__c = :opp.Id 
                                      ORDER BY CreatedDate DESC 
                                      LIMIT 1];
                
                // Parsear JSON
                Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(passport.DMT_Passport_Save__c);
                Map<String, Object> data = (Map<String, Object>) jsonData.get('data');
                
                // Buscar feature de Profitability Engine
                List<Object> features = (List<Object>) data.get('features');
                Map<String, Object> profitabilityFeature = null;
                
                for(Object feat : features) {
                    Map<String, Object> feature = (Map<String, Object>) feat;
                    String featureName = (String) feature.get('name');
                    if (featureName == 'Profitability Engine') {
                        profitabilityFeature = feature;
                        break;
                    }
                }
                
                if (profitabilityFeature != null) {
                    Map<String, Object> profitability = (Map<String, Object>) profitabilityFeature.get('profitability');
                    List<Object> results = (List<Object>) profitability.get('results');
                    
                    if (req.isOpportunityLevel) {
                        // Nivel Oportunidad - buscar elemento sin productId
                        for(Object resultObj : results) {
                            Map<String, Object> result = (Map<String, Object>) resultObj;
                            if (!result.containsKey('productId') || result.get('productId') == null) {
                                res.raroec = safeToDecimal(result.get('raroec'));
                                res.rorc = safeToDecimal(result.get('rorc'));
                                res.isOpportunityLevel = true;
                                break;
                            }
                        }
                    } else {
                        // Nivel Producto - NO se usa en Flow (se llama desde Apex directamente)
                        res.isOpportunityLevel = false;
                        res.mensaje = 'Usar método getProductLevelProfitability para nivel producto';
                    }
                }
                
                res.success = true;
                res.opportunityId = opp.Id;
                res.passportId = passport.Id;
                
            } catch(Exception e) {
                res.success = false;
                res.mensaje = 'Error: ' + e.getMessage();
            }
            
            resultados.add(res);
        }
        
        return resultados;
    }
    
    /**
     * Método para Apex - Retorna lista completa de productos
     */
    public static List<ProductProfitability> getProductLevelProfitability(String opportunityDMTId) {
        List<ProductProfitability> productos = new List<ProductProfitability>();
        
        try {
            // Buscar Opportunity por Id
            Opportunity opp = [SELECT Id 
                             FROM Opportunity 
                             WHERE Id = :opportunityDMTId 
                             LIMIT 1];
            
            // Buscar Passport asociado
            Passport__c passport = [SELECT Id, DMT_Passport_Save__c 
                                  FROM Passport__c 
                                  WHERE Opportunity__c = :opp.Id 
                                  ORDER BY CreatedDate DESC 
                                  LIMIT 1];
            
            // Parsear JSON
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(passport.DMT_Passport_Save__c);
            Map<String, Object> data = (Map<String, Object>) jsonData.get('data');
            
            // Buscar feature de Profitability Engine
            List<Object> features = (List<Object>) data.get('features');
            Map<String, Object> profitabilityFeature = null;
            
            for(Object feat : features) {
                Map<String, Object> feature = (Map<String, Object>) feat;
                String featureName = (String) feature.get('name');
                if (featureName == 'Profitability Engine') {
                    profitabilityFeature = feature;
                    break;
                }
            }
            
            if (profitabilityFeature != null) {
                Map<String, Object> profitability = (Map<String, Object>) profitabilityFeature.get('profitability');
                List<Object> results = (List<Object>) profitability.get('results');
                
                // Recorrer todos los resultados que tengan productId
                for(Object resultObj : results) {
                    Map<String, Object> result = (Map<String, Object>) resultObj;
                    
                    if (result.containsKey('productId') && result.get('productId') != null) {
                        ProductProfitability prod = new ProductProfitability();
                        prod.productId = (String) result.get('productId');
                        prod.raroec = safeToDecimal(result.get('raroec'));
                        prod.rorc = safeToDecimal(result.get('rorc'));
                        
                        // Opcional: extraer más campos si los necesitas
                        // prod.economicCapital = (Decimal) result.get('economicCapital');
                        // prod.regulatoryCapital = (Decimal) result.get('regulatoryCapital');
                        // prod.bdi = (Decimal) result.get('bdi');
                        
                        productos.add(prod);
                    }
                }
            }
            
        } catch(Exception e) {
            System.debug('Error en getProductLevelProfitability: ' + e.getMessage());
        }
        
        return productos;
    }
    
    /**
     * Clase Request para el método invocable
     */
    public class ProfitabilityRequest {
        @InvocableVariable(required=true label='DMT Opportunity ID' description='El valor del campo Id de la Opportunity')
        public String opportunityDMTId;
        
        @InvocableVariable(required=true label='Nivel Opportunity' description='True para nivel Opportunity, False para nivel Producto')
        public Boolean isOpportunityLevel;
    }
    
    /**
     * Clase Resultado para el método invocable (Flow)
     */
    public class ProfitabilityResult {
        @InvocableVariable(label='Success' description='Indica si la operación fue exitosa')
        public Boolean success;
        
        @InvocableVariable(label='Opportunity ID' description='ID de Salesforce de la Opportunity')
        public String opportunityId;
        
        @InvocableVariable(label='Passport ID' description='ID de Salesforce del Passport')
        public String passportId;
        
        @InvocableVariable(label='RAROC' description='Valor de RAROEC a nivel Opportunity')
        public Decimal raroec;
        
        @InvocableVariable(label='RORC' description='Valor de RORC a nivel Opportunity')
        public Decimal rorc;
        
        @InvocableVariable(label='Es nivel Opportunity' description='Indica si es nivel Opportunity o Producto')
        public Boolean isOpportunityLevel;
        
        @InvocableVariable(label='Mensaje' description='Mensaje informativo o de error')
        public String mensaje;
    }
    
    /**
     * Clase para resultados a nivel producto (uso desde Apex)
     */
    public class ProductProfitability {
        public String productId;
        public Decimal raroec;
        public Decimal rorc;
        public Decimal economicCapital;
        public Decimal regulatoryCapital;
        public Decimal bdi;
        
        // Constructor vacío
        public ProductProfitability() {}
    }
}