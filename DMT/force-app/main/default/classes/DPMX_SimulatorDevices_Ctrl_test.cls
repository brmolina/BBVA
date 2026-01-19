@IsTest
public class DPMX_SimulatorDevices_Ctrl_test {

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
        dynamicPricingTest.familia__c = 'Otro';
        dynamicPricingTest.familia_AcquiererCategories_Id__c = '13';
        String newDycPrgJSON = JSON.serialize(dynamicPricingTest);
        insert dynamicPricingTest; 
    }
    @IsTest
    static void getDataTestAdd(){   
        createData();
        Account acc = [SELECT Id FROM Account WHERE Name = 'AccountTest' LIMIT 1];
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT Id
                                                    FROM DPMX_Dynamic_Pricing__c 
                                                   	WHERE Client__c=:acc.Id  LIMIT 1];
        DPMX_Dynamic_Pricing__c dynamicPricingTest = DPMX_Utils.dynamicPricingSelector(dynamicPricing.Id);
        Test.startTest();
        	Map<String, Object> retMap0 = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricingTest.Id, '11', '11');
           	Map<String, Object> retMap = DPMX_SimulatorDevices_Ctrl.getData((DPMX_AcquirerActivities_Wrapper) retMap0.get('acquirerActivitiesWrapper'),'add', dynamicPricingTest); 
       	System.debug(retMap.get('dynamicPricingUpsert'));	
        dynamicPricingTest = (DPMX_Dynamic_Pricing__c) retMap.get('dynamicPricingUpsert');
        System.assertEquals(dynamicPricingTest.Sim_Fees_Cellnet_Amount__c != 0, true,'getDataTest OK');
        Test.stopTest();
    }
    @IsTest
    static void getDataTestedit(){   
        createData();
        Account acc = [SELECT Id FROM Account WHERE Name = 'AccountTest' LIMIT 1];
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT Id
                                                    FROM DPMX_Dynamic_Pricing__c 
                                                   	WHERE Client__c=:acc.Id  LIMIT 1];
        DPMX_Dynamic_Pricing__c dynamicPricingTest = DPMX_Utils.dynamicPricingSelector(dynamicPricing.Id);
        Test.startTest();
        	Map<String, Object> retMap0 = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricingTest.Id, '11','11');
           	Map<String, Object> retMap = DPMX_SimulatorDevices_Ctrl.getData((DPMX_AcquirerActivities_Wrapper) retMap0.get('acquirerActivitiesWrapper'),'edit', dynamicPricingTest); 
       	System.debug(retMap.get('dynamicPricingUpsert'));	
        dynamicPricingTest = (DPMX_Dynamic_Pricing__c) retMap.get('dynamicPricingUpsert');
        System.assertEquals(dynamicPricingTest.Sim_Fees_Cellnet_Amount__c != 0, true,'getDataTestedit OK');
        Test.stopTest();
    }
    
    @IsTest
    static void getDatasaveData(){   
        createData();
        Account acc = [SELECT Id FROM Account WHERE Name = 'AccountTest' LIMIT 1];
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT Id
                                                    FROM DPMX_Dynamic_Pricing__c 
                                                   	WHERE Client__c=:acc.Id  LIMIT 1];
        DPMX_Dynamic_Pricing__c dynamicPricingTest = DPMX_Utils.dynamicPricingSelector(dynamicPricing.Id);
        Test.startTest();
        Map<String, Object> retMap0 = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricingTest.Id, '11','11');
        Map<String, Object> retMap1 = DPMX_SimulatorDevices_Ctrl.getData((DPMX_AcquirerActivities_Wrapper) retMap0.get('acquirerActivitiesWrapper'),'edit', dynamicPricingTest); 	
        dynamicPricingTest = (DPMX_Dynamic_Pricing__c) retMap1.get('dynamicPricingUpsert');
        Map<String, Object> retMap = DPMX_SimulatorDevices_Ctrl.saveData(dynamicPricingTest, (DPMX_AcquirerActivities_Wrapper) retMap0.get('acquirerActivitiesWrapper'), (DPMX_SimulatorDevices_Ctrl.Checboxes_Wrapper) retMap1.get('checkboxesWrapper'), 3, false); 
        dynamicPricingTest = (DPMX_Dynamic_Pricing__c) retMap.get('dynamicPricingUpsert');
        System.assertEquals(dynamicPricingTest.Devices__c, true,'getDatasaveData OK');
        Test.stopTest();
    }
}