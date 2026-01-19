/**
────────────────────────────────────────────────────────────────────
Obligation service class
────────────────────────────────────────────────────────────────────
@author     torcuato.tejada.contractor@bbva.com
@modifiedBy
@version     1.0
@created     2023-02-23
@modified
@systemLayer
────────────────────────────────────────────────────────────────────
@changes
────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods, PMD.ExcessiveParameterList, sf:NPathComplexity, PMD.ApexCRUDViolation, PMD.NcssTypeCount, PMD.EmptyStatementBlock, PMD.NcssMethodCount, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.ApexSOQLInjection, PMD.FormalParameterNamingConventions, PMD.ExcessiveClassLength , PMD.ExcessivePublicCount, PMD.AvoidGlobalModifier, PMD.UnusedLocalVariable, PMD.ApexAssertionsShouldIncludeMessage, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
public class KPI_Obligation {
    /**
    @description Call service and return wrapper
    */
    public static KPI_Obligation_Wrapper getObligation(Map<String, Object> request) {
        KPI_Obligation_Wrapper res = new KPI_Obligation_Wrapper();

        final HttpResponse response = KPI_Utils.callService('KPI_getObligation', request);

        switch on response.getStatusCode() {
            when 200 {
                String responseBody = response.getBody().replaceAll('(\\d{2})/(\\d{2})/(\\d{4})', '$3-$2-$1');
                responseBody = responseBody.replaceAll('"currency"', '"curr"');
                responseBody = responseBody.replaceAll('"date"', '"obligationDate"');

                final Object obj = System.JSON.deserialize(responseBody, KPI_Obligation_Wrapper.class);
                res = (KPI_Obligation_Wrapper) obj;
                res.success = true;
            }
            when else {
                res.success = false;
                res.message = response.getBody();
            }
        }
        system.debug('response : ' + res);
        return res;
    }

    /**
    @description Call service and return wrapper
    */
    public static Map<String, Object> postObligation(Map<String, Object> request) {
        Map<String, Object> res = new Map<String, Object>{ 'success' => false };

        final HttpResponse response = KPI_Utils.callService('KPI_postObligation', request);

        try {
            switch on response.getStatusCode() {
                when 201 {
                    res.put('success', true);
                }
                when else {
                    res.put('success', false);
                    res.put('message', response.getBody());
                }
            }
        } catch (Exception e) {
            res.put('success', false);
            res.put('message', response.getBody());
        }
        return res;
    }

    /**
    @description Call service and return map (empty repsonse)
    */
    public static Map<String, Object> putObligation(Map<String, Object> request) {
        Map<String, Object> res = new Map<String, Object>{ 'success' => false };

        final HttpResponse response = KPI_Utils.callService('KPI_putObligation', request);

        switch on response.getStatusCode() {
            when 204 {
                res.put('success', true);
            }
            when else {
                res.put('success', false);
                res.put('message', response.getBody());
            }
        }
        return res;
    }

    /**
    @description Call service and return map (empty response)
    */
    public static Map<String, Object> deleteObligation(Map<String, Object> request) {
        Map<String, Object> res = new Map<String, Object>{ 'success' => false };
        final HttpResponse response = KPI_Utils.callService('KPI_deleteObligation', request);

        switch on response.getStatusCode() {
            when 204 {
                res.put('success', true);
            }
            when else {
                res.put('success', false);
                res.put('message', response.getBody());
            }
        }
        return res;
    }
}