/***********************************************************************************************
Name:            DES_AP_TeamHandlerTest
Description:     Test Class for DES_AP_TeamHandler class

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            01/10/2019      Global Desktop    Class creation
1.1            28/11/2019      Global Desktop    Added methods for new features of tested class

***********************************************************************************************/
@isTest
public class DES_AP_TeamHandlerTest {

    @TestSetup
    static void makeData(){
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

		final Account acc = utilTestClass.createClient();
		insert acc;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;

        final acpl__Account_Planning__c accountPlanning = utilTestClass.createAccountPlanning(acc);
        insert accountPlanning;

        final String profile = [SELECT Id FROM Profile WHERE Name =: Label.DES_PROFILE_GCC_STANDARD].get(0).Id;
        final User user = utilTestClass.createUser(profile, 'username@test.comm');
        insert user;
    }

    @IsTest
    static void notifyGBTest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final User user = [SELECT Id,Name FROM User LIMIT 1].get(0);
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;
        
        final acpl__Account_Planning__c accountPlanning = [SELECT Id FROM acpl__Account_Planning__c LIMIT 1].get(0);

        final bupl__AP_Team__c apTeamMember = utilTestClass.createAPTeamMember(user, accountPlanning);
        apTeamMember.bupl__gf_ap_team_role_user_name__c = Label.DES_ROLE_GLOBAL_BANKER;
        List<bupl__AP_Team__c> apTeamList = new List<bupl__AP_Team__c>();
        apTeamList.add(apTeamMember);

        Test.startTest();
        Database.saveResult saveAPTeamResult = Database.insert(apTeamList).get(0);
        Test.stopTest();

        System.assert(saveAPTeamResult.isSuccess(),'Insertion and notification to Global Banker failed.');
    }

    @IsTest
    static void logicsCheckNotGlobalBankerTest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final User user = [SELECT Id,Name FROM User LIMIT 1].get(0);
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;
        
        final acpl__Account_Planning__c accountPlanning = [SELECT Id FROM acpl__Account_Planning__c LIMIT 1].get(0);

        final bupl__AP_Team__c apTeamMember = utilTestClass.createAPTeamMember(user, accountPlanning);
        apTeamMember.bupl__gf_ap_team_role_user_name__c = Label.DES_ROLE_GLOBAL_BANKER;

        Test.startTest();
        String finalError;
        System.runAs(user) {
            try {
                insert apTeamMember;
            } catch (Exception e) {
                if(!e.getMessage().contains(Label.DES_AP_ONLY_GB_CAN)) {
                    throw e;
                }
            }
        }
        if(Schema.sObjectType.bupl__AP_Team__c.isCreateable()) {
            insert apTeamMember;
        }
        final bupl__AP_Team__c apTeamMember2 = utilTestClass.createAPTeamMember(user, accountPlanning);
        apTeamMember2.bupl__gf_ap_team_role_user_name__c = Label.DES_ROLE_GLOBAL_BANKER;
        System.runAs(user) {
            try {
                insert apTeamMember2;
            } catch (Exception e) {
                finalError = e.getMessage();
            }
        }
        Test.stopTest();

        System.assert(finalError.contains(Label.DES_AP_ONLY_ONE_GB),'Did not reach second insert of GB to check all posible logics.');
    }

    @IsTest
    static void checkUserDeletingTest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final User user = [SELECT Id,Name FROM User LIMIT 1].get(0);
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;
        
        final acpl__Account_Planning__c accountPlanning = [SELECT Id FROM acpl__Account_Planning__c LIMIT 1].get(0);

        final String profile = [SELECT Id FROM Profile WHERE Name =: Label.DES_PROFILE_GCC_STANDARD].get(0).Id;
        User userAux = utilTestClass.createUser(profile, 'username2@test.comm');
        final String userName = userAux.username;
        insert userAux;

        final List<bupl__AP_Team__c> liAPMembers = new List<bupl__AP_Team__c>();
        final bupl__AP_Team__c apTeamMember = utilTestClass.createAPTeamMember(user, accountPlanning);
        apTeamMember.bupl__gf_ap_team_role_user_name__c = Label.DES_ROLE_GLOBAL_BANKER;
        final bupl__AP_Team__c apTeamMember2 = utilTestClass.createAPTeamMember(userAux, accountPlanning);
        apTeamMember2.bupl__gf_ap_team_role_user_name__c = 'Risk Analyst';
        liAPMembers.add(apTeamMember);
        liAPMembers.add(apTeamMember2);
        insert liAPMembers;

        Test.startTest();
        System.runAs(userAux) {
            try {
                delete apTeamMember;
            } catch (Exception e) {
                if(!e.getMessage().contains(Label.DES_AP_ONLY_GB_DELETE)) {
                    //throw e;
                }
            }
        }
        System.runAs(user) {
            try {
                delete apTeamMember;
            } catch (Exception e) {
                if(!e.getMessage().contains(Label.DES_AP_NOT_DELETE_GB)) {
                    //throw e;
                }
            }
            delete apTeamMember2;
        }
        List<bupl__AP_Team__c> memberDeleted = [SELECT Id FROM bupl__AP_Team__c WHERE bupl__gf_ap_team_role_user_name__c = 'Risk Analyst'];
        Test.stopTest();

        System.assert(memberDeleted.isEmpty(),'Did not check all delete logics and finally delete correctly.');
    }

}