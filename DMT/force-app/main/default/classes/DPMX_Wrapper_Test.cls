@IsTest
public class DPMX_Wrapper_Test {
    
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
        insert dynamicPricingTest;      
    }
    
	@IsTest
    static void callAcquirerActivities(){ 
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTest' LIMIT 1];      
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c, familia_AcquiererCategories_Id__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.callAcquirerActivitiesService(dynamicPricing.Id, '11', '1'); 
        DPMX_AcquirerActivities_Wrapper AcqActWrp =(DPMX_AcquirerActivities_Wrapper) retMap.get('acquirerActivitiesWrapper');
        String valiInfo;
        valiInfo = AcqActWrp.discount.debit.itemizeType+'';
        valiInfo = AcqActWrp.discount.monetaryCeiling+'';
        valiInfo = AcqActWrp.discount.percentage.credit+'';
        valiInfo = AcqActWrp.discount.percentage.international+'';
        valiInfo = AcqActWrp.discount.totalAmount+'';
        valiInfo = AcqActWrp.billing.debit.own+'';
        valiInfo = AcqActWrp.billing.debit.thirdParty.amount+'';
        valiInfo = AcqActWrp.billing.debit.thirdParty.currency_y+'';
        valiInfo = AcqActWrp.billing.credit+'';
        valiInfo = AcqActWrp.billing.international+'';
        valiInfo = AcqActWrp.billing.totalAmount+'';
        valiInfo = AcqActWrp.commission.billing+'';
        valiInfo = AcqActWrp.commission.cellnet+'';
        valiInfo = AcqActWrp.commission.extraBilling+'';
        valiInfo = AcqActWrp.commission.opportunity.cellnet+'';
        valiInfo = AcqActWrp.commission.opportunity.lowBilling+'';
        valiInfo = AcqActWrp.commission.opportunity.posExtra+'';
        valiInfo = AcqActWrp.devices.devicesNumber+'';
        valiInfo = AcqActWrp.devices.pinPads.pinPadsNumber+'';
        valiInfo = AcqActWrp.expenses.totalAmount+'';
        valiInfo = AcqActWrp.expenses.mit+'';
        valiInfo = AcqActWrp.id_y+'';
        valiInfo = AcqActWrp.informationDate+'';
        valiInfo = AcqActWrp.ratesResult+'';
        valiInfo = AcqActWrp.percentage.credit.mixExternal+'';
        valiInfo = AcqActWrp.percentage.credit.mixOwn+'';
        valiInfo = AcqActWrp.percentage.debit+'';
        valiInfo = AcqActWrp.percentage.mixInternational+'';
        valiInfo = AcqActWrp.percentage.total+'';
        valiInfo = AcqActWrp.taxAcquirer+'';
        valiInfo = AcqActWrp.yieldPercentage+'';
        valiInfo = AcqActWrp.terminal.id_y+'';
        valiInfo = AcqActWrp.tickets.credit+'';
        valiInfo = AcqActWrp.tickets.debit+'';
        valiInfo = AcqActWrp.tickets.international+'';
        valiInfo = AcqActWrp.tickets.totalAmount+'';
        System.assertEquals(retMap.get('success'), true,'callAcquirerActivities');
        Test.stopTest();
    }
    
    @IsTest
    static void CallComparativeCategories(){   
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTest' LIMIT 1];
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, Company_Name__c FROM DPMX_Dynamic_Pricing__c WHERE Client__c=:acc.id];
        Test.startTest();
        Map<String, Object> retMap = DPMX_Container_Ctrl.CallComparativeCategories('1111111', '11', dynamicPricing.id, true); 
        DPMX_ComparativeCategories_Wrapper comCatWrp =(DPMX_ComparativeCategories_Wrapper) retMap.get('acquirerCategoriesWrapper');
        String valiInfo;
        valiInfo = comCatWrp.description+'';
        valiInfo = comCatWrp.id+'';
        valiInfo = comCatWrp.businessInformations[0].companyName+'';
        valiInfo = comCatWrp.businessInformations[0].groupName+'';
        valiInfo = comCatWrp.businessInformations[0].rate.itemizeRates[0].rateType+'';
        valiInfo = comCatWrp.businessInformations[0].rate.itemizeRates[0].itemizeRateUnit.unitType+'';
        valiInfo = comCatWrp.businessInformations[0].rate.itemizeRates[0].itemizeRateUnit.value+'';
        valiInfo = comCatWrp.businessInformations[0].rate.itemizeRates[0].itemizeRateUnit.amount+'';
        valiInfo = comCatWrp.businessInformations[0].rate.itemizeRates[0].itemizeRateUnit.currency_y+'';
        System.assertEquals(retMap.get('success'), true,'CallComparativeCategories');
        Test.stopTest();
    }
    
    @IsTest
    static void createAccountTest(){   
        Account acc = [SELECT id FROM Account WHERE Name = 'AccountTest' LIMIT 1];
        
        Test.startTest();
        Map<String, Object> retMap = DPMX_NewDynamicPricing_Ctrl.getInitialData(acc.id); 
        System.debug(retMap.get('acquirerCategoriesWrapperLst'));
        List<DPMX_AcquirerCategories_Wrapper> comCatWrpLst =(List<DPMX_AcquirerCategories_Wrapper>) retMap.get('acquirerCategoriesWrapperLst');
        DPMX_AcquirerCategories_Wrapper comCatWrp = comCatWrpLst[0];
        String valiInfo;
        valiInfo = comCatWrp.id+'';
        valiInfo = comCatWrp.description+'';
        valiInfo = comCatWrp.businessInformation.companyName+'';
        valiInfo = comCatWrp.businessInformation.groupName+'';
        valiInfo = comCatWrp.businessInformation.rate.itemizeRates[0].rateType+'';
        valiInfo = comCatWrp.businessInformation.rate.itemizeRates[0].itemizeRateUnit.amount+'';
        valiInfo = comCatWrp.businessInformation.rate.itemizeRates[0].itemizeRateUnit.currency_y+'';
        valiInfo = comCatWrp.businessInformation.rate.itemizeRates[0].itemizeRateUnit.unitType+'';
        valiInfo = comCatWrp.businessInformation.rate.itemizeRates[0].itemizeRateUnit.value+'';
        System.assertEquals(retMap.get('product'), 'Acquirer' ,'acquirerCategoriesWrapper');
        Test.stopTest();
    }
}