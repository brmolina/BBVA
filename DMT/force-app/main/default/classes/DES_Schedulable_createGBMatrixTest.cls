@isTest
public class DES_Schedulable_createGBMatrixTest{

    @isTest
    public static void DES_Schedulable_createGBMatrixTest(){

        Test.startTest();
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        Id rtSubsidiary = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Subsidiary').getRecordTypeId();
        Id rtGroup = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Account acc1 = testClass.createClient();
        acc1.DES_Structure_Type__c = Label.DES_STR_TYPE_Supragroup;
        acc1.DES_BBVA_Segmentation__c = Label.DES_Segmentation_B_BEC;
        acc1.RecordTypeId = rtGroup;
        insert acc1;
        Account acc2 = testClass.createClient();
        acc2.RecordTypeId = rtSubsidiary;
        acc2.DES_Main_Parent__c = acc1.id;
        insert acc2;
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        DES_BBVA_Management_team__c teamMember = new DES_BBVA_Management_team__c();
        teamMember.DES_User__c = userTest.Id;
        teamMember.DES_Local_Banker_Country__c = 'ES';
        teamMember.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
        teamMember.DES_Client__c = acc1.Id;
        insert teamMember;
        AMH_GBL_Account_Relationship__c relAccount = new AMH_GBL_Account_Relationship__c();
        relAccount.AMH_Parent_Account__c = acc1.Id;
        relAccount.AMH_Child_Account__c = acc2.Id;
        relAccount.AMH_Vision__c = 'Riesgo';
        insert relAccount;

        String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_createGBMatrix ());
        System.assertNotEquals(jobId, null);
        Test.stopTest();
    }


}