@IsTest
public class DMT_NBC_BasicFinancialsRendererTest {

    private static Id dmtOpportunityRecordTypeId() {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
    }

    @IsTest
    static void testBasicFinancialsPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Basic Financials',
            'DMT_NBC_BasicFinancialsRenderer',
            'DMT_NBC_OppBasicFinancialsRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    // CIBGLOBALD-4117 - the delegator has no field/section knowledge of its own: it routes to
    // whichever single renderer is active (same key as renderHtml) and returns exactly what that one
    // renderer declares.
    @IsTest
    static void testGetTrackedFieldsRoutesToIBFRenderer() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Basic Financials'),
            'NBC Basic Financials must be registered as a tracked component'
        );

        DMT_NBC_BasicFinancialsRenderer delegator = new DMT_NBC_BasicFinancialsRenderer();
        Opportunity opp = new Opportunity(RecordTypeId = dmtOpportunityRecordTypeId(), DMT_Product_Area__c = 'IB&F');

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must return the active (IB&F) renderer\'s own switch-field declaration'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{'Other_Relevant_Ratios_desc__c', 'cstk_sust_indicators_comments__c'},
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must track the two oppClient fields (same ones Approval Process Data already tracks)'
        );
        Assert.areEqual(
            new Set<String>{
                'DMT_Revenues_number__c', 'DMT_EBITDA_number__c', 'DMT_EBIT_number__c', 'DMT_Net_Income_number__c',
                'DMT_Free_Cash_Flow_number__c', 'DMT_Debt_EBITDA_number__c', 'DMT_Net_Debt_EBITDA_number__c',
                'DMT_Year__c', 'DMT_Booking_Geography__c'
            },
            new Set<String>(byObject.get('DMT_Opportunity_Business_Plan__c')),
            'Delegator must track the Basic Financials fields plus the year/geography discriminators'
        );
        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(byObject.get('Opportunity')),
            'getTrackedFieldsByObject must also carry the switch fields under the Opportunity key - resolveTrackedFieldsForItems never consults getTrackedFields() once getTrackedFieldsByObject() returns non-empty'
        );

        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> sectionsByKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        for (DMT_ApprovalChangeStep_Helper.ChildSection section : delegator.getChildSections(opp)) {
            sectionsByKey.put(section.snapshotSectionKey, section);
        }
        Assert.areEqual(2, sectionsByKey.size(), 'Exactly two child sections expected');

        DMT_ApprovalChangeStep_Helper.ChildSection clientSection = sectionsByKey.get('opportunityClient');
        Assert.isNotNull(clientSection, 'opportunityClient section must be declared, shared with Client/Approval Process Data/Basic Requeriment/Main Characteristics/Deal');
        Assert.areEqual('DMT_Opportunity_Client__c', clientSection.childObjectApiName, 'Client section object mismatch');
        Assert.areEqual('DMT_MDE_Opportunity__c', clientSection.childLookupField, 'Client section lookup mismatch');

        DMT_ApprovalChangeStep_Helper.ChildSection bpSection = sectionsByKey.get('opportunityBusinessPlan');
        Assert.isNotNull(bpSection, 'opportunityBusinessPlan section must be declared, shared with Approval Process Data');
        Assert.areEqual('DMT_Opportunity_Business_Plan__c', bpSection.childObjectApiName, 'Business Plan section object mismatch');
        Assert.areEqual('DMT_Opportunity__c', bpSection.childLookupField, 'Business Plan section lookup mismatch');
        Assert.areEqual('Id', bpSection.parentValueField, 'Business Plan section parent value mismatch');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToGTBRendererReturnsSwitchFieldsOnly() {
        DMT_NBC_BasicFinancialsRenderer delegator = new DMT_NBC_BasicFinancialsRenderer();
        Opportunity opp = new Opportunity(RecordTypeId = dmtOpportunityRecordTypeId(), DMT_Product_Area__c = 'GTB');

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'GTB still watches the switch fields even though it renders nothing else'
        );

        // GTB implements only DMT_FieldTrackableRenderer, not DMT_MultiObjectFieldTrackableRenderer -
        // its own getTrackedFieldsByObject() is the interface default (empty map), so
        // resolveTrackedFieldsForItems correctly falls back to getTrackedFields() (asserted above)
        // for this renderer instead.
        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.isTrue(byObject.isEmpty(), 'GTB has no multi-object declaration - the plain switch fields travel via getTrackedFields() instead');
        Assert.isTrue(delegator.getChildSections(opp).isEmpty(), 'GTB declares no child sections');
    }

    // ==================================================================
    // DMT_NBC_OppBasicFinancialsRenderer_IBF - direct unit tests
    // ==================================================================

    @IsTest
    static void testIbfRendererRendersGlobalBusinessPlanData() {
        DMT_NBC_OppBasicFinancialsRenderer_IBF renderer = new DMT_NBC_OppBasicFinancialsRenderer_IBF();
        Integer currentYear = Date.today().year();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'IBF Opp');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.oppAccountParentName = 'Parent Group';
        // Raw stored amounts, not millions - the renderer divides by 1,000,000 before formatting
        // to match the "(Figures in Mn)" header, so these are seeded large enough to survive that.
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'GLOBAL',
                DMT_Year__c = String.valueOf(currentYear),
                DMT_Revenues_number__c = 1234500000.0
            ),
            new DMT_Opportunity_Business_Plan__c(
                DMT_Booking_Geography__c = 'ES01',
                DMT_Year__c = String.valueOf(currentYear),
                DMT_Revenues_number__c = 9999000000.0
            )
        };

        String html = renderer.renderHtml(data);
        Assert.isTrue(html.contains('BASIC FINANCIALS - Parent Group'), 'Header should include comparison account name branch.');
        Assert.isTrue(html.contains('1.234,50'), 'GLOBAL business plan revenue value should appear formatted in millions: ' + html);
        Assert.isFalse(html.contains('9.999,00'), 'Non-GLOBAL geography record must not leak into the Opportunity-level grid.');
    }

    @IsTest
    static void testIbfRendererNullOppClientRendersGracefully() {
        DMT_NBC_OppBasicFinancialsRenderer_IBF renderer = new DMT_NBC_OppBasicFinancialsRenderer_IBF();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'IBF Null OppClient Opp');
        data.oppClient = null;

        String result = renderer.renderHtml(data);
        // Reading a field off a null sObject in Apex returns null rather than throwing
        // (unlike calling a method on one, e.g. getPopulatedFieldsAsMap()) - confirmed via
        // anonymous Apex. A null oppClient does not hit the catch block; it renders the
        // grid with blank Other Relevant Ratios / Comments sections instead.
        Assert.isTrue(result.contains('BASIC FINANCIALS'), 'A null oppClient must not prevent the Basic Financials grid from rendering.');
        Assert.isFalse(result.contains('<div>Error:'), 'A null oppClient is not an error condition.');
    }

    @IsTest
    static void testIbfRendererForcedExceptionReturnsError() {
        DMT_NBC_OppBasicFinancialsRenderer_IBF renderer = new DMT_NBC_OppBasicFinancialsRenderer_IBF();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'IBF Force Opp');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return controlled error HTML.');
    }

    @IsTest
    static void testIbfRendererGuardForEmptyDataReturnsMessage() {
        DMT_NBC_OppBasicFinancialsRenderer_IBF renderer = new DMT_NBC_OppBasicFinancialsRenderer_IBF();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity();
        data.oppClient = new DMT_Opportunity_Client__c();

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Empty wrapper must return the guard message.');
    }

    // ==================================================================
    // DMT_NBC_OppBasicFinancialsRenderer_GTB - direct unit tests
    // ==================================================================

    @IsTest
    static void testGtbRendererReturnsEmptyString() {
        DMT_NBC_OppBasicFinancialsRenderer_GTB renderer = new DMT_NBC_OppBasicFinancialsRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();

        String result = renderer.renderHtml(data);
        Assert.areEqual('', result, 'GTB stub is intentionally left empty, matching pre-split behavior - out of scope for this fix.');
    }

    @IsTest
    static void testGtbRendererForcedExceptionReturnsError() {
        DMT_NBC_OppBasicFinancialsRenderer_GTB renderer = new DMT_NBC_OppBasicFinancialsRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'GTB Force Opp', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return controlled error HTML.');
    }

    @IsTest
    static void testGtbRendererGuardForEmptyDataReturnsMessage() {
        DMT_NBC_OppBasicFinancialsRenderer_GTB renderer = new DMT_NBC_OppBasicFinancialsRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity();
        data.oppClient = new DMT_Opportunity_Client__c();

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Opportunity data not provided'), 'Empty wrapper must return the guard message.');
    }

    // ==================================================================
    // DMT_NBC_BasicFinancialsRenderer - delegator routing tests
    // ==================================================================

    @IsTest
    static void testDelegatorRoutesGtbProductAreaToGtbRenderer() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = dmtOpportunityRecordTypeId();
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_BasicFinancialsRenderer();
        String result = delegator.renderHtml(data);

        Assert.areEqual('', result, 'GTB product area should route to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToGtbRenderer() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = dmtOpportunityRecordTypeId();
        data.opportunity = new Opportunity(Name = 'IBF Extension RCF Opp', DMT_Product_Area__c = 'IB&F', DMT_Capital_Action__c = 'Extension RCF & TL');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_BasicFinancialsRenderer();
        String result = delegator.renderHtml(data);

        Assert.areEqual('', result, 'IB&F with Extension RCF & TL should route to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorRoutesIbfLocalThresholdTypeStillRendersContent() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = dmtOpportunityRecordTypeId();
        data.opportunity = new Opportunity(Name = 'IBF Local Opp', DMT_Product_Area__c = 'IB&F', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_BasicFinancialsRenderer();
        String result = delegator.renderHtml(data);

        Assert.isTrue(result.contains('BASIC FINANCIALS'), 'Threshold Type is not part of the GTB/IBF routing decision; Local must not suppress content.');
    }
}