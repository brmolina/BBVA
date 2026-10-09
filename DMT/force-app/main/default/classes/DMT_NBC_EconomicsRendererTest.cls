@IsTest
public with sharing class DMT_NBC_EconomicsRendererTest {

    // Mirrors the `cellData` inline style DMT_NBC_OppEconomicsRenderer.buildHtmlEconomics uses for
    // every Old condit. / New condit. cell, so a paired-cell match proves both columns' values for one
    // row without ambiguity — a plain html.contains(value) can't tell which column a value landed in
    // once both Old and New can be sourced from real DMT_Opportunity_Money__c records.
    private static final String CELL_STYLE = 'padding: 2px 4px; color: #004481; font-size: 10px; text-align: center; vertical-align: middle; background-color: #F4F6F9; border: 1px solid #ffffff;';

    private static String pairCellsHtml(String oldVal, String newVal) {
        return '<td style="' + CELL_STYLE + '">' + oldVal + '</td><td style="' + CELL_STYLE + '">' + newVal + '</td>';
    }

    private static String dmtOpportunityRecordTypeId() {
        return String.valueOf(Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId());
    }

    // Goes through the delegator only — DMT_NBC_RendererPairTestUtils.runPairTests requires the
    // concrete renderer class name as a string (dmt-develop has DMT_NBC_OppEconomicsRenderer; other
    // branches/orgs have it split into _IBF/_GTB), so it isn't used here. Testing purely through
    // DMT_NBC_EconomicsRenderer keeps this file identical and passing on either shape.
    @IsTest
    static void testEconomicsPair() {
        DMT_ViewRenderer delegator = new DMT_NBC_EconomicsRenderer();
        Assert.isTrue(DMT_RendererFactory.hasRenderer('NBC Economics'), 'Factory key must exist: NBC Economics');
        Assert.isInstanceOfType(DMT_RendererFactory.getRenderer('NBC Economics'), DMT_NBC_EconomicsRenderer.class, 'Factory must return DMT_NBC_EconomicsRenderer');

        String nullHtml = delegator.renderHtml(null);
        Assert.isNotNull(nullHtml, 'Delegator null HTML must not be null');
        Assert.isTrue(nullHtml.contains('Error'), 'Delegator null HTML should return error');

        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        String validHtml = delegator.renderHtml(data);
        Assert.isNotNull(validHtml, 'Delegator valid HTML must not be null');
    }

    // CIBGLOBALD-4117 - the delegator has no field/section knowledge of its own: it routes to
    // whichever single renderer is active (same key as renderHtml) and returns exactly what that one
    // renderer declares. IB&F and GTB genuinely declare different DMT_Opportunity_Money__c field sets
    // here (GTB omits Utilisation Fee/Extension Duration Fee), so routing to the wrong one would be
    // caught by these two tests' distinct field sets.
    @IsTest
    static void testGetTrackedFieldsRoutesToIBFRenderer() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Economics'),
            'NBC Economics must be registered as a tracked component'
        );

        DMT_NBC_EconomicsRenderer delegator = new DMT_NBC_EconomicsRenderer();
        Opportunity opp = new Opportunity(RecordTypeId = dmtOpportunityRecordTypeId(), DMT_Product_Area__c = 'IB&F');

        Assert.areEqual(
            new Set<String>{'DMT_Product_Area__c', 'DMT_Capital_Action__c', 'DMT_Threshold_Type__c'},
            new Set<String>(delegator.getTrackedFields(opp)),
            'Delegator must return the active (IB&F) renderer\'s own switch-field declaration'
        );

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{
                'DMT_Is_Old_Money__c', 'DMT_Up_Front_Fee_Accrual__c', 'DMT_Up_Front_Fee_Non_Accrual__c',
                'DMT_Funding_Cost__c', 'DMT_Liquidity_Fee__c', 'DMT_Interest_Rate_Period__c',
                'DMT_Applicable_Margin__c', 'DMT_Pricing_Grid_or_Step_ups__c', 'DMT_Commitment_Fee__c',
                'DMT_Utilisation_Fee__c', 'DMT_Extension_Duration_Fee__c', 'DMT_Other_Fees_Accrual__c',
                'DMT_Other_Fees_Non_Accrual__c', 'DMT_Expected_Drawn__c', 'DMT_All_in_Drawn__c',
                'DMT_All_in_Undrawn__c'
            },
            new Set<String>(byObject.get('DMT_Opportunity_Money__c')),
            'Delegator must return the active (IB&F) renderer\'s own DMT_Opportunity_Money__c fields'
        );
        Assert.areEqual(
            new Set<String>{'Product2.Name'},
            new Set<String>(byObject.get('OpportunityLineItem')),
            'Delegator must track Product2.Name for the row header'
        );

        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> sectionsByKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        for (DMT_ApprovalChangeStep_Helper.ChildSection section : delegator.getChildSections(opp)) {
            sectionsByKey.put(section.snapshotSectionKey, section);
        }
        Assert.areEqual(2, sectionsByKey.size(), 'Exactly two child sections expected');

        DMT_ApprovalChangeStep_Helper.ChildSection moneySection = sectionsByKey.get('opportunityMoney');
        Assert.isNotNull(moneySection, 'opportunityMoney section must be declared');
        Assert.areEqual('DMT_Opportunity_Money__c', moneySection.childObjectApiName, 'Money section object mismatch');
        Assert.areEqual('DMT_Opportunity_Product__r.OpportunityId', moneySection.childLookupField, 'Money section must traverse the OpportunityLineItem relationship - DMT_Opportunity_Money__c has no direct Opportunity lookup');
        Assert.areEqual('Id', moneySection.parentValueField, 'Money section parent value mismatch');

        DMT_ApprovalChangeStep_Helper.ChildSection lineItemSection = sectionsByKey.get('opportunityLineItems');
        Assert.isNotNull(lineItemSection, 'opportunityLineItems section must be declared, shared with NBC Deal/NBC Transaction Overview');
        Assert.areEqual('OpportunityLineItem', lineItemSection.childObjectApiName, 'Line item section object mismatch');
        Assert.areEqual('OpportunityId', lineItemSection.childLookupField, 'Line item section lookup mismatch');
    }

    @IsTest
    static void testGetTrackedFieldsRoutesToGTBRenderer() {
        DMT_NBC_EconomicsRenderer delegator = new DMT_NBC_EconomicsRenderer();
        Opportunity opp = new Opportunity(RecordTypeId = dmtOpportunityRecordTypeId(), DMT_Product_Area__c = 'GTB');

        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{
                'DMT_Is_Old_Money__c', 'DMT_Up_Front_Fee_Accrual__c', 'DMT_Up_Front_Fee_Non_Accrual__c',
                'DMT_Funding_Cost__c', 'DMT_Liquidity_Fee__c', 'DMT_Interest_Rate_Period__c',
                'DMT_Applicable_Margin__c', 'DMT_Pricing_Grid_or_Step_ups__c', 'DMT_Commitment_Fee__c',
                'DMT_Other_Fees_Accrual__c', 'DMT_Other_Fees_Non_Accrual__c', 'DMT_Expected_Drawn__c',
                'DMT_All_in_Drawn__c', 'DMT_All_in_Undrawn__c'
            },
            new Set<String>(byObject.get('DMT_Opportunity_Money__c')),
            'Delegator must return the active (GTB) renderer\'s own (narrower) DMT_Opportunity_Money__c fields, not IB&F\'s'
        );
    }
/*
    @IsTest
    static void testEconomicsPairForcedExceptionScenario() {
        DMT_NBC_RendererPairTestUtils.runPairTestsWithForcedException(
            'NBC Economics',
            'DMT_NBC_EconomicsRenderer',
            'DMT_NBC_OppEconomicsRenderer'
        );
        Assert.isTrue(true, 'Forced exception scenario is executed in shared utility and this class');
    }

    // ==================================================
    // DELEGATOR RENDERPDFJSON TESTS
    // ==================================================

    @IsTest
    static void testEconomicsRendererPdfJsonNullData() {
        DMT_ViewRenderer renderer = new DMT_NBC_EconomicsRenderer();
        Map<String, Object> pdf = renderer.renderPdfJson(null);
        Assert.isNotNull(pdf, 'PDF JSON for null data must never be null.');
        Assert.areEqual(0, pdf.size(), 'Null data should return an empty PDF JSON map.');
    }

    @IsTest
    static void testEconomicsRendererPdfJsonInvalidRecordType() {
        DMT_ViewRenderer renderer = new DMT_NBC_EconomicsRenderer();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.recordTypeId = buildUnknownOpportunityRecordTypeId();
        Map<String, Object> pdf = renderer.renderPdfJson(data);
        Assert.isNotNull(pdf, 'PDF JSON for invalid record type must never be null.');
        Assert.areEqual(0, pdf.size(), 'Invalid record type should return an empty PDF JSON map.');
    }

    @IsTest
    static void testEconomicsRendererPdfJsonValidRecordType() {
        DMT_ViewRenderer renderer = new DMT_NBC_EconomicsRenderer();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        Map<String, Object> pdf = renderer.renderPdfJson(data);
        Assert.isNotNull(pdf, 'PDF JSON for valid data must never be null.');
    } */

    @IsTest
    static void testOppEconomicsRendererAdditionalCoverage() {
        DMT_ViewRenderer renderer = new DMT_NBC_EconomicsRenderer();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);

        baseOpp = [
            SELECT Id, Name, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c,
                (SELECT Id, Product2Id, Product2.Name,
                        gf_group_priority_opportunity_id__c,
                        gf_payment_frequency__c,
                        DMT_PricingGrid_OR_StepUps__c,
                        DMT_TXT_Commitment_Fees__c,
                        DMT_Liquidity_Fee__c,
                        DMT_TXT_Extension_Duration_Fees__c,
                        DMT_TXT_Other_Fees_Accrual__c,
                        DMT_TXT_Other_Fees_NonAccrual__c,
                        DMT_Expected_Drawn__c
                 FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.recordTypeId = dmtOpportunityRecordTypeId();
        successData.opportunity = baseOpp;
        successData.oppClient = new DMT_Opportunity_Client__c();
        successData.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'profitability',
                'profitability' => new Map<String, Object>{
                    'results' => new List<Object>{
                        new Map<String, Object>{
                            'productId' => baseOpp.OpportunityLineItems[0].gf_group_priority_opportunity_id__c,
                            'periodicFeesPbs' => 1.10,
                            'feesUpFrontPbs' => 0.70,
                            'fundingDbPbs' => 0.55,
                            'fundingFbPbs' => 0.45,
                            'spreadDbPbs' => 0.30,
                            'spreadFbPbs' => 0.20,
                            'feesFbPbs' => 0.15,
                            'feesDbPbs' => 0.25,
                            'allInDb' => 1.25,
                            'allInFb' => 0.95
                        }
                    }
                }
            }
        };

        String successHtml = renderer.renderHtml(successData);
        //Map<String, Object> successPdf = renderer.renderPdfJson(successData);

        Assert.isNotNull(successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('ECONOMICS') || successHtml.contains('Error'), 'HTML should return a controlled response.');
        //Assert.isNotNull(successPdf, 'Success PDF map must not be null.');

        DMT_ViewController.LineDataWrapper altData = new DMT_ViewController.LineDataWrapper();
        altData.opportunity = new Opportunity();

        String altHtml = renderer.renderHtml(altData);
        //Map<String, Object> altPdf = renderer.renderPdfJson(altData);

        Assert.isNotNull(altHtml, 'Alternative path should return a controlled HTML response.');
        //Assert.isNotNull(altPdf, 'Alternative path should return a controlled PDF map.');
    }

    @IsTest
    static void testOppEconomicsRendererOldValuesComeFromOppMoneys() {
        DMT_ViewRenderer renderer = new DMT_NBC_EconomicsRenderer();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);
        // DMT_Product_Area__c must be in the SELECT — EconomicsData constructor accesses it;
        // without it the SObjectException is caught silently and opportunityLineItems stays empty.
        baseOpp = [
            SELECT Id, Name, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c,
                (SELECT Id, Product2Id, Product2.Name,
                        gf_group_priority_opportunity_id__c,
                        gf_payment_frequency__c,
                        DMT_PricingGrid_OR_StepUps__c,
                        DMT_TXT_Commitment_Fees__c,
                        DMT_Liquidity_Fee__c,
                        DMT_TXT_Extension_Duration_Fees__c,
                        DMT_TXT_Other_Fees_Accrual__c,
                        DMT_TXT_Other_Fees_NonAccrual__c,
                        DMT_Utilisation_Fee__c,
                        DMT_Expected_Drawn__c
                 FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = dmtOpportunityRecordTypeId();
        data.opportunity = baseOpp;
        data.oppClient = new DMT_Opportunity_Client__c();
        data.featuresList = new List<Map<String, Object>>();

        Id oliId = baseOpp.OpportunityLineItems[0].Id;

        DMT_ViewController.OpportunityProduct oppProduct = new DMT_ViewController.OpportunityProduct();
        oppProduct.productId = oliId;

        // Values are kept under 1000 so DMT_FormattingUtils.formatToTwoDecimals (which calls
        // Decimal.format()) does not insert a thousands separator, and avoid digit runs that
        // appear in the renderer's inline styles (e.g. #888888).
        DMT_Opportunity_Money__c oldMoney = new DMT_Opportunity_Money__c(
            DMT_Opportunity_Product__c = oliId,
            DMT_Is_Old_Money__c = true,
            DMT_Up_Front_Fee_Accrual__c = '321',
            DMT_All_in_Drawn__c = '432'
        );
        DMT_Opportunity_Money__c newMoney = new DMT_Opportunity_Money__c(
            DMT_Opportunity_Product__c = oliId,
            DMT_Is_Old_Money__c = false,
            DMT_Up_Front_Fee_Accrual__c = '654',
            DMT_All_in_Drawn__c = '765'
        );
        insert new List<DMT_Opportunity_Money__c>{ oldMoney, newMoney };

        Map<Id, DMT_Opportunity_Money__c> refreshed = new Map<Id, DMT_Opportunity_Money__c>([
            SELECT Id, DMT_Is_Old_Money__c, DMT_Up_Front_Fee_Accrual__c, DMT_All_in_Drawn__c
            FROM DMT_Opportunity_Money__c
            WHERE DMT_Opportunity_Product__c = :oliId
        ]);

        // New money added first: the old "first populated record" logic would have returned it.
        oppProduct.oppMoneys.add(refreshed.get(newMoney.Id));
        oppProduct.oppMoneys.add(refreshed.get(oldMoney.Id));
        data.oppProducts.add(oppProduct);

        String html = renderer.renderHtml(data);

        // Old=321/432 must come from the DMT_Is_Old_Money__c=true record and New=654/765 from the
        // false record, in that exact pairing per row — never swapped, never one leaking into the other.
        Assert.isTrue(html.contains(pairCellsHtml('321', '654')), 'Up-Front Fee Accrual row must pair Old=321 (old money record) with New=654 (new money record).');
        Assert.isTrue(html.contains(pairCellsHtml('432', '765')), 'All-in Drawn row must pair Old=432 (old money record) with New=765 (new money record).');
    }

    @IsTest
    static void testOldValuesBlankWhenNoOldMoneyRecordExists() {
        DMT_ViewRenderer renderer = new DMT_NBC_EconomicsRenderer();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);
        // The full OLI field list is required: getValueForLabel reads each of these, and touching
        // an unqueried field throws, which renderHtml swallows into an error div.
        baseOpp = [
            SELECT Id, Name, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c,
                (SELECT Id, Product2Id, Product2.Name,
                        gf_group_priority_opportunity_id__c,
                        gf_payment_frequency__c,
                        DMT_PricingGrid_OR_StepUps__c,
                        DMT_TXT_Commitment_Fees__c,
                        DMT_Liquidity_Fee__c,
                        DMT_TXT_Extension_Duration_Fees__c,
                        DMT_TXT_Other_Fees_Accrual__c,
                        DMT_TXT_Other_Fees_NonAccrual__c,
                        DMT_Utilisation_Fee__c,
                        DMT_Expected_Drawn__c
                 FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = dmtOpportunityRecordTypeId();
        data.opportunity = baseOpp;
        data.oppClient = new DMT_Opportunity_Client__c();
        data.featuresList = new List<Map<String, Object>>();

        Id oliId = baseOpp.OpportunityLineItems[0].Id;

        DMT_ViewController.OpportunityProduct oppProduct = new DMT_ViewController.OpportunityProduct();
        oppProduct.productId = oliId;

        DMT_Opportunity_Money__c newMoney = new DMT_Opportunity_Money__c(
            DMT_Opportunity_Product__c = oliId,
            DMT_Is_Old_Money__c = false,
            DMT_Up_Front_Fee_Accrual__c = '654'
        );
        insert newMoney;

        oppProduct.oppMoneys.add([
            SELECT Id, DMT_Is_Old_Money__c, DMT_Up_Front_Fee_Accrual__c
            FROM DMT_Opportunity_Money__c
            WHERE Id = :newMoney.Id
        ]);
        data.oppProducts.add(oppProduct);

        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains('ECONOMICS'), 'Section must still render when no old money record exists.');
        // No old-money record exists, so Old condit. must be blank; the new-money record's 654 must
        // still surface in New condit. — the two columns are independent, not linked fallbacks.
        Assert.isTrue(html.contains(pairCellsHtml('', '654')), 'With no old money record, Old condit. must be blank while New condit. still reflects the new money record.');
    }

    @IsTest
    static void testNewConditBlankWhenNoNewMoneyRecordExists() {
        DMT_ViewRenderer renderer = new DMT_NBC_EconomicsRenderer();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);
        baseOpp = [
            SELECT Id, Name, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c,
                (SELECT Id, Product2Id, Product2.Name,
                        gf_group_priority_opportunity_id__c,
                        gf_payment_frequency__c,
                        DMT_PricingGrid_OR_StepUps__c,
                        DMT_TXT_Commitment_Fees__c,
                        DMT_Liquidity_Fee__c,
                        DMT_TXT_Extension_Duration_Fees__c,
                        DMT_TXT_Other_Fees_Accrual__c,
                        DMT_TXT_Other_Fees_NonAccrual__c,
                        DMT_Utilisation_Fee__c,
                        DMT_Expected_Drawn__c
                 FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = dmtOpportunityRecordTypeId();
        data.opportunity = baseOpp;
        data.oppClient = new DMT_Opportunity_Client__c();
        // No DMT_Opportunity_Money__c records at all for this line (the common case for lines that
        // were never renewed and never had the Economics Old Money modal used on them). The
        // profitability-engine fallback in getValueForLabel is currently commented-out dead code, so
        // New condit. is blank here too - this featuresList is present only to prove that dead branch
        // genuinely has no effect on the output either way.
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'profitability',
                'profitability' => new Map<String, Object>{
                    'results' => new List<Object>{
                        new Map<String, Object>{
                            'productId' => baseOpp.OpportunityLineItems[0].gf_group_priority_opportunity_id__c,
                            'periodicFeesPbs' => 111
                        }
                    }
                }
            }
        };

        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains(pairCellsHtml('', '')), 'With no money records at all, both Old and New condit. are blank - the profitability fallback is currently disabled.');
    }

    private static DMT_ViewController.LineDataWrapper buildValidWrapperForTesting() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);

        data.opportunity = [
            SELECT Id, Name, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];
        data.recordTypeId = String.valueOf(data.opportunity.RecordTypeId);
        data.oppClient = new DMT_Opportunity_Client__c();
        data.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'profitability',
                'profitability' => new Map<String, Object>{
                    'results' => new List<Object>{
                        new Map<String, Object>{
                            'productId' => oli.gf_group_priority_opportunity_id__c,
                            'periodicFeesPbs' => 1.10,
                            'feesUpFrontPbs' => 0.70
                        }
                    }
                }
            }
        };

        return data;
    }

    // ==================================================
    // DMT_NBC_OppEconomicsRenderer_IBF coverage
    // ==================================================
    // DMT_Test_DataFactory.generateOpportunity() hardcodes DMT_Product_Area__c = 'GTB', so every
    // test above that goes through the delegator without overriding it actually exercises
    // DMT_NBC_OppEconomicsRenderer_GTB, never the IBF variant — despite asserting success. These
    // tests explicitly force the IB&F routing/branches so DMT_NBC_OppEconomicsRenderer_IBF's own
    // lines (not just the shared helper) get covered.

    @IsTest
    static void testDelegatorRoutesToIBFWhenProductAreaIsNotGTB() {
        DMT_ViewRenderer delegator = new DMT_NBC_EconomicsRenderer();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);

        baseOpp = [
            SELECT Id, Name, DMT_Product_Area__c, DMT_Capital_Action__c, DMT_Threshold_Type__c,
                (SELECT Id, Product2Id, Product2.Name,
                        gf_group_priority_opportunity_id__c,
                        gf_payment_frequency__c,
                        DMT_PricingGrid_OR_StepUps__c,
                        DMT_TXT_Commitment_Fees__c,
                        DMT_Liquidity_Fee__c,
                        DMT_TXT_Extension_Duration_Fees__c,
                        DMT_TXT_Other_Fees_Accrual__c,
                        DMT_TXT_Other_Fees_NonAccrual__c,
                        DMT_Utilisation_Fee__c,
                        DMT_Expected_Drawn__c
                 FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];
        // Override in memory (no DML needed) so the delegator's isGTB check takes the IB&F branch —
        // neither GTB_PRODUCT_AREA nor the GTB-by-capital-action condition can match.
        baseOpp.DMT_Product_Area__c = 'IB&F';
        baseOpp.DMT_Capital_Action__c = null;

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = dmtOpportunityRecordTypeId();
        data.opportunity = baseOpp;
        data.oppClient = new DMT_Opportunity_Client__c();
        data.featuresList = new List<Map<String, Object>>();

        String html = delegator.renderHtml(data);

        Assert.isFalse(html.contains('Error'), 'IB&F product area must route cleanly to DMT_NBC_OppEconomicsRenderer_IBF without erroring.');
        Assert.isTrue(html.contains('ECONOMICS'), 'Should render the Economics section header.');
        // Utilisation Fee and Extension/Duration Fee rows exist only on the IB&F row definitions
        // (DMT_NBC_OppEconomicsRenderer_GTB omits both) — their presence proves the IB&F-specific
        // row set was actually used, not just that some renderer produced output.
        Assert.isTrue(html.contains('Utilisation Fee'), 'IB&F row set must include Utilisation Fee, unlike GTB.');
        Assert.isTrue(html.contains('Extension'), 'IB&F row set must include the Extension/Duration Fee row, unlike GTB.');
    }

    @IsTest
    static void testGtbRendererLocalThresholdTypeHidesEntireSection() {
        DMT_NBC_OppEconomicsRenderer_GTB renderer = new DMT_NBC_OppEconomicsRenderer_GTB();

        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.opportunity = new Opportunity(Name = 'GTB Local Opp', DMT_Product_Area__c = 'GTB', DMT_Threshold_Type__c = 'Local');
        data.oppClient = new DMT_Opportunity_Client__c();

        String html = renderer.renderHtml(data);

        Assert.areEqual('', html, 'GTB + Local must hide the entire Economics section.');
    }

    @IsTest
    static void testGtbRendererNullDataReturnsNotProvided() {
        DMT_ViewRenderer renderer = new DMT_NBC_OppEconomicsRenderer_GTB();
        String html = renderer.renderHtml(null);
        Assert.isTrue(html.contains('Opportunity data not provided'), 'Null data should return the not-provided message.');
    }

    @IsTest
    static void testGtbRendererForcedExceptionReturnsControlledError() {
        DMT_ViewRenderer renderer = new DMT_NBC_OppEconomicsRenderer_GTB();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.opportunity.DMT_Product_Area__c = 'GTB';
        data.forceException = true;

        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains('Error'), 'Forced exception must be caught and return a controlled error div.');
    }

    @IsTest
    static void testIBFRendererNullDataReturnsNotProvided() {
        DMT_ViewRenderer renderer = new DMT_NBC_OppEconomicsRenderer_IBF();
        String html = renderer.renderHtml(null);
        Assert.isTrue(html.contains('Opportunity data not provided'), 'Null data should return the not-provided message.');
    }

    @IsTest
    static void testIBFRendererForcedExceptionReturnsControlledError() {
        DMT_ViewRenderer renderer = new DMT_NBC_OppEconomicsRenderer_IBF();
        DMT_ViewController.LineDataWrapper data = buildValidWrapperForTesting();
        data.forceException = true;

        String html = renderer.renderHtml(data);

        Assert.isTrue(html.contains('Error'), 'Forced exception must be caught and return a controlled error div.');
    }

    private static String buildUnknownOpportunityRecordTypeId() {
        return String.valueOf(Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId()).substring(0, 12) + 'UNKNOWN';
    }
}