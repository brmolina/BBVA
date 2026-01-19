/**
* ____________________________________________________________________________
* Cuco Client Package Trigger Handler Test
* Trigger handler test.
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
public class CucoClientPackageTriggerHandler_Test {

    @TestSetup
    static void testSetup() {

        final Account accountParent = UnitTestUtils.GetStandardAccount();
        accountParent.Name = 'Account Test 0';
        accountParent.OwnerId = UserInfo.getUserId();
        accountParent.SER_CClient__c = '000000010';
        accountParent.DES_BBVA_Segmentation__c = 'C';
        accountParent.DES_Structure_Type__c = 'Group';
        insert accountParent;

        final Account accountChild = UnitTestUtils.GetStandardAccount();
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

        final Account accountChild2 = UnitTestUtils.GetStandardAccount();
        accountChild2.ParentId = accountParent.Id;
        accountChild2.Name = 'Account Test Child 2';
        accountChild2.OwnerId = UserInfo.getUserId();
        accountChild2.SER_CClient__c = '000000012';
        accountChild2.DES_BBVA_Segmentation__c = 'C';
        accountChild2.DES_Structure_Type__c = 'Subsidiary';
        accountChild2.DES_Entity_Type__c = 'Subsidiary';
        accountChild2.Merge_Insert__c = true;
        accountChild2.DES_ID_Fiscal__c = 'x1236';
        insert accountChild2;

        final Account accountChild3 = UnitTestUtils.GetStandardAccount();
        accountChild3.ParentId = accountParent.Id;
        accountChild3.Name = 'Account Test Child 3';
        accountChild3.OwnerId = UserInfo.getUserId();
        accountChild3.SER_CClient__c = '000000013';
        accountChild3.DES_BBVA_Segmentation__c = 'C';
        accountChild3.DES_Structure_Type__c = 'Subsidiary';
        accountChild3.DES_Entity_Type__c = 'Subsidiary';
        accountChild3.Merge_Insert__c = true;
        accountChild3.DES_ID_Fiscal__c = 'x1238';
        insert accountChild3;

        final List<cuco__ps_catalog_package__c> psCatalogPackages = cuco.Test_Utils.createPSCatalogPackage(3, 'G');
        psCatalogPackages[0].cuco__gf_psc_package_id__c = 'G0000';
        psCatalogPackages[1].cuco__gf_psc_package_id__c = 'F1234';
        psCatalogPackages[2].cuco__gf_psc_package_id__c = 'F1235';
        insert psCatalogPackages;

        final List<cuco__client_package__c> clientPackages = cuco.Test_Utils.createClientPackage(2, new List<Account>{accountChild, accountChild2, accountChild2}, psCatalogPackages);
        clientPackages[0].cuco__gf_cust_package_id__c = '0000';
        clientPackages[1].cuco__gf_cust_package_id__c = '1234';
        insert clientPackages;

    }

    @isTest
    static void constructorTest() {
        Test.startTest();
            final CucoClientPackageTriggerHandler instance = CucoClientPackageTriggerHandler.getInstance();
            System.assertEquals(instance, instance, 'get Instance');
        Test.stopTest();
    }

    // Check getRestudyBaseInfo exception
    @IsTest
    static void insertFailTest() {
        Test.startTest();

            final List<Account> accounts = [SELECT Id, SER_CClient__c, Name FROM Account WHERE Name = 'Account Test Child 3' LIMIT 1];
            final List<cuco__ps_catalog_package__c> psCatalogPackages = [SELECT Id, cuco__gf_psc_package_id__c FROM cuco__ps_catalog_package__c WHERE cuco__gf_psc_package_id__c = 'F1235' LIMIT 1];
            final List<cuco__client_package__c> clientPackages = cuco.Test_Utils.createClientPackage(1, accounts, psCatalogPackages);
            clientPackages[0].cuco__gf_cust_package_id__c = '8877';

            try {
                insert clientPackages;
            } catch (DmlException e) {
                System.assertNotEquals(null, e.getMessage(), 'Error at CucoClientPackageTriggerHandler_Test - insertFailTest');
            }
        Test.stopTest();
    }
}