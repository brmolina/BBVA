/********************************************************************
Name:           DES_OpportunityTriggerTest2
Description:    Clase de testeo del trigger de Oportunidades
                    Los test de la clase DES_OpportunityTriggerHandler se dividen en 3 clases de test
                    porque daba error de limite de tiempo en Salesforce:
                        DES_OpportunityTriggerTest
                        DES_OpportunityTriggerTest2
                        DES_OpportunityTriggerTest3

Version        Date            Author            Summary of changes
---------------------------------------------------------------------

********************************************************************/
@isTest
public class DES_OpportunityTriggerTest2 {

	/* Declarando variable */
    private static final String IBFTYPE = 'IBF';

    @isTest
    static void testTrigger2() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;

        system.runAs(userTest) {
            final List <Account> listAccounts = new List<Account>();
            final Account acc = testClass.createClient();
            listAccounts.add(acc);
            final Account acc1 = testClass.createClient();
            acc.DES_BBVA_Segmentation__c = Label.DES_Segmentation_C_CIB;
            acc.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
            listAccounts.add(acc1);
            insert listAccounts;

            final DES_Subsidiary_Group_Relation__c matrix = new DES_Subsidiary_Group_Relation__c();
            matrix.participant_child_id__c = acc.Id;
            //matrix.senior_pos_type__c = userTest.Id;
            matrix.participant_parent_id__c = acc1.Id;
            matrix.main_subsidiary_ind_type__c = true;
            insert matrix;

            final list<Product2> productList = new list<product2>();
            final Product2 prod = testClass.createProduct(LABEL.DES_Cash_Management);
            productList.add(prod);
            final Product2 prod2 = testClass.createProduct(LABEL.DES_Corporate_Loans);
            productList.add(prod2);
            final Product2 prod3 = testClass.createProduct(Label.DES_Project_Finance_Lending);
            prod3.Family = IBFTYPE;
            productList.add(prod3);
            insert productList;

            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            bbvaMT.DES_Local_Banker_Country__c = 'AR';
            bbvaMT.DES_Member_Role__c  = Label.DES_Role_Product_Specialist;
            bbvaMT.DES_PS_Product__c = prod3.id;
            bbvaMT.DES_PS_Product_Family__c = IBFTYPE;
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            bbvaMT2.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
            listaBBVAMT.add(bbvaMT2);

            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc1);
            bbvaMT3.DES_Local_Banker_Country__c = 'AR';
            bbvaMT3.DES_Member_Role__c  = Label.DES_Role_Product_Specialist;
            bbvaMT3.DES_PS_Product__c = prod3.id;
            bbvaMT3.DES_PS_Product_Family__c = IBFTYPE;
            listaBBVAMT.add(bbvaMT3);
            final DES_BBVA_Management_team__c bbvaMT4 = testClass.createBBVAManagementTeamMember(userTest, acc1);
            bbvaMT4.DES_Member_Role__c = Label.DES_Role_Transactional_Banker;
            listaBBVAMT.add(bbvaMT4);
            insert listaBBVAMT;

            final list<PricebookEntry> pBookList = new list<PricebookEntry>();
            final PricebookEntry pricebookEntryTest = testClass.createPricebookEntry(prod);
            pBookList.add(pricebookEntryTest);
            final PricebookEntry pricebookEntryTest2 = testClass.createPricebookEntry(prod2);
            pBookList.add(pricebookEntryTest2);
            final PricebookEntry pricebookEntryTest3 = testClass.createPricebookEntry(prod3);
            pBookList.add(pricebookEntryTest3);
            insert pBookList;

            final list<Opportunity> opportunityList = new list<Opportunity>();
            final Opportunity opp = testClass.createOpportunity(acc);
            opp.StageName = LABEL.DES_Proposal;
            opp.DES_Countries__c = 'AR';
            opportunityList.add(opp);
            final Opportunity opp2 = testClass.createOpportunity(acc);
            opp2.StageName = LABEL.DES_Proposal;
            opp2.DES_Countries__c = 'AR';
            opportunityList.add(opp2);
            final Opportunity opp3 = testClass.createOpportunity(acc);
            opp3.StageName = LABEL.DES_Proposal;
            opp3.DES_Countries__c = 'AR';
            opportunityList.add(opp3);


            insert opportunityList;


            final list<OpportunityLineItem> oppItemList = new list<OpportunityLineItem>();

            Test.startTest();
            final OpportunityLineItem oppLineItem = testClass.createOppLineItem(opp, prod, pricebookEntryTest);
            oppLineItem.DES_All_In__c = null; //NOSONAR
            oppItemList.add(oppLineItem);

            OpportunityLineItem oppLineItem2 = testClass.createOppLineItem(opp2, prod2, pricebookEntryTest2);
            oppLineItem2 = testClass.updateOppLineItem(oppLineItem2, userTest);
            oppLineItem2.classification_cib_banker_type__c = null; //NOSONAR
            oppLineItem2.customer_cib_ind_type__c = 'No';
            oppLineItem2.regional_area_name__c = null; //NOSONAR
            oppLineItem2.classification_cib_banker_type__c = null; //NOSONAR
            oppItemList.add(oppLineItem2);

            OpportunityLineItem oppLineItem3 = testClass.createOppLineItem(opp3, prod3, pricebookEntryTest3);
            oppLineItem3 = testClass.updateOppLineItem(oppLineItem3, userTest);
            oppLineItem3.classification_cib_banker_type__c = null; //NOSONAR
            oppLineItem3.customer_cib_ind_type__c = 'No';
            oppLineItem3.regional_area_name__c = null; //NOSONAR
            oppLineItem3.classification_cib_banker_type__c = null; //NOSONAR
            oppItemList.add(oppLineItem3);
            insert oppItemList;

            final OpportunityLineItem oppAssert = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];
            System.assertEquals(oppAssert.id, oppLineItem.id);
            Test.StopTest();


        }
    }

    /*
    * testTrigger method
    */
    @isTest
    static void testTrigger() {
        /*Variables*/
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;

        system.runAs(userTest) {
            final Account acc = testClass.createClient();
            insert acc;

            final list<Product2> productList = new list<product2>();
            final Product2 prod = testClass.createProduct(LABEL.DES_Cash_Management);
            productList.add(prod);
            final Product2 prod2 = testClass.createProduct(LABEL.DES_Corporate_Loans);
            productList.add(prod2);
            final Product2 prod3 = testClass.createProduct(Label.DES_Project_Finance_Lending);
            prod3.Family = IBFTYPE;
            productList.add(prod3);
            insert productList;

            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            bbvaMT.DES_Local_Banker_Country__c = 'AR';
            bbvaMT.DES_Member_Role__c  = Label.DES_Role_Product_Specialist;
            bbvaMT.DES_PS_Product__c = prod3.id;
            bbvaMT.DES_PS_Product_Family__c = IBFTYPE;
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;

            final list<PricebookEntry> pBookList = new list<PricebookEntry>();
            final PricebookEntry pricebookEntryTest = testClass.createPricebookEntry(prod);
            pBookList.add(pricebookEntryTest);
            final PricebookEntry pricebookEntryTest2 = testClass.createPricebookEntry(prod2);
            pBookList.add(pricebookEntryTest2);
            final PricebookEntry pricebookEntryTest3 = testClass.createPricebookEntry(prod3);
            pBookList.add(pricebookEntryTest3);
            insert pBookList;

            final list<Opportunity> opportunityList = new list<Opportunity>();
            final Opportunity opp = testClass.createOpportunity(acc);
            opp.StageName = LABEL.DES_Proposal;
            opp.DES_Countries__c = 'AR';
            opportunityList.add(opp);
            final Opportunity opp2 = testClass.createOpportunity(acc);
            opp2.StageName = LABEL.DES_Proposal;
            opp2.DES_Countries__c = 'AR';
            opportunityList.add(opp2);
            final Opportunity opp3 = testClass.createOpportunity(acc);
            opp3.StageName = LABEL.DES_Proposal;
            opp3.DES_Countries__c = 'AR';
            opportunityList.add(opp3);
            insert opportunityList;
            Test.StartTest();
            final list<OpportunityLineItem> oppItemList = new list<OpportunityLineItem>();

            final OpportunityLineItem oppLineItem = testClass.createOppLineItem(opp, prod, pricebookEntryTest);
            oppLineItem.DES_All_In__c = null; //NOSONAR
            oppItemList.add(oppLineItem);

            OpportunityLineItem oppLineItem2 = testClass.createOppLineItem(opp2, prod2, pricebookEntryTest2);
            oppLineItem2 = testClass.updateOppLineItem(oppLineItem2, userTest);
            oppLineItem2.classification_cib_banker_type__c = null; //NOSONAR
            oppLineItem2.customer_cib_ind_type__c = 'No';
            oppLineItem2.regional_area_name__c = null; //NOSONAR
            oppLineItem2.classification_cib_banker_type__c = null; //NOSONAR
            oppItemList.add(oppLineItem2);

            OpportunityLineItem oppLineItem3 = testClass.createOppLineItem(opp3, prod3, pricebookEntryTest3);
            oppLineItem3 = testClass.updateOppLineItem(oppLineItem3, userTest);
            oppLineItem3.classification_cib_banker_type__c = null; //NOSONAR
            oppLineItem3.customer_cib_ind_type__c = 'No';
            oppLineItem3.regional_area_name__c = null; //NOSONAR
            oppLineItem3.classification_cib_banker_type__c = null; //NOSONAR
            oppItemList.add(oppLineItem3);

            insert oppItemList;
            final Opportunity oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.debug(oppUpd);
            final Account ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            insert ac2;

            opportunityList.get(0).AccountId = ac2.Id;

            opp.StageName = LABEL.DES_Approvals;
            opp2.StageName = LABEL.DES_Approvals;
            opp3.StageName = LABEL.DES_Approvals;

            System.debug('opportunityList: ' + opportunityList);

            try {
                update opportunityList;
            } catch(Exception e) {
                system.debug('ERROR: ' + e);
            }
            final Opportunity oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.assertEquals(oppAssert.StageName, Label.DES_Approvals, 'KO');
            Test.StopTest();
        }
    }
    
    /*
    * testTrigger method
    */
    @isTest
    static void testTrigger3() {
        /*Variables*/
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;

        system.runAs(userTest) {
            final Account acc = testClass.createClient();
            insert acc;

            final list<Product2> productList = new list<product2>();
            final Product2 prod4 = testClass.createProduct(Label.DES_Project_Finance_Advisory);
            productList.add(prod4);
            final Product2 prod5 = testClass.createProduct(LABEL.DES_Client_Resources);
            productList.add(prod5);
            final Product2 prod6 = testClass.createProduct(LABEL.DES_Transaction_Trade_Finance);
            productList.add(prod6);
            insert productList;

            final list<PricebookEntry> pBookList = new list<PricebookEntry>();
            final PricebookEntry pricebookEntryTest4 = testClass.createPricebookEntry(prod4);
            pBookList.add(pricebookEntryTest4);
            final PricebookEntry pricebookEntryTest5 = testClass.createPricebookEntry(prod5);
            pBookList.add(pricebookEntryTest5);
            final PricebookEntry pricebookEntryTest6 = testClass.createPricebookEntry(prod6);
            pBookList.add(pricebookEntryTest6);
            insert pBookList;

            final list<Opportunity> opportunityList = new list<Opportunity>();
            final Opportunity opp4 = testClass.createOpportunity(acc);
            opp4.StageName = LABEL.DES_Proposal;
            opp4.DES_Countries__c = 'AR';
            opportunityList.add(opp4);
            final Opportunity opp5 = testClass.createOpportunity(acc);
            opp5.StageName = LABEL.DES_Proposal;
            opp5.DES_Countries__c = 'AR';
            opportunityList.add(opp5);
            final Opportunity opp6 = testClass.createOpportunity(acc);
            opp6.StageName = LABEL.DES_Proposal;
            opp6.DES_Countries__c = 'AR';
            opportunityList.add(opp6);
            insert opportunityList;
            Test.StartTest();
            final list<OpportunityLineItem> oppItemList = new list<OpportunityLineItem>();

            OpportunityLineItem oppLineItem4 = testClass.createOppLineItem(opp4, prod4, pricebookEntryTest4);
            oppLineItem4 = testClass.updateOppLineItem(oppLineItem4, userTest);
            oppLineItem4.classification_cib_banker_type__c = null; //NOSONAR
            oppLineItem4.customer_cib_ind_type__c = 'No';
            oppLineItem4.regional_area_name__c = null; //NOSONAR
            oppLineItem4.classification_cib_banker_type__c = null; //NOSONAR
            oppItemList.add(oppLineItem4);

            OpportunityLineItem oppLineItem5 = testClass.createOppLineItem(opp5, prod5, pricebookEntryTest5);
            oppLineItem5 = testClass.updateOppLineItem(oppLineItem5, userTest);
            oppItemList.add(oppLineItem5);

            OpportunityLineItem oppLineItem6 = testClass.createOppLineItem(opp6, prod6, pricebookEntryTest6);
            oppLineItem6 = testClass.updateOppLineItem(oppLineItem6, userTest);
            oppLineItem6.syndicated_loan_drawn_amount__c = null; //NOSONAR
            oppItemList.add(oppLineItem6);

            insert oppItemList;
            final Opportunity oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.debug(oppUpd);
            final Account ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            insert ac2;

            opportunityList.get(0).AccountId = ac2.Id;

            opp4.StageName = LABEL.DES_Approvals;
            opp5.StageName = LABEL.DES_Approvals;
            opp6.StageName = LABEL.DES_Approvals;

            System.debug('opportunityList: ' + opportunityList);

            try {
                update opportunityList;
            } catch(Exception e) {
                system.debug('ERROR: ' + e);
            }
            final Opportunity oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.assertEquals(oppAssert.StageName, Label.DES_Approvals, 'KO');
            Test.StopTest();
        }
    }
    
    /*
    * testTrigger method
    */
    @isTest
    static void testTrigger4() {
        /*Variables*/
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;

        system.runAs(userTest) {
            final Account acc = testClass.createClient();
            insert acc;

            final list<Product2> productList = new list<product2>();
            final Product2 prod7 = testClass.createProduct(LABEL.DES_Working_Capital);
            productList.add(prod7);
            final Product2 prod8 = testClass.createProduct(LABEL.DES_Securities_Services);
            productList.add(prod8);
            insert productList;

            final list<PricebookEntry> pBookList = new list<PricebookEntry>();
            final PricebookEntry pricebookEntryTest7 = testClass.createPricebookEntry(prod7);
            pBookList.add(pricebookEntryTest7);
            final PricebookEntry pricebookEntryTest8 = testClass.createPricebookEntry(prod8);
            pBookList.add(pricebookEntryTest8);
            insert pBookList;

            final list<Opportunity> opportunityList = new list<Opportunity>();
            final Opportunity opp7 = testClass.createOpportunity(acc);
            opp7.StageName = LABEL.DES_Proposal;
            opp7.DES_Countries__c = 'AR';
            opportunityList.add(opp7);
            final Opportunity opp8 = testClass.createOpportunity(acc);
            opp8.StageName = LABEL.DES_Proposal;
            opp8.DES_Countries__c = 'AR';
            opportunityList.add(opp8);
            insert opportunityList;
            Test.StartTest();
            final list<OpportunityLineItem> oppItemList = new list<OpportunityLineItem>();

            OpportunityLineItem oppLineItem7 = testClass.createOppLineItem(opp7, prod7, pricebookEntryTest7);
            oppLineItem7 = testClass.updateOppLineItem(oppLineItem7, userTest);
            oppLineItem7.DES_Net_spread__c = null; //NOSONAR
            oppLineItem7.proposal_requested_ind_type__c = null; //NOSONAR
            oppLineItem7.loan_tenor_month_desc__c = null; //NOSONAR
            oppItemList.add(oppLineItem7);

            OpportunityLineItem oppLineItem8 = testClass.createOppLineItem(opp8, prod8, pricebookEntryTest8);
            oppLineItem8 = testClass.updateOppLineItem(oppLineItem8, userTest);
            oppLineItem8.pre_oppy_revenue_next_12m_amount__c = null; //NOSONAR
            oppItemList.add(oppLineItem8);



            insert oppItemList;
            final Opportunity oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.debug(oppUpd);
            final Account ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            insert ac2;

            opportunityList.get(0).AccountId = ac2.Id;
            opp7.StageName = LABEL.DES_Approvals;
            opp8.StageName = LABEL.DES_Approvals;

            System.debug('opportunityList: ' + opportunityList);

            try {
                update opportunityList;
            } catch(Exception e) {
                system.debug('ERROR: ' + e);
            }
            final Opportunity oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.assertEquals(oppAssert.StageName, Label.DES_Approvals, 'KO');
            Test.StopTest();
        }
    }

}