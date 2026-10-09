public with sharing class DMT_HighlightPanelController {
    
    @AuraEnabled(cacheable=false)
    public static HighlightPanelConfig getHighlightConfig(String objectApiName, String recordId) {
        HighlightPanelConfig config = new HighlightPanelConfig();
        
        try {
            System.debug('=== STARTING getHighlightConfig ===');

            if (String.isBlank(objectApiName) || String.isBlank(recordId)) {
                throw new AuraHandledException('objectApiName y recordId son requeridos');
            }

            // 1. Get the record's Record Type
            Map<String, Object> recordTypeInfo = getRecordTypeInfo(objectApiName, recordId);
            System.debug('recordTypeInfo: ' + JSON.serialize(recordTypeInfo));

            String recordTypeApiName = (String) recordTypeInfo.get('recordTypeApiName');

            // 2. Look up the Custom Metadata configuration
            DMT_HighlightPanel_Config__mdt metadataConfig = getMetadataConfig(objectApiName, recordTypeApiName);
            System.debug('metadataConfig found: ' + (metadataConfig != null));

            if (metadataConfig != null) {
                // 3. Parse the metadata configuration
                config = parseMetadataConfig(metadataConfig);
                config.recordTypeSpecific = metadataConfig.Record_Type_API_Name__c != null;
                config.recordTypeApiName = metadataConfig.Record_Type_API_Name__c;
                config.recordTypeId = (String) recordTypeInfo.get('recordTypeId');
            } else {
                // 4. Default configuration
                config = getDefaultConfig(objectApiName);
                config.recordTypeSpecific = false;
            }

            // 5. Get the record's field values
            Map<String, Object> fieldValues = getRecordFieldValues(config, objectApiName, recordId);

            // 6. Replace placeholders in actions {FieldName} → actual value
            replaceActionPlaceholders(config, fieldValues);

            // 7. Apply visibility and editability conditions
            applyConditions(config, fieldValues);

            // 8. Basic record information
            config.recordInfo = new RecordInfo();
            config.recordInfo.recordId = recordId;
            config.recordInfo.objectApiName = objectApiName;
            String recordName = (String) fieldValues.get('Name');
            config.recordInfo.name = recordName;
            config.recordInfo.recordTypeId = (String) fieldValues.get('RecordTypeId');
            
            Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            config.recordInfo.label = describe.getLabel();
            
            System.debug('=== FINISHING getHighlightConfig ===');
            System.debug('Visible fields: ' + config.visibleFields?.size());
            System.debug('Visible primary actions: ' + config.visiblePrimaryActions?.size());

            return config;

        } catch (Exception e) {
            System.debug('ERROR in getHighlightConfig: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading configuration: ' + e.getMessage());
        }
    }
    
    // ===== AUXILIARY METHODS =====
    
    public static Map<String, Object> getRecordTypeInfo(String objectApiName, String recordId) {
        Map<String, Object> result = new Map<String, Object>{
            'recordTypeId' => null, 'recordTypeApiName' => null
        };
        
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjectType == null || sObjectType.getDescribe().getRecordTypeInfosByName().size() == 0) {
                return result;
            }

            List<SObject> records = Database.query(
                'SELECT Id, RecordTypeId FROM ' + sObjectType + ' WHERE Id = :recordId LIMIT 1',
                AccessLevel.SYSTEM_MODE
            );
            
            if (!records.isEmpty() && records[0].get('RecordTypeId') != null) {
                String rtId = (String) records[0].get('RecordTypeId');
                result.put('recordTypeId', rtId);
                
                if (String.isNotBlank(rtId)) {
                    RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE Id = :rtId WITH SYSTEM_MODE LIMIT 1];
                    if (rt != null) {
                        result.put('recordTypeApiName', rt.DeveloperName);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in getRecordTypeInfo: ' + e.getMessage());
        }
        
        return result;
    }
    
    public static DMT_HighlightPanel_Config__mdt getMetadataConfig(String objectApiName, String recordTypeApiName) {
        List<DMT_HighlightPanel_Config__mdt> configs = new List<DMT_HighlightPanel_Config__mdt>();
        
        // 1. First look for a configuration specific to the Record Type
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
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            if (!configs.isEmpty()) return configs[0];
        }
        
        // 2. If there's no specific configuration, look for a general configuration for the object
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
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        
        return configs.isEmpty() ? null : configs[0];
    }
    
    public static HighlightPanelConfig parseMetadataConfig(DMT_HighlightPanel_Config__mdt metadata) {
        HighlightPanelConfig config = new HighlightPanelConfig();
        
        try {
            // 1. Icon configuration
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
            
            // 2. Parse fields from JSON
            config.fieldsConfig = parseFieldConfigs(metadata.Fields_Configuration__c);

            // 3. Parse primary actions
            config.primaryActions = parseActionConfigs(metadata.Primary_Actions_JSON__c);

            // 4. Parse menu actions
            config.menuActions = parseActionConfigs(metadata.Menu_Actions_JSON__c);

            // 5. Parse additional metadata
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
            System.debug('Error in parseMetadataConfig: ' + e.getMessage());
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
                
                // Basic properties
                field.type = (String) fieldMap.get('type');
                field.label = (String) fieldMap.get('label');
                field.value = (String) fieldMap.get('value');
                field.fieldApiName = (String) fieldMap.get('fieldApiName');
                field.isEditable = fieldMap.get('isEditable') != null ? (Boolean) fieldMap.get('isEditable') : false;
                field.isVisible = fieldMap.get('isVisible') != null ? (Boolean) fieldMap.get('isVisible') : true;
                field.badgeVariant = (String) fieldMap.get('badgeVariant');

                // Parse icon if present
                if (fieldMap.get('icon') != null) {
                    Map<String, Object> iconMap = (Map<String, Object>) fieldMap.get('icon');
                    field.icon = new FieldIcon();
                    field.icon.type = (String) iconMap.get('type');
                    field.icon.name = (String) iconMap.get('name');
                    field.icon.position = (String) iconMap.get('position');
                }

                // Parse action if present
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

                // Parse visibility condition if present
                if (fieldMap.get('visibilityCondition') != null) {
                    Map<String, Object> condMap = (Map<String, Object>) fieldMap.get('visibilityCondition');
                    field.visibilityCondition = parseConditionConfig(condMap);
                }

                // Parse editability condition if present
                if (fieldMap.get('editabilityCondition') != null) {
                    Map<String, Object> condMap = (Map<String, Object>) fieldMap.get('editabilityCondition');
                    field.editabilityCondition = parseConditionConfig(condMap);
                }
                
                result.add(field);
            }
            
        } catch (Exception e) {
            System.debug('Error in parseFieldConfigs: ' + e.getMessage());
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
        condition.systemPermission = (String) condMap.get('systemPermission');
        condition.combineConditions = (String) condMap.get('combineConditions');
        
        System.debug('parseConditionConfig - fieldName: ' + condition.fieldName + ', combineConditions: ' + condition.combineConditions);
        System.debug('Has conditions key: ' + condMap.containsKey('conditions') + ', value: ' + condMap.get('conditions'));
        
        // Parsear array de sub-condiciones recursivamente
        if (condMap.get('conditions') != null) {
            System.debug('Parsing sub-conditions array');
            List<Object> conditionsList = (List<Object>) condMap.get('conditions');
            condition.conditions = new List<ConditionConfig>();
            System.debug('Sub-conditions count: ' + conditionsList.size());
            for (Object subCondObj : conditionsList) {
                Map<String, Object> subCondMap = (Map<String, Object>) subCondObj;
                condition.conditions.add(parseConditionConfig(subCondMap));
            }
        }

        return condition;
    }
    
    public static List<ActionConfig> parseActionConfigs(String jsonString) {
        if (String.isBlank(jsonString)) return new List<ActionConfig>();
        
        System.debug('parseActionConfigs - JSON String length: ' + jsonString.length());
        System.debug('parseActionConfigs - First 500 chars: ' + jsonString.substring(0, Math.min(500, jsonString.length())));
        
        List<ActionConfig> result = new List<ActionConfig>();
        
        try {
            List<Object> rawList = (List<Object>) JSON.deserializeUntyped(jsonString);
            
            System.debug('parseActionConfigs - Deserialized ' + rawList.size() + ' actions');
            
            for (Object rawObj : rawList) {
                Map<String, Object> actionMap = (Map<String, Object>) rawObj;
                ActionConfig action = new ActionConfig();
                
                System.debug('Processing action, keys: ' + actionMap.keySet());
                
                // Basic properties
                action.label = (String) actionMap.get('label');
                action.name = (String) actionMap.get('name');
                action.variant = (String) actionMap.get('variant');
                action.actionType = (String) actionMap.get('actionType');
                action.disabled = actionMap.get('disabled') != null ? (Boolean) actionMap.get('disabled') : false;

                if (actionMap.get('actionConfig') != null) {
                    action.actionConfig = (Map<String, Object>) actionMap.get('actionConfig');
                }

                // Parse iconConfig if present
                if (actionMap.get('iconConfig') != null) {
                    Map<String, Object> iconMap = (Map<String, Object>) actionMap.get('iconConfig');
                    action.iconConfig = parseIconConfig(iconMap);
                }

                // Parse conditions
                if (actionMap.get('visibilityCondition') != null) {
                    Map<String, Object> condMap = (Map<String, Object>) actionMap.get('visibilityCondition');
                    System.debug('Action: ' + action.name + ', visibilityCondition keys: ' + condMap.keySet());
                    System.debug('Full visibilityCondition: ' + JSON.serialize(condMap));
                    action.visibilityCondition = parseConditionConfig(condMap);
                }
                
                if (actionMap.get('enablementCondition') != null) {
                    Map<String, Object> condMap = (Map<String, Object>) actionMap.get('enablementCondition');
                    action.enablementCondition = parseConditionConfig(condMap);
                }
                
                result.add(action);
            }
            
        } catch (Exception e) {
            System.debug('Error in parseActionConfigs: ' + e.getMessage());
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
    
    // ===== MAIN LOGIC =====
    
    public static Map<String, Object> getRecordFieldValues(HighlightPanelConfig config, String objectApiName, String recordId) {
        Map<String, Object> allValues = new Map<String, Object>();
        
        try {
            Set<String> allFieldApiNames = new Set<String>();
            
            // 1. Collect all fields from the configuration
            if (config.fieldsConfig != null) {
                for (FieldConfig field : config.fieldsConfig) {
                    if (String.isNotBlank(field.fieldApiName)) {
                        allFieldApiNames.add(field.fieldApiName);
                    }system.debug('fields'+field.fieldApiName);
                }
            }

            // 2. Collect fields for conditions
            if (config.fieldsConfig != null) {
                for (FieldConfig field : config.fieldsConfig) {
                    addConditionField(field.visibilityCondition, allFieldApiNames);
                    addConditionField(field.editabilityCondition, allFieldApiNames);
                }
            }

            // 3. Fields for primary actions
            if (config.primaryActions != null) {
                for (ActionConfig action : config.primaryActions) {
                    addConditionField(action.visibilityCondition, allFieldApiNames);
                    addConditionField(action.enablementCondition, allFieldApiNames);
                }
            }

            // 4. Fields for menu actions
            if (config.menuActions != null) {
                for (ActionConfig action : config.menuActions) {
                    addConditionField(action.visibilityCondition, allFieldApiNames);
                    addConditionField(action.enablementCondition, allFieldApiNames);
                }
            }

            // 5. Essential basic fields
            allFieldApiNames.add('Id');
            allFieldApiNames.add('Name');
            allFieldApiNames.add('RecordTypeId');

            System.debug('Total fields to query: ' + allFieldApiNames.size());
            System.debug('Fields: ' + allFieldApiNames);
            
            if (!allFieldApiNames.isEmpty()) {
                Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
                if (sObjectType == null) {
                    return allValues;
                }

                System.debug('Query object: ' + sObjectType + ' | fields: ' + allFieldApiNames);

                List<SObject> records = Database.query(
                    'SELECT ' + String.join(new List<String>(allFieldApiNames), ', ') +
                    ' FROM ' + sObjectType + ' WHERE Id = :recordId FOR UPDATE',
                    AccessLevel.SYSTEM_MODE
                );
                if (!records.isEmpty()) {
                    SObject record = records[0];
                    System.debug('allFieldApiNames: ' + allFieldApiNames);
                    // Store all values
                    for (String fieldName : allFieldApiNames) {
                        try {
                            // Supports direct fields and relationship paths (e.g. Owner.Name, Account.Name, Parent__r.Name)
                            Object value = getFieldValueFromPath(record, fieldName);
                                    allValues.put(fieldName, value);
                            System.debug('Query fieldName: value: ' + fieldName + ' : ' + value);

                            // Assign the value to the corresponding field
                            if (config.fieldsConfig != null) {
                                for (FieldConfig field : config.fieldsConfig) {
                                    if (field.fieldApiName == fieldName && value != null) {
                                        field.value = formatFieldValue(field.type, value);
                                        field.rawValue = value;
                                    }
                                }
                            }

                        } catch (Exception e) {
                            System.debug('Error retrieving field ' + fieldName + ': ' + e.getMessage()  + e.getlinenumber());
                            allValues.put(fieldName, null);
                        }
                    }
                }
            }

        } catch (Exception e) {
            System.debug('Error in getRecordFieldValues: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
        }
        
        return allValues;
    }
    
    private static Object getFieldValueFromPath(SObject record, String fieldPath) {
        if (record == null || String.isBlank(fieldPath)) {
            return null;
        }

        // Direct field, no relationship
        if (!fieldPath.contains('.')) {
            return record.get(fieldPath);
        }

        List<String> path = fieldPath.split('\\.');
        SObject current = record;

        // Walk each relationship up to the last segment (the final field)
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
                
                // Replace placeholders of the form {FieldName}
                for (String paramKey : params.keySet()) {
                    Object paramValue = params.get(paramKey);
                    if (paramValue instanceof String) {
                        String strValue = (String) paramValue;

                        // Check whether it's a {Field} placeholder
                        if (strValue.startsWith('{') && strValue.endsWith('}')) {
                            String fieldName = strValue.substring(1, strValue.length() - 1);

                            if (fieldValues.containsKey(fieldName)) {
                                Object actualValue = fieldValues.get(fieldName);
                                if (actualValue != null) {
                                    // Replace the placeholder with the actual value
                                    params.put(paramKey, String.valueOf(actualValue));
                                    System.debug('Replaced ' + strValue + ' with: ' + actualValue);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public static void addConditionField(ConditionConfig condition, Set<String> fieldSet) {
        if (condition == null) return;
        
        System.debug('addConditionField - fieldName: ' + condition.fieldName + ', has sub-conditions: ' + (condition.conditions != null));
        
        // Agregar campo simple
        if (String.isNotBlank(condition.fieldName)) {
            fieldSet.add(condition.fieldName);
            System.debug('Added field: ' + condition.fieldName);
        }
        
        // Agregar campos de sub-condiciones (recursivo)
        if (condition.conditions != null) {
            System.debug('Processing ' + condition.conditions.size() + ' sub-conditions');
            for (ConditionConfig subCondition : condition.conditions) {
                addConditionField(subCondition, fieldSet);
            }
        }
    }
    
    public static void applyConditions(HighlightPanelConfig config, Map<String, Object> fieldValues) {
        // Apply conditions to fields
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
        
        // Apply conditions to primary actions
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
        
        // Apply conditions to menu actions
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
            return true; // No condition = always visible/enabled
        }

        if (condition.conditions != null && !condition.conditions.isEmpty()) {
            System.debug('Evaluating complex condition with ' + condition.conditions.size() + ' sub-conditions');
            System.debug('CombineConditions: ' + condition.combineConditions);
            List<Boolean> results = new List<Boolean>();
            for (ConditionConfig sub : condition.conditions) {
                Boolean subResult = evaluateCondition(sub, fieldValues);
                System.debug('Sub-condition result: ' + subResult + ' for field: ' + sub.fieldName);
                results.add(subResult);
            }
            Boolean finalResult = combineResults(results, condition.combineConditions);
            System.debug('Combined result: ' + finalResult + ' for expression: ' + condition.combineConditions);
            return finalResult;
        }

        if (String.isNotBlank(condition.custompermission)) {
            String permissionName = String.valueOf(condition.custompermission).trim();
            System.debug('Evaluating custom permission: ' + permissionName);
            return FeatureManagement.checkPermission(permissionName);
        }

        if (String.isNotBlank(condition.systemPermission)) {
            return hasSystemPermission(condition.systemPermission.trim());
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

    public static Boolean hasSystemPermission(String permissionApiName) {
        if (String.isBlank(permissionApiName)) return true;

        if (!Pattern.matches('^[A-Za-z0-9]+$', permissionApiName)) {
            System.debug('systemPermission has an invalid format: ' + permissionApiName);
            return false;
        }

        Schema.SObjectField permissionField = Schema.SObjectType.PermissionSet.fields.getMap().get(permissionApiName);
        if (permissionField == null) {
            return false;
        }

        Id userId = UserInfo.getUserId();

        try {
            return Database.countQuery(
                'SELECT COUNT() FROM PermissionSetAssignment '
                + 'WHERE AssigneeId = :userId '
                + 'AND PermissionSet.' + permissionField + ' = true',
                AccessLevel.SYSTEM_MODE
            ) > 0;
        } catch (Exception e) {
            System.debug('Error evaluating systemPermission ' + permissionApiName + ': ' + e.getMessage());
            return false;
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

    private static boolean combineResults(List<Boolean> results, String logic) {
        if (String.isBlank(logic)) {
            return !results.contains(false);
        }
        
        String expr = logic.toUpperCase();
        for (Integer i = 0; i < results.size(); i++) {
            expr = expr.replace(String.valueOf(i + 1), results[i] ? 'T' : 'F');
        }
        
        while (expr.contains('(')) {
            Integer start = expr.lastIndexOf('(');
            Integer endPos = expr.indexOf(')', start);
            String sub = expr.substring(start + 1, endPos);
            expr = expr.substring(0, start) + (evalExpr(sub) ? 'T' : 'F') + expr.substring(endPos + 1);
        }        
        return evalExpr(expr);
    }

    private static boolean evalExpr(String expr) {
        if (expr.contains(' OR ')) {
            for (String p : expr.split(' OR ')) {
                if (evalExpr(p.trim())) return true;
            }
            return false;
        }
        if (expr.contains(' AND ')) {
            for (String p : expr.split(' AND ')) {
                if (!evalExpr(p.trim())) return false;
            }
            return true;
        }
        return expr == 'T';
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
        @AuraEnabled public String systemPermission;
        @AuraEnabled public List<ConditionConfig> conditions;
        @AuraEnabled public String combineConditions;
    }
    
    public class MetadataConfig {
        @AuraEnabled public Boolean showIcon = true;
        @AuraEnabled public String iconPosition = 'left';
        @AuraEnabled public Boolean compactMode = false;
        @AuraEnabled public Integer maxFieldColumns = 3;
        @AuraEnabled public Map<String, Object> customSettings;
    }
}