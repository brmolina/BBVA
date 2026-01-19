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

        // Realizar la llamada al método con un término de búsqueda que coincida
        Test.startTest();
        List<Map<String, String>> results = DMT_LineController.searchRecords(objectApiName, recordTypeApiName, searchTerm);
        Test.stopTest();

        // Validar los resultados
        Assert.isNotNull(results, 'The results should not be null');
        Assert.isTrue(results.size() > 0, 'There should be at least one result');
    }

    @isTest
    static void testSearchOpportunities() {

        String objectApiName = 'Opportunity';
        String recordTypeApiName = 'DMT_Opportunity';
        String searchTerm = '00';

        // Realizar la llamada al método con un término de búsqueda que coincida
        Test.startTest();
        List<Map<String, String>> results = DMT_LineController.searchRecords(objectApiName, recordTypeApiName, searchTerm);
        Test.stopTest();

        // Validar los resultados
        Assert.isNotNull(results, 'The results should not be null');
        Assert.isTrue(results.size() > 0, 'There should be at least one result');
    }

    @isTest
    static void testSearchLinesEmptySearchTerm() {

        String objectApiName = 'DMT_Line__c';
        String recordTypeApiName = 'TreasurySettlement';
        String searchTerm = '';

        // Realizar la llamada al método con un término de búsqueda que coincida
        Test.startTest();
        try{
            List<Map<String, String>> results = DMT_LineController.searchRecords(objectApiName, recordTypeApiName, searchTerm);
        } catch (AuraHandledException e) {
            // Validar que se lanza la excepción esperada
            Assert.isTrue(true, 'An exception should have been thrown for an empty search term');
            System.debug('Exception caught as expected: ' + e.getMessage());
            return; // Salir del test si se lanza la excepción
        }
        Test.stopTest();

        Assert.isTrue(false, 'An exception should have been thrown for an empty search term');
    }

    @isTest
    static void testNoMatchingSearchLines() {

        String objectApiName = 'DMT_Line__c';
        String recordTypeApiName = 'TreasurySettlement';
        String searchTerm = 'nonExistentTerm';

        // Realizar la llamada al método con un término de búsqueda que coincida
        Test.startTest();
        List<Map<String, String>> results = DMT_LineController.searchRecords(objectApiName, recordTypeApiName, searchTerm);
        Test.stopTest();

        // Validar que no hay resultados
        Assert.areEqual(0, results.size(), 'There should be no results for a non-matching search term');
    }

    @isTest
    static void testUnsupportedObjectApiName() {

        String objectApiName = 'Account';
        String recordTypeApiName = 'TreasurySettlement';
        String searchTerm = '00';

        // Realizar la llamada al método con un término de búsqueda que coincida
        Test.startTest();
        try{
            List<Map<String, String>> results = DMT_LineController.searchRecords(objectApiName, recordTypeApiName, searchTerm);
        } catch (AuraHandledException e) {
            // Validar que se lanza la excepción esperada
            Assert.isTrue(true, 'An exception should have been thrown for unsupported object API name');
            System.debug('Exception caught as expected: ' + e.getMessage());
            return; // Salir del test si se lanza la excepción
        }
        Test.stopTest();

        Assert.isTrue(false, 'An exception should have been thrown for unsupported object API name');
    }

    @isTest
    static void testCheckEditPermissionAsAdmin() {
        // Create a mock user with System Administrator profile
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            FirstName = 'Admin',
            LastName = 'User',
            Email = 'admin@example.com',
            Username = 'admin' + System.currentTimeMillis() + '@example.com', // Ensure unique username
            Alias = 'admin',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            DMT_User_Role__c = 'DMT_Proyecto',
            LanguageLocaleKey = 'en_US',
            ID_User__c ='iduserTest'+Integer.valueof((Math.random() * 100000000))
        );
        insert adminUser;
        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'Different-1');
        insert line;
        DMT_TeamMember__c teamMember = new DMT_TeamMember__c(
            Line__c = line.Id,
            User__c = adminUser.Id,
            AccessLevel__c = 'Edit'
        );
        insert teamMember;

        System.runAs(adminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermission(line.Id);
            System.debug('Result: ' + result);
            Test.stopTest();

            Assert.areEqual(true, result.get('isAdmin'), 'The user should be identified as an admin');
            Assert.areEqual(true, result.get('accessLevel_edit'), 'accessLevel_edit should be null for admin users');
        }
    }

    @isTest
    static void testCheckEditPermissionNoTeamMember() {
        // Create a mock user with a non-admin profile
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1];
        User nonAdminUser = new User(
            FirstName = 'NonAdmin',
            LastName = 'User',
            Email = 'nonadmin@example.com',
            Username = 'nonadmin' + System.currentTimeMillis() + '@example.com',
            Alias = 'nonadm',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'a¡¿_O00&4244'
        );
        insert nonAdminUser;

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'Different-1');
        insert line;

        DMT_TeamMember__c teamMember = new DMT_TeamMember__c(
            Line__c = line.Id,
            User__c = nonAdminUser.Id,
            AccessLevel__c = 'Read'
        );
        insert teamMember;

        System.runAs(nonAdminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermission(line.Id);
            Test.stopTest();

            Assert.areEqual(false, result.get('isAdmin'), 'The user should not be identified as an admin');
            Assert.areEqual(false, result.get('accessLevel_edit'), 'accessLevel_edit should be false when no team member record exists');
        }
    }

    @isTest
    static void testCheckEditPermissionWithApprovalEditTrue() {
        // Create a mock user and related team member record
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1];
        User nonAdminUser = new User(
            FirstName = 'NonAdmin',
            LastName = 'User',
            Email = 'nonadmin2@example.com',
            Username = 'nonadmin2' + System.currentTimeMillis() + '@example.com', // Ensure unique username
            Alias = 'nonadm2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            DMT_User_Role__c = 'DMT_Proyecto',
            LanguageLocaleKey = 'en_US',
            ID_User__c ='iduserTest'+Integer.valueof((Math.random() * 100000000))
        );
        insert nonAdminUser;

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'Different-1');
        insert line;
        DMT_TeamMember__c teamMember = new DMT_TeamMember__c(
            Line__c = line.Id,
            User__c = nonAdminUser.Id,
            AccessLevel__c = 'Edit'
        );
        insert teamMember;

        System.runAs(nonAdminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermission(line.Id);
            Test.stopTest();

            Assert.areEqual(false, result.get('isAdmin'), 'The user should not be identified as an admin');
            Assert.areEqual(true, result.get('accessLevel_edit'), 'accessLevel_edit should be true when the team member record has it set to true');
        }
    }

    @isTest
    static void testCheckEditPermissionWithApprovalEditFalse() {
        // Create a mock user and related team member record
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1];
        User nonAdminUser = new User(
            FirstName = 'NonAdmin',
            LastName = 'User',
            Email = 'nonadmin3@example.com',
            Username = 'nonadmin3' + System.currentTimeMillis() + '@example.com', // Ensure unique username
            Alias = 'nonadm3',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            LanguageLocaleKey = 'en_US',
            ID_User__c ='iduserTest'+Integer.valueof((Math.random() * 100000000))
        );
        insert nonAdminUser;

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'Different-1');
        insert line;
        DMT_TeamMember__c teamMember = new DMT_TeamMember__c(
            Line__c = line.Id,
            User__c = nonAdminUser.Id,
            AccessLevel__c = 'Read'
        );
        insert teamMember;

        System.runAs(nonAdminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermission(line.Id);
            Test.stopTest();

            Assert.areEqual(false, result.get('isAdmin'), 'The user should not be identified as an admin');
            Assert.areEqual(false, result.get('accessLevel_edit'), 'accessLevel_edit should be false when the team member record has it set to false');
        }
    }

    @isTest
    static void testCheckEditPermissionOppAsAdmin() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User adminUser = new User(
            FirstName = 'AdminOpp',
            LastName = 'User',
            Email = 'adminOpp@example.com',
            Username = 'adminOpp' + System.currentTimeMillis() + '@example.com',
            Alias = 'admopp',
            TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'es_ES',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'a¡¿_O00&4241'
        );
        insert adminUser;

        RecordType oppRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'DMT_Opportunity' LIMIT 1];

        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Draft',
            CloseDate = Date.today().addDays(30),
            AccountId = acct.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND DeveloperName='DMT_Opportunity' LIMIT 1].Id
        );
        insert opp;
        System.runAs(adminUser) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermissionOpp(opp.Id);
            Test.stopTest();

            Assert.isTrue(result.get('isAdmin'), 'Admin should be flagged as admin');
            Assert.isTrue(result.get('accessLevel_edit'), 'Admin should always have edit access');
        }
    }

    @isTest
    static void testCheckEditPermissionOppTeamMemberEdit() {
        Profile p = [SELECT Id FROM Profile WHERE Name != 'System Administrator' LIMIT 1];

        User user = new User(
            FirstName = 'TeamEdit',
            LastName = 'Opp',
            Email = 'teamEditOpp@example.com',
            Username = 'teamEditOpp' + System.currentTimeMillis() + '@example.com',
            Alias = 'tmedopp',
            TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'es_ES',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'a¡¿_O00&4240'
        );
        insert user;

        RecordType oppRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'DMT_Opportunity' LIMIT 1];
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Draft',
            CloseDate = Date.today().addDays(30),
            AccountId = acct.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND DeveloperName='DMT_Opportunity' LIMIT 1].Id
        );
        insert opp;

        DMT_TeamMember__c tm = new DMT_TeamMember__c(
            Opportunity__c = opp.Id,
            User__c = user.Id,
            AccessLevel__c = 'Edit'
        );
        insert tm;

        System.runAs(user) {
            Test.startTest();
            Map<String, Boolean> result = DMT_LineController.checkEditPermissionOpp(opp.Id);
            Test.stopTest();

            Assert.isFalse(result.get('isAdmin'), 'User should not be admin');
            Assert.isTrue(result.get('accessLevel_edit'), 'Should allow edit because team member has Edit');
        }
    }


    @isTest
    static void testCheckEditPermissionOppTeamMemberRead() {
        Profile p = [SELECT Id FROM Profile WHERE Name != 'System Administrator' LIMIT 1];

        User user = new User(
            FirstName = 'TeamRead',
            LastName = 'Opp',
            Email = 'teamReadOpp@example.com',
            Username = 'teamReadOpp' + System.currentTimeMillis() + '@example.com',
            Alias = 'tmrdopp',
            TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'es_ES',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'a¡¿_O00&4249'
        );
        insert user;

        RecordType oppRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'DMT_Opportunity' LIMIT 1];

        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Draft',
            CloseDate = Date.today().addDays(30),
            AccountId = acct.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND DeveloperName='DMT_Opportunity' LIMIT 1].Id
        );
        insert opp;

        DMT_TeamMember__c tm = new DMT_TeamMember__c(
            Opportunity__c = opp.Id,
            User__c = user.Id,
            AccessLevel__c = 'Read'
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
}