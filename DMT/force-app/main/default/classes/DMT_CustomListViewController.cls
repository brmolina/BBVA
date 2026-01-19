public with sharing class DMT_CustomListViewController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAllRecords(String objectApiName) {
        // Obtener todos los campos del objeto dinámicamente
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        List<String> fieldNames = new List<String>();
        for(String f : fieldsMap.keySet()) {
            fieldNames.add(f);
        }

        // Construir SOQL dinámico
        String soql = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + objectApiName + ' LIMIT 2000';
        List<SObject> records = Database.query(soql);

        // Convertir a lista de mapas
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for(SObject rec : records) {
            Map<String, Object> recMap = new Map<String, Object>();
            for(String f : fieldNames) {
                recMap.put(f, rec.get(f));
            }
            result.add(recMap);
        }system.debug(result);
        return result;
    }
}