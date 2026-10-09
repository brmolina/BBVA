/**
 * @description Clase para realizar mapeos dinámicos de campos basados en un JSON de configuración.
 * Permite definir dinámicamente qué campos consultar y cómo mapearlos en el resultado final.
 */
public with sharing class DMT_DynamicFieldMapper {
    
    public static Map<String, Object> mapFields(String developerName, String opportunityId) {
        return mapFields(developerName, opportunityId, null);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> mapFields(String developerName, String opportunityId, Map<String, Object> additionalParams) {
        try {
            String configJson = DMT_DynamicIntMetadataService.getJsonTemplate(developerName);
            configJson = configJson.replaceAll('(?<!")(%[A-Za-z0-9.\\[\\]_\\(\\)]+%)(?!")', '"$1"');
            
            Map<String, Object> config = (Map<String, Object>) JSON.deserializeUntyped(configJson);
            
            FieldExtractor fieldExtractor = new FieldExtractor(config);
            QueryBuilder queryBuilder = new QueryBuilder(fieldExtractor);
            Map<String, List<Map<String, Object>>> queryResults = queryBuilder.executeQueries(opportunityId);
            
            FieldMapper fieldMapper = new FieldMapper(config, queryResults, additionalParams);
            Map<String, Object> result = fieldMapper.getMapperResult();

            if (additionalParams != null && !additionalParams.isEmpty()) {
                result.putAll(additionalParams);
            }

            System.debug('debug FIELDMAPPER JSON: ' + JSON.serialize(result, true));
            return result;
            
        } catch (Exception e) {
            throw new DynamicMapperException('Error al mapear campos: ' + e.getMessage());
        }
    }

    public static void mapResponse(String developerName, String opportunityId, String responseBody) {
        try {
            String responseTemplate = DMT_DynamicIntMetadataService.getResponseTemplate(developerName);
            if (String.isBlank(responseTemplate)) {
                System.debug('DMT_DynamicFieldMapper.mapResponse — No response template configurado para: ' + developerName);
                return;
            }

            Map<String, Object> templateMap = (Map<String, Object>) JSON.deserializeUntyped(responseTemplate);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            ResponseMapper responseMapper = new ResponseMapper(templateMap, responseMap, opportunityId);
            responseMapper.processAndUpdate();

        } catch (Exception e) {
            throw new DynamicMapperException('Error al mapear response: ' + e.getMessage());
        }
    }
    
    // --- UTILS PARA EXTRACCIÓN ROBUSTA E INSENSIBLE A MAYÚSCULAS ---

    public static Object extractFromObject(Object source, List<String> parts, Integer startIndex) {
        Object current = source;
        for (Integer i = startIndex; i < parts.size(); i++) {
            if (current == null) return null;
            if (current instanceof Map<String, Object>) {
                current = getMapValueCaseInsensitive((Map<String, Object>) current, parts[i].trim());
            } else if (current instanceof SObject) {
                Map<String, Object> fieldsMap = ((SObject) current).getPopulatedFieldsAsMap();
                current = getMapValueCaseInsensitive(fieldsMap, parts[i].trim());
            } else if (current instanceof List<Object>) {
                try {
                    Integer index = Integer.valueOf(parts[i].trim());
                    List<Object> listObj = (List<Object>) current;
                    if (index >= 0 && index < listObj.size()) {
                        current = listObj.get(index);
                    } else {
                        return null;
                    }
                } catch (Exception e) {
                    return null;
                }
            } else {
                return null;
            }
        }
        return current;
    }

    public static Object getMapValueCaseInsensitive(Map<String, Object> mapObj, String key) {
        if (mapObj == null) return null;
        if (mapObj.containsKey(key)) return mapObj.get(key);
        for (String k : mapObj.keySet()) {
            if (k.equalsIgnoreCase(key)) return mapObj.get(k);
        }
        return null;
    }

    public static List<Map<String, Object>> getMapListCaseInsensitive(Map<String, List<Map<String, Object>>> allResults, String key) {
        if (allResults == null) return null;
        if (allResults.containsKey(key)) return allResults.get(key);
        for (String k : allResults.keySet()) {
            if (k.equalsIgnoreCase(key)) return allResults.get(k);
        }
        return null;
    }
    
    public static List<Map<String, Object>> getListFromResults(Map<String, List<Map<String, Object>>> allResults, String listPath) {
        if (String.isBlank(listPath)) return null;
        List<String> parts = listPath.split('\\.');
        if (parts.size() == 1) {
            return getMapListCaseInsensitive(allResults, parts[0]);
        }
        
        String rootObject = parts[0];
        List<Map<String, Object>> rootList = getMapListCaseInsensitive(allResults, rootObject);
        if (rootList == null || rootList.isEmpty()) return null;
        
        Object current = extractFromObject(rootList[0], parts, 1);
        if (current instanceof List<Object>) {
            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for (Object item : (List<Object>)current) {
                if (item instanceof Map<String, Object>) {
                    result.add((Map<String, Object>)item);
                }
            }
            return result;
        }
        return null;
    }

    private class FieldExtractor {
        private Map<String, Object> config;
        private Map<String, Set<String>> objectFields; 
        
        public FieldExtractor(Map<String, Object> config) {
            this.config = config;
            this.objectFields = new Map<String, Set<String>>();
            extractAllFields();
        }
        
        private void extractAllFields() {
            extractFieldsRecursive(config);
        }
        
        private void extractFieldsRecursive(Object obj) {
            if (obj instanceof Map<String, Object>) {
                Map<String, Object> mapObj = (Map<String, Object>) obj;
                for (String key : mapObj.keySet()) {
                    Object value = mapObj.get(key);
                    
                    if (key == '_list' && value instanceof String) {
                        String strValue = (String) value;
                        if (strValue.startsWith('LIST(') && strValue.endsWith(')')) {
                            String marker = strValue.substring(5, strValue.length() - 1).trim();
                            String rootObjName = marker.split('\\.')[0].trim();
                            if (!objectFields.containsKey(rootObjName)) {
                                objectFields.put(rootObjName, new Set<String>());
                            }
                        }
                    }

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
        
        private void parseAndAddField(String fieldReference) {
            String cleaned = fieldReference.replace('%', '');
            
            if (cleaned.startsWithIgnoreCase('SEMAFORO(') && cleaned.endsWith(')')) {
                cleaned = cleaned.substring(9, cleaned.length() - 1).trim();
            }

            if (cleaned.contains('[')) {
                String objectName = cleaned.substringBefore('[').trim();
                String fieldPath = cleaned.substringAfter('].').trim();
                
                if (!objectFields.containsKey(objectName)) {
                    objectFields.put(objectName, new Set<String>());
                }
                objectFields.get(objectName).add(fieldPath);
                
                if (objectName.equalsIgnoreCase('Case')) {
                    objectFields.get(objectName).add('DMT_Related_feature_name__c');
                }
            } else {
                List<String> parts = cleaned.split('\\.');
                
                if (parts.size() >= 2) {
                    String objectName = parts[0].trim();
                    List<String> fieldParts = new List<String>();
                    for (Integer i = 1; i < parts.size(); i++) {
                        fieldParts.add(parts[i].trim());
                    }
                    String fieldName = String.join(fieldParts, '.');
                    
                    if (!objectFields.containsKey(objectName)) {
                        objectFields.put(objectName, new Set<String>());
                    }
                    objectFields.get(objectName).add(fieldName);
                }
            }
        }
        
        public Map<String, Set<String>> getObjectFields() {
            return objectFields;
        }
    }
    
    private class QueryBuilder {
        private Map<String, Set<String>> objectFields;
        
        private final Map<String, String> FILTER_FIELD_BY_OBJECT = new Map<String, String>{
            'Opportunity'                                 => 'Id',
            'OpportunityLineItem'                         => 'OpportunityId',
            'DMT_Opportunity_Client__c'                   => 'DMT_MDE_Opportunity__c',
            'Case'                                        => 'opportunity_id__c',
            'DMT_Custom_Association_ClientOpportunity__c' => 'DMT_Custom_Association_Opportunity__r.Opportunity__c'
        };
        
        public QueryBuilder(FieldExtractor fieldExtractor) {
            this.objectFields = fieldExtractor.getObjectFields();
        }

        private String getFilterField(String objName) {
            for (String key : FILTER_FIELD_BY_OBJECT.keySet()) {
                if (key.equalsIgnoreCase(objName)) {
                    return FILTER_FIELD_BY_OBJECT.get(key);
                }
            }
            return null;
        }
        
        public Map<String, List<Map<String, Object>>> executeQueries(String opportunityId) {
            Map<String, List<Map<String, Object>>> results = new Map<String, List<Map<String, Object>>>();
            
            for (String objectName : objectFields.keySet()) {
                if (objectName.equalsIgnoreCase('User')) {
                    String userId = UserInfo.getUserId();
                    String whereClause = 'Id = \'' + String.escapeSingleQuotes(userId) + '\'';
                    String query = buildQuery(objectName, objectFields.get(objectName), whereClause);
                    results.put(objectName, executeQuery(query));
                    continue;
                }
                
                if (objectName.equalsIgnoreCase('Passport')) {
                    String query = 'SELECT DMT_Passport_Save__c FROM Passport__c WHERE Opportunity__c = \'' + String.escapeSingleQuotes(opportunityId) + '\' ORDER BY CreatedDate DESC LIMIT 1';
                    List<Map<String, Object>> parsedPassport = new List<Map<String, Object>>();
                    try {
                        List<SObject> passRecords = Database.query(query);
                        if (!passRecords.isEmpty() && passRecords[0].get('DMT_Passport_Save__c') != null) {
                            String jsonStr = (String) passRecords[0].get('DMT_Passport_Save__c');
                            Object parsed = JSON.deserializeUntyped(jsonStr);
                            if (parsed instanceof Map<String, Object>) {
                                parsedPassport.add((Map<String, Object>) parsed);
                            }
                        }
                    } catch (Exception e) {
                        System.debug('Error en query/parse de Passport: ' + e.getMessage());
                    }
                    results.put('Passport', parsedPassport);
                    continue;
                }

                String filterField = getFilterField(objectName);
                if (filterField == null) continue;
                
                String whereClause = filterField + ' = \'' + String.escapeSingleQuotes(opportunityId) + '\'';
                String query = buildQuery(objectName, objectFields.get(objectName), whereClause);
                results.put(objectName, executeQuery(query));
            }
            
            return results;
        }
        
        private String buildQuery(String objectName, Set<String> fields, String whereClause) {
            Set<String> selectFields = new Set<String>();
            Set<String> taskFields = new Set<String>(); 
            
            for (String f : fields) {
                if (objectName.equalsIgnoreCase('Case') && (f.startsWithIgnoreCase('Task.') || f.startsWithIgnoreCase('Tasks.'))) {
                    taskFields.add(f.substringAfter('.'));
                } else {
                    selectFields.add(f);
                }
            }
            
            if (objectName.equalsIgnoreCase('Case')) {
                selectFields.add('DMT_Related_feature_name__c');
            }
            
            if (selectFields.isEmpty()) selectFields.add('Id');
            
            String fieldsList = String.join(new List<String>(selectFields), ', ');
            
            if (!taskFields.isEmpty()) {
                fieldsList += ', (SELECT ' + String.join(new List<String>(taskFields), ', ') + ' FROM Tasks ORDER BY CreatedDate DESC LIMIT 1)';
            }
            
            String query = 'SELECT ' + fieldsList + ' FROM ' + objectName;
            if (String.isNotBlank(whereClause)) query += ' WHERE ' + whereClause;
            return query;
        }
        
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
    
    private class FieldMapper {
        private Map<String, Object> config;
        public Map<String, List<Map<String, Object>>> queryResults;
        private Map<String, Object> additionalParams;
        
        public FieldMapper(Map<String, Object> config, Map<String, List<Map<String, Object>>> queryResults, Map<String, Object> additionalParams) {
            this.config = config;
            this.queryResults = queryResults;
            this.additionalParams = additionalParams;
        }
        
        public Map<String, Object> getMapperResult() {
            Map<String, Object> result = new Map<String, Object>();
            mapConfigToResult(config, result, queryResults);
            return result;
        }
        
        private void mapConfigToResult(
            Map<String, Object> currentConfig, 
            Map<String, Object> result, 
            Map<String, List<Map<String, Object>>> allResults
        ) {
            for (String key : currentConfig.keySet()) {
                if (key == '_condition' || key == '_value' || key == '_list' || key == '_filter' || key == '_includeOriginal' || key == '_choose') continue;

                Object value = currentConfig.get(key);
                
                if (value instanceof String) {
                    String strValue = (String) value;
                    if (strValue.startsWith('%') && strValue.endsWith('%')) {
                        result.put(key, resolveFieldValue(strValue, null, null, allResults));
                    } else {
                        result.put(key, value);
                    }
                } else if (value instanceof Map<String, Object>) {
                    Map<String, Object> nestedConfig = (Map<String, Object>) value;

                    if (nestedConfig.containsKey('_choose')) {
                        Object chooseVal = nestedConfig.get('_choose');
                        if (chooseVal instanceof List<Object>) {
                            Object chosenValue = evaluateChooseDirective((List<Object>)chooseVal, null, null, allResults);
                            if (chosenValue != null) {
                                result.put(key, chosenValue);
                            }
                        }
                        continue;
                    }

                    if (nestedConfig.containsKey('_condition')) {
                        ConditionEvaluator evaluator = new ConditionEvaluator(this, null, null);
                        if (!evaluator.evaluate(nestedConfig.get('_condition'))) continue;

                        if (nestedConfig.containsKey('_value')) {
                            Object scalarValue = nestedConfig.get('_value');
                            if (scalarValue instanceof String) {
                                String strScalar = (String) scalarValue;
                                if (strScalar.startsWith('%') && strScalar.endsWith('%')) {
                                    scalarValue = resolveFieldValue(strScalar, null, null, allResults);
                                }
                            }
                            result.put(key, scalarValue);
                            continue;
                        }

                        Map<String, Object> cleanedConfig = new Map<String, Object>(nestedConfig);
                        cleanedConfig.remove('_condition');
                        nestedConfig = cleanedConfig;
                    }

                    String listObjectName = parseListObjectName(nestedConfig);
                    if (String.isNotBlank(listObjectName)) {
                        Map<String, Object> listItemConfig = new Map<String, Object>(nestedConfig);
                        listItemConfig.remove('_list');

                        Object filterConfig = null;
                        if (listItemConfig.containsKey('_filter')) {
                            filterConfig = listItemConfig.get('_filter');
                            listItemConfig.remove('_filter');
                        }
                        
                        Boolean includeOriginal = false;
                        if (listItemConfig.containsKey('_includeOriginal')) {
                            includeOriginal = (Boolean) listItemConfig.get('_includeOriginal');
                            listItemConfig.remove('_includeOriginal');
                        }

                        List<Map<String, Object>> listData = getListFromResults(allResults, listObjectName);
                        List<Map<String, Object>> mappedList = new List<Map<String, Object>>();
                        if (listData != null) {
                            for (Map<String, Object> rowData : listData) {
                                if (filterConfig != null) {
                                    ConditionEvaluator filterEvaluator = new ConditionEvaluator(this, rowData, listObjectName);
                                    if (!filterEvaluator.evaluate(filterConfig)) continue;
                                }

                                Map<String, Object> mappedItem = new Map<String, Object>();
                                if (includeOriginal && rowData != null) {
                                    mappedItem.putAll(rowData);
                                }
                                mapNestedConfig(listItemConfig, mappedItem, rowData, allResults, listObjectName);
                                mappedList.add(mappedItem);
                            }
                        }
                        result.put(key, mappedList);
                    } else if (isLegacyListConfig(nestedConfig, getMapListCaseInsensitive(allResults, 'OpportunityLineItem'))) {
                        Map<String, Object> cleanItemMap = new Map<String, Object>(nestedConfig);
                        Object filterConfig = cleanItemMap.get('_filter');
                        cleanItemMap.remove('_filter');

                        Boolean includeOriginal = false;
                        if (cleanItemMap.containsKey('_includeOriginal')) {
                            includeOriginal = (Boolean) cleanItemMap.get('_includeOriginal');
                            cleanItemMap.remove('_includeOriginal');
                        }

                        List<Map<String, Object>> listData = getMapListCaseInsensitive(allResults, 'OpportunityLineItem');
                        List<Map<String, Object>> mappedList = new List<Map<String, Object>>();
                        if (listData != null) {
                            for (Map<String, Object> rowData : listData) {
                                if (filterConfig != null) {
                                    ConditionEvaluator filterEvaluator = new ConditionEvaluator(this, rowData, 'OpportunityLineItem');
                                    if (!filterEvaluator.evaluate(filterConfig)) continue;
                                }

                                Map<String, Object> mappedItem = new Map<String, Object>();
                                if (includeOriginal && rowData != null) {
                                    mappedItem.putAll(rowData);
                                }
                                mapNestedConfig(cleanItemMap, mappedItem, rowData, allResults, 'OpportunityLineItem');
                                mappedList.add(mappedItem);
                            }
                        }
                        result.put(key, mappedList);
                    } else {
                        List<Map<String, Object>> oppData = getMapListCaseInsensitive(allResults, 'Opportunity');
                        Map<String, Object> nestedResult = new Map<String, Object>();
                        mapNestedConfig(
                            nestedConfig,
                            nestedResult,
                            oppData != null && !oppData.isEmpty() ? oppData.get(0) : null,
                            allResults,
                            'Opportunity'
                        );
                        result.put(key, nestedResult);
                    }
                } else if (value instanceof List<Object>) {
                    result.put(key, processListConfig((List<Object>) value, null, null, allResults));
                } else {
                    result.put(key, value);
                }
            }
        }

        private void mapNestedConfig(
            Map<String, Object> nestedConfig,
            Map<String, Object> result,
            Map<String, Object> sourceData,
            Map<String, List<Map<String, Object>>> allResults,
            String sourceObjectName
        ) {
            for (String key : nestedConfig.keySet()) {
                if (key == '_condition' || key == '_value' || key == '_list' || key == '_filter' || key == '_includeOriginal' || key == '_choose') continue;

                Object value = nestedConfig.get(key);
                
                if (value instanceof String) {
                    String strValue = (String) value;
                    if (strValue.startsWith('%') && strValue.endsWith('%')) {
                        result.put(key, resolveFieldValue(strValue, sourceData, sourceObjectName, allResults));
                    } else {
                        result.put(key, value);
                    }
                } else if (value instanceof Map<String, Object>) {
                    Map<String, Object> innerNested = (Map<String, Object>) value;

                    if (innerNested.containsKey('_choose')) {
                        Object chooseVal = innerNested.get('_choose');
                        if (chooseVal instanceof List<Object>) {
                            Object chosenValue = evaluateChooseDirective((List<Object>)chooseVal, sourceData, sourceObjectName, allResults);
                            if (chosenValue != null) {
                                result.put(key, chosenValue);
                            }
                        }
                        continue;
                    }

                    if (innerNested.containsKey('_condition')) {
                        ConditionEvaluator evaluator = new ConditionEvaluator(this, sourceData, sourceObjectName);
                        
                        if (!evaluator.evaluate(innerNested.get('_condition'))) continue;

                        if (innerNested.containsKey('_value')) {
                            Object scalarValue = innerNested.get('_value');
                            if (scalarValue instanceof String) {
                                String strScalar = (String) scalarValue;
                                if (strScalar.startsWith('%') && strScalar.endsWith('%')) {
                                    scalarValue = resolveFieldValue(strScalar, sourceData, sourceObjectName, allResults);
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
                    mapNestedConfig(innerNested, innerResult, sourceData, allResults, sourceObjectName);
                    result.put(key, innerResult);
                } else if (value instanceof List<Object>) {
                    result.put(key, processListConfig((List<Object>) value, sourceData, sourceObjectName, allResults));
                } else {
                    result.put(key, value);
                }
            }
        }

        private Object evaluateChooseDirective(
            List<Object> choices,
            Map<String, Object> sourceData,
            String sourceObjectName,
            Map<String, List<Map<String, Object>>> allResults
        ) {
            for (Object choiceObj : choices) {
                if (choiceObj instanceof Map<String, Object>) {
                    Map<String, Object> choiceMap = (Map<String, Object>) choiceObj;
                    
                    ConditionEvaluator evaluator = new ConditionEvaluator(this, sourceData, sourceObjectName);
                    if (!choiceMap.containsKey('_condition') || evaluator.evaluate(choiceMap.get('_condition'))) {
                        
                        if (choiceMap.containsKey('_value')) {
                            Object scalarValue = choiceMap.get('_value');
                            if (scalarValue instanceof String) {
                                String strScalar = (String) scalarValue;
                                if (strScalar.startsWith('%') && strScalar.endsWith('%')) {
                                    scalarValue = resolveFieldValue(strScalar, sourceData, sourceObjectName, allResults);
                                }
                            }
                            return scalarValue;
                        } else {
                            Map<String, Object> cleanedChoice = new Map<String, Object>(choiceMap);
                            cleanedChoice.remove('_condition');
                            Map<String, Object> innerResult = new Map<String, Object>();
                            mapNestedConfig(cleanedChoice, innerResult, sourceData, allResults, sourceObjectName);
                            return innerResult;
                        }
                    }
                }
            }
            return null;
        }

        private List<Object> processListConfig(
            List<Object> configList,
            Map<String, Object> sourceData,
            String sourceObjectName,
            Map<String, List<Map<String, Object>>> allResults
        ) {
            List<Object> resultList = new List<Object>();
            for (Object item : configList) {
                if (item instanceof Map<String, Object>) {
                    Map<String, Object> itemMap = (Map<String, Object>) item;
                    
                    if (itemMap.containsKey('_condition')) {
                        ConditionEvaluator evaluator = new ConditionEvaluator(this, sourceData, sourceObjectName);
                        
                        if (!evaluator.evaluate(itemMap.get('_condition'))) continue;
                        
                        if (itemMap.containsKey('_value')) {
                            Object scalar = itemMap.get('_value');
                            if (scalar instanceof String && ((String)scalar).startsWith('%')) {
                                scalar = resolveFieldValue((String)scalar, sourceData, sourceObjectName, allResults);
                            }
                            resultList.add(scalar);
                            continue;
                        }
                        Map<String, Object> cleaned = new Map<String, Object>(itemMap);
                        cleaned.remove('_condition');
                        itemMap = cleaned;
                    }
                    
                    String listObj = parseListObjectName(itemMap);
                    if (String.isNotBlank(listObj)) {
                        Map<String, Object> listItemConfig = new Map<String, Object>(itemMap);
                        listItemConfig.remove('_list');
                        
                        Object filterConfig = null;
                        if (listItemConfig.containsKey('_filter')) {
                            filterConfig = listItemConfig.get('_filter');
                            listItemConfig.remove('_filter');
                        }
                        
                        Boolean includeOriginal = false;
                        if (listItemConfig.containsKey('_includeOriginal')) {
                            includeOriginal = (Boolean) listItemConfig.get('_includeOriginal');
                            listItemConfig.remove('_includeOriginal');
                        }

                        List<Map<String, Object>> listData = getListFromResults(allResults, listObj);
                        if (listData != null) {
                            for (Map<String, Object> rowData : listData) {
                                if (filterConfig != null) {
                                    ConditionEvaluator filterEvaluator = new ConditionEvaluator(this, rowData, listObj);
                                    if (!filterEvaluator.evaluate(filterConfig)) continue;
                                }

                                Map<String, Object> mappedItem = new Map<String, Object>();
                                if (includeOriginal && rowData != null) {
                                    mappedItem.putAll(rowData);
                                }
                                mapNestedConfig(listItemConfig, mappedItem, rowData, allResults, listObj);
                                resultList.add(mappedItem);
                            }
                        }
                    } else if (isLegacyListConfig(itemMap, getMapListCaseInsensitive(allResults, 'OpportunityLineItem'))) {
                        Map<String, Object> cleanItemMap = new Map<String, Object>(itemMap);
                        Object filterConfig = cleanItemMap.get('_filter');
                        cleanItemMap.remove('_filter');

                        Boolean includeOriginal = false;
                        if (cleanItemMap.containsKey('_includeOriginal')) {
                            includeOriginal = (Boolean) cleanItemMap.get('_includeOriginal');
                            cleanItemMap.remove('_includeOriginal');
                        }

                        List<Map<String, Object>> listData = getMapListCaseInsensitive(allResults, 'OpportunityLineItem');
                        if (listData != null) {
                            for (Map<String, Object> rowData : listData) {
                                if (filterConfig != null) {
                                    ConditionEvaluator filterEvaluator = new ConditionEvaluator(this, rowData, 'OpportunityLineItem');
                                    if (!filterEvaluator.evaluate(filterConfig)) continue;
                                }

                                Map<String, Object> mappedItem = new Map<String, Object>();
                                if (includeOriginal && rowData != null) {
                                    mappedItem.putAll(rowData);
                                }
                                mapNestedConfig(cleanItemMap, mappedItem, rowData, allResults, 'OpportunityLineItem');
                                resultList.add(mappedItem);
                            }
                        }
                    } else {
                        Map<String, Object> mappedItem = new Map<String, Object>();
                        mapNestedConfig(itemMap, mappedItem, sourceData, allResults, sourceObjectName);
                        resultList.add(mappedItem);
                    }
                } else if (item instanceof List<Object>) {
                    resultList.add(processListConfig((List<Object>) item, sourceData, sourceObjectName, allResults));
                } else if (item instanceof String) {
                    String strItem = (String) item;
                    if (strItem.startsWith('%') && strItem.endsWith('%')) {
                        resultList.add(resolveFieldValue(strItem, sourceData, sourceObjectName, allResults));
                    } else {
                        resultList.add(item);
                    }
                } else {
                    resultList.add(item);
                }
            }
            return resultList;
        }

        private Boolean isLegacyListConfig(Map<String, Object> nestedConfig, List<Map<String, Object>> oppLineItemData) {
            if (oppLineItemData == null || oppLineItemData.isEmpty()) return false;
            for (String key : nestedConfig.keySet()) {
                Object value = nestedConfig.get(key);
                if (value instanceof String) {
                    String strValue = (String) value;
                    if (strValue.contains('OpportunityLineItem')) return true;
                }
            }
            return false;
        }

        private String parseListObjectName(Map<String, Object> nestedConfig) {
            if (!nestedConfig.containsKey('_list')) return null;

            Object listDirective = nestedConfig.get('_list');
            if (!(listDirective instanceof String)) {
                throw new DynamicMapperException('La directiva _list debe ser String con formato LIST(Path).');
            }

            String marker = ((String) listDirective).trim();
            if (!marker.startsWith('LIST(') || !marker.endsWith(')')) {
                throw new DynamicMapperException('Formato _list inválido: ' + marker + '. Usa LIST(Path).');
            }

            String objectName = marker.substring(5, marker.length() - 1).trim();
            if (String.isBlank(objectName)) {
                throw new DynamicMapperException('La directiva _list no contiene Path: ' + marker);
            }
            return objectName;
        }
        
        public Object resolveFieldValue(
            String fieldReference,
            Map<String, Object> sourceData,
            String sourceObjectName,
            Map<String, List<Map<String, Object>>> allResults
        ) {
            String originalCleaned = fieldReference.replace('%', '');
            Boolean isSemaforo = false;
            
            if (originalCleaned.startsWithIgnoreCase('SEMAFORO(') && originalCleaned.endsWith(')')) {
                isSemaforo = true;
                originalCleaned = originalCleaned.substring(9, originalCleaned.length() - 1).trim();
            }

            Object resolvedValue = null;

            if (originalCleaned.contains('[')) {
                String objectName = originalCleaned.substringBefore('[').trim();
                String contextPath = originalCleaned.substringBetween('[', ']').trim();
                String fieldPath = originalCleaned.substringAfter('].').trim();

                Object correlationObj = resolveSimplePath(contextPath, sourceData, sourceObjectName, allResults);
                String correlationValue = correlationObj != null ? String.valueOf(correlationObj).trim() : '';

                if (String.isNotBlank(correlationValue)) {
                    List<Map<String, Object>> objectData = getMapListCaseInsensitive(allResults, objectName);
                    if (objectData != null) {
                        for (Map<String, Object> row : objectData) {
                            
                            String correlationField = objectName.equalsIgnoreCase('Case') ? 'DMT_Related_feature_name__c' : 'Name';
                            Object rowCorrelationObj = getMapValueCaseInsensitive(row, correlationField);
                            String rowCorrelationStr = rowCorrelationObj != null ? String.valueOf(rowCorrelationObj).trim() : '';
                            
                            if (String.isNotBlank(rowCorrelationStr) && rowCorrelationStr.equalsIgnoreCase(correlationValue)) {
                                if (objectName.equalsIgnoreCase('Case') && (fieldPath.startsWithIgnoreCase('Task.') || fieldPath.startsWithIgnoreCase('Tasks.'))) {
                                    String taskField = fieldPath.substringAfter('.');
                                    Object tasksObj = getMapValueCaseInsensitive(row, 'Tasks');
                                    
                                    if (tasksObj != null) {
                                        if (tasksObj instanceof List<SObject>) {
                                            List<SObject> records = (List<SObject>) tasksObj;
                                            if (!records.isEmpty()) {
                                                resolvedValue = extractFromObject(records[0].getPopulatedFieldsAsMap(), taskField.split('\\.'), 0);
                                            }
                                        } else if (tasksObj instanceof List<Object>) {
                                            List<Object> records = (List<Object>) tasksObj;
                                            if (!records.isEmpty()) {
                                                if (records[0] instanceof Map<String, Object>) {
                                                    resolvedValue = extractFromObject((Map<String, Object>)records[0], taskField.split('\\.'), 0);
                                                } else if (records[0] instanceof SObject) {
                                                    resolvedValue = extractFromObject(((SObject)records[0]).getPopulatedFieldsAsMap(), taskField.split('\\.'), 0);
                                                }
                                            }
                                        } else if (tasksObj instanceof Map<String, Object>) {
                                            Map<String, Object> tasksMap = (Map<String, Object>) tasksObj;
                                            if (tasksMap.containsKey('records')) {
                                                List<Object> records = (List<Object>) tasksMap.get('records');
                                                if (records != null && !records.isEmpty()) {
                                                    Object firstRec = records[0];
                                                    if (firstRec instanceof Map<String, Object>) {
                                                        resolvedValue = extractFromObject((Map<String, Object>)firstRec, taskField.split('\\.'), 0);
                                                    } else if (firstRec instanceof SObject) {
                                                        resolvedValue = extractFromObject(((SObject)firstRec).getPopulatedFieldsAsMap(), taskField.split('\\.'), 0);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    resolvedValue = extractFromObject(row, fieldPath.split('\\.'), 0);
                                }
                                break; 
                            }
                        }
                    }
                }
            } else {
                resolvedValue = resolveSimplePath(originalCleaned, sourceData, sourceObjectName, allResults);
            }

            if (isSemaforo) {
                String val = resolvedValue != null ? String.valueOf(resolvedValue).trim().toLowerCase() : '';
                if (val == 'yes') return 'GREEN';
                if (val == 'no') return 'RED';
                return 'WHITE';
            }

            return resolvedValue;
        }

        private Object resolveSimplePath(String path, Map<String, Object> sourceData, String sourceObjectName, Map<String, List<Map<String, Object>>> allResults) {
            List<String> parts = path.split('\\.');
            if (parts.size() < 1) return null;

            if (sourceData != null && String.isNotBlank(sourceObjectName) && path.startsWithIgnoreCase(sourceObjectName + '.')) {
                String remainingPath = path.substring(sourceObjectName.length() + 1);
                List<String> remainingParts = remainingPath.split('\\.');
                if (remainingParts.size() == 0) return sourceData;
                return extractFromObject(sourceData, remainingParts, 0);
            }

            String objectName = parts[0].trim();
            
            if (this.additionalParams != null) {
                Object paramValue = getMapValueCaseInsensitive(this.additionalParams, objectName);
                if (paramValue != null) {
                    if (parts.size() == 1) return paramValue;
                    return extractFromObject(paramValue, parts, 1);
                }
            }
            
            if (parts.size() < 2) return null;
            
            List<Map<String, Object>> objectData = getMapListCaseInsensitive(allResults, objectName);
            if (objectData == null || objectData.isEmpty()) {
                return null;
            }
            
            return extractFromObject(objectData.get(0), parts, 1);
        }
    }
    
    private class ConditionEvaluator {
        private FieldMapper mapper;
        private Map<String, Object> rowData;
        private String sourceObjectName;

        public ConditionEvaluator(FieldMapper mapper, Map<String, Object> rowData, String sourceObjectName) {
            this.mapper = mapper;
            this.rowData = rowData;
            this.sourceObjectName = sourceObjectName;
        }

        public Boolean evaluate(Object conditionNode) {
            if (conditionNode == null) return true;
            if (!(conditionNode instanceof Map<String, Object>)) return true;

            Map<String, Object> cond = (Map<String, Object>) conditionNode;

            if (cond.containsKey('and')) {
                for (Object sub : (List<Object>) cond.get('and')) {
                    if (!evaluate(sub)) return false;
                }
                return true;
            }
            if (cond.containsKey('or')) {
                for (Object sub : (List<Object>) cond.get('or')) {
                    if (evaluate(sub)) return true;
                }
                return false;
            }
            if (cond.containsKey('not')) {
                return !evaluate(cond.get('not'));
            }

            if (cond.containsKey('field') && cond.containsKey('op')) {
                String fieldRef  = (String) cond.get('field');
                String op        = (String) cond.get('op');
                String expected  = cond.containsKey('value') ? String.valueOf(cond.get('value')) : null;
                Object rawActual = resolveFieldRef(fieldRef);
                String actual    = rawActual != null ? String.valueOf(rawActual) : null;
                return applyOp(actual, op, expected);
            }

            return true; 
        }

        private Object resolveFieldRef(String fieldRef) {
            if (!fieldRef.startsWith('%') || !fieldRef.endsWith('%')) {
                return fieldRef; 
            }
            return mapper.resolveFieldValue(fieldRef, rowData, sourceObjectName, mapper.queryResults);
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

    private class ResponseMapper {
        private Map<String, Object> templateMap;
        private Map<String, Object> responseMap;
        private String opportunityId;
        private Map<String, Map<String, Object>> fieldUpdates;

        public ResponseMapper(Map<String, Object> templateMap, Map<String, Object> responseMap, String opportunityId) {
            this.templateMap = templateMap;
            this.responseMap = responseMap;
            this.opportunityId = opportunityId;
            this.fieldUpdates = new Map<String, Map<String, Object>>();
        }

        public void processAndUpdate() {
            extractValuesRecursive(templateMap, responseMap);
            if (fieldUpdates.isEmpty()) return;
            performUpdates();
        }

        private void extractValuesRecursive(Object template, Object response) {
            if (template instanceof Map<String, Object> && response instanceof Map<String, Object>) {
                Map<String, Object> tplMap = (Map<String, Object>) template;
                Map<String, Object> resMap = (Map<String, Object>) response;

                for (String key : tplMap.keySet()) {
                    Object tplValue = tplMap.get(key);
                    Object resValue = resMap.get(key);

                    if (tplValue instanceof String) {
                        String placeholder = (String) tplValue;
                        if (placeholder.startsWith('%') && placeholder.endsWith('%') && resValue != null) {
                            registerFieldUpdate(placeholder, resValue);
                        }
                    } else if (tplValue instanceof Map<String, Object>) {
                        if (resValue instanceof Map<String, Object>) {
                            extractValuesRecursive(tplValue, resValue);
                        }
                    } else if (tplValue instanceof List<Object>) {
                        if (resValue instanceof List<Object>) {
                            extractValuesFromList((List<Object>) tplValue, (List<Object>) resValue);
                        }
                    }
                }
            }
        }

        private void extractValuesFromList(List<Object> templateList, List<Object> responseList) {
            if (templateList.isEmpty()) return;
            Object templateItem = templateList[0];
            for (Object responseItem : responseList) {
                extractValuesRecursive(templateItem, responseItem);
            }
        }

        private void registerFieldUpdate(String placeholder, Object value) {
            String cleaned = placeholder.replace('%', '');
            List<String> parts = cleaned.split('\\.');
            if (parts.size() < 2) return;

            String objectName = parts[0].trim();
            String fieldName = parts[parts.size() - 1].trim();

            if (!fieldUpdates.containsKey(objectName)) {
                fieldUpdates.put(objectName, new Map<String, Object>());
            }
            fieldUpdates.get(objectName).put(fieldName, value);
        }

        private void performUpdates() {
            Map<String, String> filterFields = new Map<String, String>{
                'Opportunity'               => 'Id',
                'OpportunityLineItem'       => 'OpportunityId',
                'DMT_Opportunity_Client__c' => 'DMT_MDE_Opportunity__c'
            };

            for (String objectName : fieldUpdates.keySet()) {
                Map<String, Object> fields = fieldUpdates.get(objectName);
                String filterField = filterFields.get(objectName);

                if (filterField == null) continue;

                String fieldsList = String.join(new List<String>(fields.keySet()), ', ');
                String query = 'SELECT Id, ' + fieldsList + ' FROM ' + objectName +
                               ' WHERE ' + filterField + ' = \'' + String.escapeSingleQuotes(opportunityId) + '\'';

                List<SObject> records = Database.query(query);
                if (records.isEmpty()) continue;

                for (SObject record : records) {
                    for (String fieldName : fields.keySet()) {
                        record.put(fieldName, fields.get(fieldName));
                    }
                }
                update records;
            }
        }
    }

    public class DynamicMapperException extends Exception {}
}