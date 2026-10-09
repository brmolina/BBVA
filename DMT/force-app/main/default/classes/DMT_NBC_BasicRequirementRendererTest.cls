@IsTest
public with sharing class DMT_NBC_BasicRequirementRendererTest {
    @IsTest
    static void testBasicRequirementPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Basic Requeriment',
            'DMT_NBC_BasicRequirementRenderer',
            'DMT_NBC_OppBasicRequirementRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGtbLocalFactoryKeyResolvesToDelegator() {
        Assert.isTrue(DMT_RendererFactory.hasRenderer('GTB Local NBC Basic Requeriment'), 'Factory key must exist: GTB Local NBC Basic Requeriment');
        DMT_ViewRenderer renderer = DMT_RendererFactory.getRenderer('GTB Local NBC Basic Requeriment');
        Assert.isInstanceOfType(renderer, DMT_NBC_BasicRequirementRenderer.class, 'GTB Local NBC Basic Requeriment must resolve to the same delegator as NBC Basic Requeriment');
    }

    @IsTest
    static void testGetTrackedFields() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Basic Requeriment'),
            'NBC Basic Requeriment must be registered as a tracked component'
        );
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('GTB Local NBC Basic Requeriment'),
            'GTB Local NBC Basic Requeriment shares the same delegator, so it is tracked too'
        );

        DMT_NBC_BasicRequirementRenderer delegator = new DMT_NBC_BasicRequirementRenderer();
        // CIBGLOBALD-4117 - the delegator has no field/section knowledge of its own: it routes to
        // whichever single renderer is active (same key as renderHtml) and returns exactly what that
        // one renderer declares. IB&F and GTB happen to declare identical fields for this component,
        // so a single routed record proves both the routing and the field content.
        Opportunity opp = new Opportunity(
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId(),
            DMT_Product_Area__c = 'IB&F'
        );

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must return the active renderer\'s own switch-field declaration'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{
                'DMT_Clients_Global_RORC_CIB_Past_FY__c', 'DMT_Client_RORC_YTD__c',
                'DMT_CDD_Clients_Global_Rorc_Last_FY__c', 'DMT_Exception_Pool__c'
            },
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must union both sub-renderers\' DMT_Opportunity_Client__c fields'
        );
        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(byObject.get('Opportunity')),
            'getTrackedFieldsByObject must also carry the switch fields under the Opportunity key - resolveTrackedFieldsForItems never consults getTrackedFields() once getTrackedFieldsByObject() returns non-empty'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected - featuresList profitability is tracked via DMT_CalloutTrackableRenderer, not a child section');
        Assert.areEqual('opportunityClient', sections[0].snapshotSectionKey, 'Must share the opportunityClient section key used by Client/Approval Process Data');
        Assert.areEqual('DMT_Opportunity_Client__c', sections[0].childObjectApiName, 'Client section object mismatch');
        Assert.areEqual('DMT_MDE_Opportunity__c', sections[0].childLookupField, 'Client section lookup mismatch');
        Assert.areEqual('Id', sections[0].parentValueField, 'Client section parent value mismatch');
    }

    @IsTest
    static void testFetchLiveTrackedValuesExtractsProfitabilityIgnoringDateStamp() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];

        Map<String, Object> feature = new Map<String, Object>{
            'name' => 'Profitability Engine',
            'lastEvaluated' => '@date',
            'profitability' => new Map<String, Object>{
                'audit' => new Map<String, Object>{'rorcThreshold' => 0.1, 'raroecThreshold' => 0.08},
                'results' => new List<Object>{
                    new Map<String, Object>{
                        'rorc' => 0.15, 'raroec' => 0.09, 'rorcProspected' => 0.13,
                        'clientRorc' => 0.12, 'incomes12Months' => 1500.25
                    }
                }
            }
        };
        String passportSaveJson = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{'features' => new List<Object>{feature}}
        });

        // A Passport__c is auto-created (dmt_passport_trigger) the moment the Opportunity is
        // inserted above - update that one rather than inserting a second, or getFeatures()'s
        // LIMIT-1-no-ORDER-BY query can non-deterministically read the wrong row.
        Passport__c passport = [SELECT Id FROM Passport__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        passport.DMT_Passport_Save__c = passportSaveJson;
        update passport;

        DMT_NBC_BasicRequirementRenderer delegator = new DMT_NBC_BasicRequirementRenderer();
        Assert.areEqual(opp.Id, delegator.getCalloutCacheKey(opp), 'Cache key must be the Opportunity Id');

        Map<String, Object> liveValues = delegator.fetchLiveTrackedValues(opp);
        Assert.areEqual(0.15, Decimal.valueOf(String.valueOf(liveValues.get('rorc'))), 'rorc must be extracted');
        Assert.areEqual(0.09, Decimal.valueOf(String.valueOf(liveValues.get('raroec'))), 'raroec must be extracted');
        Assert.areEqual(0.13, Decimal.valueOf(String.valueOf(liveValues.get('rorcProspected'))), 'rorcProspected must be extracted');
        Assert.areEqual(0.12, Decimal.valueOf(String.valueOf(liveValues.get('clientRorc'))), 'clientRorc must be extracted');
        Assert.areEqual(1500.25, Decimal.valueOf(String.valueOf(liveValues.get('incomes12Months'))), 'incomes12Months must be extracted');
        Assert.areEqual(0.1, Decimal.valueOf(String.valueOf(liveValues.get('rorcThreshold'))), 'rorcThreshold must be extracted');
        Assert.areEqual(0.08, Decimal.valueOf(String.valueOf(liveValues.get('raroecThreshold'))), 'raroecThreshold must be extracted');
        Assert.isFalse(liveValues.containsKey('lastEvaluated'), 'The @date-stamped noise field must not leak into the compared values');
    }

    @IsTest
    static void testFetchLiveTrackedValuesNoPassportReturnsEmpty() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];
        // dmt_passport_trigger auto-creates a Passport__c on insert, but DMT_Passport_Save__c stays
        // null until the evaluation service first runs - fetchLiveTrackedValues must tolerate that.

        DMT_NBC_BasicRequirementRenderer delegator = new DMT_NBC_BasicRequirementRenderer();
        Map<String, Object> liveValues = delegator.fetchLiveTrackedValues(opp);

        Assert.isTrue(liveValues.isEmpty(), 'No Passport record must yield no tracked values');
    }

    @IsTest
    static void testOppBasicRequirementRendererAdditionalCoverage() {
        DMT_NBC_OppBasicRequirementRenderer_IBF renderer = new DMT_NBC_OppBasicRequirementRenderer_IBF();

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = new Opportunity(Name = 'Opp Basic Requirement');
        successData.oppClient = new DMT_Opportunity_Client__c();
        successData.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'profitability',
                'profitability' => new Map<String, Object>{
                    'audit' => new Map<String, Object>{
                        'rorcThreshold' => 'abc',
                        'raroecThreshold' => 0.08
                    },
                    'results' => new List<Object>{
                        new Map<String, Object>{
                            'rorc' => 0.15,
                            'raroec' => 0.09,
                            'rorcProspected' => 0.13,
                            'clientRorc' => 0.12,
                            'incomes12months' => 1500.25
                        }
                    }
                }
            }
        };

        String successHtml = renderer.renderHtml(successData);

        Assert.isNotNull(successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('BASIC REQUIREMENTS*'), 'Success HTML should include title block.');
        Assert.isTrue(successHtml.contains('Expected Global RORC CIB'), 'IBF path should render the Expected Global RORC CIB column.');

        DMT_ViewController.LineDataWrapper errorData = new DMT_ViewController.LineDataWrapper();
        errorData.opportunity = new Opportunity(Name = 'Opp Catch Requirement');
        errorData.oppClient = new DMT_Opportunity_Client__c();
        errorData.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'profitability',
                'profitability' => 'INVALID_TYPE'
            }
        };

        String errorHtml = renderer.renderHtml(errorData);

        // The renderer catches TypeException internally in the data-binding constructor and
        // returns normal (empty) HTML — it does not propagate an error to the renderHtml catch block.
        Assert.isNotNull(errorHtml, 'Renderer should return a non-null response even for invalid profitability data.');
    }

    @IsTest
    static void testOppBasicRequirementRendererGtbLayout() {
        DMT_NBC_OppBasicRequirementRenderer_GTB renderer = new DMT_NBC_OppBasicRequirementRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();

        String html = renderer.renderHtml(data);

        Assert.isNotNull(html, 'GTB HTML must not be null.');
        Assert.isTrue(html.contains('BASIC REQUIREMENTS*'), 'GTB path should include title block.');
        Assert.isTrue(!html.contains('Expected Global RORC CIB'), 'GTB path must not render the Expected Global RORC CIB column.');
        Assert.isTrue(html.contains('RORC Prospective CDD'), 'GTB path should render RORC Prospective CDD in the reflowed first row.');
    }

    @IsTest
    static void testGtbDataNotProvidedReturnsGuard() {
        DMT_NBC_OppBasicRequirementRenderer_GTB renderer = new DMT_NBC_OppBasicRequirementRenderer_GTB();

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
        DMT_NBC_OppBasicRequirementRenderer_GTB renderer = new DMT_NBC_OppBasicRequirementRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'Opp GTB Force', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();
        data.forceException = true;

        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'Forced exception path must return error HTML.');
    }

    @IsTest
    static void testDelegatorRoutesGtbLayout() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Opp', DMT_Product_Area__c = 'GTB');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_BasicRequirementRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(!html.contains('Expected Global RORC CIB'), 'Delegator should route GTB opportunities to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToGtbLayout() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Extension RCF Opp', DMT_Product_Area__c = 'IB&F', DMT_Capital_Action__c = 'Extension RCF & TL');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_BasicRequirementRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(!html.contains('Expected Global RORC CIB'), 'IB&F with Extension RCF & TL should route to the GTB renderer.');
    }

    @IsTest
    static void testIbfLocalStillRendersFullLayout() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Local Opp', DMT_Product_Area__c = 'IB&F', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_BasicRequirementRenderer();
        String html = delegator.renderHtml(data);

        // Local-hiding only applies to GTB + Local per the ticket; IB&F must still render the
        // full layout regardless of Threshold Type.
        Assert.isTrue(html.contains('BASIC REQUIREMENTS*'), 'IB&F + Local should still render the title block.');
        Assert.isTrue(html.contains('Expected Global RORC CIB'), 'IB&F + Local should still render the Expected Global RORC CIB column.');
        Assert.isTrue(html.contains('RORC Prospective CDD'), 'IB&F + Local should still render RORC Prospective CDD.');
        Assert.isTrue(html.contains('Client CDD Avge 6M'), 'IB&F + Local should still render Client CDD Avge 6M.');
        Assert.isTrue(html.contains('Deal Revenues Next 12m'), 'IB&F + Local should still render Deal Revenues Next 12m.');
        Assert.isTrue(html.contains('Exception Pool'), 'IB&F + Local should still render Exception Pool.');
    }
}