@isTest
private class KSAG_Migration_Mapping_TEST {

    private static User createTestUser() {
        // Find the required profile by name
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Consultation IT' LIMIT 1];

        // Find the required role by name
        UserRole r = [SELECT Id FROM UserRole WHERE Name = 'ARCE' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser_ksag@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = r.Id,
            ID_User__c = 'T012101'
        );

        insert u;

        // Assign the permission set
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Client_info' LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );

        return u;
    }

    @isTest
    static void testBuildMappingsAndApplyToAccount() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            // Simulate custom metadata records (no insert needed)
            List<KSAG_Migration_Mapping__mdt> fakeMetadata = new List<KSAG_Migration_Mapping__mdt>{
                new KSAG_Migration_Mapping__mdt(
                    Field_Name__c = 'DES_Activity__c',
                    Mapped_Values__c = '{"OldActivity": "NewActivity"}',
                    Object__c = 'Account'
                ),
                new KSAG_Migration_Mapping__mdt(
                    Field_Name__c = 'DES_Tier__c',
                    Mapped_Values__c = '{"T1": "Tier 1"}',
                    Object__c = 'Account'
                )
            };

            // Build mappings directly
            KSAG_Migration_Mapping.buildMappings(fakeMetadata);

            // Create a test Account with old values
            Account acc = new Account(
                Name = 'Test Account',
                DES_Activity__c = 'OldActivity',
                DES_Tier__c = 'T1'
            );

            Test.startTest();
            KSAG_Migration_Mapping.applyMappings(acc, 'Account');
            Test.stopTest();

            System.assertEquals('NewActivity', acc.DES_Activity__c);
            System.assertEquals('Tier 1', acc.DES_Tier__c);
        }
    }

    @isTest
    static void testEmptyMappingsHandledGracefully() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            List<KSAG_Migration_Mapping__mdt> invalidMetadata = new List<KSAG_Migration_Mapping__mdt>{
                new KSAG_Migration_Mapping__mdt(Field_Name__c = '', Mapped_Values__c = '{}'),
                new KSAG_Migration_Mapping__mdt(Field_Name__c = 'DES_Tier__c', Mapped_Values__c = null)
            };

            KSAG_Migration_Mapping.buildMappings(invalidMetadata);

            Account acc = new Account(Name = 'Edge Case', DES_Tier__c = 'T1');

            Test.startTest();
            KSAG_Migration_Mapping.applyMappings(acc, 'Account');
            Test.stopTest();

            System.assertEquals('T1', acc.DES_Tier__c);
        }
    }
}