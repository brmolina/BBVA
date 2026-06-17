@IsTest
private class CGUR_ClientTest {

    private static final String TEST_USER_ALIAS = 'cgurc';
    private static final String TEST_USER_LAST_NAME = 'ClientTest';
    private static final String TEST_ADMIN_USER_ALIAS = 'cgura';
    private static final String TEST_ADMIN_USER_LAST_NAME = 'ClientAdminTest';
    private static final String TEST_GROUP_CODE = 'GROUP_TEST_001';
    private static final String TEST_CLIENT_CODE = 'CLIENT_TEST_001';
    private static final String TEST_CLIENT_CODE_2 = 'CLIENT_TEST_002';

    @testSetup
    static void setupData() {

        Id rtCounterparty = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Standard_Account' LIMIT 1].Id;
        Id rtSubsidiary = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'DES_Subsidiary_Commercial_Client' LIMIT 1].Id;
        Id rtGroup = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Group' LIMIT 1].Id;

        User currentUser = [
            SELECT Id, ProfileId, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        String uniqueKey = String.valueOf(DateTime.now().getTime()).right(6);
        User usr = new User(
            Alias = TEST_USER_ALIAS,
            Email = 'cgur.client.test+' + uniqueKey + '@example.com',
            EmailEncodingKey = currentUser.EmailEncodingKey,
            ID_User__c = 'U' + uniqueKey,
            LastName = TEST_USER_LAST_NAME,
            LanguageLocaleKey = currentUser.LanguageLocaleKey,
            LocaleSidKey = currentUser.LocaleSidKey,
            ProfileId = currentUser.ProfileId,
            TimeZoneSidKey = currentUser.TimeZoneSidKey,
            Username = 'cgur.client.test+' + uniqueKey + '@example.com',
            DES_Country__c = 'ESP',
            DES_LevelUO_10__c = '1234567',
            DES_LevelUO_9__c = '1234567',
            DES_LevelUO_8__c = '7654321',
            DES_LevelUO_5__c = '11111111',
            DES_LevelUO_4__c = '00006349'
        );
        User adminUsr = new User(
            Alias = TEST_ADMIN_USER_ALIAS,
            Email = 'cgur.client.admin.test+' + uniqueKey + '@example.com',
            EmailEncodingKey = currentUser.EmailEncodingKey,
            ID_User__c = 'A' + uniqueKey,
            LastName = TEST_ADMIN_USER_LAST_NAME,
            LanguageLocaleKey = currentUser.LanguageLocaleKey,
            LocaleSidKey = currentUser.LocaleSidKey,
            ProfileId = currentUser.ProfileId,
            TimeZoneSidKey = currentUser.TimeZoneSidKey,
            Username = 'cgur.client.admin.test+' + uniqueKey + '@example.com',
            DES_Country__c = 'ESP'
        );
        User subordinateUsr = new User(
            Alias = 'cgurs',
            Email = 'cgur.client.subordinate.test+' + uniqueKey + '@example.com',
            EmailEncodingKey = currentUser.EmailEncodingKey,
            ID_User__c = 'S' + uniqueKey,
            LastName = 'ClientSubordinateTest',
            LanguageLocaleKey = currentUser.LanguageLocaleKey,
            LocaleSidKey = currentUser.LocaleSidKey,
            ProfileId = currentUser.ProfileId,
            TimeZoneSidKey = currentUser.TimeZoneSidKey,
            Username = 'cgur.client.subordinate.test+' + uniqueKey + '@example.com',
            DES_Country__c = 'ESP',
            DES_LevelUO_10__c = '7654321',
            DES_LevelUO_9__c = '1234567',
            DES_LevelUO_8__c = '7654321',
            DES_LevelUO_5__c = '22222222',
            DES_LevelUO_4__c = '00006349'
        );
        insert new List<User>{ usr, adminUsr, subordinateUsr };

        PermissionSet adminPermissionSet = [
            SELECT Id
            FROM PermissionSet
            WHERE NamespacePrefix = 'cgur'
            AND Name = 'clientguruadmin'
            LIMIT 1
        ];
        System.runAs(currentUser) {
            insert new PermissionSetAssignment(
                AssigneeId = adminUsr.Id,
                PermissionSetId = adminPermissionSet.Id
            );
        }

        Id userId = usr.Id;

        String groupCode = TEST_GROUP_CODE;
        String clientCode = TEST_CLIENT_CODE;
        String clientCode2 = TEST_CLIENT_CODE_2;
        String clientStarId = '123456789-BBVASA';
        String clientStarId2 = '987654321-BBVASA';

        Account groupAcc = new Account(
            Name = 'GROUP 1',
            DES_Structure_Type__c = 'Group',
            gf_prtcpt_act_status_ind_type__c = true,
            DES_Group_Code__c = groupCode,
            RecordTypeId = rtGroup
        );
        insert groupAcc;

        Account clientAcc = new Account(
            Name = 'CLIENT 1',
            g_customer_id__c = clientCode,
            DES_Main_Parent__c = groupAcc.Id,
            DES_Structure_Type__c = 'Subsidiary',
            gf_prtcpt_act_status_ind_type__c = true,
            RecordTypeId = rtSubsidiary
        );
        Account clientAcc2 = new Account(
            Name = 'CLIENT 2',
            g_customer_id__c = clientCode2,
            DES_Main_Parent__c = groupAcc.Id,
            DES_Structure_Type__c = 'Subsidiary',
            gf_prtcpt_act_status_ind_type__c = true,
            RecordTypeId = rtSubsidiary
        );
        insert new List<Account>{ clientAcc, clientAcc2 };

        Account counterpartyAcc = new Account(
            Name = 'Counterparty 1',
            gf_prtcpt_act_status_ind_type__c = true,
            Client_STAR_ID__c = clientStarId,
            DES_Main_Parent__c = clientAcc.Id,
            RecordTypeId = rtCounterparty
        );
        Account counterpartyAcc2 = new Account(
            Name = 'Counterparty 2',
            gf_prtcpt_act_status_ind_type__c = true,
            Client_STAR_ID__c = clientStarId2,
            DES_Main_Parent__c = clientAcc2.Id,
            RecordTypeId = rtCounterparty
        );
        insert new List<Account>{ counterpartyAcc, counterpartyAcc2 };

        DES_BBVA_Management_team__c team = new DES_BBVA_Management_team__c(
            DES_User__c = userId,
            DES_Client__c = clientAcc.Id,
            participant_role_id__c = 'RCREDF'
        );
        DES_BBVA_Management_team__c team2 = new DES_BBVA_Management_team__c(
            DES_User__c = subordinateUsr.Id,
            DES_Client__c = clientAcc2.Id,
            participant_role_id__c = 'RCREDF'
        );
        DES_BBVA_Management_team__c adminTeam = new DES_BBVA_Management_team__c(
            DES_User__c = adminUsr.Id,
            DES_Client__c = clientAcc2.Id,
            participant_role_id__c = 'RCREDF'
        );
        insert new List<DES_BBVA_Management_team__c>{ team, team2, adminTeam };
    }

    @IsTest
    static void testGetManagedClients() {
        User usr = [SELECT Id FROM User WHERE Alias = :TEST_USER_ALIAS AND LastName = :TEST_USER_LAST_NAME LIMIT 1];
        cgur.Client.Wrapper wrapper;

        CGUR_Client.clientGuruAdminPermissionOverride = false;
        try {
            Test.startTest();
            System.runAs(usr) {
                wrapper = (new CGUR_Client()).getManagedClients(usr.Id);
            }
            Test.stopTest();
        } finally {
            CGUR_Client.clientGuruAdminPermissionOverride = null;
        }

        System.assertEquals(true, wrapper.clients.contains(TEST_CLIENT_CODE_2), 'Should include the second managed client');
    }

    @IsTest
    static void testGetManagedGroupClients() {
        User usr = [SELECT Id FROM User WHERE Alias = :TEST_USER_ALIAS AND LastName = :TEST_USER_LAST_NAME LIMIT 1];
        String groupCode = [SELECT DES_Group_Code__c FROM Account WHERE DES_Group_Code__c = :TEST_GROUP_CODE LIMIT 1].DES_Group_Code__c;
        cgur.Client.Wrapper wrapper;

        CGUR_Client.clientGuruAdminPermissionOverride = false;
        try {
            Test.startTest();
            System.runAs(usr) {
                wrapper = (new CGUR_Client()).getManagedGroupClients(usr.Id, groupCode);
            }
            Test.stopTest();
        } finally {
            CGUR_Client.clientGuruAdminPermissionOverride = null;
        }

        System.assertEquals(true, wrapper.clients.contains(TEST_CLIENT_CODE), 'Should include the group-matched managed client');
    }

    @IsTest
    static void testGetAllGroups() {
        User usr = [SELECT Id FROM User WHERE Alias = :TEST_USER_ALIAS AND LastName = :TEST_USER_LAST_NAME LIMIT 1];
        cgur.Client.Wrapper wrapper;

        Test.startTest();
        System.runAs(usr) {
            wrapper = (new CGUR_Client()).getAllGroups(usr.Id, null);
        }
        Test.stopTest();

        System.assertEquals(1, wrapper.groups.size(), 'The setup should expose exactly one group');
    }

    @IsTest
    static void testGetAllGroupsWithAdminPermission() {
        User usr = [SELECT Id FROM User WHERE Alias = :TEST_ADMIN_USER_ALIAS AND LastName = :TEST_ADMIN_USER_LAST_NAME LIMIT 1];
        cgur.Client.Wrapper wrapper;

        Test.startTest();
        System.runAs(usr) {
            wrapper = (new CGUR_Client()).getAllGroups(usr.Id);
        }
        Test.stopTest();

        System.assertEquals(TEST_GROUP_CODE, wrapper.groups[0].id, 'Admin path should return the configured group');
    }

    @IsTest
    static void testGetManagedGroupClientsWithAdminPermission() {
        User usr = [SELECT Id FROM User WHERE Alias = :TEST_ADMIN_USER_ALIAS AND LastName = :TEST_ADMIN_USER_LAST_NAME LIMIT 1];
        cgur.Client.Wrapper wrapper;

        Test.startTest();
        System.runAs(usr) {
            wrapper = (new CGUR_Client()).getManagedGroupClients(usr.Id, null);
        }
        Test.stopTest();

        System.assertEquals(true, wrapper.clients.contains(TEST_CLIENT_CODE_2), 'Admin path should include clients managed under the configured top UO');
    }

    @IsTest
    static void getGroupFromClient() {
        String clientId = [SELECT Id FROM Account WHERE g_customer_id__c = :TEST_CLIENT_CODE LIMIT 1].Id;
        Test.startTest();
        String res = (new CGUR_Client()).getGroup(clientId);
        Test.stopTest();
        System.assertEquals(TEST_GROUP_CODE, res, 'Group code should match the setup group');
    }

    @IsTest
    static void getGroupFromGroup() {
        String groupId = [SELECT Id FROM Account WHERE DES_Group_Code__c = :TEST_GROUP_CODE LIMIT 1].Id;
        Test.startTest();
        String res = (new CGUR_Client()).getGroup(groupId);
        Test.stopTest();
        System.assertEquals(TEST_GROUP_CODE, res, 'Group code should match the setup group');
    }


}