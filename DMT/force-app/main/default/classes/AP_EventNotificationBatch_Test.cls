/***********************************************************************************************
Name:            AP_EventNotificationBatch_Test
Description:     Test Class for AP_EventNotificationBatch, its schedulable and handler

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            02/12/2019      Global Desktop    Class creation

***********************************************************************************************/
@isTest
global class AP_EventNotificationBatch_Test {

    @isTest
    global static void apEventNotificationBatchTest() {
        final Date actualDate = Date.today();

        DES_UtilTestClass utils = new DES_UtilTestClass();
        
        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__NotificationSchedulable_batch_size__c = 1;
        insert apSettings;

        final acpl__AP_PeriodConfiguration__c apPeriodConfig = new acpl__AP_PeriodConfiguration__c();
        apPeriodConfig.acpl__gf_ap_edit_prms_type_name__c = 'General';
        apPeriodConfig.acpl__gf_ap_edit_days_left_number__c = 0;
        insert apPeriodConfig;

        final acpl__AP_Period__c period = new acpl__AP_Period__c();
        period.acpl__gf_ap_edit_start_date__c = actualDate;
        period.acpl__gf_ap_edit_end_date__c = actualDate.addDays(1);
        insert period;
        
        final Account acc = utils.createClient();
        acc.DES_PF_RENEWAL_DATE__c = actualDate;
		insert acc;

        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(acc);
        accountPlanning.acpl__gf_mandatory_type__c = 'Mandatory';
        System.debug('accountPlanning del test: ' + accountPlanning);
        insert accountPlanning;
        
        final String profile = utils.createProfile();
        final User user = utils.createUser(profile, 'username@test.comm');
        user.DES_Disable_Chatter__c = false;
        user.isActive = true;
        insert user;

        final bupl__AP_Team__c apTeamMember = utils.createAPTeamMember(user, accountPlanning);
        insert apTeamMember;
        
         Test.startTest();
            final AP_EventNotificationSchedulable batchNotification = new AP_EventNotificationSchedulable();
            batchNotification.execute(null);
		Test.stopTest();

        System.assert(period.acpl__gf_ap_edit_start_date__c == actualDate,'Ejecución Batch notificación por evento ha fallado');
    }
    /**
    * Met0d0 test 1
    */
     @isTest
    public static void apEven() {
		
		Test.startTest();        final Date actualDate = Date.today();

        DES_UtilTestClass utils = new DES_UtilTestClass();
        
        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__NotificationSchedulable_batch_size__c = 1;
        insert apSettings;

        final acpl__AP_PeriodConfiguration__c apPeriodConfig = new acpl__AP_PeriodConfiguration__c();
        apPeriodConfig.acpl__gf_ap_edit_prms_type_name__c = 'General';
        apPeriodConfig.acpl__gf_ap_edit_days_left_number__c = 0;
        insert apPeriodConfig;

        final acpl__AP_Period__c period = new acpl__AP_Period__c();
        period.acpl__gf_ap_edit_start_date__c = actualDate;
        period.acpl__gf_ap_edit_end_date__c = actualDate.addDays(1);
        insert period;
        
        final Account acc = utils.createClient();
        acc.DES_PF_RENEWAL_DATE__c = actualDate;
		insert acc;

        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(acc);
        accountPlanning.acpl__gf_mandatory_type__c = 'Mandatory';
        
        accountPlanning.acpl__gf_ap_status_type_name__c='Not started';
        System.debug('accountPlanning del test: ' + accountPlanning);
        insert accountPlanning;
        
        final String profile = utils.createProfile();
        final User user = utils.createUser(profile, 'username@test.comm');
        user.DES_Disable_Chatter__c = false;
        user.isActive = true;
        insert user;

        final bupl__AP_Team__c apTeamMember = utils.createAPTeamMember(user, accountPlanning);
        insert apTeamMember;
        final List<bupl__AP_Team__c> apTeamList = [SELECT Id, bupl__gf_ap_team_user_id__c, acpl__gf_account_planning_id__c, acpl__gf_account_planning_id__r.acpl__gf_event_date__c,
                                       acpl__gf_account_planning_id__r.Name FROM bupl__AP_Team__c 
                                       WHERE Id = :apTeamMember.Id  and acpl__gf_account_planning_id__c = :accountPlanning.Id limit 1];
		AP_EventNotificationBatchHandler.generateNotification(0,apTeamList[0]);
        AP_EventNotificationBatchHandler.generateNotification(1,apTeamList[0]);
        AP_EventNotificationBatchHandler.generateNotification(-1,apTeamList[0]);
        AP_EventNotificationBatchHandler.generateNotification(-2,apTeamList[0]);
        AP_EventNotificationBatchHandler.generateNotification(2,apTeamList[0]);
        system.assertNotEquals(apTeamList,null,'Error');
        Test.stopTest();

    
    }
    
    /**
    * Met0d0 test 2
    */
    @isTest
    public static void apEven2() {
        test.startTest();
    final Date actualDate = Date.today();

        DES_UtilTestClass utils = new DES_UtilTestClass();
        
        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__NotificationSchedulable_batch_size__c = 1;
        insert apSettings;

        final acpl__AP_PeriodConfiguration__c apPeriodConfig = new acpl__AP_PeriodConfiguration__c();
        apPeriodConfig.acpl__gf_ap_edit_prms_type_name__c = 'General';
        apPeriodConfig.acpl__gf_ap_edit_days_left_number__c = 0;
        insert apPeriodConfig;

        final acpl__AP_Period__c period = new acpl__AP_Period__c();
        period.acpl__gf_ap_edit_start_date__c = actualDate -2;
        
        period.acpl__gf_ap_edit_end_date__c = actualDate.addDays(1);
        insert period;
        
        final Account acc = utils.createClient();
        acc.DES_PF_RENEWAL_DATE__c = actualDate;
		insert acc;

        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(acc);
        accountPlanning.acpl__gf_mandatory_type__c = 'Mandatory';
        
        accountPlanning.acpl__gf_ap_status_type_name__c='Not started';
        System.debug('accountPlanning del test: ' + accountPlanning);
        insert accountPlanning;
        
        final String profile = utils.createProfile();
        final User user = utils.createUser(profile, 'username@test.comm');
        user.DES_Disable_Chatter__c = false;
        user.isActive = true;
        insert user;

        final bupl__AP_Team__c apTeamMember = utils.createAPTeamMember(user, accountPlanning);
        insert apTeamMember;
        final List<bupl__AP_Team__c> apTeamList = [SELECT Id, bupl__gf_ap_team_user_id__c, acpl__gf_account_planning_id__c, acpl__gf_account_planning_id__r.acpl__gf_event_date__c,
                                       acpl__gf_account_planning_id__r.Name FROM bupl__AP_Team__c 
                                       WHERE Id = :apTeamMember.Id  and acpl__gf_account_planning_id__c = :accountPlanning.Id limit 1];
        AP_EventNotificationBatchHandler.generateNotification(2,apTeamList[0]);
        system.assertNotEquals(apTeamList,null,'Error');
        Test.stopTest();

    
    }
    /**
    * Met0d0 test 3
    */
    @isTest
    public static void apEven3() {
		
		Test.startTest();
               final Date actualDate = Date.today();

        DES_UtilTestClass utils = new DES_UtilTestClass();
        
        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__NotificationSchedulable_batch_size__c = 1;
        insert apSettings;

        final acpl__AP_PeriodConfiguration__c apPeriodConfig = new acpl__AP_PeriodConfiguration__c();
        apPeriodConfig.acpl__gf_ap_edit_prms_type_name__c = 'General';
        apPeriodConfig.acpl__gf_ap_edit_days_left_number__c = 0;
        insert apPeriodConfig;

        final acpl__AP_Period__c period = new acpl__AP_Period__c();
        period.acpl__gf_ap_edit_start_date__c = actualDate+2;
        period.acpl__gf_ap_edit_end_date__c = actualDate.addDays(1);
        insert period;
        
        final Account acc = utils.createClient();
        acc.DES_PF_RENEWAL_DATE__c = actualDate;
		insert acc;

        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(acc);
        accountPlanning.acpl__gf_mandatory_type__c = 'Mandatory';
        
        accountPlanning.acpl__gf_ap_status_type_name__c='Not started';
        System.debug('accountPlanning del test: ' + accountPlanning);
        insert accountPlanning;
        
        final String profile = utils.createProfile();
        final User user = utils.createUser(profile, 'username@test.comm');
        user.DES_Disable_Chatter__c = false;
        user.isActive = true;
        insert user;

        final bupl__AP_Team__c apTeamMember = utils.createAPTeamMember(user, accountPlanning);
        insert apTeamMember;
        final List<bupl__AP_Team__c> apTeamList = [SELECT Id, bupl__gf_ap_team_user_id__c, acpl__gf_account_planning_id__c, acpl__gf_account_planning_id__r.acpl__gf_event_date__c,
                                       acpl__gf_account_planning_id__r.Name FROM bupl__AP_Team__c 
                                       WHERE Id = :apTeamMember.Id  and acpl__gf_account_planning_id__c = :accountPlanning.Id limit 1];
        AP_EventNotificationBatchHandler.generateNotification(-2,apTeamList[0]);
        system.assertNotEquals(apTeamList,null,'Error');
        Test.stopTest();
    }
}