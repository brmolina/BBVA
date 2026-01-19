public with sharing class DMT_MitigantsController {
    @AuraEnabled(cacheable=true)
    public static List<String> getCurrencyValues() {
         List<DMT_Taxonomy_Values__c> results = DMT_Opportunity_Selector.getCurrencies();
        
        List<String> values = new List<String>();
        for (DMT_Taxonomy_Values__c txvalue : results) {
            values.add(txvalue.DMT_Value__c);
        }
        return values;
    }
}