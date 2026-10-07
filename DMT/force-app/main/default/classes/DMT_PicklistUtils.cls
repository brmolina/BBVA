/**
 * @description       : Class that retrieves picklist values for a given object and field.
 * @author            :Javier Portilla
 * @group             : 
 * @last modified on  : 05-05-2025
 * @last modified by  : Javier Portilla
**/
global with sharing class DMT_PicklistUtils  implements Callable {

    public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try {
            Map<String, Object> result;
            if (methodName == 'getPicklistValues') {
                result = getPicklistValues(inputMap,outMap,options);
            } else if (methodName == 'getPicklistValuesLabeslAsValue') {
                result = getPicklistValuesLabeslAsValue(inputMap,outMap,options);
            } else if (methodName == 'getTaxonomyRelationshipValues') {
                result = getTaxonomyRelationshipValues(inputMap,outMap,options);
            } else if (methodName == 'getPicklistDependantValuesByParam') {
                result = getPicklistDependantValuesByParam(inputMap,outMap,options);
            } else if (methodName == 'capitalizeString') {
                result = capitalizeString(inputMap,outMap);
            }
            if (result != null) {
                outMap.putAll(result);
            }
        } catch (Exception e) {
            System.debug('Exception --> ' + e.getMessage());
            outMap.put('error', e.getMessage());
        }
        return outMap;
    }
    
    private Map<String, Object> getPicklistValues(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        
        String objectApiName = (String) inputMap.get('objectApiName');
        String fieldApiName = (String) inputMap.get('fieldApiName');
        List<String> values = new List<String>();
        List<Map<String, Object>> optionsList = new List<Map<String, Object>>();

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        if (!schemaMap.containsKey(objectApiName)) {
            throw new AuraHandledException('Objeto no válido: ' + objectApiName);
        }

        Schema.SObjectType objType = schemaMap.get(objectApiName);
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

        if (!fieldMap.containsKey(fieldApiName)) {
            throw new AuraHandledException('Campo no válido: ' + fieldApiName);
        }

        Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldApiName).getDescribe();

        if (objectApiName == 'DMT_Line__c' && (fieldApiName == 'First_Breakclause__c' || fieldApiName == 'Breakclause_Frequency__c')) {
            optionsList.add(new Map<String, Object>{
                'defaultValue' => false,
                'label' => ' ',
                'value' => ' '
            });
        }
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                optionsList.add(new Map<String, Object>{
                    'defaultValue' => entry.isDefaultValue(),
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }
        
        outMap.put('options', optionsList);
        return outMap;
    }

    private Map<String, Object> getPicklistValuesLabeslAsValue(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        
        String objectApiName = (String) inputMap.get('objectApiName');
        String fieldApiName = (String) inputMap.get('fieldApiName');
        List<String> values = new List<String>();
        List<Map<String, Object>> optionsList = new List<Map<String, Object>>();

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        if (!schemaMap.containsKey(objectApiName)) {
            throw new AuraHandledException('Objeto no válido: ' + objectApiName);
        }

        Schema.SObjectType objType = schemaMap.get(objectApiName);
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

        if (!fieldMap.containsKey(fieldApiName)) {
            throw new AuraHandledException('Campo no válido: ' + fieldApiName);
        }

        Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldApiName).getDescribe();
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                optionsList.add(new Map<String, Object>{
                    'defaultValue' => entry.isDefaultValue(),
                    'label' => entry.getValue(),
                    'value' => entry.getValue()
                });
            }
        }
        
        outMap.put('options', optionsList);
        return outMap;
    }

    
    /**
     * METHOD: getPicklistValuesLabeslAsValue
     * Busca y retorna los valores de relación entre taxonomiías
     * a partir de dos catálogos.
     * Los valores se retornan en forma de JSON dispuesto para ser usado como options de un dropdown
     * Si catálogo B depende del valor seleccionado en catálogo A, el resultado del método es un JSON
     * con los valores del catálogo A como llave y un listado de todos los valores de catálogo B que dependen de él.
     */
    
    private Map<String, Object> getTaxonomyRelationshipValues(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        // Obtener el Id del catálogo que identifica el Taxonomy Relationship
        String strCatalogId = (String) inputMap.get('catalogId');

        Boolean formattedLabel = false;
        if (inputMap != null && inputMap.containsKey('formattedLabel') && inputMap.get('formattedLabel') != null) {
            formattedLabel = (Boolean) inputMap.get('formattedLabel');
        }

        // Obtener todos las registros de relaciones entre los dos catálogos en la tabla Taxonomy Relationship
        // Se ordeenan por CREATED DATE para obtener la versión más actual en caso de elementos duplicados
        List<DMT_Taxonomy_Relationship__c> lstTaxonomyRelRawValues = [
            SELECT Id, DMT_Id_Catalog_Initial__c, DMT_Id_Catalog_Final__c, DMT_Id_Catalog__c, 
                DMT_Value_Catalog_Initial__c, DMT_Value_Catalog_Final__c, 
                DMT_Initial_Taxonomy_Value__r.DMT_Name__c, DMT_Final_Taxonomy_Value__r.DMT_Name__c,
                DMT_Final_Taxonomy_Value__r.DMT_Name_EN__c, DMT_Final_Taxonomy_Value__r.DMT_Value__c,
                DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val1_name_c__c,CreatedDate
            FROM DMT_Taxonomy_Relationship__c 
            WHERE DMT_Id_Catalog__c = :strCatalogId 
            ORDER BY CreatedDate DESC
        ];

        // Crear una clave única para el Mapa, para evitar duplicados.
        // La clave única es la combinación de catálogo de relación + catálogo inicial + catálogo final + valor de catálogo inicial
        Map<String, DMT_Taxonomy_Relationship__c> mapTaxonomyRelValues = new Map<String, DMT_Taxonomy_Relationship__c>();
        for (DMT_Taxonomy_Relationship__c objTaxonomyRel : lstTaxonomyRelRawValues) {
            String strUniqueKey = String.join(new List<String>{
                objTaxonomyRel.DMT_Id_Catalog_Initial__c,
                objTaxonomyRel.DMT_Id_Catalog_Final__c,
                objTaxonomyRel.DMT_Id_Catalog__c,
                objTaxonomyRel.DMT_Value_Catalog_Final__c
            }, '-');

            if (!mapTaxonomyRelValues.containsKey(strUniqueKey)) {
                mapTaxonomyRelValues.put(strUniqueKey, objTaxonomyRel); 
            }
        }

        // Generar el array de respuesta con la estructura de Valor de Catálogo A, con lista de posibles valores de Catálogo B
        Map<String, List<Map<String, Object>>> mapTaxonomyRelValuesFixed = new Map<String, List<Map<String, Object>>>();
        for (DMT_Taxonomy_Relationship__c objTaxonomyRelValue : mapTaxonomyRelValues.values()) {
            String strFinalCatalogValueKey = objTaxonomyRelValue.DMT_Value_Catalog_Initial__c;

            String labelValue;
            if (formattedLabel) {
                labelValue = String.valueOf(objTaxonomyRelValue.DMT_Final_Taxonomy_Value__r.DMT_Value__c) + ' - ' + String.valueOf(objTaxonomyRelValue.DMT_Final_Taxonomy_Value__r.DMT_Name_EN__c);
            } else {
                labelValue = objTaxonomyRelValue.DMT_Final_Taxonomy_Value__r.DMT_Name__c;
            }

            Map<String, Object> mapCatalogValues = new Map<String, Object>{
                'label' => labelValue,
                'value' => objTaxonomyRelValue.DMT_Value_Catalog_Final__c,
                'orden' => objTaxonomyRelValue.DMT_Final_Taxonomy_Value__r.gf_catalog_atrb_val1_name_c__c
            };

            if (!mapTaxonomyRelValuesFixed.containsKey(strFinalCatalogValueKey)) {
                mapTaxonomyRelValuesFixed.put(strFinalCatalogValueKey, new List<Map<String, Object>>{ mapCatalogValues });
            } else {
                mapTaxonomyRelValuesFixed.get(strFinalCatalogValueKey).add(mapCatalogValues);
            }
        }

        //Order related values by 'orden' field
        Map<String, Object> inputMapForSort = new Map<String, Object>();
        for (String key : mapTaxonomyRelValuesFixed.keySet()) {
            inputMapForSort.put(key, mapTaxonomyRelValuesFixed.get(key));
        }
        Map<String, Object> sortedMap = new Map<String, Object>();
        DMT_Profitability_Helper.orderCatalogs(inputMapForSort, sortedMap);

        // Cast sortedMap values back to the expected type
        Map<String, List<Map<String, Object>>> mapTaxonomyRelValuesFixedSorted = new Map<String, List<Map<String, Object>>>();
        for (String key : sortedMap.keySet()) {
            List<Object> listObj = (List<Object>)sortedMap.get(key);
            List<Map<String, Object>> listMap = new List<Map<String, Object>>();
            for (Object obj : listObj) {
                listMap.add((Map<String, Object>)obj);
            }
            mapTaxonomyRelValuesFixedSorted.put(key, listMap);
        }

        outMap.put('mapTaxonomyRelValuesFixed', mapTaxonomyRelValuesFixedSorted);
        return outMap;
    }

    /**
     * METHOD: getPicklistDependantValuesByParam
     * Busca y retorna los valores de relación entre taxonomiías
     * a partir de dos catálogos.
     * Los valores se retornan en forma de JSON dispuesto para ser usado como options de un dropdown
     * Si catálogo B depende del valor seleccionado en catálogo A, el resultado del método es un JSON
     * con los valores del catálogo A como llave y un listado de todos los valores de catálogo B que dependen de él.
     */
    
    private Map<String, Object> getPicklistDependantValuesByParam(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        // Obtener el Id del catálogo que identifica el Taxonomy Relationship
        String strCatalogId = (String) inputMap.get('catalogId');
        
        // Obtener todos las registros de relaciones entre los dos catálogos en la tabla Taxonomy Relationship
        // Se ordeenan por CREATED DATE para obtener la versión más actual en caso de elementos duplicados
        List<DMT_Taxonomy_Values__c> lstTaxonomyRelRawValues = [
            SELECT Id, DMT_Name_EN__c, DMT_Name__c, DMT_Value__c
            FROM DMT_Taxonomy_Values__c 
            WHERE DMT_Catalog__c = :strCatalogId 
            ORDER BY DMT_Value__c, CreatedDate DESC
        ];

        // Crear una clave única para el Mapa, para evitar duplicados.
        // La clave única es la combinación de catálogo de relación + catálogo inicial + catálogo final + valor de catálogo inicial
        Map<String, DMT_Taxonomy_Values__c> mapTaxonomyRelValues = new Map<String, DMT_Taxonomy_Values__c>();
        for (DMT_Taxonomy_Values__c objTaxonomyRel : lstTaxonomyRelRawValues) {
            String strUniqueKey = String.join(new List<String>{
                objTaxonomyRel.DMT_Name_EN__c,
                objTaxonomyRel.DMT_Value__c
            }, '-');

            if (!mapTaxonomyRelValues.containsKey(strUniqueKey)) {
                mapTaxonomyRelValues.put(strUniqueKey, objTaxonomyRel); 
            }
        }

        Map<String, List<Map<String, Object>>> mapTaxonomyRelValuesFixed = new Map<String, List<Map<String, Object>>>();
        for (DMT_Taxonomy_Values__c objTaxonomyRelValue : mapTaxonomyRelValues.values()) {
            String strFinalCatalogValueKey = objTaxonomyRelValue.DMT_Value__c.substring(0,2);

            Map<String, Object> mapCatalogValues = new Map<String, Object>{
                'label' => objTaxonomyRelValue.DMT_Name_EN__c,
                'value' => objTaxonomyRelValue.DMT_Value__c
            };

            if (!mapTaxonomyRelValuesFixed.containsKey(strFinalCatalogValueKey)) {
                mapTaxonomyRelValuesFixed.put(strFinalCatalogValueKey, new List<Map<String, Object>>{ mapCatalogValues });
            } else {
                mapTaxonomyRelValuesFixed.get(strFinalCatalogValueKey).add(mapCatalogValues);
            }
        }

        outMap.put('mapCatalogValuesFixed', mapTaxonomyRelValuesFixed);
        return outMap;
    }

    private Map<String, Object> capitalizeString(Map<String, Object> inputMap, Map<String, Object> outMap) {
        System.debug( 'capitalizeString - inputMap: ' + inputMap);
        System.debug( 'capitalizeString - valor de "value" en inputMap: ' + inputMap.get('arguments'));
        List<Object> arguments = (List<Object>)inputMap.get('arguments');
        String value = (String) arguments[0];
        
        if (String.isBlank(value)) {
            outMap.put('result', '');
            return outMap;
        }
        String capitalized = value.substring(0, 1).toUpperCase() + value.substring(1).toLowerCase();
        outMap.put('result', capitalized);
        return outMap;
    }
}