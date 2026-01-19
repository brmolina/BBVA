/**
------------------------------------------------------------------------------------------------
@Name     KPI_MainTableController_Test
@Author   Global Hub
@Date     Created: 2023-09-11
------------------------------------------------------------------------------------------------
@Description Test class for KPI_MainTableController_Test
------------------------------------------------------------------------------------------------
@Changes
| 2023-09-11 ivan.garces.contractor@bbva.com
            Class Creation
-----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods, PMD.ExcessiveParameterList, sf:NPathComplexity, PMD.ApexCRUDViolation, PMD.NcssTypeCount, PMD.EmptyStatementBlock, PMD.NcssMethodCount, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.ApexSOQLInjection, PMD.FormalParameterNamingConventions, PMD.ExcessiveClassLength , PMD.ExcessivePublicCount, PMD.AvoidGlobalModifier, PMD.UnusedLocalVariable, PMD.ApexAssertionsShouldIncludeMessage, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
@isTest
public with sharing class KPI_MainTableController_Test {
    private class KPI_FinantialCustomersMock implements HttpCalloutMock {
        private Integer statusCode;
        public KPI_FinantialCustomersMock (Integer statusCode) {
            this.statusCode = statusCode;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            res.setBody(JSON.serialize(new Map<String, Object>{
                'test' => 'test'
            }));
            res.setStatusCode(statusCode);

            return res;
        }
    }

    @IsTest
    static void testPutFinantialCustomer() {
        Test.setMock(HttpCalloutMock.class, new KPI_FinantialCustomersMock(204));

        Test.startTest();
        Map<String, Object> res = KPI_MainTableController.putFinantialCustomer('payload');
        Test.stopTest();

        Assert.isTrue((Boolean) res.get('success'), '');
    }
}