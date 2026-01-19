@isTest
public class DPMX_FormalizeAtam_ctrl_Test {

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
        
        DPMX_Dynamic_Pricing__c newDPMX = DPMX_Test_Utils.createDynamicPricing(NameDPMX, newAccount.Id);
        newDPMX.Company_Name__c = newAccount.Id;
        newDPMX.initDateFormalize__c = '22/02/2222';
        insert newDPMX;
        retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c); 
        retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        retMap = DPMX_Container_Ctrl.callAcquirerFeesService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), true); 
        
        DPMX_Dynamic_Pricing__c newDPMXSim = DPMX_Test_Utils.createDynamicPricing(NameDPMXSim, newAccountSim.Id);
        newDPMXSim.isLastMonthTab__c = false;
		newDPMXSim.isSimulationTab__c = true;
        newDPMXSim.formalizeTab__c = true;
        newDPMXSim.debitLastMonth__c = 1;
        newDPMXSim.CreditLastMonth__c = 2;
        newDPMXSim.IntLastMonth__c = 3;
        newDPMXSim.RentabildiadLastMonth__c = 4;
        newDPMXSim.baiLastMonth__c = 5;
        newDPMXSim.debitSim__c = 1;
        newDPMXSim.creditSim__c = 2;
        newDPMXSim.interSim__c = 3;
        newDPMXSim.RentabildiadSim__c = 4;
        newDPMXSim.baiSim__c = 5;
        newDPMXSim.Sim_Tickets_Debit_Own_Amount__c = 10;
        newDPMXSim.Sim_Tickets_Credit_Own_Amount__c = 11;
        newDPMXSim.Sim_Tickets_International_Amount__c = 12;
        newDPMXSim.Sim_Billing_TotalAmount_Amount__c = 13;
        newDPMXSim.Sim_Tickets_TotalAmount_Amount__c = 14;
        newDPMXSim.Sim_Percentage_Total__c = 15;
        newDPMXSim.initDateFormalize__c = '22/02/2222';
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
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Formalize__c formalize = [SELECT id FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_FormalizeAtam_ctrl.getInitialData(dynamicPricing.id);
        System.assertEquals(retMap.get('formalizeExist'), true,'CallInitialDataNoSim');
        Test.stopTest();
    }
    
    @IsTest
    static void getInitialDataSim(){
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccountSim' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, isSimulationTab__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Formalize__c formalize = [SELECT id FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        System.debug(dynamicPricing.isSimulationTab__c);
        Test.startTest();
        Map<String, Object> retMap = DPMX_FormalizeAtam_ctrl.getInitialData(dynamicPricing.id);
        System.assertEquals(retMap.get('formalizeExist'), true,'CallInitialDataSim');
        Test.stopTest();
    }
    
    @IsTest
    static void getsendReport(){
        User us = [SELECT id FROM User WHERE username = 'testProfi@example.com' LIMIT 1];
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccount' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Formalize__c formalize = [SELECT id FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        List<String> strLst = new List<String>();
        strLst.add('');
        Test.startTest();
        Map<String, Object> retMap = DPMX_FormalizeAtam_ctrl.sendReport(dynamicPricing.id,'DPMX_SendReportForFormalize','Saludo','Intro','Close',strLst,'Asunto', true,'Comentario');
        System.assertEquals(retMap.get('status'), 'Verificacion de envio de email para classes test.','CallsendReport');
        Test.stopTest();
    }

}