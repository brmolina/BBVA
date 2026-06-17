public with sharing class DMT_Profitability_utils {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getProductDetailsByIds(List<String> productIds, String oppId) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        if (productIds == null || productIds.isEmpty()) {
            return results;
        }

        for (OpportunityLineItem oli : DMT_Opportunity_Selector.getOpportunityLineItemsById(productIds, oppId)) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('Id', oli.Id);
            row.put('Name', oli.DMT_TXT_ProductNameOLI__c);
            row.put('InitialDate', oli.gf_initial_date__c);
            row.put('MaturityDate', oli.gf_maturity_date__c);
            row.put('gf_group_priority_opportunity_id__c', oli.gf_group_priority_opportunity_id__c);
            row.put('Currency', oli.g_currency_id__c);

            if (oli.Opportunity != null) {  
                row.put('OppName', oli.Opportunity.Name);
                row.put('OppInitialDate', oli.Opportunity.DMT_DATE_Initial_Date__c);
                row.put('OppMaturityDate', oli.Opportunity.DMT_DATE_Maturity_Date__c);
                row.put('OppCurrency', oli.Opportunity.DMT_CurrencyText__c);
            }

            results.add(row);
        }
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Object>> getNominalAmountsByOpportunityLineItemIds(List<String> productIds, String oppId) {
        Map<String, Map<String, Object>> result = new Map<String, Map<String, Object>>();

        if (productIds == null || productIds.isEmpty()) {
            return result;
        }

        for (DMT_Opportunity_Tenor__c tenor : DMT_View_Selector.getProfitabilityTenors(productIds, oppId)) {
            String oliId = tenor.DMT_Opportunity_Product__r.gf_group_priority_opportunity_id__c;
            if (!result.containsKey(oliId)) {
                result.put(oliId, new Map<String, Object>{
                    'nominalFb' => tenor.gf_nominal_amount_fb__c,
                    'nominalDb' => tenor.gj_nominal_amount_db__c
                });
            }
        }
        return result;
    }

    /**
     * @description Converts nominalFb and nominalDb values from each product's currency
     *              to the Opportunity's currency using DMT_Currency.convert.
     * @param productDetails List of product detail maps, each containing at minimum:
     *        'gf_group_priority_opportunity_id__c' (key linking to nominalAmounts),
     *        'Currency' (source currency of the product),
     *        'OppCurrency' (target currency of the opportunity).
     * @param nominalAmounts Map keyed by gf_group_priority_opportunity_id__c,
     *        each value is a map with 'nominalFb' and 'nominalDb' as Decimal.
     * @return Map<String, Map<String, Object>> same structure as nominalAmounts but
     *         with 'nominalFb' and 'nominalDb' converted to OppCurrency.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Object>> convertNominalsToOppCurrency(
        List<Map<String, Object>> productDetails,
        Map<String, Map<String, Object>> nominalAmounts
    ) {
        Map<String, Map<String, Object>> result = new Map<String, Map<String, Object>>();

        if (productDetails == null || productDetails.isEmpty() || nominalAmounts == null || nominalAmounts.isEmpty()) {
            return result;
        }

        // Build a lookup map: gf_group_priority_opportunity_id__c -> { Currency, OppCurrency }
        Map<String, Map<String, String>> currencyByProductKey = new Map<String, Map<String, String>>();
        for (Map<String, Object> detail : productDetails) {
            String productKey = (String) detail.get('gf_group_priority_opportunity_id__c');
            String fromCurrency = (String) detail.get('Currency');
            String toCurrency   = (String) detail.get('OppCurrency');
            if (productKey != null && fromCurrency != null && toCurrency != null) {
                currencyByProductKey.put(productKey, new Map<String, String>{
                    'from' => fromCurrency,
                    'to'   => toCurrency
                });
            }
        }

        Decimal totalNominalFb = 0;
        Decimal totalNominalDb = 0;
        String oppCurrency = null;
        Map<String, DMT_Currency.Wrapper> exchangeRatesCache = new Map<String, DMT_Currency.Wrapper>();

        for (String productKey : nominalAmounts.keySet()) {
            Map<String, Object> nominals = nominalAmounts.get(productKey);
            Map<String, String> currencies = currencyByProductKey.get(productKey);

            if (currencies == null) {
                // No currency info found; keep original values
                result.put(productKey, nominals);
                Decimal rawFb = nominals.get('nominalFb') != null ? (Decimal) nominals.get('nominalFb') : 0;
                Decimal rawDb = nominals.get('nominalDb') != null ? (Decimal) nominals.get('nominalDb') : 0;
                totalNominalFb += rawFb;
                totalNominalDb += rawDb;
                continue;
            }

            String fromCurrency = currencies.get('from');
            String toCurrency   = currencies.get('to');
            if (oppCurrency == null) {
                oppCurrency = toCurrency;
            }

            Decimal nominalFb = nominals.get('nominalFb') != null ? (Decimal) nominals.get('nominalFb') : 0;
            Decimal nominalDb = nominals.get('nominalDb') != null ? (Decimal) nominals.get('nominalDb') : 0;

            Decimal convertedFb = DMT_Currency.convert(nominalFb, fromCurrency, toCurrency);
            Decimal convertedDb = DMT_Currency.convert(nominalDb, fromCurrency, toCurrency);

            totalNominalFb += (convertedFb != null ? convertedFb : 0);
            totalNominalDb += (convertedDb != null ? convertedDb : 0);

            result.put(productKey, new Map<String, Object>{
                'nominalFb'    => convertedFb,
                'nominalDb'    => convertedDb,
                'fromCurrency' => fromCurrency,
                'toCurrency'   => toCurrency
            });
        }

        // Add totals entry aggregating all products in OppCurrency
        result.put('TOTAL', new Map<String, Object>{
            'nominalFb'  => totalNominalFb,
            'nominalDb'  => totalNominalDb,
            'toCurrency' => oppCurrency
        });

        return result;
    }


    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRwaRegLinkInfo(String oppId) {
        Map<String, Object> result = new Map<String, Object>{
            'enabled' => false,
            'explanationId' => ''
        };
        if (String.isBlank(oppId)) {
            return result;
        }
        Opportunity opp = DMT_Opportunity_Selector.getOpportunity(oppId);
        if (opp == null || String.isBlank(opp.DMT_branch_id_c__c)) {
            return result;
        }
        String branchId = opp.DMT_branch_id_c__c;
        String developerName = branchId.replace('-', '_');
        DMT_Taxonomy_Value_link__mdt record = DMT_Taxonomy_Value_link__mdt.getInstance(developerName);
        if (record != null && record.with_link__c == true) {
            result.put('enabled', true);
            result.put('explanationId', opp.DMT_Opp_Id__c != null ? opp.DMT_Opp_Id__c : '');
            result.put('entific', opp.Entific__c != null ? opp.Entific__c : '');
        }
        return result;
    }

}