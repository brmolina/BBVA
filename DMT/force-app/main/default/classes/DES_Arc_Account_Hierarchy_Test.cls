/*------------------------------------------------------------------
*Author:        Hector Vasquez
*Project:      	ARCE - BBVA Bancomer
*Description:   Test class for DES_Arc_Account_Hierarchy
*_______________________________________________________________________________________
*Versión    Date           	Author                              Description
*1.0        14/09/2020      ARCE's TEAM                         Created.
-----------------------------------------------------------------------------------------*/
@isTest
global with sharing class DES_Arc_Account_Hierarchy_Test {
	
    /**
        * @Description: String with value "accNumber"
    */
    private static String accNumber = 'CAONlXcCA_uxyJ402AA_xw';
    /**
    
    /**
    *-------------------------------------------------------------------------------
    * @Description Test setup
    *--------------------------------------------------------------------------------
    * @ Author hectorjeshua.vasquez.contactor@bbva.com
    * @ Date 2022-11-02
    *--------------------------------------------------------------------------------
    **/
    @TestSetup
    static void testSetup() {
        List<Local_Client__c> testAccts = new List<Local_Client__c>();
        for(Integer i=0;i<3;i++){
            Local_Client__c acc = TestFactory.createLocalClient();
            Integer randomNumber = Integer.valueof((Math.random() * 100000));
            acc.Alpha_code__c = 'ES' + randomNumber;
            testAccts.add(acc);
        }
        Local_Client__c lclAcc = TestFactory.createLocalClient();
        Account testAcc1 = new Account();
        testAcc1.Name = 'grupo padre';
        testAcc1.Phone = '646171717';
        testAcc1.DES_Country_Client__c = 'ES';
        insert testAcc1;
        
        dwp_acmh__GBL_Account_Relationship__c testRelation = new dwp_acmh__GBL_Account_Relationship__c();
        testRelation.dwp_acmh__Parent_Account__c = testAcc1.Id;
        testRelation.dwp_acmh__Child_Account__c = lclAcc.Cib_Client__c;
        testRelation.dwp_acmh__Vision__c = 'Riesgos';
        testRelation.DES_Main_Parent__c = 'S';
        insert testRelation;
        
        Local_Client__c lclAcc2 = TestFactory.createLocalClient();
        final List<Account> lstAccountSearch = [SELECT Id, Name, account_client__c FROM Account WHERE Id =: lclAcc2.Cib_Client__c LIMIT 1];
        System.debug('REVISAR PADRE 2 ' + lstAccountSearch);
        lstAccountSearch[0].account_client__c = 'S'; 
        update lstAccountSearch;
        
        dwp_acmh__GBL_Account_Relationship__c testRelation2 = new dwp_acmh__GBL_Account_Relationship__c();
        testRelation2.dwp_acmh__Parent_Account__c = testAcc1.Id;
        testRelation2.dwp_acmh__Child_Account__c = lclAcc2.Cib_Client__c;
        testRelation2.dwp_acmh__Vision__c = 'Riesgos';
        testRelation2.DES_Main_Parent__c = 'S';
        insert testRelation2;

		Local_Client__c lclAcc3 = TestFactory.createLocalClient();        
        final List<Account> lstAccountSearch2 = [SELECT Id, Name, account_client__c FROM Account WHERE Id =: lclAcc3.Cib_Client__c LIMIT 1];

        Account testAccSimple = new Account();
        testAccSimple.Name = 'grupo padre doble 1';
        testAccSimple.Phone = '646171717';
        testAccSimple.DES_Country_Client__c = 'ES';
        insert testAccSimple;
        
        Account testAccDoble2 = new Account();
        testAccDoble2.Name = 'grupo padre doble 2';
        testAccDoble2.Phone = '646171717';
        testAccDoble2.DES_Country_Client__c = 'ES';
        insert testAccDoble2;
        
        Account testAccGroup = new Account();
        testAccGroup.Name = 'grupo padre 1A';
        testAccGroup.Phone = '646171717';
        testAccGroup.account_group__c = '1A';
        testAccGroup.DES_Country_Client__c = 'ES';
        insert testAccGroup;
        
        dwp_acmh__GBL_Account_Relationship__c testRelation3 = new dwp_acmh__GBL_Account_Relationship__c();
        testRelation3.dwp_acmh__Parent_Account__c = testAccSimple.Id;
        testRelation3.dwp_acmh__Child_Account__c = lclAcc3.Cib_Client__c;
        testRelation3.dwp_acmh__Vision__c = 'Riesgos';
        testRelation3.DES_Main_Parent__c = 'S';
        insert testRelation3;
        
        dwp_acmh__GBL_Account_Relationship__c testRelation4 = new dwp_acmh__GBL_Account_Relationship__c();
        testRelation4.dwp_acmh__Parent_Account__c = testAccDoble2.Id;
        testRelation4.dwp_acmh__Child_Account__c = lclAcc3.Cib_Client__c;
        testRelation4.dwp_acmh__Vision__c = 'Riesgos';
        testRelation4.DES_Main_Parent__c = 'S';
        insert testRelation4;
        
        Local_Client__c lclAcc4 = TestFactory.createLocalClient();        
        final List<Account> lstAccountSearch3 = [SELECT Id, Name, account_client__c FROM Account WHERE Id =: lclAcc4.Cib_Client__c LIMIT 1];
        lstAccountSearch3[0].account_client__c = 'S'; 
        update lstAccountSearch3;
        
        Local_Client__c lclAcc5 = TestFactory.createLocalClient();        
        final List<Account> lstAccountSearch4 = [SELECT Id, Name, account_client__c FROM Account WHERE Id =: lclAcc5.Cib_Client__c LIMIT 1];
        lstAccountSearch4[0].account_group__c = '3'; 
        lstAccountSearch4[0].DES_Entity_Hierarchy__c = 'N';
        update lstAccountSearch4;
        
        Local_Client__c lclAcc6 = TestFactory.createLocalClient();        
        final List<Account> lstAccountSearch5 = [SELECT Id, Name, account_client__c, DES_Entity_Hierarchy__c FROM Account WHERE Id =: lclAcc6.Cib_Client__c LIMIT 1];
        lstAccountSearch5[0].account_client__c = 'S'; 
        lstAccountSearch5[0].DES_Entity_Hierarchy__c = 'S';
        update lstAccountSearch5;
        
        dwp_acmh__GBL_Account_Relationship__c testRelation5 = new dwp_acmh__GBL_Account_Relationship__c();
        testRelation5.dwp_acmh__Parent_Account__c = testAccDoble2.Id;
        testRelation5.dwp_acmh__Child_Account__c = lclAcc4.Cib_Client__c;
        testRelation5.dwp_acmh__Vision__c = 'Riesgos';
        testRelation5.DES_Main_Parent__c = 'S';
        insert testRelation5;
        
        dwp_acmh__GBL_Account_Relationship__c testRelation6 = new dwp_acmh__GBL_Account_Relationship__c();
        testRelation6.dwp_acmh__Parent_Account__c = testAccDoble2.Id;
        testRelation6.dwp_acmh__Child_Account__c = lclAcc5.Cib_Client__c;
        testRelation6.dwp_acmh__Vision__c = 'Riesgos';
        testRelation6.DES_Main_Parent__c = 'S';
        insert testRelation6;
        
        
        dwp_acmh__GBL_Account_Relationship__c testRelation7 = new dwp_acmh__GBL_Account_Relationship__c();
        testRelation7.dwp_acmh__Parent_Account__c = testAccGroup.Id;
        testRelation7.dwp_acmh__Child_Account__c = lclAcc6.Cib_Client__c;
        testRelation7.dwp_acmh__Vision__c = 'Riesgos';
        testRelation7.DES_Main_Parent__c = 'S';
        insert testRelation7;
        
        dwp_acmh__GBL_Account_Relationship__c testRelation8 = new dwp_acmh__GBL_Account_Relationship__c();
        testRelation8.dwp_acmh__Parent_Account__c = testAccGroup.Id;
        testRelation8.dwp_acmh__Child_Account__c = lclAcc5.Cib_Client__c;
        testRelation8.dwp_acmh__Vision__c = 'Riesgos';
        testRelation8.DES_Main_Parent__c = 'S';
        insert testRelation8;
        
        dwp_acmh__GBL_Account_Relationship__c testRelation9 = new dwp_acmh__GBL_Account_Relationship__c();
        testRelation9.dwp_acmh__Parent_Account__c = lstAccountSearch4[0].Id;
        testRelation9.dwp_acmh__Child_Account__c = lclAcc6.Cib_Client__c;
        testRelation9.dwp_acmh__Vision__c = 'Riesgos';
        testRelation9.DES_Main_Parent__c = 'S';
        insert testRelation9;
        
        arce__Analysis__c analysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('Test name', null, lclAcc6.Cib_Client__c);
        insert analysis;
        
        
        //final Account acc = arce.Arc_UtilitiesToTest_tst.crearCuenta('TestAcc', null, null, accNumber);
        //insert testAccts;
        List<Local_Client__c> testAcctsP = [SELECT Id, Cib_Client__c, Alpha_code__c FROM Local_Client__c];
        List<Local_Client__c> testlclAccount = [SELECT Id, Cib_Client__c, Alpha_code__c FROM Local_Client__c limit 1];
        final List<Account> lstAccount = [SELECT Id, Name, account_client__c, account_group__c FROM Account WHERE Id =: testlclAccount[0].Cib_Client__c LIMIT 1];
        lstAccount[0].account_client__c = '';
        update testlclAccount;
    }
    
     /**
    *-------------------------------------------------------------------------------
    * @Description Test DES_Arc_Account_Hierarchy_Test
    *--------------------------------------------------------------------------------
    * @ Author hectorjeshua.vasquez.contactor@bbva.com
    * @ Date 2022-11-02
    *--------------------------------------------------------------------------------
    **/
    @isTest
    global static void checkRiskHeader() {
        Test.startTest(); 
        List<Local_Client__c> testAcctsP = [SELECT Id, Alpha_code__c FROM Local_Client__c];
        final List<Account> lstAccount = [SELECT Id, Name,  account_group__c FROM Account WHERE Name = 'grupo padre' LIMIT 1];
        List<dwp_acmh__GBL_Account_Relationship__c> LstAccountS = [SELECT Id, dwp_acmh__Parent_Account__c, dwp_acmh__Child_Account__c, dwp_acmh__Vision__c, dwp_acmh__Child_Account__r.account_client__c
                                                                          FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Vision__c = 'Riesgos' AND dwp_acmh__Parent_Account__c =: lstAccount[0].Id AND dwp_acmh__Child_Account__r.account_client__c = 'N'];
        List<Local_Client__c> testAccts = [SELECT Id, Alpha_code__c, Cib_Client__c, Cib_Client__r.account_client__c FROM Local_Client__c wHERE Cib_Client__c =: LstAccountS[0].dwp_acmh__Child_Account__c];
        final List<Account> lstAccount2 = [SELECT Id, Name,  account_client__c FROM Account WHERE Id =: LstAccountS[0].dwp_acmh__Child_Account__c LIMIT 1];
        System.debug('lstAccount2 ' + lstAccount2);
        final Map<String, List<String>> maptest1 = DES_Arc_Account_Hierarchy.riskHeader(testAccts[0].Alpha_code__c);
        final Map<String, List<String>> maptest4 = DES_Arc_Account_Hierarchy.headerFinder(testAccts[0].Alpha_code__c);
        System.debug('Lista test ' + testAcctsP);
        
        final List<Account> lstAccount3 = [SELECT Id, Name,  account_group__c FROM Account WHERE Name = 'grupo padre doble 1' LIMIT 1];
        List<dwp_acmh__GBL_Account_Relationship__c> LstAccountS2 = [SELECT Id, dwp_acmh__Parent_Account__c, dwp_acmh__Child_Account__c, dwp_acmh__Vision__c, dwp_acmh__Child_Account__r.account_client__c
                                                                          FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Vision__c = 'Riesgos' AND dwp_acmh__Parent_Account__c =: lstAccount3[0].Id AND dwp_acmh__Child_Account__r.account_client__c = 'N'];

        List<Local_Client__c> testAccts2 = [SELECT Id, Alpha_code__c, Cib_Client__c, Cib_Client__r.account_client__c FROM Local_Client__c wHERE Cib_Client__c =: LstAccountS2[0].dwp_acmh__Child_Account__c];
        final Map<String, List<String>> maptest2 = DES_Arc_Account_Hierarchy.riskHeader(testAccts2[0].Alpha_code__c);
        final Map<String, List<String>> maptest5 = DES_Arc_Account_Hierarchy.headerFinder(testAccts2[0].Alpha_code__c);
        
        List<Local_Client__c> testAccts3 = [SELECT Id, Alpha_code__c, Cib_Client__r.account_client__c FROM Local_Client__c WHERE Cib_Client__r.account_client__c = 'S' LIMIT 1];
        final Map<String, List<String>> maptest3 = DES_Arc_Account_Hierarchy.riskHeader(testAccts3[0].Alpha_code__c);
        final List<Account> lstAccount1A = [SELECT Id, Name,  account_group__c FROM Account WHERE Name = 'grupo padre 1A' LIMIT 1];
        List<dwp_acmh__GBL_Account_Relationship__c> LstAccountSon = [SELECT Id, dwp_acmh__Parent_Account__c, dwp_acmh__Child_Account__c, dwp_acmh__Vision__c, dwp_acmh__Child_Account__r.account_client__c
                                                                          FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Parent_Account__c =: lstAccount1A[0].Id];
        List<Local_Client__c> testLclcc = [SELECT Id, Alpha_code__c FROM Local_Client__c WHERE Cib_Client__c =: LstAccountSon[0].dwp_acmh__Child_Account__c];
        Map<String, List<String>> mappingRiskHeader2 = DES_Arc_Account_Hierarchy.alphaCodeHierarchy(LstAccountSon[0].dwp_acmh__Child_Account__c);
        final Map<String, List<String>> maptest6 = DES_Arc_Account_Hierarchy.headerFinder(testLclcc[0].Alpha_code__c);
        Set <String> lcClientAlphaCode = new Set<String>();
        for(Account lcClients :  [SELECT Id, Name,  account_client__c FROM Account]){
            lcClientAlphaCode.add(lcClients.Id);
        }
        Set <String> localClientAlphaFinder = DES_Arc_Account_Hierarchy.localClientAlphaFinder(lcClientAlphaCode);
        System.assert(!maptest3.isEmpty(), 'Error checkRiskHeader');
        Test.stopTest(); 
    }
    
     /**
    *-------------------------------------------------------------------------------
    * @Description Test DES_Arc_Account_Hierarchy_Test
    *--------------------------------------------------------------------------------
    * @ Author jorge.diaz-blanco.contactor@bbva.com
    * @ Date 2023-01-20
    *--------------------------------------------------------------------------------
    **/
    @isTest
    global static void checksubgroupParent() {
        Test.startTest(); 
        Map<String, List<String>> mappingRiskHeader = new Map<String, List<String>>();
        final List<Account> lstAccount1 = [SELECT Id, Name,  account_group__c FROM Account WHERE Name = 'grupo padre 1A' LIMIT 1];
        List<dwp_acmh__GBL_Account_Relationship__c> LstAccountS2 = [SELECT Id, dwp_acmh__Parent_Account__c, dwp_acmh__Child_Account__c, dwp_acmh__Vision__c, dwp_acmh__Child_Account__r.account_client__c
                                                                          FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Vision__c = 'Riesgos' AND dwp_acmh__Parent_Account__c =: lstAccount1[0].Id AND dwp_acmh__Child_Account__r.account_client__c = 'S'];

        List<Local_Client__c> testAccts2 = [SELECT Id, Alpha_code__c, Cib_Client__c, Cib_Client__r.account_client__c FROM Local_Client__c wHERE Cib_Client__c =: LstAccountS2[0].dwp_acmh__Child_Account__c];
        
        final List<dwp_acmh__GBL_Account_Relationship__c> upHierarchy = [SELECT Id, dwp_acmh__Parent_Account__c, dwp_acmh__Child_Account__c, dwp_acmh__Vision__c,DES_Main_Parent__c, dwp_acmh__Parent_Account__r.account_group__c 
                                                                        FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Vision__c = 'Riesgos' AND dwp_acmh__Child_Account__c =: LstAccountS2[0].dwp_acmh__Child_Account__c AND DES_Main_Parent__c = 'S' LIMIT 1];
        mappingRiskHeader = DES_Arc_Account_Hierarchy.subgroupParent(upHierarchy, testAccts2[0].Alpha_code__c);
        final List<arce__Analysis__c > lstAnalysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        DES_Arc_Account_Hierarchy.childHierarchy(lstAnalysis[0].Id);
        System.assert(!mappingRiskHeader.isEmpty(), 'Error checksubgroupParent');
        Test.stopTest(); 
    }
}