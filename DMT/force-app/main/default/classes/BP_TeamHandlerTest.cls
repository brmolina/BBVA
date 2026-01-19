/***********************************************************************************************
Name:            BP_TeamHandlerTest
Description:     Test Class for BP_TeamHandler class

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            02/12/2019      Global Desktop    Class creation

***********************************************************************************************/

    @isTest
global class BP_TeamHandlerTest {

    @IsTest
    global static void bPInsertBPTeamMember() {
        final BP_TeamHandler bpTeamHandler = BP_TeamHandler.getInstance();
        DES_UtilTestClass utils = new DES_UtilTestClass();
        DES_UtilTestClassAux utilsAux = new DES_UtilTestClassAux();

        Account acc = utils.createClient();
        insert acc;
        
        String profile = utils.createProfile();
        User user = utils.createUser(profile, 'username@test.comm');
        insert user;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(acc);
        insert accountPlanning;

        final bupl__BusinessPlan__c businessPlan = utilsAux.createBusinessPlan(accountPlanning, acc);
        insert businessPlan;

        final bupl__AP_Team__c bpTeamMember = utils.createAPTeamMember(user, accountPlanning);
        final List<bupl__AP_Team__c> bpTeamList = new List<bupl__AP_Team__c>();
        bpTeamList.add(bpTeamMember);

        Test.startTest();
        insert bpTeamList;
        delete bpTeamList;
        Test.stopTest();
		
        final List<bupl__BusinessPlan__Share> bpShare = [SELECT AccessLevel FROM bupl__BusinessPlan__Share WHERE UserOrGroupId =: user.Id LIMIT 50000];
        System.assert(bpShare.isEmpty(), 'No se cumple Assert');
                
    }

}