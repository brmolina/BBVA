/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_StatusButtons_Test
* @Author   Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
* @Date     Created: 27/03/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description test for method class Arc_Gen_StatusButtons.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-03 Angel Fuertes Gomez
*             Class creation.
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Modification of setup method in order to increment code coverage
* |2020-01-09 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_StatusButtons_Test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_StatusButtons_Test
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example Arc_Gen_StatusButtons_Test.setup()
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

        final arce__Account_has_Analysis__c newAnalysis = arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        insert newAnalysis;

        Arc_UtilitysDataTest_tst.createBasicDataData();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method to Arc_Gen_StatusButtons
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example Arc_Gen_StatusButtons.getDynamicButtonStatusTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getDynamicButtonStatusTest() {
        final arce__Account_has_Analysis__c arceVar = [Select Id from arce__Account_has_Analysis__c limit 1];
        arce.Arc_Gen_StatusButtons clase = new arce.Arc_Gen_StatusButtons();
        Test.startTest();
        final Set<String> ltsValues = clase.getDynamicButtonStatus(arceVar.Id, 'arce__Analysis__c');
        System.assertEquals(true,ltsValues.isEmpty(), 'The result is empty');
        Test.stopTest();
    }
}