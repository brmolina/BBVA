@isTest
public with sharing class DMT_BasicFinancialsController_Test {
    @TestSetup
    static void makeData(){

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);

    }
    
    @isTest
    static void testGetAccountFields() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Opportunity> opps = DMT_BasicFinancialsController.getAccountFields(opp.Id);
        Test.stopTest();

        System.assertEquals(opps.get(0).Account.Revenues_Last_Year_number__c, 13, 'It is equals to the amount from the mock');

    }

    @isTest
    static void testGetFinancials() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<DMT_Opportunity_Client__c> opps = DMT_BasicFinancialsController.getFinancials(opp.Id);
        Test.stopTest();

        System.assertEquals(opps.get(0).Revenues_Last_Year_number__c, 14, 'It is equals to the amount from the mock');
    }

    /**
     * Multiholder opportunity: getFinancials must return only the Main Borrower (the Opportunity
     * Client whose Alpha Code matches Custom_Association_Opportunity__c.g_customer_id__c).
     */
    @isTest
    static void testGetFinancials_multiholder_returnsMainBorrower() {
        Opportunity opp = buildDraftOpportunity('Multiholder Main Borrower');

        TriggerBypass.setBypass();
        DMT_Opportunity_Client__c mainBorrower = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id, Alpha_Code_Client__c = 'ESMAIN0000001',
            Counterpart__c = 'Corporates', DMT_Sector__c = 'N', Revenues_Last_Year_number__c = 99);
        DMT_Opportunity_Client__c otherHolder = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id, Alpha_Code_Client__c = 'ESOTHER000001',
            Counterpart__c = 'Corporates', DMT_Sector__c = 'N', Revenues_Last_Year_number__c = 1);
        insert new List<DMT_Opportunity_Client__c>{ mainBorrower, otherHolder };
        insert new Custom_Association_Opportunity__c(
            Opportunity__c = opp.Id, g_customer_id__c = 'ESMAIN0000001',
            gf_customer_group_id__c = 'GRPM-' + opp.Id);
        TriggerBypass.removeBypass();

        Test.startTest();
        List<DMT_Opportunity_Client__c> result = DMT_BasicFinancialsController.getFinancials(opp.Id);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Only the Main Borrower record should be returned');
        Assert.areEqual(mainBorrower.Id, result[0].Id, 'The returned record must be the Main Borrower');
        Assert.areEqual(99, result[0].Revenues_Last_Year_number__c, 'Main Borrower financials should be returned');
    }

    /**
     * Multiholder opportunity without a Custom Association mapped: keep the original behaviour
     * (return all clients) so single-holder / legacy data is unaffected.
     */
    @isTest
    static void testGetFinancials_multiholder_fallbackWhenNoAssociation() {
        Opportunity opp = buildDraftOpportunity('Multiholder No Association');

        TriggerBypass.setBypass();
        insert new List<DMT_Opportunity_Client__c>{
            new DMT_Opportunity_Client__c(DMT_MDE_Opportunity__c = opp.Id,
                Alpha_Code_Client__c = 'ESNOA00000001', Counterpart__c = 'Corporates', DMT_Sector__c = 'N'),
            new DMT_Opportunity_Client__c(DMT_MDE_Opportunity__c = opp.Id,
                Alpha_Code_Client__c = 'ESNOA00000002', Counterpart__c = 'Corporates', DMT_Sector__c = 'N')
        };
        TriggerBypass.removeBypass();

        Test.startTest();
        List<DMT_Opportunity_Client__c> result = DMT_BasicFinancialsController.getFinancials(opp.Id);
        Test.stopTest();

        Assert.areEqual(2, result.size(),
            'Without a Custom Association the original behaviour (all clients) is kept');
    }

    private static Opportunity buildDraftOpportunity(String name) {
        TriggerBypass.setBypass();
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = name, StageName = 'Draft', CloseDate = Date.today().addDays(30), RecordTypeId = oppRtId);
        insert opp;
        TriggerBypass.removeBypass();
        return opp;
    }
}