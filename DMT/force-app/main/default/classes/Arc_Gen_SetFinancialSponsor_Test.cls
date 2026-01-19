/**
* --------------------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecRep_Service
* @Author   César Octavio Villanueva Ceballos  cesaroctavio.villanueva.cebal@bbva.com
* @Date     Created: 2020-05-13
* @Group    ARCE
* --------------------------------------------------------------------------------------------------------------
* @Description Test class for Arc_Gen_SetFinancialSponsor_Service class
* --------------------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-05-13 cesaroctavio.villanueva.cebal@bbva.com
*             Class creation.
* |2020-06-23 joseluis.garcia4.contractor@bbva.com
*             Modify reference to setFinancialSponsor method.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* ----------------------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_SetFinancialSponsor_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test group
    */
    static final string SUBSIDIARY_ID1 = 'C000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID2 = 'C000002';
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup for test
    * --------------------------------------------------------------------------------------
    * @Author   César Octavio Villanueva Ceballos cesaroctavio.villanueva.cebal@bbva.com
    * @Date     Created: 2020-05-13
    * @param void
    * @return void
    * @example Arc_Gen_SetFinancialSponsor_Test.setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;

        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID1,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);

        final arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100;300;400', '1', null);
        insert newSector;

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '1';
        insert newArce;

        final arce__Account_has_Analysis__c acc1 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, '1');
        acc1.arce__InReview__c = true;
        acc1.arce__path__c = 'MAC';
        acc1.arce__group_asset_header_type__c = '1';
        insert acc1;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for setFinancialSponsor method
    * --------------------------------------------------------------------------------------
    * @Author   César Octavio Villanueva Ceballos cesaroctavio.villanueva.cebal@bbva.com
    * @Date     Created: 2020-05-13
    * @param void
    * @return void
    * @example Arc_Gen_SetFinancialSponsor_Test.testUpdateFS()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testUpdateFS() {
        Test.startTest();
        arce__Analysis__c analysis = [SELECT Id,arce__controlled_by_sponsor_type__c FROM arce__Analysis__c LIMIT 1];
        Arc_Gen_SetFinancialSponsor_Service.setFinancialSponsorAndUpdate(analysis.Id);
        analysis = [SELECT Id,arce__controlled_by_sponsor_type__c FROM arce__Analysis__c LIMIT 1];
        System.assertEquals('1', analysis.arce__controlled_by_sponsor_type__c, 'Not the expected value');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   César Octavio Villanueva Ceballos cesaroctavio.villanueva.cebal@bbva.com
    * @Date     Created: 2020-05-13
    * @param void
    * @return void
    * @example Arc_Gen_SetFinancialSponsor_Test.testContructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructor() {
        Test.startTest();
        final Arc_Gen_SetFinancialSponsor_Service data = new Arc_Gen_SetFinancialSponsor_Service();
        system.assertEquals(data, data, 'The test to the void contructor was successfull');
        Test.stopTest();
    }

}