/***********************************************************************
Name:           DES_OpportunityTriggerTest3
Description:    Clase de testeo del trigger de Oportunidades
                    Los test de la clase DES_OpportunityTriggerHandler se dividen en 3 clases de test
                    porque daba error de limite de tiempo en Salesforce:
                        DES_OpportunityTriggerTest
                        DES_OpportunityTriggerTest2
                        DES_OpportunityTriggerTest3
Version        Date            Author            Summary of changes
--------------------------------------------------------------------------
*************************************************************************/
@isTest
public class DES_OpportunityTriggerTest3 {

	/*
	* testTrigger1 method
	*/
    @isTest
    static void testTrigger1() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
        system.runAs(userTest) {
            final List<Account> lAcc = new List<Account>();
            final Account acc = testClass.createClient();
            final Account ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            lAcc.add(acc);
            lAcc.add(ac2);
            insert lAcc;
            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;
            final list<Product2> productList = new list<product2>();
            final Product2 prod9 = testClass.createProduct(LABEL.DES_Rates);
            productList.add(prod9);
            final Product2 prod10 = testClass.createProduct(LABEL.DES_Equity);
            productList.add(prod10);
            final Product2 prod11 = testClass.createProduct(LABEL.DES_FX);
            productList.add(prod11);
            final Product2 prod12 = testClass.createProduct(LABEL.DES_Credit);
            productList.add(prod12);
            insert productList;
            final list<PricebookEntry> pEntryList = new list<PricebookEntry>();
            final PricebookEntry pEntryTest9 = testClass.createPricebookEntry(prod9);
            pEntryList.add(pEntryTest9);
            final PricebookEntry pEntryTest10 = testClass.createPricebookEntry(prod10);
            pEntryList.add(pEntryTest10);
            final PricebookEntry pEntryTest11 = testClass.createPricebookEntry(prod11);
            pEntryList.add(pEntryTest11);
            final PricebookEntry pEntryTest12 = testClass.createPricebookEntry(prod12);
            pEntryList.add(pEntryTest12);
            insert pEntryList;
            final list<Opportunity> opportunityList = new list<Opportunity>();
            final Opportunity opp9 = testClass.createOpportunity(acc);
            opp9.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp9);
            final Opportunity opp10 = testClass.createOpportunity(acc);
            opp10.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp10);
            final Opportunity opp11 = testClass.createOpportunity(acc);
            opp11.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp11);
            final Opportunity opp12 = testClass.createOpportunity(acc);
            opp12.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp12);
            insert opportunityList;
            final list<OpportunityLineItem> opportunityLineItemList = new list<OpportunityLineItem>();
            OpportunityLineItem oppLineItem9 = testClass.createOppLineItem(opp9, prod9, pEntryTest9);
            oppLineItem9 = testClass.updateOppLineItem(oppLineItem9, userTest);
            oppLineItem9.solution_name_path_desc__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem9);
            OpportunityLineItem oppLineItem10 = testClass.createOppLineItem(opp10, prod10, pEntryTest10);
            oppLineItem10 = testClass.updateOppLineItem(oppLineItem10, userTest);
            oppLineItem10.pre_oppy_revenue_next_12m_amount__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem10);
            OpportunityLineItem oppLineItem11 = testClass.createOppLineItem(opp11, prod11, pEntryTest11);
            oppLineItem11 = testClass.updateOppLineItem(oppLineItem11, userTest);
            oppLineItem11.solution_name_path_desc__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem11);
            OpportunityLineItem oppLineItem12 = testClass.createOppLineItem(opp12, prod12, pEntryTest12);
            oppLineItem12 = testClass.updateOppLineItem(oppLineItem12, userTest);
            oppLineItem12.pre_oppy_revenue_next_12m_amount__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem12);
            Test.StartTest();
                insert opportunityLineItemList;
                Opportunity oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
                oppUpd.AccountId = ac2.Id;
                update oppUpd;
            	System.assertEquals(oppUpd.AccountId, ac2.Id, 'Error');
            Test.StopTest();
        }
    }
    
    /*
	* testTrigger1 method
	*/
    @isTest
    static void testTrigger4() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
        system.runAs(userTest) {
            final List<Account> lAcc = new List<Account>();
            final Account acc = testClass.createClient();
            final Account ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            lAcc.add(acc);
            lAcc.add(ac2);
            insert lAcc;
            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;
            final list<Product2> productList = new list<product2>();
            final Product2 prod13 = testClass.createProduct(LABEL.DES_Debt_Capital_Markets);
            productList.add(prod13);
            final Product2 prod14 = testClass.createProduct(LABEL.DES_Equity_Capital_Markets);
            productList.add(prod14);
            final Product2 prod15 = testClass.createProduct(LABEL.DES_Mergers_Acquisitions);
            productList.add(prod15);
            final Product2 prod16 = testClass.createProduct(LABEL.DES_Structure_Trade_Finance);
            productList.add(prod16);
            insert productList;
            final list<PricebookEntry> pEntryList = new list<PricebookEntry>();
            final PricebookEntry pEntryTest13 = testClass.createPricebookEntry(prod13);
            pEntryList.add(pEntryTest13);
            final PricebookEntry pEntryTest14 = testClass.createPricebookEntry(prod14);
            pEntryList.add(pEntryTest14);
            final PricebookEntry pEntryTest15 = testClass.createPricebookEntry(prod15);
            pEntryList.add(pEntryTest15);
            final PricebookEntry pEntryTest16 = testClass.createPricebookEntry(prod16);
            pEntryList.add(pEntryTest16);
            insert pEntryList;
            final list<Opportunity> opportunityList = new list<Opportunity>();
            final Opportunity opp13 = testClass.createOpportunity(acc);
            opp13.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp13);
            final Opportunity opp14 = testClass.createOpportunity(acc);
            opp14.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp14);
            final Opportunity opp15 = testClass.createOpportunity(acc);
            opp15.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp15);
            final Opportunity opp16 = testClass.createOpportunity(acc);
            opp16.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp16);
            insert opportunityList;
            final list<OpportunityLineItem> opportunityLineItemList = new list<OpportunityLineItem>();
            OpportunityLineItem oppLineItem13 = testClass.createOppLineItem(opp13, prod13, pEntryTest13);
            oppLineItem13 = testClass.updateOppLineItem(oppLineItem13, userTest);
            oppLineItem13.entity_role_type__c = null; //NOSONAR
            oppLineItem13.classification_cib_banker_type__c = null; //NOSONAR
            oppLineItem13.customer_cib_ind_type__c = 'No';
            oppLineItem13.regional_area_name__c = null; //NOSONAR
            oppLineItem13.classification_cib_banker_type__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem13);
            OpportunityLineItem oppLineItem14 = testClass.createOppLineItem(opp14, prod14, pEntryTest14);
            oppLineItem14 = testClass.updateOppLineItem(oppLineItem14, userTest);
            oppLineItem14.customer_cib_ind_type__c = 'No';
            oppLineItem14.regional_area_name__c = null; //NOSONAR
            oppLineItem14.classification_cib_banker_type__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem14);
            OpportunityLineItem oppLineItem15 = testClass.createOppLineItem(opp15, prod15, pEntryTest15);
            oppLineItem15 = testClass.updateOppLineItem(oppLineItem15, userTest);
            oppLineItem15.classification_cib_banker_type__c = null; //NOSONAR
            oppLineItem15.customer_cib_ind_type__c = 'No';
            oppLineItem15.regional_area_name__c = null; //NOSONAR
            oppLineItem15.classification_cib_banker_type__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem15);
            OpportunityLineItem oppLineItem16 = testClass.createOppLineItem(opp16, prod16, pEntryTest16);
            oppLineItem16 = testClass.updateOppLineItem(oppLineItem16, userTest);
            opportunityLineItemList.add(oppLineItem16);
            Test.StartTest();
                insert opportunityLineItemList;
                Opportunity oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
                oppUpd.AccountId = ac2.Id;
                update oppUpd;
            	System.assertEquals(oppUpd.AccountId, ac2.Id, 'Error');
            Test.StopTest();
        }
    }
    
    /**
    * @author Global Desktop | 1/6/2020
    * @return void
    **/
    @isTest
    static void testTrigger2(){
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
        system.runAs(userTest){
            final List<Account> lAcc = new List<Account>();
            final Account acc = testClass.createClient();
            final Account ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            lAcc.add(acc);
            lAcc.add(ac2);
            insert lAcc;
            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;
            final list<Product2> productList = new list<product2>();
            final Product2 prod13 = testClass.createProduct(LABEL.DES_Debt_Capital_Markets);
            productList.add(prod13);
            final Product2 prod14 = testClass.createProduct(LABEL.DES_Equity_Capital_Markets);
            productList.add(prod14);
            final Product2 prod15 = testClass.createProduct(LABEL.DES_Mergers_Acquisitions);
            productList.add(prod15);
            final Product2 prod16 = testClass.createProduct(LABEL.DES_Structure_Trade_Finance);
            productList.add(prod16);
            insert productList;
            final list<PricebookEntry> pEntryList = new list<PricebookEntry>();
            final PricebookEntry pEntryTest13 = testClass.createPricebookEntry(prod13);
            pEntryList.add(pEntryTest13);
            final PricebookEntry pEntryTest14 = testClass.createPricebookEntry(prod14);
            pEntryList.add(pEntryTest14);
            final PricebookEntry pEntryTest15 = testClass.createPricebookEntry(prod15);
            pEntryList.add(pEntryTest15);
            final PricebookEntry pEntryTest16 = testClass.createPricebookEntry(prod16);
            pEntryList.add(pEntryTest16);
            insert pEntryList;
            final list<Opportunity> opportunityList = new list<Opportunity>();
            final Opportunity opp13 = testClass.createOpportunity(acc);
            opp13.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp13);
            final Opportunity opp14 = testClass.createOpportunity(acc);
            opp14.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp14);
            final Opportunity opp15 = testClass.createOpportunity(acc);
            opp15.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp15);
            final Opportunity opp16 = testClass.createOpportunity(acc);
            opp16.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp16);
            insert opportunityList;
            final list<OpportunityLineItem> opportunityLineItemList = new list<OpportunityLineItem>();
            OpportunityLineItem oppLineItem13 = testClass.createOppLineItem(opp13, prod13, pEntryTest13);
            oppLineItem13 = testClass.updateOppLineItem(oppLineItem13, userTest);
            oppLineItem13.entity_role_type__c = null; //NOSONAR
            oppLineItem13.classification_cib_banker_type__c = null; //NOSONAR
            oppLineItem13.customer_cib_ind_type__c = 'No';
            oppLineItem13.regional_area_name__c = null; //NOSONAR
            oppLineItem13.classification_cib_banker_type__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem13);
            OpportunityLineItem oppLineItem14 = testClass.createOppLineItem(opp14, prod14, pEntryTest14);
            oppLineItem14 = testClass.updateOppLineItem(oppLineItem14, userTest);
            oppLineItem14.customer_cib_ind_type__c = 'No';
            oppLineItem14.regional_area_name__c = null; //NOSONAR
            oppLineItem14.classification_cib_banker_type__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem14);
            OpportunityLineItem oppLineItem15 = testClass.createOppLineItem(opp15, prod15, pEntryTest15);
            oppLineItem15 = testClass.updateOppLineItem(oppLineItem15, userTest);
            oppLineItem15.classification_cib_banker_type__c = null; //NOSONAR
            oppLineItem15.customer_cib_ind_type__c = 'No';
            oppLineItem15.regional_area_name__c = null; //NOSONAR
            oppLineItem15.classification_cib_banker_type__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem15);
            OpportunityLineItem oppLineItem16 = testClass.createOppLineItem(opp16, prod16, pEntryTest16);
            oppLineItem16 = testClass.updateOppLineItem(oppLineItem16, userTest);
            opportunityLineItemList.add(oppLineItem16);
            Test.StartTest();
                insert opportunityLineItemList;
                opp13.StageName = LABEL.DES_Approvals;
                opp14.StageName = LABEL.DES_Approvals;
                opp15.StageName = LABEL.DES_Approvals;
                opp16.StageName = LABEL.DES_Approvals;
                System.debug('opportunityList: ' + opportunityList);
                try {
                    update opportunityList;
                    update productList;
                    System.debug('opportunityList depsues: ' + opportunityList);
                }catch(Exception e) {
            		system.debug('ERROR: ' + e);
                }
                update productList;
                final List<String> listWC = new List<String>{'solution_name_path_desc__c','loan_tenor_month_desc__c'};
                system.debug(listWC);
            	System.assertEquals(opp13.StageName, LABEL.DES_Approvals, 'Error');
            Test.StopTest();
        }
    }
    
    /**
    * @author Global Desktop | 1/6/2020
    * @return void
    **/
    @isTest
    static void testTrigger5(){
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
        system.runAs(userTest){
            final List<Account> lAcc = new List<Account>();
            final Account acc = testClass.createClient();
            final Account ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            lAcc.add(acc);
            lAcc.add(ac2);
            insert lAcc;
            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;
            final list<Product2> productList = new list<product2>();
            final Product2 prod9 = testClass.createProduct(LABEL.DES_Rates);
            productList.add(prod9);
            final Product2 prod10 = testClass.createProduct(LABEL.DES_Equity);
            productList.add(prod10);
            final Product2 prod11 = testClass.createProduct(LABEL.DES_FX);
            productList.add(prod11);
            final Product2 prod12 = testClass.createProduct(LABEL.DES_Credit);
            productList.add(prod12);
            insert productList;
            final list<PricebookEntry> pEntryList = new list<PricebookEntry>();
            final PricebookEntry pEntryTest9 = testClass.createPricebookEntry(prod9);
            pEntryList.add(pEntryTest9);
            final PricebookEntry pEntryTest10 = testClass.createPricebookEntry(prod10);
            pEntryList.add(pEntryTest10);
            final PricebookEntry pEntryTest11 = testClass.createPricebookEntry(prod11);
            pEntryList.add(pEntryTest11);
            final PricebookEntry pEntryTest12 = testClass.createPricebookEntry(prod12);
            pEntryList.add(pEntryTest12);
            insert pEntryList;
            final list<Opportunity> opportunityList = new list<Opportunity>();
            final Opportunity opp9 = testClass.createOpportunity(ac2);
            opp9.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp9);
            final Opportunity opp10 = testClass.createOpportunity(acc);
            opp10.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp10);
            final Opportunity opp11 = testClass.createOpportunity(acc);
            opp11.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp11);
            final Opportunity opp12 = testClass.createOpportunity(acc);
            opp12.StageName = LABEL.DES_Proposal;
            opportunityList.add(opp12);
            insert opportunityList;
            final list<OpportunityLineItem> opportunityLineItemList = new list<OpportunityLineItem>();
            OpportunityLineItem oppLineItem9 = testClass.createOppLineItem(opp9, prod9, pEntryTest9);
            oppLineItem9 = testClass.updateOppLineItem(oppLineItem9, userTest);
            oppLineItem9.solution_name_path_desc__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem9);
            OpportunityLineItem oppLineItem10 = testClass.createOppLineItem(opp10, prod10, pEntryTest10);
            oppLineItem10 = testClass.updateOppLineItem(oppLineItem10, userTest);
            oppLineItem10.pre_oppy_revenue_next_12m_amount__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem10);
            OpportunityLineItem oppLineItem11 = testClass.createOppLineItem(opp11, prod11, pEntryTest11);
            oppLineItem11 = testClass.updateOppLineItem(oppLineItem11, userTest);
            oppLineItem11.solution_name_path_desc__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem11);
            OpportunityLineItem oppLineItem12 = testClass.createOppLineItem(opp12, prod12, pEntryTest12);
            oppLineItem12 = testClass.updateOppLineItem(oppLineItem12, userTest);
            oppLineItem12.pre_oppy_revenue_next_12m_amount__c = null; //NOSONAR
            opportunityLineItemList.add(oppLineItem12);
            Test.StartTest();
                insert opportunityLineItemList;
                opp9.StageName = LABEL.DES_Approvals;
                opp10.StageName = LABEL.DES_Approvals;
                opp11.StageName = LABEL.DES_Approvals;
                opp12.StageName = LABEL.DES_Approvals;
                System.debug('opportunityList: ' + opportunityList);
                try {
                    update opportunityList;
                    update productList;
                    System.debug('opportunityList depsues: ' + opportunityList);
                }catch(Exception e) {
            		system.debug('ERROR: ' + e);
                }
                update productList;
                final List<String> listWC = new List<String>{'solution_name_path_desc__c','loan_tenor_month_desc__c'};
                system.debug(listWC);
            	System.assertEquals(opp9.StageName, LABEL.DES_Approvals, 'Error');
            Test.StopTest();
        }
    }

    /**
    * @description
    * @author Global Desktop | 1/6/2020
    * @return void
    **/
    @isTest
    static void testTrigger3() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
    	final User userTest = testClass.createUserWithProfileName('BBVA Desktop Finance','usuario@prueba.cdasaom');
        insert userTest;
        final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
        system.runAs(userTest) {
            final List<Account> lAcc = new List<Account>();
            final Account acc = testClass.createClient();
            lAcc.add(acc);
            insert lAcc;
            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            insert listaBBVAMT;
            final list<Product2> productList = new list<product2>();
            final Product2 prod9 = testClass.createProduct(LABEL.DES_Rates);
            productList.add(prod9);
            insert productList;
            final list<PricebookEntry> pEntryList = new list<PricebookEntry>();
            final PricebookEntry pEntryTest9 = testClass.createPricebookEntry(prod9);
            pEntryList.add(pEntryTest9);
            insert pEntryList;
            final list<Opportunity> opportunityList = new list<Opportunity>();
            final Opportunity opp9 = testClass.createOpportunity(acc);
            opp9.StageName = LABEL.DES_Draft;
            opportunityList.add(opp9);
            insert opportunityList;
            final list<OpportunityLineItem> oppLIList = new list<OpportunityLineItem>();
            OpportunityLineItem oppLineItem9 = testClass.createOppLineItem(opp9, prod9, pEntryTest9);
            oppLineItem9 = testClass.updateOppLineItem(oppLineItem9, userTest);
            oppLineItem9.solution_name_path_desc__c = null; //NOSONAR
            oppLIList.add(oppLineItem9);
            insert oppLIList;
            Test.StartTest();
                System.debug('opportunityList: ' + opportunityList);
                try {

                    update opportunityList;
                    update productList;
                     delete oppLIList;
                    System.debug('opportunityList depsues: ' + opportunityList);
                } catch(Exception e) {
            		system.debug('ERROR: ' + e);
                }
                final List<String> listWC = new List<String>{'solution_name_path_desc__c','loan_tenor_month_desc__c'};
                system.debug(listWC);
            	System.assertEquals(opp9.StageName, LABEL.DES_Draft, 'Error');
            	delete opportunityList;
            Test.StopTest();
        }
    }
}