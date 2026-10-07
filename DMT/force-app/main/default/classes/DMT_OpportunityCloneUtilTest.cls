@isTest
public with sharing class DMT_OpportunityCloneUtilTest {

    @TestSetup
    static void loadTestData() {
        TriggerBypass.setBypass();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        Product2 product2 = DMT_Test_DataFactory.generateProduct2();
        PricebookEntry pricebookEntry = DMT_Test_DataFactory.generatePricebookEntry(product2);
        OpportunityLineItem opportunityLineItem = DMT_Test_DataFactory.generateOpportunityLineItem(product2, pricebookEntry, opp);

        opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opp.Id];
        opportunityLineItem = [SELECT Id, UnitPrice, TotalPrice FROM OpportunityLineItem WHERE Id = :opportunityLineItem.Id];
        opportunityLineItem.UnitPrice = 200;
        update opportunityLineItem;

        DMT_Test_DataFactory.generateOpportunityTenor(opportunityLineItem);
        DMT_Test_DataFactory.generateOpportunityMitigant(opportunityLineItem);
        DMT_Test_DataFactory.generateUnderlyingRestriction(opportunityLineItem);
        DMT_Test_DataFactory.generatexSell(opp);
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        DMT_TeamMember__c participants = new DMT_TeamMember__c(Opportunity__c = opp.Id, User__c = UserInfo.getUserId(), AccessLevel__c = 'Read');
        insert participants;
    }

    @IsTest
    static void testCloneSuccess() {
        Opportunity originalOpp = [SELECT Id, Name, Entific__c,AccountId,RecordTypeId,gf_opportunity_product_desc__c, StageName, closedate FROM Opportunity LIMIT 1];
		List<OpportunityLineItem> olis = [SELECT Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice, TotalPrice, DMT_Line_Amount__c, DMT_Commitment_Line_Amount__c, DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DMT_ExpectedFinal_Take__c, DMT_Expected_Drawn__c, DMT_Liquidity_Fee__c, DES_Commitment_Fees__c, DMT_Extension_Duration_Fees__c, DES_Other_Fees__c, DMT_Reference_Upfront_Fees__c, DMT_Line_Currency__c, entity_role_type__c, DMT_Sub_Limit__c, bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c, DMT_Deal_amount__c, g_currency_id__c, DMT_TXT_Commitment_Fees__c, DMT_TXT_Extension_Duration_Fees__c, DMT_TXT_Other_Fees_Accrual__c, DMT_TXT_Other_Fees_NonAccrual__c 
                                            FROM OpportunityLineItem WHERE OpportunityId=:originalOpp.Id];
        List<DMT_Opportunity_Tenor__c> tenors = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Tenor__c ];
        List<DMT_Opportunity_Mitigant__c> mitigants = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Mitigant__c];
        List<DMT_Underlying__c> underlyings = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Underlying__c WHERE DMT_Opportunity_Product__r.OpportunityId =:originalOpp.Id];
        List<DMT_X_Sell__c> xSells = [SELECT Id, Opportunity__c FROM DMT_X_Sell__c];
        DMT_Opportunity_Client__c oppClient = [SELECT Id, DMT_MDE_Opportunity__c FROM DMT_Opportunity_Client__c LIMIT 1];
        Account localClient = [SELECT Id FROM Account WHERE Id = :originalOpp.AccountId];
        List<DMT_TeamMember__c> participants = [SELECT Id, Opportunity__c, AccessLevel__c, User__c FROM DMT_TeamMember__c];

        Integer originalUnderlyingsCount = underlyings.size();

        Test.startTest();
        DMT_OpportunityCloneUtil.CloneInput input = new DMT_OpportunityCloneUtil.CloneInput();
        input.originalOpportunity = originalOpp;
        input.opportunityLineItems = olis;
        input.tenors = tenors;
        input.mitigants = mitigants;
        input.xSells = xSells;
        input.opportunityClient = oppClient;
        input.localClient = localClient;
        input.participants = participants;

        List<DMT_OpportunityCloneUtil.CloneResult> results = DMT_OpportunityCloneUtil.clone(new List<DMT_OpportunityCloneUtil.CloneInput>{input});
        Test.stopTest();
        
        Assert.isNotNull(results[0].newOpportunityId, 'The Id of the new opportunity should not be null');
        Assert.isTrue(results[0].success, 'Clone should be successful');

        // Verify that Underlyings were cloned
        List<DMT_Underlying__c> clonedUnderlyings = [
            SELECT Id, DMT_Opportunity_Product__c 
            FROM DMT_Underlying__c 
            WHERE DMT_Opportunity_Product__c IN (
                SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :results[0].newOpportunityId
            )
        ];
        Assert.areEqual(originalUnderlyingsCount, clonedUnderlyings.size(), 'All underlyings should be cloned');
    }

    @IsTest
    static void testCloneWithUnderlyings() {
        Opportunity originalOpp = [SELECT Id, Name, Entific__c,AccountId,RecordTypeId,gf_opportunity_product_desc__c, StageName, closedate FROM Opportunity LIMIT 1];
        List<OpportunityLineItem> olis = [SELECT Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice, TotalPrice, DMT_Line_Amount__c, DMT_Commitment_Line_Amount__c, DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DMT_ExpectedFinal_Take__c, DMT_Expected_Drawn__c, DMT_Liquidity_Fee__c, DES_Commitment_Fees__c, DMT_Extension_Duration_Fees__c, DES_Other_Fees__c, DMT_Reference_Upfront_Fees__c, DMT_Line_Currency__c, entity_role_type__c, DMT_Sub_Limit__c, bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c, DMT_Deal_amount__c, g_currency_id__c, DMT_TXT_Commitment_Fees__c, DMT_TXT_Extension_Duration_Fees__c, DMT_TXT_Other_Fees_Accrual__c, DMT_TXT_Other_Fees_NonAccrual__c FROM OpportunityLineItem];
        List<DMT_Underlying__c> originalUnderlyings = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Underlying__c];
        DMT_Opportunity_Client__c oppClient = [SELECT Id, DMT_MDE_Opportunity__c FROM DMT_Opportunity_Client__c LIMIT 1];
        Account localClient = [SELECT Id FROM Account WHERE Id = :originalOpp.AccountId];

        Assert.isTrue(originalUnderlyings.size() > 0, 'Test data should have underlyings');

        Test.startTest();
        DMT_OpportunityCloneUtil.CloneInput input = new DMT_OpportunityCloneUtil.CloneInput();
        input.originalOpportunity = originalOpp;
        input.opportunityLineItems = olis;
        input.opportunityClient = oppClient;
        input.localClient = localClient;

        List<DMT_OpportunityCloneUtil.CloneResult> results = DMT_OpportunityCloneUtil.clone(new List<DMT_OpportunityCloneUtil.CloneInput>{input});
        Test.stopTest();

        Assert.isTrue(results[0].success, 'Clone with underlyings should be successful');
        
        // Verify that the cloned opportunity exists
        Opportunity clonedOpp = [SELECT Id FROM Opportunity WHERE Id = :results[0].newOpportunityId];
        Assert.isNotNull(clonedOpp, 'Cloned opportunity should exist');

        // Verify underlyings were cloned with correct data
        List<DMT_Underlying__c> clonedUnderlyings = [
            SELECT Id, Name, DMT_Max_Amount__c, DMT_Currency__c
            FROM DMT_Underlying__c 
            WHERE DMT_Opportunity_Product__c IN (
                SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :results[0].newOpportunityId
            )
        ];
        Assert.isTrue(clonedUnderlyings.size() > 0, 'Cloned underlyings should exist');
        Assert.areEqual(originalUnderlyings.size(), clonedUnderlyings.size(), 'Should clone all underlyings');
        Assert.areEqual('Test Underlying Restriction', clonedUnderlyings[0].Name, 'Cloned underlying should have correct name');
    }
    
    @IsTest
	static void testDifferentClient(){
    
	}
}