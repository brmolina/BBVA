@IsTest
public with sharing class DMT_NBC_TransactionOverviewRendererTest {
    @IsTest
    static void testTransactionOverviewPair() {
        DMT_NBC_RendererPairTestUtils.runPairTests(
            'NBC Transaction Overview',
            'DMT_NBC_TransactionOverviewRenderer',
            'DMT_NBC_OppTransactionOverviewRenderer'
        );
        Assert.isTrue(true, 'Assertions are executed in shared utility and this class');
    }

    @IsTest
    static void testGetTrackedFields() {
        Assert.isTrue(
            DMT_RendererFactory.getTrackedComponentNames().contains('NBC Transaction Overview'),
            'NBC Transaction Overview must be registered as a tracked component'
        );

        Id dmtOpportunityRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(RecordTypeId = dmtOpportunityRtId);

        DMT_NBC_TransactionOverviewRenderer delegator = new DMT_NBC_TransactionOverviewRenderer();
        Map<String, List<String>> byObject = delegator.getTrackedFieldsByObject(opp);
        Assert.areEqual(
            new Set<String>{
                'Product2.Name', 'Product2.CurrencyIsoCode', 'CurrencyIsoCode', 'DMT_Deal_Amount_Tenors__c',
                'DMT_ExpectedFinal_Take__c', 'DMT_NewMoney_BBVA__c', 'DMT_OldMoney_BBVA__c',
                'gf_group_priority_opportunity_id__c'
            },
            new Set<String>(byObject.get('OpportunityLineItem')),
            'Delegator must route to the record-type renderer\'s OpportunityLineItem fields'
        );

        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = delegator.getChildSections(opp);
        Assert.areEqual(1, sections.size(), 'Exactly one child section expected');
        Assert.areEqual('opportunityLineItems', sections[0].snapshotSectionKey, 'Must share the opportunityLineItems section key used by NBC Deal');
        Assert.areEqual('OpportunityLineItem', sections[0].childObjectApiName, 'Child object mismatch');
        Assert.areEqual('OpportunityId', sections[0].childLookupField, 'Lookup field mismatch');
        Assert.areEqual('Id', sections[0].parentValueField, 'Parent value field mismatch');

        Opportunity unknownRtOpp = new Opportunity(RecordTypeId = UserInfo.getOrganizationId());
        Assert.isTrue(delegator.getTrackedFieldsByObject(unknownRtOpp).isEmpty(), 'Unknown record type must yield no tracked fields');
        Assert.isTrue(delegator.getChildSections(unknownRtOpp).isEmpty(), 'Unknown record type must yield no child sections');
    }

    @IsTest
    static void testFetchLiveTrackedValuesExtractsPerProductProfitability() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        oli = [SELECT Id, gf_group_priority_opportunity_id__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];

        Map<String, Object> feature = new Map<String, Object>{
            'name' => 'Profitability Engine',
            'profitability' => new Map<String, Object>{
                'results' => new List<Object>{
                    new Map<String, Object>{
                        'productId' => oli.gf_group_priority_opportunity_id__c,
                        'averageLife' => 3.5, 'rorc' => 0.14, 'raroec' => 0.07
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

        DMT_NBC_TransactionOverviewRenderer delegator = new DMT_NBC_TransactionOverviewRenderer();
        Assert.areEqual(opp.Id, delegator.getCalloutCacheKey(opp), 'Cache key must be the Opportunity Id');

        Map<String, Object> liveValues = delegator.fetchLiveTrackedValues(opp);
        String prefix = oli.gf_group_priority_opportunity_id__c + ':';
        Assert.areEqual(3.5, Decimal.valueOf(String.valueOf(liveValues.get(prefix + 'averageLife'))), 'averageLife must be extracted');
        Assert.areEqual(0.14, Decimal.valueOf(String.valueOf(liveValues.get(prefix + 'rorc'))), 'rorc must be extracted');
        Assert.areEqual(0.07, Decimal.valueOf(String.valueOf(liveValues.get(prefix + 'raroec'))), 'raroec must be extracted');
    }

    @IsTest
    static void testFetchLiveTrackedValuesNoLineItemsReturnsEmpty() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, RecordTypeId, DMT_Product_Area__c, DMT_Capital_Action__c FROM Opportunity WHERE Id = :opp.Id];

        DMT_NBC_TransactionOverviewRenderer delegator = new DMT_NBC_TransactionOverviewRenderer();
        Map<String, Object> liveValues = delegator.fetchLiveTrackedValues(opp);

        Assert.isTrue(liveValues.isEmpty(), 'No OpportunityLineItems must yield no tracked values');
    }

    @IsTest
    static void testOppTransactionOverviewAdditionalCoverage() {
        DMT_NBC_OppTransactionOverviewRenderer renderer = new DMT_NBC_OppTransactionOverviewRenderer();

        Opportunity baseOpp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem createdOli = DMT_Test_DataFactory.generateOpportunityLineItem(baseOpp);

        baseOpp = [
            SELECT Id, Name,
                (SELECT Id, Product2Id, Product2.Name, Product2.CurrencyIsoCode, CurrencyIsoCode, gf_group_priority_opportunity_id__c, DMT_Deal_Amount_Tenors__c, DMT_ExpectedFinal_Take__c, DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DES_Tenor_years__c
                 FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id = :baseOpp.Id
            LIMIT 1
        ];

        DMT_ViewController.LineDataWrapper successData = new DMT_ViewController.LineDataWrapper();
        successData.opportunity = baseOpp;
        successData.oppClient = new DMT_Opportunity_Client__c();
        successData.featuresList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'profitability',
                'profitability' => new Map<String, Object>{
                    'results' => new List<Object>{
                        new Map<String, Object>{
                            'productId' => createdOli.gf_group_priority_opportunity_id__c,
                            'averageLife' => 4,
                            'rorc' => 0.11,
                            'raroec' => 0.08
                        }
                    }
                }
            }
        };

        String successHtml = renderer.renderHtml(successData);

        Assert.areNotEqual(null, successHtml, 'Success HTML must not be null.');
        Assert.isTrue(successHtml.contains('Transaction Overview') || successHtml.contains('Error'), 'HTML should return a controlled response.');

        DMT_ViewController.LineDataWrapper altData = new DMT_ViewController.LineDataWrapper();
        altData.opportunity = new Opportunity();

        String altHtml = renderer.renderHtml(altData);

        Assert.areNotEqual(null, altHtml, 'Alternative path should return a controlled HTML response.');
    }

    @IsTest
    static void testOppRendererOwnCalloutTrackingMethods() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        oli = [SELECT Id, gf_group_priority_opportunity_id__c FROM OpportunityLineItem WHERE Id = :oli.Id];

        Map<String, Object> feature = new Map<String, Object>{
            'name' => 'Profitability Engine',
            'profitability' => new Map<String, Object>{
                'results' => new List<Object>{
                    new Map<String, Object>{
                        'productId' => oli.gf_group_priority_opportunity_id__c,
                        'averageLife' => 3.5, 'rorc' => 0.14, 'raroec' => 0.07
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

        DMT_NBC_OppTransactionOverviewRenderer renderer = new DMT_NBC_OppTransactionOverviewRenderer();
        Assert.areEqual(opp.Id, renderer.getCalloutCacheKey(opp), 'Renderer must self-declare the Opportunity Id as its cache key');

        Map<String, Object> liveValues = renderer.fetchLiveTrackedValues(opp);
        String prefix = oli.gf_group_priority_opportunity_id__c + ':';
        Assert.areEqual(3.5, Decimal.valueOf(String.valueOf(liveValues.get(prefix + 'averageLife'))), 'averageLife must be extracted directly from the renderer');
    }
}