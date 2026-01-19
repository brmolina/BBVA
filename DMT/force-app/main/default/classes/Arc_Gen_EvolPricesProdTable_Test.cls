/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_EvolPricesProdTable_Test
* @Author   Mario Humberto Ramirez Lio
* @Date     Created: 2021-26-01
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for evolution of the main products
* ------------------------------------------------------------------------------------------------
* |2021-26-01 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public without sharing class Arc_Gen_EvolPricesProdTable_Test {
    /*
        @Description string with value 'product1'
    */
    private static final String PRODUCT1 = 'product1';
    /*
        @Description string with value 'SUCCESS'
    */
    private static final String SUCCESS = 'SUCCESS';
    /*
        @Description setup method
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c arceAn = arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        insert arceAn;

        final arce__Account_has_Analysis__c accHasAnObj = arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAn.Id, groupAccount.accId, '1');
        insert accHasAnObj;

        final List<arce__evol_main_prod_agro__c> productlts = new List<arce__evol_main_prod_agro__c>();
        for (integer itera = 0; itera < 3; itera++) {
            final arce__evol_main_prod_agro__c poductAgro = new arce__evol_main_prod_agro__c();
            poductAgro.arce__year_id__c = 2021 - itera;
            poductAgro.arce__gf_commodity_product_name__c = PRODUCT1;
            poductAgro.arce__gf_comod_prd_avg_price_amount__c = 10;
            poductAgro.arce__account_has_analysis_agro_id__c = accHasAnObj.Id;
            productlts.add(poductAgro);
        }
        insert productlts;
    }
    /*
        @Description test method
    */
    @isTest static void testgetTableInfo() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String response = Arc_Gen_EvolPricesProdTable_Ctr.getTableInfo(accHasAnls.Id);
        system.assertEquals(String.isEmpty(response), false, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void testconstructor1() {
        final Arc_Gen_EvolPricesProdTable_Ctr controller = new Arc_Gen_EvolPricesProdTable_Ctr();
        system.assertEquals(controller, controller, SUCCESS);
    }
    /*
        @Description test method
    */
    @isTest static void testconstructor2() {
        final Arc_Gen_EvolPricesProdTable_Service service = new Arc_Gen_EvolPricesProdTable_Service();
        system.assertEquals(service, service, SUCCESS);
    }
    /*
        @Description test method
    */
    @isTest static void testconstructor3() {
        final Arc_Gen_evol_main_prod_agro_Locator locator = new Arc_Gen_evol_main_prod_agro_Locator();
        system.assertEquals(locator, locator, SUCCESS);
    }
    /*
        @Description test method
    */
    @isTest static void testconstructor4() {
        final Arc_Gen_EvolPricesModal_Ctr control = new Arc_Gen_EvolPricesModal_Ctr();
        system.assertEquals(control, control, SUCCESS);
    }
    /*
        @Description test method
    */
    @isTest static void testconstructor5() {
        final Arc_Gen_EvolPricesModal_Service serv = new Arc_Gen_EvolPricesModal_Service();
        system.assertEquals(serv, serv, SUCCESS);
    }
    /*
        @Description test method
    */
    @isTest static void insertRecords() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__evol_main_prod_agro__c> prodLts = [SELECT Id, Name, arce__gf_commodity_product_name__c, arce__year_id__c, arce__gf_comod_prd_avg_price_amount__c, arce__account_has_analysis_agro_id__c
                                                            FROM arce__evol_main_prod_agro__c
                                                            WHERE arce__account_has_analysis_agro_id__c = :accHasAnls.Id
                                                            ORDER BY Name ASC];
        Test.startTest();
        Arc_Gen_EvolPricesModal_Ctr.insertRecords(null);
        final String response = Arc_Gen_EvolPricesModal_Ctr.insertRecords(JSON.serialize(prodLts));
        system.assertEquals(response.contains('true'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void deleteRecords() {
        final List<String> idLts = new List<String>();
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__evol_main_prod_agro__c> prodLts = [SELECT Id
                                                            FROM arce__evol_main_prod_agro__c
                                                            WHERE arce__account_has_analysis_agro_id__c = :accHasAnls.Id
                                                            ORDER BY Name ASC];
        for (arce__evol_main_prod_agro__c prod: prodLts) {
            idLts.add(prod.Id);
        }
        Test.startTest();
        final String response = Arc_Gen_EvolPricesModal_Ctr.deleteRecords(idLts);
        system.assertEquals(response.contains('true'), true, SUCCESS);
        Test.stopTest();
    }
    /*
        @Description test method
    */
    @isTest static void loadRecords() {
        final arce__Account_has_Analysis__c accHasAnls = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String response = Arc_Gen_EvolPricesModal_Ctr.loadRecords(accHasAnls.Id);
        system.assertEquals(String.isEmpty(response), false, SUCCESS);
        Test.stopTest();
    }
}