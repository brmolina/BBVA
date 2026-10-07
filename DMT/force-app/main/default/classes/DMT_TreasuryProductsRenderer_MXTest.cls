// CIBGLOBALD-4117 - this renderer had no test coverage at all before this fix. Self-contained
// tracking, same as every other Treasury geography variant - DMT_ProductsRenderer resolves to this
// class only when the Line is Treasury + Booking_Geography__c = 'MX'.
@IsTest
private class DMT_TreasuryProductsRenderer_MXTest {

    @IsTest
    static void testNullData() {
        DMT_TreasuryProductsRenderer_MX renderer = new DMT_TreasuryProductsRenderer_MX();
        Assert.areEqual('', renderer.renderHtml(null), 'Null data must return an empty string, same as every other Treasury geography variant.');
    }

    @IsTest
    static void testNullLineProductList() {
        DMT_TreasuryProductsRenderer_MX renderer = new DMT_TreasuryProductsRenderer_MX();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'MX Line');
        data.lineProductList = null;
        Assert.areEqual('', renderer.renderHtml(data), 'Null lineProductList must return an empty string.');
    }

    @IsTest
    static void testHappyPathRendersSummaryAndRiskTables() {
        DMT_TreasuryProductsRenderer_MX renderer = new DMT_TreasuryProductsRenderer_MX();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(
            Name = 'MX Line',
            CurrencyIsoCode = 'MXN',
            DvP_Amount__c = 1000,
            FD_Amount__c = 2000,
            DMT_Additional_Restrictions__c = 'No repos allowed',
            DMT_Comments__c = 'Reviewed quarterly'
        );
        data.lineProductList = new List<DMT_Line_Product_Item__c>();
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{
            (DMT_Risk_Line_Term__c) JSON.deserialize(
                '{"DMT_Risk_Type__c":"Derivatives","DMT_Amount__c":50}',
                DMT_Risk_Line_Term__c.class
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('No repos allowed'), 'DMT_Additional_Restrictions__c value must be rendered.');
        Assert.isTrue(result.contains('Reviewed quarterly'), 'DMT_Comments__c value must be rendered.');
        Assert.isTrue(result.contains('COUNTERPARTY RISK (DERIVATIVES RISK LINE)'), 'Derivatives risk table must be rendered.');
    }

    // CIBGLOBALD-4117 - exercises the restriction-table path (Product_Code_Value__c matching
    // against DMT_OperationalRestrictionsTRSR__mdt), untouched by the other tests here. No MX
    // configuration records are guaranteed to exist in every org, so this only proves the method
    // runs end to end without throwing - not that a specific restriction row renders.
    @IsTest
    static void testRenderHtmlWithLineProductsDoesNotThrow() {
        DMT_TreasuryProductsRenderer_MX renderer = new DMT_TreasuryProductsRenderer_MX();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'MX Line', CurrencyIsoCode = 'MXN');
        data.riskLineList = new List<DMT_Risk_Line_Term__c>();
        data.lineProductList = new List<DMT_Line_Product_Item__c>{
            new DMT_Line_Product_Item__c(
                Name = 'Product A',
                Product_Code_Value__c = 'DOES-NOT-MATCH-ANY-CONFIG',
                DMT_DerivativeRestriction__c = false,
                DMT_FDRestriction__c = false,
                DMT_DVPRestriction__c = false
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Renderer must return a non-null result even when no restriction configuration matches.');
    }

    // CIBGLOBALD-4117 - self-reports its own tracked fields; this is the sole place
    // Product_Code_Value__c can be tracked at all, since DMT_ProductsRenderer resolves straight to
    // this renderer for MX Treasury Lines - there is no union step to fall back on.
    @IsTest
    static void testTrackingMethodsAreSelfContained() {
        DMT_TreasuryProductsRenderer_MX renderer = new DMT_TreasuryProductsRenderer_MX();
        DMT_Line__c record = new DMT_Line__c();

        Set<String> lineFields = new Set<String>(renderer.getTrackedFields(record));
        Assert.isTrue(lineFields.contains('Booking_Geography__c'), 'Must self-fold the geography switch field.');
        Assert.isTrue(lineFields.contains('DvP_Amount__c'), 'Must track its own displayed fields.');

        Map<String, List<String>> byObject = renderer.getTrackedFieldsByObject(record);
        Assert.areEqual(lineFields, new Set<String>(byObject.get('DMT_Line__c')), 'DMT_Line__c key must match getTrackedFields exactly.');
        Assert.isTrue(
            new Set<String>(byObject.get('DMT_Line_Product_Item__c')).contains('Product_Code_Value__c'),
            'Product_Code_Value__c must be tracked - it decides which restriction section a product falls into.'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = renderer.getChildSections(record);
        Assert.areEqual(2, sections.size(), 'Must declare both child sections independently.');
    }
}