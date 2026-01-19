/**********************************************************************************
* @author      	Global Desktop 
* @date         22/07/2019
* @description  Clase de test de Case de Desktop
* @Revision     
**********************************************************************************/
@isTest
public class DES_CaseHandlerTest {
    
    /*
    * @author 		Global Desktop
    * @Description  general edition period
    */
    @IsTest
    static void insertAPShare() {
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        
        //Creación de perfil y usuario
        //final String profile = utils.createProfile();
        final String profile = String.valueOf([Select Id From Profile Where Name='BBVA Desktop GCC Standard'].Id);
        final User validator1 = utils.createUser(profile, '@validator1.comm');
        final User validator2 = utils.createUser(profile, '@validator2.comm');
        List<User> validatorList;
        validatorList = new List<User>();
        validatorList.add(validator1);
        validatorList.add(validator2);
        insert validatorList;
        
        //Creación cuenta
        final Account acc = utils.createClient();
        insert acc;
        
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
        
        //Creación del account planning
        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(acc);
        accountPlanning.acpl__gf_ap_validator_user_id__c = validator1.Id;
        final List<acpl__Account_Planning__c> apNewList = new List<acpl__Account_Planning__c>();
        apNewList.add(accountPlanning);
        insert accountPlanning;
        
        //Creación del caso
        final Id apCaseRT = [SELECT Id FROM RecordType WHERE DeveloperName='Account_Plan_Validation'].Id;
        Case apCase;
        apCase = new Case();
        apCase.Status = 'Pending approval';
        apCase.OwnerId = validator1.Id;
        apCase.RecordTypeId = apCaseRT;
        apCase.acpl__Account_plan_id__c = accountPlanning.Id;
        insert apCase;
        
        final Id oldValidator = apCase.OwnerId;
        Id newValidator;
        
        System.runAs(validator1) {
            Test.startTest();
            apCase.OwnerId = validator2.Id;
            update apCase;
            newValidator = apCase.OwnerId;
            Test.stopTest();
        }
        System.assert(oldValidator != newValidator, 'Case owner not changed');
    }
}