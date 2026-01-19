/**********************************************************************************
* @author       Global Desktop 
* @date         12/05/2020
* @description  DES_GA_RelatedNnGDController Test
* @Revision     
**********************************************************************************/
@isTest
public class DES_GA_RelatedNnGDControllerTest{
    /**
	* @author Global Desktop
	* @description Test
	*/
    @isTest
    public static void accOppTest(){
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        DES_UtilTestClassAux utilTestClassAux = new DES_UtilTestClassAux();
        
        list<Account> accList = new list<Account>();
        Account acc1 = utilTestClass.createClient();
        accList.add(acc1);
        Account acc2 = utilTestClass.createClient();
        accList.add(acc2);
        insert accList;
        System.assertNotEquals(acc1 ,acc2);
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning__c accountPlan = utilTestClass.createAccountPlanning(acc1);
        insert accountPlan;
        
        final bupl__BusinessPlan__c businessPlan = utilTestClassAux.createBusinessPlan(accountPlan,acc1);
        insert businessPlan;
        
        final bupl__BP_Need__c needRecord = utilTestClassAux.createNeed(accountPlan,businessPlan);
        needRecord.bupl__gf_bus_pl_cust_lock_desc__c = 'lorem';
        needRecord.bupl__gf_business_lock_record_number__c = 1; 
        needRecord.bupl__gf_bus_pl_cust_lock_name__c = 'Others';
        needRecord.bupl__gf_bus_pl_sales_goal_name__c = 'Others';
        needRecord.bupl__country_id__c = 'Argentina';
        insert needRecord;
        
        final bupl__BP_GrowthDriver__c driverRecord = utilTestClassAux.createGrowthDriver(accountPlan,businessPlan);
        driverRecord.bupl__gf_growth_drvr_prdt_short_desc__c = 'lorem';
        driverRecord.bupl__solution_category_id__c = 'GM';
        driverRecord.bupl__solution_category_desc__c = 'Credit';
        driverRecord.bupl__country_id__c = 'Argentina';
        driverRecord.bupl__gf_growth_drvr_prdt_desc__c = 'Ipsum';
        insert driverRecord;

        final DES_Group_Analysis__c gAnalysis = utilTestClassAux.createGroupAnalysis(accountPlan,acc1);
        insert gAnalysis;

        Test.StartTest();
        DES_GA_RelatedNnGDController.gtGAAPId(gAnalysis.Id);
        DES_GA_RelatedNnGDController.getRelatedNeeds('2', accountPlan.Id);
        DES_GA_RelatedNnGDController.getRelatedDrivers('2', accountPlan.Id);
        System.assertEquals(true, accountPlan.acpl__participant_id__c == acc1.Id);
        Test.StopTest();
    }
}