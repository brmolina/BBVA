/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_Simulator_Ctrl_Test
* Test class for DPMX_Simulator_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-07-22
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class DPMX_Simulator_Ctrl_Test {
	@TestSetup
    static void createData() {
        Account acc = new Account();
        acc.Name = 'AccountTest';
        insert acc;
        
        Account acc1 = new Account();
        acc1.Name = 'AccountTest1';
        insert acc1;
        
        acc.DES_Main_Parent__c = acc1.id;
        update acc;
        
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
    }
    @IsTest
    static void getDataTest(){   
        createData();
        Account acc = [SELECT Id FROM Account WHERE Name = 'AccountTest' LIMIT 1];
        DPMX_Dynamic_Pricing__c dynamicPricingTest = [SELECT Id
                                                    FROM DPMX_Dynamic_Pricing__c 
                                                   	WHERE Client__c=:acc.Id  LIMIT 1];
        Test.startTest();
           	Map<String, Object> retMap = DPMX_Simulator_Ctrl.getData(dynamicPricingTest.Id); 
       		System.assertEquals(retMap.get('success'), true,'getDataTest OK');
        	DPMX_Dynamic_Pricing__c dynamicPricing = (DPMX_Dynamic_Pricing__c)retMap.get('dynamicPricing');
        	System.assertEquals(dynamicPricing.Id, dynamicPricingTest.Id, 'retMapDynamicPricing OK');
        Test.stopTest();
    }
}