/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_Container_Ctrl_Test
* Test class for DPMX_CompanyComparisonAdd_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-09-26
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class DPMX_CompanyComparisonAdd_Ctrl_Test {
    @TestSetup
    static void createData() {
        Account acc = new Account();
        acc.Name = 'AccountTest';
        insert acc;
        
        Account acc2 = new Account();
        acc2.Name = 'AccountTest2';
        insert acc2;
        
        Local_Client__c locCli = new Local_Client__c();
        locCli.unique_id__c ='1111111';
        locCli.Name ='GRUPO AccountTest';
        locCli.Cib_Client__c = acc.Id;
        insert locCli;
        
        DPMX_Dynamic_Pricing__c dynamicPricingTest = new DPMX_Dynamic_Pricing__c();
        dynamicPricingTest.Name = 'Dynamic Pricing Test';
        dynamicPricingTest.Product__c = 'Acquirer';
        dynamicPricingTest.Client__c = acc.id;
        dynamicPricingTest.Company_Name__c = acc.Id;
        dynamicPricingTest.Frequency_of_Revision__c = 'Biannual';
        dynamicPricingTest.familia__c = 'Otro';
        dynamicPricingTest.familia_AcquiererCategories_Id__c = '13';
        String newDycPrgJSON = JSON.serialize(dynamicPricingTest);
        insert dynamicPricingTest;
        
        DPMX_Company_Comparison__c compCompar = new DPMX_Company_Comparison__c(
        	companyName__c = 'TestCompani',
            Dynamic_Pricing__c = dynamicPricingTest.Id,
            groupName__c = 'TestGroup',
            isGs__c = true,
            Debit__c = 11,
            Credit__c = 11,
            International__c = 11,
            isVisible__c = true
        );
        insert compCompar;
    }
    @isTest
    static void testGetInitialData() {
        DPMX_Dynamic_Pricing__c dynPR = [SELECT id FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        Test.startTest();
        Map<String, Object> result = DPMX_CompanyComparisonAdd_Ctrl.getData(dynPR.Id);
        Test.stopTest();
        System.assertEquals(result.get('success'), true);
    }
    
    @isTest
    static void saveData() {
        DPMX_Dynamic_Pricing__c dynPR = [SELECT id FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        List<Account> accLst = [SELECT id FROM Account LIMIT 2];
        List<String> accountsSelected = new List<String>();
        for(Account acc : accLst){
            accountsSelected.add(acc.Id);
        }
        Test.startTest();
        Map<String, Object> result = DPMX_CompanyComparisonAdd_Ctrl.saveData(dynPR.Id, accountsSelected);
        Test.stopTest();
        System.assertEquals(result.get('success'), true, 'saveData');
    }
}