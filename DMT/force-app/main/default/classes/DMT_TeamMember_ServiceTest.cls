/**
 * CIBGLOBALD-4374 - Tests of DMT_TeamMember_Service. Test data comes from DMT_Test_DataFactory.
 *
 * The queue DMT_Approvers1 already exists in the org (the same one DMT_CreateTeamMemberCase_test uses).
 */
@IsTest
private class DMT_TeamMember_ServiceTest {

    private static final String QUEUE_DEVELOPER_NAME = 'DMT_Approvers1';

    @TestSetup
    static void setup() {
        Group queue = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :QUEUE_DEVELOPER_NAME LIMIT 1];
        List<User> users = DMT_Test_DataFactory.generateUsers(2);

        DMT_Test_DataFactory.generateTestTreasuryLines();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        DMT_Approver__c approver = DMT_Test_DataFactory.generateApproverBussines();
        approver.DMT_Group__c = queue.DeveloperName;
        update approver;
        DMT_Test_DataFactory.generateApproverMemberForApprover(approver.Id, users[0].Id);
    }

    private static Group queue() {
        return [SELECT Id FROM Group WHERE DeveloperName = :QUEUE_DEVELOPER_NAME LIMIT 1];
    }

    private static DMT_Line__c line() {
        return [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];
    }

    private static Opportunity opportunity() {
        return [SELECT Id FROM Opportunity LIMIT 1];
    }

    private static User approverUser() {
        return [SELECT Id FROM User WHERE LastName = 'Dmt4374User0' LIMIT 1];
    }

    private static List<DMT_TeamMember__c> membersOf(Id userId, Id lineId, Id opportunityId) {
        return [
            SELECT Id, User__c, Line__c, Opportunity__c, AccessLevel__c, Team_Role__c, DMT_ApprovalEdit__c
            FROM DMT_TeamMember__c
            WHERE User__c = :userId AND (Line__c = :lineId OR Opportunity__c = :opportunityId)
        ];
    }

    @IsTest
    static void addApproversForCases_createsMembersForLineAndOpportunity() {
        Case approvalCase = DMT_Test_DataFactory.generateCaseOppLine(line().Id, opportunity().Id, queue().Id);

        Test.startTest();
        DMT_TeamMember_Service.addApproversForCases(new List<DMT_TeamMember_Service.CaseRequest>{
            new DMT_TeamMember_Service.CaseRequest(approvalCase.Id, false)
        });
        Test.stopTest();

        List<DMT_TeamMember__c> members = membersOf(approverUser().Id, line().Id, opportunity().Id);
        Assert.areEqual(2, members.size(), 'One participant on the Line and one on the Opportunity, never duplicated');
        for (DMT_TeamMember__c member : members) {
            Assert.areEqual(DMT_TeamMember_Service.READ_ACCESS, member.AccessLevel__c, 'Without sanctionEdit the access is Read');
            Assert.areEqual(false, member.DMT_ApprovalEdit__c, 'Without sanctionEdit no approval edit grant is opened');
        }
    }

    @IsTest
    static void addApproversForCases_queryCountDoesNotDependOnNumberOfCases() {
        Case first = DMT_Test_DataFactory.generateCaseOppLine(line().Id, opportunity().Id, queue().Id);
        Case second = DMT_Test_DataFactory.generateCaseOppLine(line().Id, opportunity().Id, queue().Id);
        Case third = DMT_Test_DataFactory.generateCaseOppLine(line().Id, opportunity().Id, queue().Id);

        Test.startTest();
        Integer before = Limits.getQueries();
        DMT_TeamMember_Service.addApproversForCases(new List<DMT_TeamMember_Service.CaseRequest>{
            new DMT_TeamMember_Service.CaseRequest(first.Id, false)
        });
        Integer queriesForOneCase = Limits.getQueries() - before;

        before = Limits.getQueries();
        DMT_TeamMember_Service.addApproversForCases(new List<DMT_TeamMember_Service.CaseRequest>{
            new DMT_TeamMember_Service.CaseRequest(first.Id, false),
            new DMT_TeamMember_Service.CaseRequest(second.Id, false),
            new DMT_TeamMember_Service.CaseRequest(third.Id, false)
        });
        Integer queriesForThreeCases = Limits.getQueries() - before;
        Test.stopTest();

        Assert.areEqual(queriesForOneCase, queriesForThreeCases, 'The SOQL cost is the same for one Case and for three Cases');
        Assert.areEqual(2, membersOf(approverUser().Id, line().Id, opportunity().Id).size(), 'Participants are not duplicated by the extra Cases');
    }

    @IsTest
    static void addApproversForCases_sanctionEditOpensEditGrantForBusinessApproverOnOpportunity() {
        Case approvalCase = DMT_Test_DataFactory.generateCaseOppLine(line().Id, opportunity().Id, queue().Id);

        Test.startTest();
        DMT_TeamMember_Service.addApproversForCases(new List<DMT_TeamMember_Service.CaseRequest>{
            new DMT_TeamMember_Service.CaseRequest(approvalCase.Id, false)
        });
        DMT_TeamMember_Service.addApproversForCases(new List<DMT_TeamMember_Service.CaseRequest>{
            new DMT_TeamMember_Service.CaseRequest(approvalCase.Id, true)
        });
        Test.stopTest();

        DMT_TeamMember__c opportunityMember = [
            SELECT AccessLevel__c, DMT_ApprovalEdit__c
            FROM DMT_TeamMember__c
            WHERE User__c = :approverUser().Id AND Opportunity__c = :opportunity().Id
            LIMIT 1
        ];
        Assert.areEqual(DMT_TeamMember_Service.EDIT_ACCESS, opportunityMember.AccessLevel__c, 'Business approver gets Edit on the Opportunity');
        Assert.areEqual(true, opportunityMember.DMT_ApprovalEdit__c, 'The approval edit grant is opened');

        DMT_TeamMember__c lineMember = [
            SELECT AccessLevel__c, DMT_ApprovalEdit__c
            FROM DMT_TeamMember__c
            WHERE User__c = :approverUser().Id AND Line__c = :line().Id
            LIMIT 1
        ];
        Assert.areEqual(DMT_TeamMember_Service.READ_ACCESS, lineMember.AccessLevel__c, 'Business approver stays Read on the Line');
    }

    @IsTest
    static void syncApprovalEditAccess_withdrawsTheGrantsOfAClosedStep() {
        List<User> users = [SELECT Id FROM User WHERE LastName LIKE 'Dmt4374User%' ORDER BY LastName];
        Id lineId = line().Id;
        Id opportunityId = opportunity().Id;

        DMT_TeamMember__c lineMember = DMT_Test_DataFactory.generateTeamMembers(
            new List<Id>{ users[1].Id }, lineId, null,
            new Map<Schema.SObjectField, Object>{
                DMT_TeamMember__c.AccessLevel__c => DMT_TeamMember_Service.EDIT_ACCESS,
                DMT_TeamMember__c.DMT_ApprovalEdit__c => true
            }
        )[0];
        DMT_TeamMember__c opportunityApprover = DMT_Test_DataFactory.generateTeamMembers(
            new List<Id>{ users[0].Id }, null, opportunityId,
            new Map<Schema.SObjectField, Object>{
                DMT_TeamMember__c.AccessLevel__c => DMT_TeamMember_Service.EDIT_ACCESS,
                DMT_TeamMember__c.Team_Role__c => DMT_TeamMember_Service.ROLE_APPROVER,
                DMT_TeamMember__c.DMT_ApprovalEdit__c => true
            }
        )[0];

        Test.startTest();
        DMT_TeamMember_Service.syncApprovalEditAccess(new Set<Id>{ lineId }, new Set<Id>{ opportunityId });
        Test.stopTest();

        Assert.areEqual(DMT_TeamMember_Service.READ_ACCESS, [SELECT AccessLevel__c FROM DMT_TeamMember__c WHERE Id = :lineMember.Id].AccessLevel__c,
            'Line participant with approval edit goes back to Read');
        Assert.areEqual(DMT_TeamMember_Service.READ_ACCESS, [SELECT AccessLevel__c FROM DMT_TeamMember__c WHERE Id = :opportunityApprover.Id].AccessLevel__c,
            'Opportunity approver with approval edit goes back to Read');
    }

    @IsTest
    static void scheduleCaseRequests_handsTheWorkToTheOrchestratorOutsideAsyncContext() {
        DMT_AsyncOrchestrator.payloadBuffer.clear();
        Id someCaseId = DMT_Test_DataFactory.generateCaseOppLine(line().Id, opportunity().Id, queue().Id).Id;
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        DMT_TeamMember_Service.scheduleCaseRequests(new List<DMT_TeamMember_Service.CaseRequest>{
            new DMT_TeamMember_Service.CaseRequest(someCaseId, false),
            new DMT_TeamMember_Service.CaseRequest(someCaseId, true)
        });

        Assert.areEqual(2, DMT_AsyncOrchestrator.payloadBuffer.size(), 'One payload per sanctionEdit value, not one per Case');
        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer[0] instanceof DMT_TeamMemberCasePayload, 'Payload type');
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

    @IsTest
    static void dispatcher_runsTheTeamMemberPayload() {
        Case approvalCase = DMT_Test_DataFactory.generateCaseOppLine(line().Id, opportunity().Id, queue().Id);

        Test.startTest();
        DMT_AsyncDispatcher.dispatch(new DMT_TeamMemberCasePayload(new List<Id>{ approvalCase.Id }, false));
        Test.stopTest();

        Assert.areEqual(2, membersOf(approverUser().Id, line().Id, opportunity().Id).size(), 'The payload creates the Line and Opportunity participants');
    }

    @IsTest
    static void builders_setTheOwnerContextAndDefaults() {
        User user = approverUser();
        DMT_TeamMember__c onLine = DMT_TeamMember_Service.buildLineMember(
            user.Id, line().Id, 'Name', DMT_TeamMember_Service.READ_ACCESS, DMT_TeamMember_Service.ROLE_APPROVER, true
        );
        DMT_TeamMember__c onOpportunity = DMT_TeamMember_Service.buildOpportunityMember(
            user.Id, opportunity().Id, null, DMT_TeamMember_Service.EDIT_ACCESS, null, null
        );

        Assert.areEqual(line().Id, onLine.Line__c, 'Line');
        Assert.isNull(onLine.Opportunity__c, 'A Line member has no Opportunity');
        Assert.areEqual(true, onLine.DMT_ApprovalEdit__c, 'Approval edit');
        Assert.areEqual(opportunity().Id, onOpportunity.Opportunity__c, 'Opportunity');
        Assert.isNull(onOpportunity.Line__c, 'An Opportunity member has no Line');
    }

    @IsTest
    static void calloutMarker_isOnThePayloadsThatCanMakeACallout() {
        DMT_AsyncPayload startPayload = new DMT_StartApprovalCasePayload('EXT', 'APPROVER', 'TASK', '[]', 'FEATURE', 'Feature', '', 'approval');
        DMT_AsyncPayload checkPayload = new DMT_CalloutTrackableCheckPayload(opportunity().Id, null, 'Client', new List<String>());
        Assert.isTrue(startPayload instanceof DMT_CalloutPayload, 'A request that can create the Sanction Line makes a callout, so it runs alone in its transaction');
        Assert.isTrue(checkPayload instanceof DMT_CalloutPayload, 'The callout tracked comparison makes a callout too');
        Assert.isFalse(new DMT_TeamMemberCasePayload(new List<Id>(), false) instanceof DMT_CalloutPayload, 'Team member work makes no callout');
    }
}
