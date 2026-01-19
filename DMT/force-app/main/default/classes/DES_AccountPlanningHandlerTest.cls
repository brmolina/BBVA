/**********************************************************************************
* @author       Global Desktop
* @date         22/07/2019
* @description  Clase de test de Account Planning
* @Revision
**********************************************************************************/
@isTest
public class DES_AccountPlanningHandlerTest {
    /*
    * @author       Global Desktop
    * @Description  Inserts the global banker in the AP team
    */
    @IsTest
    static void insertGBinTeam_Test() {
        DES_UtilTestClass utils = new DES_UtilTestClass();

        String profile = String.valueOf([Select Id From Profile Where Name='System Administrator'].Id);
        System.debug('utils.createProfile(): ' + utils.createProfile());
        System.debug('profile: ' + profile);

        List<User> userList;
        userList = new List<User>();
        User user = utils.createUser(profile, 'username@test.comm');
        userList.add(user);

        final User validator1 = utils.createUser(profile, '@validator1.comm');
        final User validator2 = utils.createUser(profile, '@validator2.comm');
        userList.add(validator1);
        userList.add(validator2);
        insert userList;

        Account groupAccount;
        groupAccount = utils.createClient();
        insert groupAccount;

        DES_BBVA_Management_team__c bbvaTM = utils.createBBVAManagementTeamMember(user, groupAccount);
        bbvaTM.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
        bbvaTM.DES_Local_Banker_Country__c = 'Global';
        insert bbvaTM;

        groupAccount.DES_Global_banker__c = user.Id;
        groupAccount.DES_PF_RENEWAL_DATE__c = system.today();
        update groupAccount;

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

        acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(groupAccount);
        accountPlanning.acpl__gf_ap_indvi_lock_edit_ind_type__c = true;
        accountPlanning.acpl__gf_ap_validator_user_id__c = validator1.Id;
        insert accountPlanning;

        System.runAs(user) {
            Test.startTest();
            accountPlanning.acpl__gf_ap_substatus_type_name__c = 'Not started';
            accountPlanning.acpl__gf_ap_indvi_lock_edit_ind_type__c = false;
            update accountPlanning;
            accountPlanning.acpl__gf_ap_indvi_lock_edit_ind_type__c = true;
            accountPlanning.acpl__gf_ap_validator_user_id__c = validator2.Id;
            update accountPlanning;
        Test.stopTest();
        System.assert(accountPlanning.acpl__gf_ap_validator_user_id__c == validator2.Id, 'Validator not changed.');
        }
    }


    /*
    * @author       Global Desktop
    * @Description  updateEventDateTest
    */
    @IsTest
    static void updateEventDateTest() {
      final DES_AccountPlanningHandler apHandler = DES_AccountPlanningHandler.getInstance();
      DES_UtilTestClass utils = new DES_UtilTestClass();

      //Creación de perfil y usuario
      final String profile = utils.createProfile();
      final User validator = utils.createUser(profile, '@validator.comm');
      insert validator;

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
      accountPlanning.acpl__gf_ap_validator_user_id__c = validator.Id;
      List<acpl__Account_Planning__c> apNewList = new List<acpl__Account_Planning__c>();
      apNewList.add(accountPlanning);

      Test.startTest();
          insert accountPlanning;
          delete accountPlanning;
      Test.stopTest();
      System.assert(accountPlanning.Id != null, 'Account Plan not deleted.');
    }

    /*
    * @author       Global Desktop
    * @Description  massiveLock
    */
    @IsTest
    static void massiveLock() {
        DES_UtilTestClass utils = new DES_UtilTestClass();
        //Creación cuenta
        final Account acc = utils.createClient();
        acc.DES_PF_RENEWAL_DATE__c = Date.Today().addDays(40);
        final Account acc2 = utils.createClient();
        List<Account> accountList;
        accountList = new List<Account>();
        accountList.add(acc);
        accountList.add(acc2);
        insert accountList;

        final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
        insert apConfig;

        final AP_notif__c apNotif = new AP_notif__c();
 			apNotif.Name ='Notificaciones';
        	apNotif.gf_admin_notif_lock_mgr_desc__c ='bloqueo masivo';
        	apNotif.gf_admin_notif_unlock_mgr_desc__c ='desbloqueo masivo';
 			insert apNotif;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;

        final acpl__Account_Planning__c accountPlanning1 = utils.createAccountPlanning(acc);
        final acpl__Account_Planning__c accountPlanning2 = utils.createAccountPlanning(acc2);
        List<acpl__Account_Planning__c> apList;
        apList = new List<acpl__Account_Planning__c>();
        apList.add(accountPlanning1);
        apList.add(accountPlanning2);
        insert apList;

        String profile = String.valueOf([Select Id From Profile Where Name='System Administrator'].Id);
        User user = utils.createUser(profile, 'username@test.comm');
        user.DES_Disable_Chatter__c = false;
        user.IsActive = true;
        insert user;


        bupl__AP_Team__c apTeam1 = utils.createAPTeamMember(user, accountPlanning1);
        bupl__AP_Team__c apTeam2 = utils.createAPTeamMember(user, accountPlanning2);
        List<bupl__AP_Team__c> apTeamList;
        apTeamList = new List<bupl__AP_Team__c>();
        apTeamList.add(apTeam1);
        apTeamList.add(apTeam2);
        insert apTeamList;

        System.runAs(user) {
        Test.startTest();
            accountPlanning1.acpl__gf_ap_substatus_type_name__c = 'Not started';
            accountPlanning1.acpl__gf_ap_indvi_lock_edit_ind_type__c = false;
            accountPlanning2.acpl__gf_ap_substatus_type_name__c = 'Not started';
            accountPlanning2.acpl__gf_ap_indvi_lock_edit_ind_type__c = false;
            update apList;
            accountPlanning1.acpl__gf_ap_indvi_lock_edit_ind_type__c = true;
            accountPlanning2.acpl__gf_ap_indvi_lock_edit_ind_type__c = true;
            update apList;
        Test.stopTest();
        System.assert(accountPlanning1.acpl__gf_ap_indvi_lock_edit_ind_type__c, 'Account Plan locked');
        }
    }

    /*
    * @author       Global Desktop
    * @Description  due date
    */
    @IsTest
    static void fillDueDateTest() {
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        //Creación cuenta
        final Account acc = utils.createClient();
        acc.DES_PF_RENEWAL_DATE__c = Date.Today().addDays(40);
        final Account acc2 = utils.createClient();
        acc2.DES_PF_RENEWAL_DATE__c = Date.Today().addDays(40);
        List<Account> accountList;
        accountList = new List<Account>();
        accountList.add(acc);
        accountList.add(acc2);
        insert accountList;

        final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
        apConfig.acpl__gf_ap_edit_prms_type_name__c = '';
        insert apConfig;

        final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
        //insert apPeriod;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;        

        final acpl__Account_Planning__c accountPlanning1 = utils.createAccountPlanning(acc);
        final acpl__Account_Planning__c accountPlanning3 = utils.createAccountPlanning(acc2);
        accountPlanning3.acpl__gf_ap_launch_name__c = 'Event driven';
        insert accountPlanning1;
        insert accountPlanning3;

        Test.startTest();
            apConfig.acpl__gf_ap_edit_prms_type_name__c = 'General';
            update apConfig;
            apPeriod.acpl__gf_ap_edit_end_date__c = Date.Today() + 1;
            insert apPeriod;
            update accountPlanning3;


        Test.stopTest();
        System.assert(apConfig.acpl__gf_ap_edit_prms_type_name__c == 'General', 'Account Plan due date empty');

    }

    /*
    * @author       Global Desktop
    * @Description  due date
    */
    @IsTest
    static void fillDueDateTestwave() {
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        //Creación cuenta
        final Account acc = utils.createClient();
        acc.DES_PF_RENEWAL_DATE__c = Date.Today().addDays(40);
        final Account acc2 = utils.createClient();
        acc2.DES_PF_RENEWAL_DATE__c = Date.Today().addDays(40);
        List<Account> accountList;
        accountList = new List<Account>();
        accountList.add(acc);
        accountList.add(acc2);
        insert accountList;

        final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
        apConfig.acpl__gf_ap_edit_prms_type_name__c = 'General';
        insert apConfig;

        final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
        //insert apPeriod;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;

        final acpl__Account_Planning__c accountPlanning1 = utils.createAccountPlanning(acc);
        final acpl__Account_Planning__c accountPlanning2 = utils.createAccountPlanning(acc2);
        final acpl__Account_Planning__c accountPlanning3 = utils.createAccountPlanning(acc2);
        accountPlanning3.acpl__gf_ap_launch_name__c = 'Event driven';
        insert accountPlanning1;
        insert accountPlanning3;

        Test.startTest();
            apConfig.acpl__gf_ap_edit_prms_type_name__c = 'Wave';
            update apConfig;
            apPeriod.acpl__gf_ap_edit_end_date__c = Date.Today() + 1;
            insert apPeriod;
            update accountPlanning3;


        Test.stopTest();
        System.assert(apConfig.acpl__gf_ap_edit_prms_type_name__c == 'Wave', 'Account Plan due date empty');

    }

    /*
    * @author       Global Desktop
    * @Description	updateGAlookupInAP test
    */
    @IsTest
    static void updateGAlookupInAPTest() {
      final DES_UtilTestClass utils = new DES_UtilTestClass();

      //Creación cuenta
      final Account account = utils.createClient();
      insert account;

      final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
      insert apConfig;

      final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
      apPeriod.acpl__gf_ap_edit_start_date__c = date.Today()+1;
      insert apPeriod;

      final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
      apSettings.acpl__Unlock_when_change_DueDate__c = false;
      insert apSettings;

      //Creación del account planning
      final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(account);
      insert accountPlanning;

      Test.startTest();
          accountPlanning.acpl__gf_ap_status_type_name__c = 'Validated';
        accountPlanning.acpl__gf_ap_substatus_type_name__c = 'In place';
        update accountPlanning;
      Test.stopTest();
      final List<DES_Group_Analysis__c> gaList = [SELECT Id FROM DES_Group_Analysis__c WHERE gf_account_planning_id__c = :accountPlanning.Id];
      System.assert(accountPlanning != null, 'Account Planning not created');
    }

}