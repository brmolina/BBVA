@isTest
public with sharing class DMT_ChartHtmlGeneratorTest {

    @testSetup
    static void setupData() {
        TriggerBypass.setBypass();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2, pricebookEntry, opp);
        DMT_Opportunity_Tenor__c tenor = DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
    }

    @isTest
    static void testBuildChartRequestsWithNullData() {
        Test.startTest();
        List<DMT_ChartHtmlGenerator.ChartRequest> results = DMT_ChartHtmlGenerator.buildChartRequests(null);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Debe retornar lista vacía para data null');
    }

    @isTest
    static void testBuildChartRequestsWithEmptyData() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.featuresList = new List<Map<String, Object>>();

        Test.startTest();
        List<DMT_ChartHtmlGenerator.ChartRequest> results = DMT_ChartHtmlGenerator.buildChartRequests(data);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Debe retornar lista vacía para featuresList vacía');
    }

    @isTest
    static void testBuildChartRequestsWithValidData() {
        Opportunity opp = [SELECT Id, RecordTypeId FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id, OpportunityId FROM OpportunityLineItem LIMIT 1];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = opp.RecordTypeId;
        data.opportunity = opp;

        // Crear features con consumptionLimits
        Map<String, Object> feature1 = new Map<String, Object>{
            'consumptionLimits' => new List<Map<String, Object>>()
        };

        Map<String, Object> feature2 = new Map<String, Object>{
            'consumptionLimits' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'conditionDesc' => 'Test Condition',
                    'currencyId' => 'EUR',
                    'limitDesc' => 'Test Limit',
                    'stateName' => 'GREEN',
                    'amount' => new Map<String, Object>{
                        'currentApprovedAmount' => 1000,
                        'cmtContDisposedAmount' => 100,
                        'uncmtContDisposedAmount' => 50,
                        'cmtContNonDspsAmount' => 200,
                        'uncmtContNonDspsAmount' => 150,
                        'authorizedRiskAmount' => 75,
                        'notSignedTrConsumptionAmount' => 25
                    }
                }
            }
        };

        data.featuresList = new List<Map<String, Object>>{feature1, feature2};

        Test.startTest();
        List<DMT_ChartHtmlGenerator.ChartRequest> results = DMT_ChartHtmlGenerator.buildChartRequests(data);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Debe retornar una ChartRequest (feature2)');
        DMT_ChartHtmlGenerator.ChartRequest req = results[0];
        System.assertEquals(1, req.labels.size(), 'Debe tener un label');
        System.assertEquals('EUR', req.currencies[0], 'Debe tener la moneda EUR');
    }

    @isTest
    static void testGetHorizontalBarChartHtmlWithNullRequest() {
        Test.startTest();
        String html = DMT_ChartHtmlGenerator.getHorizontalBarChartHtml(null);
        Test.stopTest();

        System.assertEquals('', html, 'Debe retornar string vacío para request null');
    }

    @isTest
    static void testGetHorizontalBarChartHtmlWithValidRequest() {
        DMT_ChartHtmlGenerator.ChartRequest req = new DMT_ChartHtmlGenerator.ChartRequest();
        req.labels = new List<Object>{'Limit 1', 'Limit 2'};
        req.targets = new List<Object>{1000, 2000};
        req.limitLights = new List<Object>{'GREEN', 'YELLOW'};
        req.dataDraw = new List<Object>{500, 800};
        req.dataUndrawnCommitted = new List<Object>{200, 300};
        req.dataUndrawnUncommitted = new List<Object>{100, 150};
        req.dataPendingAuthorized = new List<Object>{50, 100};
        req.dataNewOpportunity = new List<Object>{25, 50};
        req.currencies = new List<Object>{'EUR', 'USD'};
        req.conditions = new List<Object>{'Condition 1', 'Condition 2'};

        Test.startTest();
        String html = DMT_ChartHtmlGenerator.getHorizontalBarChartHtml(req);
        Test.stopTest();

        System.assertNotEquals('', html, 'Debe retornar HTML no vacío');
        System.assert(html.contains('Limit 1'), 'HTML debe contener label');
        System.assert(html.contains('table'), 'HTML debe contener tabla');
    }

    @isTest
    static void testGetHorizontalBarChartHtmlWithEmptyLabels() {
        DMT_ChartHtmlGenerator.ChartRequest req = new DMT_ChartHtmlGenerator.ChartRequest();
        req.labels = new List<Object>();
        req.targets = new List<Object>();
        req.limitLights = new List<Object>();
        req.dataDraw = new List<Object>();
        req.dataUndrawnCommitted = new List<Object>();
        req.dataUndrawnUncommitted = new List<Object>();
        req.dataPendingAuthorized = new List<Object>();
        req.dataNewOpportunity = new List<Object>();
        req.currencies = new List<Object>();
        req.conditions = new List<Object>();

        Test.startTest();
        String html = DMT_ChartHtmlGenerator.getHorizontalBarChartHtml(req);
        Test.stopTest();

        System.assertNotEquals(null, html, 'Debe retornar un string no nulo aunque no haya labels');
    }

    @isTest
    static void testGetHorizontalBarChartHtmlWithSingleBar() {
        DMT_ChartHtmlGenerator.ChartRequest req = new DMT_ChartHtmlGenerator.ChartRequest();
        req.labels = new List<Object>{'Single Limit'};
        req.targets = new List<Object>{5000};
        req.limitLights = new List<Object>{'RED'};
        req.dataDraw = new List<Object>{4000};
        req.dataUndrawnCommitted = new List<Object>{500};
        req.dataUndrawnUncommitted = new List<Object>{300};
        req.dataPendingAuthorized = new List<Object>{150};
        req.dataNewOpportunity = new List<Object>{50};
        req.currencies = new List<Object>{'GBP'};
        req.conditions = new List<Object>{'Single Condition'};

        Test.startTest();
        String html = DMT_ChartHtmlGenerator.getHorizontalBarChartHtml(req);
        Test.stopTest();

        System.assertNotEquals('', html, 'Debe retornar HTML no vacío para barra única');
        System.assert(html.contains('Single Limit'), 'HTML debe contener el label único');
    }

    @isTest
    static void testBuildChartRequestsWithNoConsumptionLimits() {
        Opportunity opp = [SELECT Id, RecordTypeId FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id, OpportunityId FROM OpportunityLineItem LIMIT 1];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = opp.RecordTypeId;
        data.opportunity = opp;

        // Crear feature sin consumptionLimits válidos
        Map<String, Object> feature = new Map<String, Object>{
            'consumptionLimits' => new List<Map<String, Object>>()
        };

        data.featuresList = new List<Map<String, Object>>{feature};

        Test.startTest();
        List<DMT_ChartHtmlGenerator.ChartRequest> results = DMT_ChartHtmlGenerator.buildChartRequests(data);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'No debe retornar ChartRequest si no hay consumptionLimits válidos');
    }

    @isTest
    static void testBuildChartRequestsWithEmptyAmounts() {
        Opportunity opp = [SELECT Id, RecordTypeId FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id, OpportunityId FROM OpportunityLineItem LIMIT 1];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = opp.RecordTypeId;
        data.opportunity = opp;

        Map<String, Object> feature = new Map<String, Object>{
            'consumptionLimits' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'conditionDesc' => 'Test',
                    'currencyId' => 'EUR',
                    'limitDesc' => 'Limit',
                    'stateName' => 'GREEN',
                    'amount' => new Map<String, Object>()
                }
            }
        };

        data.featuresList = new List<Map<String, Object>>{feature};

        Test.startTest();
        List<DMT_ChartHtmlGenerator.ChartRequest> results = DMT_ChartHtmlGenerator.buildChartRequests(data);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'No debe retornar ChartRequest si amount está vacío');
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static Map<String, Object> buildConsumptionLimit(String limitDesc, String stateName, String currencyCode) {
        Map<String, Object> amount = new Map<String, Object>{
            'currentApprovedAmount'          => 5000,
            'cmtContDisposedAmount'          => 1000,
            'uncmtContDisposedAmount'        => 500,
            'cmtContNonDspsAmount'           => 800,
            'uncmtContNonDspsAmount'         => 300,
            'authorizedRiskAmount'           => 200,
            'notSignedTrConsumptionAmount'   => 100,
            'unavailableRiskAmount'          => 3000
        };
        return new Map<String, Object>{
            'conditionDesc' => 'Condition',
            'currencyId'    => currencyCode,
            'limitDesc'     => limitDesc,
            'stateName'     => stateName,
            'amount'        => amount
        };
    }

    private static DMT_ViewController.LineDataWrapper buildWrapperWithTwoFeatures(
        Map<String, Object> secondFeature
    ) {
        // renderLimitVisualHtml skips features[0]; features[1+] are processed
        Map<String, Object> firstFeature = new Map<String, Object>{
            'consumptionLimits' => new List<Map<String, Object>>()
        };
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.featuresList    = new List<Map<String, Object>>{ firstFeature, secondFeature };
        data.currencyIsoCode = 'EUR';
        return data;
    }

    // ── renderLimitVisualHtml tests ───────────────────────────────────────────

    @isTest
    static void testRenderLimitVisualHtmlWithNullData() {
        Test.startTest();
        String result = DMT_ChartHtmlGenerator.renderLimitVisualHtml(null);
        Test.stopTest();

        System.assertEquals('', result, 'Debe retornar vacío para data null');
    }

    @isTest
    static void testRenderLimitVisualHtmlWithEmptyFeatures() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.featuresList = new List<Map<String, Object>>();

        Test.startTest();
        String result = DMT_ChartHtmlGenerator.renderLimitVisualHtml(data);
        Test.stopTest();

        System.assertEquals('', result, 'Debe retornar vacío para featuresList vacía');
    }

    @isTest
    static void testRenderLimitVisualHtmlWithValidDataGreen() {
        // Covers: renderLimitVisualHtml happy path, renderDetailTableHtml,
        //         renderColorSquare, renderTrafficLightLocal, renderTrafficLightSingleLocal
        Map<String, Object> secondFeature = new Map<String, Object>{
            'name'              => 'Feature GREEN',
            'stateName'         => 'GREEN',
            'consumptionLimits' => new List<Map<String, Object>>{
                buildConsumptionLimit('Test Limit', 'GREEN', 'EUR')
            }
        };

        DMT_ViewController.LineDataWrapper data = buildWrapperWithTwoFeatures(secondFeature);

        Test.startTest();
        String result = DMT_ChartHtmlGenerator.renderLimitVisualHtml(data);
        Test.stopTest();

        System.assertNotEquals('', result,   'Debe retornar HTML no vacío');
        System.assertNotEquals(null, result, 'Debe retornar HTML no nulo');
    }

    @isTest
    static void testRenderLimitVisualHtmlWithRedTrafficLight() {
        // Covers: RED stateName branch in title rendering
        Map<String, Object> secondFeature = new Map<String, Object>{
            'name'              => 'Feature RED',
            'stateName'         => 'RED',
            'consumptionLimits' => new List<Map<String, Object>>{
                buildConsumptionLimit('Red Limit', 'RED', 'USD')
            }
        };

        DMT_ViewController.LineDataWrapper data = buildWrapperWithTwoFeatures(secondFeature);
        data.currencyIsoCode = 'USD';

        Test.startTest();
        String result = DMT_ChartHtmlGenerator.renderLimitVisualHtml(data);
        Test.stopTest();

        System.assertNotEquals('', result, 'Debe retornar HTML con semáforo rojo');
    }

    @isTest
    static void testRenderLimitVisualHtmlWithYellowTrafficLight() {
        // Covers: YELLOW stateName branch
        Map<String, Object> secondFeature = new Map<String, Object>{
            'name'              => 'Feature YELLOW',
            'stateName'         => 'YELLOW',
            'consumptionLimits' => new List<Map<String, Object>>{
                buildConsumptionLimit('Yellow Limit', 'YELLOW', 'GBP')
            }
        };

        DMT_ViewController.LineDataWrapper data = buildWrapperWithTwoFeatures(secondFeature);
        data.currencyIsoCode = 'GBP';

        Test.startTest();
        String result = DMT_ChartHtmlGenerator.renderLimitVisualHtml(data);
        Test.stopTest();

        System.assertNotEquals('', result, 'Debe retornar HTML con semáforo amarillo');
    }

    @isTest
    static void testRenderLimitVisualHtmlWithGrayStateName() {
        // Covers: stateName not in RED/YELLOW/GREEN → title block skipped; proceed=false → empty result
        Map<String, Object> consumptionLimit = new Map<String, Object>{
            'conditionDesc' => 'Condition',
            'currencyId'    => 'EUR',
            'limitDesc'     => 'Limit',
            'stateName'     => 'GRAY',
            'amount'        => null
        };
        Map<String, Object> secondFeature = new Map<String, Object>{
            'name'              => 'Feature GRAY',
            'stateName'         => 'GRAY',
            'consumptionLimits' => new List<Map<String, Object>>{ consumptionLimit }
        };

        DMT_ViewController.LineDataWrapper data = buildWrapperWithTwoFeatures(secondFeature);

        Test.startTest();
        String result = DMT_ChartHtmlGenerator.renderLimitVisualHtml(data);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe retornar string no nulo');
    }

    @isTest
    static void testRenderLimitVisualHtmlWithBlankLimitDesc() {
        // Covers: blank limitDesc → detail table row skipped
        Map<String, Object> secondFeature = new Map<String, Object>{
            'name'              => 'Feature No Desc',
            'stateName'         => 'GREEN',
            'consumptionLimits' => new List<Map<String, Object>>{
                buildConsumptionLimit('', 'GREEN', 'EUR')
            }
        };

        DMT_ViewController.LineDataWrapper data = buildWrapperWithTwoFeatures(secondFeature);

        Test.startTest();
        String result = DMT_ChartHtmlGenerator.renderLimitVisualHtml(data);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe retornar string no nulo aunque limitDesc esté vacío');
    }

    @isTest
    static void testRenderLimitVisualHtmlMultipleLimitsInFeature() {
        // Covers: multiple consumptionLimits in one feature
        List<Map<String, Object>> limits = new List<Map<String, Object>>{
            buildConsumptionLimit('Limit A', 'GREEN', 'EUR'),
            buildConsumptionLimit('Limit B', 'RED',   'EUR')
        };
        Map<String, Object> secondFeature = new Map<String, Object>{
            'name'              => 'Multi Limit Feature',
            'stateName'         => 'YELLOW',
            'consumptionLimits' => limits
        };

        DMT_ViewController.LineDataWrapper data = buildWrapperWithTwoFeatures(secondFeature);

        Test.startTest();
        String result = DMT_ChartHtmlGenerator.renderLimitVisualHtml(data);
        Test.stopTest();

        System.assertNotEquals('', result, 'Debe retornar HTML con múltiples limits');
    }

    // ── Additional getHorizontalBarChartHtml edge case tests ──────────────────

    @isTest
    static void testGetHorizontalBarChartHtmlWithMillionScale() {
        // Covers: divisor = millionUnit → axisSuffix 'M' branch
        DMT_ChartHtmlGenerator.ChartRequest req = new DMT_ChartHtmlGenerator.ChartRequest();
        req.labels                  = new List<Object>{ 'Big Limit' };
        req.targets                 = new List<Object>{ 10000000 };
        req.limitLights             = new List<Object>{ 'GREEN' };
        req.dataDraw                = new List<Object>{ 3000000 };
        req.dataUndrawnCommitted    = new List<Object>{ 2000000 };
        req.dataUndrawnUncommitted  = new List<Object>{ 1500000 };
        req.dataPendingAuthorized   = new List<Object>{ 500000 };
        req.dataNewOpportunity      = new List<Object>{ 250000 };
        req.currencies              = new List<Object>{ 'EUR' };
        req.conditions              = new List<Object>{ 'Big Condition' };

        Test.startTest();
        String html = DMT_ChartHtmlGenerator.getHorizontalBarChartHtml(req);
        Test.stopTest();

        System.assertNotEquals('', html, 'Debe retornar HTML no vacío para escala millones');
        System.assert(html.contains('M'), 'Debe contener sufijo M');
    }

    @isTest
    static void testGetHorizontalBarChartHtmlLimitInsideBar() {
        // Covers: limitPct falls inside a bar segment (beforePct > 0 AND afterPct > 0)
        DMT_ChartHtmlGenerator.ChartRequest req = new DMT_ChartHtmlGenerator.ChartRequest();
        req.labels                  = new List<Object>{ 'Bar With Inner Limit' };
        req.targets                 = new List<Object>{ 600 };   // limit < drawn → falls inside drawn segment
        req.limitLights             = new List<Object>{ 'YELLOW' };
        req.dataDraw                = new List<Object>{ 800 };   // drawn (800) > limit (600)
        req.dataUndrawnCommitted    = new List<Object>{ 100 };
        req.dataUndrawnUncommitted  = new List<Object>{ 50 };
        req.dataPendingAuthorized   = new List<Object>{ 30 };
        req.dataNewOpportunity      = new List<Object>{ 20 };
        req.currencies              = new List<Object>{ 'EUR' };
        req.conditions              = new List<Object>{ 'Condition' };

        Test.startTest();
        String html = DMT_ChartHtmlGenerator.getHorizontalBarChartHtml(req);
        Test.stopTest();

        System.assertNotEquals('', html, 'Debe retornar HTML con límite dentro de la barra');
    }

    @isTest
    static void testGetHorizontalBarChartHtmlWithThousandScale() {
        // Covers: divisor = thousandUnit → axisSuffix 'K' branch with single bar
        DMT_ChartHtmlGenerator.ChartRequest req = new DMT_ChartHtmlGenerator.ChartRequest();
        req.labels                  = new List<Object>{ 'K Limit' };
        req.targets                 = new List<Object>{ 5000 };
        req.limitLights             = new List<Object>{ 'RED' };
        req.dataDraw                = new List<Object>{ 2000 };
        req.dataUndrawnCommitted    = new List<Object>{ 1000 };
        req.dataUndrawnUncommitted  = new List<Object>{ 500 };
        req.dataPendingAuthorized   = new List<Object>{ 200 };
        req.dataNewOpportunity      = new List<Object>{ 100 };
        req.currencies              = new List<Object>{ 'USD' };
        req.conditions              = new List<Object>{ 'K Condition' };

        Test.startTest();
        String html = DMT_ChartHtmlGenerator.getHorizontalBarChartHtml(req);
        Test.stopTest();

        System.assertNotEquals('', html, 'Debe retornar HTML para escala miles');
        System.assert(html.contains('K'), 'Debe contener sufijo K');
    }
}