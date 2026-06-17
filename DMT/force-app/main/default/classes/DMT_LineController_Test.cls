@isTest
public class DMT_LineController_Test {

    @testSetup
    static void makeData(){
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Test_DataFactory.generateOpportunity();
    }

    @isTest
    static void testSearchTreasuryLines() {
        String objectApiName = 'DMT_Line__c';
        String recordTypeApiName = 'TreasurySettlement';
        String searchTerm = '00';
        Test.startTest();
        List<Map<String, String>> results = DMT_LineController.searchRecords(objectApiName, recordTypeApiName, searchTerm);
        Test.stopTest();
        Assert.isNotNull(results, 'The results should not be null');
        Assert.isTrue(results.size() > 0, 'There should be at least one result');
    }

    @isTest
    static void testSearchOpportunities() {
        String objectApiName = 'Opportunity';
        String recordTypeApiName = 'DMT_Opportunity';
        String searchTerm = '00';
        Test.startTest();
        List<Map<String, String>> results = DMT_LineController.searchRecords(objectApiName, recordTypeApiName, searchTerm);
        Test.stopTest();
        Assert.isNotNull(results, 'The results should not be null');
        Assert.isTrue(results.size() > 0, 'There should be at least one result');
    }

    @isTest
    static void testSearchLinesEmptySearchTerm() {
        String objectApiName = 'DMT_Line__c';
        String recordTypeApiName = 'TreasurySettlement';
        String searchTerm = '';
        Test.startTest();
        try {
            List<Map<String, String>> results = DMT_LineController.searchRecords(objectApiName, recordTypeApiName, searchTerm);
        } catch (AuraHandledException e) {
            Assert.isTrue(true, 'An exception should have been thrown for an empty search term');
            return;
        }
        Test.stopTest();
        Assert.isTrue(false, 'An exception should have been thrown for an empty search term');
    }

    @isTest
    static void testNoMatchingSearchLines() {
        String objectApiName = 'DMT_Line__c';
        String recordTypeApiName = 'TreasurySettlement';
        String searchTerm = 'nonExistentTerm';
        Test.startTest();
        List<Map<String, String>> results = DMT_LineController.searchRecords(objectApiName, recordTypeApiName, searchTerm);
        Test.stopTest();
        Assert.areEqual(0, results.size(), 'There should be no results for a non-matching search term');
    }

    @isTest
    static void testUnsupportedObjectApiName() {
        String objectApiName = 'Account';
        String recordTypeApiName = 'TreasurySettlement';
        String searchTerm = '00';
        Test.startTest();
        try {
            List<Map<String, String>> results = DMT_LineController.searchRecords(objectApiName, recordTypeApiName, searchTerm);
        } catch (AuraHandledException e) {
            Assert.isTrue(true, 'An exception should have been thrown for unsupported object API name');
            return;
        }
        Test.stopTest();
        Assert.isTrue(false, 'An exception should have been thrown for unsupported object API name');
    }

    @isTest
    static void testSearchRecords_OneCharTerm() {
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_LineController.searchRecords('DMT_Line__c', 'TreasurySettlement', 'X');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        Assert.isTrue(threw, 'Should throw for 1-char search term');
    }

    @isTest
    static void testCheckEditPermissionAsAdmin() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            FirstName = 'Admin', LastName = 'User',
            Email = 'admin@example.com',
            Username = 'admin' + System.currentTimeMillis() + '@example.com',
            Alias = 'admin', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            DMT_User_Role__c = 'DMT_Proyecto',
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'iduserTest' + Integer.valueof((Math.random() * 100000000))
        );
        insert adminUser;

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'Different-1');
        insert line;

        DMT_TeamMember__c teamMember = new DMT_TeamMember__c(
            Line__c = line.Id, User__c = adminUser.Id, AccessLevel__c = 'Edit'
        );
        insert teamMember;

        System.runAs(adminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermission(line.Id);
            Test.stopTest();
            Assert.areEqual(true, result.get('isAdmin'), 'The user should be identified as an admin');
            Assert.areEqual(true, result.get('accessLevel_edit'), 'accessLevel_edit should be true for admin users');
        }
    }

    @isTest
    static void testCheckEditPermissionNoTeamMember() {
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1];
        User nonAdminUser = new User(
            FirstName = 'NonAdmin', LastName = 'User',
            Email = 'nonadmin@example.com',
            Username = 'nonadmin' + System.currentTimeMillis() + '@example.com',
            Alias = 'nonadm', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'a¡¿_O00&4244',
            DMT_User_Role__c = 'DMT_Soporte funcional'
        );
        insert nonAdminUser;

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'Different-1');
        insert line;

        DMT_TeamMember__c teamMember = new DMT_TeamMember__c(
            Line__c = line.Id, User__c = nonAdminUser.Id, AccessLevel__c = 'Read'
        );
        insert teamMember;

        System.runAs(nonAdminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermission(line.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('isAdmin'), 'The user should not be identified as an admin');
            Assert.areEqual(false, result.get('accessLevel_edit'), 'accessLevel_edit should be false');
        }
    }

    @isTest
    static void testCheckEditPermissionWithApprovalEditTrue() {
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1];
        User nonAdminUser = new User(
            FirstName = 'NonAdmin', LastName = 'User',
            Email = 'nonadmin2@example.com',
            Username = 'nonadmin2' + System.currentTimeMillis() + '@example.com',
            Alias = 'nonadm2', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            DMT_User_Role__c = 'DMT_Proyecto',
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'iduserTest' + Integer.valueof((Math.random() * 100000000))
        );
        insert nonAdminUser;

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'Different-1');
        insert line;

        DMT_TeamMember__c teamMember = new DMT_TeamMember__c(
            Line__c = line.Id, User__c = nonAdminUser.Id, AccessLevel__c = 'Edit'
        );
        insert teamMember;

        System.runAs(nonAdminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermission(line.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('isAdmin'), 'The user should not be identified as an admin');
            Assert.areEqual(true, result.get('accessLevel_edit'), 'accessLevel_edit should be true');
        }
    }

    @isTest
    static void testCheckEditPermissionWithApprovalEditFalse() {
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1];
        User nonAdminUser = new User(
            FirstName = 'NonAdmin', LastName = 'User',
            Email = 'nonadmin3@example.com',
            Username = 'nonadmin3' + System.currentTimeMillis() + '@example.com',
            Alias = 'nonadm3', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'iduserTest' + Integer.valueof((Math.random() * 100000000)),
            DMT_User_Role__c = 'DMT_Soporte funcional'
        );
        insert nonAdminUser;

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'Different-1');
        insert line;

        DMT_TeamMember__c teamMember = new DMT_TeamMember__c(
            Line__c = line.Id, User__c = nonAdminUser.Id, AccessLevel__c = 'Read'
        );
        insert teamMember;

        System.runAs(nonAdminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermission(line.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('isAdmin'), 'The user should not be identified as an admin');
            Assert.areEqual(false, result.get('accessLevel_edit'), 'accessLevel_edit should be false');
        }
    }

    @isTest
    static void testCheckEditPermission_OwnerAccess() {
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1];
        User ownerUser = new User(
            FirstName = 'Owner', LastName = 'LineUser',
            Email = 'ownerline@example.com',
            Username = 'ownerline' + System.currentTimeMillis() + '@example.com',
            Alias = 'ownln', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            LanguageLocaleKey = 'en_US',
            DMT_User_Role__c = 'DMT_Proyecto',
            ID_User__c = 'iduserOwn' + Integer.valueof((Math.random() * 100000000))
        );
        insert ownerUser;

        DMT_Line__c line;
        System.runAs(ownerUser) {
            line = new DMT_Line__c(Line_Id__c = 'Owner-Line-1');
            insert line;
        }

        System.runAs(ownerUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermission(line.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('isAdmin'), 'Owner should not be admin');
            Assert.areEqual(true, result.get('accessLevel_edit'), 'Owner of the line should have edit access');
        }
    }

    @isTest
    static void testCheckEditPermission_NoWriteAccessRole() {
        // Usamos el helper del datafactory que crea un user Read Only
        User readOnlyUser = DMT_Test_DataFactory.generateUserWithoutPermissions();

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'NoWrite-Line-1');
        insert line;

        System.runAs(readOnlyUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermission(line.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('accessLevel_edit'),
                'User without write access should not have edit access');
        }
    }

    @isTest
    static void testCheckEditPermissionOppTeamMemberEdit() {
        Profile p = [SELECT Id FROM Profile WHERE Name != 'System Administrator' LIMIT 1];
        User user = new User(
            FirstName = 'TeamEdit', LastName = 'Opp',
            Email = 'teamEditOpp@example.com',
            Username = 'teamEditOpp' + System.currentTimeMillis() + '@example.com',
            Alias = 'tmedopp', TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'es_ES', EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id, LanguageLocaleKey = 'en_US',
            ID_User__c = 'a¡¿_O00&4240'
        );
        insert user;

        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity', StageName = 'Draft',
            CloseDate = Date.today().addDays(30), AccountId = acct.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND DeveloperName='DMT_Opportunity' LIMIT 1].Id
        );
        insert opp;

        DMT_TeamMember__c tm = new DMT_TeamMember__c(
            Opportunity__c = opp.Id, User__c = user.Id, AccessLevel__c = 'Edit'
        );
        insert tm;

        System.runAs(user) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermissionOpp(opp.Id);
            Test.stopTest();
            Assert.isFalse(result.get('isAdmin'), 'User should not be admin');
            Assert.isTrue(result.get('accessLevel_read'), 'Should allow read because team member has access');
        }
    }

    @isTest
    static void testCheckEditPermissionOppTeamMemberRead() {
        Profile p = [SELECT Id FROM Profile WHERE Name != 'System Administrator' LIMIT 1];
        User user = new User(
            FirstName = 'TeamRead', LastName = 'Opp',
            Email = 'teamReadOpp@example.com',
            Username = 'teamReadOpp' + System.currentTimeMillis() + '@example.com',
            Alias = 'tmrdopp', TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'es_ES', EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id, LanguageLocaleKey = 'en_US',
            ID_User__c = 'a¡¿_O00&4249'
        );
        insert user;

        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity', StageName = 'Draft',
            CloseDate = Date.today().addDays(30), AccountId = acct.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND DeveloperName='DMT_Opportunity' LIMIT 1].Id
        );
        insert opp;

        DMT_TeamMember__c tm = new DMT_TeamMember__c(
            Opportunity__c = opp.Id, User__c = user.Id, AccessLevel__c = 'Read'
        );
        insert tm;

        System.runAs(user) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermissionOpp(opp.Id);
            Test.stopTest();
            Assert.isFalse(result.get('isAdmin'), 'User should not be admin');
            Assert.isFalse(result.get('accessLevel_edit'), 'Read access should not allow editing');
        }
    }


    @isTest
    static void testCheckEditPermissionOpp_Admin() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            FirstName = 'AdminOpp', LastName = 'User',
            Email = 'adminopp@example.com',
            Username = 'adminopp' + System.currentTimeMillis() + '@example.com',
            Alias = 'admopp', TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'es_ES', EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'en_US',
            DMT_User_Role__c = 'DMT_Proyecto',
            ID_User__c = 'iduserAdmOpp' + Integer.valueof((Math.random() * 100000000))
        );
        insert adminUser;

        Account acct = new Account(Name = 'Admin Opp Account');
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'Admin Opp Test', StageName = 'Draft',
            CloseDate = Date.today().addDays(30), AccountId = acct.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND DeveloperName='DMT_Opportunity' LIMIT 1].Id
        );
        insert opp;

        System.runAs(adminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermissionOpp(opp.Id);
            Test.stopTest();
            Assert.isTrue(result.get('isAdmin'), 'Admin should be identified as admin');
            Assert.isTrue(result.get('accessLevel_read'), 'Admin should have read access');
        }
    }



    @isTest
    static void testCheckReadPermissionWithTeamMemberReadTrue() {
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1];
        User nonAdminUser = new User(
            FirstName = 'NonAdminRead', LastName = 'User',
            Email = 'nonadminread@example.com',
            Username = 'nonadminread' + System.currentTimeMillis() + '@example.com',
            Alias = 'nadrd', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'iduserRead' + Integer.valueOf((Math.random() * 100000000)),
            DMT_User_Role__c = 'DMT_Soporte funcional'
        );
        insert nonAdminUser;

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'Different-Read-1');
        insert line;

        DMT_TeamMember__c teamMember = new DMT_TeamMember__c(
            Line__c = line.Id, User__c = nonAdminUser.Id, AccessLevel__c = 'Read'
        );
        insert teamMember;

        System.runAs(nonAdminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkReadPermission(line.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('isAdmin'), 'The user should not be identified as an admin');
            Assert.areEqual(true, result.get('accessLevel_read'), 'accessLevel_read should be true');
        }
    }

    @isTest
    static void testCheckReadPermission_Admin() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            FirstName = 'AdminRead', LastName = 'User',
            Email = 'adminread@example.com',
            Username = 'adminread' + System.currentTimeMillis() + '@example.com',
            Alias = 'admrd', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id, LanguageLocaleKey = 'en_US',
            DMT_User_Role__c = 'DMT_Proyecto',
            ID_User__c = 'iduserAdmR' + Integer.valueof((Math.random() * 100000000))
        );
        insert adminUser;

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'AdminRead-Line-1');
        insert line;

        System.runAs(adminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkReadPermission(line.Id);
            Test.stopTest();
            Assert.areEqual(true, result.get('isAdmin'), 'Should be admin');
            Assert.areEqual(true, result.get('accessLevel_read'), 'Admin should have read access');
        }
    }

    @isTest
    static void testCheckReadPermission_OwnerAccess() {
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1];
        User ownerUser = new User(
            FirstName = 'OwnerRead', LastName = 'User',
            Email = 'ownerread@example.com',
            Username = 'ownerread' + System.currentTimeMillis() + '@example.com',
            Alias = 'ownrd', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            LanguageLocaleKey = 'en_US',
            DMT_User_Role__c = 'DMT_Proyecto',
            ID_User__c = 'iduserOwnR' + Integer.valueof((Math.random() * 100000000))
        );
        insert ownerUser;

        DMT_Line__c line;
        System.runAs(ownerUser) {
            line = new DMT_Line__c(Line_Id__c = 'OwnerRead-Line-1');
            insert line;
        }

        System.runAs(ownerUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkReadPermission(line.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('isAdmin'), 'Owner should not be admin');
            Assert.areEqual(true, result.get('accessLevel_read'), 'Owner of the line should have read access');
        }
    }

    @isTest
    static void testCheckReadPermission_TeamMemberWithoutReadRole() {
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1];
        User user = new User(
            FirstName = 'TeamNoRole', LastName = 'User',
            Email = 'teamnorole@example.com',
            Username = 'teamnorole' + System.currentTimeMillis() + '@example.com',
            Alias = 'tnrol', TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            LanguageLocaleKey = 'en_US',
            // Sin DMT_Read Only en el rol — para que entre por el else con team member
            DMT_User_Role__c = 'DMT_Proyecto',
            ID_User__c = 'iduserTNR' + Integer.valueof((Math.random() * 100000000))
        );
        insert user;

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'TeamNoRole-Line-1');
        insert line;

        DMT_TeamMember__c tm = new DMT_TeamMember__c(
            Line__c = line.Id, User__c = user.Id, AccessLevel__c = 'Edit'
        );
        insert tm;

        System.runAs(user) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkReadPermission(line.Id);
            Test.stopTest();
            Assert.areEqual(false, result.get('isAdmin'));
            Assert.areEqual(true, result.get('accessLevel_read'),
                'Team member with Edit access should have read');
        }
    }

}