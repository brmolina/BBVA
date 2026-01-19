/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_Actions_Ctrl_Test
* Test class for DPMX_Summary_Ctrl apex class
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
public class DPMX_SimulationResult_Ctrl_Test {
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
        
        DPMX_Dynamic_Pricing__c dynamicPricingTest = new DPMX_Dynamic_Pricing__c();
        dynamicPricingTest.Name = 'Dynamic Pricing Test';
        dynamicPricingTest.Product__c = 'Acquirer';
        dynamicPricingTest.Client__c = acc.id;
        dynamicPricingTest.Company_Name__c = acc.DES_Main_Parent__c;
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
        DPMX_Dynamic_Pricing__c dynamicPricingTest = [SELECT Id,
                                                        Client_Information__c,
                                                        Devices__c,
                                                        Simulation_Result__c
                                                    FROM DPMX_Dynamic_Pricing__c 
                                                   	WHERE Client__c=:acc.Id  LIMIT 1];
        Test.startTest();
           	Map<String, Object> retMap = DPMX_SimulationResult_Ctrl.getData(dynamicPricingTest.Id); 
       		System.assertEquals(retMap.get('success'), true,'getDataTest OK');
        	System.assertEquals(retMap.get('dynamicPricing'), dynamicPricingTest, 'retMapDynamicPricing OK');
        Test.stopTest();
    }
}