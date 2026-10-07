@IsTest
public class DMT_DefaultLimitVisualRendererTest {

    @IsTest
    static void testNullDataReturnsGuardMessage() {
        DMT_DefaultLimitVisualRenderer renderer = new DMT_DefaultLimitVisualRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Limit Visual data not provided'), 'Null data must return guard message.');
    }

    @IsTest
    static void testEmptyFeaturesListReturnsGuardMessage() {
        DMT_DefaultLimitVisualRenderer renderer = new DMT_DefaultLimitVisualRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Limit Visual data not provided'), 'Empty featuresList must return guard message.');
    }

    @IsTest
    static void testSingleFeatureWithNoLimitsRendersWithoutError() {
        DMT_DefaultLimitVisualRenderer renderer = new DMT_DefaultLimitVisualRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        // First feature (i==0) — no traffic light header rendered, just table structure.
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'Feature One',
                'stateName' => 'GREEN',
                'consumptionLimits' => new List<Object>()
            }
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Single feature with no limits must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Single feature with no limits must not produce an error div.');
    }

    @IsTest
    static void testTwoFeaturesSecondWithRedStatusAndLimits() {
        DMT_DefaultLimitVisualRenderer renderer = new DMT_DefaultLimitVisualRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        Map<String, Object> limit1 = new Map<String, Object>{
            'amount' => new Map<String, Object>{ 'value' => 1000, 'currency' => 'EUR' },
            'type' => 'GLOBAL',
            'name' => 'Risk Limit'
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'Feature Zero', 'consumptionLimits' => new List<Object>() },
            new Map<String, Object>{
                'name' => 'Feature One',
                'stateName' => 'RED',
                'consumptionLimits' => new List<Object>{ limit1 }
            }
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Two features with RED second feature must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'RED traffic light path must not produce an error div.');
    }

    @IsTest
    static void testFeatureWithGreenStatusNoHeader() {
        DMT_DefaultLimitVisualRenderer renderer = new DMT_DefaultLimitVisualRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        Map<String, Object> limit1 = new Map<String, Object>{
            'amount' => new Map<String, Object>{ 'value' => 500, 'currency' => 'USD' }
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'First', 'consumptionLimits' => new List<Object>() },
            new Map<String, Object>{
                'name' => 'Second Feature',
                'stateName' => 'GREEN',
                'consumptionLimits' => new List<Object>{ limit1 }
            }
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'GREEN second feature must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'GREEN traffic light path must not produce an error div.');
    }

    @IsTest
    static void testFeatureWithUnknownStatusNameHasNoTrafficHeader() {
        DMT_DefaultLimitVisualRenderer renderer = new DMT_DefaultLimitVisualRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        Map<String, Object> limit1 = new Map<String, Object>{
            'amount' => new Map<String, Object>{ 'value' => 200, 'currency' => 'EUR' }
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'First', 'consumptionLimits' => new List<Object>() },
            new Map<String, Object>{
                'name' => 'Feature Unknown Status',
                'stateName' => 'UNKNOWN',
                'consumptionLimits' => new List<Object>{ limit1 }
            }
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Unknown stateName path must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Unknown stateName must not produce an error div.');
    }

    @IsTest
    static void testConsumptionLimitsAsTypedMapList() {
        DMT_DefaultLimitVisualRenderer renderer = new DMT_DefaultLimitVisualRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        Map<String, Object> limit1 = new Map<String, Object>{
            'amount' => new Map<String, Object>{ 'value' => 100, 'currency' => 'EUR' },
            'type' => 'GLOBAL'
        };
        List<Map<String, Object>> typedLimits = new List<Map<String, Object>>{ limit1 };

        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'First', 'consumptionLimits' => new List<Object>() },
            new Map<String, Object>{
                'name' => 'Second Feature',
                'stateName' => 'GREEN',
                'consumptionLimits' => typedLimits
            }
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Typed Map list consumptionLimits must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Typed Map list must not produce an error div.');
    }

    @IsTest
    static void testOpportunityPathWithProductsStructure() {
        DMT_DefaultLimitVisualRenderer renderer = new DMT_DefaultLimitVisualRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        // Opportunity path: data.opportunity is non-null with no Id (isOpportunity = false since Id is null).
        data.opportunity = new Opportunity(Name = 'Test Opp');

        Map<String, Object> limit1 = new Map<String, Object>{
            'amount' => new Map<String, Object>{ 'value' => 300, 'currency' => 'EUR' }
        };
        Map<String, Object> product = new Map<String, Object>{
            'consumptionLimits' => new List<Object>{ limit1 }
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'First', 'consumptionLimits' => new List<Object>() },
            new Map<String, Object>{
                'name' => 'Feature With Products',
                'stateName' => 'YELLOW',
                'products' => new List<Object>{ product }
            }
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Products structure must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Products structure must not produce an error div.');
    }
}