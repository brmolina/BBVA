@isTest
public class DPMX_VerificarTasa_ctrl_Test {
    
    @TestSetup
    static void createData() {
        String NameAccount = 'TestAccount';
        String NameAccountSim = 'TestAccountSim';
		String NameDPMX = 'TestDPMX';
        String NameDPMXSim = 'TestDPMXSim';
        
        Map<String, Object> retMap = new Map<String, Object>();
        Map<String, Object> retMapZero = new Map<String, Object>();
        Map<String, Object> retMapFirst = new Map<String, Object>();
        
        User testUser1 = DPMX_Test_Utils.createUser('XE0000');
        insert testUser1;
        
        Account newAccount = DPMX_Test_Utils.createAccount(NameAccount);
        insert newAccount;
        
        Local_Client__c locCli = new Local_Client__c();
        locCli.unique_id__c ='1111111';
        locCli.Name ='GRUPO AccountTest';
        locCli.Cib_Client__c = newAccount.Id;
        insert locCli;
        
        Account newAccountSim = DPMX_Test_Utils.createAccount(NameAccountSim);
        insert newAccountSim;
        
        Local_Client__c locCliSim = new Local_Client__c();
        locCliSim.unique_id__c ='1111112';
        locCliSim.Name ='GRUPO AccountTestSim';
        locCliSim.Cib_Client__c = newAccountSim.Id;
        insert locCliSim;
        
        DPMX_Dynamic_Pricing__c newDPMX = DPMX_Test_Utils.createDynamicPricing(NameDPMX, newAccount.Id);
        newDPMX.Company_Name__c = newAccount.Id;
        newDPMX.isLastMonthTab__c = true;
		newDPMX.isSimulationTab__c = false;
        newDPMX.debitLastMonth__c = 1.75;
        newDPMX.CreditLastMonth__c = 1.75;
        newDPMX.IntLastMonth__c = 1.75;
        newDPMX.familia_AcquiererCategories_Id__c = '13';
        insert newDPMX;
        retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c); 
        retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        retMap = DPMX_Container_Ctrl.callAcquirerFeesService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), true); 
        
        DPMX_Dynamic_Pricing__c newDPMXSim = DPMX_Test_Utils.createDynamicPricing(NameDPMXSim, newAccountSim.Id);
        newDPMXSim.isLastMonthTab__c = false;
		newDPMXSim.isSimulationTab__c = true;
        newDPMXSim.formalizeTab__c = true;
        newDPMXSim.Sim_Percentage_Debit_MixOwn__c = 0;
        newDPMXSim.Sim_Percentage_Debit_MixExternal__c = 0;
        newDPMXSim.Sim_Percentage_Credit_MixOwn__c = 0;
        newDPMXSim.Sim_Percentage_Credit_MixExternal__c = 0;
        newDPMXSim.Sim_Percentage_MixInternational__c = 0;
        newDPMXSim.Sim_Percentage_Total__c = 0;
        newDPMXSim.familia_AcquiererCategories_Id__c = '13';
        insert newDPMXSim;
        retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(newDPMXSim.Id, '11', newDPMXSim.familia_AcquiererCategories_Id__c); 
        retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(newDPMXSim.Id, '11', newDPMXSim.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        retMap = DPMX_Container_Ctrl.callAcquirerFeesService(newDPMXSim.Id, '11', newDPMXSim.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), true); 
    
        DPMX_Formalize__c newFormalize = DPMX_Test_Utils.createFormalize(newDPMX,'XE0000');
        insert newFormalize;
        
        DPMX_Formalize__c newFormalizeSim = DPMX_Test_Utils.createFormalize(newDPMXSim,'XE0000');
        insert newFormalizeSim;
    }
    
    @IsTest
    static void getInitialDataNoSim(){
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccount' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Formalize__c formalize = [SELECT id FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        Map<String, Object> retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        Test.startTest();
        Map<String, Object> retMap = DPMX_VerificarTasa_ctrl.getInitialData(dynamicPricing.id, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'));
        System.assertEquals(retMap.get('formalizeExist'), true,'CallInitialDataNoSim');
        Test.stopTest();
    }
    
    @IsTest
    static void getInitialDataSim(){
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccountSim' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, isSimulationTab__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Formalize__c formalize = [SELECT id FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        Map<String, Object> retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        Map<String, Object> retMap = DPMX_Container_Ctrl.callValidate(dynamicPricing.Id, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), false, 'XO222');
        Test.startTest();
        retMap = DPMX_VerificarTasa_ctrl.getInitialData(dynamicPricing.id, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'));
        System.assertEquals(retMap.get('formalizeExist'), true,'CallInitialDataSim');
        Test.stopTest();
    }
    
    @IsTest
    static void getsendReport(){
        User us = [SELECT id FROM User WHERE username = 'testProfi@example.com' LIMIT 1];
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccount' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Formalize__c formalize = [SELECT id FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        List<String> strLst = new List<String>();
        strLst.add('');
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        Map<String, Object> retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        Test.startTest();
        Map<String, Object> retMap = DPMX_VerificarTasa_ctrl.sendReport(dynamicPricing.id,'DPMX_SendReportForFormalize','Saludo','Intro','Close',strLst,'Asunto', true, us.Id,'00-00-0000', '00-00-0001',(DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'));
        System.assertEquals(retMap.get('status'), 'Verificacion de envio de email para classes test.','CallsendReport');
        Test.stopTest();
    }
    
    @IsTest
    static void getsendReportSim(){
        User us = [SELECT id FROM User WHERE username = 'testProfi@example.com' LIMIT 1];
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccountSim' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Formalize__c formalize = [SELECT id FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        List<String> strLst = new List<String>();
        strLst.add('');
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        Map<String, Object> retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        Map<String, Object> retMap = DPMX_Container_Ctrl.callValidate(dynamicPricing.Id, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), false, 'XO222');
        Test.startTest();
        retMap = DPMX_VerificarTasa_ctrl.sendReport(dynamicPricing.id,'DPMX_SendReportForFormalize','Saludo','Intro','Close',strLst,'Asunto', true, us.Id,'00-00-0000', '00-00-0001',(DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'));
        System.assertEquals(retMap.get('status'), 'Verificacion de envio de email para classes test.','CallsendReportSim');
        Test.stopTest();
    }

}