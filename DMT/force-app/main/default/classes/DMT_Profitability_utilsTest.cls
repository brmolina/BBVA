@isTest
public with sharing class DMT_Profitability_utilsTest {

    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();

    @testSetup
    static void setupData() {

        // CIBGLOBALD-4711 - Group Account instead of generateOpportunity(): its generateAccount() sets
        // Account.Past2_FY_Corp_Synd_Lending_amount__c, which is not createable for every running user.
        // Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Account account = DMT_Test_DataFactory.generateGroupAccount('Profitability Test Group', null, null);
        Opportunity opp = DMT_Test_DataFactory.generateOpportunityForAccount(account.Id);
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2,pricebookEntry,opp);
        DMT_Opportunity_Tenor__c tenor = DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
       
    }

    @isTest
    static void testGetProductDetailsByIds() {
        // OLI created in testSetup
        OpportunityLineItem oli = [SELECT Id, OpportunityId, gf_group_priority_opportunity_id__c FROM OpportunityLineItem LIMIT 1];

        // Call the method
        List<Map<String, Object>> results = DMT_profitability_utils.getProductDetailsByIds(new List<String>{oli.gf_group_priority_opportunity_id__c}, oli.OpportunityId);

        Assert.areEqual(1, results.size(), 'One record expected');
        Assert.areEqual(oli.Id, results[0].get('Id'));
        Assert.isTrue(results[0].containsKey('Name'), 'Product name expected');
        Assert.isTrue(results[0].containsKey('InitialDate'), 'InitialDate expected');
        Assert.isTrue(results[0].containsKey('MaturityDate'), 'MaturityDate expected');
        Assert.isTrue(results[0].containsKey('OppInitialDate'), 'OppInitialDate expected');
        Assert.isTrue(results[0].containsKey('OppMaturityDate'), 'OppMaturityDate expected');
    }

    @isTest
    static void testGetProductDetailsByIds_Empty() {
        List<Map<String, Object>> results = DMT_profitability_utils.getProductDetailsByIds(new List<String>(), null);
        Assert.areEqual(0, results.size(), 'No Ids must return an empty result');
    }

    @isTest
    static void testGetNominalAmountsByOpportunityLineItemIds() {
        OpportunityLineItem oli = [SELECT Id, OpportunityId, gf_group_priority_opportunity_id__c FROM OpportunityLineItem LIMIT 1];

        Map<String, Map<String, Object>> results = DMT_profitability_utils.getNominalAmountsByOpportunityLineItemIds(new List<String>{oli.gf_group_priority_opportunity_id__c}, oli.OpportunityId);

        Assert.areNotEqual(null, results, 'Result must not be null');
    }

    @isTest
    static void testGetNominalAmountsByOpportunityLineItemIds_Empty() {
        Map<String, Map<String, Object>> results = DMT_profitability_utils.getNominalAmountsByOpportunityLineItemIds(new List<String>(), null);
        Assert.areEqual(0, results.size(), 'No Ids must return an empty result');
    }

    @isTest
    static void testConvertNominalsToOppCurrency() {
        // EUR->EUR avoids depending on exchange rate data in the org
        String productKey = 'PROD-001';

        List<Map<String, Object>> productDetails = new List<Map<String, Object>>{
            new Map<String, Object>{
                'gf_group_priority_opportunity_id__c' => productKey,
                'Currency'    => 'EUR',
                'OppCurrency' => 'EUR'
            }
        };

        Map<String, Map<String, Object>> nominalAmounts = new Map<String, Map<String, Object>>{
            productKey => new Map<String, Object>{
                'nominalFb' => 1000.0,
                'nominalDb' => 500.0
            }
        };

        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.convertNominalsToOppCurrency(productDetails, nominalAmounts);
        Test.stopTest();

        // Entries expected for the product and for TOTAL
        Assert.isTrue(result.containsKey(productKey), 'Product entry expected');
        Assert.isTrue(result.containsKey('TOTAL'), 'TOTAL entry expected');

        Map<String, Object> productResult = result.get(productKey);
        Assert.areEqual(1000.0, (Decimal) productResult.get('nominalFb'), 'nominalFb must be kept in EUR->EUR');
        Assert.areEqual(500.0,  (Decimal) productResult.get('nominalDb'), 'nominalDb must be kept in EUR->EUR');
        Assert.areEqual('EUR', (String) productResult.get('fromCurrency'));
        Assert.areEqual('EUR', (String) productResult.get('toCurrency'));

        Map<String, Object> total = result.get('TOTAL');
        Assert.areEqual(1000.0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb must be the sum');
        Assert.areEqual(500.0,  (Decimal) total.get('nominalDb'), 'TOTAL nominalDb must be the sum');
        Assert.areEqual('EUR', (String) total.get('toCurrency'), 'TOTAL toCurrency must be the Opportunity currency');
    }

    @isTest
    static void testConvertNominalsToOppCurrency_Empty() {
        // Both inputs empty must return an empty map
        Map<String, Map<String, Object>> resultEmpty = DMT_Profitability_utils.convertNominalsToOppCurrency(
            new List<Map<String, Object>>(),
            new Map<String, Map<String, Object>>()
        );
        Assert.areEqual(0, resultEmpty.size(), 'Empty inputs must return an empty map');

        // productDetails null must also return an empty map
        Map<String, Map<String, Object>> resultNull = DMT_Profitability_utils.convertNominalsToOppCurrency(
            null,
            null
        );
        Assert.areEqual(0, resultNull.size(), 'Null inputs must return an empty map');
    }

    @isTest
    static void testConvertNominalsToOppCurrency_MissingCurrencyInfo() {
        // Product in nominalAmounts with a key not in productDetails -> currencies == null
        List<Map<String, Object>> productDetails = new List<Map<String, Object>>{
            new Map<String, Object>{
                'gf_group_priority_opportunity_id__c' => 'DIFFERENT-KEY',
                'Currency'    => 'EUR',
                'OppCurrency' => 'EUR'
            }
        };

        Map<String, Map<String, Object>> nominalAmounts = new Map<String, Map<String, Object>>{
            'PROD-NO-CURRENCY' => new Map<String, Object>{
                'nominalFb' => 3000.0,
                'nominalDb' => 1500.0
            }
        };

        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.convertNominalsToOppCurrency(productDetails, nominalAmounts);
        Test.stopTest();

        Assert.isTrue(result.containsKey('PROD-NO-CURRENCY'), 'Entry expected for a product without currency info');
        Assert.isTrue(result.containsKey('TOTAL'), 'TOTAL entry expected');
        Map<String, Object> total = result.get('TOTAL');
        Assert.areEqual(3000.0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb must be the original value');
        Assert.areEqual(1500.0, (Decimal) total.get('nominalDb'), 'TOTAL nominalDb must be the original value');
    }

    @isTest
    static void testConvertNominalsToOppCurrency_NullNominalsNoCurrencyInfo() {
        // Null nominals + no currency info -> covers the null ternary branches in the currencies == null block
        List<Map<String, Object>> productDetails = new List<Map<String, Object>>{
            new Map<String, Object>{
                'gf_group_priority_opportunity_id__c' => 'DIFFERENT-KEY',
                'Currency'    => 'EUR',
                'OppCurrency' => 'EUR'
            }
        };

        Map<String, Map<String, Object>> nominalAmounts = new Map<String, Map<String, Object>>{
            'PROD-NULL-NOMINALS' => new Map<String, Object>{
                'nominalFb' => null,
                'nominalDb' => null
            }
        };

        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.convertNominalsToOppCurrency(productDetails, nominalAmounts);
        Test.stopTest();

        Assert.isTrue(result.containsKey('PROD-NULL-NOMINALS'), 'Entry expected for a product with null nominals');
        Assert.isTrue(result.containsKey('TOTAL'), 'TOTAL entry expected');
        Map<String, Object> total = result.get('TOTAL');
        Assert.areEqual(0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb must be 0 with null nominals');
        Assert.areEqual(0, (Decimal) total.get('nominalDb'), 'TOTAL nominalDb must be 0 with null nominals');
    }

    @isTest
    static void testConvertNominalsToOppCurrency_NullNominalsWithCurrency() {
        // Null nominals with currency info -> covers the null ternary branches in the main path
        String productKey = 'PROD-NULL-MAIN';

        List<Map<String, Object>> productDetails = new List<Map<String, Object>>{
            new Map<String, Object>{
                'gf_group_priority_opportunity_id__c' => productKey,
                'Currency'    => 'EUR',
                'OppCurrency' => 'EUR'
            }
        };

        Map<String, Map<String, Object>> nominalAmounts = new Map<String, Map<String, Object>>{
            productKey => new Map<String, Object>{
                'nominalFb' => null,
                'nominalDb' => null
            }
        };

        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.convertNominalsToOppCurrency(productDetails, nominalAmounts);
        Test.stopTest();

        Assert.isTrue(result.containsKey(productKey), 'Product entry expected');
        Assert.isTrue(result.containsKey('TOTAL'), 'TOTAL entry expected');
        Map<String, Object> total = result.get('TOTAL');
        Assert.areEqual(0, (Decimal) total.get('nominalFb'), 'TOTAL nominalFb must be 0');
        Assert.areEqual(0, (Decimal) total.get('nominalDb'), 'TOTAL nominalDb must be 0');
    }

    @isTest
    static void testGetRwaRegLinkInfo_BlankOppId() {
        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.getRwaRegLinkInfo(null);
        Test.stopTest();

        Assert.areEqual(false, (Boolean) result.get('enabled'), 'Null oppId must not enable the link');
        Assert.areEqual('', (String) result.get('explanationId'), 'Null oppId must return an empty explanationId');
        Assert.areEqual('', (String) result.get('entific'), 'Null oppId must return an empty entific');
    }

    @isTest
    static void testGetRwaRegLinkInfo_NoBranchValues() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        // Empty branch data to validate the default return.
        opp.DMT_branch_id_c__c = null;
        oli.g_branch_id__c = null;
        update new List<SObject>{ opp, oli };

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.getRwaRegLinkInfo(opp.Id);
        Test.stopTest();

        Assert.areEqual(false, (Boolean) result.get('enabled'), 'No branch on Opportunity or OLI must not enable the link');
        Assert.areEqual('', (String) result.get('explanationId'), 'No match must return an empty explanationId');
        Assert.areEqual('', (String) result.get('entific'), 'No match must return an empty entific');
    }

    @isTest
    static void testCallExternalOrchestrators_BlankOppId() {
        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.callExternalOrchestrators(null);
        Test.stopTest();

        Assert.areEqual(false, (Boolean) result.get('success'));
        Assert.areEqual('Opportunity Id is required.', (String) result.get('message'));
    }

    @isTest
    static void testCallExternalOrchestrators_Success() {
        Opportunity opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity LIMIT 1];
        opp.DMT_Opp_Id__c = 'ESCD25OPP00000001ES';
        update opp;

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.callExternalOrchestrators(opp.Id);
        Test.stopTest();

        Assert.areEqual(true, (Boolean) result.get('success'));
        Assert.areEqual(201, (Integer) result.get('statusCode'));
    }

    @isTest
    static void testGetUnderlyingDetailsByIds_Empty() {
        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.getUnderlyingDetailsByIds(new List<String>());
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result must not be null');
        Assert.areEqual(0, result.size(), 'Empty list must return an empty map');
    }

    @isTest
    static void testGetUnderlyingDetailsByIds_Success() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        DMT_Underlying__c underlying = DMT_UTIL.createUnderlyingRecord(oli.Id, new Map<Schema.SObjectField, Object>{
            DMT_Underlying__c.Name => 'Underlying Test',
            DMT_Underlying__c.DMT_Drawn_Reference_Amount__c => 1250.5,
            DMT_Underlying__c.DMT_Undrawn_Reference_Amount__c => 349.25
        });

        Test.startTest();
        Map<String, Map<String, Object>> result = DMT_Profitability_utils.getUnderlyingDetailsByIds(
            new List<String>{ underlying.Id }
        );
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'The requested underlying expected');
        Assert.isTrue(result.containsKey(underlying.Id), 'Underlying key expected');

        Map<String, Object> row = result.get(underlying.Id);
        Assert.areEqual(underlying.Id, (String) row.get('Id'));
        Assert.areEqual('Underlying Test', (String) row.get('Name'));
        Assert.areEqual(1250.5, (Decimal) row.get('nominalDb'));
        Assert.areEqual(349.25, (Decimal) row.get('nominalFb'));
    }

    // CIBGLOBALD-4713 - Saved Passport JSON with one profitability feature (summary row + one product row).
    private static String buildPassportJson(String productId) {
        Map<String, Object> profitability = new Map<String, Object>{
            'results' => new List<Object>{
                new Map<String, Object>{ 'rorc' => 0.12, 'raroec' => 0.08, 'regulatoryEad' => 100.0 },
                new Map<String, Object>{ 'productId' => productId, 'rorc' => 0.11, 'raroec' => 0.07, 'regulatoryApr' => 50.0 }
            },
            'audit' => new Map<String, Object>{ 'rorcThreshold' => 0.10, 'raroecThreshold' => 0.08 }
        };
        return JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'features' => new List<Object>{
                    new Map<String, Object>{ 'name' => 'Profitability Engine', 'profitability' => profitability }
                }
            }
        });
    }

    @isTest
    static void testRenderProfitabilityHtml_WithData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id, gf_group_priority_opportunity_id__c FROM OpportunityLineItem LIMIT 1];
        String productId = oli.gf_group_priority_opportunity_id__c != null ? oli.gf_group_priority_opportunity_id__c : String.valueOf(oli.Id);
        DMT_Test_DataFactory.generatePassport(opp.Id, buildPassportJson(productId));

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.renderProfitabilityHtml(opp.Id, '[{"imgB64":"iVBORw0KGgoAAAANSUhEUg=="}]', false);
        Test.stopTest();

        String html = (String) result.get('html');
        Assert.isNull(result.get('message'), 'No error message expected: ' + result.get('message'));
        Assert.isTrue((Boolean) result.get('hasData'), 'Profitability results must be reported');
        Assert.isTrue(html.contains('data-dmt-table-block="summary"'), 'Renderer HTML expected: ' + html.left(300));
        Assert.isTrue(html.contains('data-dmt-action="external-rwa"'), 'The modal marker must be emitted');
        Assert.isTrue(html.contains('<img alt="profitability"'), 'The browser chart image must be used');
        Assert.isFalse(html.contains('External RWA 1Y'), 'No External RWA column unless requested');
        Assert.isTrue(((String) result.get('fileName')).endsWith('.pdf'), 'PDF file name expected');
    }

    @isTest
    static void testRenderProfitabilityHtml_WithExternalRwa() {
        Opportunity opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity LIMIT 1];
        opp.DMT_Opp_Id__c = 'ESCD25OPP00000001ES';
        update opp;
        DMT_Test_DataFactory.generatePassport(opp.Id, buildPassportJson('PROD001'));

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.renderProfitabilityHtml(opp.Id, null, true);
        Test.stopTest();

        Assert.isTrue(String.isNotBlank((String) result.get('html')), 'HTML expected after the External RWA call');
    }

    @isTest
    static void testRenderProfitabilityHtml_NoPassport() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.renderProfitabilityHtml(opp.Id, null, false);
        Test.stopTest();

        Assert.isFalse((Boolean) result.get('hasData'), 'No Passport means no profitability data');
    }

    @isTest
    static void testRenderProfitabilityHtml_InvalidOpportunity() {
        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.renderProfitabilityHtml('006000000000000AAA', null, false);
        Test.stopTest();

        Assert.areEqual('Unable to load the profitability view.', result.get('message'), 'Unknown Opportunity must return the error message');
    }

    @isTest
    static void testParseAprsCalculation() {
        String body = '{"data":{"aprsCalculator":[{"aprCalculator":{"productId":"P1","aprCalculation":12.5}},{"aprCalculator":{}}]}}';

        Test.startTest();
        Map<String, Object> parsed = DMT_Profitability_utils.parseAprsCalculation(body);
        Map<String, Object> invalid = DMT_Profitability_utils.parseAprsCalculation('not json');
        Map<String, Object> blank = DMT_Profitability_utils.parseAprsCalculation(null);
        Test.stopTest();

        Assert.areEqual(1, parsed.size(), 'Only rows with productId are kept');
        Assert.areEqual(12.5, parsed.get('P1'), 'aprCalculation mapped by productId');
        Assert.isTrue(invalid.isEmpty(), 'Unexpected response shape returns an empty map');
        Assert.isTrue(blank.isEmpty(), 'Blank response returns an empty map');
    }

    // CIBGLOBALD-4711 - Profitability detail CSV (service DMT_ProfitabilityDownloadDetail, mock from its iaso record).
    @isTest
    static void testGetProfitabilityDetailFile_Success() {
        Opportunity opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity LIMIT 1];
        opp.DMT_Opp_Id__c = 'ESCD25OPP00000001ES';
        update opp;

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.getProfitabilityDetailFile(opp.Id);
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('success'), 'Mock response must be accepted: ' + result.get('message'));
        Assert.areEqual('ProfitabilityDetail_ESCD25OPP00000001ES_v7.csv', result.get('fileName'), 'File name from DMT_Opp_Id__c and opportunityVersion');
        // The mock file (iaso record DMT_ProfitabilityDownloadDetail) is a real CSV in base64.
        List<String> csvLines = EncodingUtil.base64Decode((String) result.get('fileBase64')).toString().split('\r\n');
        Assert.areEqual('Mes;Fecha;Capital pendiente;Amortización;Interés;Descripción', csvLines[0], 'CSV header expected');
        Assert.areEqual(3, csvLines.size(), 'Header plus two rows expected');
    }

    @isTest
    static void testGetProfitabilityDetailFile_NoOpportunity() {
        Test.startTest();
        Map<String, Object> blankId = DMT_Profitability_utils.getProfitabilityDetailFile(null);
        Map<String, Object> unknownId = DMT_Profitability_utils.getProfitabilityDetailFile('006000000000000AAA');
        Test.stopTest();

        Assert.isFalse((Boolean) blankId.get('success'), 'No Opportunity Id means no file');
        Assert.areEqual(DMT_Profitability_utils.DETAIL_NO_CALCULATION_MESSAGE, blankId.get('message'), 'No calculation message expected');
        Assert.isFalse((Boolean) unknownId.get('success'), 'Unknown Opportunity means no file');
        Assert.areEqual(DMT_Profitability_utils.DETAIL_FAILED_MESSAGE, unknownId.get('message'), 'Failure message expected');
    }

    @isTest
    static void testParseDetailFileResponse() {
        Test.startTest();
        Map<String, Object> noContent = DMT_Profitability_utils.parseDetailFileResponse(buildResponse(204, ''), 'OPP1');
        Map<String, Object> notFound = DMT_Profitability_utils.parseDetailFileResponse(buildResponse(404, ''), 'OPP1');
        Map<String, Object> functionalError = DMT_Profitability_utils.parseDetailFileResponse(
            buildResponse(400, '{"messages":[{"code":"functionalError","message":"Backend error text.","type":"ERROR"}]}'), 'OPP1');
        Map<String, Object> serverError = DMT_Profitability_utils.parseDetailFileResponse(buildResponse(500, 'not json'), 'OPP1');
        Map<String, Object> emptyData = DMT_Profitability_utils.parseDetailFileResponse(buildResponse(200, '{"data":[]}'), 'OPP1');
        Map<String, Object> blankFile = DMT_Profitability_utils.parseDetailFileResponse(buildResponse(200, '{"data":[{"file":"","opportunityVersion":"1"}]}'), 'OPP1');
        Map<String, Object> noVersion = DMT_Profitability_utils.parseDetailFileResponse(buildResponse(200, '{"data":[{"file":"YSxiCjEsMg=="}]}'), 'OPP1');
        Test.stopTest();

        Assert.areEqual(DMT_Profitability_utils.DETAIL_NOT_AVAILABLE_MESSAGE, noContent.get('message'), '204 means no detail');
        Assert.areEqual(DMT_Profitability_utils.DETAIL_NOT_AVAILABLE_MESSAGE, notFound.get('message'), '404 means no detail');
        Assert.areEqual(DMT_Profitability_utils.DETAIL_FAILED_MESSAGE + ' Backend error text.', functionalError.get('message'), 'Backend message must be shown');
        Assert.areEqual(DMT_Profitability_utils.DETAIL_FAILED_MESSAGE + ' (status 500)', serverError.get('message'), 'Status code shown without backend message');
        Assert.areEqual(DMT_Profitability_utils.DETAIL_NOT_AVAILABLE_MESSAGE, emptyData.get('message'), 'Empty data means no detail');
        Assert.areEqual(DMT_Profitability_utils.DETAIL_NOT_AVAILABLE_MESSAGE, blankFile.get('message'), 'Blank file means no detail');
        Assert.isTrue((Boolean) noVersion.get('success'), 'A file without version is still valid');
        Assert.areEqual('ProfitabilityDetail_OPP1.csv', noVersion.get('fileName'), 'No version suffix when it is missing');
    }

    // CIBGLOBALD-4711 - Real CSV (header, ; separator, decimal comma, accents, quoted field) encoded as base64 in the
    // documented response shape: the file returned must decode to exactly the same CSV.
    @isTest
    static void testParseDetailFileResponse_RealCsv() {
        String csv = 'Mes;Fecha;Capital pendiente;Amortización;Interés;Descripción\r\n'
            + '1;31/01/2026;1.000.000,00;10.000,50;2.345,67;Año 1 - cuota inicial\r\n'
            + '2;28/02/2026;990.000,00;10.000,50;2.320,11;"Revisión; tipo variable €"\r\n';
        String csvBase64 = EncodingUtil.base64Encode(Blob.valueOf(csv));
        String body = JSON.serialize(new Map<String, Object>{
            'data' => new List<Object>{ new Map<String, Object>{ 'file' => csvBase64, 'opportunityVersion' => '3' } }
        });

        Test.startTest();
        Map<String, Object> result = DMT_Profitability_utils.parseDetailFileResponse(buildResponse(200, body), 'ESCD26OPP00004148ES');
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('success'), 'A real CSV file must be accepted: ' + result.get('message'));
        Assert.areEqual('ProfitabilityDetail_ESCD26OPP00004148ES_v3.csv', result.get('fileName'), 'File name from external Id and version');
        Assert.areEqual(csv, EncodingUtil.base64Decode((String) result.get('fileBase64')).toString(), 'The CSV must reach the browser unchanged');
    }

    private static HttpResponse buildResponse(Integer statusCode, String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setBody(body);
        return response;
    }
}