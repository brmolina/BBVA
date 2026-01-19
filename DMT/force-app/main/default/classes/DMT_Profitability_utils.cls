public with sharing class DMT_Profitability_utils {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getProductDetailsByIds(List<Id> productIds) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        if (productIds == null || productIds.isEmpty()) {
            return results;
        }

        for (OpportunityLineItem oli : DMT_Opportunity_Selector.getOpportunityLineItemsById(productIds)) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('Id', oli.Id);
            row.put('Name', oli.DMT_TXT_ProductNameOLI__c);
            row.put('InitialDate', oli.gf_initial_date__c);
            row.put('MaturityDate', oli.gf_maturity_date__c);

            if (oli.Opportunity != null) {
                row.put('OppName', oli.Opportunity.Name);
                row.put('OppInitialDate', oli.Opportunity.DMT_DATE_Initial_Date__c);
                row.put('OppMaturityDate', oli.Opportunity.DMT_DATE_Maturity_Date__c);
            }

            results.add(row);
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static Map<Id, Map<String, Object>> getNominalAmountsByOpportunityLineItemIds(List<Id> productIds) {
        Map<Id, Map<String, Object>> result = new Map<Id, Map<String, Object>>();

        if (productIds == null || productIds.isEmpty()) {
            return result;
        }

        for (DMT_Opportunity_Tenor__c tenor : [
            SELECT DMT_Opportunity_Product__c, gf_nominal_amount_fb__c, gj_nominal_amount_db__c
            FROM DMT_Opportunity_Tenor__c
            WHERE DMT_Opportunity_Product__c IN :productIds
            LIMIT 1
        ]) {
            Id oliId = tenor.DMT_Opportunity_Product__c;
            if (!result.containsKey(oliId)) {
                result.put(oliId, new Map<String, Object>{
                    'nominalFb' => tenor.gf_nominal_amount_fb__c,
                    'nominalDb' => tenor.gj_nominal_amount_db__c
                });
            }
        }
        return result;
    }
}