@isTest
public with sharing class DMT_CreateTeamMemberApprover_Test {
    @TestSetup
    static void setup() {
        // Se hace retrieve de la cola
        Group caseOwner = [SELECT DeveloperName, Name FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1];

        // Se crea un grupo de approver
        DMT_Approver__c approver = DMT_Test_DataFactory.generateApprover();
        approver.DMT_Group__c = caseOwner.DeveloperName;
        update approver;

        // Se crea un usuario de prueba
        Profile profileUser = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            LastName = 'testuser1',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Email = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            ProfileId = profileUser.Id,
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'TestDMT_CreateTMA'
        );
        insert testUser;

        List<DMT_Approver_Member__c> approverMembersToInsert = new List<DMT_Approver_Member__c>();

        // Se crea un approver member del approver
        DMT_Approver_Member__c approverMember = new DMT_Approver_Member__c();
        approverMember.DMT_Access_Level__c = 'Edit';
        approverMember.DMT_Approver__c = approver.Id;
        approverMember.DMT_User__c = testUser.Id;
        approverMembersToInsert.add(approverMember);

        // We create another approver Member
        DMT_Approver_Member__c approverMember2 = new DMT_Approver_Member__c();
        approverMember2.DMT_Access_Level__c = 'Edit';
        approverMember2.DMT_Approver__c = approver.Id;
        approverMember2.DMT_User__c = UserInfo.getUserId();
        approverMembersToInsert.add(approverMember2);

        insert approverMembersToInsert;

        // Se crea una línea
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];

        // Se crea un participante para asociarlo a la línea
        DMT_TeamMember__c teamMember = new DMT_TeamMember__c();
        teamMember.User__c = UserInfo.getUserId();
        teamMember.Line__c = line.Id;
        teamMember.AccessLevel__c = 'Edit';
        teamMember.Team_Role__c = 'coverage team';
        insert teamMember;
        // Se crea el caso con la cola como owner y se asocia a la línea
        Case caseRecord = DMT_Test_DataFactory.generateCase(line.Id, null, caseOwner.Id);
    }

    @isTest
    private static void createTeamMemberApproverTest() {
        Group approverGroup = [SELECT DeveloperName, Name FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1];

        DMT_TeamMember__c teamMember = [SELECT Id, User__c FROM DMT_TeamMember__c WHERE User__c != :UserInfo.getUserId() LIMIT 1];
        delete teamMember;

        DMT_CreateTeamMemberApprover.InputWrapper inputWrapper = new DMT_CreateTeamMemberApprover.InputWrapper();

        inputWrapper.listCreatedApproverMembers = [SELECT Id, DMT_User__c, DMT_User__r.Name FROM DMT_Approver_Member__c WHERE DMT_User__c != :UserInfo.getUserId()];
        inputWrapper.groupId = approverGroup.Id;
        inputWrapper.oldApproverMembers = [SELECT Id, DMT_User__c, DMT_User__r.Name FROM DMT_Approver_Member__c WHERE DMT_User__c = :UserInfo.getUserId()];


        List<DMT_CreateTeamMemberApprover.InputWrapper> inputList = new List<DMT_CreateTeamMemberApprover.InputWrapper>();
        inputList.add(inputWrapper);

        Test.startTest();
        DMT_CreateTeamMemberApprover.invokeCreateTeamMember(inputList);
        Test.stopTest();
        System.assertNotEquals(null, inputList, 'Input list is not null');
    }

    @isTest
    private static void createTeamMemberApproverExceptionTest() {
        Group approverGroup = [SELECT DeveloperName, Name FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1];

        DMT_CreateTeamMemberApprover.InputWrapper inputWrapper = new DMT_CreateTeamMemberApprover.InputWrapper();

        DMT_TeamMember__c teamMember = [SELECT Id, User__c FROM DMT_TeamMember__c WHERE User__c != :UserInfo.getUserId() LIMIT 1];
        delete teamMember;

        // We remove DMT_User__r.Name field from the query to force the exception
        inputWrapper.listCreatedApproverMembers = [SELECT Id, DMT_User__c FROM DMT_Approver_Member__c WHERE DMT_User__c != :UserInfo.getUserId()];
        inputWrapper.groupId = approverGroup.Id;
        inputWrapper.oldApproverMembers = [SELECT Id, DMT_User__c FROM DMT_Approver_Member__c WHERE DMT_User__c = :UserInfo.getUserId()];


        List<DMT_CreateTeamMemberApprover.InputWrapper> inputList = new List<DMT_CreateTeamMemberApprover.InputWrapper>();
        inputList.add(inputWrapper);

        String errorMessage = '';

        Test.startTest();
        try {
            DMT_CreateTeamMemberApprover.invokeCreateTeamMember(inputList);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();
        System.assertNotEquals(null, errorMessage, 'Error Message is not null');
    }
}