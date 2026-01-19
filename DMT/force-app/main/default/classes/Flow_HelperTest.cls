/****************************************************
* @author       Global Desktop
* @date         19/09/2019
* @description  Clase de test de la clase Flow_Helper
* @Revision
****************************************************/
@isTest
public class Flow_HelperTest {

    static void flowHelperTestMethod() {
        //Instances
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final Flow_Helper.FlowHelper flowHelperInst = new Flow_Helper.FlowHelper();

        //Profile and user creation
        final String profileId = utilTestClass.createProfile();
        final User userTest1 = utilTestClass.createUser(profileId, 'TestValidator1@test.test');
        userTest1.IsActive = true;
        userTest1.DES_Disable_Chatter__c = false;
        final User userTest2 = utilTestClass.createUser(profileId, 'TestValidator2@test.test');
        userTest2.DES_Disable_Chatter__c = true;
        final User userTest3 = utilTestClass.createUser(profileId, 'TestValidator3@test.test');
        userTest3.IsActive = false;
        final User userTest4 = utilTestClass.createUser(profileId, 'validator4@test.test');
        userTest4.IsActive = true;
        List<User> userList;
        userList = new List<User>();
        userList.add(userTest1);
        userList.add(userTest2);
        userList.add(userTest3);
        userList.add(userTest4);
        insert userList;
        List<Id> userIdSet;
        userIdSet = new List<Id>();
        for(User userAux : userList) {
            if(!userIdSet.contains(userAux.Id)) {
                userIdSet.add(userAux.Id);
            }
        }
        //Account creation
        final Account acc = utilTestClass.createClient();
        insert acc;
        final acpl__AP_PeriodConfiguration__c apPeriodConfig = new acpl__AP_PeriodConfiguration__c();
        insert apPeriodConfig;
        
        final Date actualDate = Date.today();
        final acpl__AP_Period__c period = new acpl__AP_Period__c();
        period.acpl__gf_ap_edit_start_date__c = actualDate;
        period.acpl__gf_ap_edit_end_date__c = actualDate.addDays(1);
        insert period;
        //Account Planning creation
        final acpl__Account_Planning__c accountPlanning = utilTestClass.createAccountPlanning(acc);
        final List<acpl__Account_Planning__c> accPlanList = new List<acpl__Account_Planning__c>();
        accPlanList.add(accountPlanning);
        insert accPlanList;
        //AP team creation
        final bupl__AP_Team__c apTeam1 = utilTestClass.createAPTeamMember(userTest1, accPlanList[0]);
        final bupl__AP_Team__c apTeam2 = utilTestClass.createAPTeamMember(userTest2, accPlanList[0]);
        final bupl__AP_Team__c apTeam3 = utilTestClass.createAPTeamMember(userTest3, accPlanList[0]);
        List<bupl__AP_Team__c> apTeamList;
        apTeamList = new List<bupl__AP_Team__c>();
        apTeamList.add(apTeam1);
        apTeamList.add(apTeam2);
        apTeamList.add(apTeam3);
        insert apTeamList;

        final List<Flow_Helper.FlowHelper> flowHelperList = new List<Flow_Helper.FlowHelper>();
        flowHelperList.add(flowHelperInst);

        Test.startTest();
        flowHelperInst.method = 'notifyAPTeam';
        flowHelperInst.accountPlanningList = accPlanList;
        Flow_Helper.FlowHelper.callFromFlow(flowHelperList);
        
        flowHelperInst.method = 'createShare';
        flowHelperInst.recordId = accountPlanning.Id;
        flowHelperInst.userOrGroupId = userTest4.Id;
        flowHelperInst.stringVar = 'Edit';
        Flow_Helper.FlowHelper.callFromFlow(flowHelperList);
        
        flowHelperInst.method = 'notifyUsers';
        flowHelperInst.idList = userIdSet;
        Flow_Helper.FlowHelper.callFromFlow(flowHelperList);
        
        flowHelperInst.method = 'separateUsers';
        flowHelperInst.apTeamList = apTeamList;
        Flow_Helper.FlowHelper.callFromFlow(flowHelperList);
        
        flowHelperInst.method = 'checkUserChatter';
        flowHelperInst.userOrGroupId = userTest1.Id;
        Flow_Helper.FlowHelper.callFromFlow(flowHelperList);

        System.assertNotEquals(Flow_Helper.FlowHelper.callFromFlow(flowHelperList), null);
        Test.stopTest();
    }

}