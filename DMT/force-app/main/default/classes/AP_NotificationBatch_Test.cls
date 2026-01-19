/***********************************************************************************************
Name:            AP_NotificationBatch_Test
Description:     Test Class for AP_NotificationBatch, its schedulable and handler

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            29/11/2019      Global Desktop    Class creation

***********************************************************************************************/
@isTest
global class AP_NotificationBatch_Test {

    @TestSetup
    global static void makeData() {
        final Date actualDate = Date.today();
        DES_UtilTestClass utils = new DES_UtilTestClass();

		final Account acc = utils.createClient();
		insert acc;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        apSettings.acpl__NotificationSchedulable_batch_size__c = 3;
        insert apSettings;

        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(acc);
        accountPlanning.acpl__gf_event_date__c = actualDate;
        insert accountPlanning;

        final String profile = utils.createProfile();
        final User user = utils.createUser(profile, 'username@test.comm');
        insert user;

        final bupl__AP_Team__c apTeamMember = utils.createAPTeamMember(user, accountPlanning);
        insert apTeamMember;
    }

    @isTest
    global static void apNotificationBatchGeneralTest() {
        final Date actualDate = Date.today();


        final acpl__AP_PeriodConfiguration__c apPeriodConfig = new acpl__AP_PeriodConfiguration__c();
        apPeriodConfig.acpl__gf_ap_edit_prms_type_name__c = 'General';
        apPeriodConfig.acpl__gf_ap_edit_days_left_number__c = 30;
        insert apPeriodConfig;

        final acpl__AP_Period__c period = new acpl__AP_Period__c();
        period.acpl__gf_ap_edit_start_date__c = actualDate;
        period.acpl__gf_ap_edit_end_date__c = actualDate.addDays(1);
        insert period;

        Test.startTest();
            final AP_NotificationSchedulable batchNotification = new AP_NotificationSchedulable();
            batchNotification.execute(null);
		Test.stopTest();

        final List<Task> result = [SELECT Id FROM Task];
        System.assert(!result.isEmpty(),'Ejecución Batch por prioridad general ha fallado');
    }

    @isTest
    global static void apNotificationBatchPriorityTest() {
        final Date actualDate = Date.today();
        
        final acpl__AP_PeriodConfiguration__c apPeriodConfig = new acpl__AP_PeriodConfiguration__c();
        apPeriodConfig.acpl__gf_ap_edit_prms_type_name__c = 'Wave';
        apPeriodConfig.acpl__gf_ap_edit_days_left_number__c = 30;
        insert apPeriodConfig;

        final List<acpl__AP_Period__c> liPeriods = new List<acpl__AP_Period__c>();
        final acpl__AP_Period__c periodH = new acpl__AP_Period__c();
        periodH.acpl__gf_ap_priority_edit_type__c = 'Wave 90';
        periodH.acpl__gf_ap_edit_start_date__c = actualDate.addDays(-1);
        periodH.acpl__gf_ap_edit_end_date__c = actualDate;
        liPeriods.add(periodH);
        final acpl__AP_Period__c periodM = new acpl__AP_Period__c();
        periodM.acpl__gf_ap_priority_edit_type__c = 'Wave 50';
        periodM.acpl__gf_ap_edit_start_date__c = actualDate;
        periodM.acpl__gf_ap_edit_end_date__c = actualDate.addDays(1);
        liPeriods.add(periodM);
        final acpl__AP_Period__c periodL = new acpl__AP_Period__c();
        periodL.acpl__gf_ap_priority_edit_type__c = 'Wave 1';
        periodL.acpl__gf_ap_edit_start_date__c = actualDate.addDays(-1);
        periodL.acpl__gf_ap_edit_end_date__c = actualDate.addDays(1);
        periodL.acpl__gf_ap_notfn_next_close_date__c = actualDate;
        liPeriods.add(periodL);
        insert liPeriods;

        Test.startTest();
            final AP_NotificationSchedulable batchNotification = new AP_NotificationSchedulable();
            batchNotification.execute(null);
		Test.stopTest();

        final List<Task> result = [SELECT Id FROM Task];
        System.assert(!result.isEmpty(),'Ejecución Batch por niveles de prioridad ha fallado');
    }

}