/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_TabSet_controller_test
* @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-09-10
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for code coverage of: Arc_Gen_QVCD_Ctlr and  Arc_Gen_QVCD_Service
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-09-10 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-01-09 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public without sharing class Arc_Gen_QVCD_Ctlr_test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_QVCD_Ctlr_test
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-09-10
    * @param void
    * @return void
    * @example Arc_Gen_QVCD_Ctlr_test.setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100', '1', null);
        insert newSector;

        final arce__Analysis__c newArce = arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        insert newArce;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-09-10
    * @param void
    * @return void
    * @example Arc_Gen_QVCD_Ctlr_test.getConfigurationSuccess()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getConfigurationSuccess() {
        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__analysis_customer_relation_type__c = '01';
        arceVar.arce__wf_status_id__c = '02';
        update arceVar;
        Test.startTest();
        Arc_Gen_QVCD_Ctlr.QVCD_Wrapper wrapper = new Arc_Gen_QVCD_Ctlr.QVCD_Wrapper();
        wrapper = Arc_Gen_QVCD_Ctlr.getConfiguration(arceVar.Id);
        system.assertEquals(wrapper.status, 'SUCCESS', 'The test to getConfiguration was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-09-10
    * @param void
    * @return void
    * @example Arc_Gen_QVCD_Ctlr_test.getConfigurationSuccess2()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getConfigurationSuccess2() {
        final arce__Analysis__c arceVar = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        arceVar.arce__analysis_customer_relation_type__c = '02';
        arceVar.arce__wf_status_id__c = '02';
        update arceVar;
        Test.startTest();
        Arc_Gen_QVCD_Ctlr.QVCD_Wrapper wrapper = new Arc_Gen_QVCD_Ctlr.QVCD_Wrapper();
        wrapper = Arc_Gen_QVCD_Ctlr.getConfiguration(arceVar.Id);
        system.assertEquals(wrapper.status, 'SUCCESS', 'The test to getConfiguration was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-09-10
    * @param void
    * @return void
    * @example Arc_Gen_QVCD_Ctlr_test.getConfigurationError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getConfigurationError() {
        Test.startTest();
        Arc_Gen_QVCD_Ctlr.QVCD_Wrapper wrapper = new Arc_Gen_QVCD_Ctlr.QVCD_Wrapper();
        wrapper = Arc_Gen_QVCD_Ctlr.getConfiguration(null);
        system.assertEquals(wrapper.status, 'ERROR', 'The test to getConfiguration was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-09-10
    * @param void
    * @return void
    * @example Arc_Gen_QVCD_Ctlr_test.testConstructorCtlr()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testConstructorCtlr() {
        Test.startTest();
        final Arc_Gen_QVCD_Ctlr ctlr = new Arc_Gen_QVCD_Ctlr();
        system.assertEquals(ctlr, ctlr, 'The test to void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio - mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-09-10
    * @param void
    * @return void
    * @example Arc_Gen_QVCD_Ctlr_test.testConstructorService()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testConstructorService() {
        Test.startTest();
        final Arc_Gen_QVCD_Service service = new Arc_Gen_QVCD_Service();
        system.assertEquals(service, service, 'The test to void contructor was successfull');
        Test.stopTest();
    }
}