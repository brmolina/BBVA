/**********************************************************************************
* @author       Global Desktop 
* @date         15/10/2019
* @description  DES_AP_LocalAnalysis_cnt Test
* @Revision     
**********************************************************************************/
@isTest
public class DES_AP_LocalAnalysis_cntTest {

    /**
	* @author Global Desktop
	* @description Test
	*/
    @isTest
    public static void getCountriesTest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        
        final Account acc = utilTestClass.createClient();
        insert acc;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning__c accountPlan = utilTestClass.createAccountPlanning(acc);
        insert accountPlan;
        
        insert new DES_Local_Analysis__c(gf_account_planning_id__c = accountPlan.Id);
        
        
        Test.StartTest();
        DES_AP_LocalAnalysis_cnt.isTeamMember(accountPlan.Id);
        final List<DES_Local_Analysis__c> laList = DES_AP_LocalAnalysis_cnt.getCountries(accountPlan.Id);
        System.assert(!laList.isEmpty(), 'Local Analysis no existe');
        Test.StopTest();
    }
    
        /**
	* @author Global Desktop
	* @description Test
	*/
    @isTest
    public static void getAmountsTest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        
        final Account acc = utilTestClass.createClient();
        insert acc;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning__c accountPlan = utilTestClass.createAccountPlanning(acc);
        insert accountPlan;
        
        final DES_Local_Analysis__c LocalAnalysis = new DES_Local_Analysis__c(gf_account_planning_id__c = accountPlan.Id);
        insert LocalAnalysis;
        
        
        Test.StartTest();
        DES_AP_LocalAnalysis_cnt.isTeamMember(accountPlan.Id);
        final List<DES_Local_Analysis__c> laList = DES_AP_LocalAnalysis_cnt.getAmountValues(LocalAnalysis.Id);
        System.assert(!laList.isEmpty(), 'Local Analysis no existe');
        Test.StopTest();
    }
}