/**********************************************************************************
* @author      	Global Desktop 
* @date         22/07/2019
* @description  Clase de test de Account Planning
* @Revision     
**********************************************************************************/
@isTest
public class DES_APBPcmpTriggersTest {
    
    /*instance*/
    //public final AP_PeriodConfigurationHandler apPeriodConfigHandler = AP_PeriodConfigurationHandler.getInstance();

    /*
	* @author 		Global Desktop                 
	* @Description  Inserts the global banker in the AP team     
	*/
    @IsTest
    static void triggersTest() {
        DES_UtilTestClass utils = new DES_UtilTestClass();
        DES_UtilTestClassAux utilsAux = new DES_UtilTestClassAux();
        
        Account account;
        account = utils.createClient();
        insert account;
        
        String profile = utils.createProfile();
        User user = utils.createUser(profile, 'username@test.comm');
        insert user;
        
        DES_BBVA_Management_team__c bbvaTM = utils.createBBVAManagementTeamMember(user, account);
        bbvaTM.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
        bbvaTM.DES_Local_Banker_Country__c = 'Global';
        insert bbvaTM;
        
        account.DES_Global_banker__c = user.Id;
        account.DES_PF_RENEWAL_DATE__c = system.today();
        update account;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(account);
        accountPlanning.acpl__gf_ap_indvi_lock_edit_ind_type__c = true;
		insert accountPlanning;
        
        acpl__Commercial_Plan_Event__c commPlanEvent = utilsAux.createCommercialPlanEvent(accountPlanning, account);
        bupl__BusinessPlan__c businessPlan = utilsAux.createBusinessPlan(accountPlanning, account);
        
        final acpl__AP_Question__c apQuestion = utils.createAPQuestion(accountPlanning);
        insert apQuestion;

        final dyfr__Template__c dfTemplate = utils.createDfTemplate();
        insert dfTemplate;

        final dyfr__Tab__c dfTab = utils.createDfTab(dfTemplate);
        insert dfTab;

        // crear field configs
        final dyfr__Field_Config__c fieldConfig = utils.createDfFieldConfig(dfTab);
        fieldConfig.dyfr__DeveloperName__c = apQuestion.Name + '_' + Datetime.now();
        insert fieldConfig;

        /*final dyfr__Dependent_value__c depValue = utils.createDfFieldConfig(fieldConfig);
        insert depValue;*/
        
        Test.startTest();
        insert businessPlan;
        insert commPlanEvent;
        apQuestion.acpl__gf_ap_question_form_desc__c = 'question 1';
        update apQuestion;
        
        bupl__BP_Need__c need = utilsAux.createNeed(accountPlanning, businessPlan);
        insert need;
        bupl__BP_GrowthDriver__c growthDriver = utilsAux.createGrowthDriver(accountPlanning, businessPlan);
        insert growthDriver;
        
        final bupl__BusinessPlan_Version__c bpVersion = utilsAux.createBusinessPlanVersion(businessPlan);
      	insert bpVersion;
        
      	final bupl__BusinessPlan_Item__c bpItem = utilsAux.createBusinessPlanItemNormal(bpVersion);
      	insert bpItem;
        bpItem.bupl__expected_revenue_amount__c = 10000;
        update bpItem;
        
        Test.stopTest();
        System.assert(growthDriver.Id != null, 'Did not insert record.');
    }    
}