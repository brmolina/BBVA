/**
 * @description Clase para realizar mapeos dinámicos de campos basados en un JSON de configuración.
 * Permite definir dinámicamente qué campos consultar y cómo mapearlos en el resultado final.
 * 
 * @example
 * String config = '{"nombreCampo":"%Opportunity.Id%","products":{"name":"%OpportunityLineItem.Name%"}}';
 * String oppId = '006xx000003DHyAAM';
 * Map<String, Object> result = DMT_DynamicFieldMapper.mapFields(config, oppId);
 */
public with sharing class DMT_DynamicFieldMapper {
    
    /**
     * @description Realiza el mapeo dinámico de campos según la configuración almacenada en custom metadata
     * @param developerName Nombre del desarrollador del registro en DMT_Dynamic_Int__md
     * @param opportunityId ID de la oportunidad a consultar
     * @return Map con los datos mapeados según la configuración
     * 
     * @example
     * Map<String, Object> result = DMT_DynamicFieldMapper.mapFields('sample', '006xx000003DHyAAM');
     */
    public static Map<String, Object> mapFields(String developerName, String opportunityId) {
        return mapFields(developerName, opportunityId, null);
    }

    /**
     * @description Realiza el mapeo dinámico de campos según la configuración almacenada en custom metadata,
     * incluyendo parámetros adicionales que se añaden tal cual al resultado final.
     * @param developerName Nombre del desarrollador del registro en DMT_Dynamic_Int__md
     * @param opportunityId ID de la oportunidad a consultar
     * @param additionalParams Parámetros adicionales que se incluyen directamente en el resultado (clave-valor)
     * @return Map con los datos mapeados según la configuración más los parámetros adicionales
     * 
     * @example
     * Map<String, Object> extra = new Map<String, Object>{'canal' => 'WEB', 'origen' => 'TCM'};
     * Map<String, Object> result = DMT_DynamicFieldMapper.mapFields('sample', '006xx000003DHyAAM', extra);
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> mapFields(String developerName, String opportunityId, Map<String, Object> additionalParams) {
        try {
            // Obtener el JSON de configuración desde el custom metadata
            String configJson = DMT_DynamicIntMetadataService.getJsonTemplate(developerName);

            // Pre-procesar: envolver en comillas los placeholders %...% sin comillas
            // (necesario para campos numéricos definidos sin comillas en el JSON)
            configJson = configJson.replaceAll('(?<!")(%[A-Za-z0-9._]+%)(?!")', '"$1"');
            
            // Parsear la configuración
            Map<String, Object> config = (Map<String, Object>) JSON.deserializeUntyped(configJson);
            
            // Extraer los campos necesarios de la configuración
            FieldExtractor fieldExtractor = new FieldExtractor(config);
            
            // Construir y ejecutar las queries
            QueryBuilder queryBuilder = new QueryBuilder(fieldExtractor);
            Map<String, List<Map<String, Object>>> queryResults = queryBuilder.executeQueries(opportunityId);
            
            // Mapear los resultados según la configuración
            FieldMapper fieldMapper = new FieldMapper(config, queryResults);
            Map<String, Object> result = fieldMapper.getMapperResult();

            // Añadir parámetros adicionales tal cual al resultado
            if (additionalParams != null && !additionalParams.isEmpty()) {
                result.putAll(additionalParams);
            }

            System.debug('debug FIELDMAPPER JSON: ' + JSON.serialize(result, true));
            return result;
            
        } catch (Exception e) {
            throw new DynamicMapperException('Error al mapear campos: ' + e.getMessage());
        }
    }
    
    /**
     * @description Clase interna para extraer los campos del JSON de configuración
     */
    private class FieldExtractor {
        private Map<String, Object> config;
        private Map<String, Set<String>> objectFields; // Map de Objeto -> Set de campos
        
        public FieldExtractor(Map<String, Object> config) {
            this.config = config;
            this.objectFields = new Map<String, Set<String>>();
            extractAllFields();
        }
        
        /**
         * @description Extrae recursivamente todos los campos del JSON de configuración
         */
        private void extractAllFields() {
            extractFieldsRecursive(config);
        }
        
        /**
         * @description Extrae campos de forma recursiva para manejar estructuras anidadas
         */
        private void extractFieldsRecursive(Object obj) {
            if (obj instanceof Map<String, Object>) {
                Map<String, Object> mapObj = (Map<String, Object>) obj;
                for (String key : mapObj.keySet()) {
                    Object value = mapObj.get(key);
                    if (value instanceof String) {
                        String strValue = (String) value;
                        if (strValue.startsWith('%') && strValue.endsWith('%')) {
                            parseAndAddField(strValue);
                        }
                    } else if (value instanceof Map<String, Object>) {
                        extractFieldsRecursive(value);
                    } else if (value instanceof List<Object>) {
                        extractFieldsRecursive(value);
                    }
                }
            } else if (obj instanceof List<Object>) {
                List<Object> listObj = (List<Object>) obj;
                for (Object item : listObj) {
                    extractFieldsRecursive(item);
                }
            }
        }
        
        /**
         * @description Parsea un campo con formato %Object.Field% y lo añade al mapa de campos
         */
        private void parseAndAddField(String fieldReference) {
            // Formato: %Object.Field%
            String cleaned = fieldReference.replace('%', '');
            List<String> parts = cleaned.split('\\.');
            
            if (parts.size() == 2) {
                String objectName = parts[0].trim();
                String fieldName = parts[1].trim();
                
                if (!objectFields.containsKey(objectName)) {
                    objectFields.put(objectName, new Set<String>());
                }
                objectFields.get(objectName).add(fieldName);
            }
        }
        
        public Map<String, Set<String>> getObjectFields() {
            return objectFields;
        }
    }
    
    /**
     * @description Clase interna para construir y ejecutar las queries SOQL dinámicamente
     */
    private class QueryBuilder {
        private Map<String, Set<String>> objectFields;
        
        public QueryBuilder(FieldExtractor fieldExtractor) {
            this.objectFields = fieldExtractor.getObjectFields();
        }
        
        /**
         * @description Ejecuta las queries necesarias para obtener los datos
         * @return Map de Objeto -> List de registros obtenidos
         */
        public Map<String, List<Map<String, Object>>> executeQueries(String opportunityId) {
            Map<String, List<Map<String, Object>>> results = new Map<String, List<Map<String, Object>>>();
            
            if (objectFields.containsKey('Opportunity')) {
                String oppQuery = buildQuery('Opportunity', objectFields.get('Opportunity'), 'Id = \'' + opportunityId + '\'');
                List<Map<String, Object>> oppResults = executeQuery(oppQuery);
                results.put('Opportunity', oppResults);
            }
            
            if (objectFields.containsKey('OpportunityLineItem')) {
                String oppLineItemQuery = buildQuery(
                    'OpportunityLineItem', 
                    objectFields.get('OpportunityLineItem'), 
                    'OpportunityId = \'' + opportunityId + '\''
                );
                List<Map<String, Object>> oppLineItemResults = executeQuery(oppLineItemQuery);
                results.put('OpportunityLineItem', oppLineItemResults);
            }
            
            return results;
        }
        
        /**
         * @description Construye una query SOQL dinámicamente
         */
        private String buildQuery(String objectName, Set<String> fields, String whereClause) {
            String fieldsList = String.join(new List<String>(fields), ', ');
            String query = 'SELECT ' + fieldsList + ' FROM ' + objectName;
            
            if (String.isNotBlank(whereClause)) {
                query += ' WHERE ' + whereClause;
            }
            
            return query;
        }
        
        /**
         * @description Ejecuta una query SOQL y retorna los resultados como List de Maps
         */
        private List<Map<String, Object>> executeQuery(String query) {
            List<Map<String, Object>> results = new List<Map<String, Object>>();
            
            try {
                List<SObject> sObjects = Database.query(query);
                for (SObject sObj : sObjects) {
                    results.add(sObj.getPopulatedFieldsAsMap());
                }
            } catch (Exception e) {
                throw new DynamicMapperException('Error ejecutando query: ' + query + ' - ' + e.getMessage());
            }
            
            return results;
        }
    }
    
    /**
     * @description Clase interna para mapear los datos consultados según la configuración
     */
    private class FieldMapper {
        private Map<String, Object> config;
        private Map<String, List<Map<String, Object>>> queryResults;
        
        public FieldMapper(Map<String, Object> config, Map<String, List<Map<String, Object>>> queryResults) {
            this.config = config;
            this.queryResults = queryResults;
        }
        
        /**
         * @description Obtiene el resultado final mapeado
         */
        public Map<String, Object> getMapperResult() {
            Map<String, Object> result = new Map<String, Object>();
            mapConfigToResult(config, result, queryResults.get('Opportunity'), queryResults.get('OpportunityLineItem'));
            return result;
        }
        
        /**
         * @description Mapea la configuración a los resultados de forma recursiva.
         * Soporta bloques condicionales mediante la clave reservada _condition.
         */
        private void mapConfigToResult(
            Map<String, Object> config, 
            Map<String, Object> result, 
            List<Map<String, Object>> oppData,
            List<Map<String, Object>> oppLineItemData
        ) {
            for (String key : config.keySet()) {
                if (key == '_condition' || key == '_value') continue;

                Object value = config.get(key);
                
                if (value instanceof String) {
                    String strValue = (String) value;
                    if (strValue.startsWith('%') && strValue.endsWith('%')) {
                        result.put(key, getFieldValue(strValue, oppData, oppLineItemData));
                    } else {
                        result.put(key, value);
                    }
                } else if (value instanceof Map<String, Object>) {
                    Map<String, Object> nestedConfig = (Map<String, Object>) value;

                    // Evaluar _condition si existe
                    if (nestedConfig.containsKey('_condition')) {
                        ConditionEvaluator evaluator = new ConditionEvaluator(oppData, oppLineItemData);
                        if (!evaluator.evaluate(nestedConfig.get('_condition'))) continue;

                        // Condición cumplida: ¿resultado escalar con _value?
                        if (nestedConfig.containsKey('_value')) {
                            Object scalarValue = nestedConfig.get('_value');
                            if (scalarValue instanceof String) {
                                String strScalar = (String) scalarValue;
                                if (strScalar.startsWith('%') && strScalar.endsWith('%')) {
                                    scalarValue = getFieldValue(strScalar, oppData, oppLineItemData);
                                }
                            }
                            result.put(key, scalarValue);
                            continue;
                        }

                        // Clonar sin _condition para continuar el procesado normal del bloque
                        Map<String, Object> cleanedConfig = new Map<String, Object>(nestedConfig);
                        cleanedConfig.remove('_condition');
                        nestedConfig = cleanedConfig;
                    }

                    // Verificar si es para una lista (productos)
                    if (isListConfig(nestedConfig, oppLineItemData)) {
                        List<Map<String, Object>> mappedList = new List<Map<String, Object>>();
                        if (oppLineItemData != null) {
                            for (Map<String, Object> oppLineItem : oppLineItemData) {
                                Map<String, Object> mappedItem = new Map<String, Object>();
                                mapNestedConfig(nestedConfig, mappedItem, oppLineItem);
                                mappedList.add(mappedItem);
                            }
                        }
                        result.put(key, mappedList);
                    } else {
                        Map<String, Object> nestedResult = new Map<String, Object>();
                        mapNestedConfig(nestedConfig, nestedResult, oppData != null && !oppData.isEmpty() ? oppData.get(0) : null);
                        result.put(key, nestedResult);
                    }
                } else if (value instanceof List<Object>) {
                    result.put(key, value);
                }
            }
        }
        
        /**
         * @description Mapea configuración anidada a un resultado.
         * Soporta bloques condicionales mediante la clave reservada _condition.
         */
        private void mapNestedConfig(Map<String, Object> nestedConfig, Map<String, Object> result, Map<String, Object> sourceData) {
            for (String key : nestedConfig.keySet()) {
                if (key == '_condition' || key == '_value') continue;

                Object value = nestedConfig.get(key);
                
                if (value instanceof String) {
                    String strValue = (String) value;
                    if (strValue.startsWith('%') && strValue.endsWith('%')) {
                        result.put(key, getFieldValueFromSource(strValue, sourceData));
                    } else {
                        result.put(key, value);
                    }
                } else if (value instanceof Map<String, Object>) {
                    Map<String, Object> innerNested = (Map<String, Object>) value;

                    // Evaluar _condition si existe
                    if (innerNested.containsKey('_condition')) {
                        ConditionEvaluator evaluator = new ConditionEvaluator(sourceData);
                        if (!evaluator.evaluate(innerNested.get('_condition'))) continue;

                        if (innerNested.containsKey('_value')) {
                            Object scalarValue = innerNested.get('_value');
                            if (scalarValue instanceof String) {
                                String strScalar = (String) scalarValue;
                                if (strScalar.startsWith('%') && strScalar.endsWith('%')) {
                                    scalarValue = getFieldValueFromSource(strScalar, sourceData);
                                }
                            }
                            result.put(key, scalarValue);
                            continue;
                        }

                        Map<String, Object> cleanedInner = new Map<String, Object>(innerNested);
                        cleanedInner.remove('_condition');
                        innerNested = cleanedInner;
                    }

                    Map<String, Object> innerResult = new Map<String, Object>();
                    mapNestedConfig(innerNested, innerResult, sourceData);
                    result.put(key, innerResult);
                }
            }
        }
        
        /**
         * @description Verifica si una configuración es para una lista
         */
        private Boolean isListConfig(Map<String, Object> nestedConfig, List<Map<String, Object>> oppLineItemData) {
            // Si hay datos de OpportunityLineItem y los campos de la config coinciden con esos datos, es una lista
            if (oppLineItemData == null || oppLineItemData.isEmpty()) {
                return false;
            }
            
            for (String key : nestedConfig.keySet()) {
                Object value = nestedConfig.get(key);
                if (value instanceof String) {
                    String strValue = (String) value;
                    if (strValue.contains('OpportunityLineItem')) {
                        return true;
                    }
                }
            }
            
            return false;
        }
        
        /**
         * @description Obtiene el valor de un campo desde los datos consultados
         */
        private Object getFieldValue(String fieldReference, List<Map<String, Object>> oppData, List<Map<String, Object>> oppLineItemData) {
            String cleaned = fieldReference.replace('%', '');
            List<String> parts = cleaned.split('\\.');
            
            if (parts.size() != 2) {
                return null;
            }
            
            String objectName = parts[0].trim();
            String fieldName = parts[1].trim();
            
            if (objectName.equals('Opportunity') && oppData != null && !oppData.isEmpty()) {
                return oppData.get(0).get(fieldName);
            } else if (objectName.equals('OpportunityLineItem') && oppLineItemData != null && !oppLineItemData.isEmpty()) {
                return oppLineItemData.get(0).get(fieldName);
            }
            
            return null;
        }
        
        /**
         * @description Obtiene el valor de un campo desde una fuente de datos
         */
        private Object getFieldValueFromSource(String fieldReference, Map<String, Object> sourceData) {
            if (sourceData == null) {
                return null;
            }
            
            String cleaned = fieldReference.replace('%', '');
            List<String> parts = cleaned.split('\\.');
            
            if (parts.size() == 2) {
                String fieldName = parts[1].trim();
                return sourceData.get(fieldName);
            }
            
            return null;
        }
    }
    
    /**
     * @description Evalúa condiciones definidas en el JSON de configuración.
     *
     * Condición simple:
     *   { "field": "%Opportunity.StageName%", "op": "eq", "value": "Closed Won" }
     *
     * Condición compuesta:
     *   { "and": [ {...}, {...} ] }
     *   { "or":  [ {...}, {...} ] }
     *   { "not": {...} }
     *
     * Operadores: eq, neq, gt, gte, lt, lte, contains, notcontains, isblank, isnotblank
     */
    private class ConditionEvaluator {
        private List<Map<String, Object>> oppData;
        private List<Map<String, Object>> oppLineItemData;
        private Map<String, Object> rowData;

        // Contexto top-level (Opportunity / OpportunityLineItem)
        public ConditionEvaluator(List<Map<String, Object>> oppData, List<Map<String, Object>> oppLineItemData) {
            this.oppData          = oppData;
            this.oppLineItemData  = oppLineItemData;
            this.rowData          = null;
        }

        // Contexto de fila individual (bloques anidados / listas)
        public ConditionEvaluator(Map<String, Object> rowData) {
            this.rowData         = rowData;
            this.oppData         = null;
            this.oppLineItemData = null;
        }

        /**
         * @description Evalúa un nodo de condición (simple o compuesto)
         */
        public Boolean evaluate(Object conditionNode) {
            if (conditionNode == null) return true;
            if (!(conditionNode instanceof Map<String, Object>)) return true;

            Map<String, Object> cond = (Map<String, Object>) conditionNode;

            // AND: todos los sub-nodos deben ser true
            if (cond.containsKey('and')) {
                for (Object sub : (List<Object>) cond.get('and')) {
                    if (!evaluate(sub)) return false;
                }
                return true;
            }

            // OR: al menos un sub-nodo debe ser true
            if (cond.containsKey('or')) {
                for (Object sub : (List<Object>) cond.get('or')) {
                    if (evaluate(sub)) return true;
                }
                return false;
            }

            // NOT: invierte la condición interna
            if (cond.containsKey('not')) {
                return !evaluate(cond.get('not'));
            }

            // Condición simple: { "field": "%Obj.Field%", "op": "...", "value": "..." }
            if (cond.containsKey('field') && cond.containsKey('op')) {
                String fieldRef  = (String) cond.get('field');
                String op        = (String) cond.get('op');
                String expected  = cond.containsKey('value') ? String.valueOf(cond.get('value')) : null;
                Object rawActual = resolveFieldRef(fieldRef);
                String actual    = rawActual != null ? String.valueOf(rawActual) : null;
                return applyOp(actual, op, expected);
            }

            return true; // nodo desconocido: no bloquea
        }

        private Object resolveFieldRef(String fieldRef) {
            if (!fieldRef.startsWith('%') || !fieldRef.endsWith('%')) {
                return fieldRef; // valor literal
            }
            String cleaned = fieldRef.replace('%', '');
            List<String> parts = cleaned.split('\\.');
            if (parts.size() != 2) return null;

            String objectName = parts[0].trim();
            String fieldName  = parts[1].trim();

            if (rowData != null) {
                return rowData.get(fieldName);
            }
            if (objectName == 'Opportunity' && oppData != null && !oppData.isEmpty()) {
                return oppData[0].get(fieldName);
            }
            if (objectName == 'OpportunityLineItem' && oppLineItemData != null && !oppLineItemData.isEmpty()) {
                return oppLineItemData[0].get(fieldName);
            }
            return null;
        }

        private Boolean applyOp(String actual, String op, String expected) {
            switch on op.toLowerCase() {
                when 'eq'          { return actual != null && actual == expected; }
                when 'neq'         { return actual == null || actual != expected; }
                when 'isblank'     { return String.isBlank(actual); }
                when 'isnotblank'  { return String.isNotBlank(actual); }
                when 'contains'    { return actual != null && actual.toLowerCase().contains(expected.toLowerCase()); }
                when 'notcontains' { return actual == null || !actual.toLowerCase().contains(expected.toLowerCase()); }
                when 'gt'          { return actual != null && Decimal.valueOf(actual) >  Decimal.valueOf(expected); }
                when 'gte'         { return actual != null && Decimal.valueOf(actual) >= Decimal.valueOf(expected); }
                when 'lt'          { return actual != null && Decimal.valueOf(actual) <  Decimal.valueOf(expected); }
                when 'lte'         { return actual != null && Decimal.valueOf(actual) <= Decimal.valueOf(expected); }
                when else          { return true; }
            }
        }
    }

    /**
     * @description Excepción personalizada para errores de mapeo dinámico
     */
    public class DynamicMapperException extends Exception {}
}