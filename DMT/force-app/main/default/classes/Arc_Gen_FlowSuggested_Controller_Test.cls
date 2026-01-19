/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FlowSuggested_Controller
* @Author   Isabel Ascaso - isabel.ascaso.contractor@bbva.com
* @Date     Created: 2023-11-13
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for Arc_Gen_FlowSuggested_controller
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2023-11-13 isabel.ascaso.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class Arc_Gen_FlowSuggested_Controller_Test {
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
        final String participant = Arc_Gen_FlowSuggested_Controller.getParticipantType(aha.Id);
        system.assertEquals('GROUP', participant, 'Incorrect participant');
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
    @isTest static void updateExtensionTriageTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id, arce__AHA_Extension__c FROM arce__Account_has_Analysis__c  LIMIT 1];
        final Map<String, String> formDataMap = new Map<String, String>();
        formDataMap.put('arce__RAR_rating_tool_id__c', 'Corportes');
        formDataMap.put('arce__legal_EEFF__c', 'false');

        Test.startTest();
        Arc_Gen_FlowSuggested_Controller.updateExtensionTriage(aha.Id, formDataMap);

        final arce__Account_has_Analysis__c ahaUpdated = [SELECT Id, arce__RAR_rating_tool_id__c FROM arce__Account_has_Analysis__c  LIMIT 1];
        system.assertEquals('Corportes', ahaUpdated.arce__RAR_rating_tool_id__c, 'Incorrect arce__RAR_rating_tool_id__c');
        Test.stopTest();

    }
}