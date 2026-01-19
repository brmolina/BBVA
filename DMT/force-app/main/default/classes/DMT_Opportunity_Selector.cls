public with sharing class DMT_Opportunity_Selector {
    public static Opportunity getOpportunity(String recordId) {
        return [SELECT Id, Name, DMT_Currency__c, CurrencyIsoCode,DMT_Entity__c,Entific__c,DES_Client_Country__c
        FROM Opportunity
        WHERE Id =: String.valueOf(recordId) LIMIT 1];
    }

        public static List<OpportunityLineItem> getOpportunityLineItems(Id opportunityId) {
        return [
            SELECT Id, gf_initial_date__c, gf_maturity_date__c
            FROM OpportunityLineItem
            WHERE OpportunityId =: opportunityId
        ];
    }

    public static Map<Id, PricebookEntry> getStandardActivePBEs(Set<Id> productIds, String currencyIsoCode) {
        return new Map<Id, PricebookEntry>([
            SELECT Id, Product2Id, Product2.Name, CurrencyIsoCode
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
            AND IsActive = true
            AND Pricebook2.IsStandard = true
            AND CurrencyIsoCode = :currencyIsoCode
        ]);
    }

    public static List<DMT_Taxonomy_Relationship__c> getTaxonomyValuesByEntity(String entity) {
        return [
            SELECT Id,
                   DMT_Final_Taxonomy_Value__r.DMT_Value__c,
                   DMT_Final_Taxonomy_Value__r.DMT_Name__c,
                   DMT_Value_Catalog_Initial__c
            FROM DMT_Taxonomy_Relationship__c
            WHERE DMT_Id_Catalog_Initial__c = 'H006'
              AND DMT_Final_Taxonomy_Value__c != ''
              AND DMT_Value_Catalog_Initial__c = :entity
        ];
    }

public static List<OpportunityLineItem> getAllOpportunityLineItems(String opportunityIds) {
    return [
        SELECT Id, OpportunityId, gf_group_priority_opportunity_id__c
        FROM OpportunityLineItem
        WHERE OpportunityId =:opportunityIds
        ORDER BY CreatedDate ASC
    ];
}

public static OpportunityLineItem getLastOppLineItem(Set<Id> opportunityIds) {
    List<OpportunityLineItem> oliList = [
        SELECT Id, OpportunityId, gf_group_priority_opportunity_id__c
        FROM OpportunityLineItem
        WHERE OpportunityId IN :opportunityIds
        ORDER BY gf_group_priority_opportunity_id__c DESC
    ];
    return oliList.size() > 0 ? oliList[0] : new OpportunityLineItem();
}

public static List<DMT_Taxonomy_Values__c> getCurrencies() {
        return  [
           SELECT id, DMT_Value__c FROM DMT_Taxonomy_Values__c WHERE DMT_Catalog__c = 'C264' and DMT_Active__c  = true
        ];

    }

public static List<Opportunity_Products__mdt> getOppProductsMdt() {
        return  [
           SELECT Product_Template__c
            FROM Opportunity_Products__mdt
            WHERE Product_Template__c  != null
        ];

    }

    public static Pricebook2 getPriceBook2() {
        return  [
           SELECT Id
            FROM Pricebook2
            WHERE IsStandard = true
            LIMIT 1
        ];

    }
    public static Map<Id,Product2> getProduct2(List<String> listIdProducts){
       return new Map<Id,Product2>([SELECT Id,DMT_Global_Product_Id__c ,Name,DMT_Product_category__c,DMT_Product_family__c,DMT_Product_Subcategory__c,DMT_Product_Subfamily__c FROM Product2 WHERE Id IN :listIdProducts]);
    }

    public static List<OpportunityLineItem> getOpportunityLineItemsById(List<Id> Ids) {
        return [
            SELECT Id, Name, OpportunityId, DES_Product_Name__c, DMT_TXT_ProductNameOLI__c, gf_initial_date__c, gf_maturity_date__c,
                Opportunity.Name, Opportunity.DMT_DATE_Initial_Date__c, Opportunity.DMT_DATE_Maturity_Date__c
            FROM OpportunityLineItem
            WHERE Id IN :Ids
        ];
    }
}