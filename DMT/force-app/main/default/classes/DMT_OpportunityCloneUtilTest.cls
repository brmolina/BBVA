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
        // DMT_Test_DataFactory.generatexSell(opp);
        DMT_Test_DataFactory.generateOpportunityClient(opp.Id);
        DMT_TeamMember__c participants = new DMT_TeamMember__c(Opportunity__c = opp.Id, User__c = UserInfo.getUserId(), AccessLevel__c = 'Read');
        insert participants;
        
        
    }
    
    /* @IsTest
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
    } */
    
    @IsTest
    static void testDifferentClient(){
         Opportunity originalOpp = [SELECT Id, Name, Entific__c,AccountId,RecordTypeId,gf_opportunity_product_desc__c, StageName, closedate FROM Opportunity LIMIT 1];
        
        
        Account localCli = [SELECT Id,DES_Client_Type__c FROM Account WHERE Id = :originalOpp.AccountId];
        localCli.DES_Structure_Type__c = 'Subsidiary';
        
        update localCli;
        Account subDiffAccount = new Account();
        subDiffAccount.account_client__c='Y';
        subDiffAccount.Advising__c=false;
        subDiffAccount.BBVA_Entity__c='BBVA SA';
        subDiffAccount.BillingCity='MADRID';
        subDiffAccount.BillingCountry='ES';
        subDiffAccount.BillingPostalCode='28033';
        subDiffAccount.BillingState='MADRID';
        subDiffAccount.BillingStreet='AV GRAN Test DE HORTALEZA 0321';
        subDiffAccount.CurrencyIsoCode='EUR';
        subDiffAccount.cust_first_income_country_amount__c=45088445;
        subDiffAccount.cust_first_income_country_name__c='ESPAÑA (2222815.0 EUR)';
        subDiffAccount.DES_Activity__c='NDA';
        subDiffAccount.Name='sub Acc';
        //subDiffAccount.Past2_FY_Corp_Synd_Lending_amount__c = 13;
        subDiffAccount.Revenues_Last_Year_number__c = 13;
        insert subDiffAccount;
        
        List<OpportunityLineItem> olis = [SELECT Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice, TotalPrice, DMT_Line_Amount__c, DMT_Commitment_Line_Amount__c, DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DMT_ExpectedFinal_Take__c, DMT_Expected_Drawn__c, DMT_Liquidity_Fee__c, DES_Commitment_Fees__c, DMT_Extension_Duration_Fees__c, DES_Other_Fees__c, DMT_Reference_Upfront_Fees__c, DMT_Line_Currency__c, entity_role_type__c, DMT_Sub_Limit__c, bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c, DMT_Deal_amount__c, g_currency_id__c, DMT_TXT_Commitment_Fees__c, DMT_TXT_Extension_Duration_Fees__c, DMT_TXT_Other_Fees_Accrual__c, DMT_TXT_Other_Fees_NonAccrual__c 
                                            FROM OpportunityLineItem WHERE OpportunityId=:originalOpp.Id];
        List<DMT_Opportunity_Tenor__c> tenors = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Tenor__c ];
        List<DMT_Opportunity_Mitigant__c> mitigants = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Mitigant__c];
        List<DMT_Underlying__c> underlyings = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Underlying__c WHERE DMT_Opportunity_Product__r.OpportunityId =:originalOpp.Id];
        DMT_Opportunity_Client__c oppClient = [SELECT Id, DMT_MDE_Opportunity__c FROM DMT_Opportunity_Client__c LIMIT 1];
        List<DMT_TeamMember__c> participants = [SELECT Id, Opportunity__c, AccessLevel__c, User__c FROM DMT_TeamMember__c];
        
        Integer originalUnderlyingsCount = underlyings.size();
        
        Test.startTest();
        
        DMT_OpportunityCloneUtil.CloneInput input = new DMT_OpportunityCloneUtil.CloneInput();
        input.originalOpportunity = originalOpp;
        input.opportunityLineItems = olis;
        input.tenors = tenors;
        input.mitigants = mitigants;
        input.opportunityClient = oppClient;
        input.localClient = subDiffAccount;
        input.participants = participants;
        
        List<DMT_OpportunityCloneUtil.CloneResult> results = DMT_OpportunityCloneUtil.clone(new List<DMT_OpportunityCloneUtil.CloneInput>{input});
        Test.stopTest();
        
        //Assert.isNotNull(results[0].newOpportunityId, 'The Id of the new opportunity should not be null');
        //Assert.isTrue(results[0].success, 'Clone should be successful');
        
        // Verify that Underlyings were cloned
        List<DMT_Underlying__c> clonedUnderlyings = [
            SELECT Id, DMT_Opportunity_Product__c 
            FROM DMT_Underlying__c 
            WHERE DMT_Opportunity_Product__c IN (
                SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :results[0].newOpportunityId
            )
            ];
//Assert.areEqual(originalUnderlyingsCount, clonedUnderlyings.size(), 'All underlyings should be cloned');
    }
    @IsTest
    static void cloneGroupToDiffGRoup(){
        
        Opportunity originalOpp = [SELECT Id, Name, Entific__c,AccountId,RecordTypeId,gf_opportunity_product_desc__c, StageName, closedate FROM Opportunity LIMIT 1];
        
        //Custom Associations Opportunity
        Custom_Association_Opportunity__c customAssoOpp = new Custom_Association_Opportunity__c(Opportunity__c = originalOpp.Id, g_customer_id__c = 'ESMAIN0000001',
        gf_customer_group_id__c = 'GRPM-' + originalOpp.Id);
        insert customAssoOpp;
        //Custom Associations Client
         DMT_Custom_Association_ClientOpportunity__c customAssoClientOpp = new DMT_Custom_Association_ClientOpportunity__c();
                    customAssoClientOpp.DMT_Custom_Association_Opportunity__c = customAssoOpp.Id;
                    customAssoClientOpp.DMT_g_customer_id__c = 'ESMAIN0000001';
                    customAssoClientOpp.DMT_gf_customer_group_id__c = customAssoOpp.gf_customer_group_id__c;
                    customAssoClientOpp.DMT_g_entific_id__c = originalOpp.Entific__c;
                    insert customAssoClientOpp;
            System.debug('******original OPP=> '+originalOpp);
            System.debug('******customAssoOpp OPP=> '+customAssoOpp);
            System.debug('******customAssoClientOpp OPP=> '+customAssoClientOpp);

          Account groupAccount = new Account();
        groupAccount.account_client__c='N';
        groupAccount.Advising__c=false;
        groupAccount.BBVA_Entity__c='BBVA SA';
        groupAccount.BillingCity='MADRID';
        groupAccount.BillingCountry='ES';
        groupAccount.BillingPostalCode='28033';
        groupAccount.BillingState='MADRID';
        groupAccount.BillingStreet='AV GRAN Test DE HORTALEZA 0321';
        groupAccount.CurrencyIsoCode='EUR';
        groupAccount.cust_first_income_country_amount__c=45088445;
        groupAccount.cust_first_income_country_name__c='ESPAÑA (2222815.0 EUR)';
        groupAccount.DES_Activity__c='NDA';
        groupAccount.Name='Group Acc';
        //groupAccount.Past2_FY_Corp_Synd_Lending_amount__c = 13;
        groupAccount.Revenues_Last_Year_number__c = 13;
        groupAccount.DES_Group_Code__c = 'G20180109100997';
        groupAccount.DES_Structure_Type__c ='Group';
        insert groupAccount;
        

        List<OpportunityLineItem> olis = [SELECT Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice, TotalPrice, DMT_Line_Amount__c, DMT_Commitment_Line_Amount__c, DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DMT_ExpectedFinal_Take__c, DMT_Expected_Drawn__c, DMT_Liquidity_Fee__c, DES_Commitment_Fees__c, DMT_Extension_Duration_Fees__c, DES_Other_Fees__c, DMT_Reference_Upfront_Fees__c, DMT_Line_Currency__c, entity_role_type__c, DMT_Sub_Limit__c, bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c, DMT_Deal_amount__c, g_currency_id__c, DMT_TXT_Commitment_Fees__c, DMT_TXT_Extension_Duration_Fees__c, DMT_TXT_Other_Fees_Accrual__c, DMT_TXT_Other_Fees_NonAccrual__c 
                                            FROM OpportunityLineItem WHERE OpportunityId=:originalOpp.Id];
        List<DMT_Opportunity_Tenor__c> tenors = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Tenor__c ];
        List<DMT_Opportunity_Mitigant__c> mitigants = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Mitigant__c];
        List<DMT_Underlying__c> underlyings = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Underlying__c WHERE DMT_Opportunity_Product__r.OpportunityId =:originalOpp.Id];
        DMT_Opportunity_Client__c oppClient = [SELECT Id, DMT_MDE_Opportunity__c FROM DMT_Opportunity_Client__c LIMIT 1];
        List<DMT_TeamMember__c> participants = [SELECT Id, Opportunity__c, AccessLevel__c, User__c FROM DMT_TeamMember__c];
        
        Integer originalUnderlyingsCount = underlyings.size();
        
        Test.startTest();
        
        DMT_OpportunityCloneUtil.CloneInput input = new DMT_OpportunityCloneUtil.CloneInput();
        input.originalOpportunity = originalOpp;
        input.opportunityLineItems = olis;
        input.tenors = tenors;
        input.mitigants = mitigants;
        input.opportunityClient = oppClient;
        input.localClient = groupAccount;
        input.participants = participants;
        
        List<DMT_OpportunityCloneUtil.CloneResult> results = DMT_OpportunityCloneUtil.clone(new List<DMT_OpportunityCloneUtil.CloneInput>{input});
        Test.stopTest();
        
        
    }
    @IsTest
    static void sameClientTest(){
        
        Opportunity originalOpp = [SELECT Id, Name, Entific__c,AccountId,RecordTypeId,gf_opportunity_product_desc__c, StageName, closedate FROM Opportunity LIMIT 1];
        
        
        Account localCli = [SELECT Id,DES_Client_Type__c FROM Account WHERE Id = :originalOpp.AccountId];
        localCli.DES_Structure_Type__c = 'Subsidiary';
        
        update localCli;
        
        
        List<OpportunityLineItem> olis = [SELECT Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice, TotalPrice, DMT_Line_Amount__c, DMT_Commitment_Line_Amount__c, DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DMT_ExpectedFinal_Take__c, DMT_Expected_Drawn__c, DMT_Liquidity_Fee__c, DES_Commitment_Fees__c, DMT_Extension_Duration_Fees__c, DES_Other_Fees__c, DMT_Reference_Upfront_Fees__c, DMT_Line_Currency__c, entity_role_type__c, DMT_Sub_Limit__c, bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c, DMT_Deal_amount__c, g_currency_id__c, DMT_TXT_Commitment_Fees__c, DMT_TXT_Extension_Duration_Fees__c, DMT_TXT_Other_Fees_Accrual__c, DMT_TXT_Other_Fees_NonAccrual__c 
                                            FROM OpportunityLineItem WHERE OpportunityId=:originalOpp.Id];
        List<DMT_Opportunity_Tenor__c> tenors = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Tenor__c ];
        List<DMT_Opportunity_Mitigant__c> mitigants = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Mitigant__c];
        List<DMT_Underlying__c> underlyings = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Underlying__c WHERE DMT_Opportunity_Product__r.OpportunityId =:originalOpp.Id];
        DMT_Opportunity_Client__c oppClient = [SELECT Id, DMT_MDE_Opportunity__c FROM DMT_Opportunity_Client__c LIMIT 1];
        List<DMT_TeamMember__c> participants = [SELECT Id, Opportunity__c, AccessLevel__c, User__c FROM DMT_TeamMember__c];
        
        Integer originalUnderlyingsCount = underlyings.size();
        
        Test.startTest();
        
        DMT_OpportunityCloneUtil.CloneInput input = new DMT_OpportunityCloneUtil.CloneInput();
        input.originalOpportunity = originalOpp;
        input.opportunityLineItems = olis;
        input.tenors = tenors;
        input.mitigants = mitigants;
        input.opportunityClient = oppClient;
        input.localClient = localCli;
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
    static void resolveMainHolder(){
        
        Date lastDate;
        String lastDatetxt;
        lastDatetxt = DMT_HPG_Utils.lastDate();
        lastDate = Date.valueOf(lastDatetxt);
        
        Opportunity originalOpp = [SELECT Id, Name, Entific__c,AccountId,RecordTypeId,gf_opportunity_product_desc__c, StageName, closedate FROM Opportunity LIMIT 1];
        originalOpp.Entific__c ='ES';
        List<OpportunityLineItem> olis = [SELECT Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice, TotalPrice, DMT_Line_Amount__c, DMT_Commitment_Line_Amount__c, DMT_NewMoney_BBVA__c, DMT_OldMoney_BBVA__c, DMT_ExpectedFinal_Take__c, DMT_Expected_Drawn__c, DMT_Liquidity_Fee__c, DES_Commitment_Fees__c, DMT_Extension_Duration_Fees__c, DES_Other_Fees__c, DMT_Reference_Upfront_Fees__c, DMT_Line_Currency__c, entity_role_type__c, DMT_Sub_Limit__c, bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c, DMT_Deal_amount__c, g_currency_id__c, DMT_TXT_Commitment_Fees__c, DMT_TXT_Extension_Duration_Fees__c, DMT_TXT_Other_Fees_Accrual__c, DMT_TXT_Other_Fees_NonAccrual__c 
                                            FROM OpportunityLineItem WHERE OpportunityId=:originalOpp.Id];
        List<DMT_Opportunity_Tenor__c> tenors = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Tenor__c ];
        List<DMT_Opportunity_Mitigant__c> mitigants = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Opportunity_Mitigant__c];
        List<DMT_Underlying__c> underlyings = [SELECT Id, DMT_Opportunity_Product__c FROM DMT_Underlying__c WHERE DMT_Opportunity_Product__r.OpportunityId =:originalOpp.Id];
        DMT_Opportunity_Client__c oppClient = [SELECT Id, DMT_MDE_Opportunity__c FROM DMT_Opportunity_Client__c LIMIT 1];
        List<DMT_TeamMember__c> participants = [SELECT Id, Opportunity__c, AccessLevel__c, User__c FROM DMT_TeamMember__c];
        
        Account localCli = [SELECT Id,DES_Client_Type__c,DMT_Entific__c FROM Account WHERE Id = :originalOpp.AccountId];
        localCli.DES_Structure_Type__c = 'Subsidiary';
        System.debug('+++ENtific'+localCli.DMT_Entific__c);
        /* localCli.DMT_Entific__c='ES'; */
        
        DMT_OpportunityCloneUtil.CloneInput input = new DMT_OpportunityCloneUtil.CloneInput();
        input.originalOpportunity = originalOpp;
        input.opportunityLineItems = olis;
        input.tenors = tenors;
        input.mitigants = mitigants;
        input.opportunityClient = oppClient;
        input.localClient = localCli;
        input.participants = participants;
        
        
        List<DMT_OpportunityCloneUtil.CloneResult> results = DMT_OpportunityCloneUtil.clone(new List<DMT_OpportunityCloneUtil.CloneInput>{input});
        Id newOppId = results[0].newOpportunityId;
        Opportunity newOpp = [SELECT Id from Opportunity WHERE Id=:newOppId];
        DMT_Opportunity_Client__c newOppClient =[SELECT Id FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c =:newOppId];
        
        DMT_OpportunityCloneUtil.MainHolderSelection selection = DMT_OpportunityCloneUtil.resolveMainHolderSelection(localCli.Id, originalOpp.Entific__c,lastDate);
        
        Map<String, Object> comparisonResult = DMT_Opportunity_Utils.getComparisonAccount(
        new Map<String, Object>{ 'oppAccountId' => localCli.Id }, new Map<String, Object>(), null);
        Id comparisonAccountId = (Id) comparisonResult.get('comparisonAccountId');
        
        DMT_CreateOpportunityService.ClientValues clientValues = DMT_CreateOpportunityService.getClientValues(localCli.Id, comparisonAccountId);
        
        Map<String, Object> leveragedLendingOutput = DMT_Callout_LeveragedLending.callLeveragedLendingService(
            clientValues.groupCode, lastDatetxt, new Map<String, Object>()
            );
        
        String leveragedLendingIndType = leveragedLendingOutput != null ? (String) leveragedLendingOutput.get('leveragedLendingIndType'): null;
        
        
        
        DMT_OpportunityCloneUtil.createMainHolderAssociations(newOpp,
        selection,
        clientValues,
        leveragedLendingIndType,
        newOppClient );
    }
}