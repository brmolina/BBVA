/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SyncPersistance_Test
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 28/09/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers the following apex classes:
*              Arc_Gen_SyncPersistance_Controller, Arc_Gen_SyncPersistance_Service, Arc_Gen_SyncPersistance_Helper
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |28/09/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_SyncPersistance_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test group
    */
    static final string ENCRYPTED_GROUP = 'EcxqPKmyRSc';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_AsyncPersistance_Test
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 28/09/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.setup()
    * --------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void setup() {
        arce.Arc_UtilitiesToTest_tst.enableBypass();
        Arc_UtilitysDataTest_tst.setupAcccounts();

        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        final arce__Analysis__c noVigorArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        noVigorArce.arce__anlys_wkfl_sub_process_type__c = '2';
        noVigorArce.arce__anlys_wkfl_sanction_rslt_type__c = '1';
        noVigorArce.arce__analysis_risk_expiry_date__c = System.today() - 1;
        noVigorArce.ownerId = System.UserInfo.getUserId();
        insert noVigorArce;

        final arce__Account_has_Analysis__c ahaNoVigor1 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, noVigorArce.Id, groupAccount.accId, '1');
        insert ahaNoVigor1;

        final arce__Analysis__c newArceRen = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArceRen.arce__anlys_wkfl_sub_process_type__c = '1';
        newArceRen.ownerId = System.UserInfo.getUserId();
        insert newArceRen;

        final arce__Account_has_Analysis__c ahaRen1 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArceRen.Id, groupAccount.accId, '1');
        insert ahaRen1;

        final arce__Analysis__c newArceMod = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArceMod.arce__anlys_wkfl_sub_process_type__c = '3';
        newArceMod.ownerId = System.UserInfo.getUserId();
        insert newArceMod;

        final arce__Account_has_Analysis__c ahaMod1 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArceMod.Id, groupAccount.accId, '1');
        insert ahaMod1;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 28/09/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.emptyControllConst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyControllConst() {
        Test.startTest();
        final Arc_Gen_SyncPersistance_Controller constructorCont = new Arc_Gen_SyncPersistance_Controller();
        System.assertEquals(constructorCont, constructorCont, 'Empty controller constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 28/09/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.emptyServConst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyServConst() {
        Test.startTest();
        final Arc_Gen_SyncPersistance_Service constructorServ = new Arc_Gen_SyncPersistance_Service();
        System.assertEquals(constructorServ, constructorServ, 'Empty Service constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 28/09/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.emptyServHelper()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyServHelper() {
        Test.startTest();
        final Arc_Gen_SyncPersistance_Helper constructorHelp = new Arc_Gen_SyncPersistance_Helper();
        System.assertEquals(constructorHelp, constructorHelp, 'Empty Helper constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 28/09/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.testingGetAha()
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testingGetAha() {
        Test.startTest();
        final arce__Account_has_Analysis__c aha = [SELECT Id,Name FROM arce__Account_has_Analysis__c LIMIT 1];
        final List<arce__Account_has_Analysis__c> ahaList = Arc_Gen_SyncPersistance_Controller.getAccHasAnalysis(aha.Id);
        System.assertNotEquals(null, ahaList, 'The list of retrieved AccountHasAnalysis is not null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 28/09/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.testCallSyncService()
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testRenovationSyncService() {
        Test.startTest();
        final arce__Account_has_Analysis__c aha = [SELECT Id,Name FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c = '1' LIMIT 1];
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            update new arce__Analysis__c(
                Id = [SELECT Id FROM arce__Analysis__c LIMIT 1].Id,
                arce__Stage__c = '3'
            );
            response = Arc_Gen_SyncPersistance_Controller.initCallingPersistance(aha.Id);
        } catch (Exception e) {
            System.debug('Test error ' + e.getMessage());
            response.serviceMessage = e.getMessage();
        }
        System.assertNotEquals(null, response, 'The renovation response is not null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 28/09/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.testCallSyncService()
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testModificationSyncService() {
        Test.startTest();
        update new arce__Analysis__c(
            Id = [SELECT Id FROM arce__Analysis__c LIMIT 1].Id,
            arce__Stage__c = '3'
        );
        final arce__Account_has_Analysis__c ahaRen = [SELECT Id,Name FROM arce__Account_has_Analysis__c WHERE arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c = '3' LIMIT 1];
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        try {
            response = Arc_Gen_SyncPersistance_Controller.initCallingPersistance(ahaRen.Id);
        } catch (Exception e) {
            System.debug('Test error ' + e.getMessage());
            response.serviceMessage = e.getMessage();
        }
        System.assertNotEquals(null, response, 'The modification response is not null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 28/09/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.testCallSyncService()
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testGetPersistIndicator() {
        Test.startTest();
        Boolean persistIndicator = Arc_Gen_AnalysisWizard_Controller.getPersistanceCallConfig();
        Boolean persistStatus = Arc_Gen_SyncPersistance_Helper.getPersistanceStatus(persistIndicator, '1');
        System.assertNotEquals(null, persistStatus, 'The indicator is not null');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 28/09/2020
    * @param void
    * @return void
    * @example Arc_Gen_AsyncPersistance_Test.testCallSyncService()
    * --------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testGetEventType() {
        Test.startTest();
        String eventType;
        for (Integer i = 1; i <= 3; i++) {
            eventType = Arc_Gen_SyncPersistance_Helper.setEventType(String.valueOf(i));
        }
        System.assertNotEquals(null, eventType, 'The eventType is not null');
        Test.stopTest();
    }
}