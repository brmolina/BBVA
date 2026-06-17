@IsTest
private class ONB_createOnboardingControllerTest {

    private static String getAnyActivePicklistValue(Schema.SObjectField fieldRef, String fallbackValue) {
        List<Schema.PicklistEntry> values = fieldRef.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry value : values) {
            if (value.isActive()) {
                return value.getValue();
            }
        }
        return fallbackValue;
    }
    
    private static Id getAnyAccountRecordTypeId() {
        for (Schema.RecordTypeInfo rti : Schema.SObjectType.Account.getRecordTypeInfos()) {
            if (rti.isAvailable()) {
                return rti.getRecordTypeId();
            }
        }
        return null;
    }

    private static String getAnyLegalEntityType() {
        return getAnyActivePicklistValue(ONB_Onboarding__c.Legal_Entity_Type__c, null);
    }

    private static String getAnyRequestType() {
        return getAnyActivePicklistValue(ONB_Onboarding__c.Request_Type__c, 'Add funds (without derivations)');
    }

    private static String getAnyPrioritization() {
        return getAnyActivePicklistValue(ONB_Onboarding__c.Prioritization__c, 'High');
    }

    private static String getAnyIsSalesPerson() {
        return getAnyActivePicklistValue(ONB_Onboarding__c.Is_Sales_Person__c, 'Yes');
    }

    private static String getAnyOperationInPlatform() {
        return getAnyActivePicklistValue(ONB_Onboarding__c.Operation_in_Platform__c, 'Yes');
    }

    private static String getAnyAnyMasterAgreement() {
        return getAnyActivePicklistValue(ONB_Onboarding__c.Any_Master_Agreement__c, 'No');
    }

    @testSetup
    static void setupData() {
        Account parentAcc = new Account(Name = 'Parent Account');
        insert parentAcc;

        Account existingClient = new Account(
            Name = 'Existing Client',
            lei_id__c = '12345678901234567890'
        );
        insert existingClient;
    }

    @IsTest
    static void testCreateAccountAndOnboarding_NewClient_setsClientOnOnboarding() {
        Id parentId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;

        Test.startTest();
        ONB_createOnboardingController.ONB_createOnboardingResult res =
            ONB_createOnboardingController.createAccountAndOnboarding(
                'New Client',
                '12345678901234567890',
                'CIF12345678',
                false,
                getAnyRequestType(),
                String.valueOf(parentId),
                String.valueOf(getAnyAccountRecordTypeId()),
                getAnyPrioritization(),
                'Branch 1',
                'Segment 1',
                getAnyLegalEntityType(),
                getAnyIsSalesPerson(),
                null,
                getAnyOperationInPlatform(),
                getAnyAnyMasterAgreement(),
                false,
                null
            );
        Test.stopTest();

        ONB_Onboarding__c onb = [
            SELECT Id, Client__c
            FROM ONB_Onboarding__c
            WHERE Id = :res.onboardingId
            LIMIT 1
        ];

        System.assertEquals(res.accountId, onb.Client__c);
    }

    @IsTest
    static void testCreateAccountAndOnboarding_NewClient_createsSalesPersonRelationship() {
        Id parentId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;

        Test.startTest();
        ONB_createOnboardingController.ONB_createOnboardingResult res =
            ONB_createOnboardingController.createAccountAndOnboarding(
                'New Client 2',
                '12345678901234567890',
                'CIF12345678',
                false,
                getAnyRequestType(),
                String.valueOf(parentId),
                String.valueOf(getAnyAccountRecordTypeId()),
                getAnyPrioritization(),
                'Branch 2',
                'Segment 2',
                getAnyLegalEntityType(),
                getAnyIsSalesPerson(),
                null,
                getAnyOperationInPlatform(),
                getAnyAnyMasterAgreement(),
                false,
                null
            );
        Test.stopTest();

        Integer relCount = [
            SELECT COUNT()
            FROM ONB_Onboarding_Contact_Relationship__c
            WHERE OnboardingId__c = :res.onboardingId
              AND UserId__c = :UserInfo.getUserId()
              AND Relationship_Type__c = 'Sales Person'
        ];

        System.assertEquals(1, relCount);
    }

    @IsTest
    static void testCreateAccountAndOnboarding_NewClient_createsAccountRelationshipWhenParentProvided() {
        Id parentId = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1].Id;

        Test.startTest();
        ONB_createOnboardingController.ONB_createOnboardingResult res =
            ONB_createOnboardingController.createAccountAndOnboarding(
                'New Client 3',
                '12345678901234567890',
                'CIF12345678',
                false,
                getAnyRequestType(),
                String.valueOf(parentId),
                String.valueOf(getAnyAccountRecordTypeId()),
                getAnyPrioritization(),
                'Branch 3',
                'Segment 3',
                getAnyLegalEntityType(),
                getAnyIsSalesPerson(),
                null,
                getAnyOperationInPlatform(),
                getAnyAnyMasterAgreement(),
                false,
                null
            );
        Test.stopTest();

        Integer relCount = [
            SELECT COUNT()
            FROM AMH_GBL_Account_Relationship__c
            WHERE AMH_Child_Account__c = :res.accountId
              AND AMH_Parent_Account__c = :parentId
              AND AMH_Type__c = '07 - Fondo'
              AND AMH_Vision__c = 'Negocio'
        ];

        System.assertEquals(1, relCount);
    }

    @IsTest
    static void testCreateAccountAndOnboarding_ExistingClient_setsClientOnOnboarding() {
        Id existingClientId = [SELECT Id FROM Account WHERE Name = 'Existing Client' LIMIT 1].Id;

        Test.startTest();
        ONB_createOnboardingController.ONB_createOnboardingResult res =
            ONB_createOnboardingController.createAccountAndOnboarding(
                'Ignored Name',
                'Ignored LEI',
                'IGNORED-CIF',
                false,
                getAnyRequestType(),
                null,
                String.valueOf(getAnyAccountRecordTypeId()),
                getAnyPrioritization(),
                'Branch X',
                'Segment X',
                getAnyLegalEntityType(),
                getAnyIsSalesPerson(),
                null,
                getAnyOperationInPlatform(),
                getAnyAnyMasterAgreement(),
                true,
                String.valueOf(existingClientId)
            );
        Test.stopTest();

        ONB_Onboarding__c onb = [
            SELECT Id, Client__c
            FROM ONB_Onboarding__c
            WHERE Id = :res.onboardingId
            LIMIT 1
        ];

        System.assertEquals(existingClientId, onb.Client__c);
    }

    @IsTest
    static void testGetClientInfo_returnsName() {
        Account existingClient = [SELECT Id, Name FROM Account WHERE Name = 'Existing Client' LIMIT 1];

        Test.startTest();
        ONB_createOnboardingController.ONB_clientInfo info =
            ONB_createOnboardingController.getClientInfo(existingClient.Id);
        Test.stopTest();

        System.assertEquals(existingClient.Name, info.clientName);
    }
}