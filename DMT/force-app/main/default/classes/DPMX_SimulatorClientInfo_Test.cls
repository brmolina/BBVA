@IsTest
public class DPMX_SimulatorClientInfo_Test {
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
        dynamicPricingTest.Frequency_of_Revision__c = 'Biannual';
        dynamicPricingTest.familia__c = 'Otro';
        dynamicPricingTest.familia_AcquiererCategories_Id__c = '13';
        dynamicPricingTest.isCustom__c = false;
        dynamicPricingTest.isCustomCliEdt__c = false;
        dynamicPricingTest.isCustomDisEdt__c = false;
        String newDycPrgJSON = JSON.serialize(dynamicPricingTest);
        insert dynamicPricingTest;      
    }
    
    @IsTest
    static void callgetDataSimulatorClientInfoNoEdit(){ 
         DPMX_Dynamic_Pricing__c dynamicPricingTest= [SELECT Id,
                                                        Company_Name__c,
                                                        Company_Name__r.DES_AGGR_Sector__c,
                                                        Client_Information__c,
                                                        Devices__c,
                                                        Simulation_Result__c,
                                                        Sim_Transaction_Debit_Own__c,
                                                        Sim_Billing_Debit_Own_Amount__c,
                                                        Sim_Billing_Debit_Own_Currency__c,
                                                        Sim_Tickets_Debit_Own_Amount__c,
                                                        Sim_Tickets_Debit_Own_Currency__c,
                                                        Sim_Percentage_Debit_MixOwn__c,
                                                        Sim_Transaction_Debit_ThirdParty__c,
                                                        Sim_Billing_Debit_ThirdParty_Amount__c,
                                                        Sim_Billing_Debit_ThirdParty_Currency__c,
                                                        Sim_Tickets_Debit_ThirdParty_Amount__c,
                                                        Sim_Tickets_Debit_ThirdParty_Currency__c,
                                                        Sim_Percentage_Debit_MixExternal__c,
                                                        Sim_Transaction_Credit_Own__c,
                                                        Sim_Billing_Credit_Own_Amount__c,
                                                        Sim_Billing_Credit_Own_Currency__c,
                                                        Sim_Tickets_Credit_Own_Amount__c,
                                                        Sim_Tickets_Credit_Own_Currency__c,
                                                        Sim_Percentage_Credit_MixOwn__c,
                                                        Sim_Transaction_Credit_ThirdParty__c,
                                                        Sim_Billing_Credit_ThirdParty_Amount__c,
                                                        Sim_Billing_Credit_ThirdParty_Currency__c,
                                                        Sim_Tickets_Credit_ThirdParty_Amount__c,
                                                        Sim_Tickets_Credit_ThirdParty_Currency__c,
                                                        Sim_Percentage_Credit_MixExternal__c,
                                                        Sim_Transaction_International__c,
                                                        Sim_Billing_International_Amount__c,
                                                        Sim_Billing_International_Currency__c,
                                                        Sim_Tickets_International_Amount__c,
                                                        Sim_Tickets_International_Currency__c,
                                                        Sim_Percentage_MixInternational__c,
                                                        Sim_Transaction_AcquirerAffiliation__c,
                                                        Sim_Billing_TotalAmount_Amount__c,
                                                        Sim_Billing_TotalAmount_Currency__c,
                                                        Sim_Tickets_TotalAmount_Amount__c,
                                                        Sim_Tickets_TotalAmount_Currency__c,
                                                        Sim_Percentage_Total__c,
                                                        Sim_Terminal_Id__c,
                                                        Sim_PinPadsInfo_PinPads__c,
                                                        Sim_Ecommerce__c,
                                                        Sim_DevicesInfo_Devices__c,
                                                        Sim_Fees_ExtraBilling_Amount__c,
                                                        Sim_Fees_ExtraBilling_Currency__c,
                                                        Sim_Fees_Cellnet_Amount__c,
                                                        Sim_Fees_Cellnet_Currency__c,
                                                        Sim_Fees_Billing_Amount__c,
                                                        Sim_Fees_Billing_Currency__c,
                                                        CustomAcquiredFeesCredit__c,
                                                        CustomAcquiredFeesDebit__c,
                                                        CustomAcquiredFeesInternational__c,
                                                        CustomSimulatedCredit__c,
                                                        CustomSimulatedDebit__c,
                                                        CustomSimulatedInternational__c,
                                                        flagBool__c,
                                                        familia__c,
                                                        familia_AcquiererCategories_Id__c,
                                                        isCustom__c,
                                                        isCustomCliEdt__c,
                                                        isCustomDisEdt__c
                                                    FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        System.debug(dynamicPricingTest.Id);
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricingTest.Id+'', '11', dynamicPricingTest.familia__c); 
        DPMX_AcquirerActivities_Wrapper AcqActWrp =(DPMX_AcquirerActivities_Wrapper) retMap.get('acquirerActivitiesWrapper');
        DPMX_SimulatorClientInfo_Ctrl.getData(AcqActWrp ,'actionNoEdit', dynamicPricingTest);
        DPMX_Dynamic_Pricing__c dynamicPricingTestUpd = [SELECT  id, Sim_Billing_Debit_Own_Amount__c FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        //DPMX_SimulatorClientInfo_Ctrl.saveData(dynamicPricingTest, 11);
        System.assertEquals(dynamicPricingTestUpd.Sim_Billing_Debit_Own_Amount__c, dynamicPricingTest.Sim_Billing_Debit_Own_Amount__c,'callgetDataSimulatorClientInfo');
        Test.stopTest();
    }
    
    @IsTest
    static void callgetDataSimulatorClientInfoEdit(){ 
         DPMX_Dynamic_Pricing__c dynamicPricingTest= [SELECT Id,
                                                        Company_Name__c,
                                                        Company_Name__r.DES_AGGR_Sector__c,
                                                        Client_Information__c,
                                                        Devices__c,
                                                        Simulation_Result__c,
                                                        Sim_Transaction_Debit_Own__c,
                                                        Sim_Billing_Debit_Own_Amount__c,
                                                        Sim_Billing_Debit_Own_Currency__c,
                                                        Sim_Tickets_Debit_Own_Amount__c,
                                                        Sim_Tickets_Debit_Own_Currency__c,
                                                        Sim_Percentage_Debit_MixOwn__c,
                                                        Sim_Transaction_Debit_ThirdParty__c,
                                                        Sim_Billing_Debit_ThirdParty_Amount__c,
                                                        Sim_Billing_Debit_ThirdParty_Currency__c,
                                                        Sim_Tickets_Debit_ThirdParty_Amount__c,
                                                        Sim_Tickets_Debit_ThirdParty_Currency__c,
                                                        Sim_Percentage_Debit_MixExternal__c,
                                                        Sim_Transaction_Credit_Own__c,
                                                        Sim_Billing_Credit_Own_Amount__c,
                                                        Sim_Billing_Credit_Own_Currency__c,
                                                        Sim_Tickets_Credit_Own_Amount__c,
                                                        Sim_Tickets_Credit_Own_Currency__c,
                                                        Sim_Percentage_Credit_MixOwn__c,
                                                        Sim_Transaction_Credit_ThirdParty__c,
                                                        Sim_Billing_Credit_ThirdParty_Amount__c,
                                                        Sim_Billing_Credit_ThirdParty_Currency__c,
                                                        Sim_Tickets_Credit_ThirdParty_Amount__c,
                                                        Sim_Tickets_Credit_ThirdParty_Currency__c,
                                                        Sim_Percentage_Credit_MixExternal__c,
                                                        Sim_Transaction_International__c,
                                                        Sim_Billing_International_Amount__c,
                                                        Sim_Billing_International_Currency__c,
                                                        Sim_Tickets_International_Amount__c,
                                                        Sim_Tickets_International_Currency__c,
                                                        Sim_Percentage_MixInternational__c,
                                                        Sim_Transaction_AcquirerAffiliation__c,
                                                        Sim_Billing_TotalAmount_Amount__c,
                                                        Sim_Billing_TotalAmount_Currency__c,
                                                        Sim_Tickets_TotalAmount_Amount__c,
                                                        Sim_Tickets_TotalAmount_Currency__c,
                                                        Sim_Percentage_Total__c,
                                                        Sim_Terminal_Id__c,
                                                        Sim_PinPadsInfo_PinPads__c,
                                                        Sim_Ecommerce__c,
                                                        Sim_DevicesInfo_Devices__c,
                                                        Sim_Fees_ExtraBilling_Amount__c,
                                                        Sim_Fees_ExtraBilling_Currency__c,
                                                        Sim_Fees_Cellnet_Amount__c,
                                                        Sim_Fees_Cellnet_Currency__c,
                                                        Sim_Fees_Billing_Amount__c,
                                                        Sim_Fees_Billing_Currency__c,
                                                        CustomAcquiredFeesCredit__c,
                                                        CustomAcquiredFeesDebit__c,
                                                        CustomAcquiredFeesInternational__c,
                                                        CustomSimulatedCredit__c,
                                                        CustomSimulatedDebit__c,
                                                        CustomSimulatedInternational__c,
                                                        flagBool__c,
                                                        familia__c,
                                                        familia_AcquiererCategories_Id__c,
                                                        isCustom__c,
                                                        isCustomCliEdt__c,
                                                        isCustomDisEdt__c
                                                    FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricingTest.Id+'', '11', 'Other'); 
        DPMX_AcquirerActivities_Wrapper AcqActWrp =(DPMX_AcquirerActivities_Wrapper) retMap.get('acquirerActivitiesWrapper');
        DPMX_SimulatorClientInfo_Ctrl.getData(AcqActWrp ,'edit', dynamicPricingTest);
        DPMX_Dynamic_Pricing__c dynamicPricingTestUpd = [SELECT  id, Sim_Billing_Debit_Own_Amount__c FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        System.assertEquals(dynamicPricingTestUpd.Sim_Billing_Debit_Own_Amount__c, dynamicPricingTest.Sim_Billing_Debit_Own_Amount__c,'callgetDataSimulatorClientInfo');        
		Test.stopTest();
    }
}