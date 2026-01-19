@isTest
public class DPMX_FormalizeDetails_ctrl_Test {
    @TestSetup
    static void createData() {
		String NameDPMX = 'TestDPMX';
        String NameDPMXSim = 'TestDPMXSim';
        String NameAccount = 'TestAccount';
        String NameAccountSim = 'TestAccountSim';
        
        Account newAccount = DPMX_Test_Utils.createAccount(NameAccount);
        insert newAccount;
        
        Account newAccountSim = DPMX_Test_Utils.createAccount(NameAccountSim);
        insert newAccountSim;
        
        DPMX_Dynamic_Pricing__c newDPMX = DPMX_Test_Utils.createDynamicPricing(NameDPMX, newAccount.Id);
        newDPMX.corporateRates_JSON__c = '{"data":[{"id_y":"DISCOUNT","lastUpdateDate":"2024-06-01","itemizeType":{"unitType":"AMOUNT","amount":3.0,"currency":"MXN"},"credit":{"value":2.05},"international":{"value":4.0}},{"id_y":"INTERCHANGE","lastUpdateDate":"2024-06-01","itemizeType":{"unitType":"AMOUNT","amount":1.24,"currency":"MXN"},"credit":{"value":1.53},"international":{"value":2.0}},{"id_y":"AVERAGE_DISCOUNT","lastUpdateDate":"2024-06-01","itemizeType":{"unitType":"AMOUNT","amount":2.0,"currency":"MXN"},"credit":{"value":2.0},"international":{"value":3.0}}]}';
        newDPMX.formalizeTab__c = false;
        insert newDPMX;
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c);
        Map<String, Object> retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        DPMX_Container_Ctrl.callAcquirerFeesService(newDPMX.Id, '11', newDPMX.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), true); 
        
        DPMX_Dynamic_Pricing__c newDPMXSim = DPMX_Test_Utils.createDynamicPricing(NameDPMXSim, newAccountSim.Id);
        newDPMXSim.corporateRates_JSON__c = '{"data":[{"id_y":"DISCOUNT","lastUpdateDate":"2024-06-01","itemizeType":{"unitType":"AMOUNT","amount":3.0,"currency":"MXN"},"credit":{"value":2.05},"international":{"value":4.0}},{"id_y":"INTERCHANGE","lastUpdateDate":"2024-06-01","itemizeType":{"unitType":"AMOUNT","amount":1.24,"currency":"MXN"},"credit":{"value":1.53},"international":{"value":2.0}},{"id_y":"AVERAGE_DISCOUNT","lastUpdateDate":"2024-06-01","itemizeType":{"unitType":"AMOUNT","amount":2.0,"currency":"MXN"},"credit":{"value":2.0},"international":{"value":3.0}}]}';
        newDPMXSim.formalizeTab__c = true;
        newDPMXSim.familia_AcquiererCategories_Id__c = '13';
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
        insert newDPMXSim;
        
        retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(newDPMXSim.Id, '11', newDPMXSim.familia_AcquiererCategories_Id__c);
        retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(newDPMXSim.Id, '11', newDPMXSim.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        DPMX_Container_Ctrl.callAcquirerFeesService(newDPMXSim.Id, '11', newDPMXSim.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), true); 
        
        DPMX_Formalize__c newFormalize = DPMX_Test_Utils.createFormalize(newDPMX,'XE0000');
        insert newFormalize;
        
        DPMX_Formalize__c newFormalizeSim = DPMX_Test_Utils.createFormalize(newDPMXSim,'XE0000');
        insert newFormalizeSim;
    }
    
    @IsTest
    static void getInitialData(){
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccount' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Formalize__c formalize = [SELECT id FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_FormalizeDetails_ctrl.getInitialData(formalize.id); 
        System.assertEquals(retMap.get('dynamicPricingId'), dynamicPricing.id,'CallInitialData');
        Test.stopTest();
    }
    
    @IsTest
    static void getInitialDataSim(){
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccountSim' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Formalize__c formalize = [SELECT id FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        Map<String, Object> retMapZero = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c); 
        Map<String, Object> retMapFirst = DPMX_Container_Ctrl.callCorporateRateService(dynamicPricing.Id, '11', dynamicPricing.familia_AcquiererCategories_Id__c, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'));
        Map<String, Object> retMap3 = DPMX_Container_Ctrl.callValidate(dynamicPricing.Id, (DPMX_AcquirerActivities_Wrapper) retMapZero.get('acquirerActivitiesWrapper'), (DPMX_Container_Ctrl.Discount_Rates_Wrapper) retMapFirst.get('interchangeRates'), false, 'XO222');
        Test.startTest();
        Map<String, Object> retMap = DPMX_FormalizeDetails_ctrl.getInitialData(formalize.id); 
        System.assertEquals(retMap.get('dynamicPricingId'), dynamicPricing.id,'CallInitialData');
        Test.stopTest();
    }
    
    @IsTest
    static void updateFormalize(){
        Account acc = [SELECT id FROM Account WHERE Name = 'TestAccount' LIMIT 1]; 
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        DPMX_Formalize__c formalize = [SELECT id, FirmOdtClient__c FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_FormalizeDetails_ctrl.updateFormalize(formalize.id, true, true, true, true);
        DPMX_Formalize__c formalizeUpd = [SELECT id, FirmOdtClient__c FROM DPMX_Formalize__c WHERE Dynamic_Pricing__c=:dynamicPricing.id];
        System.assertNotEquals(formalize.FirmOdtClient__c, formalizeUpd.FirmOdtClient__c,'CallupdateFormalize');
        Test.stopTest();
    }
}