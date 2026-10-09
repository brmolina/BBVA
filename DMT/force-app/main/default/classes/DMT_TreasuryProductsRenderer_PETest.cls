@IsTest
public class DMT_TreasuryProductsRenderer_PETest {

    private static DMT_ViewController.LineDataWrapper buildBaseData() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'PE Line', CurrencyIsoCode = 'EUR');
        return data;
    }

    @IsTest
    static void testNullData() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        String result = renderer.renderHtml(null);
        Assert.areEqual('', result, 'Null data must return empty string.');
    }

    @IsTest
    static void testNullLine() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = null;
        String result = renderer.renderHtml(data);
        Assert.areEqual('', result, 'Null line must return empty string.');
    }

    @IsTest
    static void testNullLineProductList() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'PE Line');
        data.lineProductList = null;
        String result = renderer.renderHtml(data);
        Assert.areEqual('', result, 'Null lineProductList must return empty string.');
    }

    @IsTest
    static void testEmptyListsRendersDvpAndOneOffSection() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = buildBaseData();
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'Empty lists must produce a non-null result.');
        Assert.isTrue(result.contains('PRODUCTS'), 'Result should contain the PRODUCTS header.');
        Assert.isTrue(result.contains('ONE-OFF-TRANSACTION'), 'Result should always include the ONE-OFF-TRANSACTION table.');
        Assert.isTrue(!result.contains('COUNTERPARTY RISK'), 'No derivatives means no COUNTERPARTY RISK table.');
        Assert.isTrue(!result.contains('DEPOS RISK LINE'), 'No depos means no DEPOS table.');
        Assert.isTrue(!result.contains('AVAILABLE PRODUCTS'), 'Empty lineProductList means no AVAILABLE PRODUCTS table.');
    }

    @IsTest
    static void testDerivativesNonSingularRendersCounterpartyRisk() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = buildBaseData();
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
    static void testDerivativesSingularRendersOneOffRows() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = buildBaseData();
        String riskJson = '{"DMT_Risk_Type__c":"Derivatives","DMT_Singular__c":true,'
            + '"DMT_Amount__c":50000,"DMT_Singular_Active__c":true,"DMT_Singular_Operation__c":"FX Swap"}';
        DMT_Risk_Line_Term__c singularLine = (DMT_Risk_Line_Term__c) JSON.deserialize(riskJson, DMT_Risk_Line_Term__c.class);
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{ singularLine };
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('FX Swap'), 'Singular Derivatives operation name should appear in ONE-OFF-TRANSACTION.');
        Assert.isTrue(result.contains('Yes'), 'Active singular should render Yes.');
    }

    @IsTest
    static void testDerivativesSingularInactiveRendersNo() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = buildBaseData();
        String riskJson = '{"DMT_Risk_Type__c":"Derivatives","DMT_Singular__c":true,'
            + '"DMT_Singular_Active__c":false,"DMT_Singular_Operation__c":"IRS"}';
        DMT_Risk_Line_Term__c singularLine = (DMT_Risk_Line_Term__c) JSON.deserialize(riskJson, DMT_Risk_Line_Term__c.class);
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{ singularLine };
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('No'), 'Inactive singular should render No in ACTIVE column.');
    }

    @IsTest
    static void testDeposWithPositiveAmountRendersDeposTable() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = buildBaseData();
        DMT_Risk_Line_Term__c deposLine = new DMT_Risk_Line_Term__c(
            DMT_Risk_Type__c = 'Depos',
            DMT_Amount__c = 200000
        );
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{ deposLine };
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('DEPOS RISK LINE'), 'Depos with positive amount must render the DEPOS table.');
    }

    @IsTest
    static void testDeposWithZeroAmountNoDeposTable() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = buildBaseData();
        DMT_Risk_Line_Term__c deposLine = new DMT_Risk_Line_Term__c(
            DMT_Risk_Type__c = 'Depos',
            DMT_Amount__c = 0
        );
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{ deposLine };
        String result = renderer.renderHtml(data);
        Assert.isTrue(!result.contains('DEPOS RISK LINE'), 'Depos with zero amount must NOT render the DEPOS table.');
    }

    @IsTest
    static void testDeposWithNullAmountNoDeposTable() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = buildBaseData();
        DMT_Risk_Line_Term__c deposLine = new DMT_Risk_Line_Term__c(
            DMT_Risk_Type__c = 'Depos',
            DMT_Amount__c = null
        );
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{ deposLine };
        String result = renderer.renderHtml(data);
        Assert.isTrue(!result.contains('DEPOS RISK LINE'), 'Depos with null amount must NOT render the DEPOS table.');
    }

    @IsTest
    static void testLineProductListRendersOperationalRestrictions() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = buildBaseData();
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
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_ViewController.LineDataWrapper data = buildBaseData();
        DMT_Risk_Line_Term__c singularActive = (DMT_Risk_Line_Term__c) JSON.deserialize(
            '{"DMT_Risk_Type__c":"Derivatives","DMT_Singular__c":true,"DMT_Singular_Active__c":true,"DMT_Amount__c":50}',
            DMT_Risk_Line_Term__c.class
        );
        data.riskLineList = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Derivatives', DMT_Singular__c = false, DMT_Amount__c = 100),
            singularActive,
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Depos', DMT_Amount__c = 300)
        };
        data.lineProductList = new List<DMT_Line_Product_Item__c>{
            new DMT_Line_Product_Item__c(Name = 'Product A', DMT_DerivativeRestriction__c = false, DMT_FDRestriction__c = false, DMT_DVPRestriction__c = false)
        };
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('COUNTERPARTY RISK'), 'All sections: COUNTERPARTY RISK should be present.');
        Assert.isTrue(result.contains('DEPOS RISK LINE'), 'All sections: DEPOS table should be present.');
        Assert.isTrue(result.contains('AVAILABLE PRODUCTS'), 'All sections: AVAILABLE PRODUCTS table should be present.');
    }

        @IsTest
    static void testSortRiskLines() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        List<DMT_Risk_Line_Term__c> riskLines = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Derivatives', DMT_Singular__c = false),
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Derivatives', DMT_Singular__c = true),
            new DMT_Risk_Line_Term__c(DMT_Risk_Type__c = 'Depos')
        };
        Map<String, List<DMT_Risk_Line_Term__c>> result = renderer.sortRiskLines(riskLines);
        Assert.areEqual(1, result.get('DerivativesNonSingular').size(), 'Should classify one non-singular derivative.');
        Assert.areEqual(1, result.get('DerivativesSingular').size(), 'Should classify one singular derivative.');
        Assert.areEqual(1, result.get('Depos').size(), 'Should classify one depo.');
    }

    @IsTest
    static void testCreatePageBreak() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        Map<String, Object> result = renderer.createPageBreak();
        Assert.areEqual('pageBreak', result.get('type'), 'Page break type must match.');
        Assert.areEqual(30, result.get('threshold'), 'Page break threshold must match.');
    }

    @IsTest
    static void testCreateDerivativesTable() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        List<DMT_Risk_Line_Term__c> riskLines = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Init_Term__c = '12', DMT_End_Term__c = '24', DMT_Amount__c = 1000)
        };
        Map<String, Object> result = renderer.createDerivativesTable(riskLines, 'EUR');
        Assert.areEqual('table', result.get('type'), 'Table type must match.');
        List<List<String>> body = (List<List<String>>) result.get('body');
        Assert.areEqual(1, body.size(), 'Body should have one row.');
    }

    @IsTest
    static void testCreateSingularTable() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        String riskJson = '{"DMT_Singular_Operation__c":"FX Swap","DMT_Amount__c":500,'
            + '"DMT_Term__c":"12","DMT_Singular_Active__c":true}';
        DMT_Risk_Line_Term__c singularLine = (DMT_Risk_Line_Term__c) JSON.deserialize(riskJson, DMT_Risk_Line_Term__c.class);
        Map<String, Object> result = renderer.createSingularTable(new List<DMT_Risk_Line_Term__c>{ singularLine });
        List<List<String>> body = (List<List<String>>) result.get('body');
        Assert.areEqual('FX Swap', body[0][0], 'First column should be the operation name.');
        Assert.areEqual('Yes', body[0][4], 'Active flag should render as Yes.');
    }

    @IsTest
    static void testHasPositiveDepos() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        Boolean positiveResult = renderer.hasPositiveDepos(new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Amount__c = 100)
        });
        Boolean zeroResult = renderer.hasPositiveDepos(new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Amount__c = 0)
        });
        Boolean nullResult = renderer.hasPositiveDepos(new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Amount__c = null)
        });
        Assert.isTrue(positiveResult, 'Positive amount should return true.');
        Assert.isFalse(zeroResult, 'Zero amount should return false.');
        Assert.isFalse(nullResult, 'Null amount should return false.');
    }

    @IsTest
    static void testCreateDeposTable() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        List<DMT_Risk_Line_Term__c> riskLines = new List<DMT_Risk_Line_Term__c>{
            new DMT_Risk_Line_Term__c(DMT_Init_Term__c = '6', DMT_End_Term__c = '18', DMT_Amount__c = 2000)
        };
        Map<String, Object> result = renderer.createDeposTable(riskLines, 'USD');
        List<List<String>> body = (List<List<String>>) result.get('body');
        Assert.areEqual(1, body.size(), 'Body should have one row.');
    }

    @IsTest
    static void testCreateRestrictionsTable() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        List<DMT_Line_Product_Item__c> products = new List<DMT_Line_Product_Item__c>{
            new DMT_Line_Product_Item__c(Name = 'FX', DMT_DerivativeRestriction__c = true, DMT_FDRestriction__c = false, DMT_DVPRestriction__c = true)
        };
        Map<String, Object> result = renderer.createRestrictionsTable(products, 'EUR');
        Assert.isTrue(result.containsKey('columnStyles'), 'Restrictions table must include columnStyles.');
    }

    @IsTest
    static void testCreateTableAndStyleHelpers() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        Map<String, Object> table = renderer.createTable(
            new List<List<String>>{ new List<String>{'H1', 'H2'} },
            new List<List<String>>{ new List<String>{'A', 'B'} }
        );
        Assert.areEqual('table', table.get('type'), 'Table type must match.');
        Assert.isNotNull(renderer.getTableStyles(), 'Table styles must not be null.');
        Assert.isNotNull(renderer.getHeadStyles(), 'Head styles must not be null.');
        Assert.isNotNull(renderer.getMarginTable(), 'Margin table must not be null.');
    }

    // CIBGLOBALD-4117 - this renderer now self-reports its own tracked fields instead of relying on
    // DMT_TreasuryProductsRenderer's union - confirms it is self-contained.
    @IsTest
    static void testTrackingMethodsAreSelfContained() {
        DMT_TreasuryProductsRenderer_PE renderer = new DMT_TreasuryProductsRenderer_PE();
        DMT_Line__c record = new DMT_Line__c();

        Set<String> lineFields = new Set<String>(renderer.getTrackedFields(record));
        Assert.isTrue(lineFields.contains('Booking_Geography__c'), 'Must self-fold the geography switch field.');
        Assert.isTrue(lineFields.contains('DvP_Amount__c'), 'Must track its own displayed fields.');

        Map<String, List<String>> byObject = renderer.getTrackedFieldsByObject(record);
        Assert.areEqual(lineFields, new Set<String>(byObject.get('DMT_Line__c')), 'DMT_Line__c key must match getTrackedFields exactly.');
        Assert.isTrue(new Set<String>(byObject.get('DMT_Risk_Line_Term__c')).contains('DMT_Singular_DvP__c'), 'Must track its own Singular-transaction fields.');
        Assert.isTrue(byObject.get('DMT_Line_Product_Item__c').contains('Max_Tenor_WC__c'), 'PE renders a Maturity Term column, unlike CO.');

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = renderer.getChildSections(record);
        Assert.areEqual(2, sections.size(), 'Must declare both child sections independently.');
    }
}