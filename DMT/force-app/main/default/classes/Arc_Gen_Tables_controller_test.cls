/*------------------------------------------------------------------
*Author:        Diego Miguel Tamarit - diego.miguel.contractor@bbva.com / dmiguelt@minsait.com
*Project:      	ARCE - BBVA Bancomer
*Description:   Test class for code coverage of:
Arc_Gen_Tables_controller
*_______________________________________________________________________________________
*Version    Date           Author                                   Description
*1.0        11/04/2019     diego.miguel.contractor@bbva.com    	    Creación.
*1.1        23/06/2020     manuelhugo.castillo.contractor@bbva.com  Add methods 'testGetTableJsonComponentMA_BOTTOM_UP',
*                                                                   'testGetTableJsonComponentMA_TOP_DOWN'.
*1.1        23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
-----------------------------------------------------------------------------------------*/
@isTest
public class Arc_Gen_Tables_controller_test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Method:  test method
    * @Description: testing method.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
    }

    @isTest static void testGetTableJsonComponent() {
        String collectionType = String.valueOf((Math.random()*10000).round());
        String recordId = String.valueOf((Math.random()*10000).round());
        Test.startTest();
        Arc_Gen_Tables_controller tableController = new Arc_Gen_Tables_controller();
        String table = tableController.getTableJsonComponent(collectionType, recordId);
        Boolean isValid = table.contains(collectionType) && table.contains(recordId);
        system.assertEquals(true, isValid,'testGetTableJsonComponent json table do not contains correct values');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method for Arc_Gen_Tables_controller
    * --------------------------------------------------------------------------------------
    * @Author   Manuel Hugo Castillo Chavarria  manuelhugo.castillo.contractor@bbva.com
    * @Date     Created: 2020-06-23
    * @param void
    * @return void
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGetTableJsonComponentMABOTTOMUP() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper accHasAnls = groupAccWrapper.get(GROUP_ID);
        arce__Analysis__c analysisTest = Arc_UtilitysDataTest_tst.crearArceAnalysis('Analysis Test', null, accHasAnls.accId);
        insert analysisTest;
        arce__Sector__c sectorTest = Arc_UtilitysDataTest_tst.crearSector('g-01', '100', 'g-01', null);
        insert sectorTest;
        arce__Account_has_Analysis__c ahaTest = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sectorTest.Id, analysisTest.Id, accHasAnls.accId, 'g-01');
        ahaTest.arce__anlys_wkfl_cnsld_ffss_type__c = '1';
        insert ahaTest;
        final String collectionType = 'Main_affiliates';
        Test.startTest();
        Arc_Gen_Tables_controller tableController = new Arc_Gen_Tables_controller();
        String table = tableController.getTableJsonComponent(collectionType, ahaTest.Id);
        Boolean isValid = table.contains(collectionType) && table.contains(ahaTest.Id);
        system.assertEquals(true, isValid,'testGetTableJsonComponent json table do not contains correct values');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method for Arc_Gen_Tables_controller
    * --------------------------------------------------------------------------------------
    * @Author   Manuel Hugo Castillo Chavarria  manuelhugo.castillo.contractor@bbva.com
    * @Date     Created: 2020-06-23
    * @param void
    * @return void
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testGetTableJsonComponentMATOPDOWN() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper accHasAnls = groupAccWrapper.get(GROUP_ID);
        arce__Analysis__c analysisTest = Arc_UtilitysDataTest_tst.crearArceAnalysis('Analysis Test', null, accHasAnls.accId);
        insert analysisTest;
        arce__Sector__c sectorTest = Arc_UtilitysDataTest_tst.crearSector('g-01', '100', 'g-01', null);
        insert sectorTest;
        arce__Account_has_Analysis__c ahaTest = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sectorTest.Id, analysisTest.Id, accHasAnls.accId, 'g-01');
        ahaTest.arce__anlys_wkfl_cnsld_ffss_type__c = '2';
        insert ahaTest;
        final String collectionType = 'Main_affiliates';
        Test.startTest();
        Arc_Gen_Tables_controller tableController = new Arc_Gen_Tables_controller();
        String table = tableController.getTableJsonComponent(collectionType, ahaTest.Id);
        Boolean isValid = table.contains(collectionType) && table.contains(ahaTest.Id);
        system.assertEquals(true, isValid,'testGetTableJsonComponent json table do not contains correct values');
        Test.stopTest();
    }
}