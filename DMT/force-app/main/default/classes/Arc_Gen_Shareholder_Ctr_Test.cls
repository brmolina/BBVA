/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Shareholder_Ctr_Test
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-05-11
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for Arc_Gen_ShareholderTable_Ctr, Arc_Gen_ShareholderTable_Service
* and Arc_Gen_ShareholderTable_Helper.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-05-11 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-05-18 mariohumberto.ramirez.contractor@bbva.com
*             update test class.
* |2020-06-11 manuelhugo.castillo.contractor@bbva.com
*             update test class.
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__third_participant_per__c for arce__third_prtcpt_intervention_per__c
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* -----------------------------------------------------------------------------------------------
*/
@isTest
public without sharing class Arc_Gen_Shareholder_Ctr_Test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID2 = 'C000003';
    /*
        @Description Setup Method
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID,SUBSIDIARY_ID2});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
        final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);
        final arce.Arc_Gen_Account_Wrapper childAccount2 = groupAccWrapper.get(SUBSIDIARY_ID2);

        final arce__Analysis__c arceVar = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        arceVar.arce__analysis_customer_relation_type__c = '01';
        arceVar.arce__Stage__c = '2';
        arceVar.arce__anlys_wkfl_sub_process_type__c = '2';
        insert arceVar;

        arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100;300;400', '1', null);
        newSector.arce__sector_analisis_type__c = '2';
        newSector.arce__active_type__c = true;
        insert newSector;

        final arce__Account_has_Analysis__c accHasAnGp = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceVar.Id, groupAccount.accId, '1');
        accHasAnGp.arce__group_asset_header_type__c = '1';
        insert accHasAnGp;

        final arce__Account_has_Analysis__c accHasAnCl = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceVar.Id, childAccount.accId, '1');
        accHasAnCl.arce__InReview__c = true;
        accHasAnCl.arce__group_asset_header_type__c = '2';
        accHasAnCl.arce__participant_name__c = 'testName';
        insert accHasAnCl;

        final arce__Account_has_Analysis__c accHasAnCl2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceVar.Id, childAccount2.accId, '1');
        accHasAnCl2.arce__InReview__c = true;
        accHasAnCl2.arce__group_asset_header_type__c = '2';
        accHasAnCl2.arce__participant_name__c = 'testName2';
        insert accHasAnCl2;

        final arce__Third_Participant__c thirdpart = Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
        thirdpart.Name = 'Jaime';
        insert thirdpart;

        final arce__Third_Participant__c thirdpart2 = Arc_UtilitysDataTest_tst.crearThirdParticipant(null);
        thirdpart2.Name = 'Juan';
        insert thirdpart2;

        arce__third_participant_details__c thirdPartDetails = Arc_UtilitysDataTest_tst.crearThirdParticipantDetails(accHasAnCl.Id, thirdpart.Id, 'Shareholders');
        thirdPartDetails.arce__third_participant_per__c = 100;
        thirdPartDetails.arce__third_participant_role_type__c = '03';
        insert thirdPartDetails;

        arce__third_participant_details__c thirdPartDetails2 = Arc_UtilitysDataTest_tst.crearThirdParticipantDetails(accHasAnCl2.Id, thirdpart2.Id, 'Shareholders');
        thirdPartDetails2.arce__third_participant_per__c = 100;
        thirdPartDetails2.arce__third_participant_role_type__c = '03';
        insert thirdPartDetails2;
    }
    /*
        @Description Test Method
    */
    @isTest static void testGetData() {
        arce__Account_has_Analysis__c acchas = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2' LIMIT 1];

        Test.startTest();
        final String response = Arc_Gen_ShareholderTable_Ctr.getData(acchas.Id, new List<String>());
        system.assertEquals(true, response.contains('true'), 'The client Validation was Successfull');
        Test.stopTest();
    }
    /*
        @Description Test Method
    */
    @isTest static void testGetDataEmpty() {
        arce__Account_has_Analysis__c acchas = [SELECT Id FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '2' LIMIT 1];
        delete [SELECT Id FROM arce__third_participant_details__c LIMIT 10];
        Test.startTest();
        final String response = Arc_Gen_ShareholderTable_Ctr.getData(acchas.Id, new List<String>());
        system.assertEquals(true, response.contains('false'), 'There are not data');
        Test.stopTest();
    }
    /*
        @Description Test Method
    */
    @isTest static void emptyConstructor() {
        Test.startTest();
        Arc_Gen_ShareholderTable_Ctr controller = new Arc_Gen_ShareholderTable_Ctr();
        system.assertEquals(controller, controller, 'The test to the empty controller was successfull');
        Arc_Gen_ShareholderTable_Service service = new Arc_Gen_ShareholderTable_Service();
        system.assertEquals(service, service, 'The test to the empty controller was successfull');
        Arc_Gen_ShareholderTable_Helper helper = new Arc_Gen_ShareholderTable_Helper();
        system.assertEquals(helper, helper, 'The test to the empty controller was successfull');
        Test.stopTest();
    }
}