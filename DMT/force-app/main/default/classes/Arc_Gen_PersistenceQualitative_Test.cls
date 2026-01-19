/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistenceQualitative_Test
* @Author   José Luis García Díaz joseluis.garcia4.contractor@bbva.com
* @Date     Created: 12/05/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers:  Arc_Gen_PersistenceQualitative_Service and Arc_Gen_PersistenceQualitative_Data
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-05-12 joseluis.garcia4.contractor@bbva.com
*             Class creation.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__Institution_type__c value
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* -----------------------------------------------------------------------------------------------
*/
@IsTest
public class Arc_Gen_PersistenceQualitative_Test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method. Creates accounts, analysis and AHA.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * --------------------------------------------------------------------------------------
    **/
    @testSetup
    static void setupTest() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '1';
        insert newArce;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__Institution_type__c = 'Private';
        insert newAnalysis;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method. Tests the persistence of variables.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testPersistVariablesAnalysis() {
        final arce__Account_has_Analysis__c aha = [SELECT arce__Institution_type__c FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Arc_Gen_PersistenceQualitative_Service.VariablePersistenceResult response = Arc_Gen_PersistenceQualitative_Service.persistVariablesOfAnalysis(aha);
        Test.stopTest();

        System.assertEquals('200', response.serviceCode, 'Service call must have been successful');
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method. Tests the correct result when no variables are persisted.
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testPersistVariablesAnalysisNoVars() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Arc_Gen_PersistenceQualitative_Service.VariablePersistenceResult response = Arc_Gen_PersistenceQualitative_Service.persistVariablesOfAnalysis(aha);
        Test.stopTest();

        System.assertEquals('200', response.serviceCode, 'Service call must have been successful');
    }
}