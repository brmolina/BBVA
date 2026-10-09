public with sharing class DMT_Profitability_Helper {

    public static void callProfitabilityMatrixService(Map<String, Object> request, Map<String, Object> outMap) {
        HttpResponse response;
        String serviceName='DMT_ProfitabilityMatrix';
      
        iaso__GBL_integration_service__mdt serviceDetails = [SELECT iaso__Mock_LTA__c , iaso__Http_Method__c, iaso__Retrieve_Mock_LTA__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =:serviceName WITH SECURITY_ENFORCED LIMIT 1];
        if (Test.isRunningTest() || serviceDetails.iaso__Retrieve_Mock_LTA__c == true) {
            response = DMT_HPG_Utils.getMock(serviceName);
        } else {
            if (Test.isRunningTest() || serviceDetails.iaso__Retrieve_Mock_LTA__c == true) {
                response = DMT_HPG_Utils.getMock(serviceName);
            } else {
                response=DMT_Utils.callService(serviceName, request);
                //response = iaso.GBL_Integration_GenericService.invoke('DMT_ProfitabilityMatrix', requestStr);
            }
            
        }

        if( (response.getStatusCode() == 200 || response.getStatusCode() == 201) ){
            System.debug('*** Response OK');
            String bodyResponse = response.getBody();
            outMap.put('result', true);
            outMap.put('bodyResponse', bodyResponse );
            System.debug(response);
        } else {
            
            String bodyResponse = response.getBody();
            Map<String,Object> errorResponse = ( Map<String,Object>)JSON.deserializeUntyped(bodyResponse);
            String errorMsg = errorResponse.get('message')!= null ? (String) errorResponse.get('message') : 'Unknown';
            System.debug('*** Response KO: '+bodyResponse);
            System.debug('*** Response: '+errorResponse);

            outMap.put('result', false);
            outMap.put('messageTitle', 'External service call failed');
            outMap.put('message', 'Error '+response.getStatusCode()+':\r\n '+errorMsg);
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<DMT_Taxonomy_Values__c> getTaxonomyValues() {

        // Query the DMT_Taxonomy_Values__c object to fetch the relevant data
        List<DMT_Taxonomy_Values__c> taxonomyValues = [
            SELECT gf_catalog_atrb_val1_name_c__c,DMT_Value__c, DMT_Name__c, DMT_Catalog__c
             FROM DMT_Taxonomy_Values__c WHERE DMT_Catalog__c ='C204' AND DMT_Active__c=true
        ];
        

        return taxonomyValues;
    }
    
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> callOrderCatalogs(List<Map<String, Object>> items) {
        List<Object> normalizedItems = new List<Object>();
        for (Map<String, Object> item : items) {
            Map<String, Object> normalized = new Map<String, Object>();
            normalized.put('label', item.get('label'));
            normalized.put('value', item.get('value'));
            normalized.put('orden', item.get('orden'));
            normalizedItems.add(normalized);
        }
        Map<String, Object> inputMap = new Map<String, Object>{
            'data' => normalizedItems
        };
        Map<String, Object> outMap = new Map<String, Object>();
        orderCatalogs(inputMap, outMap);
        return outMap;
    }

    public static void orderCatalogs(Map<String, Object> inputMap,  Map<String, Object> outMap) {
        List<Object> catalogList = new List<Object>();
        for(String catalogKey:inputMap.keySet()){
            if(inputMap.get(catalogKey) instanceof List<Object>){

                List<Object> catalogValues = (List<Object>)inputMap.get(catalogKey);
                System.debug('Mi lista de '+catalogKey+' con valores: '+catalogValues);

                // Convertir a lista de envoltorios ordenables
                List<OrderWrapper> wrappers = new List<OrderWrapper>();
                for (Object obj : catalogValues) {
                    wrappers.add(new OrderWrapper(obj));
                }
                wrappers.sort();

                // Volver a dejar solo los objetos originales, ya ordenados
                List<Object> sortedCatalogValues = new List<Object>();
                for (OrderWrapper w : wrappers) {
                    sortedCatalogValues.add(w.original);
                }
                outMap.put(catalogKey, sortedCatalogValues);
                System.debug('Mi lista de '+catalogKey+' ordenada: '+sortedCatalogValues);
            }
        }
    }

    public class OrderWrapper implements Comparable {
        protected Object original;
        protected Integer orden;

    public OrderWrapper(Object obj) {
        this.original = obj;
        Map<String, Object> mapObj = (Map<String, Object>)obj;
        this.orden = mapObj.containsKey('orden') && mapObj.get('orden') != null && String.valueOf(mapObj.get('orden')).isNumeric()
        ? Integer.valueOf(String.valueOf(mapObj.get('orden')))
        : 2147483647 ;
    }

    public Integer compareTo(Object other) {
        OrderWrapper o = (OrderWrapper)other;
        if (this.orden == o.orden) return 0;
        if (this.orden > o.orden) return 1;
        return -1;
    }
}


    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> calculateIsPercentageValue(String axisX, String axisY, String axisCentral) {
        Map<String, Boolean> result = new Map<String, Boolean>{ 'x' => false, 'y' => false, 'c' => false };
        // Build a set of non-blank axis names to query
        Set<String> axisNames = new Set<String>();
        if (!String.isBlank(axisX)) axisNames.add(axisX);
        if (!String.isBlank(axisY)) axisNames.add(axisY);
        if (!String.isBlank(axisCentral)) axisNames.add(axisCentral);

        if (axisNames.isEmpty()) return result;

        List<DMT_Profitability_Axis__c> axes = [
            SELECT gf_axis_data_type_desc__c, gf_percentage_1_sign_type__c
            FROM DMT_Profitability_Axis__c
            WHERE gf_axis_data_type_desc__c IN :axisNames
        ];

        for (DMT_Profitability_Axis__c a : axes) {
            if (a.gf_axis_data_type_desc__c == axisX) result.put('x', a.gf_percentage_1_sign_type__c);
            if (a.gf_axis_data_type_desc__c == axisY) result.put('y', a.gf_percentage_1_sign_type__c);
            if (a.gf_axis_data_type_desc__c == axisCentral) result.put('c', a.gf_percentage_1_sign_type__c);
        }
        return result;
    }

    /**
    * @description retrives Passport__c record by Opportunity Id to check is obsoleted
    * @author BBVA DMT | 16-10-2025 
    * @param oppId 
    * @return Passport__c 
    **/
    @AuraEnabled
    public static Passport__c getPassportByOpp(String oppId) {
        System.debug('getPassportByOpp oppId => '+oppId);
        if (String.isBlank(oppId)) return null;
        return DMT_Passport_Selector.passportByIdOpportunity(oppId);
    }

    /**
    * @description Thin @AuraEnabled bridge invoked by the plain LWC dmt_profitabilityTestMain
    * (Scenarios calculator) to run the Profitability Matrix calculation, reusing the same
    * DMT_Profitability_Handler "callProfitabilityMatrix" Apex Remote action that OmniStudio
    * FlexCards used before their retirement (see DMT_ProfitabilityMatrix_Wrapper.createRequest
    * for the expected inputMap keys: oppId, prodId, version, axisX, axisY, axisCentral,
    * axisX_Id, axisY_Id, minX, maxX, minY, maxY, catalogRating, overrideFields).
    * @author BBVA DMT
    * @param inputMap flat map matching DMT_ProfitabilityMatrix_Wrapper.createRequest's contract
    * @return Map<String, Object> with result (Boolean) and either bodyResponse (String, JSON)
    *   when result = true, or messageTitle/message when result = false
    **/
    @AuraEnabled
    public static Map<String, Object> calculateProfitabilityMatrix(Map<String, Object> inputMap) {
        Map<String, Object> outMap = new Map<String, Object>();
        try {
            Map<String, Object> args = new Map<String, Object>{
                'input' => inputMap,
                'output' => outMap,
                'options' => new Map<String, Object>()
            };
            new DMT_Profitability_Handler().call('callProfitabilityMatrix', args);
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_Profitability_Helper', 'calculateProfitabilityMatrix', 'DMT', '');
            outMap.put('result', false);
            outMap.put('messageTitle', 'Error when calculating the profitability matrix');
            outMap.put('message', e.getMessage());
        }
        return outMap;
    }


    /**
    * @description Catalog ids consumed by the Profitability "Scenarios" tabs (dmt_profitabilityTestMain).
    * C204 = Internal Rating, C009 = External Rating, CD07 = Entific, H006 = Entity,
    * D971 = Client Type, C264 = Currency, C245 = Country Risk, H007 = Booking.
    **/
    private static final Set<String> PROFITABILITY_CATALOG_IDS = new Set<String>{
        'C204', 'C009', 'CD07', 'H006', 'D971', 'C264', 'C245', 'H007'
    };

    /* Rating catalogs must be ordered using orderCatalogs() based on the 'orden' attribute. */
    private static final Set<String> PROFITABILITY_RATING_CATALOG_IDS = new Set<String>{ 'C204', 'C009' };

    /* Catalogs whose label must be displayed as "value - label" (Entific and Entity). */
    private static final Set<String> PROFITABILITY_VALUE_LABEL_CATALOG_IDS = new Set<String>{ 'CD07', 'H006' };

    /* Catalogs whose label must be the raw DMT_Value__c code only (Currency 3-letter code). */
    private static final Set<String> PROFITABILITY_CODE_LABEL_CATALOG_IDS = new Set<String>{ 'C264' };

    /**
    * @description Returns the picklist options (label/value/orden) for every DMT_Taxonomy_Values__c
    * catalog used by the Profitability "Scenarios" tabs, in a single bulkified query.
    * Internal/External Rating catalogs (C204/C009) are returned already sorted via orderCatalogs().
    * The Entific (CD07) and Entity (H006) catalogs are labeled as "value - label".
    * @author BBVA DMT
    * @return Map<String, List<Map<String, Object>>> keyed by DMT_Catalog__c
    **/
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, Object>>> getProfitabilityCatalogValues() {
        Map<String, List<Map<String, Object>>> result = new Map<String, List<Map<String, Object>>>();

        List<DMT_Taxonomy_Values__c> taxonomyValues = [
            SELECT DMT_Catalog__c, DMT_Value__c, DMT_Name_EN__c, gf_catalog_atrb_val1_name_c__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c IN :PROFITABILITY_CATALOG_IDS AND DMT_Active__c = true
            ORDER BY DMT_Catalog__c, DMT_Name_EN__c
        ];

        for (DMT_Taxonomy_Values__c taxValue : taxonomyValues) {
            String labelValue;
            if (PROFITABILITY_VALUE_LABEL_CATALOG_IDS.contains(taxValue.DMT_Catalog__c)) {
                labelValue = String.valueOf(taxValue.DMT_Value__c) + ' - ' + String.valueOf(taxValue.DMT_Name_EN__c);
            } else if (PROFITABILITY_CODE_LABEL_CATALOG_IDS.contains(taxValue.DMT_Catalog__c)) {
                labelValue = taxValue.DMT_Value__c;
            } else {
                labelValue = taxValue.DMT_Name_EN__c;
            }

            Map<String, Object> option = new Map<String, Object>{
                'label' => labelValue,
                'value' => taxValue.DMT_Value__c,
                'orden' => taxValue.gf_catalog_atrb_val1_name_c__c
            };

            if (!result.containsKey(taxValue.DMT_Catalog__c)) {
                result.put(taxValue.DMT_Catalog__c, new List<Map<String, Object>>());
            }
            result.get(taxValue.DMT_Catalog__c).add(option);
        }

        // Sort rating catalogs (Internal/External Rating) using the shared orderCatalogs utility.
        Map<String, Object> ratingCatalogsToSort = new Map<String, Object>();
        for (String ratingCatalogId : PROFITABILITY_RATING_CATALOG_IDS) {
            if (result.containsKey(ratingCatalogId)) {
                ratingCatalogsToSort.put(ratingCatalogId, result.get(ratingCatalogId));
            }
        }
        if (!ratingCatalogsToSort.isEmpty()) {
            Map<String, Object> sortedRatingCatalogs = new Map<String, Object>();
            orderCatalogs(ratingCatalogsToSort, sortedRatingCatalogs);
            for (String ratingCatalogId : sortedRatingCatalogs.keySet()) {
                List<Object> sortedList = (List<Object>) sortedRatingCatalogs.get(ratingCatalogId);
                List<Map<String, Object>> sortedOptions = new List<Map<String, Object>>();
                for (Object sortedOption : sortedList) {
                    sortedOptions.add((Map<String, Object>) sortedOption);
                }
                result.put(ratingCatalogId, sortedOptions);
            }
        }

        return result;
    }

    /**
    * @description Returns the Entific->Entity (H287) and Entity->Booking (H291) taxonomy
    * relationships, keyed by the initial catalog value, reusing DMT_PicklistUtils.getTaxonomyRelationshipValues.
    * H287 is requested with formattedLabel = true so its Entity (final catalog) options are also
    * displayed as "value - label", consistent with the base Entity (H006) catalog list.
    * H291 is requested with formattedLabel = false (Booking labels are not formatted).
    * @author BBVA DMT
    * @return Map<String, Object> with keys 'H287' and 'H291', each a Map<String, List<Map<String, Object>>>
    **/
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getEntificEntityAndBookingRelationships() {
        Map<String, Object> result = new Map<String, Object>();
        result.put('H287', callTaxonomyRelationshipValues('H287', true));
        result.put('H291', callTaxonomyRelationshipValues('H291', false));
        return result;
    }

    /**
    * @description Invokes DMT_PicklistUtils (Callable) action 'getTaxonomyRelationshipValues' for a
    * single catalog id, returning the 'mapTaxonomyRelValuesFixed' output.
    * @author BBVA DMT
    * @param catalogId Taxonomy Relationship catalog id (e.g. 'H287', 'H291')
    * @param formattedLabel Whether the final catalog label should be formatted as "value - label"
    * @return Object the 'mapTaxonomyRelValuesFixed' output from DMT_PicklistUtils
    **/
    private static Object callTaxonomyRelationshipValues(String catalogId, Boolean formattedLabel) {
        Callable picklistUtils = (Callable) Type.forName('DMT_PicklistUtils').newInstance();
        Map<String, Object> input = new Map<String, Object>{
            'catalogId' => catalogId,
            'formattedLabel' => formattedLabel
        };
        Map<String, Object> output = new Map<String, Object>();
        picklistUtils.call('getTaxonomyRelationshipValues', new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => new Map<String, Object>()
        });
        return output.get('mapTaxonomyRelValuesFixed');
    }

    /**
    * @description Returns the Opportunities to list on the Profitability "Scenarios" selector,
    * depending on which toggle button is active (Current opportunities vs Basic opportunities).
    * - Current opportunities (isDraft = false): Opportunities with a Passport already requested,
    *   belonging either directly to the client (AccountId) or to any account in the same
    *   commercial group (Account.DES_Main_Parent__r.DES_Group_Code__c).
    * - Basic opportunities (isDraft = true): non-disclosed placeholder Opportunities with a
    *   Passport already requested.
    * @author BBVA DMT
    * @param clientId Salesforce Account Id of the selected client
    * @param groupCode Commercial group code (DES_Group_Code__c) of the selected client's group
    * @param isDraft false = Current opportunities, true = Basic opportunities
    * @return List<Opportunity>
    **/
    @AuraEnabled(cacheable=false)
    public static List<Opportunity> getOpportunitiesByType(String clientId, String groupCode, Boolean isDraft) {
        System.debug('getOpportunitiesByType isDraft => '+isDraft);
        List<Opportunity> opportunities = new List<Opportunity>();
        if (isDraft) {
            opportunities = [
                SELECT Id, Name, DMT_Opp_Id__c
                FROM Opportunity
                WHERE RecordType.DeveloperName = 'DMT_Opportunity'
                  AND DMT_Requested_Passport__c = true
                  AND dmt_isDraft_opp__c = true
                  AND StageName NOT IN ('Closed Won', 'Closed Lost')
                  AND Account.Name = 'non - disclosed'
                  AND Id IN (SELECT OpportunityId FROM OpportunityLineItem)
                WITH SECURITY_ENFORCED
            ];
            System.debug('getOpportunitiesByType opportunities => '+opportunities);
            return opportunities;
        }

            opportunities = [
                SELECT Id, Name, DMT_Opp_Id__c
                FROM Opportunity
                WHERE RecordType.DeveloperName = 'DMT_Opportunity'
                  AND DMT_Opp_Id__c != null
                  AND DMT_Requested_Passport__c = true
                  AND dmt_isDraft_opp__c = false
                  AND StageName NOT IN ('Closed Won', 'Closed Lost')
                  AND (Account.g_customer_id__c = :clientId OR Account.DES_Main_Parent__r.DES_Group_Code__c = :groupCode)
                  AND Id IN (SELECT OpportunityId FROM OpportunityLineItem)
                WITH SECURITY_ENFORCED
            ];
            System.debug('getOpportunitiesByType opportunities => '+opportunities);
            return opportunities;
    }

    /**
    * @description Wrapper combining the Opportunity/client fields and product (OpportunityLineItem)
    * options needed by the Profitability "Scenarios" tabs, for a single selected Opportunity.
    * @author BBVA DMT
    **/
    public class OpportunityDetailsWrapper {
        // Opportunity fields
        @AuraEnabled public String entity;
        @AuraEnabled public String entific;

        // DMT_Opportunity_Client__c fields (related to the Opportunity via DMT_MDE_Opportunity__c)
        @AuraEnabled public String internalRating;
        @AuraEnabled public String externalRating;
        @AuraEnabled public Decimal scoring;
        @AuraEnabled public String clientType;

        // Derived from Opportunity.DMT_DATE_Initial_Date__c / DMT_DATE_Maturity_Date__c
        @AuraEnabled public Integer oppTerm;

        @AuraEnabled public List<ProductWrapper> products;
    }

    /**
    * @description Wrapper exposing the OpportunityLineItem (product) fields needed by the
    * Profitability "Scenarios" Product/Amortization/Tenor tabs.
    * @author BBVA DMT
    **/
    public class ProductWrapper {
        // Salesforce OpportunityLineItem Id used by the LWC selector.
        @AuraEnabled public Id productId;
        // Business identifier required as prodId by the profitability service.
        @AuraEnabled public String groupPriorityOpportunityId;
        @AuraEnabled public String name;
        @AuraEnabled public String booking;
        @AuraEnabled public String currencyOli;
        @AuraEnabled public String countryRating;
        @AuraEnabled public String amortizationType;
        @AuraEnabled public String paymentFrequency;
        @AuraEnabled public Date initialDate;
        @AuraEnabled public Date maturityDate;
        // 'Line' -> Scenario calculation is unavailable for this product on the LWC side.
        @AuraEnabled public String lineOneOffDeal;
        // The 6 fields below (+ tenorDate) are sourced from the related DMT_Opportunity_Tenor__c
        // record (see getLatestEligibleTenorByProduct), not from OpportunityLineItem.
        @AuraEnabled public Decimal nominalAmount;
        @AuraEnabled public Decimal nominalFb;
        @AuraEnabled public Decimal spreadAmount;
        @AuraEnabled public Decimal spreadFb;
        @AuraEnabled public Decimal accrualfee;
        @AuraEnabled public Decimal nonaccrualfee;
        @AuraEnabled public Date tenorDate;
    }

    /**
    * @description Returns the Opportunity/client fields and product (OpportunityLineItem) options
    * for the Opportunity selected on the Profitability "Scenarios" selector.
    * @author BBVA DMT
    * @param oppId Selected Opportunity Id
    * @return OpportunityDetailsWrapper
    **/
    @AuraEnabled(cacheable=true)
    public static OpportunityDetailsWrapper getOpportunityDetails(Id oppId) {
        Opportunity opp = [
            SELECT Id, DMT_Entity__c, Entific__c, DMT_DATE_Initial_Date__c, DMT_DATE_Maturity_Date__c
            FROM Opportunity
            WHERE Id = :oppId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        List<DMT_Opportunity_Client__c> oppClients = [
            SELECT Id, g_upd_lmscl_internal_ratg_type__c, External_Rating__c, DMT_Scoring__c, Counterpart__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :oppId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        List<OpportunityLineItem> lineItems = [
            SELECT Id, Name, g_branch_id__c, g_currency_id__c, gf_country_rating__c, gf_amortization_type__c,
                 gf_payment_frequency__c, gf_initial_date__c, gf_maturity_date__c, DMT_Line_Oneoffdeal__c,
                 gf_group_priority_opportunity_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
            WITH SECURITY_ENFORCED
        ];

        Set<Id> lineItemIds = new Set<Id>();
        for (OpportunityLineItem lineItem : lineItems) {
            lineItemIds.add(lineItem.Id);
        }
        Map<Id, DMT_Opportunity_Tenor__c> latestTenorByProduct = getLatestEligibleTenorByProduct(lineItemIds);

        OpportunityDetailsWrapper result = new OpportunityDetailsWrapper();
        result.entity = opp.DMT_Entity__c;
        result.entific = opp.Entific__c;
        result.oppTerm = calculateOppTerm(opp.DMT_DATE_Initial_Date__c, opp.DMT_DATE_Maturity_Date__c);

        if (!oppClients.isEmpty()) {
            DMT_Opportunity_Client__c oppClient = oppClients[0];
            result.internalRating = oppClient.g_upd_lmscl_internal_ratg_type__c;
            result.externalRating = oppClient.External_Rating__c;
            result.scoring = oppClient.DMT_Scoring__c;
            result.clientType = oppClient.Counterpart__c;
        }

        result.products = new List<ProductWrapper>();
        for (OpportunityLineItem lineItem : lineItems) {
            ProductWrapper product = new ProductWrapper();
            product.productId = lineItem.Id;
            product.groupPriorityOpportunityId = lineItem.gf_group_priority_opportunity_id__c;
            product.name = lineItem.Name;
            product.booking = lineItem.g_branch_id__c;
            product.currencyOli = lineItem.g_currency_id__c;
            product.countryRating = lineItem.gf_country_rating__c;
            product.amortizationType = lineItem.gf_amortization_type__c;
            product.paymentFrequency = lineItem.gf_payment_frequency__c;
            product.initialDate = lineItem.gf_initial_date__c;
            product.maturityDate = lineItem.gf_maturity_date__c;
            product.lineOneOffDeal = lineItem.DMT_Line_Oneoffdeal__c;

            DMT_Opportunity_Tenor__c tenor = latestTenorByProduct.get(lineItem.Id);
            if (tenor != null) {
                product.nominalAmount = tenor.gj_nominal_amount_db__c;
                product.nominalFb = tenor.gf_nominal_amount_fb__c;
                product.spreadAmount = tenor.gf_spread_db__c;
                product.spreadFb = tenor.gf_spread_fb__c;
                product.accrualfee = tenor.gf_accrual_fees_bp__c;
                product.nonaccrualfee = tenor.gf_non_accrual_fees_bp__c;
                product.tenorDate = tenor.gf_tenor_date__c;
            }
            result.products.add(product);
        }

        return result;
    }

    /**
    * @description Returns, per OpportunityLineItem (product) Id, the single "current" eligible
    * DMT_Opportunity_Tenor__c record to use on the Profitability "Scenarios" Tenor tab: eligible
    * rows must have a non-zero drawn/undrawn notional and belong to a product whose amortization
    * type is not 'User-Defined' (the Tenor tab is hidden in that case); when several eligible
    * rows exist for the same product, the one with the latest (most future) gf_tenor_date__c wins.
    * @author BBVA DMT
    * @param lineItemIds OpportunityLineItem Ids to look up tenors for
    * @return Map<Id, DMT_Opportunity_Tenor__c> keyed by DMT_Opportunity_Product__c
    **/
    private static Map<Id, DMT_Opportunity_Tenor__c> getLatestEligibleTenorByProduct(Set<Id> lineItemIds) {
        Map<Id, DMT_Opportunity_Tenor__c> latestTenorByProduct = new Map<Id, DMT_Opportunity_Tenor__c>();
        if (lineItemIds.isEmpty()) {
            return latestTenorByProduct;
        }

        List<DMT_Opportunity_Tenor__c> tenors = [
            SELECT Id, DMT_Opportunity_Product__c, gf_tenor_date__c, gj_nominal_amount_db__c,
                   gf_nominal_amount_fb__c, gf_spread_db__c, gf_spread_fb__c, gf_accrual_fees_bp__c,
                   gf_non_accrual_fees_bp__c
            FROM DMT_Opportunity_Tenor__c
            WHERE DMT_Opportunity_Product__c IN :lineItemIds
              AND (gj_nominal_amount_db__c != 0 OR gf_nominal_amount_fb__c != 0)
              AND DMT_Opportunity_Product__r.gf_amortization_type__c != 'User-Defined'
            WITH SECURITY_ENFORCED
            ORDER BY gf_tenor_date__c DESC
        ];

        for (DMT_Opportunity_Tenor__c tenor : tenors) {
            if (!latestTenorByProduct.containsKey(tenor.DMT_Opportunity_Product__c)) {
                latestTenorByProduct.put(tenor.DMT_Opportunity_Product__c, tenor);
            }
        }
        return latestTenorByProduct;
    }

    /**
    * @description Computes the Term (in months, floored) between an Opportunity's Initial and
    * Maturity dates: ROUND(DATEDIFF(initialDate, maturityDate) / 30, 0, FLOOR).
    * @author BBVA DMT
    * @param initialDate Opportunity.DMT_DATE_Initial_Date__c
    * @param maturityDate Opportunity.DMT_DATE_Maturity_Date__c
    * @return Integer term in months (floored), or null if either date is missing
    **/
    private static Integer calculateOppTerm(Date initialDate, Date maturityDate) {
        if (initialDate == null || maturityDate == null) {
            return null;
        }
        Integer days = initialDate.daysBetween(maturityDate);
        return (Integer) Math.floor(days / 30.0);
    }
}