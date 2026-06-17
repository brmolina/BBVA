@IsTest
private class DMT_ProfitabilityChartGenerator_Test {
    
    private static Map<String, Object> buildProfitabilityDataFromStaticResource() {
        StaticResource sr = [ SELECT Body FROM StaticResource WHERE Name = 'DMT_ProfitabilityChartGenerator_TestData' LIMIT 1];

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(sr.Body.toString());
        return (Map<String, Object>) root.get('profitability');
    }

    @IsTest
    static void testBuildChartRequest_NullAndEmpty() {
        Test.startTest();
        DMT_ProfitabilityChartGenerator.ChartRequest nullResult = DMT_ProfitabilityChartGenerator.buildChartRequest(null);
        DMT_ProfitabilityChartGenerator.ChartRequest emptyResult = DMT_ProfitabilityChartGenerator.buildChartRequest(new Map<String, Object>());
        Test.stopTest();

        System.assertNotEquals(null, nullResult, 'Null input must return an empty ChartRequest, not null.');
        System.assertEquals(0, nullResult.years.size(), 'Null input must have no years.');
        System.assertEquals(0, emptyResult.years.size(), 'Empty map must have no years.');
    }

    @IsTest
    static void testBuildChartRequest_FromStaticResource() {
        Map<String, Object> profitabilityNode = buildProfitabilityDataFromStaticResource();

        Test.startTest();
        DMT_ProfitabilityChartGenerator.ChartRequest chartReq = DMT_ProfitabilityChartGenerator.buildChartRequest(profitabilityNode);
        Test.stopTest();

        System.assertNotEquals(null, chartReq, 'ChartRequest must not be null.');
        System.assertNotEquals(0, chartReq.years.size(), 'Years list must not be empty.');
        System.assertEquals(3, chartReq.years.size(), 'Should have 3 years from test data.');
        System.assertEquals(2026, chartReq.years[0], 'First year should be 2026.');
        System.assertEquals(2028, chartReq.years[2], 'Last year should be 2028.');

        System.assertEquals(3, chartReq.eadEcoData.size(), 'EAD Eco data should match years count.');
        System.assertEquals(3, chartReq.eadRegData.size(), 'EAD Reg data should match years count.');
        System.assertEquals(3, chartReq.rorcData.size(), 'RORC data should match years count.');
        System.assertEquals(3, chartReq.raroecData.size(), 'RAROEC data should match years count.');
    }

    @IsTest
    static void testBuildChartRequest_DataAggregation() {
        Map<String, Object> profitabilityNode = buildProfitabilityDataFromStaticResource();

        Test.startTest();
        DMT_ProfitabilityChartGenerator.ChartRequest chartReq = DMT_ProfitabilityChartGenerator.buildChartRequest(profitabilityNode);
        Test.stopTest();

        // For year 2026, both products have data. EAD values should be assigned (not summed)
        Decimal expectedEadEco2026 = 12000000.0;
        Decimal expectedEadReg2026 = 12000000.0;

        System.assertEquals(expectedEadEco2026, chartReq.eadEcoData[0], 'EAD Eco for 2026 should match product data.');
        System.assertEquals(expectedEadReg2026, chartReq.eadRegData[0], 'EAD Reg for 2026 should match product data.');

        // RORC and RAROEC should be averaged across products
        Decimal product1Rorc2026 = -0.0003197826534343216;
        Decimal product2Rorc2026 = 0.0045123456789012;
        Decimal expectedRorc2026 = (product1Rorc2026 + product2Rorc2026) / 2.0;

        System.assertEquals(expectedRorc2026.setScale(15, RoundingMode.HALF_UP), chartReq.rorcData[0].setScale(15, RoundingMode.HALF_UP), 'RORC for 2026 should be averaged.');
    }

    @IsTest
    static void testGetMixedChartHtml_NullAndEmpty() {
        Test.startTest();
        String nullHtml = DMT_ProfitabilityChartGenerator.getMixedChartHtml(null);
        String emptyHtml = DMT_ProfitabilityChartGenerator.getMixedChartHtml(new DMT_ProfitabilityChartGenerator.ChartRequest());
        Test.stopTest();

        System.assertEquals('', nullHtml, 'Null ChartRequest must return empty HTML.');
        System.assertEquals('', emptyHtml, 'Empty ChartRequest must return empty HTML.');
    }

    @IsTest
    static void testGetMixedChartHtml_WithData() {
        Map<String, Object> profitabilityNode = buildProfitabilityDataFromStaticResource();
        DMT_ProfitabilityChartGenerator.ChartRequest chartReq = DMT_ProfitabilityChartGenerator.buildChartRequest(profitabilityNode);

        Test.startTest();
        String html = DMT_ProfitabilityChartGenerator.getMixedChartHtml(chartReq);
        Test.stopTest();

        System.assertNotEquals('', html, 'Chart HTML should not be empty for valid data.');
        System.assert(html.contains('EAD ECO'), 'HTML should include EAD ECO legend.');
        System.assert(html.contains('EAD REG'), 'HTML should include EAD REG legend.');
        System.assert(html.contains('RORC'), 'HTML should include RORC legend.');
        System.assert(html.contains('RAROEC'), 'HTML should include RAROEC legend.');
        System.assert(html.contains('2026'), 'HTML should include year label 2026.');
        System.assert(html.contains('2027'), 'HTML should include year label 2027.');
        System.assert(html.contains('2028'), 'HTML should include year label 2028.');
    }

    @IsTest
    static void testGetMixedChartHtml_BaseWidth() {
        Map<String, Object> profitabilityNode = buildProfitabilityDataFromStaticResource();
        DMT_ProfitabilityChartGenerator.ChartRequest chartReq = DMT_ProfitabilityChartGenerator.buildChartRequest(profitabilityNode);

        Test.startTest();
        String htmlDefault = DMT_ProfitabilityChartGenerator.getMixedChartHtml(chartReq);
        String htmlCustom = DMT_ProfitabilityChartGenerator.getMixedChartHtml(chartReq, 600.0);
        Test.stopTest();

        System.assertNotEquals('', htmlDefault, 'Default base width should generate HTML.');
        System.assertNotEquals('', htmlCustom, 'Custom base width should generate HTML.');
        System.assertNotEquals(htmlDefault, htmlCustom, 'Different base widths should generate different HTML.');
    }

    @IsTest
    static void testGetMixedChartHtml_HtmlStructure() {
        Map<String, Object> profitabilityNode = buildProfitabilityDataFromStaticResource();
        DMT_ProfitabilityChartGenerator.ChartRequest chartReq = DMT_ProfitabilityChartGenerator.buildChartRequest(profitabilityNode);

        Test.startTest();
        String html = DMT_ProfitabilityChartGenerator.getMixedChartHtml(chartReq);
        Test.stopTest();

        System.assert(html.contains('<div'), 'HTML should use div elements for rendering.');
        System.assert(html.contains('position:absolute'), 'HTML should use absolute positioning.');
        System.assert(html.contains('background-color'), 'HTML should define background colors.');
        System.assert(html.contains('width:') && html.contains('height:'), 'HTML should define dimensions.');
        System.assert(html.contains('z-index'), 'HTML should use z-index for layering.');
    }

    @IsTest
    static void testChartRequestDataTypes() {
        Map<String, Object> profitabilityNode = buildProfitabilityDataFromStaticResource();

        Test.startTest();
        DMT_ProfitabilityChartGenerator.ChartRequest chartReq = DMT_ProfitabilityChartGenerator.buildChartRequest(profitabilityNode);
        Test.stopTest();

        System.assertNotEquals(null, chartReq.years, 'Years list must be initialized.');
        System.assertNotEquals(null, chartReq.eadEcoData, 'EAD Eco list must be initialized.');
        System.assertNotEquals(null, chartReq.eadRegData, 'EAD Reg list must be initialized.');
        System.assertNotEquals(null, chartReq.rorcData, 'RORC list must be initialized.');
        System.assertNotEquals(null, chartReq.raroecData, 'RAROEC list must be initialized.');

        // Verify data consistency across lists
        Integer size = chartReq.years.size();
        System.assertEquals(size, chartReq.eadEcoData.size(), 'All data lists must have same size as years.');
        System.assertEquals(size, chartReq.eadRegData.size(), 'All data lists must have same size as years.');
        System.assertEquals(size, chartReq.rorcData.size(), 'All data lists must have same size as years.');
        System.assertEquals(size, chartReq.raroecData.size(), 'All data lists must have same size as years.');
    }
}