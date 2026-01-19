/**********************************************************************************
* @author       Global Desktop 
* @date         15/10/2019
* @description  DES_AP_LocalAnalysis_cnt Test
* @Revision     
**********************************************************************************/
@isTest
public class DES_BP_ItemHandlerTest {

    /**
	* @author Global Desktop
	* @description Test
	*/
    @isTest
    public static void insertLATest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final DES_UtilTestClassAux utilTestClassAux = new DES_UtilTestClassAux();
        
        final Account account = utilTestClass.createClient();
        insert account;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning__c accountPlanning = utilTestClass.createAccountPlanning(account);
        insert accountPlanning;
        
        final bupl__BusinessPlan__c businessPlan = utilTestClassAux.createBusinessPlan(accountPlanning, account);
        insert businessPlan;
        final bupl__BusinessPlan_Version__c bpVersion = utilTestClassAux.createBusinessPlanVersion(businessPlan);
        insert bpVersion;
        final bupl__BusinessPlan_Item__c bpItem = utilTestClassAux.createBusinessPlanItemNormal(bpVersion);
        final bupl__BusinessPlan_Item__c bpItem2 = utilTestClassAux.createBusinessPlanItemNormal(bpVersion);
        bpItem2.bupl__gf_booking_operation_cntry_id__c = 'Spain';
        final bupl__BusinessPlan_Item__c bpItem3 = utilTestClassAux.createBusinessPlanItemNormal(bpVersion);
        bpItem3.bupl__gf_booking_operation_cntry_id__c = 'Argentina';

        Test.StartTest();
        insert bpItem;
        insert bpItem2;
        insert bpItem3;
        final List<DES_Local_Analysis__c> laList = [SELECT Id FROM DES_Local_Analysis__c WHERE gf_account_planning_id__c = :accountPlanning.Id];
        System.assert(!laList.isEmpty(), 'Local Analysis no existe');
        Test.StopTest();
    }
}