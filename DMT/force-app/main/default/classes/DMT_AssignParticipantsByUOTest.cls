@IsTest
private class DMT_AssignParticipantsByUOTest {

    private static final String SHARED_UO = 'UO4269001';
    private static final String OTHER_UO = 'UO4269002';

    @TestSetup
    static void setupUsers() {
        Id profileId = [
            SELECT Id
            FROM Profile
            WHERE Name = 'BBVA Standard User'
            LIMIT 1
        ].Id;

        insert new List<User>{
            buildUser(profileId, 'uoowner', SHARED_UO),
            buildUser(profileId, 'uopeer', SHARED_UO),
            buildUser(profileId, 'uoother', OTHER_UO),
            buildUser(profileId, 'uoblank', null)
        };
    }

    @IsTest
    static void assignsParticipantsForLineAndOpportunity() {
        Map<String, User> usersByAlias = getUsersByAlias();

        User owner = usersByAlias.get('uoowner');
        User peer = usersByAlias.get('uopeer');
        User other = usersByAlias.get('uoother');

        DMT_Line__c lineRecord = new DMT_Line__c(
            Name = 'CIBGLOBALD-4269 Test Line',
            OwnerId = owner.Id
        );
        insert lineRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = 'CIBGLOBALD-4269 Test Opportunity',
            StageName = getActiveOpportunityStage(),
            CloseDate = Date.today().addDays(30),
            OwnerId = owner.Id
        );
        insert opportunityRecord;

        DMT_AssignParticipantsByUO.Request lineRequest =
            buildRequest(lineRecord.Id);

        DMT_AssignParticipantsByUO.Request opportunityRequest =
            buildRequest(opportunityRecord.Id);

        Test.startTest();

        DMT_AssignParticipantsByUO.assignParticipants(
            new List<DMT_AssignParticipantsByUO.Request>{
                lineRequest,
                opportunityRequest
            }
        );

        Test.stopTest();

        List<DMT_TeamMember__c> lineParticipants = [
            SELECT Id, User__c, AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :lineRecord.Id
        ];

        List<DMT_TeamMember__c> opportunityParticipants = [
            SELECT Id, User__c, AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE Opportunity__c = :opportunityRecord.Id
        ];

        System.assertEquals(
            1,
            lineParticipants.size(),
            'The Line must have one participant from the Owner UO.'
        );

        System.assertEquals(
            peer.Id,
            lineParticipants[0].User__c,
            'The Line participant must belong to the Owner UO.'
        );

        System.assertEquals(
            'Edit',
            lineParticipants[0].AccessLevel__c,
            'The Line participant must have Read/Write access.'
        );

        System.assertEquals(
            1,
            opportunityParticipants.size(),
            'The Opportunity must have one participant from the Owner UO.'
        );

        System.assertEquals(
            peer.Id,
            opportunityParticipants[0].User__c,
            'The Opportunity participant must belong to the Owner UO.'
        );

        System.assertEquals(
            'Edit',
            opportunityParticipants[0].AccessLevel__c,
            'The Opportunity participant must have Read/Write access.'
        );

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM DMT_TeamMember__c
                WHERE (
                    Line__c = :lineRecord.Id
                    OR Opportunity__c = :opportunityRecord.Id
                )
                AND User__c IN :new Set<Id>{ owner.Id, other.Id }
            ],
            'The Owner and users from other UOs must not be added.'
        );

        DMT_Line__Share lineShare = [
            SELECT AccessLevel
            FROM DMT_Line__Share
            WHERE ParentId = :lineRecord.Id
            AND UserOrGroupId = :peer.Id
            LIMIT 1
        ];

        OpportunityShare opportunityShare = [
            SELECT OpportunityAccessLevel
            FROM OpportunityShare
            WHERE OpportunityId = :opportunityRecord.Id
            AND UserOrGroupId = :peer.Id
            LIMIT 1
        ];

        System.assertEquals(
            'Edit',
            lineShare.AccessLevel,
            'The Line share must have Edit access.'
        );

        System.assertEquals(
            'Edit',
            opportunityShare.OpportunityAccessLevel,
            'The Opportunity share must have Edit access.'
        );
    }

    @IsTest
    static void avoidsDuplicatesAndUpgradesReadAccess() {
        Map<String, User> usersByAlias = getUsersByAlias();

        User owner = usersByAlias.get('uoowner');
        User peer = usersByAlias.get('uopeer');

        DMT_Line__c lineRecord = new DMT_Line__c(
            Name = 'CIBGLOBALD-4269 Existing Participant',
            OwnerId = owner.Id
        );
        insert lineRecord;

        // The record-triggered Flow may have already created the participant.
        List<DMT_TeamMember__c> autoCreated = [
            SELECT Id, AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :lineRecord.Id
            AND User__c = :peer.Id
        ];

        DMT_TeamMember__c existingParticipant;

        if (autoCreated.isEmpty()) {
            existingParticipant = new DMT_TeamMember__c(
                Line__c = lineRecord.Id,
                User__c = peer.Id,
                AccessLevel__c = 'Read'
            );
            insert existingParticipant;
        } else {
            existingParticipant = autoCreated[0];
            existingParticipant.AccessLevel__c = 'Read';
            update existingParticipant;
        }

        DMT_AssignParticipantsByUO.Request request =
            buildRequest(lineRecord.Id);

        Test.startTest();

        DMT_AssignParticipantsByUO.assignParticipants(
            new List<DMT_AssignParticipantsByUO.Request>{ request }
        );

        // A second execution must not create a duplicate.
        DMT_AssignParticipantsByUO.assignParticipants(
            new List<DMT_AssignParticipantsByUO.Request>{ request }
        );

        Test.stopTest();

        List<DMT_TeamMember__c> participants = [
            SELECT Id, AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :lineRecord.Id
            AND User__c = :peer.Id
        ];

        System.assertEquals(
            1,
            participants.size(),
            'The existing participant must not be duplicated.'
        );

        System.assertEquals(
            existingParticipant.Id,
            participants[0].Id,
            'The existing participant record must be preserved.'
        );

        System.assertEquals(
            'Edit',
            participants[0].AccessLevel__c,
            'Read access must be upgraded to Read/Write.'
        );

        DMT_Line__Share lineShare = [
            SELECT AccessLevel
            FROM DMT_Line__Share
            WHERE ParentId = :lineRecord.Id
            AND UserOrGroupId = :peer.Id
            LIMIT 1
        ];

        System.assertEquals(
            'Edit',
            lineShare.AccessLevel,
            'The existing share must also be upgraded.'
        );
    }

    @IsTest
    static void doesNothingWhenOwnerHasNoUo() {
        User ownerWithoutUo = getUsersByAlias().get('uoblank');

        DMT_Line__c lineRecord = new DMT_Line__c(
            Name = 'CIBGLOBALD-4269 Owner Without UO',
            OwnerId = ownerWithoutUo.Id
        );
        insert lineRecord;

        Test.startTest();

        DMT_AssignParticipantsByUO.assignParticipants(
            new List<DMT_AssignParticipantsByUO.Request>{
                buildRequest(lineRecord.Id)
            }
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM DMT_TeamMember__c
                WHERE Line__c = :lineRecord.Id
            ],
            'No participants must be created when the Owner UO is empty.'
        );
    }

    private static User buildUser(
        Id profileId,
        String alias,
        String uo
    ) {
        String uniqueValue =
            alias + String.valueOf(DateTime.now().getTime());

        return new User(
            ProfileId = profileId,
            FirstName = 'Test',
            LastName = alias,
            Alias = alias,
            Email = uniqueValue + '@test.com',
            Username = uniqueValue + '@test.com',
            CommunityNickname = uniqueValue,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ID_User__c = uniqueValue,
            DES_LevelUO_10__c = uo
        );
    }

    private static Map<String, User> getUsersByAlias() {
        Map<String, User> usersByAlias = new Map<String, User>();

        for (User userRecord : [
            SELECT Id, Alias, DES_LevelUO_10__c
            FROM User
            WHERE Alias IN (
                'uoowner',
                'uopeer',
                'uoother',
                'uoblank'
            )
        ]) {
            usersByAlias.put(userRecord.Alias, userRecord);
        }

        return usersByAlias;
    }

    private static String getActiveOpportunityStage() {
        for (
            Schema.PicklistEntry entry :
            Opportunity.StageName
                .getDescribe()
                .getPicklistValues()
        ) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }

        return null;
    }

    private static DMT_AssignParticipantsByUO.Request buildRequest(
        Id recordId
    ) {
        DMT_AssignParticipantsByUO.Request request =
            new DMT_AssignParticipantsByUO.Request();

        request.recordId = recordId;
        return request;
    }
}