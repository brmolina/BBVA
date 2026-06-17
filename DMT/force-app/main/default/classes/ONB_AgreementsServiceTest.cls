@isTest
private class ONB_AgreementsServiceTest {
    static final String ONB_NEW_CLIENT_ONB_RTNAME = System.Label.ONB_NEW_CLIENT_ONB_RTNAME;

    @testSetup
    static void setup() {

        // Create the Account with the FINSID matching the JSON Party ID (86984)

        Id rtId = [SELECT Id FROM RecordType WHERE sObjectType='Account' AND DeveloperName = :ONB_NEW_CLIENT_ONB_RTNAME].Id;

        Account acc = new Account(
            RecordTypeId = rtId,
            lei_id__c = 'lei00000000000000000',
            g_customer_id__c = 'codigocliente',
            Name = 'Test Client',
            ONB_FINSID__c = '86984'

        );

        insert acc;
    }

    @isTest
    static void testSyncAgreements() {
        // 1. Create a unique user to run the test
        // We use 'Standard User' profile as a generic baseline
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User testUser = new User(
            Alias = 'onbtst', 
            Email = 'onbtest@example.com',
            EmailEncodingKey = 'UTF-8', 
            LastName = 'OnboardingTest', 
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', 
            ProfileId = p.Id,
            FederationIdentifier = 'T011111',
            ID_User__c = 'T011111',
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'onbtestuser_' + DateTime.now().getTime() + '@example.com'
        );
        insert testUser;

        // 2. Assign the 'ONB_Onboarding' Permission Set to this user
        // This grants the 'ONB_Onboarding_CP' custom permission needed for the check
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ONB_Onboarding' LIMIT 1];
        
        insert new PermissionSetAssignment(
            AssigneeId = testUser.Id, 
            PermissionSetId = ps.Id
        );

        // Retrieve the account created in setup

        // 3. Run the test logic AS the user with the permission set
        System.runAs(testUser) {
            Test.startTest();
            
                Account testAcc = [SELECT Id FROM Account WHERE ONB_FINSID__c = '86984' LIMIT 1];
                // Set the mock callout (Uncomment and replace 'YourMockClass' if you have one ready)
                // Test.setMock(HttpCalloutMock.class, new YourMockClass()); 

                // Call the controller method
                // This will now pass the FeatureManagement.checkPermission('ONB_Onboarding_CP') check
                ONB_AgreementsSyncController.SyncResult result = ONB_AgreementsSyncController.syncAgreementsForAccount(testAcc.Id);
            Test.stopTest();

            // Validate results based on the logic in ONB_AgreementsSyncController
            System.assertEquals(true, result.success, 'Sync should be successful');
            System.assertEquals(1, result.contratosUpserted, 'Should have upserted 1 Contrato_Marco__c');

            // Verify Contrato_Marco__c was created and Lookup was resolved
            // Note: Queries inside runAs respect the user's permissions, so ensure they have read access 
            // to these objects via the Permission Set or Profile.
            Contrato_Marco__c cm = [SELECT ONB_Contract_Code__c, participant_id__c FROM Contrato_Marco__c LIMIT 1];
            System.assertEquals('CMOF-ES-2013-000438', cm.ONB_Contract_Code__c);
            System.assertEquals(testAcc.Id, cm.participant_id__c, 'The participant lookup should have resolved to our test account');

            // Verify Junction record
            Integer junctionCount = [SELECT count() FROM ONB_Master_Agreement__c WHERE ONB_Client__c = :testAcc.Id];
            System.assertEquals(1, junctionCount, 'One junction record should exist');
        }
    }
}