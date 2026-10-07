@IsTest
private class DMT_LaunchDealManagementServiceTest {

    @TestSetup
    static void setupData() {
        DMT_Test_DataFactory.generateAccount();

        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>{
            DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT', 'https://service.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket', 'https://validation.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint', 'https://group-position.ok', 'ServicesPartition', false)
        };
        insert settingsToInsert;
    }

    @IsTest
    static void launchDealManagement_returnsExpectedContract() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test company 1' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Map<String, Object> response = DMT_LaunchDealManagementService.launchDealManagement(
            acc.Id,
            'Lines',
            'Lines',
            null,
            null,
            null,
            false
        );
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        Assert.isTrue(response.containsKey('returnedDate'), 'Response must contain returnedDate');
        Assert.isTrue(response.containsKey('groupCode'), 'Response must contain groupCode');
        Assert.isTrue(response.containsKey('OppAccess'), 'Response must contain OppAccess');
        Assert.isTrue(response.containsKey('hasWriteAccessUser'), 'Response must contain hasWriteAccessUser');
        Assert.isTrue(response.containsKey('hasLineGodAccess'), 'Response must contain hasLineGodAccess');
        Assert.isTrue(response.containsKey('UserInfo'), 'Response must contain UserInfo');
    }

    @IsTest
    static void resolveGroupAccountId_returnsGroupAndExcludesSubsidiary() {
        Account existingAccount = [
            SELECT Id, DES_Group_Code__c
            FROM Account
            WHERE Name = 'Test company 1'
            LIMIT 1
        ];
        existingAccount.DES_Structure_Type__c = 'Subsidiary';
        update existingAccount;

        Account groupAccount = new Account(
            Name = 'Selected parent group',
            DES_Group_Code__c = existingAccount.DES_Group_Code__c,
            DES_Structure_Type__c = 'Group'
        );
        insert groupAccount;

        Test.startTest();
        Id result = DMT_LaunchDealManagementService.resolveGroupAccountId(
            existingAccount.DES_Group_Code__c
        );
        Test.stopTest();

        Assert.areEqual(groupAccount.Id, result, 'The selected group Account must be resolved');
        Assert.areNotEqual(existingAccount.Id, result, 'A subsidiary sharing the group code must not be returned');
    }
}