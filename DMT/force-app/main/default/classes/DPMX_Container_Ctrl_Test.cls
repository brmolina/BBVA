/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_Container_Ctrl_Test
* Test class for DPMX_Container_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-07-20
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class DPMX_Container_Ctrl_Test {
    @TestSetup
    static void createData() {
        Account acc = new Account();
        acc.Name = 'AccountTest';
        insert acc;

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
        dynamicPricingTest.isCustom__c = false;
        String newDycPrgJSON = JSON.serialize(dynamicPricingTest);
        dynamicPricingTest.Sim_Transaction_Debit_Own__c = 1;
        dynamicPricingTest.Sim_Billing_Credit_Own_Amount__c = 2;
		dynamicPricingTest.Sim_Billing_International_Amount__c = 3;
        dynamicPricingTest.Sim_Fees_Billing_Checkbox__c = true;
        dynamicPricingTest.Sim_Fees_Cellnet_Checkbox__c = true;
		dynamicPricingTest.Sim_Terminal_Id__c = 2;

        insert dynamicPricingTest;
        
        Account acc1 = new Account();
        acc1.Name = 'AccountTestisGs';
        insert acc1;
        
        DPMX_Dynamic_Pricing__c dynamicPricingTestisGs = new DPMX_Dynamic_Pricing__c();
        dynamicPricingTestisGs.Name = 'Dynamic Pricing Test1';
        dynamicPricingTestisGs.Product__c = 'Acquirer';
        dynamicPricingTestisGs.Client__c = acc1.id;
        dynamicPricingTestisGs.Company_Name__c = acc1.Id;
        dynamicPricingTestisGs.familia__c = 'Grandes_Superficies';
        dynamicPricingTestisGs.familia_AcquiererCategories_Id__c = '13';
        dynamicPricingTestisGs.isCustom__c = true;
        dynamicPricingTestisGs.isLastMonthTab__c = false;
        String newDycPrgJSON1 = JSON.serialize(dynamicPricingTestisGs);
        dynamicPricingTestisGs.Sim_Transaction_Debit_Own__c = 1;
        dynamicPricingTestisGs.Sim_Billing_Credit_Own_Amount__c = 2;
		dynamicPricingTestisGs.Sim_Billing_International_Amount__c = 3;
        dynamicPricingTestisGs.Sim_Fees_Billing_Checkbox__c = true;
        dynamicPricingTestisGs.Sim_Fees_Cellnet_Checkbox__c = true;
		dynamicPricingTestisGs.Sim_Terminal_Id__c = 2;
        insert dynamicPricingTestisGs;
        
        DPMX_Company_Comparison__c companyComparision = new DPMX_Company_Comparison__c();
        companyComparision.companyName__c = 'Test';
        companyComparision.groupName__c = 'TestGroup';
        companyComparision.Dynamic_Pricing__c = dynamicPricingTest.Id;
        companyComparision.isVisible__c = false;
        companyComparision.Credit__c = 11;
        companyComparision.Debit__c =22;
        companyComparision.International__c =33;
        insert companyComparision;
        
    }
    
    @IsTest
    static void createAccountTest(){   
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTest' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        
        Test.startTest();
      	Map<String, Object> retMap = DPMX_Container_Ctrl.getInitialData(dynamicPricing.id); 
        System.assertEquals(retMap.get('succes'), 'Cliente encontrado','createAccountTest');
        Test.stopTest();
    }

    @IsTest
    static void createAccountTestIsGs(){   
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        
        Test.startTest();
      	Map<String, Object> retMap = DPMX_Container_Ctrl.getInitialData(dynamicPricing.id); 
        System.assertEquals(retMap.get('succes'), 'Cliente establecido','AccountTestisGs');
        Test.stopTest();
    }
    
    @IsTest
    static void createAccountTestCustom(){         
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, isCustom__c FROM DPMX_Dynamic_Pricing__c WHERE isCustom__c= true];
        System.debug('***'+dynamicPricing.isCustom__c);
        Test.startTest();
      	Map<String, Object> retMap = DPMX_Container_Ctrl.getInitialData(dynamicPricing.id); 
        System.assertEquals(retMap.get('succes'), 'Cliente establecido','createAccountTestCustom');
        Test.stopTest();
    }
    
    @IsTest
    static void callAcquirerActivitiesService(){
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTest' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        System.assertEquals(retMap.get('success'), true,'callAcquirerActivitiesService');
        Test.stopTest();
    }
    
    @IsTest
    static void callAcquirerActivitiesServiceIsGs(){
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        System.assertEquals(retMap.get('success'), true,'callAcquirerActivitiesService');
        Test.stopTest();
    }

	@IsTest
    static void CallComparativeCategories(){   
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.CallComparativeCategories('1111111', '11', dynamicPricing.id, true); 
        System.assertEquals(retMap.get('success'), true,'CallComparativeCategories');
        Test.stopTest();
    }
    
    @IsTest
    static void CallComparativeCategoriesifCompanyExist(){   
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTest' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.CallComparativeCategories('1111111', '11', dynamicPricing.id, true);
        Map<String, Object> retMapSec = DPMX_Container_Ctrl.CallComparativeCategories('1111111', '11', dynamicPricing.id, true);
        System.assertEquals(retMap.get('success'), true,'CallComparativeCategories');
        Test.stopTest();
    }
    
    @IsTest
    static void callAcquirerFeesService(){   
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        Map<String, Object> retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper')); 
        Map<String, Object> retMap = DPMX_Container_Ctrl.callAcquirerFeesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), true); 
        System.assertEquals(retMap.get('success'), true,'callAcquirerFeesService');
        Test.stopTest();
    }
    
    @IsTest
    static void callCorporateRateService(){
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        Map<String, Object> retMap = DPMX_Container_Ctrl.callCorporateRateService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper')); 
        System.assertEquals(retMap.get('success'), true,'callCorporateRateService');
        Test.stopTest();
    }
    
    @IsTest
    static void updateFields(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.updateFields(dynamicPricing.Id,'Bueno', 11, true, 22, true, 33, true, false, 2, 5);
        DPMX_Dynamic_Pricing__c dynamicPricing1 = [SELECT id, CustomAcquiredFeesCredit__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Dynamic_Pricing__c dynamicPricingreturn = (DPMX_Dynamic_Pricing__c) retMap.get('dynamicPricing');
        System.assertEquals(dynamicPricing1.CustomAcquiredFeesCredit__c, dynamicPricingreturn.CustomAcquiredFeesCredit__c,'updateFields');
        Test.stopTest();
    }

    @IsTest
    static void updateFieldsSimulated(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.updateFields(dynamicPricing.Id,'Bueno', 11, true, 22, true, 33, true, false, 2, 5);       
        DPMX_Dynamic_Pricing__c dynamicPricing1 = [SELECT id, CustomAcquiredFeesCredit__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Dynamic_Pricing__c dynamicPricingreturn = (DPMX_Dynamic_Pricing__c) retMap.get('dynamicPricing');
        System.assertEquals(dynamicPricing1.CustomAcquiredFeesCredit__c, dynamicPricingreturn.CustomAcquiredFeesCredit__c,'updateFieldsSimulated');
        Test.stopTest();
    }
    
    @IsTest
    static void updateCustomSimulation(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        DPMX_Container_Ctrl.updateCustomSimulation(dynamicPricing.Id, 11, 22, 33); 
        DPMX_Dynamic_Pricing__c dynamicPricing1 = [SELECT id, CustomSimulatedCredit__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        System.assertEquals(dynamicPricing1.CustomSimulatedCredit__c, 11,'updateCustomSimulation');
        Test.stopTest();
    }

	@IsTest
    static void updateRates(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTest' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        Map<String, Object> retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper')); 
        Map<String, Object> retMap = DPMX_Container_Ctrl.updateRates(dynamicPricing.Id, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'),true,11.2,22.2,33.2, false, 500); 
        System.assertEquals(retMap.get('success'), true,'updateRates');
        Test.stopTest();
    }

    @IsTest
    static void updateRatesSimulation(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTest' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        Map<String, Object> retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        Map<String, Object> retMapSec = DPMX_Container_Ctrl.callAcquirerFeesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), true);
        Map<String, Object> retMap = DPMX_Container_Ctrl.updateRates(dynamicPricing.Id, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'),true,11.2,22.2,33.2, true, 500); 
        System.assertEquals(retMap.get('success'), true,'updateRatesSimulation');
        Test.stopTest();
    }
    
    @IsTest
    static void saveFamily(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.saveFamily(dynamicPricing.Id, 'otro', '13'); 
		System.assertEquals(retMap.get('success'), true,'saveFamily');
        Test.stopTest();
    }
    
    @IsTest
    static void updateInfoToSendReport(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, isLastMonthTab__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        DPMX_Container_Ctrl.updateInfoToSendReport(dynamicPricing.Id, true, false,'1000', 1, 2, 3, 4, 5, '1000', 1, 2, 3, 4, 5);
        DPMX_Dynamic_Pricing__c dynamicPricingVerify = [SELECT id, isLastMonthTab__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
		System.assertNotEquals(dynamicPricing.isLastMonthTab__c, dynamicPricingVerify.isLastMonthTab__c,'updateInfoToSendReport');
        Test.stopTest();
    }
    
    @IsTest
    static void callstatusFee(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.callstatusFee(dynamicPricing.Id, '13', '13', 'otro'); 
        System.debug('******'+retMap);
		System.assertEquals(retMap.get('error'), 'json no creado','callstatusFee');
        Test.stopTest();
    }
    
    @IsTest
    static void callValidate(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        Map<String, Object> retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        Map<String, Object> retMap = DPMX_Container_Ctrl.callValidate(dynamicPricing.Id, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), false, 'XO222');
        System.debug('******'+retMap);
		System.assertEquals(retMap.get('success'), true,'callValidate');
        Test.stopTest();
    }
    
    @IsTest
    static void callGetStatusService(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTestisGs' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.callGetStatusService(dynamicPricing.Id,'XE0000','29', 0); 
        System.debug('******'+retMap);
		System.assertEquals(retMap.get('success'), false,'callGetStatusService');
        Test.stopTest();
    }
}