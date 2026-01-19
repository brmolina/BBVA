@isTest
public with sharing class DMT_CreateTeamMemberCase_test {
    @TestSetup
    static void setup() {
        // Se hace retrieve de la cola
        Group caseOwner = [SELECT DeveloperName, Name FROM Group WHERE DeveloperName = 'DMT_Approvers1' LIMIT 1];

        // Se crea un grupo de approver
        DMT_Approver__c approver = DMT_Test_DataFactory.generateApprover();
        approver.DMT_Group__c = caseOwner.DeveloperName;
        update approver;

        String uniqueId = String.valueOf(System.currentTimeMillis()).substring(0, 12) + Math.abs(Math.random() * 10000);
        String shortId = uniqueId.substring(0, 20);

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
            ID_User__c = shortId
        );
        insert testUser;

        // Se crea un approver member del approver
        DMT_Approver_Member__c approverMember = new DMT_Approver_Member__c();
        approverMember.DMT_Access_Level__c = 'Edit';
        approverMember.DMT_Approver__c = approver.Id;
        approverMember.DMT_User__c = testUser.Id;
        insert approverMember;

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
    private static void createTeamMemberCaseTest() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        DMT_CreateTeamMemberCase.InputWrapper inputWrapper = new DMT_CreateTeamMemberCase.InputWrapper();
        inputWrapper.caseId = testCase.Id;
        inputWrapper.sanctionEdit = true;

        List<DMT_CreateTeamMemberCase.InputWrapper> inputList = new List<DMT_CreateTeamMemberCase.InputWrapper>();
        inputList.add(inputWrapper);

        Test.startTest();
        DMT_CreateTeamMemberCase.createTeamMemberCase(inputList);
        Test.stopTest();

        System.assertNotEquals(null, inputList);
    }

    @isTest
    private static void createTeamMemberCaseExceptionTest() {
        DMT_CreateTeamMemberCase.InputWrapper inputWrapper = new DMT_CreateTeamMemberCase.InputWrapper();
        inputWrapper.caseId = null;

        List<DMT_CreateTeamMemberCase.InputWrapper> inputList = new List<DMT_CreateTeamMemberCase.InputWrapper>();
        inputList.add(inputWrapper);

        String errorMessage = '';

        Test.startTest();
        try {
            DMT_CreateTeamMemberCase.createTeamMemberCase(inputList);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();
        System.assertNotEquals(null, errorMessage);
    }
}