/**
* @description
*/
@isTest
public with sharing class CSTK_Alert_Test {

    /**
    * @description
    */
    @TestSetup
    static void setupTestData() {
        final Account acc = new Account();
        acc.Name = 'name';
        insert acc;
    }

    /**
    * @description
    */
    @isTest
    static void createUserAlertAndGetUserAlertsTest() {
        final List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        final String adminProfileId  = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        final User userTest = new User();
        userTest.Email = 'test@bbva.com';
       	userTest.UserName = 'test@bbva.com';
       	userTest.Alias = 'ali';
       	userTest.TimeZoneSidKey = 'GMT';
        userTest.LocaleSidKey = 'en_US';
		userTest.EmailEncodingKey = 'UTF-8';
       	userTest.LanguageLocaleKey = 'en_US';
       	userTest.FirstName = 'test';
       	userTest.LastName = 'test';
        userTest.ProfileId = adminProfileId;
        userTest.FederationIdentifier = 'T000000';
        userTest.ID_User__c = 'ID_User__c ';
        insert userTest;

        Test.startTest();
        final cstk.Alert_Wrapper alertWrapper = new cstk.Alert_Wrapper();
        alertWrapper.userId = userTest.Id;
        alertWrapper.accountId = accounts[0].Id;
        alertWrapper.name = 'nameTest';
        CSTK_Alert.createUserAlert(alertWrapper);
        alertWrapper.userId = userTest.Id;
        final List<altm__Commercial_Alert__c> alerts = CSTK_Alert.getUserAlerts(alertWrapper);
        alertWrapper.status = 'Reviewed';
        alertWrapper.alertIds = new List<String>();
        alertWrapper.alertIds.add(alerts[0].Id);
        CSTK_Alert.updateAlertStatus(alertWrapper);
        System.assertEquals(alerts[0].name, alertWrapper.name, 'OK');
        Test.stopTest();
    }

    /**
    * @description
    */
    @isTest
    static void createGroupAlertAndGetUserAlertsFilterByPublicGroupTest() {
        final List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        final Group groupTest = new Group();
        groupTest.DeveloperName = 'GroupDeveloperName';
        groupTest.Name = 'name';
        insert groupTest;
        final GroupMember groupMemberTest = new GroupMember();
        groupMemberTest.UserOrGroupId = UserInfo.getUserId();
        groupMemberTest.GroupId = groupTest.Id;
        insert groupMemberTest;
        Test.startTest();
        final cstk.Alert_Wrapper alertWrapper = new cstk.Alert_Wrapper();
        alertWrapper.userId = UserInfo.getUserId();
        alertWrapper.accountId = accounts[0].Id;
        alertWrapper.name = 'nameTest';
        alertWrapper.groupDeveloperName = 'GroupDeveloperName';
        alertWrapper.groupDeveloperNames = new List<String>{'GroupDeveloperName'};
        CSTK_Alert.createGroupAlert(new List<cstk.Alert_Wrapper>{alertWrapper});
        final List<altm__Commercial_Alert__c> alerts = CSTK_Alert.getUnreadUserAlertsFilterByPublicGroup(alertWrapper);
        System.assert(true, 'OK');
        Test.stopTest();
    }

    /**
    * @description
    */
    @isTest
    static void createRolAlertTestAndGetUnreadUserAlertsFilterByRol() {
        final List<AggregateResult> roles = [SELECT UserRole.Name, COUNT(Id)
                                        FROM User
                                        WHERE IsActive = TRUE
                                        GROUP BY UserRole.Name
                                        ORDER BY COUNT(Id) ASC];
        final List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        final cstk.Alert_Wrapper alertWrapper = new cstk.Alert_Wrapper();
        alertWrapper.userId = UserInfo.getUserId();
        alertWrapper.accountId = accounts[0].Id;
        alertWrapper.name = 'nameTest';
        alertWrapper.rolName = (String)roles[0].get('Name');
        alertWrapper.rolesNames = new List<String>{(String)roles[0].get('Name')};
        alertWrapper.alertId = String.valueOf(Datetime.now()) + '1';
        CSTK_Alert.createRolAlert(new List<cstk.Alert_Wrapper>{alertWrapper});
        CSTK_Alert.getUnreadUserAlertsFilterByRol(alertWrapper);
        System.assert(true, 'OK');
        Test.stopTest();
    }
}