/**********************************************************************************
* @author       Global Desktop 
* @date         22/05/2020
* @description  Clase de test de DES_BusinessPlanVersion_TriggerHandler
* @Revision     
**********************************************************************************/
@isTest
public class DES_BusinessPlanVersion_HandlerTest {
    
    /*
    * @author       Global Desktop
    * @Description  updateEventDateTest
    */
    @IsTest
    static void insertAuditTest() {
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        final DES_UtilTestClassAux utilsAux = new DES_UtilTestClassAux();
        
        //Creación cuenta
        final Account acc = utils.createClient();
        insert acc;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
        insert apConfig;
        
        final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
        apPeriod.acpl__gf_ap_edit_start_date__c = date.Today()+1;
        insert apPeriod;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        //Creación del account planning
        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(acc);
        insert accountPlanning; 
        
        final bupl__BusinessPlan__c businessPlan = utilsAux.createBusinessPlan(accountPlanning, acc);
        insert businessPlan;
        
        final bupl__BusinessPlan_Version__c bpVersion1 = utilsAux.createBusinessPlanVersion(businessPlan);
        insert bpVersion1;

        final bupl__BusinessPlan_Item__c bpItem = utilsAux.createBusinessPlanItemNormal(bpVersion1);
        insert bpItem;
        
        accountPlanning.acpl__gf_ap_status_type_name__c = 'Validated';
        accountPlanning.acpl__gf_ap_substatus_type_name__c = 'In Place';
        update accountPlanning;
        
        //creación de nueva versión de BP
        accountPlanning.acpl__gf_ap_indvi_lock_edit_ind_type__c = true;
        accountPlanning.acpl__gf_ap_substatus_type_name__c = 'Under Review';

        final bupl__BusinessPlan_Version__c bpVersion2 = utilsAux.createBusinessPlanVersion(businessPlan);

        Test.startTest();
        insert bpVersion2; 
        Test.stopTest();
        System.assert(bpVersion2.Id != null, 'BPversion not created.');
    }
}