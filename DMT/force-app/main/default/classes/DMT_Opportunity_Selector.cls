public with sharing class DMT_Opportunity_Selector {
    public static Opportunity getOpportunity(String recordId) {
        return [SELECT Id, Name, DMT_CurrencyText__c, DMT_Opportunity_amount__c, CurrencyIsoCode,DMT_Entity__c,Entific__c,DES_Client_Country__c,DMT_branch_id_c__c,
        DMT_DATE_Initial_Date__c,DMT_DATE_Maturity_Date__c, AccountId, DMT_ApproverGlobalBanker__c, DMT_Approver__c, DMT_Booking_Unit_Risk_Analyst__c
        FROM Opportunity
        WHERE Id =: String.valueOf(recordId) LIMIT 1];
    }

        public static List<OpportunityLineItem> getOpportunityLineItems(Id opportunityId) {
        return [
            SELECT Id, Product2Id,DMT_TXT_ProductNameOLI__c,DES_Product_Name__c, ProductCode, DMT_Associated_Line_Product__c, gf_group_priority_opportunity_id__c,
                   gf_initial_date__c, gf_maturity_date__c, DMT_Risk_Type__c, opportunity_risk_name__c,
                   DMT_TXT_Comentarios__c, DMT_Deal_Amount_Tenors__c, g_currency_Id__c,
                   g_branch_id__c, g_line_commitment_level_type__c, g_multioperation_ind_type__c, OpportunityId, Opportunity.AccountId,Opportunity.DMT_Opp_Id__c,
                   gf_payment_frequency__c, gf_amortization_type__c, DMT_balloon_amortization_indicator__c,
                   DMT_bullet_amortization_indicator__c
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
    public static  Passport__c getPassport(Id opportunityId) {
        return [
            SELECT Id
            FROM Passport__c
            WHERE Opportunity__c  = :opportunityId
            LIMIT 1
        ];
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

@AuraEnabled(cacheable=true)
public static List<OpportunityLineItem> getProductIds(String opportunityExternalId, List<String> productIds) {
    if (String.isBlank(opportunityExternalId) || productIds == null || productIds.isEmpty()) {
        return new List<OpportunityLineItem>();
    }

    return [
        SELECT Id, DES_Product_Name__c, gf_group_priority_opportunity_id__c, Opportunity.DMT_Opp_Id__c
        FROM OpportunityLineItem
        WHERE Opportunity.DMT_Opp_Id__c = :opportunityExternalId
        AND gf_group_priority_opportunity_id__c IN :productIds
    ];
}

public static Opportunity getOpportunityByExternalIdWithSanction(String opportunityExternalId) {
    List<Opportunity> opportunities = [
        SELECT DMT_Sanction__c, DMT_Sanction__r.Id, DMT_Sanction__r.Name
        FROM Opportunity
        WHERE DMT_Opp_Id__c = :opportunityExternalId
        LIMIT 1
    ];

    if (opportunities.isEmpty()) {
        return null;
    }

    return opportunities[0];
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
    public static List<OpportunityLineItem> getOpportunityLineItemsById(List<String> Ids, String oppId) {
        return [
            SELECT Id, Name, OpportunityId, DES_Product_Name__c, DMT_TXT_ProductNameOLI__c, gf_initial_date__c, gf_maturity_date__c,
                Opportunity.Name, Opportunity.DMT_DATE_Initial_Date__c, Opportunity.DMT_DATE_Maturity_Date__c,gf_group_priority_opportunity_id__c, g_currency_id__c, Opportunity.DMT_CurrencyText__c
            FROM OpportunityLineItem
            WHERE gf_group_priority_opportunity_id__c IN :Ids AND OpportunityId = :oppId
        ];
    }
    public static List<OpportunityLineItem> getOpportunityLineItemsById(List<Id> Ids) {
        return [
            SELECT Id, Name, OpportunityId, DES_Product_Name__c, DMT_TXT_ProductNameOLI__c, gf_initial_date__c, gf_maturity_date__c,
                Opportunity.Name, Opportunity.DMT_DATE_Initial_Date__c, Opportunity.DMT_DATE_Maturity_Date__c
            FROM OpportunityLineItem
            WHERE gf_group_priority_opportunity_id__c IN :Ids
        ];
    }

    public static List<PricebookEntry> getPbeByProductIds(Set<Id> productIds) {
        return [
        SELECT Id, Product2Id 
        FROM PricebookEntry 
        WHERE Product2Id IN :productIds
        AND Pricebook2.IsStandard = true
    ];
}


    public static List<DMT_Warranty__c> getWarrantiesByRiskLineIds(List<Id> riskLineIds) {
        return [
            SELECT Id, DMT_Risk_Line_Term__c, gf_group_priority_line_id__c, Name,
                   g_limits_grid_guarantee_type__c, gf_origin_application_type__c, g_entific_id__c
            FROM DMT_Warranty__c
            WHERE DMT_Risk_Line_Term__c IN :riskLineIds
        ];
    }

    public static List<DMT_Currency_Provision__c> getCurrencyProvisionsByRiskLineIds(List<Id> riskLineIds) {
        return [
            SELECT Id, DMT_Risk_Line_Term__c, gf_group_priority_line_id__c, Name,
                   g_currency_id__c, gf_origin_application_type__c, g_entific_id__c
            FROM DMT_Currency_Provision__c
            WHERE DMT_Risk_Line_Term__c IN :riskLineIds
        ];
    }

    public static DMT_Line__c getLineByOpportunityId(String oppId) {
        List<DMT_Line__c> lines = [
            SELECT Id, Name, Booking_Geography__c, Client_Code__c, Client__c, CurrencyIsoCode,
                   DMT_ApproverGlobalBanker__c, DMT_Approver__c, DMT_Booking_Unit_Risk_Analyst__c,
                   DMT_ClientRating__c, DMT_Client_Entific__c, DMT_Entity__c, DMT_LocalClient__c,
                   DMT_Opportunity__c, DMT_Origin__c, End_Date__c, Line_Id__c, RecordTypeId,
                   Start_Date__c, Status__c, gf_min_raroec_wo_fcg_per__c, gf_min_rorc_wo_fcg_per__c
            FROM DMT_Line__c
            WHERE DMT_Opportunity__c = :oppId
            LIMIT 1
        ];
        return lines.isEmpty() ? null : lines[0];
    }

}