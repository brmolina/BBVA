public with sharing class DMT_HighlightPanelController {
    
    @AuraEnabled(cacheable=false)
    public static HighlightPanelConfig getHighlightConfig(String objectApiName, String recordId) {
        HighlightPanelConfig config = new HighlightPanelConfig();
        
        try {
            System.debug('=== INICIANDO getHighlightConfig ===');
            
            if (String.isBlank(objectApiName) || String.isBlank(recordId)) {
                throw new AuraHandledException('objectApiName y recordId son requeridos');
            }
            
            // 1. Obtener Record Type del registro
            Map<String, Object> recordTypeInfo = getRecordTypeInfo(objectApiName, recordId);
            System.debug('recordTypeInfo: ' + JSON.serialize(recordTypeInfo));
            
            String recordTypeApiName = (String) recordTypeInfo.get('recordTypeApiName');
            
            // 2. Buscar configuración del Custom Metadata
            DMT_HighlightPanel_Config__mdt metadataConfig = getMetadataConfig(objectApiName, recordTypeApiName);
            System.debug('metadataConfig encontrado: ' + (metadataConfig != null));
            
            if (metadataConfig != null) {
                // 3. Parsear la configuración del metadata
                config = parseMetadataConfig(metadataConfig);
                config.recordTypeSpecific = metadataConfig.Record_Type_API_Name__c != null;
                config.recordTypeApiName = metadataConfig.Record_Type_API_Name__c;
                config.recordTypeId = (String) recordTypeInfo.get('recordTypeId');
            } else {
                // 4. Configuración por defecto
                config = getDefaultConfig(objectApiName);
                config.recordTypeSpecific = false;
            }
            
            // 5. Obtener valores de los campos del registro
            Map<String, Object> fieldValues = getRecordFieldValues(config, objectApiName, recordId);
            
            // 6. Reemplazar placeholders en acciones {NombreCampo} → valor real
            replaceActionPlaceholders(config, fieldValues);
            
            // 7. Aplicar condiciones de visibilidad y editabilidad
            applyConditions(config, fieldValues);
            
            // 8. Información básica del registro
            config.recordInfo = new RecordInfo();
            config.recordInfo.recordId = recordId;
            config.recordInfo.objectApiName = objectApiName;
            String recordName = (String) fieldValues.get('Name');
            config.recordInfo.name = recordName;
            config.recordInfo.recordTypeId = (String) fieldValues.get('RecordTypeId');
            
            Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            config.recordInfo.label = describe.getLabel();
            
            System.debug('=== FINALIZANDO getHighlightConfig ===');
            System.debug('Campos visibles: ' + config.visibleFields?.size());
            System.debug('Acciones principales visibles: ' + config.visiblePrimaryActions?.size());
            
            return config;
            
        } catch (Exception e) {
            System.debug('ERROR en getHighlightConfig: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading configuration: ' + e.getMessage());
        }
    }
    
    // ===== MÉTODOS AUXILIARES =====
    
    public static Map<String, Object> getRecordTypeInfo(String objectApiName, String recordId) {
        Map<String, Object> result = new Map<String, Object>{
            'recordTypeId' => null, 'recordTypeApiName' => null
        };
        
        try {
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectApiName)?.getDescribe();
            if (objectDescribe == null || objectDescribe.getRecordTypeInfosByName().size() == 0) {
                return result;
            }
            
            String query = 'SELECT Id, RecordTypeId FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
            List<SObject> records = Database.query(query);
            
            if (!records.isEmpty() && records[0].get('RecordTypeId') != null) {
                String rtId = (String) records[0].get('RecordTypeId');
                result.put('recordTypeId', rtId);
                
                if (String.isNotBlank(rtId)) {
                    RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE Id = :rtId LIMIT 1];
                    if (rt != null) {
                        result.put('recordTypeApiName', rt.DeveloperName);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error en getRecordTypeInfo: ' + e.getMessage());
        }
        
        return result;
    }
    
    public static DMT_HighlightPanel_Config__mdt getMetadataConfig(String objectApiName, String recordTypeApiName) {
        List<DMT_HighlightPanel_Config__mdt> configs = new List<DMT_HighlightPanel_Config__mdt>();
        
        // 1. Primero buscar configuración específica para el Record Type
        if (String.isNotBlank(recordTypeApiName)) {
            configs = [
                SELECT Id, DeveloperName, MasterLabel, 
                       Object_API_Name__c, Record_Type_API_Name__c,
                       Icon_Type__c, Icon_Name__c, Icon_Size__c,
                       Static_Resource_Name__c, Static_Resource_Path__c,
                       Custom_Icon_URL__c,
                       Fields_Configuration__c,
                       Primary_Actions_JSON__c,
                       Menu_Actions_JSON__c,
                       Metadata_Config__c
                FROM DMT_HighlightPanel_Config__mdt 
                WHERE Object_API_Name__c = :objectApiName 
                AND Record_Type_API_Name__c = :recordTypeApiName
                LIMIT 1
            ];
            
            if (!configs.isEmpty()) return configs[0];
        }
        
        // 2. Si no hay configuración específica, buscar configuración general del objeto
        configs = [
            SELECT Id, DeveloperName, MasterLabel, 
                   Object_API_Name__c, Record_Type_API_Name__c,
                   Icon_Type__c, Icon_Name__c, Icon_Size__c,
                   Static_Resource_Name__c, Static_Resource_Path__c,
                   Custom_Icon_URL__c,
                   Fields_Configuration__c,
                   Primary_Actions_JSON__c,
                   Menu_Actions_JSON__c,
                   Metadata_Config__c
            FROM DMT_HighlightPanel_Config__mdt 
            WHERE Object_API_Name__c = :objectApiName 
            AND (Record_Type_API_Name__c = null OR Record_Type_API_Name__c = '')
            LIMIT 1
        ];
        
        return configs.isEmpty() ? null : configs[0];
    }
    
    public static HighlightPanelConfig parseMetadataConfig(DMT_HighlightPanel_Config__mdt metadata) {
        HighlightPanelConfig config = new HighlightPanelConfig();
        
        try {
            // 1. Configuración del icono
            config.iconConfig = new IconConfig();
            config.iconConfig.type = String.isNotBlank(metadata.Icon_Type__c) ? metadata.Icon_Type__c : 'standard';
            config.iconConfig.name = metadata.Icon_Name__c;
            config.iconConfig.size = String.isNotBlank(metadata.Icon_Size__c) ? metadata.Icon_Size__c : 'medium';
            
            if (metadata.Icon_Type__c == 'staticresource' && String.isNotBlank(metadata.Static_Resource_Name__c)) {
                config.iconConfig.staticResource = new StaticResourceConfig();
                config.iconConfig.staticResource.resourceName = metadata.Static_Resource_Name__c;
                config.iconConfig.staticResource.iconPath = metadata.Static_Resource_Path__c;
            } else if (metadata.Icon_Type__c == 'custom' && String.isNotBlank(metadata.Custom_Icon_URL__c)) {
                config.iconConfig.customIcon = new CustomIconConfig();
                config.iconConfig.customIcon.src = metadata.Custom_Icon_URL__c;
            }
            
            // 2. Parsear campos desde JSON
            config.fieldsConfig = parseFieldConfigs(metadata.Fields_Configuration__c);
            
            // 3. Parsear acciones principales
            config.primaryActions = parseActionConfigs(metadata.Primary_Actions_JSON__c);
            
            // 4. Parsear acciones del menú
            config.menuActions = parseActionConfigs(metadata.Menu_Actions_JSON__c);
            
            // 5. Parsear metadata adicional
            if (String.isNotBlank(metadata.Metadata_Config__c)) {
                try {
                    config.metadata = (MetadataConfig) JSON.deserialize(metadata.Metadata_Config__c, MetadataConfig.class);
                } catch (Exception e) {
                    config.metadata = new MetadataConfig();
                }
            } else {
                config.metadata = new MetadataConfig();
            }
            
        } catch (Exception e) {
            System.debug('Error en parseMetadataConfig: ' + e.getMessage());
            throw e;
        }
        
        return config;
    }
    
    public static List<FieldConfig> parseFieldConfigs(String jsonString) {
        if (String.isBlank(jsonString)) return new List<FieldConfig>();
        
        List<FieldConfig> result = new List<FieldConfig>();
        
        try {
            List<Object> rawList = (List<Object>) JSON.deserializeUntyped(jsonString);
            
            for (Object rawObj : rawList) {
                Map<String, Object> fieldMap = (Map<String, Object>) rawObj;
                FieldConfig field = new FieldConfig();
                
                // Propiedades básicas
                field.type = (String) fieldMap.get('type');
                field.label = (String) fieldMap.get('label');
                field.value = (String) fieldMap.get('value');
                field.fieldApiName = (String) fieldMap.get('fieldApiName');
                field.isEditable = fieldMap.get('isEditable') != null ? (Boolean) fieldMap.get('isEditable') : false;
                field.isVisible = fieldMap.get('isVisible') != null ? (Boolean) fieldMap.get('isVisible') : true;
                field.badgeVariant = (String) fieldMap.get('badgeVariant');
                
                // Parsear icono si existe
                if (fieldMap.get('icon') != null) {
                    Map<String, Object> iconMap = (Map<String, Object>) fieldMap.get('icon');
                    field.icon = new FieldIcon();
                    field.icon.type = (String) iconMap.get('type');
                    field.icon.name = (String) iconMap.get('name');
                    field.icon.position = (String) iconMap.get('position');
                }
                
                // Parsear acción si existe
                if (fieldMap.get('action') != null) {
                    Map<String, Object> actionMap = (Map<String, Object>) fieldMap.get('action');
                    field.action = new FieldAction();
                    field.action.type = (String) actionMap.get('type');
                    field.action.name = (String) actionMap.get('name');
                    field.action.iconName = (String) actionMap.get('iconName');
                    
                    if (actionMap.get('params') != null) {
                        field.action.params = (Map<String, Object>) actionMap.get('params');
                    }
                }
                
                // Parsear condición de visibilidad si existe
                if (fieldMap.get('visibilityCondition') != null) {
                    Map<String, Object> condMap = (Map<String, Object>) fieldMap.get('visibilityCondition');
                    field.visibilityCondition = parseConditionConfig(condMap);
                }
                
                // Parsear condición de editabilidad si existe
                if (fieldMap.get('editabilityCondition') != null) {
                    Map<String, Object> condMap = (Map<String, Object>) fieldMap.get('editabilityCondition');
                    field.editabilityCondition = parseConditionConfig(condMap);
                }
                
                result.add(field);
            }
            
        } catch (Exception e) {
            System.debug('Error parseFieldConfigs: ' + e.getMessage());
            throw new JSONException('Error parsing field configs: ' + e.getMessage());
        }
        
        return result;
    }
    
    public static ConditionConfig parseConditionConfig(Map<String, Object> condMap) {
        if (condMap == null) return null;
        
        ConditionConfig condition = new ConditionConfig();
        condition.fieldName = (String) condMap.get('fieldName');
        condition.operator = (String) condMap.get('operator');
        condition.value = (String) condMap.get('value');
        condition.custompermission = (String) condMap.get('custompermission');
        return condition;
    }
    
    public static List<ActionConfig> parseActionConfigs(String jsonString) {
        if (String.isBlank(jsonString)) return new List<ActionConfig>();
        
        List<ActionConfig> result = new List<ActionConfig>();
        
        try {
            List<Object> rawList = (List<Object>) JSON.deserializeUntyped(jsonString);
            
            for (Object rawObj : rawList) {
                Map<String, Object> actionMap = (Map<String, Object>) rawObj;
                ActionConfig action = new ActionConfig();
                
                // Propiedades básicas
                action.label = (String) actionMap.get('label');
                action.name = (String) actionMap.get('name');
                action.variant = (String) actionMap.get('variant');
                action.actionType = (String) actionMap.get('actionType');
                action.disabled = actionMap.get('disabled') != null ? (Boolean) actionMap.get('disabled') : false;
                
                if (actionMap.get('actionConfig') != null) {
                    action.actionConfig = (Map<String, Object>) actionMap.get('actionConfig');
                }
                
                // Parsear iconConfig si existe
                if (actionMap.get('iconConfig') != null) {
                    Map<String, Object> iconMap = (Map<String, Object>) actionMap.get('iconConfig');
                    action.iconConfig = parseIconConfig(iconMap);
                }
                
                // Parsear condiciones
                if (actionMap.get('visibilityCondition') != null) {
                    Map<String, Object> condMap = (Map<String, Object>) actionMap.get('visibilityCondition');
                    action.visibilityCondition = parseConditionConfig(condMap);
                }
                
                if (actionMap.get('enablementCondition') != null) {
                    Map<String, Object> condMap = (Map<String, Object>) actionMap.get('enablementCondition');
                    action.enablementCondition = parseConditionConfig(condMap);
                }
                
                result.add(action);
            }
            
        } catch (Exception e) {
            System.debug('Error parseActionConfigs: ' + e.getMessage());
            throw new JSONException('Error parsing action configs: ' + e.getMessage());
        }
        
        return result;
    }
    
    public static IconConfig parseIconConfig(Map<String, Object> iconMap) {
        if (iconMap == null) return null;
        
        IconConfig iconConfig = new IconConfig();
        iconConfig.type = (String) iconMap.get('type');
        iconConfig.name = (String) iconMap.get('name');
        iconConfig.size = (String) iconMap.get('size');
        iconConfig.alternativeText = (String) iconMap.get('alternativeText');
        iconConfig.color = (String) iconMap.get('color');
        iconConfig.variant = (String) iconMap.get('variant');
        
        if (iconMap.get('staticResource') != null) {
            Map<String, Object> srMap = (Map<String, Object>) iconMap.get('staticResource');
            iconConfig.staticResource = new StaticResourceConfig();
            iconConfig.staticResource.resourceName = (String) srMap.get('resourceName');
            iconConfig.staticResource.iconPath = (String) srMap.get('iconPath');
        }
        
        if (iconMap.get('customIcon') != null) {
            Map<String, Object> ciMap = (Map<String, Object>) iconMap.get('customIcon');
            iconConfig.customIcon = new CustomIconConfig();
            iconConfig.customIcon.src = (String) ciMap.get('src');
            iconConfig.customIcon.alt = (String) ciMap.get('alt');
        }
        
        return iconConfig;
    }
    
    // ===== LÓGICA PRINCIPAL =====
    
    public static Map<String, Object> getRecordFieldValues(HighlightPanelConfig config, String objectApiName, String recordId) {
        Map<String, Object> allValues = new Map<String, Object>();
        
        try {
            Set<String> allFieldApiNames = new Set<String>();
            
            // 1. Recolectar todos los campos de configuración
            if (config.fieldsConfig != null) {
                for (FieldConfig field : config.fieldsConfig) {
                    if (String.isNotBlank(field.fieldApiName)) {
                        allFieldApiNames.add(field.fieldApiName);
                    }system.debug('fields'+field.fieldApiName);
                }
            }
            
            // 2. Recolectar campos para condiciones
            if (config.fieldsConfig != null) {
                for (FieldConfig field : config.fieldsConfig) {
                    addConditionField(field.visibilityCondition, allFieldApiNames);
                    addConditionField(field.editabilityCondition, allFieldApiNames);
                }
            }
            
            // 3. Campos para acciones principales
            if (config.primaryActions != null) {
                for (ActionConfig action : config.primaryActions) {
                    addConditionField(action.visibilityCondition, allFieldApiNames);
                    addConditionField(action.enablementCondition, allFieldApiNames);
                }
            }
            
            // 4. Campos para acciones del menú
            if (config.menuActions != null) {
                for (ActionConfig action : config.menuActions) {
                    addConditionField(action.visibilityCondition, allFieldApiNames);
                    addConditionField(action.enablementCondition, allFieldApiNames);
                }
            }
            
            // 5. Campos básicos imprescindibles
            allFieldApiNames.add('Id');
            allFieldApiNames.add('Name');
            allFieldApiNames.add('RecordTypeId');
            
            System.debug('Campos totales a consultar: ' + allFieldApiNames.size());
            System.debug('Campos: ' + allFieldApiNames);
            
            if (!allFieldApiNames.isEmpty()) {
                String query = 'SELECT ' + String.join(new List<String>(allFieldApiNames), ', ') +
                             ' FROM ' + objectApiName + ' WHERE Id = :recordId FOR UPDATE';
                
                System.debug('Query ejecutada: ' + query);
                
                List<SObject> records = Database.query(query);
                if (!records.isEmpty()) {
                    SObject record = records[0];
                    System.debug('allFieldApiNames: ' + allFieldApiNames);
                    // Guardar todos los valores
                    for (String fieldName : allFieldApiNames) {
                        try {
                            // Soporta campos directos y rutas de relacion (ej: Owner.Name, Account.Name, Parent__r.Name)
                            Object value = getFieldValueFromPath(record, fieldName);
                                    allValues.put(fieldName, value);
                            System.debug('Query fieldName: value: ' + fieldName + ' : ' + value);
                            
                            // Asignar valor al campo correspondiente
                            if (config.fieldsConfig != null) {
                                for (FieldConfig field : config.fieldsConfig) {
                                    if (field.fieldApiName == fieldName && value != null) {
                                        field.value = formatFieldValue(field.type, value);
                                        field.rawValue = value;
                                    }
                                }
                            }
                            
                        } catch (Exception e) {
                            System.debug('Error obteniendo campo ' + fieldName + ': ' + e.getMessage()  + e.getlinenumber());
                            allValues.put(fieldName, null);
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error getRecordFieldValues: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
        }
        
        return allValues;
    }
    
    private static Object getFieldValueFromPath(SObject record, String fieldPath) {
        if (record == null || String.isBlank(fieldPath)) {
            return null;
        }

        // Campo directo sin relacion
        if (!fieldPath.contains('.')) {
            return record.get(fieldPath);
        }

        List<String> path = fieldPath.split('\\.');
        SObject current = record;

        // Recorre cada relacion hasta el ultimo segmento (el campo final)
        for (Integer i = 0; i < path.size() - 1; i++) {
            if (current == null) {
                return null;
            }
            current = current.getSObject(path[i]);
        }

        if (current == null) {
            return null;
        }

        return current.get(path[path.size() - 1]);
    }
    
    public static void replaceActionPlaceholders(HighlightPanelConfig config, Map<String, Object> fieldValues) {
        if (config.fieldsConfig == null) return;
        
        for (FieldConfig field : config.fieldsConfig) {
            if (field.action != null && field.action.params != null) {
                Map<String, Object> params = field.action.params;
                
                // Reemplazar placeholders del tipo {NombreCampo}
                for (String paramKey : params.keySet()) {
                    Object paramValue = params.get(paramKey);
                    if (paramValue instanceof String) {
                        String strValue = (String) paramValue;
                        
                        // Verificar si es un placeholder {Campo}
                        if (strValue.startsWith('{') && strValue.endsWith('}')) {
                            String fieldName = strValue.substring(1, strValue.length() - 1);
                            
                            if (fieldValues.containsKey(fieldName)) {
                                Object actualValue = fieldValues.get(fieldName);
                                if (actualValue != null) {
                                    // Reemplazar el placeholder con el valor real
                                    params.put(paramKey, String.valueOf(actualValue));
                                    System.debug('Reemplazado ' + strValue + ' con: ' + actualValue);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public static void addConditionField(ConditionConfig condition, Set<String> fieldSet) {
        if (condition != null && String.isNotBlank(condition.fieldName)) {
            fieldSet.add(condition.fieldName);
        }
    }
    
    public static void applyConditions(HighlightPanelConfig config, Map<String, Object> fieldValues) {
        // Aplicar condiciones a campos
        config.visibleFields = new List<FieldConfig>();
        if (config.fieldsConfig != null) {
            for (FieldConfig field : config.fieldsConfig) {
                boolean isVisible = evaluateCondition(field.visibilityCondition, fieldValues);
                if (!isVisible) continue;system.debug('field.isVisible'+field.isVisible);
                boolean isEditable = field.isEditable == true;
                if (field.editabilityCondition != null) {
                    isEditable = evaluateCondition(field.editabilityCondition, fieldValues);
                }
                field.isEditable = isEditable;
                if (field.isVisible != false) {
                    config.visibleFields.add(field);
                }
            
            }
        }
        
        // Aplicar condiciones a acciones principales
        config.visiblePrimaryActions = new List<ActionConfig>();
        if (config.primaryActions != null) {
            for (ActionConfig action : config.primaryActions) {
                boolean isVisible = evaluateCondition(action.visibilityCondition, fieldValues);
                if (!isVisible) continue;
                
                boolean isEnabled = action.disabled != true;
                if (action.enablementCondition != null) {
                    isEnabled = evaluateCondition(action.enablementCondition, fieldValues);
                }
                action.disabled = !isEnabled;
                
                config.visiblePrimaryActions.add(action);
            }
        }
        
        // Aplicar condiciones a acciones del menú
        config.visibleMenuActions = new List<ActionConfig>();
        if (config.menuActions != null) {
            for (ActionConfig action : config.menuActions) {
                boolean isVisible = evaluateCondition(action.visibilityCondition, fieldValues);
                if (!isVisible) continue;
                
                boolean isEnabled = action.disabled != true;
                if (action.enablementCondition != null) {
                    isEnabled = evaluateCondition(action.enablementCondition, fieldValues);
                }
                action.disabled = !isEnabled;
                
                config.visibleMenuActions.add(action);
            }
        }
    }
    
    public static boolean evaluateCondition(ConditionConfig condition, Map<String, Object> fieldValues) {
        if (condition == null) {
            return true; // Sin condición = siempre visible/habilitado
        }
        
        if (String.isNotBlank(condition.custompermission)) {
            String permissionName = String.valueOf(condition.custompermission).trim();
            System.debug('Evaluando custom permission: ' + permissionName);
            return FeatureManagement.checkPermission(permissionName);
        }

        if (String.isBlank(condition.fieldName)) {
            return true;
        }

        Object fieldValue = fieldValues.get(condition.fieldName);
        if (fieldValue == null) return false;
            
        String stringValue = String.valueOf(fieldValue);
        String conditionValue = condition.value;
        String operator = condition.operator != null ? condition.operator.toLowerCase() : 'equals';
            
        switch on operator {
                when 'equals', '=' {
                    return stringValue == conditionValue;
                }
                when 'not equals', '!=' {
                    return stringValue != conditionValue;
                }
                when 'contains' {
                    return stringValue.contains(conditionValue);
                }
                when 'in' {
                    return conditionValue.contains(stringValue);
                }
                when 'not in' {
                    return !conditionValue.contains(stringValue);
                }
                when 'not contains' {
                    return !stringValue.contains(conditionValue);
                }
                when 'starts with' {
                    return stringValue.startsWith(conditionValue);
                }
                when 'ends with' {
                    return stringValue.endsWith(conditionValue);
                }
                when 'greater than', '>' {
                    try {
                        Decimal numValue = Decimal.valueOf(stringValue);
                        Decimal condNumValue = Decimal.valueOf(conditionValue);
                        return numValue > condNumValue;
                    } catch (Exception e) {
                        return false;
                    }
                }
                when 'less than', '<' {
                    try {
                        Decimal numValue = Decimal.valueOf(stringValue);
                        Decimal condNumValue = Decimal.valueOf(conditionValue);
                        return numValue < condNumValue;
                    } catch (Exception e) {
                        return false;
                    }
                }
                when 'true' {
                    return Boolean.valueOf(fieldValue) == true;
                }
                when 'false' {
                    return Boolean.valueOf(fieldValue) == false;
                }
                when 'not null' {
                    return fieldValue != null;
                }
                when 'null' {
                    return fieldValue == null;
                }
                when else {
                    return stringValue == conditionValue;
                }
        }
    }
    
    public static String formatFieldValue(String type, Object value) {
        if (value == null) return '';
        
        switch on type?.toLowerCase() {
            when 'date' {
                return ((Date) value).format();
            }
            when 'datetime' {
                return ((DateTime) value).format();
            }
            when 'currency' {
                Decimal decimalValue = (Decimal) value;
                return '$' + decimalValue.format();
            }
            when 'percent' {
                Decimal decimalValue = (Decimal) value;
                return decimalValue.setScale(2) + '%';
            }
            when 'boolean' {
                Boolean boolValue = (Boolean) value;
                return boolValue ? 'Sí' : 'No';
            }
            when else {
                return String.valueOf(value);
            }
        }
    }
    
    public static HighlightPanelConfig getDefaultConfig(String objectApiName) {
        HighlightPanelConfig config = new HighlightPanelConfig();
        config.iconConfig = new IconConfig();
        config.iconConfig.type = 'standard';
        config.iconConfig.name = objectApiName.toLowerCase();
        config.iconConfig.size = 'medium';
        
        config.fieldsConfig = new List<FieldConfig>();
        config.primaryActions = new List<ActionConfig>();
        config.menuActions = new List<ActionConfig>();
        config.metadata = new MetadataConfig();
        
        return config;
    }
    
    // ===== CLASES WRAPPER =====
    
    public class HighlightPanelConfig {
        @AuraEnabled public IconConfig iconConfig;
        @AuraEnabled public RecordInfo recordInfo;
        @AuraEnabled public List<FieldConfig> fieldsConfig;
        @AuraEnabled public List<FieldConfig> visibleFields;
        @AuraEnabled public List<ActionConfig> primaryActions;
        @AuraEnabled public List<ActionConfig> visiblePrimaryActions;
        @AuraEnabled public List<ActionConfig> menuActions;
        @AuraEnabled public List<ActionConfig> visibleMenuActions;
        @AuraEnabled public MetadataConfig metadata;
        @AuraEnabled public Boolean recordTypeSpecific;
        @AuraEnabled public String recordTypeApiName;
        @AuraEnabled public String recordTypeId;
    }
    
    public class IconConfig {
        @AuraEnabled public String type;
        @AuraEnabled public String name;
        @AuraEnabled public String size;
        @AuraEnabled public String alternativeText;
        @AuraEnabled public StaticResourceConfig staticResource;
        @AuraEnabled public CustomIconConfig customIcon;
        @AuraEnabled public String color;
        @AuraEnabled public String variant;
    }
    
    public class StaticResourceConfig {
        @AuraEnabled public String resourceName;
        @AuraEnabled public String iconPath;
    }
    
    public class CustomIconConfig {
        @AuraEnabled public String src;
        @AuraEnabled public String alt;
    }
    
    public class RecordInfo {
        @AuraEnabled public String recordId;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String recordTypeId;
    }
    
    public class FieldConfig {
        @AuraEnabled public String type;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Object rawValue;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public Boolean isEditable;
        @AuraEnabled public Boolean isVisible;
        @AuraEnabled public FieldIcon icon;
        @AuraEnabled public String badgeVariant;
        @AuraEnabled public FieldAction action;
        @AuraEnabled public ConditionConfig visibilityCondition;
        @AuraEnabled public ConditionConfig editabilityCondition;
    }
    
    public class FieldIcon {
        @AuraEnabled public String type;
        @AuraEnabled public String name;
        @AuraEnabled public String position;
    }
    
    public class FieldAction {
        @AuraEnabled public String type;
        @AuraEnabled public String name;
        @AuraEnabled public String iconName;
        @AuraEnabled public Map<String, Object> params;
    }
    
    public class ActionConfig {
        @AuraEnabled public String label;
        @AuraEnabled public String name;
        @AuraEnabled public IconConfig iconConfig;
        @AuraEnabled public String variant;
        @AuraEnabled public String actionType;
        @AuraEnabled public Map<String, Object> actionConfig;
        @AuraEnabled public Boolean disabled;
        @AuraEnabled public ConditionConfig visibilityCondition;
        @AuraEnabled public ConditionConfig enablementCondition;
    }
    
    public class ConditionConfig {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String operator;
        @AuraEnabled public String value;
        @AuraEnabled public String custompermission;
    }
    
    public class MetadataConfig {
        @AuraEnabled public Boolean showIcon = true;
        @AuraEnabled public String iconPosition = 'left';
        @AuraEnabled public Boolean compactMode = false;
        @AuraEnabled public Integer maxFieldColumns = 3;
        @AuraEnabled public Map<String, Object> customSettings;
    }
}