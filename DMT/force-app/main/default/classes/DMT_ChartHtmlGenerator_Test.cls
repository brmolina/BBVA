@IsTest
private class DMT_ChartHtmlGenerator_Test {

    private static DMT_ViewController.LineDataWrapper buildDataFromStaticResource() {
        StaticResource sr = [ SELECT Body FROM StaticResource WHERE Name = 'DMT_ChartHtmlGenerator_TestData' LIMIT 1];

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(sr.Body.toString());
        Map<String, Object> dataNode = (Map<String, Object>) root.get('data');

        List<Map<String, Object>> features = new List<Map<String, Object>>();
        for (Object featureObj : (List<Object>) dataNode.get('features')) {
            features.add((Map<String, Object>) featureObj);
        }

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.currencyIsoCode = String.valueOf(dataNode.get('currencyCode'));
        data.featuresList = features;
        return data;
    }

    @IsTest
    static void testBuildChartRequests_NullAndEmpty() {
        Test.startTest();
        List<DMT_ChartHtmlGenerator.ChartRequest> nullResult = DMT_ChartHtmlGenerator.buildChartRequests(null);
        List<DMT_ChartHtmlGenerator.ChartRequest> emptyResult = DMT_ChartHtmlGenerator.buildChartRequests(new DMT_ViewController.LineDataWrapper());
        Test.stopTest();

        System.assertNotEquals(null, nullResult, 'Null input must return an empty list, not null.');
        System.assertEquals(0, nullResult.size(), 'Null input must return no chart requests.');
        System.assertEquals(0, emptyResult.size(), 'Wrapper without features must return no chart requests.');
    }

    @IsTest
    static void testBuildChartRequests_FromStaticResource() {
        DMT_ViewController.LineDataWrapper data = buildDataFromStaticResource();

        Test.startTest();
        List<DMT_ChartHtmlGenerator.ChartRequest> requests = DMT_ChartHtmlGenerator.buildChartRequests(data);
        Test.stopTest();

        System.assertEquals(1, requests.size(), 'Only the second feature should generate chart data.');
        DMT_ChartHtmlGenerator.ChartRequest req = requests[0];

        System.assertEquals(2, req.labels.size(), 'Only consumption limits with amount must be included.');
        System.assertEquals(2, req.targets.size(), 'Targets must be populated for each valid amount.');
        System.assertEquals(2, req.dataDraw.size(), 'Drawn data must be populated for each valid amount.');
        System.assertEquals('EUR', String.valueOf(req.currencies[0]), 'Currency must come from consumption limit.');
    }

    @IsTest
    static void testGetHorizontalBarChartHtml_Content() {
        DMT_ViewController.LineDataWrapper data = buildDataFromStaticResource();
        DMT_ChartHtmlGenerator.ChartRequest req = DMT_ChartHtmlGenerator.buildChartRequests(data)[0];

        Test.startTest();
        String html = DMT_ChartHtmlGenerator.getHorizontalBarChartHtml(req);
        String emptyHtml = DMT_ChartHtmlGenerator.getHorizontalBarChartHtml(null);
        Test.stopTest();

        System.assertEquals('', emptyHtml, 'Null request must return empty HTML.');
        System.assertNotEquals('', html, 'Chart HTML should not be empty for valid request.');
        System.assert(html.contains('Drawn'), 'Legend must include Drawn.');
        System.assert(html.contains('Undrawn Committed'), 'Legend must include Undrawn Committed.');
        System.assert(html.contains('Pending Authorized'), 'Legend must include Pending Authorized.');
        System.assert(html.contains('New Opportunity'), 'Legend must include New Opportunity.');
        System.assert(html.contains('be680b79c5603078a249b08da6074628483'), 'HTML must include limit description label.');
        System.assert(html.contains('EUR'), 'HTML must include currency in limit marker text.');
    }

    @IsTest
    static void testRenderLimitVisualHtml_FromStaticResource() {
        DMT_ViewController.LineDataWrapper data = buildDataFromStaticResource();

        Test.startTest();
        String html = DMT_ChartHtmlGenerator.renderLimitVisualHtml(data);
        String emptyHtml = DMT_ChartHtmlGenerator.renderLimitVisualHtml(new DMT_ViewController.LineDataWrapper());
        Test.stopTest();

        System.assertEquals('', emptyHtml, 'Wrapper without features must return empty HTML.');
        System.assertNotEquals('', html, 'Rendered limit visual HTML should not be empty.');
        System.assert(html.contains('S&T Credit Risk Group Approval'), 'Feature title must be rendered.');
        System.assert(html.contains('Limit'), 'Detail table must include Limit row.');
        System.assert(html.contains('Exceeded'), 'Detail table must include Exceeded row.');
        System.assert(html.contains('be680b79c5603078a249b08da6074628483'), 'Detail section must include limit description.');
    }
}