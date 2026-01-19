/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_test
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 2020-03-31
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for code coverage of: Arc_Gen_ButtonsCMP_test
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-03-31 juanignacio.hita.contractor@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_ButtonsCMP_test {
    /**
        * --------------------------------------------------------------------------------------
        * @Description Setup method for Arc_Gen_ButtonsCMP_test
        * --------------------------------------------------------------------------------------
        * @Author   juanignacio.hita.contractor@bbva.com
        * @Date     31/03/2020
        * @return void
        * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001','G000002','C000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__anlys_wkfl_sub_process_type__c = arce.Arc_Gen_Constants.SUBPROCESS_NEW;
        insert newArce;

        final arce.Arc_Gen_Account_Wrapper groupAccount1 = groupAccWrapper.get('G000002');
        final arce__Analysis__c newArce1 = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis1', null, groupAccount1.accId);
        newArce1.arce__anlys_wkfl_sub_process_type__c = arce.Arc_Gen_Constants.SUBPROCESS_RATING;
        insert newArce1;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     31/03/2020
    * @return void
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getBtnCollection() {
        Test.startTest();
        final arce__Analysis__c arceVar = [SELECT Id, arce__anlys_wkfl_sub_process_type__c FROM arce__Analysis__c WHERE Name = 'Arce Analysis' LIMIT 1];
        final String res = Arc_Gen_ButtonsCMP_controller.getBtnCollection(arceVar.Id);
        System.assertEquals('Arc_Gen_ButtonPanel', res, 'Button collection Arc_Gen_ButtonPanel');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     31/03/2020
    * @return void
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getBtnCollectionKO() {
        Test.startTest();
        try {
            final arce__Analysis__c arceVar = [SELECT Id, Name FROM arce__Analysis__c LIMIT 1];
            Arc_Gen_ButtonsCMP_controller.getBtnCollection(arceVar.Name);
        } catch(Exception ex) {
            System.debug(ex.getMessage());
            System.assertEquals('Invalid id: Arce Analysis', ex.getMessage(), 'Exception getBtnCollection');
        }
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     31/03/2020
    * @return void
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getBtnCollectionRAIP() {
        Test.startTest();
        final arce__Analysis__c arceVar = [SELECT Id, arce__anlys_wkfl_sub_process_type__c FROM arce__Analysis__c WHERE Name = 'Arce Analysis1' LIMIT 1];
        final String res = Arc_Gen_ButtonsCMP_controller.getBtnCollection(arceVar.Id);
        System.assertEquals('Arc_Gen_RAIPPanel', res, 'Button collection Arc_Gen_RAIPPanel');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     31/03/2020
    * @return void
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyConstController() {
        Test.startTest();
        final Arc_Gen_ButtonsCMP_controller constructorServ = new Arc_Gen_ButtonsCMP_controller();
        System.assertEquals(constructorServ, constructorServ, 'Empty constructor');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     31/03/2020
    * @return void
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void emptyConstService() {
        Test.startTest();
        final Arc_Gen_ButtonsCMP_service constructorServ = new Arc_Gen_ButtonsCMP_service();
        System.assertEquals(constructorServ, constructorServ, 'Empty constructor');
        Test.stopTest();
    }
}