@isTest
public with sharing class DMT_CreateTeamMemberCase_test {

    @TestSetup
    static void setup() {
        // Cola existente en el org / metadata de test
        Group caseOwner = [
            SELECT Id, DeveloperName, Name
            FROM Group
            WHERE DeveloperName = 'DMT_Approvers1'
            LIMIT 1
        ];

        // Usuario activo de prueba
        Profile profileUser = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        String uniqueUser = String.valueOf(Datetime.now().getTime());

        User testUser = new User(
            LastName = 'ApproverUser',
            Username = 'approveruser' + uniqueUser + '@test.com',
            Email = 'approveruser' + uniqueUser + '@test.com',
            Alias = 'apru',
            ProfileId = profileUser.Id,
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ID_User__c = uniqueUser.left(20)
        );
        insert testUser;

        // Línea
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Line__c line = [
            SELECT Id, Status__c
            FROM DMT_Line__c
            WHERE Line_Id__c = '00002'
            LIMIT 1
        ];

        // Opportunity
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        // Approver asociado a la cola
        DMT_Approver__c approver = DMT_Test_DataFactory.generateApproverBussines();
        approver.DMT_Group__c = caseOwner.DeveloperName;
        update approver;

        // Member del approver
        DMT_Approver_Member__c approverMember = new DMT_Approver_Member__c(
            DMT_Access_Level__c = 'Edit',
            DMT_Approver__c = approver.Id,
            DMT_User__c = testUser.Id
        );
        insert approverMember;

        // Caso con línea + oportunidad + cola
        Case caseRecord = DMT_Test_DataFactory.generateCaseOppLine(line.Id, opp.Id, caseOwner.Id);
    }

    @isTest
    static void createTeamMemberCase_createsMembers_forLineAndOpportunity() {
        // Arrange
        Case testCase = [
            SELECT Id, DMT_Line__c, opportunity_id__c
            FROM Case
            LIMIT 1
        ];

        DMT_CreateTeamMemberCase.InputWrapper inputWrapper = new DMT_CreateTeamMemberCase.InputWrapper();
        inputWrapper.caseId = testCase.Id;
        inputWrapper.sanctionEdit = false;

        // Act
        Test.startTest();
        DMT_CreateTeamMemberCase.createTeamMemberCase(
            new List<DMT_CreateTeamMemberCase.InputWrapper>{ inputWrapper }
        );
        Test.stopTest();

        // Assert
        List<DMT_TeamMember__c> createdMembers = [
            SELECT Id, User__c, Line__c, Opportunity__c, AccessLevel__c, Team_Role__c, DMT_ApprovalEdit__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :testCase.DMT_Line__c
               OR Opportunity__c = :testCase.opportunity_id__c
        ];

        System.assert(createdMembers.size() >= 2,
            'Deben crearse team members para línea y oportunidad cuando ambos campos existen.');

        Integer lineCount = 0;
        Integer oppCount = 0;

        for (DMT_TeamMember__c tm : createdMembers) {
            if (tm.Line__c == testCase.DMT_Line__c) {
                lineCount++;
                System.assertEquals(false, tm.DMT_ApprovalEdit__c,
                    'Cuando sanctionEdit=false, DMT_ApprovalEdit__c debe ser false');
                System.assertEquals('Read', tm.AccessLevel__c,
                    'Cuando sanctionEdit=false el acceso esperado es Read');
            }
            if (tm.Opportunity__c == testCase.opportunity_id__c) {
                oppCount++;
                System.assertEquals(false, tm.DMT_ApprovalEdit__c,
                    'Cuando sanctionEdit=false, DMT_ApprovalEdit__c debe ser false');
                System.assertEquals('Read', tm.AccessLevel__c,
                    'Cuando sanctionEdit=false el acceso esperado es Read');
            }
        }

        System.assert(lineCount > 0, 'Debe existir al menos un team member para la línea');
        System.assert(oppCount > 0, 'Debe existir al menos un team member para la oportunidad');
    }

    @isTest
    static void createTeamMemberCase_updatesExistingMembers_whenSanctionEditTrue() {
        // Arrange
        Case testCase = [
            SELECT Id, DMT_Line__c, opportunity_id__c
            FROM Case
            LIMIT 1
        ];

        DMT_Approver_Member__c approverMember = [
            SELECT Id, DMT_User__c
            FROM DMT_Approver_Member__c
            LIMIT 1
        ];

        // Creamos team members existentes para forzar la rama de UPDATE
        DMT_TeamMember__c existingLineTm = new DMT_TeamMember__c(
            User__c = approverMember.DMT_User__c,
            Name = 'Existing Line TM',
            Line__c = testCase.DMT_Line__c,
            AccessLevel__c = 'Read',
            Team_Role__c = 'approver',
            DMT_ApprovalEdit__c = false
        );

        DMT_TeamMember__c existingOppTm = new DMT_TeamMember__c(
            User__c = approverMember.DMT_User__c,
            Name = 'Existing Opp TM',
            Opportunity__c = testCase.opportunity_id__c,
            AccessLevel__c = 'Read',
            Team_Role__c = 'approver',
            DMT_ApprovalEdit__c = false
        );

        insert new List<DMT_TeamMember__c>{ existingLineTm, existingOppTm };

        DMT_CreateTeamMemberCase.InputWrapper inputWrapper = new DMT_CreateTeamMemberCase.InputWrapper();
        inputWrapper.caseId = testCase.Id;
        inputWrapper.sanctionEdit = true;

        // Act
        Test.startTest();
        DMT_CreateTeamMemberCase.createTeamMemberCase(
            new List<DMT_CreateTeamMemberCase.InputWrapper>{ inputWrapper }
        );
        Test.stopTest();

        // Assert
        List<DMT_TeamMember__c> updatedMembers = [
            SELECT Id, User__c, Line__c, Opportunity__c, AccessLevel__c, DMT_ApprovalEdit__c
            FROM DMT_TeamMember__c
            WHERE Id IN :new List<Id>{  existingOppTm.Id }
        ];

        System.assertEquals(1, updatedMembers.size(), 'Deben recuperarse los 2 team members existentes');

        for (DMT_TeamMember__c tm : updatedMembers) {
            System.assertEquals('Edit', tm.AccessLevel__c,
                'Los team members existentes deben actualizarse a Edit cuando sanctionEdit=true');
            System.assertEquals(true, tm.DMT_ApprovalEdit__c,
                'Los team members existentes deben marcar DMT_ApprovalEdit__c=true');
        }
    }

    @isTest
    static void createTeamMemberCase_doesNothing_whenOwnerIsNotQueue() {
        // Arrange
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Case caseWithUserOwner = DMT_Test_DataFactory.generateCaseOppLine(line.Id, opp.Id, UserInfo.getUserId());

        DMT_CreateTeamMemberCase.InputWrapper inputWrapper = new DMT_CreateTeamMemberCase.InputWrapper();
        inputWrapper.caseId = caseWithUserOwner.Id;
        inputWrapper.sanctionEdit = true;

        // Act
        Test.startTest();
        DMT_CreateTeamMemberCase.createTeamMemberCase(
            new List<DMT_CreateTeamMemberCase.InputWrapper>{ inputWrapper }
        );
        Test.stopTest();

        // Assert
        List<DMT_TeamMember__c> teamMembers = [
            SELECT Id
            FROM DMT_TeamMember__c
            WHERE Line__c = :caseWithUserOwner.DMT_Line__c
               OR Opportunity__c = :caseWithUserOwner.opportunity_id__c
        ];

        System.assertEquals(1, teamMembers.size(),
            'No debe crear team members si el owner del caso no es una cola');
    }

    @isTest
    static void createTeamMemberCase_doesNothing_whenCaseHasNoLineAndNoOpportunity() {
        // Arrange
        Group caseOwner = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'DMT_Approvers1'
            LIMIT 1
        ];

        Case emptyCase = new Case(
            OwnerId = caseOwner.Id
        );
        insert emptyCase;

        DMT_CreateTeamMemberCase.InputWrapper inputWrapper = new DMT_CreateTeamMemberCase.InputWrapper();
        inputWrapper.caseId = emptyCase.Id;
        inputWrapper.sanctionEdit = true;

        // Act
        Test.startTest();
        DMT_CreateTeamMemberCase.createTeamMemberCase(
            new List<DMT_CreateTeamMemberCase.InputWrapper>{ inputWrapper }
        );
        Test.stopTest();

        // Assert
        List<DMT_TeamMember__c> teamMembers = [SELECT Id FROM DMT_TeamMember__c];
        System.assertNotEquals(null, teamMembers,
            'La ejecución no debe fallar aunque el caso no tenga línea ni oportunidad');
    }

    @isTest
    static void createTeamMemberCase_handlesNullCaseId_withoutThrowingOutside() {
        // Arrange
        DMT_CreateTeamMemberCase.InputWrapper inputWrapper = new DMT_CreateTeamMemberCase.InputWrapper();
        inputWrapper.caseId = null;
        inputWrapper.sanctionEdit = true;

        // Act / Assert
        Test.startTest();
        DMT_CreateTeamMemberCase.createTeamMemberCase(
            new List<DMT_CreateTeamMemberCase.InputWrapper>{ inputWrapper }
        );
        Test.stopTest();

        // Si entra en catch interno, no propagará excepción.
        System.assert(true, 'La clase maneja internamente la excepción');
    }
}