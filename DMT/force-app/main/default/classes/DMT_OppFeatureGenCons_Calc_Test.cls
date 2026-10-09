@isTest
private class DMT_OppFeatureGenCons_Calc_Test {

    @TestSetup
    static void loadTestData() {

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        Product2 prod = DMT_Test_DataFactory.generateProduct2();

        DMT_Opportunity_Client__c oppCl =DMT_Test_DataFactory.generateOpportunityClient(opp.Id);

        PricebookEntry pbe = DMT_Test_DataFactory.generatePricebookEntry(prod);

        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(prod,pbe,opp);

        DMT_Test_DataFactory.generatexSell(opp);

        DMT_Test_DataFactory.generateOpportunityTenor(oli);

        DMT_Test_DataFactory.generateTestRiskApprovalLines(opp.AccountId);

        DMT_Line__c testLineUpdate = [SELECT Id FROM DMT_Line__c LIMIT 1];
        DMT_Risk_Line_Term__c testRiskLineUpdate = [SELECT Id FROM DMT_Risk_Line_Term__c LIMIT 1];

        oppCl.g_upd_lmscl_internal_ratg_type__c = 'A+';
        update oppCl;

        opp.DMT_Sanction__c = testLineUpdate.Id;
        update opp;

        oli.DMT_Associated_Line_Product__c = testRiskLineUpdate.Id;
        update oli;
    }

    @isTest
    static void testCheckValidationsAllConditions() {
        Opportunity opp = [SELECT Id, Name, DMT_Entity__c, DMT_Sanction__c, DMT_Approver__c, DMT_Opportunity_amount__c, DMT_ApproverGlobalBanker__c, DMT_Booking_Unit_Risk_Analyst__c,DMT_Opp_Id__c, DMT_CUR_Notional_Amount__c, DMT_DATE_Maturity_Date__c, opp_external_id__c, DES_Client_Text__c, Booking__c, DES_Booking_Geography__c,
                        OwnerId, StageName, DMT_DATE_Initial_Date__c, DES_Date_Won_Lost__c, CurrencyIsoCode, DMT_NUM_Version__c, Entific__c, AccountId, DMT_CurrencyText__c,  DMT_Client_Type__c, Account.DES_Client_Type__c, Account.DES_Rating_Int__c,
                        Account.Client_STAR_ID__c, Account.Name, Account.g_customer_id__c,DMT_CUR_Notional__c, DMT_Tenor__c, DMT_Product_Area__c, DMT_Threshold_Type__c,
                        (SELECT Id, g_customer_id__c FROM Custom_Associations__r), (
                                SELECT Id,Name,gf_maturity_date__c,DMT_Associated_Line_Product__c,ProductCode,gf_accrual_fees_bp__c,DMT_Risk_Type__c,Product2Id,gf_entity_id__c,gf_financing_type__c,gf_funding_cost_db__c,gf_green_bonus__c,gf_social_bond__c,gf_funding_cost_fb__c,
                                CurrencyIsoCode,g_product_id__c,gf_country_risk__c,gf_country_rating__c,gf_crr2_essential_public_services__c,Funding_Curve__c,Life_Funding_Type__c,gf_amortization_type__c,gf_payment_frequency__c,
                                gf_intermediate_date__c,g_branch_id__c,gf_initial_date__c,g_currency_id__c, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c, DMT_Extension_Duration_Fees__c, DMT_sustainable_deal_assessment__c,DMT_Line_Oneoffdeal__c FROM OpportunityLineItems) FROM Opportunity];

        Account acc = [SELECT Id,DES_Rating_Int__c,DES_Segment__c FROM Account WHERE Id=:opp.AccountId LIMIT 1];
        DMT_Opportunity_Client__c oppClient = [SELECT Id,g_upd_lmscl_internal_ratg_type__c,DMT_MDE_Opportunity__c, DMT_Scoring__c, External_Rating__c, DMT_External_Rating_Fitch__c, DMT_CAMN__c,
                                                        DMT_External_Rating_Moodys__c, DMT_External_Rating_SP__c, DMT_Leveraged_Lending__c,DMT_Sector__c,DMT_Subsector__c, DMT_Activity__c, Counterpart__c
                                                        FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c =:opp.Id LIMIT 1 ];
        String expectedMatchedRating = 'UT_MATCH_RATING';
        oppClient.g_upd_lmscl_internal_ratg_type__c = expectedMatchedRating;
        update oppClient;
        String customerIdForGroup;
        if (opp.Custom_Associations__r != null && !opp.Custom_Associations__r.isEmpty()) {
            SObject customAssociation = (SObject)opp.Custom_Associations__r[0];
            customerIdForGroup = (String)customAssociation.get('g_customer_id__c');
            if (String.isBlank(customerIdForGroup)) {
                customerIdForGroup = 'UT_CUST_INMEM_001';
                customAssociation.put('g_customer_id__c', customerIdForGroup);
            }
        } else {
            customerIdForGroup = opp.Account.g_customer_id__c;
            if (String.isBlank(customerIdForGroup)) {
                customerIdForGroup = 'UT_CUST_INMEM_001';
                opp.Account.g_customer_id__c = customerIdForGroup;
            }
        }
        if (customerIdForGroup == null) {
            customerIdForGroup = '';
        }

        Test.startTest();
        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
            {
                'customerId' => customerIdForGroup,
                'currentRatingToolDate' => Date.today(),
                'updLmsclInternalRatgType' => expectedMatchedRating,
                'customerCounterpartiesCodesDesc' => 'A+',
                'totalRatingScoreNumber' => 8.236,
                'unifiedExtRatgLtFcType' => 'NR',
                'fitchLtRatingLcType' => 'A',
                'spLtRatingLcType' => 'A',
                'moodysLtRatingLcType' => 'A2',
                'assetAllocationSectorType' => 'SectorTest',
                'assetAllocationSubSecType' => 'SubSectorTest',
                'assetAllocationActvyType' => 'ActivityTest',
                'leveragedLendingIndType' => 'N/A',
                'activityMinimumLevelCode' => 'CAMN_TEST'
            }};

        // Call the method
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> result =
            DMT_OppFeatureGenCons_Calc.checkValidations(opp,acc,oppclient, JSON.serialize(clientsGroup));
        Test.stopTest();

        // Basic asserts (optional)
        System.assertNotEquals(0, result.size(), 'Expected some validations to be triggered');

        Boolean foundXsellMsg = false;
        Boolean foundTenorMsg = false;
        Boolean foundInitialDateMsg = false;
        Boolean foundNotionalMsg = false;
        Boolean foundInternalRatingConsistentByName = false;
        Boolean foundClientInformationMatch = false;

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
            if (fgc.name == 'Rating is consistent') {
                foundInternalRatingConsistentByName = true;
            }
            if (fgc.name == 'Client information matches original data') {
                foundClientInformationMatch = true;
            }
        }

        /*System.assert(foundXsellMsg, 'Should detect invalid XSell Year');
        System.assert(foundTenorMsg, 'Should detect missing tenor date for User-Defined');
        System.assert(foundNotionalMsg, 'Should validate notional amounts consistency');*/
        System.assert(foundClientInformationMatch, 'A blank external rating must match an HPG null rating represented as NR in the client template.');
        System.debug('foundInternalRatingConsistentByName: ' + foundInternalRatingConsistentByName);
    }
    @isTest
    static void testCheckValidationsNoProductsLinked() {
        Opportunity opp = [SELECT Id, Name, DMT_Entity__c, DMT_Sanction__c,DMT_Opp_Id__c, DMT_Approver__c, DMT_Opportunity_amount__c, DMT_ApproverGlobalBanker__c, DMT_Booking_Unit_Risk_Analyst__c, DMT_CUR_Notional_Amount__c, DMT_DATE_Maturity_Date__c, opp_external_id__c, DES_Client_Text__c, Booking__c, DES_Booking_Geography__c,
                        OwnerId, StageName, DMT_DATE_Initial_Date__c, DES_Date_Won_Lost__c, CurrencyIsoCode, DMT_NUM_Version__c, Entific__c, AccountId, DMT_CurrencyText__c,  DMT_Client_Type__c, Account.DES_Client_Type__c, Account.DES_Rating_Int__c,
                        Account.Client_STAR_ID__c, Account.Name, Account.g_customer_id__c,DMT_CUR_Notional__c, DMT_Tenor__c, DMT_Product_Area__c, DMT_Threshold_Type__c,
                        (SELECT Id, g_customer_id__c FROM Custom_Associations__r), (
                                SELECT Id,Name,gf_maturity_date__c,DMT_Associated_Line_Product__c,ProductCode,gf_accrual_fees_bp__c,DMT_Risk_Type__c,Product2Id,gf_entity_id__c,gf_financing_type__c,gf_funding_cost_db__c,gf_green_bonus__c,gf_social_bond__c,gf_funding_cost_fb__c,
                                CurrencyIsoCode,g_product_id__c,gf_country_risk__c,gf_country_rating__c,gf_crr2_essential_public_services__c,Funding_Curve__c,Life_Funding_Type__c,gf_amortization_type__c,gf_payment_frequency__c,
                                gf_intermediate_date__c,g_branch_id__c,gf_initial_date__c,g_currency_id__c, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c, DMT_Extension_Duration_Fees__c, DMT_sustainable_deal_assessment__c,DMT_Line_Oneoffdeal__c FROM OpportunityLineItems) FROM Opportunity];
        List<OpportunityLineItem> listOpli = new List<OpportunityLineItem>();
        for(OpportunityLineItem opli : opp.OpportunityLineItems){
            opli.DMT_Associated_Line_Product__c = null;
            listOpli.add(opli);
        }
        update listOpli;
         Account acc = [SELECT Id,DES_Rating_Int__c,DES_Segment__c FROM Account WHERE Id=:opp.AccountId LIMIT 1];
        DMT_Opportunity_Client__c oppClient = [SELECT Id,g_upd_lmscl_internal_ratg_type__c,DMT_MDE_Opportunity__c, DMT_Scoring__c, External_Rating__c, DMT_External_Rating_Fitch__c, DMT_CAMN__c,
                                                        DMT_External_Rating_Moodys__c, DMT_External_Rating_SP__c, DMT_Leveraged_Lending__c, DMT_Sector__c,DMT_Subsector__c, DMT_Activity__c, Counterpart__c
                                                        FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c =:opp.Id LIMIT 1 ];
        String customerIdForGroup;
        if (opp.Custom_Associations__r != null && !opp.Custom_Associations__r.isEmpty()) {
            SObject customAssociation = (SObject)opp.Custom_Associations__r[0];
            customerIdForGroup = (String)customAssociation.get('g_customer_id__c');
            if (String.isBlank(customerIdForGroup)) {
                customerIdForGroup = 'UT_CUST_INMEM_002';
                customAssociation.put('g_customer_id__c', customerIdForGroup);
            }
        } else {
            customerIdForGroup = opp.Account.g_customer_id__c;
            if (String.isBlank(customerIdForGroup)) {
                customerIdForGroup = 'UT_CUST_INMEM_002';
                opp.Account.g_customer_id__c = customerIdForGroup;
            }
        }
        if (customerIdForGroup == null) {
            customerIdForGroup = '';
        }

        Test.startTest();

        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{new Map<String, Object>
            {
                'customerId' => customerIdForGroup,
                'currentRatingToolDate' => Date.today(),
                'updLmsclInternalRatgType' => 'A-',
                'customerCounterpartiesCodesDesc' => 'A+',
                'totalRatingScoreNumber' => 6.445,
                'unifiedExtRatgLtFcType' => 'NR',
                'fitchLtRatingLcType' => 'BBB',
                'spLtRatingLcType' => 'BBB',
                'moodysLtRatingLcType' => 'Baa2',
                'assetAllocationSectorType' => 'SectorMismatch',
                'assetAllocationSubSecType' => 'SubSectorMismatch',
                'assetAllocationActvyType' => 'ActivityMismatch',
                'leveragedLendingIndType' => 'Y',
                'activityMinimumLevelCode' => 'CAMN_MISMATCH'
            }};

        // Call the method
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> result =
            DMT_OppFeatureGenCons_Calc.checkValidations(opp, acc,oppClient, JSON.serialize(clientsGroup));
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
    }

    @isTest
    static void testRatingValidationGreen() {
        Opportunity opp = [SELECT Id, Name, DMT_Entity__c, DMT_Sanction__c, DMT_Approver__c, DMT_ApproverGlobalBanker__c, DMT_Booking_Unit_Risk_Analyst__c,
                            DMT_Opp_Id__c, DMT_CUR_Notional_Amount__c, DMT_Opportunity_amount__c, DMT_DATE_Maturity_Date__c, opp_external_id__c, DES_Client_Text__c, Booking__c, DES_Booking_Geography__c,
                            OwnerId, StageName, DMT_DATE_Initial_Date__c, DES_Date_Won_Lost__c, CurrencyIsoCode, DMT_NUM_Version__c, Entific__c, AccountId, DMT_CurrencyText__c,
                            DMT_Client_Type__c, Account.DES_Client_Type__c, Account.DES_Rating_Int__c, Account.Client_STAR_ID__c, Account.Name, Account.g_customer_id__c,
                            DMT_CUR_Notional__c, DMT_Tenor__c, DMT_Product_Area__c, DMT_Threshold_Type__c,
                            (SELECT Id, g_customer_id__c FROM Custom_Associations__r),
                            (SELECT Id, Name, gf_maturity_date__c, DMT_Associated_Line_Product__c, ProductCode, gf_accrual_fees_bp__c, DMT_Risk_Type__c, Product2Id,
                             gf_entity_id__c, gf_financing_type__c, gf_funding_cost_db__c, gf_green_bonus__c, gf_social_bond__c, gf_funding_cost_fb__c,
                             CurrencyIsoCode, g_product_id__c, gf_country_risk__c, gf_country_rating__c, gf_crr2_essential_public_services__c, Funding_Curve__c,
                             Life_Funding_Type__c, gf_amortization_type__c, gf_payment_frequency__c, gf_intermediate_date__c, g_branch_id__c, gf_initial_date__c,
                             g_currency_id__c, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c,
                             DMT_Extension_Duration_Fees__c, DMT_sustainable_deal_assessment__c,DMT_Line_Oneoffdeal__c FROM OpportunityLineItems)
                           FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id, DES_Rating_Int__c, DES_Segment__c FROM Account WHERE Id = :opp.AccountId LIMIT 1];
        DMT_Opportunity_Client__c oppClient = [SELECT Id, g_upd_lmscl_internal_ratg_type__c, DMT_MDE_Opportunity__c, DMT_Scoring__c, External_Rating__c,
                                               DMT_External_Rating_Fitch__c, DMT_CAMN__c, DMT_External_Rating_Moodys__c, DMT_External_Rating_SP__c,
                                               DMT_Leveraged_Lending__c, DMT_Sector__c, DMT_Subsector__c, DMT_Activity__c, Counterpart__c
                                               FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c = :opp.Id LIMIT 1];

        String customerId;
        if (opp.Custom_Associations__r != null && !opp.Custom_Associations__r.isEmpty()) {
            SObject ca = opp.Custom_Associations__r[0];
            customerId = (String)ca.get('g_customer_id__c');
            if (String.isBlank(customerId)) {
                customerId = 'UT_GREEN_CUST';
                ca.put('g_customer_id__c', customerId);
            }
        } else {
            customerId = opp.Account.g_customer_id__c;
            if (String.isBlank(customerId)) {
                customerId = 'UT_GREEN_CUST';
                opp.Account.g_customer_id__c = customerId;
            }
        }

        // Valid rating: scaleLastUpdDate recent, ratingValidityStartDate + 19mo still in the future
        String recentDate    = String.valueOf(Date.today().addMonths(-6));
        String validityStart = String.valueOf(Date.today().addMonths(-1));

        List<Map<String, Object>> clientsGroup = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerId'                 => customerId,
                'scaleLastUpdDate'           => recentDate,
                'ratingValidityStartDate'    => validityStart,
                'rtFfssvldydtmtNumber'       => 19,
                'currentRatingToolDate'      => recentDate,
                'ffssRegulatoryRatingDate'   => validityStart,
                'updLmsclInternalRatgType'   => oppClient.g_upd_lmscl_internal_ratg_type__c,
                'totalRatingScoreNumber'     => oppClient.DMT_Scoring__c != null ? oppClient.DMT_Scoring__c : 7.0,
                'unifiedExtRatgLtFcType'     => oppClient.External_Rating__c != null ? oppClient.External_Rating__c : 'NR',
                'fitchLtRatingLcType'        => oppClient.DMT_External_Rating_Fitch__c,
                'spLtRatingLcType'           => oppClient.DMT_External_Rating_SP__c,
                'moodysLtRatingLcType'       => oppClient.DMT_External_Rating_Moodys__c,
                'assetAllocationSectorType'  => oppClient.DMT_Sector__c,
                'assetAllocationSubSecType'  => oppClient.DMT_Subsector__c,
                'assetAllocationActvyType'   => oppClient.DMT_Activity__c,
                'leveragedLendingIndType'    => oppClient.DMT_Leveraged_Lending__c != null ? oppClient.DMT_Leveraged_Lending__c : 'N/A',
                'activityMinimumLevelCode'   => oppClient.DMT_CAMN__c
            }
        };

        Test.startTest();
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> result =
            DMT_OppFeatureGenCons_Calc.checkValidations(opp, acc, oppClient, JSON.serialize(clientsGroup));
        Test.stopTest();

        Boolean foundRatingGreen = false;
        for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations fgc : result) {
            if (fgc.name == DMT_Constants.FEATURE_NAME_RATING && fgc.state == DMT_Constants.FEATURE_GC_STATE_GREEN) {
                foundRatingGreen = true;
            }
        }
        System.assert(foundRatingGreen, 'Expected GREEN rating when scaleLastUpdDate is recent and validity is within 19 months');
    }

    @isTest
    static void testRatingValidationYellow() {
        Opportunity opp = [SELECT Id, Name, DMT_Entity__c, DMT_Sanction__c, DMT_Approver__c, DMT_ApproverGlobalBanker__c, DMT_Booking_Unit_Risk_Analyst__c,
                            DMT_Opp_Id__c, DMT_CUR_Notional_Amount__c, DMT_Opportunity_amount__c, DMT_DATE_Maturity_Date__c, opp_external_id__c, DES_Client_Text__c, Booking__c, DES_Booking_Geography__c,
                            OwnerId, StageName, DMT_DATE_Initial_Date__c, DES_Date_Won_Lost__c, CurrencyIsoCode, DMT_NUM_Version__c, Entific__c, AccountId, DMT_CurrencyText__c,
                            DMT_Client_Type__c, Account.DES_Client_Type__c, Account.DES_Rating_Int__c, Account.Client_STAR_ID__c, Account.Name, Account.g_customer_id__c,
                            DMT_CUR_Notional__c, DMT_Tenor__c, DMT_Product_Area__c, DMT_Threshold_Type__c,
                            (SELECT Id, g_customer_id__c FROM Custom_Associations__r),
                            (SELECT Id, Name, gf_maturity_date__c, DMT_Associated_Line_Product__c, ProductCode, gf_accrual_fees_bp__c, DMT_Risk_Type__c, Product2Id,
                             gf_entity_id__c, gf_financing_type__c, gf_funding_cost_db__c, gf_green_bonus__c, gf_social_bond__c, gf_funding_cost_fb__c,
                             CurrencyIsoCode, g_product_id__c, gf_country_risk__c, gf_country_rating__c, gf_crr2_essential_public_services__c, Funding_Curve__c,
                             Life_Funding_Type__c, gf_amortization_type__c, gf_payment_frequency__c, gf_intermediate_date__c, g_branch_id__c, gf_initial_date__c,
                             g_currency_id__c, DMT_Associated_Line_Product__r.gf_group_priority_line_id__c, gf_group_priority_opportunity_id__c,
                             DMT_Extension_Duration_Fees__c, DMT_sustainable_deal_assessment__c,DMT_Line_Oneoffdeal__c FROM OpportunityLineItems)
                           FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id, DES_Rating_Int__c, DES_Segment__c FROM Account WHERE Id = :opp.AccountId LIMIT 1];
        DMT_Opportunity_Client__c oppClient = [SELECT Id, g_upd_lmscl_internal_ratg_type__c, DMT_MDE_Opportunity__c, DMT_Scoring__c, External_Rating__c,
                                               DMT_External_Rating_Fitch__c, DMT_CAMN__c, DMT_External_Rating_Moodys__c, DMT_External_Rating_SP__c,
                                               DMT_Leveraged_Lending__c, DMT_Sector__c, DMT_Subsector__c, DMT_Activity__c, Counterpart__c
                                               FROM DMT_Opportunity_Client__c WHERE DMT_MDE_Opportunity__c = :opp.Id LIMIT 1];

        String customerId;
        if (opp.Custom_Associations__r != null && !opp.Custom_Associations__r.isEmpty()) {
            SObject ca = opp.Custom_Associations__r[0];
            customerId = (String)ca.get('g_customer_id__c');
            if (String.isBlank(customerId)) {
                customerId = 'UT_YELLOW_CUST';
                ca.put('g_customer_id__c', customerId);
            }
        } else {
            customerId = opp.Account.g_customer_id__c;
            if (String.isBlank(customerId)) {
                customerId = 'UT_YELLOW_CUST';
                opp.Account.g_customer_id__c = customerId;
            }
        }

        // YELLOW case 1: no rating dates at all
        List<Map<String, Object>> clientsGroupNoDates = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerId'                 => customerId,
                'updLmsclInternalRatgType'   => 'A',
                'totalRatingScoreNumber'     => 7.0,
                'unifiedExtRatgLtFcType'     => 'NR',
                'leveragedLendingIndType'    => 'N/A'
            }
        };

        Test.startTest();
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> resultNoDates =
            DMT_OppFeatureGenCons_Calc.checkValidations(opp, acc, oppClient, JSON.serialize(clientsGroupNoDates));

        // YELLOW case 2: scaleLastUpdDate older than 12 months
        String oldDate = String.valueOf(Date.today().addMonths(-13));
        List<Map<String, Object>> clientsGroupOldDate = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerId'                 => customerId,
                'scaleLastUpdDate'           => oldDate,
                'ratingValidityStartDate'    => oldDate,
                'rtFfssvldydtmtNumber'       => 19,
                'updLmsclInternalRatgType'   => 'A',
                'totalRatingScoreNumber'     => 7.0,
                'unifiedExtRatgLtFcType'     => 'NR',
                'leveragedLendingIndType'    => 'N/A'
            }
        };
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> resultOldDate =
            DMT_OppFeatureGenCons_Calc.checkValidations(opp, acc, oppClient, JSON.serialize(clientsGroupOldDate));

        // YELLOW case 3: validity expired (ratingValidityStartDate + 19mo in the past)
        String recentDate  = String.valueOf(Date.today().addMonths(-3));
        String expiredStart = String.valueOf(Date.today().addMonths(-20));
        List<Map<String, Object>> clientsGroupExpired = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerId'                 => customerId,
                'scaleLastUpdDate'           => recentDate,
                'ratingValidityStartDate'    => expiredStart,
                'rtFfssvldydtmtNumber'       => 19,
                'updLmsclInternalRatgType'   => 'A',
                'totalRatingScoreNumber'     => 7.0,
                'unifiedExtRatgLtFcType'     => 'NR',
                'leveragedLendingIndType'    => 'N/A'
            }
        };
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> resultExpired =
            DMT_OppFeatureGenCons_Calc.checkValidations(opp, acc, oppClient, JSON.serialize(clientsGroupExpired));

        // YELLOW case 4: currentRatingToolDate path — ffssRegulatoryRatingDate expired (covers line 347)
        String currentRecentDate  = String.valueOf(Date.today().addMonths(-3));
        String ffssExpiredDate    = String.valueOf(Date.today().addMonths(-20));
        List<Map<String, Object>> clientsGroupFfssExpired = new List<Map<String, Object>>{
            new Map<String, Object>{
                'customerId'                 => customerId,
                'currentRatingToolDate'      => currentRecentDate,
                'ffssRegulatoryRatingDate'   => ffssExpiredDate,
                'updLmsclInternalRatgType'   => 'A',
                'totalRatingScoreNumber'     => 7.0,
                'unifiedExtRatgLtFcType'     => 'NR',
                'leveragedLendingIndType'    => 'N/A'
            }
        };
        List<DMT_Wrapper_Passport_Abs.FeatureGenConsiderations> resultFfssExpired =
            DMT_OppFeatureGenCons_Calc.checkValidations(opp, acc, oppClient, JSON.serialize(clientsGroupFfssExpired));
        Test.stopTest();

        Boolean yellowNoDates = false, yellowOldDate = false, yellowExpired = false, yellowFfssExpired = false;
        for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations fgc : resultNoDates) {
            if (fgc.name == DMT_Constants.FEATURE_NAME_RATING && fgc.state == DMT_Constants.FEATURE_GC_STATE_YELLOW) { yellowNoDates = true; }
        }
        for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations fgc : resultOldDate) {
            if (fgc.name == DMT_Constants.FEATURE_NAME_RATING && fgc.state == DMT_Constants.FEATURE_GC_STATE_YELLOW) { yellowOldDate = true; }
        }
        for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations fgc : resultExpired) {
            if (fgc.name == DMT_Constants.FEATURE_NAME_RATING && fgc.state == DMT_Constants.FEATURE_GC_STATE_YELLOW) { yellowExpired = true; }
        }
        for (DMT_Wrapper_Passport_Abs.FeatureGenConsiderations fgc : resultFfssExpired) {
            if (fgc.name == DMT_Constants.FEATURE_NAME_RATING && fgc.state == DMT_Constants.FEATURE_GC_STATE_YELLOW) { yellowFfssExpired = true; }
        }
        System.assert(yellowNoDates,     'Expected YELLOW when no rating dates are present');
        System.assert(yellowOldDate,     'Expected YELLOW when scaleLastUpdDate is older than 12 months');
        System.assert(yellowExpired,     'Expected YELLOW when ratingValidityStartDate + 19 months is in the past');
        System.assert(yellowFfssExpired, 'Expected YELLOW when ffssRegulatoryRatingDate + 19 months is in the past');
    }

    @isTest
    static void testTransformSegmentToCounterpart() {
        Test.startTest();

        System.assertEquals('Sov',        DMT_OppFeatureGenCons_Calc.transformSegmentToCounterpart('00001'), 'Segment 00001 should map to Sov');
        System.assertEquals('Pub Inst',   DMT_OppFeatureGenCons_Calc.transformSegmentToCounterpart('00002'), 'Segment 00002 should map to Pub Inst');
        System.assertEquals('SME',        DMT_OppFeatureGenCons_Calc.transformSegmentToCounterpart('00003'), 'Segment 00003 should map to SME');
        System.assertEquals('Corporates', DMT_OppFeatureGenCons_Calc.transformSegmentToCounterpart('00005'), 'Segment 00005 should map to Corporates');
        System.assertEquals('Fin Inst-B', DMT_OppFeatureGenCons_Calc.transformSegmentToCounterpart('00006'), 'Segment 00006 should map to Fin Inst-B');

        String expected = null;
        System.assertEquals(expected, DMT_OppFeatureGenCons_Calc.transformSegmentToCounterpart('00004'), 'Segment 00004 (Other) should return null');
        System.assertEquals(expected, DMT_OppFeatureGenCons_Calc.transformSegmentToCounterpart('99999'), 'Unknown segment should return null');
        System.assertEquals(expected, DMT_OppFeatureGenCons_Calc.transformSegmentToCounterpart(null),   'Null segment should return null');

        Test.stopTest();
    }

}