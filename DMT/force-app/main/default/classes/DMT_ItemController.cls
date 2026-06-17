public with sharing class DMT_ItemController {

    @AuraEnabled
    public static ContentVersion uploadFile(Map<String, Object> fileData) {
        String fileName = (String) fileData.get('fileName');
        String base64Data = (String) fileData.get('base64');

        Blob fileBlob = Blob.valueOf(base64Data);

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = fileName;
        contentVersion.VersionData = fileBlob;

        insert contentVersion;

        return [SELECT Id, ContentDocumentId, Title  FROM ContentVersion WHERE Id = :contentVersion.Id WITH USER_MODE];
    }

    // Obtener las opciones del campo controlador (Type_Item__c)
    @AuraEnabled(cacheable=true)
    public static List<String> getTypeItemOptions() {
        Schema.DescribeFieldResult fieldResult = DMT_Items__c.Type_Item__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        List<String> options = new List<String>();

        for (Schema.PicklistEntry picklistValue : picklistValues) {
            options.add(picklistValue.getLabel());
        }
        return options;
    }

    // Obtener todas las opciones del campo dependiente (DMT_Component_Item__c)
    @AuraEnabled(cacheable=true)
    public static List<String> getComponentItemOptions() {
        Schema.DescribeFieldResult fieldResult = DMT_Items__c.DMT_Component_Item__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        List<String> options = new List<String>();

        for (Schema.PicklistEntry picklistValue : picklistValues) {
            options.add(picklistValue.getLabel());
        }
        return options;
    }

    /**
     * Devuelve una lista de valores validos del picklist DMT_Component_Item__c del objeto DMT_Items__c,
     * filtrados por el tipo de vista (DMT_Type__c) proporcionado.
     *
     * Este método consulta el Custom Metadata Type DMT_Configurator_View_Items__mdt, el cual define
     * las combinaciones permitidas entre tipos de vista y componentes (items). Luego cruza esa información
     * con los valores definidos actualmente en el picklist DMT_Component_Item__c para asegurarse de que
     * los valores devueltos sean válidos.
     *
     * @param viewType El valor del tipo de vista seleccionado (DMT_Type__c), usado para filtrar los items compatibles.
     * @return Lista de valores de picklist permitidos para el tipo de vista proporcionado.
     *
     */
     @AuraEnabled(cacheable=true)
     public static List<String> getFilteredComponentItemOptions(String viewType) {
        Set<String> filteredValues = new Set<String>();

        if (Schema.sObjectType.DMT_Configurator_View_Items__mdt.isAccessible()) {

            List<DMT_Configurator_View_Items__mdt> mappings = DMT_CustomMetadata_Selector.getConfiguratorViewItemsByViewType(viewType);

            Set<String> validPicklistValues = new Set<String>();
            Schema.DescribeFieldResult fieldResult = DMT_Items__c.DMT_Component_Item__c.getDescribe();

            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                validPicklistValues.add(entry.getValue());
            }
            System.debug('Valid picklist values: ' + validPicklistValues);

            for (DMT_Configurator_View_Items__mdt mapping : mappings) {
                if (validPicklistValues.contains(mapping.DMT_Component_Item__c)) {
                    filteredValues.add(mapping.DMT_Component_Item__c);
                }
            }

        }

        System.debug('Filtered component items: ' + filteredValues);

        return new List<String>(filteredValues);
    }
}