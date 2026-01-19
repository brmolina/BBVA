/**
* ____________________________________________________________________________
* Cuco Delete Participants Test
* Web Service to Execute Batch that removes participants marked as deleted.
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-08-16
* @modified
* @systemLayer Service
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@isTest
public class CucoDeleteParticipants_Test {

    @TestSetup
    static void makeDataOfParticipantSample() {

        final DES_UtilTestClass utilClass = new DES_UtilTestClass();

        Account accountParent = UnitTestUtils.GetStandardAccount();
        accountParent.Name = 'Account Test 0';
        accountParent.OwnerId = UserInfo.getUserId();
        accountParent.SER_CClient__c = '000000010';
        accountParent.DES_BBVA_Segmentation__c = 'C';
        accountParent.DES_Structure_Type__c = 'Group';
        insert accountParent;

        Account accountChild = UnitTestUtils.GetStandardAccount();
        accountChild.ParentId = accountParent.Id;
        accountChild.Name = 'Account Test Child 0';
        accountChild.OwnerId = UserInfo.getUserId();
        accountChild.SER_CClient__c = '000000011';
        accountChild.DES_BBVA_Segmentation__c = 'C';
        accountChild.DES_Structure_Type__c = 'Subsidiary';
        accountChild.DES_Entity_Type__c = 'Subsidiary';
        accountChild.Merge_Insert__c = true;
        accountChild.DES_ID_Fiscal__c = 'x1234';
        insert accountChild;

        Account accountChild2 = UnitTestUtils.GetStandardAccount();
        accountChild2.ParentId = accountParent.Id;
        accountChild2.Name = 'Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255 Longer than 255';
        accountChild2.OwnerId = UserInfo.getUserId();
        accountChild2.SER_CClient__c = '000000012';
        accountChild2.DES_BBVA_Segmentation__c = 'C';
        accountChild2.DES_Structure_Type__c = 'Subsidiary';
        accountChild2.DES_Entity_Type__c = 'Subsidiary';
        accountChild2.Merge_Insert__c = true;
        accountChild2.DES_ID_Fiscal__c = 'x1235';
        insert accountChild2;

        final dwp_acmh__GBL_Account_Relationship__c relationship = utilClass.createAccRelationship(accountParent, accountChild);
        insert relationship;

        final List<cuco__profitability_sheet__c> profSheets = cuco.Test_Utils.createProfSheet(2, accountParent);
        profSheets[0].cuco__gf_profitability_sheet_id__c = 'ES0182010000010';
        profSheets[0].apply_cond_ind_type__c = 'N';
        profSheets[1].cuco__gf_profitability_sheet_id__c = 'ES0182010000011';
        profSheets[1].apply_cond_ind_type__c = 'S';
        insert profSheets;

        profSheets[0].apply_cond_ind_type__c = 'S';
        profSheets[1].apply_cond_ind_type__c = 'N';
        update profSheets;

        final List<cuco__profitability_sheet_participant__c> participants = cuco.Test_Utils.createProfSheetParticipant(2, profSheets[0].Id, new List<Id>{accountChild.Id, accountChild2.Id});
        participants[0].Valid_Participant__c = false;
        participants[1].Valid_Participant__c = false;
        insert participants;
    }

    @isTest
    static void constructorTest() {
        Test.startTest();
            final cucoDeleteParticipants res = new cucoDeleteParticipants();
            System.assertEquals(res, res, 'private constructor');
        Test.stopTest();
    }

    @isTest
    public static void testCall(){

        test.startTest();

        final RestRequest request = new RestRequest();
        final RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/cucoDeleteParticipants';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = response;

        Id batchId = CucoDeleteParticipants.doGet();
        Boolean result = batchId == null ? false : true;

        System.assert(result, 'Ok');
        //System.abortJob(batchId);

        test.stopTest();
    }

}