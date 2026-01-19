/**********************************************************************************
* @author      	Global Desktop 
* @date         22/07/2019
* @description  Clase de test de AP Configuration
* @Revision     
**********************************************************************************/
@isTest
public class DES_AP_ConfigurationHandlerTest {

    /*
	* @author 		Global Desktop                 
	* @Description  Inserts the global banker in the AP team     
	*/
    @IsTest
    static void fillDueDate() {
        DES_UtilTestClass utils = new DES_UtilTestClass();
        
        final Account acc = utils.createClient();
        acc.DES_PF_RENEWAL_DATE__c = Date.Today();
        final Account acc2 = utils.createClient();
        List<Account> accountList;
        accountList = new List<Account>();
        accountList.add(acc);
        accountList.add(acc2);
        insert accountList;
        
        acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
        apConfig.acpl__gf_ap_edit_prms_type_name__c = '';
        //apConfig.acpl__gf_ap_edit_days_left_number__c = 4;
        insert apConfig;
        
        acpl__AP_Period__c apPeriod = utils.createAPPeriod();

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(acc);
        accountPlanning.acpl__gf_ap_launch_name__c = 'Event driven';
        accountPlanning.acpl__gf_ap_limit_date__c = Date.Today()+1;
        accountPlanning.acpl__gf_event_date__c = Date.Today();
        final acpl__Account_Planning__c accountPlanning2 = utils.createAccountPlanning(acc);
        accountPlanning.acpl__gf_ap_launch_name__c = 'Event driven';
        accountPlanning.acpl__gf_ap_priority_type_name__c = '';
        List<acpl__Account_Planning__c> apList;
        apList = new List<acpl__Account_Planning__c>();
        apList.add(accountPlanning);
        apList.add(accountPlanning2);
        insert apList;
        
        Test.startTest();
        apConfig.acpl__gf_ap_edit_days_left_number__c = 7;
        update apConfig;
        
        insert apPeriod;
        apConfig.acpl__gf_ap_edit_days_left_number__c = -7;
        apConfig.acpl__gf_ap_edit_prms_type_name__c = 'General';
        update apConfig;
        
        apConfig.acpl__gf_ap_edit_prms_type_name__c = 'Wave';
        apConfig.acpl__gf_ap_edit_days_left_number__c = 7;
        update apConfig;
        delete apPeriod;
        apPeriod = utils.createAPPeriod();
        apPeriod.acpl__gf_ap_priority_edit_type__c = 'Wave 2';
        insert apPeriod;
        apConfig.acpl__gf_ap_edit_days_left_number__c = -7;
        update apConfig;
        Test.stopTest();
        System.assert(accountPlanning.acpl__gf_ap_limit_date__c != null, 'Account Plan Due date not filled.');
    }
}