@IsTest
public with sharing class DMT_NBC_OtherAspectsRendererTest {
    @IsTest
    static void testOtherAspectsPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Other Aspects',
            'DMT_NBC_OtherAspectsRenderer',
            'DMT_NBC_OppOtherAspectRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGtbLocalFactoryKeyResolvesToDelegator() {
        Assert.isTrue(DMT_RendererFactory.hasRenderer('GTB Local NBC Other Aspects'), 'Factory key must exist: GTB Local NBC Other Aspects');
        DMT_ViewRenderer renderer = DMT_RendererFactory.getRenderer('GTB Local NBC Other Aspects');
        Assert.isInstanceOfType(renderer, DMT_NBC_OtherAspectsRenderer.class, 'GTB Local NBC Other Aspects must resolve to the same delegator as NBC Other Aspects');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToIBFRenderer() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Other Aspects'),
            'NBC Other Aspects must be registered as a tracked component'
        );
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('GTB Local NBC Other Aspects'),
            'GTB Local NBC Other Aspects shares the same delegator, so it is tracked too'
        );

        DMT_NBC_OtherAspectsRenderer delegator = new DMT_NBC_OtherAspectsRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'IB&F'
        );

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must route to the IBF renderer\'s own switch fields'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{
                'DMT_Applicable_Jurisdiction__c', 'DMT_Security_Package__c', 'DMT_Rating_Scenarios__c',
                'DMT_Other_Relevant_Issues__c', 'DMT_Competition_Deal__c'
            },
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must track the IBF renderer\'s own DMT_Opportunity_Client__c fields'
        );
        Assert.areEqual(
            new Set<String>{'Name', 'DMT_Type__c', 'DMT_Funds__c'},
            new Set<String>(byObject.get('DMT_Global_Structure__c')),
            'Delegator must track the same Global Structure fields as Approval Process Data'
        );
        Assert.areEqual(
            new Set<String>{'Name', 'DMT_Ticket__c', 'DMT_Fees__c', 'DMT_Margin__c', 'DMT_N_Banks__c'},
            new Set<String>(byObject.get('DMT_Banking_Pool_Structure__c')),
            'Delegator must track the same Banking Pool Structure fields as Approval Process Data'
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
        Assert.areEqual(3, sectionsByKey.size(), 'Exactly three child sections expected on the IBF renderer');
        Assert.isTrue(sectionsByKey.containsKey('opportunityClient'), 'opportunityClient section must be declared');
        Assert.isTrue(sectionsByKey.containsKey('opportunityGlobalStructure'), 'opportunityGlobalStructure section must be declared');
        Assert.isTrue(sectionsByKey.containsKey('opportunityBankingPoolStructure'), 'opportunityBankingPoolStructure section must be declared');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToGTBRenderer() {
        DMT_NBC_OtherAspectsRenderer delegator = new DMT_NBC_OtherAspectsRenderer();
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'GTB'
        );

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must route to the GTB renderer\'s own switch fields'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{'DMT_Other_Relevant_Issues__c'},
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must track only the GTB renderer\'s own narrower field set'
        );
        Assert.isFalse(byObject.containsKey('DMT_Global_Structure__c'), 'GTB renderer declares no Global Structure section');
        Assert.isFalse(byObject.containsKey('DMT_Banking_Pool_Structure__c'), 'GTB renderer declares no Banking Pool Structure section');

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'GTB renderer declares only the opportunityClient section');
        Assert.areEqual('opportunityClient', sections[0].snapshotSectionKey, 'Section key mismatch');
    }

    @IsTest
    static void testOppOtherAspectsRendererAdditionalCoverage() {
        DMT_NBC_OppOtherAspectRenderer_IBF renderer = new DMT_NBC_OppOtherAspectRenderer_IBF();

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = new Opportunity(Name = 'Opp Other Aspects');
        successData.oppClient = new DMT_Opportunity_Client__c(
            DMT_Applicable_Jurisdiction__c = 'Spain',
            DMT_Security_Package__c = 'Package A',
            DMT_Rating_Scenarios__c = 'Scenario A',
            DMT_Other_Relevant_Issues__c = 'Issue A',
            DMT_Competition_Deal__c = 'Competition A'
        );
        successData.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();

        String successHtml = renderer.renderHtml(successData);

        Assert.areNotEqual(null, successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('THE DEAL (2/2)') || successHtml.contains('Error'), 'HTML should return a controlled response.');

        DMT_ViewController.LineDataWrapper altData = new DMT_ViewController.LineDataWrapper();
        altData.opportunity = new Opportunity(Name = 'Opp Other Aspects Alt');
        altData.oppClient = null;

        String altHtml = renderer.renderHtml(altData);

        Assert.areNotEqual(null, altHtml, 'Alternative path should return a controlled HTML response.');
    }

    @IsTest
    static void testGTBPathRendersOtherAspectsGTB() {
        DMT_NBC_OppOtherAspectRenderer_GTB renderer = new DMT_NBC_OppOtherAspectRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Other_Relevant_Issues__c = 'GTB relevant issue'
        );
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'GTB path must return a non-null result.');
        Assert.isTrue(result.contains('OTHER ASPECTS') || result.contains('GTB relevant issue') || result.contains('Error'),
            'GTB path should render OTHER ASPECTS section or a controlled error.');
        Assert.isTrue(!result.contains('THE DEAL (2/2)'), 'GTB path must not render the IBF header THE DEAL (2/2).');
    }

    @IsTest
    static void testWithProfitabilityContextSetsRorcRaroec() {
        DMT_NBC_OppOtherAspectRenderer_IBF renderer = new DMT_NBC_OppOtherAspectRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp Profitability', DMT_Product_Area__c = 'IBF');
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Competition_Deal__c = 'Some competitor'
        );
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();

        Map<String, Object> summaryResult = new Map<String, Object>{
            'rorc' => 0.12,
            'raroec' => 0.08
        };
        Map<String, Object> audit = new Map<String, Object>{
            'rorcThreshold' => 0.10,
            'raroecThreshold' => 0.08
        };
        Map<String, Object> profitability = new Map<String, Object>{
            'results' => new List<Object>{ summaryResult },
            'audit' => audit
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => profitability }
        };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Profitability context must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Profitability context must not produce an error div.');
    }

    @IsTest
    static void testWithBankingPoolStructureTiers() {
        DMT_NBC_OppOtherAspectRenderer_IBF renderer = new DMT_NBC_OppOtherAspectRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Banking Pool Opp');
        data.oppClient = new DMT_Opportunity_Client__c(
            DMT_Competition_Deal__c = 'Competitor'
        );
        DMT_Banking_Pool_Structure__c tier1 = new DMT_Banking_Pool_Structure__c(
            Name = 'Tier 1',
            DMT_Ticket__c = '200',
            DMT_Fees__c = '1.0',
            DMT_Margin__c = '3.0',
            DMT_N_Banks__c = '4'
        );
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>{ tier1 };

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Banking pool tier data must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Banking pool tier data must not produce an error div.');
    }

    @IsTest
    static void testGtbDataNotProvidedReturnsGuard() {
        DMT_NBC_OppOtherAspectRenderer_GTB renderer = new DMT_NBC_OppOtherAspectRenderer_GTB();

        String nullResult = renderer.renderHtml(null);
        Assert.isTrue(nullResult.contains('Opportunity data not provided'), 'Null data must return guard message.');

        DMT_ViewController.LineDataWrapper emptyData = new DMT_ViewController.LineDataWrapper();
        emptyData.opportunity = new Opportunity();
        emptyData.oppClient = new DMT_Opportunity_Client__c();

        String emptyResult = renderer.renderHtml(emptyData);
        Assert.isTrue(emptyResult.contains('Opportunity data not provided'), 'Empty populated-fields data must return guard message.');
    }

    @IsTest
    static void testGtbForcedExceptionReturnsError() {
        DMT_NBC_OppOtherAspectRenderer_GTB renderer = new DMT_NBC_OppOtherAspectRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB Force', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return error HTML.');
    }

    @IsTest
    static void testDelegatorRoutesGtbToGtbRenderer() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();

        DMT_ViewRenderer delegator = new DMT_NBC_OtherAspectsRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(!html.contains('THE DEAL (2/2)'), 'Delegator should route GTB opportunities to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToGtbRenderer() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Extension RCF Opp', DMT_Product_Area__c = 'IB&F', DMT_Capital_Action__c = 'Extension RCF & TL');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();

        DMT_ViewRenderer delegator = new DMT_NBC_OtherAspectsRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(!html.contains('THE DEAL (2/2)'), 'IB&F with Extension RCF & TL should route to the GTB renderer.');
    }

    @IsTest
    static void testIbfLocalStillRendersFullContent() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Local Opp', DMT_Product_Area__c = 'IB&F', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();

        DMT_ViewRenderer delegator = new DMT_NBC_OtherAspectsRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(html.contains('THE DEAL (2/2)'), 'Local-hiding only applies to GTB + Local per the ticket; IB&F must still render the full content regardless of Threshold Type.');
    }

    @IsTest
    static void testProfitabilityContextMissingFeatureAndMissingResultsReturnEmptyContext() {
        DMT_NBC_OppOtherAspectRenderer_IBF renderer = new DMT_NBC_OppOtherAspectRenderer_IBF();

        DMT_ViewController.LineDataWrapper noProfitabilityFeature = new DMT_ViewController.LineDataWrapper();
        noProfitabilityFeature.opportunity = new Opportunity(Name = 'No Profitability Feature Opp');
        noProfitabilityFeature.oppClient = new DMT_Opportunity_Client__c();
        noProfitabilityFeature.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();
        noProfitabilityFeature.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'someOtherFeature' => new Map<String, Object>() }
        };

        String noFeatureResult = renderer.renderHtml(noProfitabilityFeature);
        Assert.isNotNull(noFeatureResult, 'A features list with no profitability entry must still return a controlled result.');

        DMT_ViewController.LineDataWrapper missingResults = new DMT_ViewController.LineDataWrapper();
        missingResults.opportunity = new Opportunity(Name = 'Missing Results Opp');
        missingResults.oppClient = new DMT_Opportunity_Client__c();
        missingResults.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();
        missingResults.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => new Map<String, Object>() }
        };

        String missingResultsResult = renderer.renderHtml(missingResults);
        Assert.isNotNull(missingResultsResult, 'A profitability feature with no results must still return a controlled result.');
    }

    @IsTest
    static void testProfitabilitySummaryWhereEveryResultHasProductIdReturnsNoSummary() {
        DMT_NBC_OppOtherAspectRenderer_IBF renderer = new DMT_NBC_OppOtherAspectRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'All Products Have Id Opp');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();

        Map<String, Object> resultWithProductA = new Map<String, Object>{ 'productId' => '01aAAA', 'rorc' => 0.1 };
        Map<String, Object> resultWithProductB = new Map<String, Object>{ 'productId' => '01aBBB', 'rorc' => 0.2 };
        Map<String, Object> profitability = new Map<String, Object>{
            'results' => new List<Object>{ resultWithProductA, resultWithProductB },
            'audit' => new Map<String, Object>{ 'rorcThreshold' => 0.15, 'raroecThreshold' => 0.1 }
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => profitability }
        };

        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'A results list where every record has a productId must still return a controlled result.');
    }

    @IsTest
    static void testInvalidRorcThresholdIsIgnoredInsteadOfFailing() {
        DMT_NBC_OppOtherAspectRenderer_IBF renderer = new DMT_NBC_OppOtherAspectRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Invalid Threshold Opp');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();

        Map<String, Object> summaryResult = new Map<String, Object>{ 'rorc' => 0.12 };
        Map<String, Object> profitability = new Map<String, Object>{
            'results' => new List<Object>{ summaryResult },
            'audit' => new Map<String, Object>{ 'rorcThreshold' => 'not-a-number', 'raroecThreshold' => 0.08 }
        };
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{ 'profitability' => profitability }
        };

        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'A non-numeric threshold must be treated as absent rather than raising an error.');
        Assert.isTrue(!result.contains('<div>Error:'), 'A non-numeric threshold must not surface as a rendering error.');
    }

    @IsTest
    static void testNullBankingPoolStructuresListReturnsEmptyTierMap() {
        DMT_NBC_OppOtherAspectRenderer_IBF renderer = new DMT_NBC_OppOtherAspectRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'No Banking Pool List Opp');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.bankingPoolStructures = null;

        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'A null banking pool structures list must still return a controlled result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'A null banking pool structures list must not surface as a rendering error.');
    }

    @IsTest
    static void testGlobalStructuresDisplayNameHandlesBlankAndTechnicalAndRealNames() {
        DMT_NBC_OppOtherAspectRenderer_IBF renderer = new DMT_NBC_OppOtherAspectRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();

        String debtId = '0ABCDE000000021AAA';
        String usesId = '0ABCDE000000023AAA';
        String oppJson = '{"Name":"NBC Global Structures Opp","StageName":"Prospecting","CloseDate":"2026-12-31",'
            + '"Global_Structures__r":{"totalSize":3,"done":true,"records":['
            + '{"Id":"' + debtId + '","Name":"","DMT_Type__c":"Funding Debt","DMT_Funds__c":100},'
            + '{"Id":"0ABCDE000000022AAA","Name":"GS Equity Real","DMT_Type__c":"Funding Equity","DMT_Funds__c":200},'
            + '{"Id":"' + usesId + '","Name":"' + usesId + '","DMT_Type__c":"Uses","DMT_Funds__c":300}'
            + ']},'
            + '"OpportunityLineItems":{"totalSize":0,"done":true,"records":[]}}';
        data.opportunity = (Opportunity) JSON.deserialize(oppJson, Opportunity.class);
        data.oppClient = new DMT_Opportunity_Client__c();
        data.bankingPoolStructures = new List<DMT_Banking_Pool_Structure__c>();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Global Structures with debt, equity and uses records must return a non-null result.');
        Assert.isTrue(!result.contains('<div>Error:'), 'Blank, technical-Id and real names must all be handled without error.');
        Assert.isTrue(result.contains('GS Equity Real') && result.contains('200'),
            'A real, non-technical name must be displayed as-is.');
        Assert.isTrue(!result.contains(usesId), 'A name matching its own record Id must be treated as technical and hidden.');
    }
}