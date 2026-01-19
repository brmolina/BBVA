/**
* ────────────────────────────────────────────────────────────────────
* Cuco Participants CIB Test
* Test class of the Participant_itf interface methods for CIB
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-08-21
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@IsTest
public class CucoParticipantCIB_Test {

    @TestSetup
    static void makeDataOfParticipantSample() {

        // Create account supra
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        List<Account> accounts = getAccounts();
        Account sampleAccountSupra = accounts[0];
        Account sampleAccountParent = accounts[1];
        Account sampleAccountChild1 = accounts[2];
        Account sampleAccountChild2 = accounts[3];

        // create relationships
        final List<dwp_acmh__GBL_Account_Relationship__c> relationships =  new List<dwp_acmh__GBL_Account_Relationship__c>();
        final dwp_acmh__GBL_Account_Relationship__c relationship1 = utilClass.createAccRelationship(sampleAccountSupra, sampleAccountParent);
        relationships.add(relationship1);

        final dwp_acmh__GBL_Account_Relationship__c relationship2 = utilClass.createAccRelationship(sampleAccountParent, sampleAccountChild1);
        relationships.add(relationship2);

        final dwp_acmh__GBL_Account_Relationship__c relationship3 = utilClass.createAccRelationship(sampleAccountParent, sampleAccountChild2);
        relationships.add(relationship3);

        insert relationships;

        // Create profitability sheets
        final List<cuco__profitability_sheet__c> lstPS = cuco.Test_Utils.createProfSheet(2, sampleAccountParent);
        lstPS[0].cuco__gf_profitability_sheet_id__c = 'ES0182000000010';
        lstPS[1].cuco__gf_profitability_sheet_id__c = 'ES0182000000020';
        lstPS[1].cuco__participant_id__c = sampleAccountChild2.Id;
        insert lstPS;

        final List<cuco__profitability_analysis__c> lstPA = cuco.Test_Utils.createProfAnalysis(2, sampleAccountParent);
        lstPA[0].cuco__gf_pa_management_type_name__c = 'New';
        lstPA[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstPA[0].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';

        lstPA[1].cuco__gf_pa_management_type_name__c = 'Cancellation';
        lstPA[1].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstPA[1].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
        lstPA[1].cuco__gf_profitability_sheet_id__c = lstPS[1].Id;
        insert lstPA;

        // create participants
        final List<cuco__profitability_sheet_participant__c> lstPSP = cuco.Test_Utils.createProfSheetParticipant(1, lstPS[0].Id, new List<Id>{sampleAccountChild1.Id});
        insert lstPSP;

        final List<cuco__profitability_sheet_participant__c> lstPSP2 = cuco.Test_Utils.createProfSheetParticipant(1, lstPS[1].Id, new List<Id>{sampleAccountChild2.Id});
        insert lstPSP2;
    }

    private static List<Account> getAccounts() {

        // Create account supra
        final Id groupRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        final Id supraRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('SupraGroup').getRecordTypeId();

        final Account sampleAccountSupra = UnitTestUtils.GetStandardAccount();
        sampleAccountSupra.Name = 'Account Test SupraGroup';
        sampleAccountSupra.OwnerId = UserInfo.getUserId();
        sampleAccountSupra.SER_CClient__c = '000000020';
        sampleAccountSupra.DES_BBVA_Segmentation__c = 'C';
        sampleAccountSupra.DES_Structure_Type__c = 'SupraGroup';
        sampleAccountSupra.RecordTypeId = supraRecordTypeId;
        insert sampleAccountSupra;

        // Create account parent
        final Account sampleAccountParent = UnitTestUtils.GetStandardAccount();
        sampleAccountParent.DES_Main_Parent__c = sampleAccountParent.Id;
        sampleAccountParent.Name = 'Account Test 0';
        sampleAccountParent.OwnerId = UserInfo.getUserId();
        sampleAccountParent.SER_CClient__c = '000000010';
        sampleAccountParent.DES_BBVA_Segmentation__c = 'C';
        sampleAccountParent.DES_Structure_Type__c = 'Group';
        sampleAccountParent.ParentId = sampleAccountSupra.Id;
        sampleAccountParent.RecordTypeId = groupRecordTypeId;
        insert sampleAccountParent;

        // Create account child
        final Account sampleAccountChild1 = UnitTestUtils.GetStandardAccount();
        sampleAccountChild1.DES_Main_Parent__c = sampleAccountParent.Id;
        sampleAccountChild1.ParentId = sampleAccountParent.Id;
        sampleAccountChild1.Name = 'Account Test Child 0';
        sampleAccountChild1.OwnerId = UserInfo.getUserId();
        sampleAccountChild1.SER_CClient__c = '000000011';
        sampleAccountChild1.DES_BBVA_Segmentation__c = 'C';
        sampleAccountChild1.DES_Structure_Type__c = 'Subsidiary';
        sampleAccountChild1.DES_Entity_Type__c = 'Subsidiary';
        sampleAccountChild1.Merge_Insert__c = true;
        sampleAccountChild1.DES_ID_Fiscal__c = 'x1234';
        insert sampleAccountChild1;

        // Create account child
        final Account sampleAccountChild2 = UnitTestUtils.GetStandardAccount();
        sampleAccountChild2.DES_Main_Parent__c = sampleAccountParent.Id;
        sampleAccountChild2.ParentId = sampleAccountParent.Id;
        sampleAccountChild2.Name = 'Account Test Child 1';
        sampleAccountChild2.OwnerId = UserInfo.getUserId();
        sampleAccountChild2.SER_CClient__c = '000000021';
        sampleAccountChild2.DES_BBVA_Segmentation__c =  'C';
        sampleAccountChild2.DES_Structure_Type__c = 'Subsidiary';
        sampleAccountChild2.DES_Entity_Type__c = 'Subsidiary';
        sampleAccountChild2.Merge_Insert__c = true;
        sampleAccountChild2.DES_ID_Fiscal__c = 'x1235';
        insert sampleAccountChild2;

        return new List<Account>{sampleAccountSupra, sampleAccountParent, sampleAccountChild1, sampleAccountChild2};
    }

    // Test getParticipantDetails method
    @IsTest
    static void getParticipantDetailsTest1() {

        Test.startTest();
            final List<Account> lstAcc = [SELECT Id, Name, Rating, SER_CClient__c FROM Account WHERE Name = 'Account Test Child 0' LIMIT 1];
            final List<cuco.Participant_Wrapper> expectedWrapper = new List<cuco.Participant_Wrapper>();
            final cuco.Participant_Wrapper pWrapp = new cuco.Participant_Wrapper();
            pWrapp.participantId = lstAcc[0].Id;
            pWrapp.participantName = lstAcc[0].Name;
            pWrapp.documentNumber = lstAcc[0].SER_CClient__c;
            pWrapp.documentType = 'CIF';
            pWrapp.documentTypeCode = '2';
            pWrapp.participantCode = lstAcc[0].SER_CClient__c;
            pWrapp.participantIntegrationId = 'ES0182' + lstAcc[0].SER_CClient__c + 'C';
            pWrapp.isCustomer = true;
            pWrapp.rating = lstAcc[0].Rating;
            expectedWrapper.add(pWrapp);
            CucoParticipantCIB partSample = new CucoParticipantCIB();
            final List<cuco.Participant_Wrapper> actualWrapper = partSample.getParticipantDetails(new Set<Id>{lstAcc[0].Id});
            System.assertEquals(expectedWrapper[0].participantId, actualWrapper[0].participantId, 'Error at CucoParticipantCIB_Test getPartipantDetailsTest1');
        Test.stopTest();

    }

    // Test getParticipantsToSelect method
    @IsTest
    static void getParticipantDetailsTest2() {

        Test.startTest();
            final List<Account> lstAcc = [SELECT Id, Name, Rating, SER_CClient__c FROM Account WHERE Name = 'Account Test 0' LIMIT 1];
            final List<cuco.Participant_Wrapper> expectedWrapper = new List<cuco.Participant_Wrapper>();

            final cuco.Participant_Wrapper pWrapp = new cuco.Participant_Wrapper();
            pWrapp.participantId = lstAcc[0].Id;
            pWrapp.participantName = lstAcc[0].Name;
            pWrapp.documentNumber = lstAcc[0].SER_CClient__c;
            pWrapp.documentType = 'CIF';
            pWrapp.documentTypeCode = '2';
            pWrapp.participantCode = lstAcc[0].SER_CClient__c;
            pWrapp.participantIntegrationId = 'ES0182' + lstAcc[0].SER_CClient__c + 'C';
            pWrapp.isCustomer = true;
            pWrapp.rating = lstAcc[0].Rating;
            expectedWrapper.add(pWrapp);

            final CucoParticipantCIB partSample = new CucoParticipantCIB();
            final List<cuco.Participant_Wrapper> actualWrapper = partSample.getParticipantsToSelect(new Set<Id>{lstAcc[0].Id}, UserInfo.getUserId());
            System.assertEquals(expectedWrapper[0].participantId, actualWrapper[0].participantId, 'Error at CucoParticipantCIB_Test getPartipantDetailsTest2');
        Test.stopTest();
    }

    // Test getPartipantHierarchy method
    @IsTest
    static void getParticipantHierarchy1() {
        Test.startTest();
            final List<Account> lstAcc = [SELECT Id, Name, Rating, SER_CClient__c FROM Account WHERE Name = 'Account Test 0' LIMIT 1];
            final cuco.ParticipantHierarchy_Wrapper expectedWrapper = new cuco.ParticipantHierarchy_Wrapper();
            final CucoParticipantCIB partSample = new CucoParticipantCIB();
            final cuco.ParticipantHierarchy_Wrapper actualWrapper = partSample.getParticipantHierarchy(lstAcc[0].Id);
            System.debug(actualWrapper);
            System.assertEquals(expectedWrapper, expectedWrapper, 'Error at CucoParticipantCIB_Test getParticipantHierarchy1');
        Test.stopTest();
    }

    // Test getPartipantHierarchy method
    @IsTest
    static void getParticipantHierarchy2() {
        Test.startTest();
            final List<Account> lstAcc = [SELECT Id, Name, Rating, SER_CClient__c FROM Account WHERE Name = 'Account Test SupraGroup' LIMIT 1];
            final cuco.ParticipantHierarchy_Wrapper expectedWrapper = new cuco.ParticipantHierarchy_Wrapper();
            final CucoParticipantCIB partSample = new CucoParticipantCIB();
            final cuco.ParticipantHierarchy_Wrapper actualWrapper = partSample.getParticipantHierarchy(lstAcc[0].Id);
            System.debug(actualWrapper);
            System.assertEquals(expectedWrapper, expectedWrapper, 'Error at CucoParticipantCIB_Test getParticipantHierarchy2');
        Test.stopTest();
    }

    // Test getPartipantHierarchy method
    @IsTest
    static void getPartipantHierarchy3() {
        Test.startTest();
            final List<Account> lstAcc = [SELECT Id, Name, Rating, SER_CClient__c FROM Account WHERE Name = 'Account Test Child 0' LIMIT 1];
            final cuco.ParticipantHierarchy_Wrapper expectedWrapper = new cuco.ParticipantHierarchy_Wrapper();
            final CucoParticipantCIB partSample = new CucoParticipantCIB();
            final cuco.ParticipantHierarchy_Wrapper actualWrapper = partSample.getParticipantHierarchy(lstAcc[0].Id);
            System.debug(actualWrapper);
            System.assertEquals(expectedWrapper, expectedWrapper, 'Error at CucoParticipantCIB_Test getPartipantHierarchy3');
        Test.stopTest();
    }

    // Test getPartipantHierarchy method
    @IsTest
    static void getPartipantIdsTest() {
        Test.startTest();
            final List<cuco__profitability_sheet_participant__c> participants = [SELECT Id, cuco__participant_id__c, cuco__participant_id__r.Name, cuco__participant_id__r.SER_CClient__c FROM cuco__profitability_sheet_participant__c WHERE cuco__participant_id__r.Name = 'Account Test Child 0' LIMIT 1];
            Set<String> integrationIds = new Set<string>{'ES0182000000011'};
            Map<String, Id> expected = new Map<String, Id>{participants[0].cuco__participant_id__r.SER_CClient__c => participants[0].cuco__participant_id__c};
            Map<String, Id> participantIds = CucoParticipantCIB.getParticipantsIds(integrationIds);
            System.assertEquals(expected, participantIds, 'Error at CucoParticipantCIB_Test getPartipantIdsTest');
        Test.stopTest();
    }

}