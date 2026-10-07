@IsTest
public with sharing class DMT_NBC_ClientRendererTest {
    // Test coverage for DMT_NBC_OppClientRenderer_IBF / DMT_NBC_OppClientRenderer_GTB

    @IsTest
    static void testClientPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Client',
            'DMT_NBC_ClientRenderer',
            'DMT_NBC_OppClientRenderer_IBF'
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testClientPairForcedExceptionScenario() {
        DMT_NBC_RendererPairTestUtils.runPairTestsWithForcedException(
            'NBC Client',
            'DMT_NBC_ClientRenderer',
            'DMT_NBC_OppClientRenderer_IBF'
        );
        Assert.isTrue(true, 'Forced exception scenario is executed in shared utility and this class');
    }

    private static final Set<String> IBF_OPP_CLIENT_FIELDS = new Set<String>{
        'DMT_Sector_Head__c', 'DMT_Industry__c', 'DMT_External_Rating_SP__c',
        'DMT_External_Rating_Moodys__c', 'DMT_External_Rating_Fitch__c',
        'DMT_Guarantor_Name_Fiscal_ID__c', 'g_upd_lmscl_internal_ratg_type__c',
        'DMT_Scoring__c', 'DMT_Commitment_Deadline__c'
    };

    // CIBGLOBALD-4117 - the delegator has no field/section knowledge of its own: it routes to
    // whichever single renderer is active (same key as renderHtml) and returns exactly what that one
    // renderer declares. NBC Client is the one component where IB&F and GTB genuinely read different
    // plain Opportunity fields (New Client/Under X-Sell Monitoring vs Threshold Type/Structured GTB), so
    // routing to the wrong one would be caught by these two tests' distinct field sets.
    @IsTest
    static void testGetTrackedFieldsRoutesToIBFRenderer() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Client'),
            'NBC Client must be registered as a tracked component'
        );

        DMT_NBC_ClientRenderer delegator = new DMT_NBC_ClientRenderer();
        Opportunity opp = new Opportunity(RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(), DMT_Product_Area__c = 'IB&F');

        Assert.areEqual(
            new Set<String>{
                'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c',
                'DMT_NewClient__c', 'Name', 'DMT_Tenor__c', 'DMT_CurrencyText__c',
                'DMT_Opportunity_amount__c', 'DMT_CUR_Notional_Amount__c', 'DMT_GlobalBanker__c',
                'DMT_Under_X_Selling_Monitoring__c',
                'DMT_branch_id_c__c', 'DMT_Entity__c', 'Entific__c', 'DMT_Booking_EFAN__c'
            },
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must return the active (IB&F) renderer\'s own field declaration, not GTB\'s'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            IBF_OPP_CLIENT_FIELDS, new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must return the active (IB&F) renderer\'s own DMT_Opportunity_Client__c fields'
        );
        Assert.areEqual(
            new Set<String>(delegator.getTrackedFields(opp)),
            new Set<String>(byObject.get('Opportunity')),
            'getTrackedFieldsByObject must also carry the plain fields under the Opportunity key'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected from the IB&F renderer');
        Assert.areEqual('opportunityClient', sections[0].snapshotSectionKey, 'Section must be shared with Client/Approval Process Data/Basic Requeriment/Deal/Assessment');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToGTBRenderer() {
        DMT_NBC_ClientRenderer delegator = new DMT_NBC_ClientRenderer();
        Opportunity opp = new Opportunity(RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(), DMT_Product_Area__c = 'GTB');

        Assert.areEqual(
            new Set<String>{
                'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c', 'Name',
                'DMT_Tenor__c', 'DMT_CurrencyText__c', 'DMT_Opportunity_amount__c', 'DMT_CUR_Notional_Amount__c',
                'DMT_GlobalBanker__c', 'DMT_Structured_GTB__c',
                'DMT_branch_id_c__c', 'DMT_Entity__c', 'Entific__c', 'DMT_Booking_EFAN__c'
            },
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must return the active (GTB) renderer\'s own field declaration, not IB&F\'s'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            IBF_OPP_CLIENT_FIELDS, new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'GTB declares the same DMT_Opportunity_Client__c fields as IB&F'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected from the GTB renderer');
    }

    @IsTest
    static void testFetchLiveTrackedValuesReturnsToolkitProfitabilityAndVisitFields() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        // Re-query with RecordTypeId/DMT_Product_Area__c: generateOpportunity()'s own SELECT omits
        // them, but the delegator needs both to resolve which single renderer is active (same as
        // Trigger.new would carry in production).
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];

        DMT_NBC_ClientRenderer delegator = new DMT_NBC_ClientRenderer();
        Assert.areEqual(opp.Id, delegator.getCalloutCacheKey(opp), 'Cache key must be the Opportunity Id');

        Map<String, Object> liveValues = delegator.fetchLiveTrackedValues(opp);
        Assert.isTrue(
            liveValues.containsKey('toolkitTri') && liveValues.containsKey('toolkitPositioning'),
            'Toolkit-derived keys must always be present, even when the test org has no cstk__Toolkit__c record for this Account'
        );
    }

    @IsTest
    static void testFetchLiveTrackedValuesExtractsOpportunityLevelAllIn() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        // Re-query with RecordTypeId/DMT_Product_Area__c: generateOpportunity()'s own SELECT omits
        // them, but the delegator needs both to resolve which single renderer is active.
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];
        Map<String, Object> feature = new Map<String, Object>{
            'name' => 'Profitability Engine',
            'profitability' => new Map<String, Object>{
                'results' => new List<Object>{
                    new Map<String, Object>{'allInDb' => 55, 'allInFb' => 12}
                }
            }
        };
        String passportSaveJson = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{'features' => new List<Object>{feature}}
        });
        Passport__c passport = [SELECT Id FROM Passport__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        passport.DMT_Passport_Save__c = passportSaveJson;
        update passport;

        DMT_NBC_ClientRenderer delegator = new DMT_NBC_ClientRenderer();
        Map<String, Object> liveValues = delegator.fetchLiveTrackedValues(opp);

        Assert.areEqual(55, Decimal.valueOf(String.valueOf(liveValues.get('allInDb'))), 'allInDb must be extracted from the Opportunity-level summary row');
        Assert.areEqual(12, Decimal.valueOf(String.valueOf(liveValues.get('allInFb'))), 'allInFb must be extracted from the Opportunity-level summary row');
    }

    @IsTest
    static void testOppClientRendererRenderHtmlWithValidData() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
    }

    @IsTest
    static void testOppClientRendererRenderHtmlWithForcedException() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.forceException = true;

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(result.contains('Error'), 'no error');
    }

    @IsTest
    static void testOppClientRendererGtbRenderHtmlWithForcedException() {
        DMT_NBC_OppClientRenderer_GTB renderer = new DMT_NBC_OppClientRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.forceException = true;

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(result.contains('Error'), 'GTB forced exception path must return error HTML');
    }

    @IsTest
    static void testOppClientRendererRenderHtmlWithUnderXSell() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.opportunity.DMT_Under_X_Selling_Monitoring__c = true;

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(result.contains('Under X-Sell Monitoring'), 'Under X-Sell Monitoring label should be rendered');
    }

    @IsTest
    static void testOppClientRendererRenderHtmlWithoutUnderXSell() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.opportunity.DMT_Under_X_Selling_Monitoring__c = false;

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
    }

    @IsTest
    static void testOppClientRendererRenderHtmlWithEmptyPopulatedFields() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        data.opportunity = opp;
        data.oppClient = new DMT_Opportunity_Client__c();
        data.recordTypeId = String.valueOf(Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId());

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(result.contains('Client data not provided'), 'no error message');
    }

    @IsTest
    static void testOppClientRendererGtbRenderHtmlWithEmptyPopulatedFields() {
        DMT_NBC_OppClientRenderer_GTB renderer = new DMT_NBC_OppClientRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        data.opportunity = opp;
        data.oppClient = new DMT_Opportunity_Client__c();
        data.recordTypeId = String.valueOf(Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId());

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(result.contains('Client data not provided'), 'no error message');
    }

    @IsTest
    static void testOppClientRendererGetClientGroupString() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
    }

    @IsTest
    static void testOppClientRendererRenderHtmlNullData() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();

        String result = renderer.renderHtml(null);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(result.contains('Client data not provided'), 'no error message');
    }

    @IsTest
    static void testOppClientRendererFormatting() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.oppBookingGeography = 'Spain';

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
    }

    @IsTest
    static void testOppClientRendererRenderHtmlBuildsMainBlocks() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(!result.contains('Client data not provided'), 'renderHtml should not return no-data message');
        Assert.isTrue(!result.contains('<div>Error:'), 'renderHtml should not return catch error');
        Assert.isTrue(result.contains('<table style="width:97%; border-collapse:collapse; table-layout:fixed;">'), 'main table block should be rendered');
        Assert.isTrue(result.contains('Group / Client'), 'group/client block should be rendered');
        Assert.isTrue(result.contains('Type of Deal:'), 'type of deal block should be rendered');
        Assert.isTrue(result.contains('Sector Head'), 'sector head block should be rendered');
    }

    @IsTest
    static void testOppClientRendererRenderHtmlContainsStyleConstants() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(!result.contains('<div>Error:'), 'renderHtml should be successful to validate styles');
        Assert.isTrue(result.contains('background-color:#004481;'), 'container color style should be present');
        // Org renderer uses font-size:8px (not 10px) for the label style constant
        Assert.isTrue(result.contains('font-size:8px; font-weight:bold;'), 'label style should be present');
        Assert.isTrue(result.contains('border:1px solid #004481;'), 'value border style should be present');
    }

    @IsTest
    static void testOppClientRendererClientGroupUsesAccountNameWhenGroupBlank() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.clientGroupName = '';

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(!result.contains('Client data not provided'), 'renderer should process blank group path');
    }

    @IsTest
    static void testOppClientRendererClientGroupConcatenatesGroupAndAccount() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.clientGroupName = 'Parent Group Branch';

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(!result.contains('Client data not provided'), 'renderer should process concatenation branch');
    }

    @IsTest
    static void testOppClientRendererClientGroupUsesGroupWhenContainsAccount() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        String accountName = data.opportunity.Account != null ? data.opportunity.Account.Name : 'Account';
        data.clientGroupName = 'Client ' + accountName;

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(!result.contains('Client data not provided'), 'renderer should process contains-account branch');
    }

    @IsTest
    static void testOppClientRendererRenderHtmlWithNullBusinessPlans() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.businessPlanRecords = null;

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(!result.contains('Client data not provided'), 'renderer should process null business plan branch');
    }

    @IsTest
    static void testOppClientRendererRenderHtmlNonEmptyBusinessPlanWithoutNonXSell() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        DMT_Opportunity_Business_Plan__c bp = new DMT_Opportunity_Business_Plan__c();
        bp.DMT_Booking_Geography__c = 'ES01';
        bp.DMT_Active__c = true;
        data.businessPlanRecords = new List<DMT_Opportunity_Business_Plan__c>{ bp };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(!result.contains('Client data not provided'), 'renderer should process non-empty business plan without non x-sell');
    }

    @IsTest
    static void testOppClientRendererClientGroupEmptyWhenNoAccountId() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.opportunity.AccountId = null;
        data.opportunity.Account = null;
        data.clientGroupName = 'Should Not Render';

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'result is null');
        Assert.isTrue(!result.contains('Should Not Render'), 'client group should be empty when account id is null');
    }

    @IsTest
    static void testOppClientRendererGTBPath() {
        DMT_NBC_OppClientRenderer_GTB renderer = new DMT_NBC_OppClientRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'GTB path must return a non-null result.');
        Assert.isTrue(!result.contains('Client data not provided'), 'GTB path should not return no-data message.');
        Assert.isTrue(!result.contains('<div>Error:'), 'GTB path with valid data must not produce an error div.');
        Assert.isTrue(result.contains('Group / Client'), 'GTB path should render the Group / Client header.');
    }

    @IsTest
    static void testOppClientRendererGTBGlobalHidesOnlyOriginalThreeFields() {
        DMT_NBC_OppClientRenderer_GTB renderer = new DMT_NBC_OppClientRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.opportunity.DMT_Threshold_Type__c = 'Global';

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'GTB + Global must return a non-null result.');
        Assert.isTrue(!result.contains('Last Visit to the Client'), 'GTB always hides Last Visit to the Client.');
        Assert.isTrue(!result.contains('Prospect'), 'GTB always hides Prospect.');
        Assert.isTrue(!result.contains('Under X-Sell Monitoring'), 'GTB always hides Under X-Sell Monitoring.');
        Assert.isTrue(result.contains('Deal Amount Mn'), 'GTB + Global must still show Deal Amount Mn.');
        Assert.isTrue(result.contains('Commit. Deadline'), 'GTB + Global must still show Commitment Deadline.');
    }

    @IsTest
    static void testOppClientRendererGTBLocalHidesAllFiveFields() {
        DMT_NBC_OppClientRenderer_GTB renderer = new DMT_NBC_OppClientRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.opportunity.DMT_Threshold_Type__c = 'Local';

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'GTB + Local must return a non-null result.');
        Assert.isTrue(!result.contains('Last Visit to the Client'), 'GTB + Local hides Last Visit to the Client.');
        Assert.isTrue(!result.contains('Prospect'), 'GTB + Local hides Prospect.');
        Assert.isTrue(!result.contains('Under X-Sell Monitoring'), 'GTB + Local hides Under X-Sell Monitoring.');
        Assert.isTrue(!result.contains('Deal Amount Mn'), 'GTB + Local additionally hides Deal Amount Mn.');
        Assert.isTrue(!result.contains('Commit. Deadline'), 'GTB + Local additionally hides Commitment Deadline.');
        Assert.isTrue(result.contains('Group / Client'), 'GTB + Local must still render unrelated fields.');
        Assert.isTrue(result.contains('BBVA Commit. Mn'), 'GTB + Local must still render BBVA Commit. Mn.');
    }

    @IsTest
    static void testOppClientRendererLastVisitClientSet() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.lastVisitClient = Date.today();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Non-null lastVisitClient must not crash the renderer.');
        Assert.isTrue(!result.contains('<div>Error:'), 'lastVisitClient set should render successfully.');
    }

    @IsTest
    static void testOppClientRendererBothRatingAndScoringBlank() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.oppClient.g_upd_lmscl_internal_ratg_type__c = null;
        data.oppClient.DMT_Scoring__c = null;

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Blank rating and scoring must render without crash.');
    }

    @IsTest
    static void testOppClientRendererIBFPath() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'IBF path must return a non-null result.');
        Assert.isTrue(!result.contains('Client data not provided'), 'IBF path should not return no-data message.');
        Assert.isTrue(!result.contains('<div>Error:'), 'IBF path with valid data must not produce an error div.');
        Assert.isTrue(result.contains('Under X-Sell Monitoring'), 'IBF path should render Under X-Sell Monitoring.');
        Assert.isTrue(result.contains('Last Visit to the Client'), 'IBF path should render Last Visit to the Client.');
    }

    @IsTest
    static void testOppClientRendererIBFPathWithNullLastVisit() {
        DMT_NBC_OppClientRenderer_IBF renderer = new DMT_NBC_OppClientRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.lastVisitClient = null;

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'IBF path with null lastVisit must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'IBF path with null lastVisit must not produce an error div.');
    }

    @IsTest
    static void testDelegatorRoutesGtbLocalToGtbRenderer() {
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.opportunity.DMT_Product_Area__c = 'GTB';
        data.opportunity.DMT_Threshold_Type__c = 'Local';

        DMT_ViewRenderer delegator = new DMT_NBC_ClientRenderer();
        String result = delegator.renderHtml(data);

        Assert.isNotNull(result, 'Delegator must return a non-null result for GTB + Local.');
        Assert.isTrue(!result.contains('Deal Amount Mn'), 'Delegator should route GTB + Local opportunities to the GTB renderer, hiding Deal Amount Mn.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToGtbRenderer() {
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.opportunity.DMT_Product_Area__c = 'IB&F';
        data.opportunity.DMT_Capital_Action__c = 'Extension RCF & TL';

        DMT_ViewRenderer delegator = new DMT_NBC_ClientRenderer();
        String result = delegator.renderHtml(data);

        Assert.isNotNull(result, 'Delegator must return a non-null result for IB&F + Extension RCF & TL.');
        Assert.isTrue(!result.contains('Under X-Sell Monitoring'), 'IB&F with Extension RCF & TL should route to the GTB renderer, hiding Under X-Sell Monitoring.');
    }

    @IsTest
    static void testDelegatorKeepsIbfLocalFieldsVisible() {
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.opportunity.DMT_Product_Area__c = 'IB&F';
        data.opportunity.DMT_Threshold_Type__c = 'Local';

        DMT_ViewRenderer delegator = new DMT_NBC_ClientRenderer();
        String result = delegator.renderHtml(data);

        Assert.isNotNull(result, 'Delegator must return a non-null result for IB&F + Local.');
        Assert.isTrue(result.contains('Deal Amount Mn'), 'Local-hiding only applies to GTB + Local per the ticket; IB&F must render Deal Amount Mn regardless of Threshold Type.');
    }

    private static DMT_ViewController.LineDataWrapper buildValidWrapperForTesting() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);
        DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);

        data.opportunity = [
            SELECT Id, Name, RecordTypeId, DMT_Product_Area__c, DMT_CurrencyText__c, DMT_CUR_Notional_Amount__c, DMT_Opportunity_amount__c, bbva_prtcp_tranche_amount__c, DMT_Capital_Action__c, DMT_Tenor__c, DMT_GlobalBanker__c, AccountId, Account.Name,
                DMT_Booking_EFAN__c, DMT_Structured_GTB__c, DMT_NewClient__c, DMT_Under_X_Selling_Monitoring__c,
                (SELECT Id, Product2Id, Product2.Name FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];
        // Populated explicitly (not queried above) so the GTB renderer can read it without an SObjectException;
        // defaults to Global so existing tests keep exercising the original 3-field GTB hide-list.
        data.opportunity.DMT_Threshold_Type__c = 'Global';
        data.recordTypeId = String.valueOf(data.opportunity.RecordTypeId);
        data.clientAccount = data.opportunity.Account;
        data.oppClient = [
            SELECT  Id, DMT_MDE_Opportunity__c, DMT_Sector_Head__c, DMT_Industry__c, g_upd_lmscl_internal_ratg_type__c, DMT_Scoring__c, DMT_External_Rating_SP__c, DMT_External_Rating_Moodys__c, DMT_External_Rating_Fitch__c, DMT_tri__c, DMT_positioning__c, DMT_Commitment_Deadline__c, DMT_Guarantor_Name_Fiscal_ID__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :baseOpp.Id
            LIMIT 1
        ];

        // Ensure oppClient has populated fields for testing
        data.oppClient.DMT_Sector_Head__c = 'Head1';
        data.oppClient.DMT_Industry__c = 'Ind1';
        data.oppClient.g_upd_lmscl_internal_ratg_type__c = 'Rating1';

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
}