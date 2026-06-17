public with sharing class DMT_feature_limitController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMitigantsAndOppLineItemsByField(String oppId, List<String> productsId, List<String> mitigantsId) {
        List<OpportunityLineItem> oliList = [
            SELECT Id, DES_Product_Name__c, gf_group_priority_opportunity_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
            AND gf_group_priority_opportunity_id__c IN :productsId
        ];

        List<DMT_Opportunity_Mitigant__c> mitigantsList = [
            SELECT Id, Name
            FROM DMT_Opportunity_Mitigant__c
            WHERE Id IN :mitigantsId
        ];

        List<Map<String, Object>> results = new List<Map<String, Object>>();

        for (OpportunityLineItem oli : oliList) {
            results.add(new Map<String, Object>{
                'statusCode' => 200,
                'result' => new Map<String, Object>{
                    'id'      => oli.Id,
                    'gf_group_priority_opportunity_id__c' => oli.gf_group_priority_opportunity_id__c,
                    'apiName' => 'OpportunityLineItem',
                    'fields'  => new Map<String, Object>{
                        'DES_Product_Name__c' => new Map<String, Object>{ 'value' => oli.DES_Product_Name__c }
                    }
                }
            });
        }

        for (DMT_Opportunity_Mitigant__c mit : mitigantsList) {
            results.add(new Map<String, Object>{
                'statusCode' => 200,
                'result' => new Map<String, Object>{
                    'id'      => mit.Id,
                    'apiName' => 'DMT_Opportunity_Mitigant__c',
                    'fields'  => new Map<String, Object>{
                        'Name' => new Map<String, Object>{ 'value' => mit.Name }
                    }
                }
            });
        }

        return new Map<String, Object>{ 'results' => results };
    }
}