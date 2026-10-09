public with sharing class DMT_Profitability_utils {

    private static final String RWA_ENABLED_KEY = 'enabled';
    private static final String RWA_EXPLANATION_ID_KEY = 'explanationId';
    private static final String RWA_ENTIFIC_KEY = 'entific';
    private static final String RWA_BASE_URL_KEY = 'baseUrl';
    private static final String RWA_BASE_URL_INTEGRATED = 'https://calculadoraholding-int.work-03.nextgen.igrupobbva/index.html';
    private static final String RWA_BASE_URL_PRODUCTION = 'https://calculadoraholding.live-03.nextgen.igrupobbva/index.html';

    private static Boolean isIntegratedOrg() {
        Boolean isSandboxOrg = false;

        try {
            Organization orgInfo = [SELECT IsSandbox FROM Organization LIMIT 1];
            isSandboxOrg = orgInfo.IsSandbox;
        } catch (Exception ex) {
            // Fallback if Organization query is not available in some execution contexts.
            String orgDomain = URL.getOrgDomainUrl().toExternalForm().toLowerCase();
            isSandboxOrg = orgDomain.contains('--');
        }

        return isSandboxOrg;
    }

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
        String rwaBaseUrl = isIntegratedOrg() ? RWA_BASE_URL_INTEGRATED : RWA_BASE_URL_PRODUCTION;

        Map<String, Object> response = new Map<String, Object>{
            RWA_ENABLED_KEY => false,
            RWA_EXPLANATION_ID_KEY => '',
            RWA_ENTIFIC_KEY => '',
            RWA_BASE_URL_KEY => rwaBaseUrl
        };

        if (String.isBlank(oppId)) {
            return response;
        }

        Opportunity opp = [
            SELECT Id, DMT_branch_id_c__c, Entific__c, DMT_Opp_Id__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        if (String.isBlank(opp.DMT_branch_id_c__c)) {
            return response;
        }

        String opportunityBranch = opp.DMT_branch_id_c__c.trim().toUpperCase();

        for (DMT_Taxonomy_Value_link__mdt taxonomyValue : [
            SELECT MasterLabel, with_link__c
            FROM DMT_Taxonomy_Value_link__mdt
            WHERE with_link__c = true
        ]) {
            if (String.isBlank(taxonomyValue.MasterLabel)) {
                continue;
            }

            String branchLabel = taxonomyValue.MasterLabel.trim().toUpperCase();
            if (branchLabel != opportunityBranch) {
                continue;
            }

            response.put(RWA_ENABLED_KEY, true);
            response.put(RWA_EXPLANATION_ID_KEY, String.isBlank(opp.DMT_Opp_Id__c) ? '' : opp.DMT_Opp_Id__c.trim());
            response.put(RWA_ENTIFIC_KEY, String.isBlank(opp.Entific__c) ? '' : opp.Entific__c.trim());
            return response;
        }

        return response;
    }

    @AuraEnabled
    public static Map<String, Object> callExternalOrchestrators(String oppId) {
        Map<String, Object> result = new Map<String, Object>{
            'success' => false,
            'statusCode' => 0,
            'message' => 'Unable to execute external orchestrators service.'
        };

        if (String.isBlank(oppId)) {
            result.put('message', 'Opportunity Id is required.');
            return result;
        }

        Opportunity opp = [
            SELECT Id, DMT_Opp_Id__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        if (String.isBlank(opp.DMT_Opp_Id__c)) {
            result.put('message', 'Opportunity external Id (DMT_Opp_Id__c) is empty.');
            return result;
        }

        Map<String, Object> request = new Map<String, Object>{
            'aprsType' => 'APRS',
            'opportunityId' => opp.DMT_Opp_Id__c
        };

        HttpResponse response = DMT_Utils.callService('DMTO_ExternalOrchestrators', request);
        Integer statusCode = response != null ? response.getStatusCode() : 0;

        result.put('statusCode', statusCode);
        result.put('responseBody', response != null ? response.getBody() : null);

        if (statusCode >= 200 && statusCode < 300) {
            result.put('success', true);
            result.put('message', 'External orchestrators service executed successfully.');
        } else {
            result.put('message', 'External orchestrators service failed with status code ' + statusCode + '.');
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Object>> getUnderlyingDetailsByIds(List<String> underlyingIds) {
        Map<String, Map<String, Object>> result = new Map<String, Map<String, Object>>();

        if (underlyingIds == null || underlyingIds.isEmpty()) {
            return result;
        }

        for (DMT_Underlying__c ul : [
            SELECT Id, Name, DMT_Drawn_Reference_Amount__c, DMT_Undrawn_Reference_Amount__c
            FROM DMT_Underlying__c
            WHERE Id IN :underlyingIds
        ]) {
            result.put(ul.Id, new Map<String, Object>{
                'Id'        => ul.Id,
                'Name'      => ul.Name,
                'nominalDb' => ul.DMT_Drawn_Reference_Amount__c,
                'nominalFb' => ul.DMT_Undrawn_Reference_Amount__c
            });
        }

        return result;
    }

}