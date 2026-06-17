@IsTest
public class ONB_MasterAgreementsControllerTest {

    @testSetup
    static void setupData() {
        // User to use as Internal Notification
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'tuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Madrid',
            ProfileId = p.Id,
            ID_User__c = 'TEST',
            Username = 'tuser.' + System.currentTimeMillis() + '@example.com'
        );
        insert u;

        // Onboarding
        ONB_Onboarding__c onb = new ONB_Onboarding__c(Name = 'ONB Test');
        insert onb;

        // Contracts
        Contrato_Marco__c cDirect = new Contrato_Marco__c(
            Name = 'Direct Contract',
            OnboardingId__c = onb.Id,
            ONB_Origin__c = 'New'
        );
        Contrato_Marco__c cExisting1 = new Contrato_Marco__c(
            Name = 'Existing Contract 1',
            ONB_Origin__c = 'Existing'
        );
        Contrato_Marco__c cExisting2 = new Contrato_Marco__c(
            Name = 'Existing Contract 2',
            ONB_Origin__c = 'Existing'
        );
        insert new List<Contrato_Marco__c>{ cDirect, cExisting1, cExisting2 };

        // Junction links one Existing contract
        ONB_Onboarding_Contract__c j1 = new ONB_Onboarding_Contract__c(
            Onboarding__c = onb.Id,
            Contract__c = cExisting1.Id
        );
        insert j1;

        // Internal notification relationship (pre-existing) for getInternalNotificationUserIds
        ONB_Onboarding_Contact_Relationship__c rel = new ONB_Onboarding_Contact_Relationship__c(
            OnboardingId__c = onb.Id,
            UserId__c = u.Id,
            ONB_Contact_Type__c = 'Internal_Notification'
        );
        insert rel;
    }

    private static ONB_Onboarding__c getOnboarding() {
        return [SELECT Id FROM ONB_Onboarding__c LIMIT 1];
    }

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
    }

    private static Contrato_Marco__c getDirectContract(Id onboardingId) {
        return [
            SELECT Id
            FROM Contrato_Marco__c
            WHERE OnboardingId__c = :onboardingId
            LIMIT 1
        ];
    }

    private static Contrato_Marco__c getExistingLinkedContract(Id onboardingId) {
        Id linkedId = [
            SELECT Contract__c
            FROM ONB_Onboarding_Contract__c
            WHERE Onboarding__c = :onboardingId
            LIMIT 1
        ].Contract__c;

        return [SELECT Id FROM Contrato_Marco__c WHERE Id = :linkedId LIMIT 1];
    }

    private static Contrato_Marco__c getExistingNotLinkedContract(Id onboardingId) {
        Set<Id> linked = new Set<Id>();
        for (ONB_Onboarding_Contract__c j : [
            SELECT Contract__c FROM ONB_Onboarding_Contract__c WHERE Onboarding__c = :onboardingId
        ]) {
            linked.add(j.Contract__c);
        }

        return [
            SELECT Id
            FROM Contrato_Marco__c
            WHERE ONB_Origin__c = 'Existing'
            AND Id NOT IN :linked
            LIMIT 1
        ];
    }

    private static String getMappedContractTypeByCategory(String category) {
        List<ONB_ContractLineCategory__mdt> rows = [
            SELECT Master_Agreement_Type__c
            FROM ONB_ContractLineCategory__mdt
            WHERE Line_Category__c = :category
              AND Master_Agreement_Type__c != null
            LIMIT 1
        ];

        return rows.isEmpty() ? null : rows[0].Master_Agreement_Type__c;
    }

    private static String getAnyUnmappedContractType() {
        Set<String> mappedTypes = new Set<String>();
        for (ONB_ContractLineCategory__mdt row : [
            SELECT Master_Agreement_Type__c
            FROM ONB_ContractLineCategory__mdt
            WHERE Master_Agreement_Type__c != null
        ]) {
            mappedTypes.add(row.Master_Agreement_Type__c.trim().toLowerCase());
        }

        for (Schema.PicklistEntry entry : Contrato_Marco__c.master_agreement_type__c.getDescribe().getPicklistValues()) {
            if (!entry.isActive()) {
                continue;
            }

            String value = entry.getValue();
            if (!mappedTypes.contains(value.trim().toLowerCase())) {
                return value;
            }
        }

        return null;
    }

    @IsTest
    static void testGetContractItems_null() {
        Test.startTest();
        List<Contrato_Marco__c> res = ONB_MasterAgreementsController.getContractItems(null);
        Test.stopTest();

        System.assertEquals(0, res.size());
    }

    @IsTest
    static void testGetContractItems_combinesDirectAndJunction() {
        ONB_Onboarding__c onb = getOnboarding();

        Test.startTest();
        List<Contrato_Marco__c> res = ONB_MasterAgreementsController.getContractItems(onb.Id);
        Test.stopTest();

        System.assertEquals(2, res.size());
    }

    @IsTest
    static void testGetContractLineCategoryStatus_nullOnboarding() {
        Test.startTest();
        ONB_MasterAgreementsController.ContractLineCategoryStatus status =
            ONB_MasterAgreementsController.getContractLineCategoryStatus(null, 'test');
        Test.stopTest();

        System.assertNotEquals(null, status);
        System.assertEquals(false, status.hasAssociatedContracts);
        System.assertEquals(false, status.hasReposContracts);
        System.assertEquals(false, status.hasDerivativesContracts);
        System.assertEquals(false, status.hasSecurityLendingContracts);
    }

    @IsTest
    static void testGetContractLineCategoryStatus_withContracts() {
        ONB_Onboarding__c onb = getOnboarding();

        Test.startTest();
        ONB_MasterAgreementsController.ContractLineCategoryStatus status =
            ONB_MasterAgreementsController.getContractLineCategoryStatus(onb.Id, 'test');
        Test.stopTest();

        System.assertNotEquals(null, status);
        System.assertEquals(true, status.hasAssociatedContracts);
    }

    @IsTest
    static void testGetContractLineCategoryStatus_securityLendingCategory() {
        String securityLendingType = getMappedContractTypeByCategory('SECURITY_LENDING');
        System.assertNotEquals(
            null,
            securityLendingType,
            'Expected at least one ONB_ContractLineCategory__mdt row for SECURITY_LENDING.'
        );

        ONB_Onboarding__c onb = new ONB_Onboarding__c(Name = 'ONB Security Lending Test');
        insert onb;

        insert new Contrato_Marco__c(
            Name = 'Security Lending Contract',
            OnboardingId__c = onb.Id,
            ONB_Origin__c = 'New',
            master_agreement_type__c = securityLendingType
        );

        Test.startTest();
        ONB_MasterAgreementsController.ContractLineCategoryStatus status =
            ONB_MasterAgreementsController.getContractLineCategoryStatus(onb.Id, 'test-security-lending');
        Test.stopTest();

        System.assertEquals(true, status.hasAssociatedContracts);
        System.assertEquals(true, status.hasSecurityLendingContracts);
    }

    @IsTest
    static void testGetContractLineCategoryStatus_reposCategory() {
        String reposType = getMappedContractTypeByCategory('REPOS');
        System.assertNotEquals(
            null,
            reposType,
            'Expected at least one ONB_ContractLineCategory__mdt row for REPOS.'
        );

        ONB_Onboarding__c onb = new ONB_Onboarding__c(Name = 'ONB Repos Test');
        insert onb;

        insert new Contrato_Marco__c(
            Name = 'Repos Contract',
            OnboardingId__c = onb.Id,
            ONB_Origin__c = 'New',
            master_agreement_type__c = reposType
        );

        Test.startTest();
        ONB_MasterAgreementsController.ContractLineCategoryStatus status =
            ONB_MasterAgreementsController.getContractLineCategoryStatus(onb.Id, 'test-repos');
        Test.stopTest();

        System.assertEquals(true, status.hasAssociatedContracts);
        System.assertEquals(true, status.hasReposContracts);
    }

    @IsTest
    static void testGetContractLineCategoryStatus_derivativesCategory() {
        String derivativesType = getMappedContractTypeByCategory('DERIVATIVES');
        System.assertNotEquals(
            null,
            derivativesType,
            'Expected at least one ONB_ContractLineCategory__mdt row for DERIVATIVES.'
        );

        ONB_Onboarding__c onb = new ONB_Onboarding__c(Name = 'ONB Derivatives Test');
        insert onb;

        insert new Contrato_Marco__c(
            Name = 'Derivatives Contract',
            OnboardingId__c = onb.Id,
            ONB_Origin__c = 'New',
            master_agreement_type__c = derivativesType
        );

        Test.startTest();
        ONB_MasterAgreementsController.ContractLineCategoryStatus status =
            ONB_MasterAgreementsController.getContractLineCategoryStatus(onb.Id, 'test-derivatives');
        Test.stopTest();

        System.assertEquals(true, status.hasAssociatedContracts);
        System.assertEquals(true, status.hasDerivativesContracts);
    }

    @IsTest
    static void testGetContractLineCategoryStatus_unmappedContractType() {
        String unmappedType = getAnyUnmappedContractType();
        System.assertNotEquals(
            null,
            unmappedType,
            'Expected at least one active master agreement type not mapped in ONB_ContractLineCategory__mdt.'
        );

        ONB_Onboarding__c onb = new ONB_Onboarding__c(Name = 'ONB Unmapped Type Test');
        insert onb;

        insert new Contrato_Marco__c(
            Name = 'Unmapped Contract',
            OnboardingId__c = onb.Id,
            ONB_Origin__c = 'New',
            master_agreement_type__c = unmappedType
        );

        Test.startTest();
        ONB_MasterAgreementsController.ContractLineCategoryStatus status =
            ONB_MasterAgreementsController.getContractLineCategoryStatus(onb.Id, 'test-unmapped');
        Test.stopTest();

        System.assertEquals(true, status.hasAssociatedContracts);
        System.assertEquals(false, status.hasReposContracts);
        System.assertEquals(false, status.hasDerivativesContracts);
        System.assertEquals(false, status.hasSecurityLendingContracts);
    }

    @IsTest
    static void testGetExistingContracts_excludesAlreadyLinked() {
        ONB_Onboarding__c onb = getOnboarding();

        Test.startTest();
        List<Contrato_Marco__c> res = ONB_MasterAgreementsController.getExistingContracts(onb.Id);
        Test.stopTest();

        System.assertEquals(1, res.size());
    }

    @IsTest
    static void testGetInternalNotificationUserIds_ok() {
        ONB_Onboarding__c onb = getOnboarding();
        User u = getTestUser();

        Test.startTest();
        List<Id> ids = ONB_MasterAgreementsController.getInternalNotificationUserIds(onb.Id);
        Test.stopTest();

        System.assertEquals(u.Id, ids.isEmpty() ? null : ids[0]);
    }

    @IsTest
    static void testAddInternalNotificationUser_insertsWhenMissing() {
        ONB_Onboarding__c onb = getOnboarding();

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u2 = new User(
            Alias = 'tus2',
            Email = 'tus2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tester2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Madrid',
            ProfileId = p.Id,
            ID_User__c = 'TEST2',
            Username = 'tus2.' + System.currentTimeMillis() + '@example.com'
        );
        insert u2;

        Test.startTest();
        ONB_MasterAgreementsController.addInternalNotificationUser(onb.Id, u2.Id);
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT()
            FROM ONB_Onboarding_Contact_Relationship__c
            WHERE OnboardingId__c = :onb.Id
              AND ONB_Contact_Type__c = 'Internal_Notification'
              AND UserId__c = :u2.Id
        ];
        System.assertEquals(1, cnt);
    }

    @IsTest
    static void testRemoveInternalNotificationUser_deletes() {
        ONB_Onboarding__c onb = getOnboarding();
        User u = getTestUser();

        Test.startTest();
        ONB_MasterAgreementsController.removeInternalNotificationUser(onb.Id, u.Id);
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT()
            FROM ONB_Onboarding_Contact_Relationship__c
            WHERE OnboardingId__c = :onb.Id
              AND ONB_Contact_Type__c = 'Internal_Notification'
              AND UserId__c = :u.Id
        ];
        System.assertEquals(0, cnt);
    }

    @IsTest
    static void testCreateOnboardingContractsJunction_insertsMissingOnly() {
        ONB_Onboarding__c onb = getOnboarding();
        Contrato_Marco__c existingLinked = getExistingLinkedContract(onb.Id);
        Contrato_Marco__c existingNotLinked = getExistingNotLinkedContract(onb.Id);

        Test.startTest();
        ONB_MasterAgreementsController.createOnboardingContractsJunction(
            onb.Id,
            new List<Id>{ existingLinked.Id, existingNotLinked.Id, null }
        );
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT()
            FROM ONB_Onboarding_Contract__c
            WHERE Onboarding__c = :onb.Id
              AND Contract__c = :existingNotLinked.Id
        ];
        System.assertEquals(1, cnt);
    }

    @IsTest
    static void testRemoveOnboardingContractJunction_deletes() {
        ONB_Onboarding__c onb = getOnboarding();
        Contrato_Marco__c linked = getExistingLinkedContract(onb.Id);

        Test.startTest();
        ONB_MasterAgreementsController.removeOnboardingContractJunction(onb.Id, linked.Id);
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT()
            FROM ONB_Onboarding_Contract__c
            WHERE Onboarding__c = :onb.Id
              AND Contract__c = :linked.Id
        ];
        System.assertEquals(0, cnt);
    }
}