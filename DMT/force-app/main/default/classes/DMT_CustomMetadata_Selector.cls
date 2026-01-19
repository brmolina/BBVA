public with sharing class DMT_CustomMetadata_Selector {
    /**
     * Retrieves DMT_Configurator_View_Items__mdt records filtered by view type and active status.
     *
     * @param viewType The value of the DMT_Type__c field to filter by
     * @return List of DMT_Configurator_View_Items__mdt records ordered by PositionInList__c
     */
    public static List<DMT_Configurator_View_Items__mdt> getConfiguratorViewItemsByViewType(String viewType) {
        if (!Schema.sObjectType.DMT_Configurator_View_Items__mdt.isAccessible()) {
            System.debug(LoggingLevel.WARN, 'User does not have access to DMT_Configurator_View_Items__mdt');
            return new List<DMT_Configurator_View_Items__mdt>();
        }
        return [
            SELECT DMT_Component_Item__c, PositionInList__c
            FROM DMT_Configurator_View_Items__mdt
            WHERE DMT_Type__c = :viewType AND Active__c = true
            ORDER BY PositionInList__c
        ];
    }
}