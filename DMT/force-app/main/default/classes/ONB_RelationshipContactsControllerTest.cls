@isTest
private class ONB_RelationshipContactsControllerTest {

    @testSetup
    static void setupData() {
        ONB_Onboarding__c onb = new ONB_Onboarding__c(
            Name = 'Test Onboarding'
        );
        insert onb;

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User user1 = new User(
            ProfileId = p.Id,
            Username = 'test.rel.user1.' + System.currentTimeMillis() + '@example.com',
            Email = 'rel.user1@example.com',
            LastName = 'RelUser1',
            Alias = 'relusr1',
            TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'es_ES',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es'
        );
        user1.ID_User__C = String.valueOf((Math.random()*100000));
        insert user1;

        User user2 = new User(
            ProfileId = p.Id,
            Username = 'test.rel.user2.' + System.currentTimeMillis() + '@example.com',
            Email = 'rel.user2@example.com',
            LastName = 'RelUser2',
            Alias = 'relusr2',
            TimeZoneSidKey = 'Europe/Madrid',
            LocaleSidKey = 'es_ES',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es'
        );
        user2.ID_User__C = String.valueOf((Math.random()*100000));
        insert user2;
        
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        Contact contact1 = new Contact(
            AccountId = acc.Id,
            LastName = 'RelContact1',
            Email_ExternalID__c = 'rel.contact1@bbva.com',
            Phone = '123456789'
        );
        insert contact1;
        
        List<ONB_Onboarding_Contact_Relationship__c> rels = new List<ONB_Onboarding_Contact_Relationship__c>{
            new ONB_Onboarding_Contact_Relationship__c(
                OnboardingId__c = onb.Id,
                UserId__c = user1.Id,
                Relationship_Type__c = 'Sales Person',
                ONB_Contact_Type_State__c = 'RELATIONSHIP_CONTACTS'
            ),
            new ONB_Onboarding_Contact_Relationship__c(
                OnboardingId__c = onb.Id,
                UserId__c = user2.Id,
                Relationship_Type__c = 'Relationship Manager',
                ONB_Contact_Type_State__c = 'RELATIONSHIP_CONTACTS'
            ),
            new ONB_Onboarding_Contact_Relationship__c(
                OnboardingId__c = onb.Id,
                ContactId__c = contact1.Id,
                Relationship_Type__c = 'Sales Person',
                ONB_Contact_Type_State__c = 'RELATIONSHIP_CONTACTS'
            )
        };
        insert rels;

        List<ONB_External_Contact__c> externalContacts = new List<ONB_External_Contact__c>{
            new ONB_External_Contact__c(
                OnboardingId__c = onb.Id,
                Name = 'Risk Contact',
                Email__c = 'risk@example.com',
                Type__c = 'RISK_CLIENT_CONTACT'
            ),
            new ONB_External_Contact__c(
                OnboardingId__c = onb.Id,
                Name = 'Legal Contact',
                Email__c = 'legal@example.com',
                Type__c = 'LEGAL_CLIENT_CONTACT'
            )
        };
        insert externalContacts;
    }

    @IsTest
    static void test_getRelationshipContactsByOnboarding_nullId() {
        Test.startTest();
        List<ONB_Onboarding_Contact_Relationship__c> result =
            ONB_RelationshipContactsController.getRelationshipContactsByOnboarding(null,'nonce-null');
        Test.stopTest();

        System.assertNotEquals(null, result, 'No debe devolver null');
        System.assertEquals(0, result.size(), 'Con onboardingId null debe devolver lista vacía');
    }

    @IsTest
    static void test_getRelationshipContactsByOnboarding_withData() {
        ONB_Onboarding__c onb = [SELECT Id FROM ONB_Onboarding__c LIMIT 1];

        Test.startTest();
        List<ONB_Onboarding_Contact_Relationship__c> result =
            ONB_RelationshipContactsController.getRelationshipContactsByOnboarding(onb.Id, 'nonce');
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Debe traer los 3 relationships insertados');
        for(ONB_Onboarding_Contact_Relationship__c rel : result) {
            System.assertNotEquals(null, rel.Id, 'El Id no debe ser nulo');
            System.assertEquals(onb.Id, rel.OnboardingId__c, 'El OnboardingId debe coincidir');
            System.assertNotEquals(null, rel.Relationship_Type__c, 'El tipo de relación no debe ser nulo');
            System.assert(rel.UserId__c != null || rel.ContactId__c != null, 'Debe tener un Usuario o un Contacto vinculado');
            System.assertEquals('RELATIONSHIP_CONTACTS', rel.ONB_Contact_Type_State__c, 'El campo de estado debe venir relleno desde la BD');
        }
    }

    @IsTest
    static void test_getUserEmail_nullId() {
        Test.startTest();
        String email = ONB_RelationshipContactsController.getUserEmail(null);
        Test.stopTest();

        System.assertEquals(null, email, 'Con userId null debe devolver null');
    }

    @IsTest
    static void test_getUserEmail_ok() {
        User u = [SELECT Id, Email FROM User WHERE Email = 'rel.user1@example.com' LIMIT 1];

        Test.startTest();
        String email = ONB_RelationshipContactsController.getUserEmail(u.Id);
        Test.stopTest();

        System.assertEquals(u.Email, email, 'Debe devolver el email del usuario');
    }

    @IsTest
    static void test_getContactEmail_nullId() {
        Test.startTest();
        String email = ONB_RelationshipContactsController.getContactEmail(null);
        Test.stopTest();

        System.assertEquals(null, email, 'Con contactId null debe devolver null');
    }

    @IsTest
    static void test_getContactEmail_ok() {
        Contact c = [SELECT Id, Email FROM Contact WHERE Email = 'rel.contact1@bbva.com' LIMIT 1];

        Test.startTest();
        String email = ONB_RelationshipContactsController.getContactEmail(c.Id);
        Test.stopTest();

        System.assertEquals(c.Email, email, 'Debe devolver el email del contacto');
    }

    @IsTest
    static void test_getExternalContactsByOnboarding_nullId() {
        Test.startTest();
        List<ONB_External_Contact__c> result =
            ONB_RelationshipContactsController.getExternalContactsByOnboarding(null, 'nonce-null');
        Test.stopTest();

        System.assertNotEquals(null, result, 'No debe devolver null');
        System.assertEquals(0, result.size(), 'Con onboardingId null debe devolver lista vacía');
    }

    @IsTest
    static void test_getExternalContactsByOnboarding_withData() {
        ONB_Onboarding__c onb = [SELECT Id FROM ONB_Onboarding__c LIMIT 1];

        Test.startTest();
        List<ONB_External_Contact__c> result =
            ONB_RelationshipContactsController.getExternalContactsByOnboarding(onb.Id, 'nonce');
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Debe traer los 2 contactos externos insertados');
        
        // Verificamos que los campos solicitados en la Query vienen llenos
        for(ONB_External_Contact__c extContact : result) {
            System.assertNotEquals(null, extContact.Id, 'El Id no debe ser nulo');
            System.assertNotEquals(null, extContact.Name, 'El nombre no debe ser nulo');
            System.assertNotEquals(null, extContact.Type__c, 'El Type__c no debe ser nulo');
            System.assertNotEquals(null, extContact.Email__c, 'El email no debe ser nulo'); 
        }
    }


}