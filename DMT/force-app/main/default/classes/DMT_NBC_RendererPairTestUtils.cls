@IsTest
public with sharing class DMT_NBC_RendererPairTestUtils {

    private static final String DMT_OPP_RT = 'DMT_Opportunity';

    /**
     * Runs common tests for a delegator/opportunity-renderer pair.
     * @param factoryKey Factory key used by DMT_RendererFactory.
     * @param delegatorClassName Delegator renderer class name.
     * @param oppClassName Opportunity renderer class name.
     */
    public static void runPairTests(
        String factoryKey,
        String delegatorClassName,
        String oppClassName
    ) {
        DMT_ViewRenderer factoryRenderer = DMT_RendererFactory.getRenderer(factoryKey);
        Assert.isTrue(DMT_RendererFactory.hasRenderer(factoryKey), 'Factory key must exist: ' + factoryKey);
        Assert.isInstanceOfType(factoryRenderer, Type.forName(delegatorClassName), 'Factory must return ' + delegatorClassName);

        DMT_ViewRenderer delegator = newRenderer(delegatorClassName);
        DMT_ViewController.LineDataWrapper valid = buildValidWrapper();
        assertDelegatorNullAndUnknown(delegator, valid);

        String delegatorValidHtml = delegator.renderHtml(valid);
        Assert.isNotNull(delegatorValidHtml, 'Delegator valid HTML must not be null');

        DMT_ViewRenderer oppRenderer = newRenderer(oppClassName);
        assertOppRendererNullAndValid(oppRenderer, valid);
    }

    /**
     * Backward-compatible overload used by existing tests in some environments.
     * @param factoryKey Factory key used by DMT_RendererFactory.
     * @param delegatorClassName Delegator renderer class name.
     * @param oppClassName Opportunity renderer class name.
     * @param runForcedExceptionScenario Whether to execute the forced exception branch.
     */
    public static void runPairTests(
        String factoryKey,
        String delegatorClassName,
        String oppClassName,
        Boolean runForcedExceptionScenario
    ) {
        if (runForcedExceptionScenario == true) {
            runPairTestsWithForcedException(factoryKey, delegatorClassName, oppClassName);
            return;
        }
        runPairTests(factoryKey, delegatorClassName, oppClassName);
    }

    /**
     * Runs common tests for a delegator/opportunity-renderer pair and forces the exception branch.
     * @param factoryKey Factory key used by DMT_RendererFactory.
     * @param delegatorClassName Delegator renderer class name.
     * @param oppClassName Opportunity renderer class name.
     */
    public static void runPairTestsWithForcedException(
        String factoryKey,
        String delegatorClassName,
        String oppClassName
    ) {
        DMT_ViewRenderer factoryRenderer = DMT_RendererFactory.getRenderer(factoryKey);
        Assert.isTrue(DMT_RendererFactory.hasRenderer(factoryKey), 'Factory key must exist: ' + factoryKey);
        Assert.isInstanceOfType(factoryRenderer, Type.forName(delegatorClassName), 'Factory must return ' + delegatorClassName);

        DMT_ViewRenderer delegator = newRenderer(delegatorClassName);
        DMT_ViewController.LineDataWrapper valid = buildValidWrapper();
        assertDelegatorNullAndUnknown(delegator, valid);

        String delegatorValidHtml = delegator.renderHtml(valid);
        Assert.isNotNull(delegatorValidHtml, 'Delegator valid HTML must not be null');

        DMT_ViewRenderer oppRenderer = newRenderer(oppClassName);
        assertOppRendererNullAndValid(oppRenderer, valid);

        Boolean previousForceException = valid.forceException;
        valid.forceException = true;
        String forcedHtml = oppRenderer.renderHtml(valid);
        valid.forceException = previousForceException;
        Assert.isTrue(forcedHtml.contains('Error'), 'Forced exception path must return error HTML');
    }

    /**
     * Runs common tests for a delegator/opportunity-renderer pair with forced exception scenario.
     * @param factoryKey Factory key used by DMT_RendererFactory.
     * @param delegatorClassName Delegator renderer class name.
     * @param oppClassName Opportunity renderer class name.
     */
    private static void runPairTestsWithException(
        String factoryKey,
        String delegatorClassName,
        String oppClassName
    ) {
        runPairTestsWithForcedException(factoryKey, delegatorClassName, oppClassName);
    }

    private static void assertDelegatorNullAndUnknown(
        DMT_ViewRenderer delegator,
        DMT_ViewController.LineDataWrapper valid
    ) {
        String delegatorNullHtml = delegator.renderHtml(null);
        Assert.isNotNull(delegatorNullHtml, 'Delegator null HTML must not be null');
        Assert.isTrue(delegatorNullHtml.contains('Error'), 'Delegator null HTML should return error');

        String previousRecordTypeId = valid.recordTypeId;
        valid.recordTypeId = buildUnknownRecordTypeId();
        String delegatorUnknownHtml = delegator.renderHtml(valid);
        valid.recordTypeId = previousRecordTypeId;
        Assert.isNotNull(delegatorUnknownHtml, 'Delegator unknown-RT HTML must not be null');
        Assert.isTrue(delegatorUnknownHtml.contains('Error'), 'Delegator unknown-RT HTML should return error');
    }

    private static void assertOppRendererNullAndValid(
        DMT_ViewRenderer oppRenderer,
        DMT_ViewController.LineDataWrapper valid
    ) {
        String oppNullHtml = oppRenderer.renderHtml(null);
        Assert.isNotNull(oppNullHtml, 'Opp renderer null HTML must not be null');

        String oppValidHtml = oppRenderer.renderHtml(valid);
        Assert.isNotNull(oppValidHtml, 'Opp renderer valid HTML must not be null');
    }

    private static DMT_ViewRenderer newRenderer(String className) {
        Type t = Type.forName(className);
        Assert.isNotNull(t, 'Class must exist: ' + className);
        return (DMT_ViewRenderer) t.newInstance();
    }

    private static Id rtId() {
        return Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get(DMT_OPP_RT)
            .getRecordTypeId();
    }

    private static DMT_ViewController.LineDataWrapper buildValidWrapper() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);
        DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);

        data.opportunity = [
            SELECT
                Id,
                Name,
                RecordTypeId,
                DMT_Product_Area__c,
                DMT_CurrencyText__c,
                DMT_CUR_Notional_Amount__c,
                bbva_prtcp_tranche_amount__c,
                DMT_Capital_Action__c,
                DMT_Threshold_Type__c,
                AccountId,
                Account.Name,
                DMT_NewClient__c,
                DMT_Under_X_Selling_Monitoring__c,
                (SELECT Id, Product2Id, Product2.Name FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];
        data.recordTypeId = String.valueOf(data.opportunity.RecordTypeId);
        data.clientAccount = data.opportunity.Account;
        data.oppClient = [
            SELECT Id, DMT_MDE_Opportunity__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :baseOpp.Id
            LIMIT 1
        ];

        data.line = new DMT_Line__c(Name = 'Test Line');
        data.oppBookingGeography = 'Spain';
        data.clientGroupName = 'Test Group';

        data.taxonomyH007BPMap = new Map<String, String>{
            'ES01' => 'Spain',
            '' => 'GLOBAL'
        };

        DMT_Opportunity_Business_Plan__c bp = new DMT_Opportunity_Business_Plan__c();
        bp.DMT_Booking_Geography__c = 'ES01';
        bp.DMT_Active__c = true;
        bp.DMT_Year__c = String.valueOf(Date.today().year());
        bp.DMT_Currency__c = 'EUR';
        bp.Current_FY_Total_X_Sell_amount__c = 100;
        bp.Current_FY_Total_Non_X_Sell_amount__c = 50;
        bp.Current_FY_Total_Revenues_amount__c = 150;
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{ bp };

        Map<String, Object> profitability = new Map<String, Object>{
            'results' => new List<Object>{
                new Map<String, Object>{ 'key' => 'sample', 'value' => 1 }
            }
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'name' => 'profitability', 'profitability' => profitability }
        };

        return data;
    }

    private static String buildUnknownRecordTypeId() {
        String knownRtId = String.valueOf(rtId());
        String lastChar = knownRtId.right(1);
        String replacement = lastChar == 'A' ? 'B' : 'A';
        return knownRtId.left(knownRtId.length() - 1) + replacement;
    }
}