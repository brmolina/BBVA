/**
 * CIBGLOBALD-4117 - minimal dedicated coverage for the field-drift fix on
 * DMT_TreasuryProductsRenderer (base/default geography variant): DMT_Additional_Restrictions__c and
 * DMT_Comments__c were tracked by an earlier fix but never actually displayed, until this one.
 */
@IsTest
private class DMT_TreasuryProductsRendererTest {

    @IsTest
    static void testRenderHtmlDisplaysAdditionalRestrictionsAndComments() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(
            Name = 'Default Geography Line',
            CurrencyIsoCode = 'EUR',
            DMT_Additional_Restrictions__c = 'No repos allowed',
            DMT_Comments__c = 'Reviewed quarterly'
        );
        data.lineProductList = new List<DMT_Line_Product_Item__c>();

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('No repos allowed'), 'DMT_Additional_Restrictions__c value must be rendered.');
        Assert.isTrue(result.contains('Reviewed quarterly'), 'DMT_Comments__c value must be rendered.');
    }

        @IsTest
    static void testNullData() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        String result = renderer.renderHtml(null);
        Assert.areEqual('', result, 'Null data must return empty string.');
    }

    @IsTest
    static void testNullLine() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = null;
        String result = renderer.renderHtml(data);
        Assert.areEqual('', result, 'Null line must return empty string.');
    }

    @IsTest
    static void testNullLineProductList() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Default Geography Line');
        data.lineProductList = null;
        String result = renderer.renderHtml(data);
        Assert.areEqual('', result, 'Null lineProductList must return empty string.');
    }

    @IsTest
    static void testDerivativesRendersCounterpartyRisk() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Default Geography Line', CurrencyIsoCode = 'EUR');
        data.lineProductList = new List<DMT_Line_Product_Item__c>();
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(
                DMT_Risk_Type__c = 'Derivatives',
                DMT_Amount__c = 100000,
                DMT_Init_Term__c = '12',
                DMT_End_Term__c = '36'
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('COUNTERPARTY RISK'), 'Derivatives must render the COUNTERPARTY RISK table.');
    }

    @IsTest
    static void testLineProductListNonAR() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Default Geography Line', CurrencyIsoCode = 'EUR', Booking_Geography__c = 'ES');
        data.riskLineList = new List<DMT_Risk_Line_Term__c>();
        data.lineProductList = new List<DMT_Line_Product_Item__c>{
            new DMT_Line_Product_Item__c(
                Name = 'FX Products',
                DMT_DerivativeRestriction__c = true,
                DMT_FDRestriction__c = true,
                DMT_DVPRestriction__c = false,
                Max_Tenor_WC__c = '24'
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('AVAILABLE PRODUCTS'), 'Non-empty lineProductList must render the AVAILABLE PRODUCTS table.');
        Assert.isTrue(result.contains('FX Products'), 'Product name should appear.');
        Assert.isTrue(result.contains('FD LINE'), 'Non-AR geography must show the FD LINE column.');
        Assert.isTrue(result.contains('colspan="5"'), 'Non-AR geography must use colspan 5.');
    }

    @IsTest
    static void testLineProductListAR() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'AR Line', CurrencyIsoCode = 'EUR', Booking_Geography__c = 'AR');
        data.riskLineList = new List<DMT_Risk_Line_Term__c>();
        data.lineProductList = new List<DMT_Line_Product_Item__c>{
            new DMT_Line_Product_Item__c(
                Name = 'AR Product',
                DMT_DerivativeRestriction__c = false,
                DMT_FDRestriction__c = false,
                DMT_DVPRestriction__c = true,
                Max_Tenor_WC__c = null
            )
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('AVAILABLE PRODUCTS'), 'Non-empty lineProductList must render the AVAILABLE PRODUCTS table for AR too.');
        Assert.isTrue(result.contains('colspan="4"'), 'AR geography must use colspan 4.');
        Assert.isFalse(result.contains('FD LINE'), 'AR geography must NOT show the FD LINE column.');
    }

    @IsTest
    static void testDeposWithPositiveAmountRendersDeposTable() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Default Geography Line', CurrencyIsoCode = 'EUR');
        data.lineProductList = new List<DMT_Line_Product_Item__c>();
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Depos', DMT_Amount__c = 200000)
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('DEPOS RISK LINE'), 'Depos with positive amount must render the DEPOS table.');
    }

    @IsTest
    static void testDeposWithZeroOrNullAmountNoDeposTable() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Default Geography Line', CurrencyIsoCode = 'EUR');
        data.lineProductList = new List<DMT_Line_Product_Item__c>();
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Depos', DMT_Amount__c = 0),
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Depos', DMT_Amount__c = null)
        };

        String result = renderer.renderHtml(data);

        Assert.isFalse(result.contains('DEPOS RISK LINE'), 'Depos with only zero/null amounts must NOT render the DEPOS table.');
    }

    @IsTest
    static void testEquitiesWithPositiveAmountRendersEquitiesTable() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Default Geography Line', CurrencyIsoCode = 'EUR');
        data.lineProductList = new List<DMT_Line_Product_Item__c>();
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Equities', DMT_Amount__c = 50000)
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('EQUITIES WWR RISK LINE'), 'Equities with positive amount must render the EQUITIES table.');
    }

    @IsTest
    static void testEquitiesWithZeroOrNullAmountNoEquitiesTable() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Default Geography Line', CurrencyIsoCode = 'EUR');
        data.lineProductList = new List<DMT_Line_Product_Item__c>();
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Equities', DMT_Amount__c = 0),
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Equities', DMT_Amount__c = null)
        };

        String result = renderer.renderHtml(data);

        Assert.isFalse(result.contains('EQUITIES WWR RISK LINE'), 'Equities with only zero/null amounts must NOT render the EQUITIES table.');
    }

    @IsTest
    static void testAllSectionsRenderedTogether() {
        DMT_TreasuryProductsRenderer renderer = new DMT_TreasuryProductsRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Default Geography Line', CurrencyIsoCode = 'EUR', Booking_Geography__c = 'ES');
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Derivatives', DMT_Amount__c = 100),
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Depos', DMT_Amount__c = 300),
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Equities', DMT_Amount__c = 400)
        };
        data.lineProductList = new List<DMT_Line_Product_Item__c>{
            new DMT_Line_Product_Item__c(Name = 'Product A', DMT_DerivativeRestriction__c = false, DMT_FDRestriction__c = false, DMT_DVPRestriction__c = false, Max_Tenor_WC__c = '6')
        };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('COUNTERPARTY RISK'), 'All sections: COUNTERPARTY RISK should be present.');
        Assert.isTrue(result.contains('AVAILABLE PRODUCTS'), 'All sections: AVAILABLE PRODUCTS should be present.');
        Assert.isTrue(result.contains('DEPOS RISK LINE'), 'All sections: DEPOS should be present.');
        Assert.isTrue(result.contains('EQUITIES WWR RISK LINE'), 'All sections: EQUITIES should be present.');
    }
}