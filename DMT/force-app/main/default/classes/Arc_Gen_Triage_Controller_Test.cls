/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Triage_Controller_Test
* @Author   Isabel Ascaso - isabel.ascaso.contractor@bbva.com
* @Date     Created: 2023-07-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2023-07-24 isabel.ascaso.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class Arc_Gen_Triage_Controller_Test {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Test method
    * ----------------------------------------------------------------------------------------------------
    * @author isabel.ascaso.contractor@bbva.com
    * @date 2023-07-24
    * @param void
    * @return void
    * @example Arc_Gen_Triage_Controller_Test.setup()
    * ----------------------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final User usuarioA = Arc_UtilitysDataTest_tst.crearUsuario('Secreta','System Administrator', null);
        insert usuarioA;

        final arce__Analysis__c newAnalysis = new arce__Analysis__c();
        newAnalysis.Name = 'Analysis';
        newAnalysis.arce__Group__c = groupAccount.accId;
        newAnalysis.OwnerId = usuarioA.Id;
        newAnalysis.arce__wf_status_id__c = '01';
        insert newAnalysis;

        final arce__AHA_Extension__c ahaExtGrp = new arce__AHA_Extension__c();
        insert ahaExtGrp;

        final arce__Account_has_Analysis__c ahaTest = new arce__Account_has_Analysis__c();
        ahaTest.arce__Analysis__c = newAnalysis.Id;
        ahaTest.arce__Customer__c = groupAccount.accId;
        ahaTest.arce__Stage__c = '3';
        ahaTest.arce__InReview__c = true;
        ahaTest.arce__AHA_Extension__c = ahaExtGrp.Id;
        insert ahaTest;

    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method test for returnFlowSub
    * --------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.contractor@bbva.com
    * @param void
    * @return void
    * @example returnFlowSubTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void returnFlowSubTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__AHA_Extension__c FROM arce__Account_has_Analysis__c  LIMIT 1];
        final arce__AHA_Extension__c ahaExtension = [SELECT arce__level_Shell__c, arce__filial_Core__c, arce__group_corporative__c, arce__matrizIg__c, arce__legal_EEFF__c, arce__conditions_8116__c, arce__explicit_guarantee__c, arce__parametry5__c, arce__bank_spain__c, arce__group_treasury_subsidiary__c FROM arce__AHA_Extension__c LIMIT 1];
        ahaExtension.arce__group_corporative__c = true;
        ahaExtension.arce__filial_Core__c = true;
        ahaExtension.arce__explicit_guarantee__c = true;
        update ahaExtension;

        Test.startTest();
        final String flow = Arc_Gen_Triage_Controller.returnFlow(aha.Id, 'SUBSIDIARY');
        system.assertEquals('2021RTC_EG', flow, 'Incorrect flow');
        Test.stopTest();

    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method test for returnFlowGroup
    * --------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.contractor@bbva.com
    * @param void
    * @return void
    * @example returnFlowGroupTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void returnFlowGroupTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__AHA_Extension__c FROM arce__Account_has_Analysis__c  LIMIT 1];
        final arce__AHA_Extension__c ahaExtension = [SELECT arce__level_Shell__c, arce__filial_Core__c, arce__group_corporative__c, arce__matrizIg__c, arce__legal_EEFF__c, arce__conditions_8116__c, arce__explicit_guarantee__c, arce__parametry5__c, arce__bank_spain__c, arce__group_treasury_subsidiary__c FROM arce__AHA_Extension__c LIMIT 1];
        ahaExtension.arce__level_Shell__c = true;
        update ahaExtension;

        Test.startTest();
        final String flow = Arc_Gen_Triage_Controller.returnFlow(aha.Id, 'GROUP');
        system.assertEquals('2021RTC_GEN', flow, 'Incorrect flow');
        Test.stopTest();

    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method test for returnFlowGroup
    * --------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.contractor@bbva.com
    * @param void
    * @return void
    * @example returnFlowGroupTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void returnJsonFlowTest() {
        Test.startTest();
        final String flow = Arc_Gen_Triage_Controller.returnJsonFlow();
        system.assertNotEquals(null, flow, 'Incorrect flow');
        Test.stopTest();

    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method test for getParticipantType
    * --------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.contractor@bbva.com
    * @param void
    * @return void
    * @example getParticipantTypeTest()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void getParticipantTypeTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__AHA_Extension__c FROM arce__Account_has_Analysis__c  LIMIT 1];

        Test.startTest();
        final String participant = Arc_Gen_Triage_Controller.getParticipantType(aha.Id);
        system.assertEquals('GROUP', participant, 'Incorrect participant');
        Test.stopTest();

    }
}