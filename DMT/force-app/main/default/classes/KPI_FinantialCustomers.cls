/**
────────────────────────────────────────────────────────────────────
FinantialCustomers service class
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
public class KPI_FinantialCustomers {
    /**
    @description Call service and return wrapper
    */
    public static KPI_FinantialCustomers_Wrapper getFinantialCustomers(Map<String, Object> request) {
        KPI_FinantialCustomers_Wrapper res = new KPI_FinantialCustomers_Wrapper();

        final HttpResponse response = KPI_Utils.callService('KPI_getFinancialCustomer', request);
        String responseReplace = '';

        switch on response.getStatusCode() {
            when 200 {
                responseReplace = response.getBody().replace('"group"', '"clientGroup"');
                responseReplace = responseReplace.replace('"currency"', '"productCurrency"');

                final Object obj = System.JSON.deserialize(responseReplace, KPI_FinantialCustomers_Wrapper.class);
                res = (KPI_FinantialCustomers_Wrapper) obj;
                res.success = res.data.isEmpty() ? false : true;
                res.message = res.data.isEmpty() ? 'Respuesta vacia' : '';
            }
            when else {
                res.success = false;
                res.message = response.getBody();
            }
        }
        return res;
    }

    /**
    @description Call service and return map (empty repsonse)
    */
    public static Map<String, Object> putFinantialCustomer(Map<String, Object> request) {
        Map<String, Object> res = new Map<String, Object>{ 'success' => false };

        final HttpResponse response = KPI_Utils.callService('KPI_putFinantialCustomer', request);

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