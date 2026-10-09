@IsTest
public with sharing class DMT_NBC_DealRendererTest {
    @IsTest
    static void testDealPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Deal',
            'DMT_NBC_DealRenderer',
            'DMT_NBC_OppDealRenderer_IBF',
            true
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGtbLocalFactoryKeyResolvesToDelegator() {
        Assert.isTrue(DMT_RendererFactory.hasRenderer('GTB Local NBC Deal'), 'Factory key must exist: GTB Local NBC Deal');
        DMT_ViewRenderer renderer = DMT_RendererFactory.getRenderer('GTB Local NBC Deal');
        Assert.isInstanceOfType(renderer, DMT_NBC_DealRenderer.class, 'GTB Local NBC Deal must resolve to the same delegator as NBC Deal');
    }

    @IsTest
    static void testGetTrackedFields() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Deal'),
            'NBC Deal must be registered as a tracked component'
        );
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('GTB Local NBC Deal'),
            'GTB Local NBC Deal shares the same delegator, so it is tracked too'
        );

        DMT_NBC_DealRenderer delegator = new DMT_NBC_DealRenderer();
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
            new Set<String>{'DMT_History_Deal__c', 'DMT_Guarantor_Name_Fiscal_ID__c'},
            new Set<String>(byObject.get('DMT_Opportunity_Client__c')),
            'Delegator must union both sub-renderers\' DMT_Opportunity_Client__c fields'
        );
        Assert.areEqual(
            new Set<String>{
                'Product2.Name', 'DMT_TXT_ProductNameOLI__c', 'DMT_Deal_amount__c', 'g_currency_id__c',
                'entity_role_type__c', 'underwriting_agreement_type__c', 'bbva_prtcp_tranche_amount__c',
                'syndicated_loan_drawn_amount__c', 'DMT_Sub_Limit__c', 'DMT_NewMoney_BBVA__c',
                'DMT_OldMoney_BBVA__c', 'gf_group_priority_opportunity_id__c'
            },
            new Set<String>(byObject.get('OpportunityLineItem')),
            'Delegator must union both sub-renderers\' OpportunityLineItem fields'
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
        Assert.isNotNull(clientSection, 'opportunityClient section must be declared, shared with Client/Approval Process Data/Basic Requeriment');
        Assert.areEqual('DMT_Opportunity_Client__c', clientSection.childObjectApiName, 'Client section object mismatch');
        Assert.areEqual('DMT_MDE_Opportunity__c', clientSection.childLookupField, 'Client section lookup mismatch');
        Assert.areEqual('Id', clientSection.parentValueField, 'Client section parent value mismatch');

        DMT_ApprovalChangeStep_Helper.ChildSection lineItemSection = sectionsByKey.get('opportunityLineItems');
        Assert.isNotNull(lineItemSection, 'opportunityLineItems section must be declared');
        Assert.areEqual('OpportunityLineItem', lineItemSection.childObjectApiName, 'Line item section object mismatch');
        Assert.areEqual('OpportunityId', lineItemSection.childLookupField, 'Line item section lookup mismatch');
        Assert.areEqual('Id', lineItemSection.parentValueField, 'Line item section parent value mismatch');
    }

    @IsTest
    static void testFetchLiveTrackedValuesExtractsPerProductProfitability() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        oli = [SELECT Id, gf_group_priority_opportunity_id__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        Assert.isNotNull(oli.gf_group_priority_opportunity_id__c, 'Test fixture must populate the product join key');

        Map<String, Object> feature = new Map<String, Object>{
            'name' => 'Profitability Engine',
            'profitability' => new Map<String, Object>{
                'results' => new List<Object>{
                    new Map<String, Object>{
                        'productId' => oli.gf_group_priority_opportunity_id__c,
                        'rorc' => 0.15, 'raroec' => 0.09, 'term' => 4.5,
                        'averageLife' => 3.2, 'regulatoryEad' => 310.4
                    },
                    new Map<String, Object>{
                        'productId' => 'SOME-OTHER-PRODUCT-NOT-ON-THIS-OPP',
                        'rorc' => 0.99
                    }
                }
            }
        };
        String passportSaveJson = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{'features' => new List<Object>{feature}}
        });
        Passport__c passport = [SELECT Id FROM Passport__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        passport.DMT_Passport_Save__c = passportSaveJson;
        update passport;

        DMT_NBC_DealRenderer delegator = new DMT_NBC_DealRenderer();
        Assert.areEqual(opp.Id, delegator.getCalloutCacheKey(opp), 'Cache key must be the Opportunity Id');

        Map<String, Object> liveValues = delegator.fetchLiveTrackedValues(opp);
        String prefix = oli.gf_group_priority_opportunity_id__c + ':';
        Assert.areEqual(0.15, Decimal.valueOf(String.valueOf(liveValues.get(prefix + 'rorc'))), 'rorc must be extracted for this product');
        Assert.areEqual(0.09, Decimal.valueOf(String.valueOf(liveValues.get(prefix + 'raroec'))), 'raroec must be extracted for this product');
        Assert.areEqual(4.5, Decimal.valueOf(String.valueOf(liveValues.get(prefix + 'term'))), 'term must be extracted for this product');
        Assert.areEqual(3.2, Decimal.valueOf(String.valueOf(liveValues.get(prefix + 'averageLife'))), 'averageLife must be extracted for this product');
        Assert.areEqual(310.4, Decimal.valueOf(String.valueOf(liveValues.get(prefix + 'regulatoryEad'))), 'regulatoryEad must be extracted for this product');
        Assert.isFalse(liveValues.containsKey('SOME-OTHER-PRODUCT-NOT-ON-THIS-OPP:rorc'), 'Profitability rows for products not on this Opportunity must be ignored');
    }

    @IsTest
    static void testFetchLiveTrackedValuesNoLineItemsReturnsEmpty() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];

        DMT_NBC_DealRenderer delegator = new DMT_NBC_DealRenderer();
        Map<String, Object> liveValues = delegator.fetchLiveTrackedValues(opp);

        Assert.isTrue(liveValues.isEmpty(), 'No OpportunityLineItems must yield no tracked values');
    }

    @IsTest
    static void testOppDealRendererAdditionalCoverage() {
        DMT_NBC_OppDealRenderer_IBF renderer = new DMT_NBC_OppDealRenderer_IBF();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);
        DMT_Opportunity_Client__c oppClient = DMT_Test_DataFactory.generateOpportunityClient(baseOpp.Id);

        oli.DMT_TXT_ProductNameOLI__c = 'Bridge Loan';
        oli.DMT_Deal_amount__c = 1234.56;
        oli.entity_role_type__c = 'Bookrunner';
        oli.underwriting_agreement_type__c = 'No';
        oli.bbva_prtcp_tranche_amount__c = 200.5;
        oli.syndicated_loan_drawn_amount__c = 180.25;
        oli.DMT_Sub_Limit__c = 'Sub-limit A';
        oli.DMT_NewMoney_BBVA__c = 75.25;
        oli.DMT_OldMoney_BBVA__c = 24.75;
        oli.DES_Tenor_years__c = 7;
        update oli;

        oppClient.DMT_History_Deal__c = 'Deal history for html coverage';
        oppClient.DMT_Guarantor_Name_Fiscal_ID__c = 'Guarantor Test';
        update oppClient;

        baseOpp = [
            SELECT Id, Name, RecordTypeId, DMT_Product_Area__c, Account.Name, Account.DES_ID_Fiscal__c,
                (
                    SELECT Id, Product2Id, Product2.Name, CurrencyIsoCode, DMT_TXT_ProductNameOLI__c,
                        DMT_Deal_amount__c, g_currency_id__c, entity_role_type__c, underwriting_agreement_type__c,
                        bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c, DMT_Sub_Limit__c,
                        DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DES_Tenor_years__c,
                        gf_group_priority_opportunity_id__c
                    FROM OpportunityLineItems
                )
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = baseOpp;
        data.oppClient = [
            SELECT Id, DMT_History_Deal__c, DMT_Guarantor_Name_Fiscal_ID__c
            FROM DMT_Opportunity_Client__c
            WHERE Id = :oppClient.Id
            LIMIT 1
        ];
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'profitability',
                'profitability' => new Map<String, Object>{
                    'results' => new List<Object>{
                        new Map<String, Object>{
                            'productId' => oli.gf_group_priority_opportunity_id__c,
                            'regulatoryEad' => 310.4,
                            'rorc' => 0.12,
                            'raroec' => 0.09,
                            'averageLife' => 5
                        }
                    }
                }
            }
        };

        String html = renderer.renderHtml(data);
        Assert.areNotEqual(null, html, 'HTML must not be null.');
        Assert.isTrue(!html.contains('Opportunity data not provided'), 'HTML should contain rendered Deal section, not guard message.');
        Assert.isTrue(!html.contains('Error:'), 'HTML should render the Deal section without exceptions.');
        Assert.isTrue(html.contains('Bridge Loan'), 'HTML should include the transaction type value.');
        Assert.isTrue(html.contains('EUR'), 'HTML should include the currency value.');
        Assert.isTrue(html.contains('Bookrunner'), 'HTML should include the BBVA role value.');
        Assert.isTrue(html.contains('Sub-limit A'), 'HTML should include the sub-limit value.');
    }

    @IsTest
    static void testOppDealRendererGtbOmitsIbfOnlyLabels() {
        DMT_NBC_OppDealRenderer_GTB renderer = new DMT_NBC_OppDealRenderer_GTB();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);

        baseOpp = [
            SELECT Id, Name, RecordTypeId, DMT_Product_Area__c, DMT_Threshold_Type__c, Account.Name, Account.DES_ID_Fiscal__c,
                (
                    SELECT Id, Product2Id, Product2.Name, CurrencyIsoCode, DMT_TXT_ProductNameOLI__c,
                        DMT_Deal_amount__c, g_currency_id__c, entity_role_type__c, underwriting_agreement_type__c,
                        bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c, DMT_Sub_Limit__c,
                        DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DES_Tenor_years__c,
                        gf_group_priority_opportunity_id__c
                    FROM OpportunityLineItems
                )
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];
        baseOpp.DMT_Product_Area__c = 'GTB';

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = baseOpp;
        data.oppClient = new DMT_Opportunity_Client__c();

        String html = renderer.renderHtml(data);

        Assert.areNotEqual(null, html, 'GTB HTML must not be null.');
        Assert.isTrue(html.contains('THE DEAL</div>'), 'GTB path should render the GTB header (no "(1/2)" suffix).');
        Assert.isTrue(!html.contains('Underwriting'), 'GTB path should not render the IBF-only Underwriting label.');
        Assert.isTrue(!html.contains('Average Life'), 'GTB path should not render the IBF-only Average Life label.');
    }

    @IsTest
    static void testGtbDataNotProvidedReturnsGuard() {
        DMT_NBC_OppDealRenderer_GTB renderer = new DMT_NBC_OppDealRenderer_GTB();

        String nullResult = renderer.renderHtml(null);
        Assert.isTrue(nullResult.contains('Opportunity data not provided'), 'Null data must return guard message.');

        DMT_ViewController.LineDataWrapper emptyData = new DMT_ViewController.LineDataWrapper();
        emptyData.opportunity = new Opportunity();

        String emptyResult = renderer.renderHtml(emptyData);
        Assert.isTrue(emptyResult.contains('Opportunity data not provided'), 'Empty populated-fields data must return guard message.');
    }

    @IsTest
    static void testGtbForcedExceptionReturnsError() {
        DMT_NBC_OppDealRenderer_GTB renderer = new DMT_NBC_OppDealRenderer_GTB();

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

        DMT_ViewRenderer delegator = new DMT_NBC_DealRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(!html.contains('Underwriting'), 'Delegator should route GTB opportunities to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorRoutesIbfWithExtensionRcfTlToGtbLayout() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Extension RCF Opp', DMT_Product_Area__c = 'IB&F', DMT_Capital_Action__c = 'Extension RCF & TL');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_DealRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(!html.contains('Underwriting'), 'IB&F with Extension RCF & TL should route to the GTB renderer.');
    }

    @IsTest
    static void testDelegatorKeepsIbfLocalTransactionOverviewVisible() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'IBF Local Opp', DMT_Product_Area__c = 'IB&F', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_DealRenderer();
        String html = delegator.renderHtml(data);

        Assert.isTrue(html.contains('THE DEAL'), 'IB&F + Local should still render the header.');
        Assert.isTrue(html.contains('HISTORY OF THE DEAL'), 'IB&F + Local should still render History of the Deal.');
        Assert.isTrue(html.contains('CORPORATE STRUCTURE'), 'IB&F + Local should still render Corporate Structure.');
        Assert.isTrue(html.contains('TRANSACTION OVERVIEW'), 'Local-hiding only applies to GTB + Local per the ticket; IB&F must still render Transaction Overview regardless of Threshold Type.');
    }

    @IsTest
    static void testDelegatorHidesEntireGtbLocalDealComponent() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = String.valueOf(
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        data.opportunity = new Opportunity(Name = 'GTB Local Opp', DMT_Product_Area__c = 'GTB', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        DMT_ViewRenderer delegator = new DMT_NBC_DealRenderer();
        String html = delegator.renderHtml(data);

        Assert.areEqual('', html, 'GTB + Local should hide the entire Deal component, including Corporate Structure.');
    }

    // CIBGLOBALD-4117 - direct coverage for DMT_NBC_OppDealRenderer_IBF's own tracking methods,
    // independent of which sub-renderer the delegator happens to route test fixtures to elsewhere in
    // this file (DMT_Test_DataFactory.generateOpportunity() defaults to GTB).
    @IsTest
    static void testIBFRendererOwnTrackingMethods() {
        DMT_NBC_OppDealRenderer_IBF renderer = new DMT_NBC_OppDealRenderer_IBF();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(renderer.getTrackedFields(opp)),
            'IB&F renderer must declare its own switch fields'
        );
        Assert.areEqual(opp.Id, renderer.getCalloutCacheKey(opp), 'IB&F renderer cache key must be the Opportunity Id');
        Assert.isTrue(renderer.fetchLiveTrackedValues(opp).isEmpty(), 'No OpportunityLineItems must yield no tracked values');
    }
}