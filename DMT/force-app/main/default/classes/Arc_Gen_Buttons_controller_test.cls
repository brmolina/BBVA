/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Buttons_controller_test
* @Author   luisruben.quinto.munoz@bbva.com
* @Date     Created: 2019-07-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for Arc_Gen_Buttons_controller_test
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-24 luisruben.quinto.munoz@bbva.com
*             Class creation.
* |2019-08-29 mariohumberto.ramirez.contractor@bbva.com
*             Add new methods
* |2019-11-04 javier.soto.carrascosa@bbva.com
*             Add new methods
* |2020-01-07 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-06-18 manuelhugo.castillo.contractor@bbva.com
*             Add new method 'getButtonsJsonComponenttst8', modified method 'getButtonsJsonComponenttst6' add BottomUp
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_Buttons_controller_test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * --------------------------------------------------------------------------------------
    * @Description set up test method
    * --------------------------------------------------------------------------------------
    * @Author   luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example Arc_Gen_Buttons_controller_test.setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description set up test method
    * --------------------------------------------------------------------------------------
    * @Author   luisruben.quinto.munoz@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example Arc_Gen_Buttons_controller_test.getButtonsJsonComponenttst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getButtonsJsonComponenttst() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper accHasAnls = groupAccWrapper.get(GROUP_ID);
        final String collectionType='Activities';
        final String apiNameObject = 'arce__Data_Collections__c';
        Test.startTest();
        final String responseJson = Arc_Gen_Buttons_controller.getButtonsJsonComponent(collectionType, accHasAnls.accId, apiNameObject);
        final Boolean isValid = responseJson.contains(collectionType);
        system.assertEquals(true, isValid,'testGetComponents json responseJson do not contains correct values');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method for Arc_Gen_Buttons_controller
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-29
    * @param void
    * @return void
    * @example Arc_Gen_Buttons_controller_test.getButtonsJsonComponenttst2()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getButtonsJsonComponenttst2() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper accHasAnls = groupAccWrapper.get(GROUP_ID);
        final String collectionType='Shareholders';
        final String apiNameObject = 'arce__Third_Participant_Details__c';
        Test.startTest();
        final String responseJson = Arc_Gen_Buttons_controller.getButtonsJsonComponent(collectionType, accHasAnls.accId, apiNameObject);
        final Boolean isValid = responseJson.contains(collectionType);
        system.assertEquals(true, isValid,'testGetComponents json responseJson do not contains correct values');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method for Arc_Gen_Buttons_controller
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-29
    * @param void
    * @return void
    * @example Arc_Gen_Buttons_controller_test.getButtonsJsonComponenttst3()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getButtonsJsonComponenttst3() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper accHasAnls = groupAccWrapper.get(GROUP_ID);
        final String collectionType='Activities';
        final String apiNameObject = 'arce__Table_Content_per_Analysis__c';
        Test.startTest();
        final String responseJson = Arc_Gen_Buttons_controller.getButtonsJsonComponent(collectionType, accHasAnls.accId, apiNameObject);
        final Boolean isValid = responseJson.contains(collectionType);
        system.assertEquals(true, isValid,'testGetComponents json responseJson do not contains correct values');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method for Arc_Gen_Buttons_controller
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-29
    * @param void
    * @return void
    * @example Arc_Gen_Buttons_controller_test.getButtonsJsonComponenttst4()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getButtonsJsonComponenttst4() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper accHasAnls = groupAccWrapper.get(GROUP_ID);
        final String collectionType='Main_Banks';
        final String apiNameObject = 'arce__main_banks__c';
        Test.startTest();
        final String responseJson = Arc_Gen_Buttons_controller.getButtonsJsonComponent(collectionType, accHasAnls.accId, apiNameObject);
        final Boolean isValid = responseJson.contains(collectionType);
        system.assertEquals(true, isValid,'testGetComponents json responseJson do not contains correct values');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method for Arc_Gen_Buttons_controller
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-29
    * @param void
    * @return void
    * @example Arc_Gen_Buttons_controller_test.getButtonsJsonComponenttst5()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getButtonsJsonComponenttst5() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper accHasAnls = groupAccWrapper.get(GROUP_ID);
        final String collectionType = 'Main_clients';
        final String apiNameObject = 'arce__Third_Participant_Details__c';
        Test.startTest();
        final String responseJson = Arc_Gen_Buttons_controller.getButtonsJsonComponent(collectionType, accHasAnls.accId, apiNameObject);
        final Boolean isValid = responseJson.contains(collectionType);
        system.assertEquals(true, isValid,'testGetComponents json responseJson do not contains correct values');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method for Arc_Gen_Buttons_controller
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-29
    * @param void
    * @return void
    * @example Arc_Gen_Buttons_controller_test.getButtonsJsonComponenttst6()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getButtonsJsonComponenttst6() {
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
        final String apiNameObject = 'arce__Third_Participant_Details__c';
        Test.startTest();
        final String responseJson = Arc_Gen_Buttons_controller.getButtonsJsonComponent(collectionType, ahaTest.Id, apiNameObject);
        final Boolean isValid = responseJson.contains(collectionType);
        system.assertEquals(true, isValid,'testGetComponents json responseJson do not contains correct values');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description test method for Arc_Gen_Buttons_controller
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-29
    * @param void
    * @return void
    * @example Arc_Gen_Buttons_controller_test.getButtonsJsonComponenttst6()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getButtonsJsonComponenttst7() {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID});
        final arce.Arc_Gen_Account_Wrapper accHasAnls = groupAccWrapper.get(GROUP_ID);
        final String collectionType = 'Maturity_table';
        final String apiNameObject = 'arce__Table_Content_per_Analysis__c';
        Test.startTest();
        final String responseJson = Arc_Gen_Buttons_controller.getButtonsJsonComponent(collectionType, accHasAnls.accId, apiNameObject);
        final Boolean isValid = responseJson.contains(collectionType);
        system.assertEquals(true, isValid,'testGetComponents json responseJson do not contains correct values');
        Test.stopTest();
    }
        /**
    * --------------------------------------------------------------------------------------
    * @Description test method for Arc_Gen_Buttons_controller
    * --------------------------------------------------------------------------------------
    * @Author   Manuel Hugo Castillo Chavarria  manuelhugo.castillo.contractor@bbva.com
    * @Date     Created: 2020-06-18
    * @param void
    * @return void
    * @example Arc_Gen_Buttons_controller_test.getButtonsJsonComponenttst8()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getButtonsJsonComponenttst8() {
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
        final String apiNameObject = 'arce__Third_Participant_Details__c';
        Test.startTest();
        final String responseJson = Arc_Gen_Buttons_controller.getButtonsJsonComponent(collectionType, ahaTest.Id, apiNameObject);
        final Boolean isValid = responseJson.contains(collectionType);
        system.assertEquals(true, isValid,'testGetComponents json responseJson do not contains correct values');
        Test.stopTest();
    }
}