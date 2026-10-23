public without sharing class DMT_Profitability_utils {

    private static final String RWA_ENABLED_KEY = 'enabled';
    private static final String RWA_EXPLANATION_ID_KEY = 'explanationId';
    private static final String RWA_ENTIFIC_KEY = 'entific';
    private static final String RWA_BASE_URL_KEY = 'baseUrl';
    private static final String RWA_BASE_URL_INTEGRATED = 'https://calculadoraholding-int.work-03.nextgen.igrupobbva/index.html';
    private static final String RWA_BASE_URL_PRODUCTION = 'https://calculadoraholding.live-03.nextgen.igrupobbva/index.html';
    // CIBGLOBALD-4711 - Profitability detail CSV download (getProfitabilityDetailFile).
    private static final String DETAIL_SERVICE_NAME = 'DMT_ProfitabilityDownloadDetail';
    @TestVisible
    private static final String DETAIL_NO_CALCULATION_MESSAGE = 'There is no profitability calculation for this Opportunity.';
    @TestVisible
    private static final String DETAIL_NOT_AVAILABLE_MESSAGE = 'The profitability detail is not available for this Opportunity.';
    @TestVisible
    private static final String DETAIL_FAILED_MESSAGE = 'The profitability detail could not be downloaded.';

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

    /**
     * CIBGLOBALD-4711 - Gets the Profitability detail file (monthly amortization table) of an Opportunity for
     * the 'Profitability Detail' button of the Profitability modal (LWC dmt_profitability_view
     * .downloadProfitabilityDetail, called from dmt_passport_modal). Nothing is recalculated or stored.
     *
     * Callout: Epsilon service profitability_download_detail (APX), exposed by the ASO API DmtDownloadDetailsV0
     * as GET /dmt/v0/download-details?opportunityId=<Opportunity.DMT_Opp_Id__c>; custom metadata
     * iaso__GBL_integration_service__mdt record DMT_ProfitabilityDownloadDetail (custom setting
     * iaso__GBL_Rest_Services_Url__c DMT_ProfitabilityDownloadDetail_INT, iaso__Enable_Log__c writes
     * iaso__GBL_Application_Log__c); call path getProfitabilityDetailFile -> DMT_Utils.callService ->
     * DMT_HPG_Utils.callService. Response 200: {data: [{file: CSV in base64, opportunityVersion}]}.
     *
     * @param oppId Opportunity Id.
     * @return Map with 'success', 'fileBase64', 'fileName' and 'message' (error text or null).
     */
    @AuraEnabled
    public static Map<String, Object> getProfitabilityDetailFile(String oppId) {
        Map<String, Object> result;
        try {
            Opportunity opp = String.isBlank(oppId) ? null : [SELECT Id, DMT_Opp_Id__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
            if (opp == null || String.isBlank(opp.DMT_Opp_Id__c)) {
                result = buildDetailFileError(DETAIL_NO_CALCULATION_MESSAGE);
            } else {
                String externalOppId = opp.DMT_Opp_Id__c.trim();
                HttpResponse response = DMT_Utils.callService(DETAIL_SERVICE_NAME, new Map<String, Object>{ 'opportunityId' => externalOppId });
                result = parseDetailFileResponse(response, externalOppId);
            }
        } catch (Exception e) {
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_Profitability_utils', 'getProfitabilityDetailFile', 'DMT', 'Opportunity'));
            result = buildDetailFileError(DETAIL_FAILED_MESSAGE);
        }
        DMT_AsyncOrchestrator.flush();
        return result;
    }

    /**
     * CIBGLOBALD-4711 - Reads the DMT_ProfitabilityDownloadDetail response. 204, 404, an empty data list or a
     * blank file mean there is no detail; other non-2xx codes return the backend message
     * (messages[0].message, e.g. code functionalError on 400) when present. A 200 body that is not the
     * documented JSON throws, so the caller logs it.
     */
    @TestVisible
    private static Map<String, Object> parseDetailFileResponse(HttpResponse response, String externalOppId) {
        Integer statusCode = response != null ? response.getStatusCode() : 0;
        String body = response != null ? response.getBody() : null;
        if (statusCode == 204 || statusCode == 404) {
            return buildDetailFileError(DETAIL_NOT_AVAILABLE_MESSAGE);
        }
        if (statusCode < 200 || statusCode >= 300) {
            String backendMessage = getBackendMessage(body);
            return buildDetailFileError(String.isBlank(backendMessage)
                ? DETAIL_FAILED_MESSAGE + ' (status ' + statusCode + ')'
                : DETAIL_FAILED_MESSAGE + ' ' + backendMessage);
        }
        if (String.isBlank(body)) {
            return buildDetailFileError(DETAIL_NOT_AVAILABLE_MESSAGE);
        }
        List<Object> dataList = (List<Object>) ((Map<String, Object>) JSON.deserializeUntyped(body)).get('data');
        Map<String, Object> detail = dataList == null || dataList.isEmpty() ? null : (Map<String, Object>) dataList[0];
        String fileBase64 = detail == null ? null : (String) detail.get('file');
        if (String.isBlank(fileBase64)) {
            return buildDetailFileError(DETAIL_NOT_AVAILABLE_MESSAGE);
        }
        String version = detail.get('opportunityVersion') == null ? '' : String.valueOf(detail.get('opportunityVersion'));
        return new Map<String, Object>{
            'success' => true,
            'fileBase64' => fileBase64,
            'fileName' => 'ProfitabilityDetail_' + externalOppId + (String.isBlank(version) ? '' : '_v' + version) + '.csv',
            'message' => null
        };
    }

    // CIBGLOBALD-4711 - messages[0].message of an ASO error body, or null when the body has another shape.
    private static String getBackendMessage(String body) {
        try {
            List<Object> messages = (List<Object>) ((Map<String, Object>) JSON.deserializeUntyped(body)).get('messages');
            return messages == null || messages.isEmpty() ? null : (String) ((Map<String, Object>) messages[0]).get('message');
        } catch (Exception e) {
            return null;
        }
    }

    private static Map<String, Object> buildDetailFileError(String message) {
        return new Map<String, Object>{ 'success' => false, 'message' => message };
    }

    /**
     * CIBGLOBALD-4713 - Renders the Profitability section of an Opportunity with the same renderer as
     * the NBC views (DMT_RendererFactory 'Profitability' -> DMT_ProfitabilityRenderer ->
     * DMT_OppProfitabilityRenderer), building only the LineDataWrapper fields that renderer reads.
     * Used by the Profitability modal of the Passport (LWC dmt_profitability_view inside dmt_passport_modal).
     *
     * Data: Opportunity from DMT_View_Selector.getOpportunityWithRelatedData (same query as
     * DMT_ViewController.loadRelatedData), features from the saved Passport JSON
     * (DMT_ViewController.getFeatures, Passport__c.DMT_Passport_Save__c), product data from
     * preloadProfitabilityData. Nothing is recalculated.
     *
     * Callout (only when withExternalRwa is true, the modal's 'External RWA calculate' button):
     * service DMTO_ExternalOrchestrators, custom metadata iaso__GBL_integration_service__mdt record
     * DMTO_ExternalOrchestrators, call path renderProfitabilityHtml -> callExternalOrchestrators ->
     * DMT_Utils.callService -> DMT_HPG_Utils.callService. The result is only rendered, never stored.
     * RWA calculator link: getRwaRegLinkInfo (DMT_Taxonomy_Value_link__mdt by Opportunity branch).
     *
     * @param oppId           Opportunity Id.
     * @param itemsImg        JSON list of DMT_ViewController.ItemImgB64 with the chart image generated in
     *                        the browser (dmt_profitability_chart.getChartImage); blank uses the server chart.
     * @param withExternalRwa true to call the External RWA service and add the 'External RWA 1Y' column.
     * @return Map with 'html', 'hasData' (profitability results exist), 'fileName' (PDF name) and
     *         'message' (error text or null).
     */
    @AuraEnabled
    public static Map<String, Object> renderProfitabilityHtml(String oppId, String itemsImg, Boolean withExternalRwa) {
        Map<String, Object> response = new Map<String, Object>{
            'html' => '',
            'hasData' => false,
            'message' => null
        };
        try {
            DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

            // The callout goes first: no DML or async enqueue may precede it in this transaction.
            if (withExternalRwa == true) {
                Map<String, Object> rwaResult = callExternalOrchestrators(oppId);
                if (rwaResult.get('success') == true) {
                    data.profitabilityAprsByProductId = parseAprsCalculation((String) rwaResult.get('responseBody'));
                } else {
                    response.put('message', String.valueOf(rwaResult.get('message')));
                }
            }

            data.objectApiName = 'Opportunity';
            data.opportunity = DMT_View_Selector.getOpportunityWithRelatedData(oppId, 'DMT_Opportunity');
            data.recordTypeId = data.opportunity.RecordTypeId;
            data.currencyIsoCode = data.opportunity.CurrencyIsoCode;
            data.featuresList = DMT_ViewController.getFeatures(oppId);
            preloadProfitabilityData(data);

            data.isImg64 = String.isNotBlank(itemsImg);
            if (data.isImg64) {
                data.itemImgBase64 = (List<DMT_ViewController.ItemImgB64>) JSON.deserialize(itemsImg, List<DMT_ViewController.ItemImgB64>.class);
            }
            data.profitabilityRwaLinkInfo = getRwaRegLinkInfo(oppId);
            data.profitabilityShowRwaAction = true;

            response.put('hasData', !getProfitabilityProductIds(data.featuresList).isEmpty());
            response.put('fileName', 'Profitability_' + (String.isBlank(data.opportunity.DMT_Opp_Id__c) ? String.valueOf(data.opportunity.Id) : data.opportunity.DMT_Opp_Id__c) + '.pdf');
            response.put('html', DMT_RendererFactory.getRenderer('Profitability').renderHtml(data));
        } catch (Exception e) {
            DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DMT_Profitability_utils', 'renderProfitabilityHtml', 'DMT', 'Opportunity'));
            response.put('message', 'Unable to load the profitability view.');
        }
        DMT_AsyncOrchestrator.flush();
        return response;
    }

    /**
     * CIBGLOBALD-4713 - Loads the product details, nominal amounts and converted nominals of the
     * profitability results into the wrapper, so the profitability renderers read them without
     * issuing queries. Shared by DMT_ViewController.loadRelatedData and renderProfitabilityHtml.
     * @param data Wrapper with opportunity and featuresList already set.
     */
    public static void preloadProfitabilityData(DMT_ViewController.LineDataWrapper data) {
        List<String> profitabilityProductIdList = getProfitabilityProductIds(data.featuresList);
        if (profitabilityProductIdList.isEmpty()) {
            return;
        }
        data.profitabilityProductDetailsList = getProductDetailsByIds(profitabilityProductIdList, data.opportunity.Id);
        data.profitabilityNominalAmountsMap = getNominalAmountsByOpportunityLineItemIds(profitabilityProductIdList, data.opportunity.Id);
        data.profitabilityNominalAmountsConvertedMap = convertNominalsToOppCurrency(data.profitabilityProductDetailsList, data.profitabilityNominalAmountsMap);
    }

    // CIBGLOBALD-4713 - productIds of every profitability result row in the Passport features.
    private static List<String> getProfitabilityProductIds(List<Map<String, Object>> featuresList) {
        Set<String> productIds = new Set<String>();
        for (Map<String, Object> feat : featuresList) {
            if (!feat.containsKey('profitability')) {
                continue;
            }
            Map<String, Object> profitability = (Map<String, Object>) feat.get('profitability');
            if (profitability == null || !profitability.containsKey('results')) {
                continue;
            }
            for (Object resultObj : (List<Object>) profitability.get('results')) {
                Map<String, Object> row = (Map<String, Object>) resultObj;
                if (row.containsKey('productId') && row.get('productId') != null) {
                    productIds.add(String.valueOf(row.get('productId')));
                }
            }
        }
        return new List<String>(productIds);
    }

    // CIBGLOBALD-4713 - Reads data.aprsCalculator[].aprCalculator {productId, aprCalculation} from the
    // DMTO_ExternalOrchestrators response (same mapping as the former modal code in dmt_profitability_chart).
    @TestVisible
    private static Map<String, Object> parseAprsCalculation(String responseBody) {
        Map<String, Object> aprsByProductId = new Map<String, Object>();
        if (String.isBlank(responseBody)) {
            return aprsByProductId;
        }
        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            Map<String, Object> bodyData = (Map<String, Object>) body.get('data');
            List<Object> aprsCalculatorList = bodyData != null ? (List<Object>) bodyData.get('aprsCalculator') : null;
            if (aprsCalculatorList == null) {
                return aprsByProductId;
            }
            for (Object item : aprsCalculatorList) {
                Map<String, Object> aprCalculator = (Map<String, Object>) ((Map<String, Object>) item).get('aprCalculator');
                if (aprCalculator != null && aprCalculator.get('productId') != null) {
                    aprsByProductId.put(String.valueOf(aprCalculator.get('productId')), aprCalculator.get('aprCalculation'));
                }
            }
        } catch (Exception e) {
            // Unexpected response shape: render without the column, like the former modal code.
            System.debug(LoggingLevel.WARN, 'Unexpected DMTO_ExternalOrchestrators response: ' + e.getMessage());
        }
        return aprsByProductId;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Object>> getUnderlyingDetailsByIds(List<String> underlyingIds) {
        Map<String, Map<String, Object>> result = new Map<String, Map<String, Object>>();

        if (underlyingIds == null || underlyingIds.isEmpty()) {
            return result;
        }

        Integer orderIndex = 0;
        for (DMT_Underlying__c ul : [
            SELECT Id, Name, DMT_Drawn_Reference_Amount__c, DMT_Undrawn_Reference_Amount__c
            FROM DMT_Underlying__c
            WHERE Id IN :underlyingIds
            ORDER BY CreatedDate ASC, Id ASC
        ]) {
            result.put(ul.Id, new Map<String, Object>{
                'Id'         => ul.Id,
                'Name'       => ul.Name,
                'nominalDb'  => ul.DMT_Drawn_Reference_Amount__c,
                'nominalFb'  => ul.DMT_Undrawn_Reference_Amount__c,
                'orderIndex' => orderIndex
            });
            orderIndex++;
        }

        return result;
    }

}