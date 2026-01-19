@isTest
private class DES_OpportunityTriggerHandlerTest{

    /*
     *
     * @description Clase auxiliar tests
     **/
    private final static DES_UtilTestClass UTIL_TEST_CLASS = new DES_UtilTestClass();

    /*
     *
     * @description Literal email user para test
     **/
    private final static String USER_TEST = 'user@test.test';

    /*
    *
    *
    */
    private final static String ACCOUNTSSTR = 'accounts';

    /*
    *
    *
    */
    private final static String OPPSSTR = 'opps';

    /*
    *
    *
    */
    private final static String OLLISSTR = 'ollis';
    /*
     *
     * @description Literal recordtype grupos
     **/
    private final static String GROUP_RT = 'Group';

    /*
     *
     * @description Literal subsidiaria
     **/
    private final static String SUBSIDIARY = 'Subsidiary';

    /*
     *
     * @description Lista con recordtypes para grupo y subsidiaria
     **/
    private final static List<Recordtype> RECORDTYPE = [SELECT id, DeveloperName FROM Recordtype WHERE DeveloperName = :GROUP_RT OR DeveloperName = :SUBSIDIARY];

    /*
     *
     * @description Id cuenta grupo
     **/
    private static Id accountGroupRT;

    /*
     *
     * @description Id cuenta filial
     **/
    private static Id accountFilialRT;

    public static void DES_OpportunityTriggerHandlerTest() {
        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == GROUP_RT) {
                accountGroupRT = i.Id;
            } else if(i.DeveloperName == SUBSIDIARY) {
                accountFilialRT = i.Id;
            }
        }
        List<Account> accList;
        accList = new list<Account>();
        Account accGroup;
        accGroup = UTIL_TEST_CLASS.createClient();
        accGroup.RecordTypeId = accountGroupRT;
        accGroup.DES_Structure_Type__c = GROUP_RT;
        accGroup.DES_BBVA_Segmentation__c = 'C';
        accList.add(accGroup);
        Account accFilial;
        accFilial = UTIL_TEST_CLASS.createClient();
        accFilial.Des_Main_Parent__c = accGroup.Id;
        accFilial.RecordTypeId = accountFilialRT;
        accList.add(accFilial);
        Account accFilial2;
        accFilial2 = UTIL_TEST_CLASS.createClient();
        accFilial2.Des_Main_Parent__c = accFilial.Id;
        accFilial2.RecordTypeId = accountFilialRT;
        accList.add(accFilial2);
        insert accList;

        final Product2 prod1 = UTIL_TEST_CLASS.createProduct(Label.DES_Mergers_Acquisitions);
        insert prod1;
        final PricebookEntry pBookEntry1 = UTIL_TEST_CLASS.createPricebookEntry(prod1);
        insert pBookEntry1;

        List<Opportunity> oppList;
        oppList = new list<Opportunity>();
        Opportunity opp;
        opp = UTIL_TEST_CLASS.createOpportunity(accFilial2);
        opp.DES_Booking_Geography__c = 'BE';
        opp.DES_Countries__c = 'BE';
        opp.CurrencyIsoCode = 'EUR';
        oppList.add(opp);
        final Opportunity opp2 = UTIL_TEST_CLASS.createOpportunity(accGroup);
        oppList.add(opp2);
        Opportunity opp3;
        opp3 = UTIL_TEST_CLASS.createOpportunity(accFilial);
        opp3.DES_Booking_Geography__c = 'BE';
        opp3.DES_Countries__c = 'BE';
        opp3.CurrencyIsoCode = 'EUR';
        opp3.StageName = Label.DES_Draft;
        oppList.add(opp3);
        insert oppList;

        test.startTest();
        List<OpportunityLineItem> oppLineItemList;
        oppLineItemList = new List<OpportunityLineItem>();
        final OpportunityLineItem oppLineItem = UTIL_TEST_CLASS.createOppLineItem(opp, prod1, pBookEntry1);
        oppLineItemList.add(oppLineItem);
        OpportunityLineItem oppLineItem2;
        oppLineItem2 = UTIL_TEST_CLASS.createOppLineItem(opp3, prod1, pBookEntry1);
        oppLineItem2.DES_Booking_System__c = 'booking system';
        oppLineItem2.DES_Booking_ID__c = 'booking id';
        oppLineItemList.add(oppLineItem2);
        insert oppLineItemList;
        oppList.get(0).StageName = Label.DES_Proposal;
        update oppList.get(0);
        oppList.get(2).StageName = Label.DES_Proposal;
        //oppList.get(2).participant_campaign_id__c = accCampaign.Id;
        System.debug('oppList.get(2)');
        try{
            update oppList.get(2);
        } catch(Exception e) {}
        test.stopTest();
    }

    @isTest(SeeAllData=true) 
    public static void updateOpps() {
        test.startTest();

        

        List <User> usersToInsert;
        usersToInsert = new List <User>();
        final String profileTest = UTIL_TEST_CLASS.createProfile();
        final User user1 = UTIL_TEST_CLASS.createUser(profileTest, USER_TEST);
        usersToInsert.add(user1);
        insert usersToInsert;

        System.runAs(user1){
            final Account accFilial = UTIL_TEST_CLASS.createClient();
            insert accFilial;
        

        final Product2 prod1 = UTIL_TEST_CLASS.createProduct(Label.DES_Mergers_Acquisitions);
        insert prod1;
        final PricebookEntry pBookEntry1 = UTIL_TEST_CLASS.createPricebookEntry(prod1);
        insert pBookEntry1;

        Opportunity opp3;
        opp3 = UTIL_TEST_CLASS.createOpportunity(accFilial);
        opp3.DES_Booking_Geography__c = 'BE';
        opp3.DES_Countries__c = 'BE';
        opp3.CurrencyIsoCode = 'EUR';
        opp3.StageName = Label.DES_Ready_to_close;
        //opp3.participant_campaign_id__c = accCampaign.Id;
        insert opp3;

        List<OpportunityLineItem> oppLineItemList;
        oppLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItem oppLineItem2;
        oppLineItem2 = UTIL_TEST_CLASS.createOppLineItem(opp3, prod1, pBookEntry1);
        oppLineItem2.DES_Booking_System__c = 'booking system';
        oppLineItem2.DES_Booking_ID__c = 'booking id';
        UTIL_TEST_CLASS.updateOppLineItem(oppLineItem2, user1);
        oppLineItemList.add(oppLineItem2);
        insert oppLineItem2;
        try{
            opp3.StageName = Label.DES_Closed_Won;
            update opp3;
        } catch (Exception e) {  System.debug('excepcion');  }

        final Opportunity oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp3.Id LIMIT 1];
        system.assertEquals(oppAssert.StageName, Label.DES_Ready_to_close);
    }
        test.stopTest();
    }

    @isTest
    public static void oppConfidentialTest() {
        test.startTest();
        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == GROUP_RT) {
                accountGroupRT = i.Id;
            } else if(i.DeveloperName == SUBSIDIARY) {
                accountFilialRT = i.Id;
            }
        }
        List <User> usersToInsert;
        usersToInsert = new List <User>();
        final String profileTest = UTIL_TEST_CLASS.createProfile();
        final User user1 = UTIL_TEST_CLASS.createUser(profileTest, USER_TEST);
        usersToInsert.add(user1);
        insert usersToInsert;

        List<Account> accList;
        accList = new list<Account>();
        Account accGroup;
        accGroup = UTIL_TEST_CLASS.createClient();
        accGroup.RecordTypeId = accountGroupRT;
        accGroup.DES_Structure_Type__c = GROUP_RT;
        accGroup.DES_BBVA_Segmentation__c = 'C';
        accList.add(accGroup);
        Account accFilial;
        accFilial = UTIL_TEST_CLASS.createClient();
        accFilial.Des_Main_Parent__c = accGroup.Id;
        accFilial.RecordTypeId = accountFilialRT;
        accList.add(accFilial);
        Account accFilial2;
        accFilial2 = UTIL_TEST_CLASS.createClient();
        accFilial2.Des_Main_Parent__c = accFilial.Id;
        accFilial2.RecordTypeId = accountFilialRT;
        accList.add(accFilial2);
        insert accList;

        List<Opportunity> oppConfidential;
        oppConfidential = new List<Opportunity>();
        Opportunity oppConf1;
        oppConf1 = UTIL_TEST_CLASS.createOpportunity(accGroup);
        oppConf1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Draft_Opportunity).getRecordTypeId();
        oppConf1.disclosure_info_type__c = Label.DES_OP_CONFIDENTIAL;
        oppConf1.CurrencyIsoCode = 'EUR';
        oppConfidential.add(oppConf1);
        Opportunity oppConf2;
        oppConf2 = UTIL_TEST_CLASS.createOpportunity(accGroup);
        oppConf2.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Opportunity).getRecordTypeId();
        oppConf2.disclosure_info_type__c = Label.DES_OP_CONFIDENTIAL;
        oppConf2.CurrencyIsoCode = 'EUR';
        oppConfidential.add(oppConf2);
        Opportunity oppConf3;
        oppConf3 = UTIL_TEST_CLASS.createOpportunity(accGroup);
        oppConf3.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId();
        oppConf3.StageName = Label.DES_OPP_stage_draft;
        oppConf3.CurrencyIsoCode = 'EUR';
        oppConfidential.add(oppConf3);
        Opportunity oppConf4;
        oppConf4 = UTIL_TEST_CLASS.createOpportunity(accGroup);
        oppConf4.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId();
        oppConf4.StageName = Label.DES_Proposal;
        oppConf4.CurrencyIsoCode = 'EUR';
        oppConfidential.add(oppConf4);
        Opportunity oppConf5;
        oppConf5 = UTIL_TEST_CLASS.createOpportunity(accGroup);
        oppConf5.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_SalesGM_Confidential_Opp).getRecordTypeId();
        oppConf5.CurrencyIsoCode = 'EUR';
        oppConfidential.add(oppConf5);


        System.debug('oppConfidential: ' + oppConfidential);
        insert oppConfidential;



        final Opportunity oppAssert = [SELECT Id, RecordTypeId FROM Opportunity WHERE Id = :oppConf1.Id LIMIT 1];
        system.assertEquals(oppAssert.RecordTypeId, Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId());
        test.stopTest();
    }


    @isTest
    public static void needTemplate() {

        final Account accFilial = UTIL_TEST_CLASS.createClient();
        insert accFilial;

        List<Product2> productList;
        productList = new list<product2>();
        final Product2 prod1 = UTIL_TEST_CLASS.createProduct(Label.DES_Project_Finance_Lending);
        productList.add(prod1);
        final Product2 prod2 = UTIL_TEST_CLASS.createProduct(LABEL.DES_Working_Capital);
        productList.add(prod2);
        insert productList;

        List<PricebookEntry> pBookList;
        pBookList = new list<PricebookEntry>();
        final PricebookEntry pBookEntry = UTIL_TEST_CLASS.createPricebookEntry(prod1);
        pBookList.add(pBookEntry);
        final PricebookEntry pBookEntry2 = UTIL_TEST_CLASS.createPricebookEntry(prod2);
        pBookList.add(pBookEntry2);
        insert pBookList;

        Opportunity opp1;
        opp1 = UTIL_TEST_CLASS.createOpportunity(accFilial);
        opp1.DES_Booking_Geography__c = 'NY';
        opp1.DES_Countries__c = 'BE';
        opp1.CurrencyIsoCode = 'EUR';
        opp1.StageName = Label.DES_Proposal;
        insert opp1;

        Opportunity opp2;
        opp2 = UTIL_TEST_CLASS.createOpportunity(accFilial);
        opp2.DES_Booking_Geography__c = 'NY';
        opp2.DES_Countries__c = 'BE';
        opp2.CurrencyIsoCode = 'EUR';
        opp2.StageName = Label.DES_Proposal;
        insert opp2;

        test.startTest();

        List<OpportunityLineItem> olliList;
        olliList = new list<OpportunityLineItem>();

        OpportunityLineItem oppLineItem;
        oppLineItem = UTIL_TEST_CLASS.createOppLineItem(opp2, prod1, pBookEntry);
        oppLineItem.DES_All_In__c = null;
        oppLineItem.solution_name_path_desc__c = 'Asset Finance';
        oppLineItem.DES_Origination_Geography__c = 'Mexico';
        oppLineItem.origin_country_name__c = 'N.A.';
        oppLineItem.country_name__c = 'Belgium';
        oppLineItem.participant_name__c = 'Borrower';
        oppLineItem.entity_role_type__c = 'Bookrunner';
        oppLineItem.oppy_asset_level_1_name__c = 'Infrastructure';
        oppLineItem.oppy_asset_level_2_name__c = 'Real Estate';
        oppLineItem.deal_total_amount__c = 555555;
        oppLineItem.opportunity_tenor_years_number__c = 3;
        oppLineItem.bbva_prtcp_tranche_amount__c = 25000000;
        oppLineItem.syndicated_loan_drawn_amount__c = 999999;
        oppLineItem.pre_gross_margin_next_12m_per__c = 5;
        oppLineItem.opening_fee_per__c = 4;
        oppLineItem.DES_RaR_Expected_Before_Cost_Funding__c = null;
        oppLineItem.DES_All_In__c = 50;
        oppLineItem.DES_RaR_Expected_Post_Cost_of_Funding__c = 10;
        oppLineItem.pre_oppy_revenue_next_12m_amount__c = 111111;
        oppLineItem.product_scope_type__c = 'CIB';

        olliList.add(oppLineItem);

        OpportunityLineItem oppLineItem2;
        oppLineItem2 = UTIL_TEST_CLASS.createOppLineItem(opp1, prod2, pBookEntry2);
        oppLineItem2.DES_All_In__c = null;
        oppLineItem2.product_scope_type__c = 'CIB';
        oppLineItem2.syndicated_loan_drawn_amount__c = 25000000;
        oppLineItem2.solution_name_path_desc__c = 'Sub Product';
        oppLineItem2.pre_oppy_revenue_next_12m_amount__c = 12345;
        olliList.add(oppLineItem2);

        insert olliList;

        List<DES_Template__c> lTemp;
        lTemp = new List<DES_Template__c>();

        DES_Template__c temp;
        temp = new DES_Template__c();
        temp.opportunity_id__c = opp2.id;
        temp.Opportunity_Product_Id__c = prod1.id;
        temp.Template_approved_type__c = false;
        temp.YTD_RORC_per_CDD__c = 1;
        temp.Past_FY_RORC_per_CDD__c = 2;
        temp.Standalone_CDD_RaR_number__c = 1;
        temp.Standalone_CDD_RORC_number__c = 1;

        DES_Template__c temp2;
        temp2 = new DES_Template__c();
        temp2.opportunity_id__c = opp1.id;
        temp2.Opportunity_Product_Id__c = prod2.id;
        temp2.Template_approved_type__c = false;
        temp2.YTD_RORC_per_CDD__c = 1;
        temp2.Past_FY_RORC_per_CDD__c = 2;
        temp2.Standalone_CDD_RaR_number__c = 1;
        temp2.Standalone_CDD_RORC_number__c = 1;

        lTemp.add(temp);
        lTemp.add(temp2);

        insert lTemp;


        final List <Template_Configurations__c> listConfig = new List <Template_Configurations__c>();
        Template_Configurations__c tmplconfig1;
        tmplconfig1 = new Template_Configurations__c();
        tmplconfig1.Product_id__c = prod1.id;
        tmplconfig1.Template_type__c = 'PF';
        tmplconfig1.Amount_num__c = 0;
        listconfig.add(tmplconfig1);
        Template_Configurations__c tmplconfig2;
        tmplconfig2 = new Template_Configurations__c();
        tmplconfig2.Product_id__c = prod2.id;
        tmplconfig2.Template_type__c = 'GTB';
        tmplconfig2.Amount_num__c = 25000000;
        listconfig.add(tmplconfig2);
        insert listConfig;

        try{
            opp1.StageName = LABEL.DES_Approvals;
            update opp1;
        }
        catch(Exception e) {
            try{
                opp2.StageName = LABEL.DES_Approvals;
                update opp2;
            }
            catch(Exception e2) {
                System.debug(e.getMessage());
                final Boolean contains = e.getMessage().contains(LABEL.DES_Need_Template);
                final Boolean contains2 = e2.getMessage().contains(LABEL.DES_Need_Template);
                System.assertEquals(true, contains);
                System.assertEquals(true, contains2);
            }
        }
        test.stopTest();
    }

    /**
    *
    *
    * @description  Test para validar opp confidencial con producto que impida compartir con equipo de cobertura
    */
     @isTest
    public static void confidentialExcProducts() {

        //test.startTest();
        List <User> usersToInsert;
        usersToInsert = new List <User>();
        final String profileTest = UTIL_TEST_CLASS.createProfile();
        final User user1 = UTIL_TEST_CLASS.createUser(profileTest, USER_TEST);
        usersToInsert.add(user1);
        insert usersToInsert;

        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == GROUP_RT) {
                accountGroupRT = i.Id;
            }
        }

        list<Account> accList;
        accList = new list<Account>();
        Account accGroup;
        accGroup = UTIL_TEST_CLASS.createClient();
        accGroup.RecordTypeId = accountGroupRT;
        accGroup.DES_Structure_Type__c = GROUP_RT;
        accGroup.DES_BBVA_Segmentation__c = 'C';
        accList.add(accGroup);
        insert accList;

        final List<Opportunity> oppConfidential = new List<Opportunity>();

        test.startTest();
        //Confidencial y producto m a
        final Opportunity oppConf6 = UTIL_TEST_CLASS.createOpportunity(accGroup);
        oppConf6.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId();
        oppConf6.CurrencyIsoCode = 'EUR';
       	oppConf6.disclosure_info_type__c = Label.DES_OP_CONFIDENTIAL;
        oppConfidential.add(oppConf6);
        insert oppConfidential;
        final OpportunityTeamMember oppTeamMemberTest = UTIL_TEST_CLASS.oppTeamMember(oppConf6,user1);
        oppTeamMemberTest.TeamMemberRole = 'Product Specialist';
        system.debug('>>>>> oppTeamMemberTest : ' + oppTeamMemberTest);
        insert oppTeamMemberTest;

        final Product2 prod1 = UTIL_TEST_CLASS.createProduct(Label.DES_Mergers_Acquisitions);
        insert prod1;
        final PricebookEntry pricebook1 = UTIL_TEST_CLASS.createPricebookEntry(prod1);
        pricebook1.Product2 = prod1;
        insert pricebook1;
        final OpportunityLineItem oppLineItem2 = UTIL_TEST_CLASS.createOppLineItem(oppConf6, prod1, pricebook1);
        oppLineItem2.DES_Booking_System__c = 'booking system';
        oppLineItem2.DES_Booking_ID__c = 'booking id';
        oppLineItem2.oppy_target_country_name__c = 'BE';
        oppLineItem2.oppy_target_industry_name__c = 'Construction & Infra';
        UTIL_TEST_CLASS.updateOppLineItem(oppLineItem2, user1);
        oppLineItem2.PricebookEntry = pricebook1;
        insert oppLineItem2;
     	system.debug('opportunity product name ' + oppLineItem2.OpportunityId);
        test.stopTest();
        final Opportunity oppAssert = [SELECT Id, RecordTypeId FROM Opportunity WHERE Id = :oppConf6.Id LIMIT 1];
        system.assertEquals(oppAssert.RecordTypeId, Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(Label.DES_RT_ACC_Confidential_Opportunity).getRecordTypeId(), 'Test');
    }



    @isTest(SeeAllData='true') //NOSONAR
    /**
    *
    *
    * @description  Test para validar opp con producto multitranche, cuando no se están usando tranches
    */
    public static void noMultitrancheTestCL() {
        Test.startTest();
        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == GROUP_RT) {
                accountGroupRT = i.Id;
            } else if(i.DeveloperName == SUBSIDIARY) {
                accountFilialRT = i.Id;
            }
        }

        final Product2 prod = UTIL_TEST_CLASS.createProduct(Label.DES_Corporate_Loans);
        insert prod;
        final PricebookEntry pBookEntry = UTIL_TEST_CLASS.createPricebookEntry(prod);
        insert pBookEntry;
        final Map<String,List<SObject>> mapTestData = fillTestData(prod,pBookEntry);

        final List<Account> accList = (List<Account>) mapTestData.get(ACCOUNTSSTR);
        insert accList;

        Opportunity opp;
        opp = (Opportunity) mapTestData.get(OPPSSTR).get(0);
        opp.AccountId = accList.get(2).Id;
        insert opp;

        OpportunityLineItem oppLineItem;
        oppLineItem = (OpportunityLineItem) mapTestData.get(OLLISSTR).get(0);
        oppLineItem.OpportunityId = opp.Id;
        insert oppLineItem;
        opp.StageName = Label.DES_Proposal;
        update opp;
        Test.stopTest();
        opp.StageName = Label.DES_Approvals;
        try {
            update opp;
        } catch(Exception e) {
            oppLineItem.product_scope_type__c = 'BEC';
            update oppLineItem;
            update opp;
        }
        opp.StageName = Label.DES_Ready_to_close;
        update opp;

        System.assertEquals(Label.DES_No,oppLineItem.multi_tranche_type__c,'noMultitrancheTestCL OK');
    }

    @isTest(SeeAllData='true') //NOSONAR
    /**
    *
    *
    * @description  Test para validar opp con producto multitranche, cuando no se están usando tranches
    */
    public static void noMultitrancheTestWC() {
        Test.startTest();
        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == GROUP_RT) {
                accountGroupRT = i.Id;
            } else if(i.DeveloperName == SUBSIDIARY) {
                accountFilialRT = i.Id;
            }
        }

        final Product2 prod = UTIL_TEST_CLASS.createProduct(Label.DES_Working_Capital);
        insert prod;
        final PricebookEntry pBookEntry = UTIL_TEST_CLASS.createPricebookEntry(prod);
        insert pBookEntry;
        final Map<String,List<SObject>> mapTestData = fillTestData(prod,pBookEntry);

        final List<Account> accList = (List<Account>) mapTestData.get(ACCOUNTSSTR);
        insert accList;

        Opportunity opp;
        opp = (Opportunity) mapTestData.get(OPPSSTR).get(0);
        opp.AccountId = accList.get(2).Id;
        insert opp;

        OpportunityLineItem oppLineItem;
        oppLineItem = (OpportunityLineItem) mapTestData.get(OLLISSTR).get(0);
        oppLineItem.OpportunityId = opp.Id;
        insert oppLineItem;
        opp.StageName = Label.DES_Proposal;
        update opp;
        Test.stopTest();
        opp.StageName = Label.DES_Approvals;
        try {
            update opp;
        } catch(Exception e) {
            oppLineItem.product_scope_type__c = 'BEC';
            update oppLineItem;
            update opp;
        }
        opp.StageName = Label.DES_Ready_to_close;
        update opp;

        System.assertEquals(Label.DES_No,oppLineItem.multi_tranche_type__c,'noMultitrancheTestWC OK');
    }

    @isTest  //NOSONAR
    /**
    *
    *
    * @description  Test para validar opp con producto multitranche, cuando no se están usando tranches
    */
    public static void noMultitrancheTestClientResources() {
        Test.startTest();
        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == GROUP_RT) {
                accountGroupRT = i.Id;
            } else if(i.DeveloperName == SUBSIDIARY) {
                accountFilialRT = i.Id;
            }
        }

        final Product2 prod = UTIL_TEST_CLASS.createProduct(Label.DES_Client_Resources);
        insert prod;
        final PricebookEntry pBookEntry = UTIL_TEST_CLASS.createPricebookEntry(prod);
        insert pBookEntry;
        final Map<String,List<SObject>> mapTestData = fillTestData(prod,pBookEntry);

        final List<Account> accList = (List<Account>) mapTestData.get(ACCOUNTSSTR);
        insert accList;

        Opportunity opp;
        opp = (Opportunity) mapTestData.get(OPPSSTR).get(0);
        opp.AccountId = accList.get(2).Id;
        insert opp;

        OpportunityLineItem oppLineItem;
        oppLineItem = (OpportunityLineItem) mapTestData.get(OLLISSTR).get(0);
        oppLineItem.OpportunityId = opp.Id;
        oppLineItem.solution_name_path_desc__c = 'Accounts';
        insert oppLineItem;

        oppLineItem.solution_name_path_desc__c = 'Puttable deposits';
        update oppLineItem;

        System.assertEquals('Puttable deposits',oppLineItem.solution_name_path_desc__c,'noMultitrancheTestClientResources OK');
        Test.stopTest();
    }

    @isTest  //NOSONAR
    /**
    *
    *
    * @description  Test para validar opp con producto multitranche, cuando no se están usando tranches
    */
    public static void noMultitrancheTestTTF() {
        Test.startTest();
        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == GROUP_RT) {
                accountGroupRT = i.Id;
            } else if(i.DeveloperName == SUBSIDIARY) {
                accountFilialRT = i.Id;
            }
        }

        final Product2 prod = UTIL_TEST_CLASS.createProduct(Label.DES_Transaction_Trade_Finance);
        insert prod;
        final PricebookEntry pBookEntry = UTIL_TEST_CLASS.createPricebookEntry(prod);
        insert pBookEntry;
        final Map<String,List<SObject>> mapTestData = fillTestData(prod,pBookEntry);

        final List<Account> accList = (List<Account>) mapTestData.get(ACCOUNTSSTR);
        insert accList;

        Opportunity opp;
        opp = (Opportunity) mapTestData.get(OPPSSTR).get(0);
        opp.AccountId = accList.get(2).Id;
        insert opp;

        OpportunityLineItem oppLineItem;
        oppLineItem = (OpportunityLineItem) mapTestData.get(OLLISSTR).get(0);
        oppLineItem.OpportunityId = opp.Id;
        oppLineItem.subproduct_name__c = Label.DES_Prod_Trade_Loans;
        insert oppLineItem;

        oppLineItem.subproduct_name__c = Label.DES_Prod_Guarantees_SBLCs;
        oppLineItem.solution_name_path_desc__c ='Silent Guarantee Issuance & Financing';
        oppLineItem.DES_Risk_Fee_Next_12_Months__c = 250;
        oppLineItem.syndicated_loan_drawn_amount__c = 5000;
        update oppLineItem;

        oppLineItem.subproduct_name__c = Label.DES_Prod_Letter_of_Credit;
        oppLineItem.solution_name_path_desc__c = 'Import LC with Beneficiary Financing';
        update oppLineItem;
        oppLineItem.solution_name_path_desc__c = 'LC Silent Confirmation';
        update oppLineItem;
        oppLineItem.solution_name_path_desc__c = null; //NOSONAR
        update oppLineItem;

        System.assertEquals(Label.DES_Prod_Letter_of_Credit,oppLineItem.subproduct_name__c,'noMultitrancheTestTTF OK');
        Test.stopTest();
    }

    @isTest  //NOSONAR
    /**
    *
    *
    * @description  Test para validar opp con producto multitranche, cuando no se están usando tranches
    */
    public static void noMultitrancheTestCM() {
        Test.startTest();
        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == GROUP_RT) {
                accountGroupRT = i.Id;
            } else if(i.DeveloperName == SUBSIDIARY) {
                accountFilialRT = i.Id;
            }
        }

        final Product2 prod = UTIL_TEST_CLASS.createProduct(Label.DES_Cash_Management);
        insert prod;
        final PricebookEntry pBookEntry = UTIL_TEST_CLASS.createPricebookEntry(prod);
        insert pBookEntry;
        final Map<String,List<SObject>> mapTestData = fillTestData(prod,pBookEntry);

        final List<Account> accList = (List<Account>) mapTestData.get(ACCOUNTSSTR);
        insert accList;

        Opportunity opp;
        opp = (Opportunity) mapTestData.get(OPPSSTR).get(0);
        opp.AccountId = accList.get(2).Id;
        insert opp;

        OpportunityLineItem oppLineItem;
        oppLineItem = (OpportunityLineItem) mapTestData.get(OLLISSTR).get(0);
        oppLineItem.OpportunityId = opp.Id;
        oppLineItem.subproduct_name__c = 'Channels';
        oppLineItem.DES_Risk_Fee_Next_12_Months__c = 250;
        oppLineItem.syndicated_loan_drawn_amount__c = 5000;
        insert oppLineItem;

        oppLineItem.subproduct_name__c = 'Payments';
        oppLineItem.unit_price_with_tax_amount__c = 500;
        oppLineItem.opportunity_sold_prdt_number__c = 5000;
        update oppLineItem;

        oppLineItem.unit_price_with_tax_amount__c = null; //NOSONAR
        oppLineItem.opportunity_sold_prdt_number__c = null; //NOSONAR
        oppLineItem.DES_Price_Percent__c = 40;
        oppLineItem.DES_Volume_in_Amounts__c = 5000;
        oppLineItem.DES_Funding_Transfer_Price__c = 40;
        oppLineItem.avg_balance_annual_amount__c = 5000;
        update oppLineItem;

        System.assertEquals('Payments',oppLineItem.subproduct_name__c,'noMultitrancheTestCM OK');
        Test.stopTest();
    }

    @isTest  //NOSONAR
    /**
    *
    *
    * @description  Test para validar opp con producto multitranche, cuando no se están usando tranches
    */
    public static void noMultitrancheTestSimpleProducts() {
        Test.startTest();
        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == GROUP_RT) {
                accountGroupRT = i.Id;
            } else if(i.DeveloperName == SUBSIDIARY) {
                accountFilialRT = i.Id;
            }
        }

        final Product2 prod = UTIL_TEST_CLASS.createProduct(Label.DES_Leverage_Buyout_LBOs);
        final Product2 prod2 = UTIL_TEST_CLASS.createProduct(Label.DES_Project_Finance_Advisory);
        final Product2 prod3 = UTIL_TEST_CLASS.createProduct(Label.DES_Structure_Trade_Finance);
        final List<Product2> listProds = new List<Product2>{prod,prod2,prod3};
        insert listProds;
        final PricebookEntry pBookEntry = UTIL_TEST_CLASS.createPricebookEntry(prod);
        final PricebookEntry pBookEntry2 = UTIL_TEST_CLASS.createPricebookEntry(prod2);
        final PricebookEntry pBookEntry3 = UTIL_TEST_CLASS.createPricebookEntry(prod3);
        final List<PricebookEntry> listPriceBooks = new List<PricebookEntry>{pBookEntry,pBookEntry2,pBookEntry3};
        insert listPriceBooks;
        final Map<String,List<SObject>> mapTestData = fillTestData(prod,pBookEntry);
        final Map<String,List<SObject>> mapTestData2 = fillTestData(prod2,pBookEntry2);
        final Map<String,List<SObject>> mapTestData3 = fillTestData(prod3,pBookEntry3);

        final List<Account> accList = (List<Account>) mapTestData.get(ACCOUNTSSTR);
        final List<Account> accList2 = (List<Account>) mapTestData2.get(ACCOUNTSSTR);
        final List<Account> accList3 = (List<Account>) mapTestData3.get(ACCOUNTSSTR);
        insert accList;
        insert accList2;
        insert accList3;

        Opportunity opp;
        opp = (Opportunity) mapTestData.get(OPPSSTR).get(0);
        opp.AccountId = accList.get(2).Id;
        Opportunity opp2;
        opp2 = (Opportunity) mapTestData2.get(OPPSSTR).get(0);
        opp2.AccountId = accList2.get(2).Id;
        Opportunity opp3;
        opp3 = (Opportunity) mapTestData3.get(OPPSSTR).get(0);
        opp3.AccountId = accList3.get(2).Id;
        final List<Opportunity> listOpps = new List<Opportunity>{opp,opp2,opp3};
        insert listOpps;

        OpportunityLineItem oppLineItem;
        oppLineItem = (OpportunityLineItem) mapTestData.get(OLLISSTR).get(0);
        oppLineItem.OpportunityId = opp.Id;
        OpportunityLineItem oppLineItem2;
        oppLineItem2 = (OpportunityLineItem) mapTestData2.get(OLLISSTR).get(0);
        oppLineItem2.OpportunityId = opp2.Id;
        OpportunityLineItem oppLineItem3;
        oppLineItem3 = (OpportunityLineItem) mapTestData3.get(OLLISSTR).get(0);
        oppLineItem3.OpportunityId = opp3.Id;
        final List<OpportunityLineItem> listOllis = new List<OpportunityLineItem>{oppLineItem,oppLineItem2,oppLineItem3};
        insert listOllis;


        System.assertEquals(3,listOllis.size(),'noMultitrancheTestSimpleProducts OK');
        Test.stopTest();
    }

    @isTest  //NOSONAR
    /**
    *
    *
    * @description  Test para validar opp con producto multitranche, cuando no se están usando tranches
    */
    public static void switchMultitrancheDCM() {
        Test.startTest();
        for(Recordtype i : RECORDTYPE) {
            if(i.DeveloperName == GROUP_RT) {
                accountGroupRT = i.Id;
            } else if(i.DeveloperName == SUBSIDIARY) {
                accountFilialRT = i.Id;
            }
        }

        final Product2 prod = UTIL_TEST_CLASS.createProduct(Label.DES_Debt_Capital_Markets);
        insert prod;
        final PricebookEntry pBookEntry = UTIL_TEST_CLASS.createPricebookEntry(prod);
        insert pBookEntry;
        final Map<String,List<SObject>> mapTestData = fillTestData(prod,pBookEntry);

        final List<Account> accList = (List<Account>) mapTestData.get(ACCOUNTSSTR);
        insert accList;

        Opportunity opp;
        opp = (Opportunity) mapTestData.get(OPPSSTR).get(0);
        opp.AccountId = accList.get(2).Id;
        insert opp;

        OpportunityLineItem oppLineItem;
        oppLineItem = (OpportunityLineItem) mapTestData.get(OLLISSTR).get(0);
        oppLineItem.OpportunityId = opp.Id;
        insert oppLineItem;
        oppLineItem.multi_tranche_type__c = Label.DES_YES;
        update oppLineItem;
        oppLineItem.multi_tranche_type__c = Label.DES_No;
        update oppLineItem;

        System.assertEquals(Label.DES_No,oppLineItem.multi_tranche_type__c,'noMultitrancheTestWC OK');
    }

    /**
    *
    *
    * @description  Función auxiliar para rellenar datos de test
    */
    private static Map<String,List<SObject>> fillTestData(Product2 prod, PricebookEntry pBookEntry) {
        List<Account> listAccounts;
        listAccounts = new List<Account>();

        Account accGroup;
        accGroup = UTIL_TEST_CLASS.createClient();
        accGroup.RecordTypeId = accountGroupRT;
        accGroup.DES_Structure_Type__c = GROUP_RT;
        accGroup.DES_BBVA_Segmentation__c = 'C';
        listAccounts.add(accGroup);
        Account accFilial;
        accFilial = UTIL_TEST_CLASS.createClient();
        accFilial.Des_Main_Parent__c = accGroup.Id;
        accFilial.RecordTypeId = accountFilialRT;
        listAccounts.add(accFilial);
        Account accFilial2;
        accFilial2 = UTIL_TEST_CLASS.createClient();
        accFilial2.Des_Main_Parent__c = accFilial.Id;
        accFilial2.RecordTypeId = accountFilialRT;
        listAccounts.add(accFilial2);

        Opportunity opp;
        opp = UTIL_TEST_CLASS.createOpportunity(accFilial2);
        opp.DES_Booking_Geography__c = 'BE';
        opp.DES_Countries__c = 'BE';
        opp.CurrencyIsoCode = 'EUR';
        opp.DES_Booking_Geography__c = 'BE';
        opp.DES_Countries__c = 'BE';
        opp.CurrencyIsoCode = 'EUR';
        opp.StageName = Label.DES_Draft;
        final List<Opportunity> listOpps = new List<Opportunity>{opp};

        OpportunityLineItem oppLineItem;
        oppLineItem = UTIL_TEST_CLASS.createOppLineItem(opp, prod, pBookEntry);
        if(prod.Name == Label.DES_Corporate_Loans) {
            oppLineItem.opening_fee_per__c = 25;
            oppLineItem.multi_tranche_type__c = Label.DES_No;
            oppLineItem.customer_cib_ind_type__c = Label.DES_YES;
            oppLineItem.opportunity_tenor_years_number__c = 5;
            oppLineItem.pre_gross_margin_next_12m_per__c = 25;
            oppLineItem.deal_total_amount__c = 5000;
            oppLineItem.bbva_prtcp_tranche_amount__c = 3000;
            oppLineItem.multi_tranche_type__c = Label.DES_No;
            oppLineItem.entity_role_type__c = 'Agent';
            oppLineItem.origin_country_name__c = 'USA';
            oppLineItem.product_scope_type__c = 'BEC';
            oppLineItem.operation_underwriting_per__c = 25;
            oppLineItem.underwriting_amount__c = 250;
            oppLineItem.syndicated_loan_drawn_amount__c = 1500;
        } else if(prod.Name == Label.DES_Working_Capital) {
            oppLineItem.opening_fee_per__c = 25;
            oppLineItem.multi_tranche_type__c = Label.DES_No;
            oppLineItem.syndicated_loan_drawn_amount__c = 1500;
            oppLineItem.solution_name_path_desc__c = 'Bilateral Loans';
        } else if(prod.Name == Label.DES_Debt_Capital_Markets) {
            oppLineItem.multi_tranche_type__c = Label.DES_No;
        }
        final List<OpportunityLineItem> listOllis = new List<OpportunityLineItem>{oppLineItem};

        Map<String,List<SObject>> mapTestData;
        mapTestData = new Map<String,List<SObject>>();
        mapTestData.put(ACCOUNTSSTR,listAccounts);
        mapTestData.put(OPPSSTR,listOpps);
        mapTestData.put(OLLISSTR,listOllis);

        return mapTestData;
    }

}