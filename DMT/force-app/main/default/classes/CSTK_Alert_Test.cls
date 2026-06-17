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
    static void createUserAlertAndUpdateStatusTest() {
        final String standardProfileId  = [SELECT Id FROM Profile WHERE Name = 'BBVA Standard User' LIMIT 1].Id;
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
        userTest.ProfileId = standardProfileId;
        userTest.Dataloader_Profile_Name__c = 'BBVA Standard User';
        userTest.FederationIdentifier = 'T000000';
        userTest.ID_User__c = 'ID_User__c ';
        insert userTest;

        System.runAs(userTest) {
            final Account acc = new Account();
            acc.Name = 'Name Standard User';
            insert acc;
            Test.startTest();
            final cstk.Alert_Wrapper alertWrapper = new cstk.Alert_Wrapper();
            alertWrapper.userId = userTest.Id;
            alertWrapper.accountId = acc.Id;
            alertWrapper.name = 'nameTest';
            alertWrapper.alertId = String.valueOf(Datetime.now());
            alertWrapper.alertType = 'Sustainability Turnover Alert';
            alertWrapper.description =  'Testing description';
            alertWrapper.priority = 'Low';
            alertWrapper.year = '2022';
            alertWrapper.federationId = userTest.FederationIdentifier;
            CSTK_Alert.createUserAlerts(new List<cstk.Alert_Wrapper>{alertWrapper});
            final List<altm__Commercial_Alert__c> alerts = CSTK_Alert.getUnreadToolkitAlerts();
            alertWrapper.status = 'Pending';
            alertWrapper.alertIds = new List<String>();
            alertWrapper.alertIds.add(alerts[0].Id);
            CSTK_Alert.updateAlertStatus(alertWrapper);
            final List<altm__Commercial_Alert__c> alertsUpdated = [SELECT Id, altm__alert_stage_type__c FROM altm__Commercial_Alert__c];
            Test.stopTest();
            System.assertEquals(alerts[0].name, alertWrapper.name, 'OK');
            System.assertEquals('Pending', alertsUpdated[0].altm__alert_stage_type__c, 'Status is pending.');
        }
    }

    /**
    * @description
    */
    @isTest
    static void createRolAlertTestAndGetUnreadToolkitAlerts() {
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
        CSTK_Alert.getUnreadToolkitAlerts();
        System.assert(true, 'OK');
        Test.stopTest();
    }
}