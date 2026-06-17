/**
* @File Name          : Arc_Gen_UploadAndViewFile_Test.cls
* @Description        : test for method class Arc_Gen_UploadAndViewFile_Test.
* @Author             : -
* @Group              : ARCE
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 07-09-2025
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    -          -     Initial Version
**/
@isTest
public class Arc_Gen_UploadAndViewFile_Test {
    @testSetup static void setup() {
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        utilTestClass.createCustomSettingByPass();

        ContentVersion contentVersion = new ContentVersion(
          Title = 'Penguins',
          PathOnClient = 'Penguins.pdf',
          VersionData = Blob.valueOf('Test Content'),
          FirstPublishLocationId=groupAccount.accId
        );
        insert contentVersion;
    }

    @isTest static void getIdConttst() {
        Account accHasAnls = [Select Id from Account limit 1];
        ContentDocument contentDoc = [Select Id from ContentDocument limit 1];
        Test.startTest();
        String idDoc = Arc_Gen_UploadAndViewFile_Ctrl.getIdCont(accHasAnls.Id, 'Penguins');
        System.assertEquals(contentDoc.Id,idDoc,'Matches');
        Test.stopTest();
    }

    @isTest static void updateFiletst() {
        ContentDocument contentDoc = [Select Id from ContentDocument limit 1];
        Test.startTest();
        boolean respon = Arc_Gen_UploadAndViewFile_Ctrl.updateFile(contentDoc.Id, 'Penguins', 'prueba');
        System.assertEquals(true,respon,'Matches');
        Test.stopTest();
    }

    @isTest static void updateFileErrortst() {
        Test.startTest();
        boolean respon = Arc_Gen_UploadAndViewFile_Ctrl.updateFile(null, 'Penguins', 'prueba');
        System.assertEquals(false,respon,'Matches');
        Test.stopTest();
    }
}