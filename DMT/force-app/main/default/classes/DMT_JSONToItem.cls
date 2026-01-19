public with sharing class DMT_JSONToItem {
    @InvocableMethod(label='Convert JSON to DMT_Items__c List and Insert with View Id' description='Converts a JSON string to a list of DMT_Items__c records, assigns the view Id, and inserts them into the database')
    public static void convertToItemsAndInsert(List<RequestWrapper> inputRequests) {
        // Crear un mapa para almacenar ítems relacionados por viewId
        Map<Id, List<DMT_Items__c>> itemsToInsertMap = new Map<Id, List<DMT_Items__c>>();

        // Recolectar los Ids de vistas que necesitamos eliminar
        Set<Id> viewIds = new Set<Id>();
        for (RequestWrapper request : inputRequests) {
            viewIds.add(request.viewId);
        }

        // Eliminar los ítems existentes relacionados con las vistas (una sola consulta)
        deleteExistingItems(viewIds);

        // Deserializar y preparar los nuevos ítems
        for (RequestWrapper request : inputRequests) {
            List<Object> deserializedItems = (List<Object>) JSON.deserializeUntyped(request.jsonItems);
            
            List<DMT_Items__c> items = new List<DMT_Items__c>();

            for (Object obj : deserializedItems) {
                Map<String, Object> itemMap = (Map<String, Object>) obj;
                
                DMT_Items__c newItem = new DMT_Items__c();
                newItem.DMT_order_display__c = (Integer) itemMap.get('orderDisplay');
                newItem.Type_Item__c = (String) itemMap.get('type');
                newItem.DMT_Component_Item__c = (String) itemMap.get('component');
                newItem.DMT_Text__c = (String) itemMap.get('textValue');
                newItem.DMT_View__c = request.viewId;

                items.add(newItem);
            }

            // Añadir los ítems a su lista correspondiente en el mapa por viewId
            if (!itemsToInsertMap.containsKey(request.viewId)) {
                itemsToInsertMap.put(request.viewId, new List<DMT_Items__c>());
            }
            itemsToInsertMap.get(request.viewId).addAll(items);
        }

        // Insertar los ítems en lotes (bulk insert)
        List<DMT_Items__c> itemsToInsert = new List<DMT_Items__c>();
        for (Id viewId : itemsToInsertMap.keySet()) {
            itemsToInsert.addAll(itemsToInsertMap.get(viewId));
        }

        // Insertar en la base de datos
        if (!itemsToInsert.isEmpty()) {
            try {
                insert itemsToInsert;
            } catch (DmlException e) {
                System.debug('Error al insertar los registros: ' + e.getMessage());
                throw new AuraHandledException('Error al insertar los registros.');
            }
        }
    }

    // Método para eliminar ítems existentes para varios viewIds
    private static void deleteExistingItems(Set<Id> viewIds) {
        try {
            List<DMT_Items__c> existingItems = [
                SELECT Id FROM DMT_Items__c WHERE DMT_View__c IN :viewIds
            ];
            if (!existingItems.isEmpty()) {
                delete existingItems;
            }
        } catch (DmlException e) {
            System.debug('Error al eliminar los registros existentes: ' + e.getMessage());
            throw new AuraHandledException('Error al eliminar los registros existentes.');
        }
    }

    // Clase envoltorio (wrapper) para pasar tanto el JSON como el Id de la vista
    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String jsonItems;

        @InvocableVariable(required=true)
        public Id viewId;
    }
}