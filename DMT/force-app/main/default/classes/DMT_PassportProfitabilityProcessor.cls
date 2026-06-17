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