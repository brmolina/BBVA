@isTest
private class ONB_RiskStateControllerTest {
   /* public static final String CONST_RISK_CLIENT_CONTACT_TYPE = 'RISK_CLIENT_CONTACT';

    private static ONB_Onboarding__c createOnboarding() {
        ONB_Onboarding__c onb = new ONB_Onboarding__c();
        onb.Name = 'Test Onboarding';
        insert onb;
        return onb;
    }

    @IsTest
    static void test_returnsExistingExternalContact() {
        // Arrange
        ONB_Onboarding__c onb = createOnboarding();

        ONB_External_Contact__c existing = new ONB_External_Contact__c(
            OnboardingId__c = onb.Id,
            Client_Type__c = CONST_RISK_CLIENT_CONTACT_TYPE
        );
        insert existing;

        // Act
        Test.startTest();
        Id resId = ONB_RiskStateController.getOrCreateExternalContact(onb.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(existing.Id, resId, 'Debe devolver el contacto externo existente');

        Integer cnt = [
            SELECT COUNT()
            FROM ONB_External_Contact__c
            WHERE OnboardingId__c = :onb.Id
              AND Client_Type__c = :CONST_RISK_CLIENT_CONTACT_TYPE
        ];
        System.assertEquals(1, cnt, 'No debe crear duplicados si ya existe');
    }

    @IsTest
    static void test_createsExternalContactWhenMissing() {
        ONB_Onboarding__c onb = createOnboarding();

        // Act
        Test.startTest();
        Id resId = ONB_RiskStateController.getOrCreateExternalContact(onb.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, resId, 'Debe crear y devolver un Id');

        ONB_External_Contact__c created = [
            SELECT Id, OnboardingId__c, Client_Type__c
            FROM ONB_External_Contact__c
            WHERE Id = :resId
            LIMIT 1
        ];
        System.assertEquals(onb.Id, created.OnboardingId__c, 'Debe setear el lookup al onboarding');
        System.assertEquals(
            ONB_RiskStateController.CONST_RISK_CLIENT_CONTACT_TYPE,
            created.Client_Type__c,
            'Debe setear el Client_Type__c a RISK_CLIENT_CONTACT'
        );
    }

    @IsTest
    static void test_nullOnboardingIdReturnsNull() {
        Test.startTest();
        Id resId = ONB_RiskStateController.getOrCreateExternalContact(null);
        Test.stopTest();

        System.assertEquals(null, resId, 'Si onboardingId es null debe devolver null');
    }/** */

}