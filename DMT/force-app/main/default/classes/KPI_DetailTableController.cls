/**
────────────────────────────────────────────────────────────────────
KPI_MainTableController
Controller class for KPI_MainTable Aura Component
────────────────────────────────────────────────────────────────────
@author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
@modifiedBy
@version     1.0
@created     2023-02-24
@modified
@systemLayer
────────────────────────────────────────────────────────────────────
@changes
────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods, PMD.ExcessiveParameterList, sf:NPathComplexity, PMD.ApexCRUDViolation, PMD.NcssTypeCount, PMD.EmptyStatementBlock, PMD.NcssMethodCount, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.ApexSOQLInjection, PMD.FormalParameterNamingConventions, PMD.ExcessiveClassLength , PMD.ExcessivePublicCount, PMD.AvoidGlobalModifier, PMD.UnusedLocalVariable, PMD.ApexAssertionsShouldIncludeMessage, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
public with sharing class KPI_DetailTableController {
    /**
    @description Method that returns obligations
    @param catalogType KPI_TYPE, CRITERIA_NAME, BUSINESS_AREA, INDUSTRY_GROUP, INDUSTRY_ACTIVITY
    @return Map<String, Object> {success, options [{id, name}]}
    */
    @AuraEnabled
    public static KPI_Obligation_Wrapper refreshObligation(String contract, String category, String timeStamp) {
        return getObligation(contract, category, timeStamp);
    }

    /**
    @description Method that returns obligations
    @param catalogType KPI_TYPE, CRITERIA_NAME, BUSINESS_AREA, INDUSTRY_GROUP, INDUSTRY_ACTIVITY
    @return Map<String, Object> {success, options [{id, name}]}
    */
    @AuraEnabled(cacheable=true)
    public static KPI_Obligation_Wrapper getObligation(String contract, String category, String timeStamp) {
        String queryString = '?';

        // Contract id
        if (!String.isEmpty(contract)) {
            queryString += 'contract.id=' + contract + '&';
        }

        // Sustainable Subcategory
        if (!String.isEmpty(category)) {
            queryString += 'sustainableSubcategory.id=' + category + '&';
        }
        queryString += 'nocache=' + timeStamp;
        final Map<String, Object> request = new Map<String, Object>{ 'queryString' => queryString };
        return KPI_Obligation.getObligation(request);
    }

    /**
    @description Method that returns a catalog (from a service call)
    @param catalogType KPI_TYPE, CRITERIA_NAME, BUSINESS_AREA, INDUSTRY_GROUP, INDUSTRY_ACTIVITY
    @return Map<String, Object> {success, options [{id, name}]}
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCatalog(String catalogId) {
        final Map<string, Object> res = new Map<string, Object>{ 'success' => false };
        final Map<String, Object> request = new Map<String, Object>{ 'catalogId' => catalogId };

        try {
            HttpResponse response = KPI_Utils.callService('KPI_getCatalogIdRecords', request);
            if (new List<Integer>{ 200, 201 }.contains(response.getStatusCode())) {
                final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                final List<Map<String, Object>> options = new List<Map<String, Object>>();

                for (Object objData : (List<Object>) responseMap.get('data')) {
                    final Map<String, Object> data = (Map<String, Object>) objData;
                    final Map<String, Object> option = new Map<String, Object>{ 'label' => data.get('description'), 'value' => data.get('id') };
                    options.add(option);
                }
                res.put('success', true);
                res.put('options', options);
            }
        } catch (Exception e) {
            res.put('errorMessage', e.getMessage());
        }

        return res;
    }

    /**
    @description Method that returns obligations
    @param jsonString Json to send in the call
    @return Map<String, Object> {success}
    */
    @AuraEnabled
    public static Map<String, Object> postObligation(String insertRequest) {
        Map<String, Object> res = new Map<string, Object>{ 'success' => true };
        if (insertRequest != null) {
            final String payload = insertRequest.replaceAll('(\\d{4})-(\\d{2})-(\\d{2})(T[0-9:\\.]*Z)?', '$1-$2-$3');
            final Map<String, Object> request = new Map<String, Object>{ 'payload' => payload };
            res = KPI_Obligation.postObligation(request);
        }

        return res;
    }

    /**
    @description Method that returns obligations
    @param jsonString Json to send in the call
    @return Map<String, Object> {success}
    */
    @AuraEnabled
    public static Map<String, Object> putObligation(String updateRequest) {
        Map<String, Object> res = new Map<string, Object>{ 'success' => true };
        if (updateRequest != null) {
            final String payload = updateRequest.replaceAll('(\\d{4})-(\\d{2})-(\\d{2})(T[0-9:\\.]*Z)?', '$1-$2-$3');
            final Map<String, Object> request = new Map<String, Object>{ 'payload' => payload };
            res = KPI_Obligation.putObligation(request);
        }
        return res;
    }

    /**
    @description Method that delete obligation
    @param jsonString Json to send in the call
    @return Map<String, Object> {success}
    */
    @AuraEnabled
    public static Map<String, Object> deleteObligation(String scaleId) {
        final String queryString = '?actions.triggers.scale.id=' + scaleId;
        final Map<String, Object> request = new Map<String, Object>{ 'queryString' => queryString };
        return KPI_Obligation.deleteObligation(request);
    }
}