/**
* @author        Global Desktop
* @date         09/03/2020
* @description  Test del componente de privacidad del Business Plan
* @Revision
*
* Version   Date            Author          Summary of changes
*/
@IsTest
public class DES_DisclaimersBusinessPlanTest {

    /*
    * @author     Global Desktop
    * @Description  Retrieves Privacy settings from Business Plan Test
    */
    @IsTest
    public static void getDisclaimerTest() {
        final DES_UtilTestClass utilTest = new DES_UtilTestClass();
        final DES_UtilTestClassAux utilTestAux = new DES_UtilTestClassAux();
        final DES_DisclaimersBusinessPlan disclaimerTest = DES_DisclaimersBusinessPlan.getInstance();
        System.debug('disclaimerTest' + disclaimerTest);
        final Account clientDeTest = utilTest.createClient();
        insert clientDeTest;
        
        DES_UtilTestClass utils = new DES_UtilTestClass();
        final acpl__AP_PeriodConfiguration__c apPeriodConfig = new acpl__AP_PeriodConfiguration__c();
        insert apPeriodConfig;
        
        final Date actualDate = Date.today();
        final acpl__AP_Period__c period = new acpl__AP_Period__c();
        period.acpl__gf_ap_edit_start_date__c = actualDate;
        period.acpl__gf_ap_edit_end_date__c = actualDate.addDays(1);
        insert period;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning__c apDeTest = utilTest.createAccountPlanning(clientDeTest);
        insert apDeTest;
        final bupl__BusinessPlan__c bpDeTest = utilTestAux.createBusinessPlan(apDeTest, clientDeTest);
        insert bpDeTest;
        Test.startTest();
        final Boolean privacyTest = DES_DisclaimersBusinessPlan.getBPPrivacy(apDeTest.Id);
        System.assert(privacyTest, 'Private Business Plan');
        Test.stopTest();
    }
}