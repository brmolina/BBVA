public with sharing class ONB_ProductStepController {
    private static final Map<String, String> BOOKING_ENTITY_TO_PRICEBOOK = new Map<String, String>{
        'BBVA_Mexico' => 'PB_ONB_MEXICO_EQUITIES',
        'BBVA_SA_Belgium' => 'PB_ONB_FX_SPOT_ONLY',
        'BBVA_SA_China' => 'PB_ONB_FX_SPOT_ONLY',
        'BBVA_SA_France' => 'PB_ONB_FX_SPOT_ONLY',
        'BBVA_SA_Germany' => 'PB_ONB_FX_SPOT_ONLY',
        'BBVA_SA_Hong_Kong' => 'PB_ONB_FX_SPOT_ONLY',
        'BBVA_SA_Italy' => 'PB_ONB_FX_SPOT_ONLY',
        'BBVA_SA_Japan' => 'PB_ONB_FX_SPOT_ONLY',
        'BBVA_SA_Singapore' => 'PB_ONB_FX_SPOT_ONLY',
        'BBVA_SA_Spain' => 'PB_ONB_SPAIN_FULL',
        'BBVA_SA_Taiwan' => 'PB_ONB_FX_SPOT_ONLY',
        'BBVA_SA_United_Kingdom' => 'PB_ONB_FX_SPOT_ONLY',
        'BBVA_SA_United_States_of_America' => 'PB_ONB_US_MIX',
        'BSI' => 'PB_ONB_BSI'
    };

    @AuraEnabled(cacheable=false)
    public static List<ONB_Onboarding_Line__c> getProductItemsByOnboarding(Id onboardingId) {
        if (onboardingId == null) {
            return new List<ONB_Onboarding_Line__c>();
        }

        return [
            SELECT Id,
                   Name,
                   OnboardingId__c,
                   Product2Id__c,
                   Product2Id__r.Name,
                   Product_Category__c,
                   Booking_Entity__c,
                   Selling_Location__c,
                   Branch_Code__c,
                   Account_Officer__c,
                   Comments__c
            FROM ONB_Onboarding_Line__c
            WHERE OnboardingId__c = :onboardingId
            ORDER BY CreatedDate ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductsByBookingEntityAndCategory(
        Id onboardingId,
        String bookingEntity,
        String productCategory
    ) {
        if (onboardingId == null || String.isBlank(bookingEntity) || String.isBlank(productCategory)) {
            return new List<Product2>();
        }

        ONB_Onboarding__c onboarding = [
            SELECT Any_Master_Agreement__c
            FROM ONB_Onboarding__c
            WHERE Id = :onboardingId
            LIMIT 1
        ];

        String pricebookName = BOOKING_ENTITY_TO_PRICEBOOK.get(bookingEntity);
        if (String.isBlank(pricebookName)) {
            return new List<Product2>();
        }

        List<Pricebook2> pricebooks = [
            SELECT Id
            FROM Pricebook2
            WHERE Name = :pricebookName
            AND IsActive = true
            LIMIT 1
        ];

        if (pricebooks.isEmpty()) {
            return new List<Product2>();
        }

        Boolean restrictToFxSpotAndBonds = onboarding.Any_Master_Agreement__c == 'No';

        List<PricebookEntry> entries = [
            SELECT Product2Id,
                Product2.Name,
                Product2.ONB_Product_Category__c,
                Product2.IsActive
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebooks[0].Id
            AND IsActive = true
            AND Product2.IsActive = true
            AND Product2.ONB_Product_Category__c = :productCategory
            ORDER BY Product2.Name
            LIMIT 2000
        ];

        List<Product2> result = new List<Product2>();
        Set<Id> seen = new Set<Id>();

        for (PricebookEntry entry : entries) {
            if (entry.Product2Id == null || seen.contains(entry.Product2Id)) {
                continue;
            }

            if (
                restrictToFxSpotAndBonds &&
                entry.Product2.Name != 'FX Spot' &&
                entry.Product2.Name != 'Bonds'
            ) {
                continue;
            }

            seen.add(entry.Product2Id);
            result.add(new Product2(
                Id = entry.Product2Id,
                Name = entry.Product2.Name,
                ONB_Product_Category__c = entry.Product2.ONB_Product_Category__c
            ));
        }

        return result;
    }

    public class ProductModalDTO {
        @AuraEnabled public List<ONB_Onboarding_Line__c> products;
        @AuraEnabled public List<Id> preselectedProductIds;
    }

    @AuraEnabled(cacheable=true)
    public static ProductModalDTO getProductItemsForFunds(Id onboardingId, Id fundId) {
        ProductModalDTO dto = new ProductModalDTO();
        dto.products = new List<ONB_Onboarding_Line__c>();
        dto.preselectedProductIds = new List<Id>();

        if (onboardingId == null || fundId == null) {
            return dto;
        }

        List<ONB_Onboarding_Line__c> rows = [
            SELECT Id,
                   Name,
                   OnboardingId__c,
                   Product2Id__c,
                   Product2Id__r.Name,
                   Product_Category__c,
                   Booking_Entity__c,
                   Selling_Location__c,
                   Branch_Code__c,
                   Account_Officer__c,
                   Comments__c
            FROM ONB_Onboarding_Line__c
            WHERE OnboardingId__c = :onboardingId
              AND Product2Id__c != null
              AND (Product2Id__r.Name = 'FX Spot' OR Product2Id__r.Name = 'Bonds')
            ORDER BY CreatedDate ASC
        ];

        dto.products = rows;

        Set<Id> selectedProductIds = new Set<Id>();
        for (ONB_Fund_Product_Relsh__c rel : [
            SELECT ProductId__c
            FROM ONB_Fund_Product_Relsh__c
            WHERE FundItemId__c = :fundId
        ]) {
            if (rel.ProductId__c != null) {
                selectedProductIds.add(rel.ProductId__c);
            }
        }

        dto.preselectedProductIds.addAll(selectedProductIds);
        return dto;
    }

    @AuraEnabled
    public static void saveProductsForFund(Id fundId, List<Id> selectedProductsIds) {
        if (fundId == null) {
            return;
        }

        Set<Id> selected = new Set<Id>();
        if (selectedProductsIds != null) {
            selected.addAll(selectedProductsIds);
        }

        List<ONB_Fund_Product_Relsh__c> existing = [
            SELECT Id, FundItemId__c, ProductId__c
            FROM ONB_Fund_Product_Relsh__c
            WHERE FundItemId__c = :fundId
        ];

        if (!existing.isEmpty()) {
            delete existing;
        }

        if (selected.isEmpty()) {
            return;
        }

        List<ONB_Fund_Product_Relsh__c> toInsert = new List<ONB_Fund_Product_Relsh__c>();
        for (Id productId : selected) {
            toInsert.add(new ONB_Fund_Product_Relsh__c(
                FundItemId__c = fundId,
                ProductId__c = productId
            ));
        }

        insert toInsert;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean isMassFundProductAssignmentActive(Id onboardingId) {
        if (onboardingId == null) {
            return false;
        }

        List<ONB_Fund_Item__c> funds = [
            SELECT Id
            FROM ONB_Fund_Item__c
            WHERE OnboardingId__c = :onboardingId
        ];

        List<ONB_Onboarding_Line__c> products = [
            SELECT Id
            FROM ONB_Onboarding_Line__c
            WHERE OnboardingId__c = :onboardingId
              AND Product2Id__c != null
              AND (Product2Id__r.Name = 'FX Spot' OR Product2Id__r.Name = 'Bonds')
        ];

        if (funds.isEmpty() || products.isEmpty()) {
            return false;
        }

        Set<Id> fundIds = new Set<Id>();
        for (ONB_Fund_Item__c fund : funds) {
            fundIds.add(fund.Id);
        }

        Set<Id> productIds = new Set<Id>();
        for (ONB_Onboarding_Line__c product : products) {
            productIds.add(product.Id);
        }

        Integer expectedCount = fundIds.size() * productIds.size();

        Set<String> existingPairs = new Set<String>();
        for (ONB_Fund_Product_Relsh__c rel : [
            SELECT FundItemId__c, ProductId__c
            FROM ONB_Fund_Product_Relsh__c
            WHERE FundItemId__c IN :fundIds
              AND ProductId__c IN :productIds
        ]) {
            if (rel.FundItemId__c != null && rel.ProductId__c != null) {
                existingPairs.add(String.valueOf(rel.FundItemId__c) + '|' + String.valueOf(rel.ProductId__c));
            }
        }

        return existingPairs.size() == expectedCount;
    }

    @AuraEnabled
    public static void applyMassFundProductAssignment(Id onboardingId, Boolean enabled) {
        if (onboardingId == null) {
            return;
        }

        List<ONB_Fund_Item__c> funds = [
            SELECT Id
            FROM ONB_Fund_Item__c
            WHERE OnboardingId__c = :onboardingId
        ];

        Set<Id> fundIds = new Set<Id>();
        for (ONB_Fund_Item__c fund : funds) {
            fundIds.add(fund.Id);
        }

        List<ONB_Onboarding_Line__c> products = [
            SELECT Id
            FROM ONB_Onboarding_Line__c
            WHERE OnboardingId__c = :onboardingId
              AND Product2Id__c != null
              AND (Product2Id__r.Name = 'FX Spot' OR Product2Id__r.Name = 'Bonds')
        ];

        Set<Id> productIds = new Set<Id>();
        for (ONB_Onboarding_Line__c product : products) {
            productIds.add(product.Id);
        }

        List<ONB_Fund_Product_Relsh__c> existing = new List<ONB_Fund_Product_Relsh__c>();
        if (!fundIds.isEmpty()) {
            existing = [
                SELECT Id, FundItemId__c, ProductId__c
                FROM ONB_Fund_Product_Relsh__c
                WHERE FundItemId__c IN :fundIds
            ];
        }

        if (!enabled) {
            if (!existing.isEmpty()) {
                delete existing;
            }
            return;
        }

        if (fundIds.isEmpty() || productIds.isEmpty()) {
            return;
        }

        Set<String> existingPairs = new Set<String>();
        for (ONB_Fund_Product_Relsh__c rel : existing) {
            if (rel.FundItemId__c != null && rel.ProductId__c != null) {
                existingPairs.add(String.valueOf(rel.FundItemId__c) + '|' + String.valueOf(rel.ProductId__c));
            }
        }

        List<ONB_Fund_Product_Relsh__c> toInsert = new List<ONB_Fund_Product_Relsh__c>();
        for (Id fundId : fundIds) {
            for (Id productId : productIds) {
                String key = String.valueOf(fundId) + '|' + String.valueOf(productId);
                if (!existingPairs.contains(key)) {
                    toInsert.add(new ONB_Fund_Product_Relsh__c(
                        FundItemId__c = fundId,
                        ProductId__c = productId
                    ));
                }
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }
}