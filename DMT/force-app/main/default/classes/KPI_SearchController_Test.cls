/**
------------------------------------------------------------------------------------------------
@Name     KPI_SearchController_Test
@Author   Global Hub
@Date     Created: 2023-09-11
------------------------------------------------------------------------------------------------
@Description Test class for KPI_SearchController_Test
------------------------------------------------------------------------------------------------
@Changes
| 2023-09-11 ivan.garces.contractor@bbva.com
            Class Creation
-----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods, PMD.ExcessiveParameterList, sf:NPathComplexity, PMD.ApexCRUDViolation, PMD.NcssTypeCount, PMD.EmptyStatementBlock, PMD.NcssMethodCount, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.ApexSOQLInjection, PMD.FormalParameterNamingConventions, PMD.ExcessiveClassLength , PMD.ExcessivePublicCount, PMD.AvoidGlobalModifier, PMD.UnusedLocalVariable, PMD.ApexAssertionsShouldIncludeMessage, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
@isTest
public with sharing class KPI_SearchController_Test {
    /**
    @description
    @author Global Hub | 2023-09-11
    */
    @testSetup
    static void setupTestData() {
        List<Account> accToinsert = new List<Account>();
        final Account acc = new Account();
        acc.Name = 'TestParentAcc';
        acc.DES_Group_Code__c = 'Test';
        acc.DES_Structure_Type__c = 'Group';
        insert acc;

        final Account acc2 = new Account();
        acc2.Name = 'TestParentAcc1';
        acc2.DES_Group_Code__c = 'Test1';
        acc2.DES_Structure_Type__c = 'Subsidiary';
        insert acc2;

        final cstk__Toolkit__c tool = new cstk__Toolkit__c();
        tool.cstk__toolkit_unique_id__c = 'test';
        tool.cstk__account_id__c = acc.Id;

        insert tool;
    }

    /**
    @description
    @author Global Hub | 2023-09-07
    */
    @isTest
    static void getKPICatalogTest() {
        Test.startTest();
        final Map<String, Object> kpiCatalogue = KPI_searchController.getKPICatalog('INDUSTRY_GROUP', new List<String>{ 'ESGKPI01' });
        system.assert((boolean) kpiCatalogue.get('success'), 'Not the same name');
        Test.stopTest();
    }

    /**
    @description
    @author Global Hub | 2024-02-07
    */
    @isTest
    static void getClientsTest() {
        final cstk__Toolkit__c tool = [SELECT Id FROM cstk__Toolkit__c LIMIT 1];
        Test.startTest();
        final KPI_FinantialCustomers_Wrapper kpiwrapper = KPI_searchController.getClients(new List<String>{ 'business' }, new List<String>{ 'sector' }, new List<String>{ 'country' }, new List<String>{ 'catalog' }, new List<String>{ 'cliente' }, new List<String>{ 'product' }, new List<String>{ 'group' }, tool.Id);
        system.assert((boolean) kpiwrapper.success, 'Not the same name');
        Test.stopTest();
    }

    /**
    @description
    @author Global Hub | 2024-03-07
    */
    @isTest
    static void getUserGMBATest() {
        User mytestUser = createUser('TestUserGM', 'System Administrator');
        PermissionSet permisionSetGM = [SELECT Id FROM PermissionSet WHERE Name = 'KPI_Business_Area_GM'];
        PermissionSetAssignment permAssigmentTestUser = new PermissionSetAssignment(PermissionSetId = permisionSetGM.Id, AssigneeId = mytestUser.Id);
        insert permAssigmentTestUser;
        System.runAs(mytestUser) {
            Test.startTest();
            final String result = KPI_searchController.getUserBAPermissionSet();
            system.assertEquals('GLOBAL MARKETS', result, 'Not the same name');
            Test.stopTest();
        }
    }
    /**
    @description
    @author Global Hub | 2024-03-07
    */
    @isTest
    static void getUserGTBBATest() {
        User mytestUser = createUser('TestUserGTB', 'System Administrator');
        PermissionSet permisionSetGM = [SELECT Id FROM PermissionSet WHERE Name = 'KPI_Business_Area_GTB'];
        PermissionSetAssignment permAssigmentTestUser = new PermissionSetAssignment(PermissionSetId = permisionSetGM.Id, AssigneeId = mytestUser.Id);
        insert permAssigmentTestUser;
        System.runAs(mytestUser) {
            Test.startTest();
            final String result = KPI_searchController.getUserBAPermissionSet();
            system.assertEquals('GLOBAL TRANSACTIONAL BANKING', result, 'Not the same name');
            Test.stopTest();
        }
    }

    /**
    @description
    @author Global Hub | 2024-03-07
    */
    @isTest
    static void getUserNOBATest() {
        User mytestUser = createUser('TestUserNOBA', 'System Administrator');
        System.runAs(mytestUser) {
            Test.startTest();
            final String result = KPI_searchController.getUserBAPermissionSet();
            system.assertEquals('NoBAPermissionSet', result, 'Not the same name');
            Test.stopTest();
        }
    }

    /** Copiado de la clase 'TestFactory' */
    private static User createUser(String userName, String Perfil) {
        User u = new User();
        Double random = Math.random();
        u.Username = userName + 'u2@u.com.u' + random;
        u.LastName = userName + 'uLast2';
        u.Email = userName + 'u2@u.com';
        u.Alias = String.valueOf(random).substring(0, 3) + 'uAas2';
        u.TimeZoneSidKey = 'America/Mexico_City';
        u.IsActive = true;
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        List<Profile> prof = new List<Profile>([SELECT Id, Name FROM Profile WHERE Name = :Perfil]);
        u.ProfileId = prof[0].Id;
        u.LanguageLocaleKey = 'es';
        u.ID_User__c = 'Test' + userName.substring(0, 3) + String.valueOf(random).substring(0, 3);
        insert u;
        return u;
    }
}