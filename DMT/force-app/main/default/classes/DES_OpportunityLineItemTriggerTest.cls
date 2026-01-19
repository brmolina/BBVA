@isTest
public class DES_OpportunityLineItemTriggerTest {

    /*
    * String para comprobaciones
    */
    static final String CAMPO = 'Cash Management';

    /******************************************************************************
    *@author: VASS
    *@Method: testTrigger1
    *@Description: Test Method trigger
    *@Returns: void
    *@Versions:
          - v1 - 23/01/2019 - Initial version
    ******************************************************************************/
    @isTest
    static void testTrigger() {
        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings;
        userSettings = testClass.createCustomSetting();
        insert userSettings;
      
        system.runAs(userTest) {
            Account acc;
            acc = testClass.createClient();
            insert acc;  
            Product2 prod;
            prod = testClass.createProduct('Cash Management');
            insert prod; 
            PricebookEntry pbEntryTest;
            pbEntryTest = testClass.createPricebookEntry(prod);
            insert pbEntryTest;  
            Opportunity opp;
            opp = testClass.createOpportunity(acc);
            insert opp;               
            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opp, prod, pbEntryTest);
            insert oppLineItem;
            OpportunityTeamMember oppTeamMemberTest;
            oppTeamMemberTest = testClass.oppTeamMember(opp,userTest);
            insert oppTeamMemberTest;
            
            Test.StartTest();
            oppLineItem.pre_oppy_revenue_next_12m_amount__c = 5;
            update oppLineItem;
            oppLineItem.pre_oppy_revenue_next_12m_amount__c = null;
            update oppLineItem;
            delete oppLineItem;
            system.assertEquals(oppLineItem.pre_oppy_revenue_next_12m_amount__c,null,'Error');
            Test.StopTest();
        }
    }
    
    /******************************************************************************
    *@author: VASS
    *@Method: testTrigger1
    *@Description: Test Method for setPcklstDecisionTaken in DES_sumRevenueOpportunityTriggerHandler
    *@Returns: void
    *@Versions:
          - v1 - 23/01/2019 - Initial version
    ******************************************************************************/
    @isTest
    static void testTrigger1() {
        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings;
        userSettings = testClass.createCustomSetting();
        insert userSettings;

        system.runAs(userTest) {
            final List<OpportunityLineItem> oppliToUpdate = new List<OpportunityLineItem>();
            final List<Opportunity> oppsToInsert = new List<Opportunity>();
            final List<OpportunityLineItem> oppliToInsert = new List<OpportunityLineItem>();

            Account acc;
            acc = testClass.createClient();
            insert acc;

            Product2 prod;
            prod = testClass.createProduct(LABEL.DES_Corporate_Loans);
            insert prod;

            PricebookEntry pbEntryTest;
            pbEntryTest = testClass.createPricebookEntry(prod);
            insert pbEntryTest;

            Opportunity opp; 
            opp = testClass.createOpportunity(acc);
            Opportunity opp2;
            opp2 = testClass.createOpportunity(acc);

            oppsToInsert.add(opp);
            oppsToInsert.add(opp2);
            insert oppsToInsert;

            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opp, prod, pbEntryTest);
            OpportunityLineItem oppLineItem2;
            oppLineItem2  = testClass.createOppLineItem(opp2, prod, pbEntryTest);

            oppliToInsert.add(oppLineItem);
            oppliToInsert.add(oppLineItem2);
            insert oppliToInsert;

            Test.StartTest();
            oppLineItem.opportunity_nbc_recm_ind_type__c = label.NBC_DECISION_N_A;
            oppLineItem2.opportunity_nbc_recm_ind_type__c = label.NBC_DECISION_N_A;
            oppliToUpdate.add(oppLineItem);
            oppliToUpdate.add(oppLineItem2);
            update oppliToUpdate;

            system.assertEquals(oppliToUpdate.get(0).opportunity_nbc_recm_ind_type__c, label.NBC_DECISION_N_A, 'Assert NA');
            Test.StopTest();
        }
    }

     /******************************************************************************
    *@author: VASS
    *@Method: fillOppPrductsTest
    *@Description: Test Method for fillOppPrducts in DES_relatedProductsTriggerHandler
    *@Returns: void
    *@Versions:
          - v1 - 13/12/2019 - Initial version
    ******************************************************************************/
    @isTest
    static void fillOppPrductsTest() {

        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings;
        userSettings = testClass.createCustomSetting();
        insert userSettings;
        Boolean correcto = false;
        Boolean correcto2 = false;
        Boolean def = false;
        system.runAs(userTest) {
            final Opportunity opp = datos();
            List<Opportunity> lstOpp;
            lstOpp = [SELECT id, gf_opportunity_product_desc__c  FROM Opportunity WHERE id = : opp.Id LIMIT 1];
            system.debug('--------------------->'+lstOpp[0].gf_opportunity_product_desc__c );
            if(lstOpp[0].gf_opportunity_product_desc__c .contains(CAMPO)&&lstOpp[0].gf_opportunity_product_desc__c .contains('Corporate Loans')) {
                correcto = true;
            }
            List<OpportunityLineItem> lstOppLineIt;
            lstOppLineIt = [SELECT id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId = :opp.id LIMIT 2];
            system.debug('---------------------->'+lstOppLineIt);
            if(!lstOppLineIt.isEmpty()) {
                final OpportunityLineItem elim = lstOppLineIt[0];
                delete elim;
            }
            List<Opportunity> lstOppElim;
            lstOppElim = [SELECT id, gf_opportunity_product_desc__c  FROM Opportunity WHERE id = : opp.Id LIMIT 1];
            if(lstOppElim[0].gf_opportunity_product_desc__c .contains(CAMPO) || lstOppElim[0].gf_opportunity_product_desc__c .contains('Corporate Loans')) {
                correcto2 = true;
            }
            if(correcto && correcto2) {
                def = true;
            }
            system.Assert(def, 'msg');
        }
    }

     /******************************************************************************
    *@author: VASS
    *@Method: fillOppPrductsTest
    *@Description: Test Method for fillOppPrducts datos in DES_relatedProductsTriggerHandler
    *@Returns: Opportunity opp
    *@Versions:
          - v1 - 19/12/2019 - Initial version
    ******************************************************************************/
    public static Opportunity datos() {
        Test.startTest();
        List<OpportunityLineItem> lstOppLine;
        lstOppLine = new List<OpportunityLineItem>();
        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        Account acc;
        acc = testClass.createClient();
        insert acc;
        Product2 prod;
        prod = testClass.createProduct(CAMPO);
        insert prod;
        Product2 prod2;
        prod2 = testClass.createProduct('Corporate Loans');
        insert prod2;
        PricebookEntry pbEntryTest;
        pbEntryTest = testClass.createPricebookEntry(prod);
        insert pbEntryTest;
        PricebookEntry pbEntryTest2;
        pbEntryTest2 = testClass.createPricebookEntry(prod2);
        insert pbEntryTest2;
        Opportunity opp;
        opp = testClass.createOpportunity(acc);
        insert opp;
        OpportunityLineItem oppLineItem;
        oppLineItem = testClass.createOppLineItem(opp, prod, pbEntryTest);
        OpportunityLineItem oppLineItem2;
        lstOppLine.add(oppLineItem);
        oppLineItem2  = testClass.createOppLineItem(opp, prod2, pbEntryTest2);
        lstOppLine.add(oppLineItem2);
        insert lstOppLine;
        Test.stopTest();
        return opp;
    }


    /******************************************************************************
    *@author: VASS
    *@Method: testFillBbvaPartiPerUpdateYes
    *@Description: Test Method trigger "fillBbvaParticipationPer(Map<Id,OpportunityLineItem> mapOppliNew, Map<Id,OpportunityLineItem> mapOppliOld)"
    *@Returns: void
    *@Versions:
          - v1 - 21/10/2020 - Initial version
          - v2 - 27/10/2020 - Formula fix
    ******************************************************************************/
    @isTest
    static void testFillBbvaPartiPerUpdateYes() {
        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings;
        userSettings = testClass.createCustomSetting();
        insert userSettings;
      
        system.runAs(userTest) {
            Account acc;
            acc = testClass.createClient();
            insert acc;  
            Product2 prod;
            prod = testClass.createProduct('Cash Management');
            insert prod; 
            PricebookEntry pbEntryTest;
            pbEntryTest = testClass.createPricebookEntry(prod);
            insert pbEntryTest;  
            Opportunity opp;
            opp = testClass.createOpportunity(acc);
            insert opp;               
            
            
            Test.StartTest();
            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opp, prod, pbEntryTest);
            oppLineItem.underwriting_agreement_type__c = 'Yes';
            oppLineItem.bbva_prtcp_tranche_amount__c = 500;
            oppLineItem.deal_total_amount__c = 1000;
            insert oppLineItem;

            oppLineItem.bbva_prtcp_tranche_amount__c = 1;
            oppLineItem.deal_total_amount__c = 2;
            update oppLineItem;
            oppLineItem = [SELECT Id, underwriting_agreement_type__c,bbva_participation_per__c, bbva_prtcp_tranche_amount__c, deal_total_amount__c FROM OpportunityLineItem LIMIT 1];
            system.assertEquals(50,oppLineItem.bbva_participation_per__c,'Error bbva_participation_per__c must be 50%');
            Test.StopTest();
        }
    }

    /******************************************************************************
    *@author: VASS
    *@Method: testFillBbvaPartiPerUpdate
    *@Description: Test Method trigger "fillBbvaParticipationPer(Map<Id,OpportunityLineItem> mapOppliNew, Map<Id,OpportunityLineItem> mapOppliOld)"
    *@Returns: void
    *@Versions:
          - v1 - 21/10/2020 - Initial version
          - v2 - 27/10/2020 - Formula fix
    ******************************************************************************/
    @isTest
    static void testFillBbvaPartiPerUpdate() {
        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings;
        userSettings = testClass.createCustomSetting();
        insert userSettings;
      
        system.runAs(userTest) {
            Account acc;
            acc = testClass.createClient();
            insert acc;  
            Product2 prod;
            prod = testClass.createProduct('Cash Management');
            insert prod; 
            PricebookEntry pbEntryTest;
            pbEntryTest = testClass.createPricebookEntry(prod);
            insert pbEntryTest;  
            Opportunity opp;
            opp = testClass.createOpportunity(acc);
            insert opp;               
            
            
            Test.StartTest();
            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opp, prod, pbEntryTest);
            oppLineItem.underwriting_agreement_type__c = 'Yes';
            oppLineItem.bbva_prtcp_tranche_amount__c = 500;
            oppLineItem.deal_total_amount__c = 1000;
            insert oppLineItem;

            oppLineItem.underwriting_agreement_type__c = 'Deal not materialised';
            oppLineItem.bbva_prtcp_tranche_amount__c = 500;
            oppLineItem.deal_total_amount__c = 700;
            update oppLineItem;
            oppLineItem = [SELECT Id, underwriting_agreement_type__c,bbva_participation_per__c, bbva_prtcp_tranche_amount__c, deal_total_amount__c FROM OpportunityLineItem LIMIT 1];
            system.assertEquals(100,oppLineItem.bbva_participation_per__c,'Error bbva_participation_per__c must be 100%');
            Test.StopTest();
        }
    }

     /******************************************************************************
    *@author: VASS
    *@Method: testFillBbvaPartiPerInsert
    *@Description: Test Method trigger "fillBbvaParticipationPer(Map<Id,OpportunityLineItem> mapOppliNew)"
    *@Returns: void
    *@Versions:
          - v1 - 28/10/2020 - Initial version
    ******************************************************************************/
    @isTest
    static void testFillBbvaPartiPerInsert() {
        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings;
        userSettings = testClass.createCustomSetting();
        insert userSettings;
      
        system.runAs(userTest) {
            Account acc;
            acc = testClass.createClient();
            insert acc;  
            Product2 prod;
            prod = testClass.createProduct('Cash Management');
            insert prod; 
            PricebookEntry pbEntryTest;
            pbEntryTest = testClass.createPricebookEntry(prod);
            insert pbEntryTest;  
            Opportunity opp;
            opp = testClass.createOpportunity(acc);
            insert opp;               
            
            
            Test.StartTest();
            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opp, prod, pbEntryTest);
            oppLineItem.underwriting_agreement_type__c = 'Yes';
            oppLineItem.bbva_prtcp_tranche_amount__c = 500;
            oppLineItem.deal_total_amount__c = 1000;
            
            insert oppLineItem;
            oppLineItem = [SELECT Id, underwriting_agreement_type__c,bbva_participation_per__c, bbva_prtcp_tranche_amount__c, deal_total_amount__c FROM OpportunityLineItem LIMIT 1];
            system.assertEquals(50,oppLineItem.bbva_participation_per__c,'Error bbva_participation_per__c must be 50%');
            Test.StopTest();
        }
    }

     /******************************************************************************
    *@author: VASS
    *@Method: testFillFinalAllocation
    *@Description: Test Method trigger "fillFinalAllocation(Map<Id,OpportunityLineItem> mapOppliNew, Map<Id,OpportunityLineItem> mapOppliOld)"
    *@Returns: void
    *@Versions:
          - v1 - 27/11/2020 - Initial version
    ******************************************************************************/
    @isTest
    static void testFillFinalAllocation() {
        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings;
        userSettings = testClass.createCustomSetting();
        insert userSettings;
      
        system.runAs(userTest) {
            Account acc;
            acc = testClass.createClient();
            insert acc;  
            Product2 prod;
            prod = testClass.createProduct('Cash Management');
            insert prod; 
            PricebookEntry pbEntryTest;
            pbEntryTest = testClass.createPricebookEntry(prod);
            insert pbEntryTest;  
            Opportunity opp;
            opp = testClass.createOpportunity(acc);
            insert opp;               
            
            
            Test.StartTest();
            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opp, prod, pbEntryTest);
            oppLineItem.underwriting_agreement_type__c = 'Best Efforts';
            oppLineItem.gf_synd_fnl_primry_allc_amount__c = null;
            oppLineItem.bbva_prtcp_tranche_amount__c = null;
            insert oppLineItem;
            
            oppLineItem.bbva_prtcp_tranche_amount__c = 5000;
            update oppLineItem;
            
            oppLineItem = [SELECT Id, gf_synd_fnl_primry_allc_amount__c FROM OpportunityLineItem LIMIT 1];
            system.assertEquals(5000,oppLineItem.gf_synd_fnl_primry_allc_amount__c,'Error gf_synd_fnl_primry_allc_amount__c must be 5000');
            Test.StopTest();
        }
    }


      /******************************************************************************
    *@author: VASS
    *@Method: 
    *@Description: Test Method trigger "fillAmountToBeSold(Trigger.newMap,Trigger.oldMap)"
    *@Returns: void
    *@Versions:
          - v1 - 27/11/2020 - Initial version
    ******************************************************************************/
    @isTest
    static void testFillAmountToBeSold() {
        DES_UtilTestClass testClass;
        testClass = new DES_UtilTestClass();
        String idProfile;
        idProfile = testClass.createProfile();
        User userTest;
        userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings;
        userSettings = testClass.createCustomSetting();
        insert userSettings;
      
        system.runAs(userTest) {
            Account acc;
            acc = testClass.createClient();
            insert acc;  
            Product2 prod;
            prod = testClass.createProduct('Cash Management');
            insert prod; 
            PricebookEntry pbEntryTest;
            pbEntryTest = testClass.createPricebookEntry(prod);
            insert pbEntryTest;  
            Opportunity opp;
            opp = testClass.createOpportunity(acc);
            insert opp;               
            
            
            Test.StartTest();
            OpportunityLineItem oppLineItem;
            oppLineItem = testClass.createOppLineItem(opp, prod, pbEntryTest);
            insert oppLineItem;
        
            oppLineItem.underwriting_agreement_type__c = 'Deal not materialised';
            oppLineItem.underwriting_amount__c = null;
            oppLineItem.gf_synd_fnl_primry_allc_amount__c = 50000;
            oppLineItem.syndicated_loan_drawn_amount__c = 5000;
            final Decimal output = oppLineItem.gf_synd_fnl_primry_allc_amount__c - oppLineItem.syndicated_loan_drawn_amount__c;
            update oppLineItem;
            
            oppLineItem = [SELECT Id, underwriting_amount__c FROM OpportunityLineItem LIMIT 1];
            system.assertEquals(output,oppLineItem.underwriting_amount__c,'Error underwriting_amount__c must be 45000');
            Test.StopTest();
        }
    }
}