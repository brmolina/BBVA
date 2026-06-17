public with sharing class ONB_FundItemController {
    public class FundItemRow {
        @AuraEnabled public Id fundId;
        @AuraEnabled public String fundName;
        @AuraEnabled public String fundType;
        @AuraEnabled public String leiId;
        @AuraEnabled public String cif;
        @AuraEnabled public Boolean leiPendingCreate;
        @AuraEnabled public Id onboardingId;
        @AuraEnabled public Integer linesCount;
        @AuraEnabled public Boolean hasLinkedContract;
        @AuraEnabled public Boolean hasLinkedProduct;
    }

    @AuraEnabled(cacheable=true)
    public static List<FundItemRow> getFundItems(Id onboardingId) {
        if (onboardingId == null) return new List<FundItemRow>();

        List<ONB_Fund_Item__c> funds = [
            SELECT Id, ONB_FundName__c, ONB_Fund_Type__c, lei_id__c, ONB_CIF__c, ONB_LEI_Pending_Create__c, OnboardingId__c, ContractId__c
            FROM ONB_Fund_Item__c
            WHERE OnboardingId__c = :onboardingId
            ORDER BY ONB_Fund_Type__c DESC
        ];

        Map<Id, Integer> linesCountByFundId = new Map<Id, Integer>();
        Map<Id, Integer> productCountByFundId = new Map<Id, Integer>();

        if (!funds.isEmpty()) {
            Set<Id> fundIds = new Set<Id>();
            for (ONB_Fund_Item__c fund : funds) {
                fundIds.add(fund.Id);
                linesCountByFundId.put(fund.Id, 0);
                productCountByFundId.put(fund.Id, 0);
            }

            for (AggregateResult ar : [
                SELECT FundItemId__c fundId, COUNT(Id) total
                FROM ONB_Line__c
                WHERE FundItemId__c IN :fundIds
                GROUP BY FundItemId__c
            ]) {
                linesCountByFundId.put(
                    (Id) ar.get('fundId'),
                    Integer.valueOf(String.valueOf(ar.get('total')))
                );
            }

            for (AggregateResult ar : [
                SELECT FundItemId__c fundId, COUNT(Id) total
                FROM ONB_Fund_Product_Relsh__c
                WHERE FundItemId__c IN :fundIds
                GROUP BY FundItemId__c
            ]) {
                productCountByFundId.put(
                    (Id) ar.get('fundId'),
                    Integer.valueOf(String.valueOf(ar.get('total')))
                );
            }
        }

        List<FundItemRow> result = new List<FundItemRow>();

        for (ONB_Fund_Item__c fund : funds) {
            FundItemRow row = new FundItemRow();
            row.fundId = fund.Id;
            row.fundName = fund.ONB_FundName__c;
            row.fundType = fund.ONB_Fund_Type__c;
            row.leiId = fund.lei_id__c;
            row.onboardingId = fund.OnboardingId__c;
            row.cif = fund.ONB_CIF__c;
            row.leiPendingCreate = fund.ONB_LEI_Pending_Create__c;
            row.linesCount = linesCountByFundId.get(fund.Id);
            row.hasLinkedContract = fund.ContractId__c != null;
            row.hasLinkedProduct = (productCountByFundId.get(fund.Id) != null) && productCountByFundId.get(fund.Id) > 0;
            result.add(row);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<ONB_Line__c> getLineItems(Id fundId) {
        if (fundId == null) return new List<ONB_Line__c>();

        return [
            SELECT Id, Line_Type__c, ONB_Line_Subtype__c, Amount__c, ONB_Currency__c, ONB_Maturity__c
            FROM ONB_Line__c
            WHERE FundItemId__c = :fundId
            ORDER BY CreatedDate ASC
        ];
    }

    public class FundModalDTO {
        @AuraEnabled public List<ONB_Fund_Item__c> funds;
        @AuraEnabled public List<Id> preselectedFundIds;
    }

    @AuraEnabled(cacheable=true)
    public static FundModalDTO getFundItemsForContract(Id onboardingId, Id contractId) {
        FundModalDTO dto = new FundModalDTO();
        dto.funds = new List<ONB_Fund_Item__c>();
        dto.preselectedFundIds = new List<Id>();

        if (onboardingId == null || contractId == null) return dto;

        List<ONB_Fund_Item__c> rows = [
            SELECT Id, ONB_FundName__c, ONB_Fund_Type__c, lei_id__c, OnboardingId__c, ONB_CIF__c, ONB_LEI_Pending_Create__c, ContractId__c
            FROM ONB_Fund_Item__c
            WHERE OnboardingId__c = :onboardingId
              AND (ContractId__c = NULL OR ContractId__c = :contractId)
            ORDER BY ONB_Fund_Type__c DESC
        ];

        dto.funds = rows;
        for (ONB_Fund_Item__c f : rows) {
            if (f.ContractId__c == contractId) dto.preselectedFundIds.add(f.Id);
        }
        return dto;
    }

    @AuraEnabled
    public static void saveFundsForContract(Id contractId, List<Id> selectedFundIds) {
        if (contractId == null) return;
        if (selectedFundIds == null) selectedFundIds = new List<Id>();
        Set<Id> selected = new Set<Id>(selectedFundIds);

        List<ONB_Fund_Item__c> currentlyLinked = [
            SELECT Id, ContractId__c
            FROM ONB_Fund_Item__c
            WHERE ContractId__c = :contractId
        ];

        List<ONB_Fund_Item__c> toUpdate = new List<ONB_Fund_Item__c>();

        for (ONB_Fund_Item__c f : currentlyLinked) {
            if (!selected.contains(f.Id)) {
                f.ContractId__c = null;
                toUpdate.add(f);
            }
        }

        if (!selected.isEmpty()) {
            List<ONB_Fund_Item__c> selectedRows = [
                SELECT Id, ContractId__c
                FROM ONB_Fund_Item__c
                WHERE Id IN :selected
            ];

            for (ONB_Fund_Item__c f : selectedRows) {
                if (f.ContractId__c != null && f.ContractId__c != contractId) {
                    throw new AuraHandledException('Some selected funds are already associated with another contract.');
                }
            }

            for (ONB_Fund_Item__c f : selectedRows) {
                f.ContractId__c = contractId;
                toUpdate.add(f);
            }
        }

        if (!toUpdate.isEmpty()) update toUpdate;
    }

    public class CloneFundResult {
        @AuraEnabled public Id newFundId;
        @AuraEnabled public Integer clonedLines;
    }

    @AuraEnabled
    public static CloneFundResult cloneFundWithLines(Id fundId) {
        if (fundId == null) {
            throw new AuraHandledException('Fund Id is required.');
        }

        ONB_Fund_Item__c src = [
            SELECT Id, ONB_FundName__c, ONB_Fund_Type__c, lei_id__c, ONB_CIF__c, ONB_LEI_Pending_Create__c, OnboardingId__c
            FROM ONB_Fund_Item__c
            WHERE Id = :fundId
            LIMIT 1
        ];

        ONB_Fund_Item__c dst = new ONB_Fund_Item__c();
        dst.ONB_FundName__c = src.ONB_FundName__c;
        dst.ONB_Fund_Type__c = src.ONB_Fund_Type__c;
        dst.lei_id__c = src.lei_id__c;
        dst.ONB_CIF__c = src.ONB_CIF__c;
        dst.ONB_LEI_Pending_Create__c = src.ONB_LEI_Pending_Create__c;
        dst.OnboardingId__c = src.OnboardingId__c;

        insert dst;

        List<ONB_Line__c> autoCreatedLines = [
            SELECT Id
            FROM ONB_Line__c
            WHERE FundItemId__c = :dst.Id
            AND ONB_Line_Subtype__c IN ('DVP', 'Free Delivery')
        ];
        if (!autoCreatedLines.isEmpty()) {
            delete autoCreatedLines;
        }

        List<ONB_Line__c> srcLines = [
            SELECT Id,
                   Line_Type__c,
                   ONB_Line_Subtype__c,
                   Amount__c,
                   ONB_Currency__c,
                   ONB_Maturity__c
            FROM ONB_Line__c
            WHERE FundItemId__c = :src.Id
            ORDER BY CreatedDate ASC
        ];

        List<ONB_Line__c> dstLines = new List<ONB_Line__c>();
        for (ONB_Line__c l : srcLines) {
            ONB_Line__c nl = new ONB_Line__c();
            nl.FundItemId__c = dst.Id;
            nl.Line_Type__c = l.Line_Type__c;
            nl.ONB_Line_Subtype__c = l.ONB_Line_Subtype__c;
            nl.Amount__c = l.Amount__c;
            nl.ONB_Currency__c = l.ONB_Currency__c;
            nl.ONB_Maturity__c = l.ONB_Maturity__c;
            dstLines.add(nl);
        }

        if (!dstLines.isEmpty()) {
            insert dstLines;
        }

        CloneFundResult res = new CloneFundResult();
        res.newFundId = dst.Id;
        res.clonedLines = dstLines.size();
        return res;
    }
}