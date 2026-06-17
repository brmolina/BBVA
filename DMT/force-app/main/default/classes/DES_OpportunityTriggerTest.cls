/*****************************************
Name:           DES_OpportunityTriggerTest
Description:    Clase de testeo del trigger de Oportunidades
                    Los test de la clase DES_OpportunityTriggerHandler se dividen en 3 clases de test porque daba error de limite de tiempo en Salesforce:
                        DES_OpportunityTriggerTest
                        DES_OpportunityTriggerTest2
                        DES_OpportunityTriggerTest3

Version        Date            Author            Summary of changes
--------------------------------------------------------------------

********************************************/
@isTest
private class DES_OpportunityTriggerTest {

    @isTest (SeeAllData=true)
    static void testTrigger0() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;

    system.runAs(userTest) {


        List<Account> lstAcc;
        lstAcc = new List<Account>();
        final Account acc = testClass.createClient();
        Account ac2;
        ac2 = testClass.createClient();
        ac2.Name = 'Cuenta TEST 2';
        lstAcc.add(acc);
        lstAcc.add(ac2);
        insert lstAcc;

        final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
        final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, lstAcc[0]);
        listaBBVAMT.add(bbvaMT);
        final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, lstAcc[0]);
        listaBBVAMT.add(bbvaMT2);
        final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, lstAcc[0]);
        listaBBVAMT.add(bbvaMT3);
        insert listaBBVAMT;

        List<Product2> productList = new List<Product2>();
        productList = createProducts(productList);


        List<PricebookEntry> prBkEntryList;
        prBkEntryList = new List<PricebookEntry>();
        prBkEntryList = createEntries(productList, prBkEntryList);
        prBkEntryList = createEntries1(productList, prBkEntryList);
        insert prBkEntryList;

        List<Opportunity> opportunityList = new List<Opportunity>();
        opportunityList = createOpps(opportunityList, lstAcc[0], null);
        opportunityList = createOpps1(opportunityList, lstAcc[0], null);
        insert opportunityList;

        final list<OpportunityLineItem> OppLineItmList = new list<OpportunityLineItem>();

        OpportunityLineItem oppLineItem;
        oppLineItem = testClass.createOppLineItem(opportunityList[0], productList[0], prBkEntryList[0]);
        oppLineItem.DES_All_In__c = null;
        OppLineItmList.add(oppLineItem);

        OpportunityLineItem oppLineItem2 = testClass.createOppLineItem(opportunityList[1], productList[1], prBkEntryList[1]);
        oppLineItem2 = testClass.updateOppLineItem(oppLineItem2, userTest);
        oppLineItem2.customer_cib_ind_type__c = 'No';
        oppLineItem2.regional_area_name__c = null;
        oppLineItem2.classification_cib_banker_type__c = null;
        OppLineItmList.add(oppLineItem2);

        OpportunityLineItem oppLineItem3 = testClass.createOppLineItem(opportunityList[2], productList[2], prBkEntryList[2]);
        oppLineItem3 = testClass.updateOppLineItem(oppLineItem3, userTest);
        oppLineItem3.classification_cib_banker_type__c = null;
        oppLineItem3.customer_cib_ind_type__c = 'No';
        oppLineItem3.regional_area_name__c = null;
        oppLineItem3.classification_cib_banker_type__c = null;
        OppLineItmList.add(oppLineItem3);

        OpportunityLineItem oppLineItem4 = testClass.createOppLineItem(opportunityList[3], productList[3], prBkEntryList[3]);
        oppLineItem4 = testClass.updateOppLineItem(oppLineItem4, userTest);
        oppLineItem4.classification_cib_banker_type__c = null;
        oppLineItem4.customer_cib_ind_type__c = 'No';
        oppLineItem4.regional_area_name__c = null;
        oppLineItem4.classification_cib_banker_type__c = null;
        OppLineItmList.add(oppLineItem4);

        OpportunityLineItem oppLineItem5 = testClass.createOppLineItem(opportunityList[4], productList[4], prBkEntryList[4]);
        oppLineItem5 = testClass.updateOppLineItem(oppLineItem5, userTest);
        OppLineItmList.add(oppLineItem5);

        OpportunityLineItem oppLineItem6 = testClass.createOppLineItem(opportunityList[5], productList[5], prBkEntryList[5]);
        oppLineItem6 = testClass.updateOppLineItem(oppLineItem6, userTest);
        OppLineItmList.add(oppLineItem6);

        OpportunityLineItem oppLineItem7 = testClass.createOppLineItem(opportunityList[6], productList[6], prBkEntryList[6]);
        oppLineItem7 = testClass.updateOppLineItem(oppLineItem7, userTest);
        oppLineItem7.DES_Net_spread__c = null;
        oppLineItem7.proposal_requested_ind_type__c = null;
        OppLineItmList.add(oppLineItem7);

        OpportunityLineItem oppLineItem8 = testClass.createOppLineItem(opportunityList[7], productList[7], prBkEntryList[7]);
        oppLineItem8 = testClass.updateOppLineItem(oppLineItem8, userTest);
        OppLineItmList.add(oppLineItem8);

        OpportunityLineItem oppLineItem9 = testClass.createOppLineItem(opportunityList[8], productList[8], prBkEntryList[8]);
        oppLineItem9 = testClass.updateOppLineItem(oppLineItem9, userTest);
        oppLineItem9.solution_name_path_desc__c = null;
        OppLineItmList.add(oppLineItem9);

        OpportunityLineItem oppLineItem10 = testClass.createOppLineItem(opportunityList[9], productList[9], prBkEntryList[9]);
        oppLineItem10 = testClass.updateOppLineItem(oppLineItem10, userTest);
        oppLineItem10.pre_oppy_revenue_next_12m_amount__c = null;
        OppLineItmList.add(oppLineItem10);

        OpportunityLineItem oppLineItem11 = testClass.createOppLineItem(opportunityList[10], productList[10], prBkEntryList[10]);
        oppLineItem11 = testClass.updateOppLineItem(oppLineItem11, userTest);
        oppLineItem11.solution_name_path_desc__c = null;
        OppLineItmList.add(oppLineItem11);

        OpportunityLineItem oppLineItem12 = testClass.createOppLineItem(opportunityList[11], productList[11], prBkEntryList[11]);
        oppLineItem12 = testClass.updateOppLineItem(oppLineItem12, userTest);
        oppLineItem12.solution_name_path_desc__c = null;
        OppLineItmList.add(oppLineItem12);

        OpportunityLineItem oppLineItem13 = testClass.createOppLineItem(opportunityList[12], productList[12], prBkEntryList[12]);
        oppLineItem13 = testClass.updateOppLineItem(oppLineItem13, userTest);
        oppLineItem13.customer_cib_ind_type__c = 'No';
        oppLineItem13.regional_area_name__c = null;
        oppLineItem13.classification_cib_banker_type__c = null;
        OppLineItmList.add(oppLineItem13);

        OpportunityLineItem oppLineItem14 = testClass.createOppLineItem(opportunityList[13], productList[13], prBkEntryList[13]);
        oppLineItem14 = testClass.updateOppLineItem(oppLineItem14, userTest);
        oppLineItem14.customer_cib_ind_type__c = 'No';
        oppLineItem14.regional_area_name__c = null;
        oppLineItem14.classification_cib_banker_type__c = null;
        OppLineItmList.add(oppLineItem14);

        OpportunityLineItem oppLineItem15 = testClass.createOppLineItem(opportunityList[14], productList[14], prBkEntryList[14]);
        oppLineItem15 = testClass.updateOppLineItem(oppLineItem15, userTest);
        oppLineItem15.classification_cib_banker_type__c = null;
        oppLineItem15.customer_cib_ind_type__c = 'No';
        OppLineItmList.add(oppLineItem15);

        OpportunityLineItem oppLineItem16 = testClass.createOppLineItem(opportunityList[15], productList[15], prBkEntryList[15]);
        oppLineItem16 = testClass.updateOppLineItem(oppLineItem16, userTest);
        OppLineItmList.add(oppLineItem16);

        OpportunityLineItem oppLineItem17 = testClass.createOppLineItem(opportunityList[16], productList[16], prBkEntryList[16]);
        oppLineItem17 = testClass.updateOppLineItem(oppLineItem17, userTest);
        oppLineItem17.customer_cib_ind_type__c = null;
        oppLineItem17.regional_area_name__c = null;
        oppLineItem17.classification_cib_banker_type__c = null;
        OppLineItmList.add(oppLineItem17);

        OpportunityLineItem oppLineItem18 = testClass.createOppLineItem(opportunityList[17], productList[16], prBkEntryList[16]);
        oppLineItem18 = testClass.updateOppLineItem(oppLineItem18, userTest);
        oppLineItem18.customer_cib_ind_type__c = 'No';
        oppLineItem18.DES_Origination_Geography__c = 'USA';
        oppLineItem18.regional_area_name__c = null;
        oppLineItem18.classification_cib_banker_type__c = null;
        OppLineItmList.add(oppLineItem18);

        OpportunityLineItem oppLineItem19 = testClass.createOppLineItem(opportunityList[18], productList[16], prBkEntryList[16]);
        oppLineItem19 = testClass.updateOppLineItem(oppLineItem19, userTest);
        oppLineItem19.customer_cib_ind_type__c = 'No';
        oppLineItem19.DES_Origination_Geography__c = 'Spain';
        oppLineItem19.regional_area_name__c = null;
        oppLineItem19.classification_cib_banker_type__c = null;
        OppLineItmList.add(oppLineItem19);

        insert OppLineItmList;


        opportunityList[0].StageName = LABEL.DES_Proposal;
        opportunityList[1].StageName = LABEL.DES_Proposal;
        opportunityList[2].StageName = LABEL.DES_Proposal;
        opportunityList[3].StageName = LABEL.DES_Proposal;
        opportunityList[4].StageName = LABEL.DES_Proposal;
        opportunityList[5].StageName = LABEL.DES_Proposal;
        opportunityList[6].StageName = LABEL.DES_Proposal;
        opportunityList[7].StageName = LABEL.DES_Proposal;
        opportunityList[8].StageName = LABEL.DES_Proposal;
        opportunityList[9].StageName = LABEL.DES_Proposal;
        opportunityList[10].StageName = LABEL.DES_Proposal;
        opportunityList[11].StageName = LABEL.DES_Proposal;
        opportunityList[12].StageName = LABEL.DES_Proposal;
        opportunityList[13].StageName = LABEL.DES_Proposal;
        opportunityList[14].StageName = LABEL.DES_Proposal;
        opportunityList[15].StageName = LABEL.DES_Proposal;
        opportunityList[16].StageName = LABEL.DES_Proposal;
        opportunityList[17].StageName = LABEL.DES_Proposal;
        opportunityList[18].StageName = LABEL.DES_Proposal;
        System.debug('opportunityList: ' + opportunityList);
        Test.startTest();
           try {

				update opportunityList;

            } catch(Exception e) {
                  System.debug('Error: ' + e.getMessage());
            }

            Opportunity oppAssert;
            oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.assertEquals(oppAssert.StageName, Label.DES_Proposal, 'Error');

        Test.StopTest();
      }
    }
    @isTest
    static void testTrigger() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        //final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        //insert userSettings;

        system.runAs(userTest) {

            Lead ldld1;
            ldld1 = new Lead();
            ldld1.LastName = 'Test';
            ldld1.Company = 'Test';
            insert ldld1;

            List<Account> lstAcc;
            lstAcc = new List<Account>();
            final Account acc = testClass.createClient();
            Account ac2;
            ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            lstAcc.add(acc);
            lstAcc.add(ac2);
            insert lstAcc;

            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, lstAcc[0]);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, lstAcc[0]);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, lstAcc[0]);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;

            List<Product2> productList = new List<Product2>();
            productList = createProducts(productList);


            List<PricebookEntry> prBkEntryList;
            prBkEntryList = new List<PricebookEntry>();
            prBkEntryList = createEntries(productList, prBkEntryList);
            prBkEntryList = createEntries1(productList, prBkEntryList);
            insert prBkEntryList;

            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = createOpps(opportunityList, lstAcc[0], null);
            opportunityList = createOpps1(opportunityList, lstAcc[0], null);
            insert opportunityList;

            
            final list<OpportunityLineItem> OppLineItmList = new list<OpportunityLineItem>();

            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opportunityList[0], productList[0], prBkEntryList[0]);
            oppLineItem.DES_All_In__c = null;
            OppLineItmList.add(oppLineItem);

            OpportunityLineItem oppLineItem2 = testClass.createOppLineItem(opportunityList[1], productList[1], prBkEntryList[1]);
            oppLineItem2 = testClass.updateOppLineItem(oppLineItem2, userTest);
            oppLineItem2.customer_cib_ind_type__c = 'No';
            oppLineItem2.regional_area_name__c = null;
            oppLineItem2.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem2);

            OpportunityLineItem oppLineItem3 = testClass.createOppLineItem(opportunityList[2], productList[2], prBkEntryList[2]);
            oppLineItem3 = testClass.updateOppLineItem(oppLineItem3, userTest);
            oppLineItem3.classification_cib_banker_type__c = null;
            oppLineItem3.customer_cib_ind_type__c = 'No';
            oppLineItem3.regional_area_name__c = null;
            oppLineItem3.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem3);

            OpportunityLineItem oppLineItem4 = testClass.createOppLineItem(opportunityList[3], productList[3], prBkEntryList[3]);
            oppLineItem4 = testClass.updateOppLineItem(oppLineItem4, userTest);
            oppLineItem4.classification_cib_banker_type__c = null;
            oppLineItem4.customer_cib_ind_type__c = 'No';
            oppLineItem4.regional_area_name__c = null;
            oppLineItem4.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem4);

            OpportunityLineItem oppLineItem5 = testClass.createOppLineItem(opportunityList[4], productList[4], prBkEntryList[4]);
            oppLineItem5 = testClass.updateOppLineItem(oppLineItem5, userTest);
            OppLineItmList.add(oppLineItem5);

            OpportunityLineItem oppLineItem6 = testClass.createOppLineItem(opportunityList[5], productList[5], prBkEntryList[5]);
            oppLineItem6 = testClass.updateOppLineItem(oppLineItem6, userTest);
            OppLineItmList.add(oppLineItem6);

            OpportunityLineItem oppLineItem7 = testClass.createOppLineItem(opportunityList[6], productList[6], prBkEntryList[6]);
            oppLineItem7 = testClass.updateOppLineItem(oppLineItem7, userTest);
            oppLineItem7.DES_Net_spread__c = null;
            oppLineItem7.proposal_requested_ind_type__c = null;
            OppLineItmList.add(oppLineItem7);

            OpportunityLineItem oppLineItem8 = testClass.createOppLineItem(opportunityList[7], productList[7], prBkEntryList[7]);
            oppLineItem8 = testClass.updateOppLineItem(oppLineItem8, userTest);
            OppLineItmList.add(oppLineItem8);

            OpportunityLineItem oppLineItem9 = testClass.createOppLineItem(opportunityList[8], productList[8], prBkEntryList[8]);
            oppLineItem9 = testClass.updateOppLineItem(oppLineItem9, userTest);
            oppLineItem9.solution_name_path_desc__c = null;
            OppLineItmList.add(oppLineItem9);

            OpportunityLineItem oppLineItem10 = testClass.createOppLineItem(opportunityList[9], productList[9], prBkEntryList[9]);
            oppLineItem10 = testClass.updateOppLineItem(oppLineItem10, userTest);
            oppLineItem10.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem10);

            OpportunityLineItem oppLineItem11 = testClass.createOppLineItem(opportunityList[10], productList[10], prBkEntryList[10]);
            oppLineItem11 = testClass.updateOppLineItem(oppLineItem11, userTest);
            oppLineItem11.solution_name_path_desc__c = null;
            OppLineItmList.add(oppLineItem11);

            OpportunityLineItem oppLineItem12 = testClass.createOppLineItem(opportunityList[11], productList[11], prBkEntryList[11]);
            oppLineItem12 = testClass.updateOppLineItem(oppLineItem12, userTest);
            oppLineItem12.solution_name_path_desc__c = null;
            OppLineItmList.add(oppLineItem12);

            OpportunityLineItem oppLineItem13 = testClass.createOppLineItem(opportunityList[12], productList[12], prBkEntryList[12]);
            oppLineItem13 = testClass.updateOppLineItem(oppLineItem13, userTest);
            oppLineItem13.customer_cib_ind_type__c = 'No';
            oppLineItem13.regional_area_name__c = null;
            oppLineItem13.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem13);

            OpportunityLineItem oppLineItem14 = testClass.createOppLineItem(opportunityList[13], productList[13], prBkEntryList[13]);
            oppLineItem14 = testClass.updateOppLineItem(oppLineItem14, userTest);
            oppLineItem14.customer_cib_ind_type__c = 'No';
            oppLineItem14.regional_area_name__c = null;
            oppLineItem14.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem14);

            OpportunityLineItem oppLineItem15 = testClass.createOppLineItem(opportunityList[14], productList[14], prBkEntryList[14]);
            oppLineItem15 = testClass.updateOppLineItem(oppLineItem15, userTest);
            oppLineItem15.classification_cib_banker_type__c = null;
            oppLineItem15.customer_cib_ind_type__c = 'No';
            OppLineItmList.add(oppLineItem15);

            OpportunityLineItem oppLineItem16 = testClass.createOppLineItem(opportunityList[15], productList[15], prBkEntryList[15]);
            oppLineItem16 = testClass.updateOppLineItem(oppLineItem16, userTest);
            OppLineItmList.add(oppLineItem16);

            OpportunityLineItem oppLineItem17 = testClass.createOppLineItem(opportunityList[16], productList[16], prBkEntryList[16]);
            oppLineItem17 = testClass.updateOppLineItem(oppLineItem17, userTest);
            oppLineItem17.customer_cib_ind_type__c = null;
            oppLineItem17.regional_area_name__c = null;
            oppLineItem17.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem17);

            OpportunityLineItem oppLineItem18 = testClass.createOppLineItem(opportunityList[17], productList[16], prBkEntryList[16]);
            oppLineItem18 = testClass.updateOppLineItem(oppLineItem18, userTest);
            oppLineItem18.customer_cib_ind_type__c = 'No';
            oppLineItem18.DES_Origination_Geography__c = 'USA';
            oppLineItem18.regional_area_name__c = null;
            oppLineItem18.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem18);

            OpportunityLineItem oppLineItem19 = testClass.createOppLineItem(opportunityList[18], productList[16], prBkEntryList[16]);
            oppLineItem19 = testClass.updateOppLineItem(oppLineItem19, userTest);
            oppLineItem19.customer_cib_ind_type__c = 'No';
            oppLineItem19.DES_Origination_Geography__c = 'Spain';
            oppLineItem19.regional_area_name__c = null;
            oppLineItem19.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem19);

            insert OppLineItmList;
            Test.startTest();
            Opportunity oppUpd;
            oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];

            NBC__c nbcTest;
            nbcTest = testClass.createNBC();
            insert nbcTest;



            oppUpd.AccountId = lstAcc[1].Id;
            oppUpd.Template_approved_type__c = true;
            oppUpd.Committee_id__c = nbcTest.Id;
            oppUpd.DES_Prospect__c = ldld1.id;

            DES_Template__c templateTest;
            templateTest = testClass.createTemplate(oppUpd,OppLineItmList[0]);
            templateTest.YTD_RORC_per_CDD__c = 1;
            templateTest.Past_FY_RORC_per_CDD__c = 2;
            templateTest.Standalone_CDD_RaR_number__c = 1;
            templateTest.Standalone_CDD_RORC_number__c = 1;
            insert templateTest;

            ContentVersion ctntVerTest;

            testClass.createCustomSettingByPass();
            
            ctntVerTest = testClass.createContentVersion(true);
            List<ContentDocument> documents;
            documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            ContentDocumentLink documentTest;
            documentTest = testClass.createContentDocumentLink(templateTest,documents[0]);
            insert documentTest;

            //DES_Commercial_Alert__c alertTest = testClass.createAlert(userTest,userTest,acc,1,'Notification');
            //insert alertTest;
            //oppUpd.commercial_alert_id__c = alertTest.Id;
            OppLineItmList[0].subproduct_name__c = 'Electronics Channels';
            OppLineItmList[0].DES_Service__c = 'Collections - PoS';

            oppLineItem.DES_All_In__c = null;
            update OppLineItmList[0];
                oppUpd.StageName = Label.DES_Proposal;
                update oppUpd;
            Test.StopTest();
                opportunityList[0].StageName = LABEL.DES_Proposal;
                opportunityList[1].StageName = LABEL.DES_Proposal;
                opportunityList[2].StageName = LABEL.DES_Proposal;
                opportunityList[3].StageName = LABEL.DES_Proposal;
                opportunityList[4].StageName = LABEL.DES_Proposal;
                opportunityList[5].StageName = LABEL.DES_Proposal;
                opportunityList[6].StageName = LABEL.DES_Proposal;
                opportunityList[7].StageName = LABEL.DES_Proposal;
                opportunityList[8].StageName = LABEL.DES_Proposal;
                opportunityList[9].StageName = LABEL.DES_Proposal;
                opportunityList[10].StageName = LABEL.DES_Proposal;
                opportunityList[11].StageName = LABEL.DES_Proposal;
                opportunityList[12].StageName = LABEL.DES_Proposal;
                opportunityList[13].StageName = LABEL.DES_Proposal;
                opportunityList[14].StageName = LABEL.DES_Proposal;
                opportunityList[15].StageName = LABEL.DES_Proposal;
                opportunityList[16].StageName = LABEL.DES_Proposal;
                opportunityList[17].StageName = LABEL.DES_Proposal;
                opportunityList[18].StageName = LABEL.DES_Proposal;
                System.debug('opportunityList: ' + opportunityList);

            try {

                //update opportunityList;

                } catch(Exception e) {
                    System.debug('Error: ' + e.getMessage());
                }

                Opportunity oppAssert;
                oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
                system.assertEquals(oppAssert.StageName, Label.DES_Proposal, 'Error');

        }
    }

    @isTest
    static void testTrigger2() {
        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        //final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        //insert userSettings;

        system.runAs(userTest) {
            Test.startTest();
            Account acc;
            acc = testClass.createClient();
            acc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
            acc.DES_Structure_Type__c = 'Group';
            acc.DES_BBVA_Segmentation__c = 'C';
            acc.DES_Entity_Type__c = 'Group';
            acc.DES_Tier__c = '00000020'; //  cib platinum
            acc.DES_Segment__c = '00004'; // others
            insert acc;
            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = createOpps(opportunityList, acc, null);
            insert opportunityList;

            Account acc2;
            acc2 = testClass.createClient();
            acc2.DES_Tier__c = '00000020'; //  cib platinum
            acc2.DES_Segment__c = '00005'; // corporate
            acc2.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
            acc2.DES_Structure_Type__c = 'Group';
            acc2.DES_BBVA_Segmentation__c = 'C';
            acc2.DES_Entity_Type__c = 'Group';
            insert acc2;
            Account acc1;
            acc1 = testClass.createClient();
            acc1.DES_Main_Parent__c = acc2.id;
            insert acc1;
            Opportunity opp;
            opp = testClass.createOpportunity(acc1);
            opp.StageName = 'Draft Opp';
            insert opp;

            List<Product2> productList = new List<Product2>();
            productList = createProducts(productList);
            Product2 prodd;
            prodd = testClass.createProduct(LABEL.DES_Corporate_Loans);
            insert prodd;
            productList.add(prodd);
            List<PricebookEntry> prBkEntryList;
            prBkEntryList = new List<PricebookEntry>();
            prBkEntryList = createEntries(productList, prBkEntryList);
            prBkEntryList = createEntries1(productList, prBkEntryList);
            insert prBkEntryList;
            Test.stopTest();


            Account accc3;
            accc3 = testClass.createClient();
            accc3.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
            accc3.DES_Structure_Type__c = 'Group';
            accc3.DES_BBVA_Segmentation__c = 'C';
            accc3.DES_Entity_Type__c = 'Group';
            acc.DES_Tier__c = '00000020'; //  cib platinum
            insert accc3;
            Account accc2;
            accc2 = testClass.createClient();
            accc2.DES_Main_Parent__c = accc3.id;
            insert accc2;
            Account accc;
            accc = testClass.createClient();
            accc.DES_Main_Parent__c = accc2.id;
            insert accc;

            Opportunity opp2;
            opp2 = testClass.createOpportunity(accc);
            opp2.StageName = 'Draft';
            insert opp2;

            Account acccc3;
            acccc3 = testClass.createClient();
            acccc3.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
            acccc3.DES_Structure_Type__c = 'Group';
            acccc3.DES_BBVA_Segmentation__c = 'C';
            acccc3.DES_Entity_Type__c = 'Group';
            acc.DES_Tier__c = '00000025'; // cib geographic
            insert acccc3;
            Account acccc2;
            acccc2 = testClass.createClient();
            acccc2.DES_Main_Parent__c = acccc3.id;
            acc.DES_Tier__c = '00000025'; // cib geographic
            insert acccc2;
            Account acccc;
            acccc = testClass.createClient();
            acccc.DES_Main_Parent__c = acccc2.id;
            insert acccc;
            Account accc0;
            accc0 = testClass.createClient();
            accc0.DES_Main_Parent__c = acccc.id;
            insert accc0;

            Opportunity opp3;
            opp3 = testClass.createOpportunity(accc0);
            insert opp3;

            delete opp3;
            System.assertNotEquals(accc0.id, null, 'Error');


        }
    }

    @isTest
    static void test3(){
		final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
        bypassSettings.CIB_DES_DataMigration__c = true;
		insert bypassSettings;
		DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        //final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        //insert userSettings;

        system.runAs(userTest) {
            List<Account> accList = new List<Account>();
            Account acc;
            acc = testClass.createClient();
            acc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
            acc.DES_Structure_Type__c = 'Group';
            acc.DES_BBVA_Segmentation__c = 'C';
            acc.DES_Entity_Type__c = 'Group';
            acc.DES_Tier__c = '00000020'; //  cib platinum
            acc.DES_Segment__c = '00004'; // others
            //insert acc;
            accList.add(acc);
            Account acc2;
            acc2 = testClass.createClient();
            acc2.DES_Tier__c = '00000020'; //  cib platinum
            acc2.DES_Segment__c = '00005'; // corporate
            acc2.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
            acc2.DES_Structure_Type__c = 'Group';
            acc2.DES_BBVA_Segmentation__c = 'C';
            acc2.DES_Entity_Type__c = 'Group';
            //insert acc2;
            accList.add(acc2);
            Account acc1;
            acc1 = testClass.createClient();
            acc1.DES_Main_Parent__c = acc2.id;
            //insert acc1;
            accList.add(acc1);
            insert accList;
            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = createOpps(opportunityList, acc, null);
            Opportunity opp;
            opp = testClass.createOpportunity(acc1);
            opp.StageName = 'Draft Opp';
            //insert opp;
            opportunityList.add(opp);
            insert opportunityList;

            List<Product2> productList = new List<Product2>();
            productList = createProducts(productList);
            Product2 prodd;
            prodd = testClass.createProduct(LABEL.DES_Corporate_Loans);
            insert prodd;
            productList.add(prodd);
            List<PricebookEntry> prBkEntryList;
            prBkEntryList = new List<PricebookEntry>();
            prBkEntryList = createEntries(productList, prBkEntryList);
            prBkEntryList = createEntries1(productList, prBkEntryList);
            insert prBkEntryList;

            OpportunityLineItem oppLineItem = testClass.createOppLineItem(opp, prodd, prBkEntryList[0]);
            oppLineItem.DES_All_In__c = null;
            oppLineItem.pre_gross_margin_next_12m_per__c = 77;
            oppLineItem.syndicated_loan_drawn_amount__c = 77;
            oppLineItem.bbva_prtcp_tranche_amount__c = 77;
            oppLineItem.deal_total_amount__c = 77;
            oppLineItem.pre_oppy_revenue_next_12m_amount__c = 77;
            oppLineItem.DES_Tenor__c = '77';
            oppLineItem.opportunity_tenor_years_number__c = 7;
            oppLineItem.opening_fee_per__c = 77;
            oppLineItem.customer_cib_ind_type__c = 'YES';
            oppLineItem.entity_role_type__c = 'Agent';
            oppLineItem.DES_Origination_Geography__c = 'Spain';
            oppLineItem.product_scope_type__c = 'CIB';
            oppLineItem.DES_Service__c = 'Others';
            oppLineItem.origin_country_name__c ='N/A';
            oppLineItem.subproduct_name__c = 'Electronic Channels';
            insert oppLineItem;
            Test.startTest();
            oppLineItem = [SELECT id FROM OpportunityLineItem WHERE id = :oppLineItem.id];
            opp.StageName = LABEL.DES_Proposal;
            try {
                  update opp;
                  opp.StageName = LABEL.DES_Approvals;
                  update opp;
            } catch(Exception e){
                  System.debug('test');
            }

            System.assertEquals(opp.StageName, LABEL.DES_Approvals,'Error');
			Test.stopTest();
      }
    }

    /*
    *toCloseWonTest
    */
    @isTest
    static void toCloseWon() {
		final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
        bypassSettings.CIB_DES_DataMigration__c = true;
		insert bypassSettings;
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        //final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        //insert userSettings;

        system.runAs(userTest) {
            final Account acc = testClass.createClient();
            insert acc;

            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;

            List<Product2> productList = new List<Product2>();
            productList = createProducts(productList);

            List<PricebookEntry> prBkEntryList;
            prBkEntryList = new List<PricebookEntry>();
            prBkEntryList = createEntries(productList, prBkEntryList);
            insert prBkEntryList;

            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = createOpps(opportunityList, acc, LABEL.DES_Approvals);
            insert opportunityList;

            final list<OpportunityLineItem> OppLineItmList = new list<OpportunityLineItem>();

            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opportunityList[0], productList[0], prBkEntryList[0]);
            oppLineItem.DES_All_In__c = null;
            oppLineItem.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem);

            OpportunityLineItem oppLineItem2 = testClass.createOppLineItem(opportunityList[1], productList[1], prBkEntryList[1]);
            oppLineItem2 = testClass.updateOppLineItem(oppLineItem2, userTest);
            oppLineItem2.classification_cib_banker_type__c = null;
            oppLineItem2.customer_cib_ind_type__c = 'No';
            oppLineItem2.regional_area_name__c = null;
            OppLineItmList.add(oppLineItem2);

            OpportunityLineItem oppLineItem3 = testClass.createOppLineItem(opportunityList[2], productList[2], prBkEntryList[2]);
            oppLineItem3 = testClass.updateOppLineItem(oppLineItem3, userTest);
            oppLineItem3.classification_cib_banker_type__c = null;
            oppLineItem3.customer_cib_ind_type__c = 'No';
            oppLineItem3.regional_area_name__c = null;
            oppLineItem3.DES_Booking_System__c = null;
            OppLineItmList.add(oppLineItem3);

            OpportunityLineItem oppLineItem4 = testClass.createOppLineItem(opportunityList[3], productList[3], prBkEntryList[3]);
            oppLineItem4 = testClass.updateOppLineItem(oppLineItem4, userTest);
            oppLineItem4.classification_cib_banker_type__c = null;
            oppLineItem4.customer_cib_ind_type__c = 'No';
            oppLineItem4.regional_area_name__c = null;
            oppLineItem4.fee_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem4);

            OpportunityLineItem oppLineItem5 = testClass.createOppLineItem(opportunityList[4], productList[4], prBkEntryList[4]);
            oppLineItem5 = testClass.updateOppLineItem(oppLineItem5, userTest);
            oppLineItem5.loan_tenor_month_desc__c = null;
            OppLineItmList.add(oppLineItem5);

            OpportunityLineItem oppLineItem6 = testClass.createOppLineItem(opportunityList[5], productList[5], prBkEntryList[5]);
            oppLineItem6 = testClass.updateOppLineItem(oppLineItem6, userTest);
            oppLineItem6.DES_Booking_Office__c = null;
            OppLineItmList.add(oppLineItem6);

            OpportunityLineItem oppLineItem7 = testClass.createOppLineItem(opportunityList[6], productList[6], prBkEntryList[6]);
            oppLineItem7 = testClass.updateOppLineItem(oppLineItem7, userTest);
            oppLineItem7.DES_Net_spread__c = null;
            oppLineItem7.proposal_requested_ind_type__c = null;
            oppLineItem7.loan_tenor_month_desc__c = null;
            OppLineItmList.add(oppLineItem7);

		OpportunityLineItem oppLineItem8;
            oppLineItem8 = testClass.createOppLineItem(opportunityList[7], productList[7], prBkEntryList[7]);
            oppLineItem8.signing_date__c = null;
            OppLineItmList.add(oppLineItem8);

            OpportunityLineItem oppLineItem9 = testClass.createOppLineItem(opportunityList[8], productList[8], prBkEntryList[8]);
            oppLineItem9 = testClass.updateOppLineItem(oppLineItem9, userTest);
            oppLineItem9.solution_name_path_desc__c = null;
            oppLineItem9.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem9);

            Test.StartTest();

            insert OppLineItmList;
            Opportunity oppUpd;
            oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            Account ac2;
            ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            insert ac2;

            oppUpd.AccountId = ac2.Id;
            update oppUpd;



            opportunityList[0].StageName = LABEL.DES_Closed_Won;
            opportunityList[1].StageName = LABEL.DES_Closed_Won;
            opportunityList[2].StageName = LABEL.DES_Closed_Won;
            opportunityList[3].StageName = LABEL.DES_Closed_Won;
            opportunityList[4].StageName = LABEL.DES_Closed_Won;
            opportunityList[5].StageName = LABEL.DES_Closed_Won;
            opportunityList[6].StageName = LABEL.DES_Closed_Won;
            opportunityList[7].StageName = LABEL.DES_Closed_Won;
            opportunityList[8].StageName = LABEL.DES_Closed_Won;


            System.debug('opportunityList: ' + opportunityList);

            try {
                update opportunityList;
            } catch(Exception e) {
                  System.debug('Error: ' + e.getMessage());
            }
           	Opportunity oppAssert;
            oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.assertEquals(oppAssert.StageName, LABEL.DES_Approvals,'Error');
            Test.StopTest();
        }
    }



    /*
    *toCloseWonAuxTest
    */

    @isTest
    static void toClsWonAux() {
		final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
        bypassSettings.CIB_DES_DataMigration__c = true;
		insert bypassSettings;
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        //final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        //insert userSettings;

        system.runAs(userTest) {
            final Account acc = testClass.createClient();
            insert acc;

            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;

            List<Product2> productList = new List<Product2>();
            productList = createProducts(productList);


            List<PricebookEntry> prBkEntryList;
            prBkEntryList = new List<PricebookEntry>();
            prBkEntryList = createEntries1(productList, prBkEntryList);
            insert prBkEntryList;

            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = createOpps1(opportunityList, acc, LABEL.DES_Approvals);
            insert opportunityList;


            final list<OpportunityLineItem> OppLineItmList = new list<OpportunityLineItem>();


            OpportunityLineItem oppLineItem10 = testClass.createOppLineItem(opportunityList[0], productList[9], prBkEntryList[0]);
            oppLineItem10 = testClass.updateOppLineItem(oppLineItem10, userTest);
            oppLineItem10.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem10);

            OpportunityLineItem oppLineItem11 = testClass.createOppLineItem(opportunityList[1], productList[10], prBkEntryList[1]);
            oppLineItem11 = testClass.updateOppLineItem(oppLineItem11, userTest);
            oppLineItem11.solution_name_path_desc__c = null;
            oppLineItem11.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem11);

            OpportunityLineItem oppLineItem12 = testClass.createOppLineItem(opportunityList[2], productList[11], prBkEntryList[2]);
            oppLineItem12 = testClass.updateOppLineItem(oppLineItem12, userTest);
            oppLineItem12.solution_name_path_desc__c = null;
            oppLineItem12.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem12);

            OpportunityLineItem oppLineItem13 = testClass.createOppLineItem(opportunityList[3], productList[12], prBkEntryList[3]);
            oppLineItem13 = testClass.updateOppLineItem(oppLineItem13, userTest);
            oppLineItem13.customer_cib_ind_type__c = 'No';
            oppLineItem13.regional_area_name__c = null;
            oppLineItem13.classification_cib_banker_type__c = null;
            oppLineItem13.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem13);

            OpportunityLineItem oppLineItem14 = testClass.createOppLineItem(opportunityList[4], productList[13], prBkEntryList[4]);
            oppLineItem14 = testClass.updateOppLineItem(oppLineItem14, userTest);
            oppLineItem14.customer_cib_ind_type__c = 'No';
            oppLineItem14.regional_area_name__c = null;
            oppLineItem14.classification_cib_banker_type__c = null;
            oppLineItem14.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem14);

            OpportunityLineItem oppLineItem15 = testClass.createOppLineItem(opportunityList[5], productList[14], prBkEntryList[5]);
            oppLineItem15 = testClass.updateOppLineItem(oppLineItem15, userTest);
            oppLineItem15.classification_cib_banker_type__c = null;
            oppLineItem15.customer_cib_ind_type__c = 'No';
			oppLineItem15.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem15);

            OpportunityLineItem oppLineItem16 = testClass.createOppLineItem(opportunityList[6], productList[15], prBkEntryList[6]);
            oppLineItem16 = testClass.updateOppLineItem(oppLineItem16, userTest);
            oppLineItem16.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem16);

            OpportunityLineItem oppLineItem17 = testClass.createOppLineItem(opportunityList[7], productList[16], prBkEntryList[7]);
            oppLineItem17 = testClass.updateOppLineItem(oppLineItem17, userTest);
            oppLineItem17.customer_cib_ind_type__c = null;
            oppLineItem17.regional_area_name__c = null;
            oppLineItem17.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem17);

            OpportunityLineItem oppLineItem18 = testClass.createOppLineItem(opportunityList[8], productList[16], prBkEntryList[7]);
            oppLineItem18 = testClass.updateOppLineItem(oppLineItem18, userTest);
            oppLineItem18.customer_cib_ind_type__c = 'No';
            oppLineItem18.DES_Origination_Geography__c = 'USA';
            oppLineItem18.regional_area_name__c = null;
            oppLineItem18.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem18);

            OpportunityLineItem oppLineItem19 = testClass.createOppLineItem(opportunityList[9], productList[16], prBkEntryList[7]);
            oppLineItem19 = testClass.updateOppLineItem(oppLineItem19, userTest);
            oppLineItem19.customer_cib_ind_type__c = 'No';
            oppLineItem19.DES_Origination_Geography__c = 'Spain';
            oppLineItem19.regional_area_name__c = null;
            oppLineItem19.classification_cib_banker_type__c = null;

            OppLineItmList.add(oppLineItem19);
           	Test.StartTest();

            insert OppLineItmList;
            Opportunity oppUpd;
            oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            Account ac2;
            ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            insert ac2;

            oppUpd.AccountId = ac2.Id;
            update oppUpd;




            opportunityList[0].StageName = LABEL.DES_Closed_Won;
            opportunityList[1].StageName = LABEL.DES_Closed_Won;
            opportunityList[2].StageName = LABEL.DES_Closed_Won;
            opportunityList[3].StageName = LABEL.DES_Closed_Won;
            opportunityList[4].StageName = LABEL.DES_Closed_Won;
            opportunityList[5].StageName = LABEL.DES_Closed_Won;
            opportunityList[6].StageName = LABEL.DES_Closed_Won;
            opportunityList[7].StageName = LABEL.DES_Closed_Won;
            opportunityList[8].StageName = LABEL.DES_Closed_Won;
            opportunityList[9].StageName = LABEL.DES_Closed_Won;


            System.debug('opportunityList: ' + opportunityList);

            try {
                update opportunityList;
            } catch(Exception e) {
                  System.debug('Error: ' + e.getMessage());
            }
            Opportunity oppAssert;
            oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.assertEquals(oppAssert.StageName, LABEL.DES_Approvals, 'Error');

            Test.StopTest();
        }
    }

    /*
    * testToApproval
    */
    @isTest
    static void testToApvl() {
		final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
        bypassSettings.CIB_DES_DataMigration__c = true;
		insert bypassSettings;
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        //final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        //insert userSettings;

        system.runAs(userTest) {
            final Account acc = testClass.createClient();
            insert acc;

            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;

            List<Product2> productList = new List<Product2>();
            productList = createProducts(productList);

            List<PricebookEntry> prBkEntryList;
            prBkEntryList = new List<PricebookEntry>();
            prBkEntryList = createEntries(productList, prBkEntryList);
            insert prBkEntryList;

            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = createOpps(opportunityList, acc, LABEL.DES_Proposal);
            insert opportunityList;

            final list<OpportunityLineItem> OppLineItmList = new list<OpportunityLineItem>();

            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opportunityList[0], productList[0], prBkEntryList[0]);
            oppLineItem.DES_All_In__c = null;
            OppLineItmList.add(oppLineItem);

            OpportunityLineItem oppLineItem2 = testClass.createOppLineItem(opportunityList[1], productList[1], prBkEntryList[1]);
            oppLineItem2 = testClass.updateOppLineItem(oppLineItem2, userTest);
            oppLineItem2.customer_cib_ind_type__c = 'No';
            oppLineItem2.regional_area_name__c = null;
            oppLineItem2.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem2);

            OpportunityLineItem oppLineItem3 = testClass.createOppLineItem(opportunityList[2], productList[2], prBkEntryList[2]);
            oppLineItem3 = testClass.updateOppLineItem(oppLineItem3, userTest);
            oppLineItem3.classification_cib_banker_type__c = null;
            oppLineItem3.customer_cib_ind_type__c = 'No';
            oppLineItem3.regional_area_name__c = null;
            oppLineItem3.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem3);

            OpportunityLineItem oppLineItem4 = testClass.createOppLineItem(opportunityList[3], productList[3], prBkEntryList[3]);
            oppLineItem4 = testClass.updateOppLineItem(oppLineItem4, userTest);
            oppLineItem4.classification_cib_banker_type__c = null;
            oppLineItem4.customer_cib_ind_type__c = 'No';
            oppLineItem4.regional_area_name__c = null;
            oppLineItem4.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem4);

            OpportunityLineItem oppLineItem5 = testClass.createOppLineItem(opportunityList[4], productList[4], prBkEntryList[4]);
            oppLineItem5 = testClass.updateOppLineItem(oppLineItem5, userTest);
            OppLineItmList.add(oppLineItem5);

            OpportunityLineItem oppLineItem6 = testClass.createOppLineItem(opportunityList[5], productList[5], prBkEntryList[5]);
            oppLineItem6 = testClass.updateOppLineItem(oppLineItem6, userTest);
            oppLineItem6.syndicated_loan_drawn_amount__c = null;
            OppLineItmList.add(oppLineItem6);

            OpportunityLineItem oppLineItem7 = testClass.createOppLineItem(opportunityList[6], productList[6], prBkEntryList[6]);
            oppLineItem7 = testClass.updateOppLineItem(oppLineItem7, userTest);
            oppLineItem7.DES_Net_spread__c = null;
            oppLineItem7.proposal_requested_ind_type__c = null;
            oppLineItem7.loan_tenor_month_desc__c = null;
            OppLineItmList.add(oppLineItem7);

            OpportunityLineItem oppLineItem8 = testClass.createOppLineItem(opportunityList[7], productList[7], prBkEntryList[7]);
            oppLineItem8 = testClass.updateOppLineItem(oppLineItem8, userTest);
            oppLineItem8.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem8);

            OpportunityLineItem oppLineItem9 = testClass.createOppLineItem(opportunityList[8], productList[8], prBkEntryList[8]);
            oppLineItem9 = testClass.updateOppLineItem(oppLineItem9, userTest);
            oppLineItem9.solution_name_path_desc__c = null;
            OppLineItmList.add(oppLineItem9);

            insert OppLineItmList;


            Test.StartTest();

            Opportunity oppUpd;
            oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            Account ac2;
            ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            insert ac2;

            oppUpd.AccountId = ac2.Id;
            update oppUpd;



            opportunityList[0].StageName = LABEL.DES_Approvals;
            opportunityList[1].StageName = LABEL.DES_Approvals;
            opportunityList[2].StageName = LABEL.DES_Approvals;
            opportunityList[3].StageName = LABEL.DES_Approvals;
            opportunityList[4].StageName = LABEL.DES_Approvals;
            opportunityList[5].StageName = LABEL.DES_Approvals;
            opportunityList[6].StageName = LABEL.DES_Approvals;
            opportunityList[7].StageName = LABEL.DES_Approvals;
            opportunityList[8].StageName = LABEL.DES_Approvals;

            System.debug('opportunityList: ' + opportunityList);

            try {
                update opportunityList;

            } catch(Exception e) {
                  System.debug('Error: ' + e.getMessage());
            }
            Opportunity oppAssert;
            oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.assertEquals(oppAssert.StageName, LABEL.DES_Approvals, 'Error');
            Test.StopTest();
        }
    }

    @isTest
    static void testToAppAux() {
		final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
        bypassSettings.CIB_DES_DataMigration__c = true;
		insert bypassSettings;
		final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        //final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        //insert userSettings;

        system.runAs(userTest) {
            final Account acc = testClass.createClient();
            insert acc;

            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;

            List<Product2> productList = new List<Product2>();
            productList = createProducts(productList);


            List<PricebookEntry> prBkEntryList;
            prBkEntryList = new List<PricebookEntry>();
            prBkEntryList = createEntries1(productList, prBkEntryList);
            insert prBkEntryList;

            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = createOpps1(opportunityList, acc, LABEL.DES_Proposal);
            insert opportunityList;

            final list<OpportunityLineItem> OppLineItmList = new list<OpportunityLineItem>();



            OpportunityLineItem oppLineItem10 = testClass.createOppLineItem(opportunityList[0], productList[9], prBkEntryList[0]);
            oppLineItem10 = testClass.updateOppLineItem(oppLineItem10, userTest);
            oppLineItem10.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem10);

            OpportunityLineItem oppLineItem11 = testClass.createOppLineItem(opportunityList[1], productList[10], prBkEntryList[1]);
            oppLineItem11 = testClass.updateOppLineItem(oppLineItem11, userTest);
            oppLineItem11.solution_name_path_desc__c = null;
            OppLineItmList.add(oppLineItem11);

            OpportunityLineItem oppLineItem12 = testClass.createOppLineItem(opportunityList[2], productList[11], prBkEntryList[2]);
            oppLineItem12 = testClass.updateOppLineItem(oppLineItem12, userTest);
            oppLineItem12.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem12);

            OpportunityLineItem oppLineItem13 = testClass.createOppLineItem(opportunityList[3], productList[12], prBkEntryList[3]);
            oppLineItem13 = testClass.updateOppLineItem(oppLineItem13, userTest);
            oppLineItem13.entity_role_type__c = null;
            oppLineItem13.classification_cib_banker_type__c = null;
            oppLineItem13.customer_cib_ind_type__c = 'No';
            oppLineItem13.regional_area_name__c = null;
            OppLineItmList.add(oppLineItem13);

            OpportunityLineItem oppLineItem14 = testClass.createOppLineItem(opportunityList[4], productList[13], prBkEntryList[4]);
            oppLineItem14 = testClass.updateOppLineItem(oppLineItem14, userTest);
            oppLineItem14.customer_cib_ind_type__c = 'No';
            oppLineItem14.regional_area_name__c = null;
            oppLineItem14.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem14);

            OpportunityLineItem oppLineItem15 = testClass.createOppLineItem(opportunityList[5], productList[14], prBkEntryList[5]);
            oppLineItem15 = testClass.updateOppLineItem(oppLineItem15, userTest);
            oppLineItem15.classification_cib_banker_type__c = null;
            oppLineItem15.customer_cib_ind_type__c = 'No';
            oppLineItem15.regional_area_name__c = null;
            OppLineItmList.add(oppLineItem15);

            OpportunityLineItem oppLineItem16 = testClass.createOppLineItem(opportunityList[6], productList[15], prBkEntryList[6]);
            oppLineItem16 = testClass.updateOppLineItem(oppLineItem16, userTest);
            OppLineItmList.add(oppLineItem16);

            OpportunityLineItem oppLineItem17 = testClass.createOppLineItem(opportunityList[7], productList[16], prBkEntryList[7]);
            oppLineItem17 = testClass.updateOppLineItem(oppLineItem17, userTest);
            oppLineItem17.customer_cib_ind_type__c = null;
            oppLineItem17.regional_area_name__c = null;
            oppLineItem17.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem17);

            OpportunityLineItem oppLineItem18 = testClass.createOppLineItem(opportunityList[8], productList[16], prBkEntryList[7]);
            oppLineItem18 = testClass.updateOppLineItem(oppLineItem18, userTest);
            oppLineItem18.customer_cib_ind_type__c = 'No';
            oppLineItem18.DES_Origination_Geography__c = 'USA';
            oppLineItem18.regional_area_name__c = null;
            oppLineItem18.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem18);

            OpportunityLineItem oppLineItem19 = testClass.createOppLineItem(opportunityList[9], productList[16], prBkEntryList[7]);
            oppLineItem19 = testClass.updateOppLineItem(oppLineItem19, userTest);
            oppLineItem19.customer_cib_ind_type__c = 'No';
            oppLineItem19.DES_Origination_Geography__c = 'Spain';
            oppLineItem19.regional_area_name__c = null;
            oppLineItem19.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem19);

            insert OppLineItmList;
            Opportunity oppUpd;
            oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            Account ac2;
            ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            insert ac2;

			Test.StartTest();
            oppUpd.AccountId = ac2.Id;
            update oppUpd;


            opportunityList[0].StageName = LABEL.DES_Approvals;
            opportunityList[1].StageName = LABEL.DES_Approvals;
            opportunityList[2].StageName = LABEL.DES_Approvals;
            opportunityList[3].StageName = LABEL.DES_Approvals;
            opportunityList[4].StageName = LABEL.DES_Approvals;
            opportunityList[5].StageName = LABEL.DES_Approvals;
            opportunityList[6].StageName = LABEL.DES_Approvals;
            opportunityList[7].StageName = LABEL.DES_Approvals;
            opportunityList[8].StageName = LABEL.DES_Approvals;
            opportunityList[9].StageName = LABEL.DES_Approvals;

            System.debug('opportunityList: ' + opportunityList);

            try {
                update opportunityList;

            } catch(Exception e) {
                  System.debug('Error: ' + e.getMessage());
            }
            Opportunity oppAssert;
            oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.assertEquals(oppAssert.StageName, LABEL.DES_Approvals, 'Error');
            Test.StopTest();
        }
    }

    /*
    * toCloseLostTest
    */
    @isTest
    static void toCloseLostTest() {
		final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
        bypassSettings.CIB_DES_DataMigration__c = true;
		insert bypassSettings;
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        //final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        //insert userSettings;

        system.runAs(userTest) {
            final Account acc = testClass.createClient();
            insert acc;

            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;

            List<Product2> productList = new List<Product2>();
            productList = createProducts(productList);

            List<PricebookEntry> prBkEntryList;
            prBkEntryList = new List<PricebookEntry>();
            prBkEntryList = createEntries(productList, prBkEntryList);
            insert prBkEntryList;

            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = createOpps(opportunityList, acc, LABEL.DES_Approvals);
            insert opportunityList;

            final list<OpportunityLineItem> OppLineItmList = new list<OpportunityLineItem>();

            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opportunityList[0], productList[0], prBkEntryList[0]);
            oppLineItem.DES_All_In__c = null;
            oppLineItem.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem);

            OpportunityLineItem oppLineItem2 = testClass.createOppLineItem(opportunityList[1], productList[1], prBkEntryList[1]);
            oppLineItem2 = testClass.updateOppLineItem(oppLineItem2, userTest);
            oppLineItem2.classification_cib_banker_type__c = null;
            oppLineItem2.customer_cib_ind_type__c = 'No';
            oppLineItem2.regional_area_name__c = null;
            oppLineItem2.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem2);

            OpportunityLineItem oppLineItem3 = testClass.createOppLineItem(opportunityList[2], productList[2], prBkEntryList[2]);
            oppLineItem3 = testClass.updateOppLineItem(oppLineItem3, userTest);
            oppLineItem3.classification_cib_banker_type__c = null;
            oppLineItem3.customer_cib_ind_type__c = 'No';
            oppLineItem3.regional_area_name__c = null;
            oppLineItem3.DES_Booking_System__c = null;
            oppLineItem3.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem3);

            OpportunityLineItem oppLineItem4 = testClass.createOppLineItem(opportunityList[3], productList[3], prBkEntryList[3]);
            oppLineItem4 = testClass.updateOppLineItem(oppLineItem4, userTest);
            oppLineItem4.classification_cib_banker_type__c = null;
            oppLineItem4.customer_cib_ind_type__c = 'No';
            oppLineItem4.regional_area_name__c = null;
            oppLineItem4.fee_next_12m_amount__c = null;
            oppLineItem4.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem4);

            OpportunityLineItem oppLineItem5 = testClass.createOppLineItem(opportunityList[4], productList[4], prBkEntryList[4]);
            oppLineItem5 = testClass.updateOppLineItem(oppLineItem5, userTest);
            oppLineItem5.loan_tenor_month_desc__c = null;
            oppLineItem5.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem5);

            OpportunityLineItem oppLineItem6 = testClass.createOppLineItem(opportunityList[5], productList[5], prBkEntryList[5]);
            oppLineItem6 = testClass.updateOppLineItem(oppLineItem6, userTest);
            oppLineItem6.DES_Booking_Office__c = null;
            oppLineItem6.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem6);

            OpportunityLineItem oppLineItem7 = testClass.createOppLineItem(opportunityList[6], productList[6], prBkEntryList[6]);
            oppLineItem7 = testClass.updateOppLineItem(oppLineItem7, userTest);
            oppLineItem7.DES_Net_spread__c = null;
            oppLineItem7.proposal_requested_ind_type__c = null;
            oppLineItem7.pre_oppy_revenue_next_12m_amount__c = null;
            oppLineItem7.loan_tenor_month_desc__c = null;
            OppLineItmList.add(oppLineItem7);

            OpportunityLineItem oppLineItem8 = testClass.createOppLineItem(opportunityList[7], productList[7], prBkEntryList[7]);
            oppLineItem8 = testClass.updateOppLineItem(oppLineItem8, userTest);
            oppLineItem8.signing_date__c = null;
            oppLineItem8.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem8);

            OpportunityLineItem oppLineItem9 = testClass.createOppLineItem(opportunityList[8], productList[8], prBkEntryList[8]);
            oppLineItem9 = testClass.updateOppLineItem(oppLineItem9, userTest);
            oppLineItem9.solution_name_path_desc__c = null;
            oppLineItem9.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem9);

            Test.StartTest();

            insert OppLineItmList;
            Opportunity oppUpd;
            oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            Account ac2;
            ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            insert ac2;

            oppUpd.AccountId = ac2.Id;
            update oppUpd;



            opportunityList[0].StageName = LABEL.DES_Closed_Lose;
            opportunityList[1].StageName = LABEL.DES_Closed_Lose;
            opportunityList[2].StageName = LABEL.DES_Closed_Lose;
            opportunityList[3].StageName = LABEL.DES_Closed_Lose;
            opportunityList[4].StageName = LABEL.DES_Closed_Lose;
            opportunityList[5].StageName = LABEL.DES_Closed_Lose;
            opportunityList[6].StageName = LABEL.DES_Closed_Lose;
            opportunityList[7].StageName = LABEL.DES_Closed_Lose;
            opportunityList[8].StageName = LABEL.DES_Closed_Lose;


            System.debug('opportunityList: ' + opportunityList);

            try {
                update opportunityList;

            } catch(Exception e) {
                  System.debug('Error ' + e.getMessage());
            }
            Opportunity oppAssert;
            oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.assertEquals(oppAssert.StageName, LABEL.DES_Approvals, 'Error');

            Test.StopTest();
        }
    }

    @isTest
    static void toClLstAux() {
		final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
        bypassSettings.CIB_DES_DataMigration__c = true;
		insert bypassSettings;
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        //final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        //insert userSettings;

        system.runAs(userTest) {
            final Account acc = testClass.createClient();
            insert acc;

            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;
			Test.StartTest();
            List<Product2> productList = new List<Product2>();
            productList = createProducts(productList);


            List<PricebookEntry> prBkEntryList;
            prBkEntryList = new List<PricebookEntry>();
            prBkEntryList = createEntries1(productList, prBkEntryList);
            insert prBkEntryList;

            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = createOpps1(opportunityList, acc, LABEL.DES_Approvals);
            insert opportunityList;

            final list<OpportunityLineItem> OppLineItmList = new list<OpportunityLineItem>();


            OpportunityLineItem oppLineItem10 = testClass.createOppLineItem(opportunityList[0], productList[9], prBkEntryList[0]);
            oppLineItem10 = testClass.updateOppLineItem(oppLineItem10, userTest);
            oppLineItem10.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem10);

            OpportunityLineItem oppLineItem11 = testClass.createOppLineItem(opportunityList[1], productList[10], prBkEntryList[1]);
            oppLineItem11 = testClass.updateOppLineItem(oppLineItem11, userTest);
            oppLineItem11.solution_name_path_desc__c = null;
            oppLineItem11.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem11);

            OpportunityLineItem oppLineItem12 = testClass.createOppLineItem(opportunityList[2], productList[11], prBkEntryList[2]);
            oppLineItem12 = testClass.updateOppLineItem(oppLineItem12, userTest);
            oppLineItem12.solution_name_path_desc__c = null;
            oppLineItem12.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem12);

            OpportunityLineItem oppLineItem13 = testClass.createOppLineItem(opportunityList[3], productList[12], prBkEntryList[3]);
            oppLineItem13 = testClass.updateOppLineItem(oppLineItem13, userTest);
            oppLineItem13.classification_cib_banker_type__c = null;
            oppLineItem13.customer_cib_ind_type__c = 'No';
            oppLineItem13.regional_area_name__c = null;
            oppLineItem13.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem13);

            OpportunityLineItem oppLineItem14 = testClass.createOppLineItem(opportunityList[4], productList[13], prBkEntryList[4]);
            oppLineItem14 = testClass.updateOppLineItem(oppLineItem14, userTest);
            oppLineItem14.customer_cib_ind_type__c = 'No';
            oppLineItem14.regional_area_name__c = null;
            oppLineItem14.classification_cib_banker_type__c = null;
            oppLineItem14.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem14);

            
            insert OppLineItmList;
            Test.StopTest();
            Opportunity oppUpd;
            oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            Account ac2;
            ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            insert ac2;

            oppUpd.AccountId = ac2.Id;
            
            update oppUpd;
            




            opportunityList[0].StageName = LABEL.DES_Closed_Lose;
            opportunityList[1].StageName = LABEL.DES_Closed_Lose;
            opportunityList[2].StageName = LABEL.DES_Closed_Lose;
            opportunityList[3].StageName = LABEL.DES_Closed_Lose;
            opportunityList[4].StageName = LABEL.DES_Closed_Lose;

            System.debug('opportunityList: ' + opportunityList);

            try {
                update opportunityList;

            } catch(Exception e) {
                  System.debug('Error ' + e.getMessage());
            }
            Opportunity oppAssert;
            oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            system.assertEquals(oppAssert.StageName, LABEL.DES_Approvals, 'Error');
            
        }
    }

    /*
    *toCloseLostAux2Test
    */
    @isTest
    static void toClLstAux2() {
		final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
        bypassSettings.CIB_DES_DataMigration__c = true;
		insert bypassSettings;
    	final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        insert userTest;
        //final CIB_User_Org__c userSettings = testClass.createCustomSetting();
        //insert userSettings;

        system.runAs(userTest) {
            final Account acc = testClass.createClient();
            insert acc;

            final List<DES_BBVA_Management_team__c> listaBBVAMT = new List<DES_BBVA_Management_team__c>();
            final DES_BBVA_Management_team__c bbvaMT = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT);
            final DES_BBVA_Management_team__c bbvaMT2 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT2);
            final DES_BBVA_Management_team__c bbvaMT3 = testClass.createBBVAManagementTeamMember(userTest, acc);
            listaBBVAMT.add(bbvaMT3);
            insert listaBBVAMT;

            List<Product2> productList = new List<Product2>();
            productList = createProducts(productList);


            List<PricebookEntry> prBkEntryList;
            prBkEntryList = new List<PricebookEntry>();
            prBkEntryList = createEntries1(productList, prBkEntryList);
            insert prBkEntryList;

            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = createOpps1(opportunityList, acc, LABEL.DES_Approvals);
            insert opportunityList;

            final list<OpportunityLineItem> OppLineItmList = new list<OpportunityLineItem>();

    		OpportunityLineItem oppLineItem15 = testClass.createOppLineItem(opportunityList[5], productList[14], prBkEntryList[5]);
            oppLineItem15 = testClass.updateOppLineItem(oppLineItem15, userTest);
            oppLineItem15.classification_cib_banker_type__c = null;
            oppLineItem15.customer_cib_ind_type__c = 'No';
			oppLineItem15.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem15);

            OpportunityLineItem oppLineItem16 = testClass.createOppLineItem(opportunityList[6], productList[15], prBkEntryList[6]);
            oppLineItem16 = testClass.updateOppLineItem(oppLineItem16, userTest);
            oppLineItem16.pre_oppy_revenue_next_12m_amount__c = null;
            OppLineItmList.add(oppLineItem16);

            OpportunityLineItem oppLineItem17 = testClass.createOppLineItem(opportunityList[7], productList[16], prBkEntryList[7]);
            oppLineItem17 = testClass.updateOppLineItem(oppLineItem17, userTest);
            oppLineItem17.customer_cib_ind_type__c = null;
            oppLineItem17.regional_area_name__c = null;
            oppLineItem17.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem17);

            OpportunityLineItem oppLineItem18 = testClass.createOppLineItem(opportunityList[8], productList[16], prBkEntryList[7]);
            oppLineItem18 = testClass.updateOppLineItem(oppLineItem18, userTest);
            oppLineItem18.customer_cib_ind_type__c = 'No';
            oppLineItem18.DES_Origination_Geography__c = 'USA';
            oppLineItem18.regional_area_name__c = null;
            oppLineItem18.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem18);

            OpportunityLineItem oppLineItem19 = testClass.createOppLineItem(opportunityList[9], productList[16], prBkEntryList[7]);
            oppLineItem19 = testClass.updateOppLineItem(oppLineItem19, userTest);
            oppLineItem19.customer_cib_ind_type__c = 'No';
            oppLineItem19.DES_Origination_Geography__c = 'Spain';
            oppLineItem19.regional_area_name__c = null;
            oppLineItem19.classification_cib_banker_type__c = null;
            OppLineItmList.add(oppLineItem19);

            
            insert OppLineItmList;
            Opportunity oppUpd;
            oppUpd = [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];
            Account ac2;
            ac2 = testClass.createClient();
            ac2.Name = 'Cuenta TEST 2';
            insert ac2;
            Test.StartTest();
            oppUpd.AccountId = ac2.Id;
            update oppUpd;




            opportunityList[5].StageName = LABEL.DES_Closed_Lose;
            opportunityList[6].StageName = LABEL.DES_Closed_Lose;
            opportunityList[7].StageName = LABEL.DES_Closed_Lose;
            opportunityList[8].StageName = LABEL.DES_Closed_Lose;
            opportunityList[9].StageName = LABEL.DES_Closed_Lose;

            System.debug('opportunityList: ' + opportunityList);

            try {
                update opportunityList;

            } catch(Exception e) {
                  System.debug('Error ' + e.getMessage());
            }
            Opportunity oppAssert;
            oppAssert = [SELECT Id, StageName FROM Opportunity WHERE Id = :opportunityList.get(0).Id LIMIT 1];

            system.assertEquals(oppAssert.StageName, LABEL.DES_Approvals);
            Test.StopTest();
        }
    }


     public static List<Product2> createProducts(List<Product2> productList) {
    	final DES_UtilTestClass testClass = new DES_UtilTestClass();
		final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();
        bypassSettings.CIB_DES_DataMigration__c = true;
		insert bypassSettings;
		final Product2 prod = testClass.createProduct(LABEL.DES_Cash_Management);
        productList.add(prod);
        final Product2 prod2 = testClass.createProduct(LABEL.DES_Corporate_Loans);
        productList.add(prod2);
        final Product2 prod3 = testClass.createProduct(Label.DES_Project_Finance_Lending);
        productList.add(prod3);
        final Product2 prod4 = testClass.createProduct(Label.DES_Project_Finance_Advisory);
        productList.add(prod4);
        final Product2 prod5 = testClass.createProduct(LABEL.DES_Client_Resources);
        productList.add(prod5);
        final Product2 prod6 = testClass.createProduct(LABEL.DES_Transaction_Trade_Finance);
        productList.add(prod6);
        final Product2 prod7 = testClass.createProduct(LABEL.DES_Working_Capital);
        productList.add(prod7);
        final Product2 prod8 = testClass.createProduct(LABEL.DES_Securities_Services);
        productList.add(prod8);
        final Product2 prod9 = testClass.createProduct(LABEL.DES_Rates);
        productList.add(prod9);
        final Product2 prod10 = testClass.createProduct(LABEL.DES_Equity);
        productList.add(prod10);
        final Product2 prod11 = testClass.createProduct(LABEL.DES_FX);
        productList.add(prod11);
        final Product2 prod12 = testClass.createProduct(LABEL.DES_Credit);
        productList.add(prod12);
        final Product2 prod13 = testClass.createProduct(LABEL.DES_Debt_Capital_Markets);
        productList.add(prod13);
        final Product2 prod14 = testClass.createProduct(LABEL.DES_Equity_Capital_Markets);
        productList.add(prod14);
        final Product2 prod15 = testClass.createProduct(LABEL.DES_Mergers_Acquisitions);
        productList.add(prod15);
        final Product2 prod16 = testClass.createProduct(LABEL.DES_Structure_Trade_Finance);
        productList.add(prod16);
        final Product2 prod17 = testClass.createProduct(LABEL.DES_Leverage_Buyout_LBOs);
        productList.add(prod17);
		insert productList;
        return productList;
    }


    public static List<PricebookEntry> createEntries(List<Product2> productList, List<PricebookEntry> prBkEntryList) {
    	final DES_UtilTestClass testClass = new DES_UtilTestClass();
    	final PricebookEntry pbEntryTest = testClass.createPricebookEntry(productList[0]);
        prBkEntryList.add(pbEntryTest);
        final PricebookEntry pbEntryTest2 = testClass.createPricebookEntry(productList[1]);
        prBkEntryList.add(pbEntryTest2);
        final PricebookEntry pbEntryTest3 = testClass.createPricebookEntry(productList[2]);
        prBkEntryList.add(pbEntryTest3);
        final PricebookEntry pbEntryTest4 = testClass.createPricebookEntry(productList[3]);
        prBkEntryList.add(pbEntryTest4);
        final PricebookEntry pbEntryTest5 = testClass.createPricebookEntry(productList[4]);
        prBkEntryList.add(pbEntryTest5);
        final PricebookEntry pbEntryTest6 = testClass.createPricebookEntry(productList[5]);
        prBkEntryList.add(pbEntryTest6);
        final PricebookEntry pbEntryTest7 = testClass.createPricebookEntry(productList[6]);
        prBkEntryList.add(pbEntryTest7);
        final PricebookEntry pbEntryTest8 = testClass.createPricebookEntry(productList[7]);
        prBkEntryList.add(pbEntryTest8);
        final PricebookEntry pbEntryTest9 = testClass.createPricebookEntry(productList[8]);
        prBkEntryList.add(pbEntryTest9);

        return prBkEntryList;
    }
     public static List<PricebookEntry> createEntries1(List<Product2> productList, List<PricebookEntry> prBkEntryList) {
    	final DES_UtilTestClass testClass = new DES_UtilTestClass();

        final PricebookEntry pricebookEntryTest10 = testClass.createPricebookEntry(productList[9]);
        prBkEntryList.add(pricebookEntryTest10);
        final PricebookEntry pricebookEntryTest11 = testClass.createPricebookEntry(productList[10]);
        prBkEntryList.add(pricebookEntryTest11);
        final PricebookEntry pricebookEntryTest12 = testClass.createPricebookEntry(productList[11]);
        prBkEntryList.add(pricebookEntryTest12);
        final PricebookEntry pricebookEntryTest13 = testClass.createPricebookEntry(productList[12]);
        prBkEntryList.add(pricebookEntryTest13);
        final PricebookEntry pricebookEntryTest14 = testClass.createPricebookEntry(productList[13]);
        prBkEntryList.add(pricebookEntryTest14);
        final PricebookEntry pricebookEntryTest15 = testClass.createPricebookEntry(productList[14]);
        prBkEntryList.add(pricebookEntryTest15);
        final PricebookEntry pricebookEntryTest16 = testClass.createPricebookEntry(productList[15]);
        prBkEntryList.add(pricebookEntryTest16);
        final PricebookEntry pricebookEntryTest17 = testClass.createPricebookEntry(productList[16]);
        prBkEntryList.add(pricebookEntryTest17);

        return prBkEntryList;
    }

    public static List<Opportunity> createOpps(List<Opportunity> opportunityList, Account acc, String stage) {
    	final DES_UtilTestClass testClass = new DES_UtilTestClass();

        final Opportunity opp = testClass.createOpportunity(acc);
        final Opportunity opp2 = testClass.createOpportunity(acc);
        final Opportunity opp3 = testClass.createOpportunity(acc);
        final Opportunity opp4 = testClass.createOpportunity(acc);
        final Opportunity opp5 = testClass.createOpportunity(acc);
        final Opportunity opp6 = testClass.createOpportunity(acc);
        final Opportunity opp7 = testClass.createOpportunity(acc);
        final Opportunity opp8 = testClass.createOpportunity(acc);
        final Opportunity opp9 = testClass.createOpportunity(acc);

        if(stage != null) {
        	opp.StageName = stage;
        	opp2.StageName = stage;
        	opp3.StageName = stage;
        	opp4.StageName = stage;
        	opp5.StageName = stage;
        	opp6.StageName = stage;
        	opp7.StageName = stage;
        	opp8.StageName = stage;
        	opp9.StageName = stage;
        }
        opportunityList.add(opp);
        opportunityList.add(opp2);
        opportunityList.add(opp3);
        opportunityList.add(opp4);
        opportunityList.add(opp5);
        opportunityList.add(opp6);
        opportunityList.add(opp7);
        opportunityList.add(opp8);
        opportunityList.add(opp9);

        return opportunityList;
    }

     public static List<Opportunity> createOpps1(List<Opportunity> opportunityList, Account acc, String stage) {
    	final DES_UtilTestClass testClass = new DES_UtilTestClass();

        final Opportunity opp10 = testClass.createOpportunity(acc);
        final Opportunity opp11 = testClass.createOpportunity(acc);
        final Opportunity opp12 = testClass.createOpportunity(acc);
        final Opportunity opp13 = testClass.createOpportunity(acc);
        final Opportunity opp14 = testClass.createOpportunity(acc);
        final Opportunity opp15 = testClass.createOpportunity(acc);
        final Opportunity opp16 = testClass.createOpportunity(acc);
        final Opportunity opp17 = testClass.createOpportunity(acc);
        final Opportunity opp18 = testClass.createOpportunity(acc);
        final Opportunity opp19 = testClass.createOpportunity(acc);

        if(stage != null) {
        	opp10.StageName = stage;
        	opp11.StageName = stage;
        	opp12.StageName = stage;
        	opp13.StageName = stage;
        	opp14.StageName = stage;
        	opp15.StageName = stage;
        	opp16.StageName = stage;
        	opp17.StageName = stage;
        	opp18.StageName = stage;
        	opp19.StageName = stage;
        }

        opportunityList.add(opp10);
        opportunityList.add(opp11);
        opportunityList.add(opp12);
        opportunityList.add(opp13);
        opportunityList.add(opp14);
        opportunityList.add(opp15);
        opportunityList.add(opp16);
        opportunityList.add(opp17);
        opportunityList.add(opp18);
        opportunityList.add(opp19);

        return opportunityList;
    }

}