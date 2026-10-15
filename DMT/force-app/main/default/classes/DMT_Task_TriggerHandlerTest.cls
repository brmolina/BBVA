/**
 * CIBGLOBALD-4374 - Tests of DMT_Task_TriggerHandler (hooked in Task.trigger). Test data comes from
 * DMT_Test_DataFactory.
 */
@IsTest
private class DMT_Task_TriggerHandlerTest {

    @TestSetup
    static void setup() {
        DMT_Test_DataFactory.generateUsers(1);
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Test_DataFactory.generateOpportunity();
    }

    private static DMT_Line__c line() {
        return [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
    }

    private static Opportunity opportunity() {
        return [SELECT Id, DMT_Has_Asset_Allocation__c FROM Opportunity LIMIT 1];
    }

    private static Case approvalCase() {
        return DMT_Test_DataFactory.generateCaseOppLine(line().Id, opportunity().Id, UserInfo.getUserId());
    }

    @IsTest
    static void beforeUpdate_stampsTheClosingUserWhenAStepIsCompleted() {
        Case parentCase = approvalCase();
        DMT_Task_Type__c taskType = DMT_Test_DataFactory.generateTaskType('Stamp step', 'T4374-STAMP', false);
        Task step = DMT_Test_DataFactory.generateApprovalTask(UserInfo.getUserId(), parentCase.Id, taskType.Id, 'In Progress');

        Test.startTest();
        step.Status = DMT_Constants.COMPLETED;
        update step;
        Test.stopTest();

        Task stamped = [SELECT DMT_UserClosedTask__c, DMT_Completed_Date_Time__c FROM Task WHERE Id = :step.Id];
        Assert.areEqual(UserInfo.getUserId(), stamped.DMT_UserClosedTask__c, 'The closing user is stamped');
        Assert.isNotNull(stamped.DMT_Completed_Date_Time__c, 'The closing date is stamped');
    }

    @IsTest
    static void beforeUpdate_doesNotStampAFinishedStep() {
        Case parentCase = approvalCase();
        DMT_Task_Type__c taskType = DMT_Test_DataFactory.generateTaskType('No stamp step', 'T4374-NOSTAMP', false);
        Task step = DMT_Test_DataFactory.generateApprovalTask(UserInfo.getUserId(), parentCase.Id, taskType.Id, 'In Progress');

        Test.startTest();
        step.Status = DMT_Constants.FINISHED;
        update step;
        Test.stopTest();

        Task unchanged = [SELECT DMT_UserClosedTask__c FROM Task WHERE Id = :step.Id];
        Assert.isNull(unchanged.DMT_UserClosedTask__c, 'Finished steps are not stamped, same rule as the flow');
    }

    @IsTest
    static void afterInsert_assetAllocationStepFlagsTheOpportunity() {
        Case parentCase = approvalCase();
        DMT_Task_Type__c assetAllocation = DMT_Test_DataFactory.generateTaskType(
            DMT_Task_TriggerHandler.ASSET_ALLOCATION_TASK_TYPE, 'T4374-AA', false
        );

        Test.startTest();
        DMT_Test_DataFactory.generateApprovalTask(UserInfo.getUserId(), parentCase.Id, assetAllocation.Id, 'In Progress');
        Test.stopTest();

        Assert.areEqual(true, opportunity().DMT_Has_Asset_Allocation__c, 'The Opportunity is flagged as having an asset allocation step');
    }

    @IsTest
    static void afterUpdate_closedStepWithdrawsTheApprovalEditGrants() {
        Case parentCase = approvalCase();
        DMT_Task_Type__c taskType = DMT_Test_DataFactory.generateTaskType('Grant step', 'T4374-GRANT', false);
        Task step = DMT_Test_DataFactory.generateApprovalTask(UserInfo.getUserId(), parentCase.Id, taskType.Id, 'In Progress');
        User member = [SELECT Id FROM User WHERE LastName = 'Dmt4374User0' LIMIT 1];
        DMT_TeamMember__c lineMember = DMT_Test_DataFactory.generateTeamMembers(
            new List<Id>{ member.Id }, line().Id, null,
            new Map<Schema.SObjectField, Object>{
                DMT_TeamMember__c.AccessLevel__c => DMT_TeamMember_Service.EDIT_ACCESS,
                DMT_TeamMember__c.DMT_ApprovalEdit__c => true
            }
        )[0];

        Test.startTest();
        step.Status = DMT_Constants.COMPLETED;
        update step;
        Test.stopTest();

        Assert.areEqual(DMT_TeamMember_Service.READ_ACCESS, [SELECT AccessLevel__c FROM DMT_TeamMember__c WHERE Id = :lineMember.Id].AccessLevel__c,
            'Closing the step puts the participant back to Read');
    }
}
