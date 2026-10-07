public with sharing class DMT_FieldsRequiredParser {

    // Clave de agrupación para rutas de servicio sin configuración en el Custom Metadata Type.
    // No es el nombre de ninguna pestaña real de dmt_opp_tab: es sólo un contenedor informativo.
    public static final String UNMAPPED_TAB_KEY = 'unmapped';

    // Cache estático: Service_Path__c -> registro de configuración. Se construye una única vez
    // por transacción a partir del Custom Metadata Type DMT_FieldsRequiredPassport__mdt.
    private static Map<String, DMT_FieldsRequiredPassport__mdt> CONFIG_BY_PATH {
        get {
            if (CONFIG_BY_PATH == null) {
                CONFIG_BY_PATH = new Map<String, DMT_FieldsRequiredPassport__mdt>();
                for (DMT_FieldsRequiredPassport__mdt fieldConfig : [
                    SELECT Service_Path__c, Tab_Name__c, Section_Name__c, Field_Api_Name__c, Field_Label__c
                    FROM DMT_FieldsRequiredPassport__mdt
                ]) {
                    CONFIG_BY_PATH.put(fieldConfig.Service_Path__c, fieldConfig);
                }
            }
            return CONFIG_BY_PATH;
        }
        set;
    }

    public static Map<String, Object> parse(String fieldMessage) {
        Map<String, Object> root = new Map<String, Object>();
        if (String.isBlank(fieldMessage)) return root;

        for (String rawPath : fieldMessage.split(',')) {
            String path = rawPath.trim();
            if (String.isBlank(path)) continue;

            String productIndex = extractProductIndex(path);
            // Los índices numéricos (ej. "[01]") se abstraen a "[*]" para el producto.
            // Cualquier otro bracket (ej. "[a6sKE000000a94bYAA]", un Id de mitigante) se elimina,
            // ya que la configuración no lo modela como comodín, sólo el nivel de producto.
            String normalizedPath = path.replaceAll('\\[\\d+\\]', '[*]');
            normalizedPath = normalizedPath.replaceAll('\\[(?!\\*\\])[^\\]]*\\]', '');

            DMT_FieldsRequiredPassport__mdt fieldConfig = CONFIG_BY_PATH.get(normalizedPath);
            // Si la ruta no está configurada en el Custom Metadata Type (p.ej. un warning nuevo
            // del backend que aún no se ha mapeado), no se descarta: se agrupa como campo plano
            // bajo UNMAPPED_TAB_KEY para que el LWC pueda avisar de que existe pero no se podrá
            // localizar/redirigir automáticamente.
            if (fieldConfig == null) {
                if (!root.containsKey(UNMAPPED_TAB_KEY)) root.put(UNMAPPED_TAB_KEY, new List<Object>());
                List<Object> unmappedList = (List<Object>) root.get(UNMAPPED_TAB_KEY);
                Map<String, String> unmappedEntry = new Map<String, String>{
                    'apiName' => path,
                    'label' => path,
                    'unmapped' => 'true'
                };
                if (!containsApiName(unmappedList, path)) unmappedList.add(unmappedEntry);
                continue;
            }

            String tabName = fieldConfig.Tab_Name__c;
            String sectionName = fieldConfig.Section_Name__c;
            String apiName = fieldConfig.Field_Api_Name__c;
            String label = fieldConfig.Field_Label__c;

            Map<String, String> fieldEntry = new Map<String, String>{ 'apiName' => apiName, 'label' => label };

            if (String.isNotBlank(sectionName)) {
                String idx = (productIndex != null) ? productIndex : '00';

                if (!root.containsKey(tabName)) root.put(tabName, new Map<String, Object>());
                Map<String, Object> tabMap = (Map<String, Object>) root.get(tabName);

                if (!tabMap.containsKey(idx)) tabMap.put(idx, new Map<String, Object>());
                Map<String, Object> productMap = (Map<String, Object>) tabMap.get(idx);

                if (!productMap.containsKey(sectionName)) productMap.put(sectionName, new List<Object>());
                List<Object> fieldList = (List<Object>) productMap.get(sectionName);

                if (!containsApiName(fieldList, apiName)) fieldList.add(fieldEntry);

            } else {
                if (!root.containsKey(tabName)) root.put(tabName, new List<Object>());
                List<Object> fieldList = (List<Object>) root.get(tabName);

                if (!containsApiName(fieldList, apiName)) fieldList.add(fieldEntry);
            }
        }
        return root;
    }

    private static Boolean containsApiName(List<Object> fieldList, String apiName) {
        for (Object entry : fieldList) {
            if (((Map<String, String>) entry).get('apiName') == apiName) return true;
        }
        return false;
    }

    private static String extractProductIndex(String path) {
        if (!path.contains('[')) return null;
        Integer startIdx = path.indexOf('[') + 1;
        Integer endIdx = path.indexOf(']');
        return (startIdx > 0 && endIdx > startIdx) ? path.substring(startIdx, endIdx) : null;
    }

}