@isTest
public class DPMX_SendReport_ctrl_test {
    
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
        
        Account newAccountSim = DPMX_Test_Utils.createAccount(NameAccountSim);
        insert newAccountSim;
        
        Local_Client__c locCli = DPMX_Test_Utils.createLocalClient(newAccount, '123456');
        insert locCli;
        
        Local_Client__c locCliSim = DPMX_Test_Utils.createLocalClient(newAccountSim, '123457');
        insert locCliSim;
        
        DPMX_Dynamic_Pricing__c newDPMX = DPMX_Test_Utils.createDynamicPricing(NameDPMX, newAccount.Id);
        newDPMX.Company_Name__c = newAccount.Id;
        insert newDPMX;
        retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c); 
        retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        retMap = DPMX_Container_Ctrl.callAcquirerFeesService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), true); 
        
        DPMX_Dynamic_Pricing__c newDPMXSim = DPMX_Test_Utils.createDynamicPricing(NameDPMXSim, newAccountSim.Id);
        newDPMXSim.Company_Name__c = newAccountSim.Id;
        newDPMXSim.isLastMonthTab__c = false;
		newDPMXSim.isSimulationTab__c = true;
        newDPMXSim.Sim_Percentage_Debit_MixOwn__c = 0;
        newDPMXSim.Sim_Percentage_Debit_MixExternal__c = 0;
        newDPMXSim.Sim_Percentage_Credit_MixOwn__c = 0;
        newDPMXSim.Sim_Percentage_Credit_MixExternal__c = 0;
        newDPMXSim.Sim_Percentage_MixInternational__c = 0;
        newDPMXSim.Sim_Percentage_Total__c = 0;
        insert newDPMXSim;
        retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(newDPMXSim.Id, '11', newDPMXSim.familia_AcquiererCategories_Id__c); 
        retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(newDPMXSim.Id, '11', newDPMXSim.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        retMap = DPMX_Container_Ctrl.callAcquirerFeesService(newDPMXSim.Id, '11', newDPMXSim.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), true); 
    
    }
    
    @IsTest
    static void getInitialDataNoSim(){
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccount' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, familia__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_SendReport_ctrl.getInitialData(dynamicPricing.id);
        System.assertEquals(retMap.get('DPMX_familia__c'), dynamicPricing.familia__c,'CallInitialDataNoSim');
        Test.stopTest();
    }
    
    @IsTest
    static void getInitialDataSim(){
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccountSim' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, familia__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_SendReport_ctrl.getInitialData(dynamicPricing.id);
        System.assertEquals(retMap.get('DPMX_familia__c'), dynamicPricing.familia__c,'CallInitialDataSim');
        Test.stopTest();
    }
    
    @IsTest
    static void getsendReport(){
        User us = [SELECT id FROM User WHERE username = 'testProfi@example.com' LIMIT 1];
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccount' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        List<String> strLst = new List<String>();
        strLst.add('');
        Test.startTest();
        Map<String, Object> retMap = DPMX_SendReport_ctrl.sendReport(dynamicPricing.id,'DPMX_SendReportForFormalize','Saludo','Intro','Close',strLst,'Asunto');
        System.assertEquals(retMap.get('status'), 'Verificacion de envio de email para classes test.','CallsendReport');
        Test.stopTest();
    }
    
    @IsTest
    static void getsendReportSim(){
        User us = [SELECT id FROM User WHERE username = 'testProfi@example.com' LIMIT 1];
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccountSim' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        List<String> strLst = new List<String>();
        strLst.add('');
        Test.startTest();
        Map<String, Object> retMap = DPMX_SendReport_ctrl.sendReport(dynamicPricing.id,'DPMX_SendReportForFormalize','Saludo','Intro','Close',strLst,'Asunto');
        System.assertEquals(retMap.get('status'), 'Verificacion de envio de email para classes test.','CallsendReportSim');
        Test.stopTest();
    }

}