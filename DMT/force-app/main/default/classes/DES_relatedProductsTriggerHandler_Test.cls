/**********************************************************************************
* @author       Global Desktop
* @date         04/02/2020
* @description  Clase de test para la clase DES_relatedProductsTriggerHandler
* @Revision
**********************************************************************************/
@isTest
public with sharing class DES_relatedProductsTriggerHandler_Test {

    /* Variable para diferenciar producto Channels en producto Cash Management */
    private static final Integer CINCO = 5;

    /* Variable para diferenciar producto Channels en producto Cash Management */
    private static final Integer TRES = 3;
    /*
    *   @author Global Desktop
    **/
    @isTest
    public static void newProductsGFTest() {
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
            final List<fprd__GBL_Product_version__c> prodVer = initializeProdVersion();
            Account acc;
            acc = testClass.createClient();
            insert acc;
            final List<Product2> lstprod = initializeProducto(testClass);
            final List<PricebookEntry> pbEntryTest = initializePricebook(lstprod, testClass);
            Opportunity opp;
            opp = testClass.createOpportunity(acc);
            insert opp;
            final List<OpportunityLineItem> lstOppLT = initializeOppLI(lstprod, opp, pbEntryTest, prodVer, testClass);
            OpportunityTeamMember oppTeamMemberTest;
            oppTeamMemberTest = testClass.oppTeamMember(opp,userTest);
            insert oppTeamMemberTest;


            Test.StartTest();
            List<OpportunityLineItem> lstOppUpdate;
            lstOppUpdate = new List<OpportunityLineItem>();
            for(OpportunityLineItem opplt : lstOppLT) {
            	opplt.fee_next_12m_amount__c = CINCO;
                system.debug('Product2Id-------------------->'+opplt.Product2Id);
                lstOppUpdate.add(opplt);
            }
            system.debug('lstOppLT ANTES UPDATE------------------>'+lstOppUpdate);
            update lstOppUpdate;
            boolean igual = false;
            Integer cont = 0;
            final List<OpportunityLineItem> oppLT = [SELECT pre_oppy_revenue_next_12m_amount__c, Product2Id FROM OpportunityLineItem LIMIT 3];
            system.debug('opplt0-------------------->'+oppLT[0].Product2Id);
            system.debug('opplt0-------------------->'+oppLT[1].Product2Id);
            system.debug('opplt0-------------------->'+oppLT[2].Product2Id);
            for(OpportunityLineItem opplit : oppLT) {
                if(opplit.pre_oppy_revenue_next_12m_amount__c == CINCO) {
                    cont++;
                }
            }
            if(cont == TRES) {
                igual = true;
            }
            system.assert(igual,'Error');
            Test.StopTest();
        }
    }

    /*
    *   @author Global Desktop
    **/
    private static List<fprd__GBL_Product_version__c> initializeProdVersion() {
        List<fprd__GBL_Product_version__c> prodVer;
        prodVer= new List<fprd__GBL_Product_version__c>();
        fprd__GBL_Product_version__c prodVer1;
        prodVer1 = new fprd__GBL_Product_version__c();
        prodVer1.fprd__Version_number__c = 2;
        prodVer1.fprd__Active__c = true;
        prodVer.add(prodVer1);
        fprd__GBL_Product_version__c prodVer2;
        prodVer2 = new fprd__GBL_Product_version__c();
        prodVer2.fprd__Version_number__c = 2;
        prodVer2.fprd__Active__c = true;
        prodVer.add(prodVer2);
        fprd__GBL_Product_version__c prodVer3;
        prodVer3 = new fprd__GBL_Product_version__c();
        prodVer3.fprd__Version_number__c = 2;
        prodVer3.fprd__Active__c = true;
        prodVer.add(prodVer3);
        insert prodVer;
        return prodVer;
    }

    /*
    *   @author Global Desktop
    **/
    private static List<Product2> initializeProducto(DES_UtilTestClass testClass) {
        List<Product2> lstprod;
        lstprod = new List<Product2>();
        Product2 prod;
        prod = testClass.createProduct(Label.DES_Liability_Management);
        prod.Family = 'IBF';
        lstprod.add(prod);
        Product2 prod2;
        prod2 = testClass.createProduct(Label.DES_Rating_Advisory);
        prod2.Family = 'IBF';
        lstprod.add(prod2);
        Product2 prod3;
        prod3 = testClass.createProduct(Label.DES_FI_capital_Solutions);
        prod3.Family = 'IBF';
        lstprod.add(prod3);
        insert lstprod;
        return lstprod;
    }

    /*
    *   @author Global Desktop
    **/
    private static List<PricebookEntry> initializePricebook(List<Product2> lstprod, DES_UtilTestClass testClass) {
        List<PricebookEntry> pbEntryTest;
        pbEntryTest = new List<PricebookEntry>();
        PricebookEntry pbEntryTest1;
        pbEntryTest1 = testClass.createPricebookEntry(lstprod[0]);
        pbEntryTest.add(pbEntryTest1);
        PricebookEntry pbEntryTest2;
        pbEntryTest2 = testClass.createPricebookEntry(lstprod[1]);
        pbEntryTest.add(pbEntryTest2);
        PricebookEntry pbEntryTest3;
        pbEntryTest3 = testClass.createPricebookEntry(lstprod[2]);
        pbEntryTest.add(pbEntryTest3);
        insert pbEntryTest;
        return pbEntryTest;
    }

    /*
    *   @author Global Desktop
    **/
    private static List<OpportunityLineItem> initializeOppLI(List<Product2> lstprod, Opportunity opp, List<PricebookEntry> pbEntryTest,List<fprd__GBL_Product_version__c> prodVer, DES_UtilTestClass testClass) {
        List<OpportunityLineItem> lstOppLT;
        lstOppLT = new List<OpportunityLineItem>();
        OpportunityLineItem oppLineItem1;
        oppLineItem1 = testClass.createOppLineItem(opp, lstprod[0], pbEntryTest[0]);
        oppLineItem1.fprd__GBL_Product_version__c = prodVer[0].id;
        lstOppLT.add(oppLineItem1);
        OpportunityLineItem oppLineItem2;
        oppLineItem2 = testClass.createOppLineItem(opp, lstprod[1], pbEntryTest[1]);
        oppLineItem2.fprd__GBL_Product_version__c = prodVer[1].id;
        lstOppLT.add(oppLineItem2);
        OpportunityLineItem oppLineItem3;
        oppLineItem3 = testClass.createOppLineItem(opp, lstprod[2], pbEntryTest[2]);
        oppLineItem3.fprd__GBL_Product_version__c = prodVer[2].id;
        lstOppLT.add(oppLineItem3);
        insert lstOppLT;
        return lstOppLT;
    }
}