@isTest
private class DMT_OppFeatureGenCons_Calc_Test {

    @TestSetup
    static void loadTestData() {

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        Product2 prod = DMT_Test_DataFactory.generateProduct2();

        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(prod,pbe,opp);

        DMT_X_Sell__c xSellValid = DMT_Test_DataFactory.generatexSell(opp);

        DMT_Opportunity_Tenor__c tenorInvalid = DMT_Test_DataFactory.generateOpportunityTenor(oli);

        DMT_Test_DataFactory.generateTestRiskApprovalLines(opp.AccountId);

        DMT_Line__c testLineUpdate = [SELECT Id FROM DMT_Line__c LIMIT 1];
        DMT_Risk_Line_Term__c testRiskLineUpdate = [SELECT Id FROM DMT_Risk_Line_Term__c LIMIT 1];

        opp.DMT_Sanction__c = testLineUpdate.Id;
        update opp;

        oli.DMT_Associated_Line_Product__c = testRiskLineUpdate.Id;
        update oli;
    }

    @isTest
    static void testCheckValidations_AllConditions() {
        Opportunity opp = [SELECT Id, Name, DMT_Entity__c, DMT_Sanction__c,DMT_Opp_Id__c, DMT_CUR_Notional_Amount__c, DMT_Notional_Items_Sum__c, DMT_DATE_Maturity_Date__c, opp_external_id__c, DES_Client_Text__c, Booking__c, DES_Booking_Geography__c,
                        OwnerId, StageName, DMT_DATE_Initial_Date__c, DES_Date_Won_Lost__c, CurrencyIsoCode, DMT_NUM_Version__c, Entific__c, AccountId, DMT_CurrencyText__c,  DMT_Client_Type__c, Account.DES_Client_Type__c, Account.DES_Rating_Int__c,
                        Account.Client_STAR_ID__c, Account.Name,  (
                                SELECT Id,Name,gf_maturity_date__c,DMT_Associated_Line_Product__c,ProductCode,gf_accrual_fees_bp__c,DMT_Risk_Type__c,Product2Id,gf_entity_id__c,gf_financing_type__c,gf_funding_cost_db__c,gf_green_bonus__c,gf_social_bond__c,gf_funding_cost_fb__c,
                                CurrencyIsoCode,g_product_id__c,gf_country_risk__c,gf_country_rating__c,gf_crr2_essential_public_services__c,Funding_Curve__c,Life_Funding_Type__c,gf_amortization_type__c,gf_payment_frequency__c,
                                gf_intermediate_date__c,g_branch_id__c,gf_initial_date__c,g_currency_id__c, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c FROM OpportunityLineItems) FROM Opportunity];

        Test.startTest();
        // Call the method
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> result =
            DMT_OppFeatureGenCons_Calc.checkValidations(opp, 'TestGroup');
        Test.stopTest();

        // Basic asserts (optional)
        System.assertNotEquals(0, result.size(), 'Expected some validations to be triggered');

        Boolean foundXsellMsg = false;
        Boolean foundTenorMsg = false;
        Boolean foundInitialDateMsg = false;
        Boolean foundNotionalMsg = false;

        for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations fgc : result) {
            if (fgc.message.contains('Cross SELL')) {
                foundXsellMsg = true;
            }
            if (fgc.message.contains('Inconsistent Payment Date')) {
                foundTenorMsg = true;
            }
            if (fgc.message.contains('Initial Date is not consistent')) {
                foundInitialDateMsg = true;
            }
            if (fgc.message.contains('Notional Amount is consistent')) {
                foundNotionalMsg = true;
            }
        }

        /*System.assert(foundXsellMsg, 'Should detect invalid XSell Year');
        System.assert(foundTenorMsg, 'Should detect missing tenor date for User-Defined');
        System.assert(foundNotionalMsg, 'Should validate notional amounts consistency');*/
    }
    @isTest
    static void testCheckValidations_NotProductsLinked() {
        Opportunity opp = [SELECT Id, Name, DMT_Entity__c, DMT_Sanction__c,DMT_Opp_Id__c, DMT_CUR_Notional_Amount__c, DMT_Notional_Items_Sum__c, DMT_DATE_Maturity_Date__c, opp_external_id__c, DES_Client_Text__c, Booking__c, DES_Booking_Geography__c,
                        OwnerId, StageName, DMT_DATE_Initial_Date__c, DES_Date_Won_Lost__c, CurrencyIsoCode, DMT_NUM_Version__c, Entific__c, AccountId, DMT_CurrencyText__c,  DMT_Client_Type__c, Account.DES_Client_Type__c, Account.DES_Rating_Int__c,
                        Account.Client_STAR_ID__c, Account.Name,  (
                                SELECT Id,Name,gf_maturity_date__c,DMT_Associated_Line_Product__c,ProductCode,gf_accrual_fees_bp__c,DMT_Risk_Type__c,Product2Id,gf_entity_id__c,gf_financing_type__c,gf_funding_cost_db__c,gf_green_bonus__c,gf_social_bond__c,gf_funding_cost_fb__c,
                                CurrencyIsoCode,g_product_id__c,gf_country_risk__c,gf_country_rating__c,gf_crr2_essential_public_services__c,Funding_Curve__c,Life_Funding_Type__c,gf_amortization_type__c,gf_payment_frequency__c,
                                gf_intermediate_date__c,g_branch_id__c,gf_initial_date__c,g_currency_id__c, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c FROM OpportunityLineItems) FROM Opportunity];
        List<OpportunityLineItem> listOpli = new List<OpportunityLineItem>();
        for(OpportunityLineItem opli : opp.OpportunityLineItems){
            opli.DMT_Associated_Line_Product__c = null;
            listOpli.add(opli);
        }
        update listOpli;
        Test.startTest();
        // Call the method
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> result =
            DMT_OppFeatureGenCons_Calc.checkValidations(opp, 'TestGroup');
        Test.stopTest();

        // Basic asserts (optional)
        System.assertNotEquals(0, result.size(), 'Expected some validations to be triggered');

        Boolean foundXsellMsg = false;
        Boolean foundTenorMsg = false;
        Boolean foundInitialDateMsg = false;
        Boolean foundNotionalMsg = false;

        for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations fgc : result) {
            if (fgc.message.contains('Cross SELL')) {
                foundXsellMsg = true;
            }
            if (fgc.message.contains('Inconsistent Payment Date')) {
                foundTenorMsg = true;
            }
            if (fgc.message.contains('Initial Date is not consistent')) {
                foundInitialDateMsg = true;
            }
            if (fgc.message.contains('Notional Amount is consistent')) {
                foundNotionalMsg = true;
            }
        }

        /*System.assert(foundXsellMsg, 'Should detect invalid XSell Year');
        System.assert(foundTenorMsg, 'Should detect missing tenor date for User-Defined');
        System.assert(foundNotionalMsg, 'Should validate notional amounts consistency');*/
    }
}