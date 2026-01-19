/***********************************************************************************************
Name:            DES_APDynamicButtonsTest
Description:     Test Class for DES_APDynamicButtonsStatusHandler and APButtonsValidationMessages classes

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            29/04/2020      Global Desktop    Class creation

***********************************************************************************************/
@isTest
public class DES_APDynamicButtonsTest {
	
    /**
    * dynamicButtonsPanel test
    */
    @IsTest
    static void dynamicButtonsPanel() {
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        
        final Account acc = utils.createClient();
        insert acc;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        apSettings.acpl__Member_Role__c = 'Global Banker';
        insert apSettings;

        final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
        apConfig.acpl__gf_ap_edit_prms_type_name__c = 'General';
        insert apConfig;

        final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
        insert apPeriod;

        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(acc);
        accountPlanning.acpl__gf_ap_indvi_lock_edit_ind_type__c = true;
        accountPlanning.acpl__participant_id__c = acc.Id;
        accountPlanning.acpl__gf_ap_launch_name__c  = 'General Period';
        accountPlanning.acpl__gf_ap_status_type_name__c = 'Not Started';        
        accountPlanning.acpl__gf_ap_substatus_type_name__c  = 'Not Started';
        insert accountPlanning;

        final String profile = utils.createProfile();
        final User user = utils.createUser(profile, 'username@test.comm');
        insert user;

        final bupl__AP_Team__c apTeamMember = utils.createAPTeamMember(user, accountPlanning);
        apTeamMember.bupl__gf_ap_team_role_user_name__c = 'Global Banker';
        final List<bupl__AP_Team__c> apTeamList = new List<bupl__AP_Team__c>();
        apTeamList.add(apTeamMember);
        insert apTeamList;

        accountPlanning.acpl__gf_ap_status_type_name__c = 'Validated';        
        accountPlanning.acpl__gf_ap_substatus_type_name__c  = 'In place';
        update accountPlanning;

        System.runAs(user) {
            Test.startTest();
            final Set<String> buttonsStatusSet = DES_APDynamicButtonsStatusHandler.getDynamicButtonStatus(accountPlanning.Id, 'acpl__Account_Planning__c');
            accountPlanning.acpl__gf_ap_substatus_type_name__c  = 'Under Review';
            update accountPlanning;
            DES_APDynamicButtonsStatusHandler.getDynamicButtonStatus(accountPlanning.Id, 'acpl__Account_Planning__c');
            Test.stopTest();
            System.assert(!buttonsStatusSet.isEmpty(), 'User not Global Banker');
        }
    }
}