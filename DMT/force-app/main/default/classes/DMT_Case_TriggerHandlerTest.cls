/**
 * CIBGLOBALD-4374 - Tests of DMT_Case_TriggerHandler (hooked in SER_Case_TRIGGER). Test data comes from
 * DMT_Test_DataFactory.
 */
@IsTest
private class DMT_Case_TriggerHandlerTest {

    private static final String QUEUE_DEVELOPER_NAME = 'DMT_Approvers1';

    @TestSetup
    static void setup() {
        Group queue = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :QUEUE_DEVELOPER_NAME LIMIT 1];
        List<User> users = DMT_Test_DataFactory.generateUsers(1);

        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Test_DataFactory.generateOpportunity();

        DMT_Approver__c approver = DMT_Test_DataFactory.generateApproverBussines();
        approver.DMT_Group__c = queue.DeveloperName;
        update approver;
        DMT_Test_DataFactory.generateApproverMemberForApprover(approver.Id, users[0].Id);
    }

    private static Id queueId() {
        return [SELECT Id FROM Group WHERE DeveloperName = :QUEUE_DEVELOPER_NAME LIMIT 1].Id;
    }

    private static DMT_Line__c line() {
        return [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
    }

    private static Opportunity opportunity() {
        return [SELECT Id FROM Opportunity LIMIT 1];
    }

    @IsTest
    static void afterInsert_approvalCaseGetsTheApproverGroupAsParticipants() {
        Test.startTest();
        Case approvalCase = DMT_Test_DataFactory.generateCaseOppLine(line().Id, opportunity().Id, queueId());
        Test.stopTest();

        User approver = [SELECT Id FROM User WHERE LastName = 'Dmt4374User0' LIMIT 1];
        Integer participants = [
            SELECT COUNT()
            FROM DMT_TeamMember__c
            WHERE User__c = :approver.Id AND (Line__c = :line().Id OR Opportunity__c = :opportunity().Id)
        ];
        Assert.areEqual(2, participants, 'The Case insert creates the Line and Opportunity participants through the trigger hook');
        Assert.isNotNull(approvalCase.Id, 'Case created');
    }

    @IsTest
    static void afterUpdate_finishedCaseMovesItsAttachmentsToTheCurrentTask() {
        Case approvalCase = DMT_Test_DataFactory.generateCaseOppLine(line().Id, opportunity().Id, queueId());
        DMT_Task_Type__c taskType = DMT_Test_DataFactory.generateTaskType('Attachment move step', 'T4374-ATT', false);
        Task openTask = DMT_Test_DataFactory.generateApprovalTask(UserInfo.getUserId(), approvalCase.Id, taskType.Id, 'In Progress');
        Attachment onCase = DMT_Test_DataFactory.generateAttachment(approvalCase.Id, 'case-attachment.txt');

        Test.startTest();
        approvalCase.Status = DMT_Constants.FINISHED;
        update approvalCase;
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Attachment WHERE ParentId = :approvalCase.Id], 'The Case no longer has the attachment');
        List<Attachment> onTask = [SELECT Id, Name FROM Attachment WHERE ParentId = :openTask.Id];
        Assert.areEqual(1, onTask.size(), 'The attachment is now on the current Task');
        Assert.areEqual(onCase.Name, onTask[0].Name, 'Same attachment');
    }
}
