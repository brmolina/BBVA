/**
 * CIBGLOBALD-4117 - minimal dedicated coverage for the field-drift fix on
 * DMT_TreasuryProductsRenderer_CO: DMT_Singular_DvP__c/DMT_Singular_FD__c (ONE-OFF-TRANSACTION
 * table) and DMT_Additional_Restrictions__c/DMT_Comments__c (header table) were tracked by an
 * earlier fix but never actually displayed, until this one.
 */
@IsTest
private class DMT_TreasuryProductsRenderer_COTest {

    @IsTest
    static void testRenderHtmlDisplaysFieldDriftAuditFixes() {
        DMT_TreasuryProductsRenderer_CO renderer = new DMT_TreasuryProductsRenderer_CO();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(
            Name = 'CO Line',
            CurrencyIsoCode = 'EUR',
            DMT_Additional_Restrictions__c = 'No repos allowed',
            DMT_Comments__c = 'Reviewed quarterly'
        );
        data.lineProductList = new List<DMT_Line_Product_Item__c>();
        String riskJson = '{"DMT_Risk_Type__c":"Derivatives","DMT_Singular__c":true,'
            + '"DMT_Singular_Active__c":true,"DMT_Singular_Operation__c":"FX Swap",'
            + '"DMT_Singular_DvP__c":15000,"DMT_Singular_FD__c":7500}';
        DMT_Risk_Line_Term__c singularLine = (DMT_Risk_Line_Term__c) JSON.deserialize(riskJson, DMT_Risk_Line_Term__c.class);
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{ singularLine };

        String result = renderer.renderHtml(data);

        // formatCurrencyAmount formats digit grouping per the running user's locale (e.g. '15.000'
        // in es_ES, '15,000' in en_US) - compute the expected string the same way rather than
        // hardcoding a separator, so this assertion isn't locale-dependent.
        String expectedDvp = DMT_FormattingUtils.formatCurrencyAmount(15000, null);
        String expectedFd = DMT_FormattingUtils.formatCurrencyAmount(7500, null);

        Assert.isTrue(result.contains('No repos allowed'), 'DMT_Additional_Restrictions__c value must be rendered.');
        Assert.isTrue(result.contains('Reviewed quarterly'), 'DMT_Comments__c value must be rendered.');
        Assert.isTrue(result.contains(expectedDvp), 'DMT_Singular_DvP__c value must be rendered.');
        Assert.isTrue(result.contains(expectedFd), 'DMT_Singular_FD__c value must be rendered.');
    }
        @IsTest
    static void testNullData() {
        DMT_TreasuryProductsRenderer_CO renderer = new DMT_TreasuryProductsRenderer_CO();
        String result = renderer.renderHtml(null);
        Assert.areEqual('', result, 'Null data must return empty string.');
    }

    @IsTest
    static void testNullLine() {
        DMT_TreasuryProductsRenderer_CO renderer = new DMT_TreasuryProductsRenderer_CO();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = null;
        String result = renderer.renderHtml(data);
        Assert.areEqual('', result, 'Null line must return empty string.');
    }

    @IsTest
    static void testNullLineProductList() {
        DMT_TreasuryProductsRenderer_CO renderer = new DMT_TreasuryProductsRenderer_CO();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'CO Line');
        data.lineProductList = null;
        String result = renderer.renderHtml(data);
        Assert.areEqual('', result, 'Null lineProductList must return empty string.');
    }

    @IsTest
    static void testDerivativesNonSingularRendersCounterpartyRisk() {
        DMT_TreasuryProductsRenderer_CO renderer = new DMT_TreasuryProductsRenderer_CO();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'CO Line', CurrencyIsoCode = 'EUR');
        data.lineProductList = new List<DMT_Line_Product_Item__c>();
        DMT_Risk_Line_Term__c derivativeLine = new DMT_Risk_Line_Term__c(
            DMT_Risk_Type__c = 'Derivatives',
            DMT_Singular__c = false,
            DMT_Amount__c = 100000,
            DMT_Init_Term__c = '12',
            DMT_End_Term__c = '36'
        );
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{ derivativeLine };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('COUNTERPARTY RISK'), 'Non-singular Derivatives must render the COUNTERPARTY RISK table.');
    }

    @IsTest
    static void testLineProductListRendersAvailableProducts() {
        DMT_TreasuryProductsRenderer_CO renderer = new DMT_TreasuryProductsRenderer_CO();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'CO Line', CurrencyIsoCode = 'EUR');
        data.riskLineList = new List<DMT_Risk_Line_Term__c>();
        DMT_Line_Product_Item__c product = new DMT_Line_Product_Item__c(
            Name = 'FX Products',
            DMT_DerivativeRestriction__c = true,
            DMT_FDRestriction__c = false,
            DMT_DVPRestriction__c = true
        );
        data.lineProductList = new List<DMT_Line_Product_Item__c>{ product };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('AVAILABLE PRODUCTS'), 'Non-empty lineProductList must render the AVAILABLE PRODUCTS table.');
        Assert.isTrue(result.contains('FX Products'), 'Product name should appear in the restrictions table.');
    }

    @IsTest
    static void testAllSectionsRenderedTogether() {
        DMT_TreasuryProductsRenderer_CO renderer = new DMT_TreasuryProductsRenderer_CO();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'CO Line', CurrencyIsoCode = 'EUR');
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Derivatives', DMT_Singular__c = false, DMT_Amount__c = 100),
            (DMT_Risk_Line_Term__c) JSON.deserialize(
                '{"DMT_Risk_Type__c":"Derivatives","DMT_Singular__c":true,"DMT_Singular_Active__c":true,"DMT_Amount__c":50}',
                DMT_Risk_Line_Term__c.class
            )
        };
        data.lineProductList = new List<DMT_Line_Product_Item__c>{
            new DMT_Line_Product_Item__c(Name = 'Product A', DMT_DerivativeRestriction__c = false, DMT_FDRestriction__c = false, DMT_DVPRestriction__c = false)
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('COUNTERPARTY RISK'), 'All sections: COUNTERPARTY RISK should be present.');
        Assert.isTrue(result.contains('AVAILABLE PRODUCTS'), 'All sections: AVAILABLE PRODUCTS should be present.');
    }

    // CIBGLOBALD-4117 - this renderer now self-reports its own tracked fields instead of relying on
    // DMT_TreasuryProductsRenderer's union - confirms it is self-contained.
    @IsTest
    static void testTrackingMethodsAreSelfContained() {
        DMT_TreasuryProductsRenderer_CO renderer = new DMT_TreasuryProductsRenderer_CO();
        DMT_Line__c record = new DMT_Line__c();

        Set<String> lineFields = new Set<String>(renderer.getTrackedFields(record));
        Assert.isTrue(lineFields.contains('Booking_Geography__c'), 'Must self-fold the geography switch field.');
        Assert.isTrue(lineFields.contains('DvP_Amount__c'), 'Must track its own displayed fields.');

        Map<String, List<String>> byObject = renderer.getTrackedFieldsByObject(record);
        Assert.areEqual(lineFields, new Set<String>(byObject.get('DMT_Line__c')), 'DMT_Line__c key must match getTrackedFields exactly.');
        Assert.isTrue(new Set<String>(byObject.get('DMT_Risk_Line_Term__c')).contains('DMT_Singular_DvP__c'), 'Must track its own Singular-transaction fields.');
        Assert.isFalse(byObject.get('DMT_Line_Product_Item__c').contains('Max_Tenor_WC__c'), 'CO does not render a Maturity Term column, unlike PE.');

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = renderer.getChildSections(record);
        Assert.areEqual(2, sections.size(), 'Must declare both child sections independently.');
    }
}