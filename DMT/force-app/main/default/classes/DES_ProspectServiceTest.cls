/**
 * _________________________________________________________________________________
 * @Name      DES_ProspectServiceTest
 * @Author    Borja Lorenzo Adajas
 * @Date      2026-05-18
 * ---------------------------------------------------------------------------------
 * @Description  Test class for DES_ProspectService.
 *               assignAccountTeamMember critical paths get individual methods.
 *               Simple paths (no-op scenarios) and read-only methods are grouped.
 * ---------------------------------------------------------------------------------
 * @History
 * Version   Date            Author          Summary of changes
 * 1.0       2026-05-18      Borja Lorenzo   Versión inicial.
 * _________________________________________________________________________________
 **/
@IsTest(testFor='ApexClass:DES_ProspectService')
private class DES_ProspectServiceTest {

    // ──────────────────────────────────────────────────────────────────────────
    // Test data setup
    // ──────────────────────────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        final DES_UtilTestClass util = new DES_UtilTestClass();
        final String profileId = util.createProfile();

        final User banker1 = util.createUser(profileId, 'banker1@prospect.test');
        final User banker2 = util.createUser(profileId, 'banker2@prospect.test');
        insert new List<User>{ banker1, banker2 };

        final Id prospectGroupRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP)
            .getRecordTypeId();

        final Account prospectAcc = util.createClient();
        prospectAcc.RecordTypeId = prospectGroupRtId;
        insert prospectAcc;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // assignAccountTeamMember — critical paths
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void assignAccountTeamMember_insertWithBanker_createsTeamMember() {
        // assignAccountTeamMember — insert context, DES_Global_banker__c set
        final User banker1 = [SELECT Id FROM User WHERE Username LIKE '%banker1@prospect.test%' LIMIT 1];
        final Account acc = [SELECT Id, RecordTypeId FROM Account LIMIT 1];
        acc.DES_Global_banker__c = banker1.Id;

        Test.startTest();
        DES_ProspectService.assignAccountTeamMember(new List<Account>{ acc }, null);
        Test.stopTest();

        final List<DES_BBVA_Management_team__c> members = [
            SELECT DES_Member_Role__c FROM DES_BBVA_Management_team__c
            WHERE DES_Client__c = :acc.Id AND DES_Member_Role__c = :Label.DES_ROLE_GLOBAL_BANKER
        ];
        System.assertEquals(1, members.size(), 'A DES_BBVA_Management_team__c record should be created on insert when a banker is assigned');
    }

    @IsTest
    static void assignAccountTeamMember_updateBankerAssigned_createsTeamMember() {
        // assignAccountTeamMember — update context, null → User
        final User banker1 = [SELECT Id FROM User WHERE Username LIKE '%banker1@prospect.test%' LIMIT 1];
        final Account acc = [SELECT Id, RecordTypeId, DES_Global_banker__c FROM Account LIMIT 1];

        final Account oldAcc = acc.clone(true, true, false, false);
        oldAcc.DES_Global_banker__c = null;
        acc.DES_Global_banker__c = banker1.Id;

        Test.startTest();
        DES_ProspectService.assignAccountTeamMember(
            new List<Account>{ acc },
            new Map<Id, Account>{ acc.Id => oldAcc }
        );
        Test.stopTest();

        final List<DES_BBVA_Management_team__c> members = [
            SELECT Id FROM DES_BBVA_Management_team__c
            WHERE DES_Client__c = :acc.Id AND DES_Member_Role__c = :Label.DES_ROLE_GLOBAL_BANKER
        ];
        System.assertEquals(1, members.size(), 'A DES_BBVA_Management_team__c record should be created when a banker is assigned on update');
    }

    @IsTest
    static void assignAccountTeamMember_updateBankerRemoved_deletesTeamMember() {
        // assignAccountTeamMember — update context, User → null
        final User banker1 = [SELECT Id FROM User WHERE Username LIKE '%banker1@prospect.test%' LIMIT 1];
        final Account acc = [SELECT Id, RecordTypeId FROM Account LIMIT 1];

        insert new DES_BBVA_Management_team__c(
            DES_Client__c               = acc.Id,
            DES_User__c                 = banker1.Id,
            DES_Member_Role__c          = Label.DES_ROLE_GLOBAL_BANKER,
            DES_Local_Banker_Country__c = DES_Constants.MANAGEMENT_TEAM_GLOBAL_COUNTRY
        );

        final Account oldAcc = acc.clone(true, true, false, false);
        oldAcc.DES_Global_banker__c = banker1.Id;
        acc.DES_Global_banker__c = null;

        Test.startTest();
        DES_ProspectService.assignAccountTeamMember(
            new List<Account>{ acc },
            new Map<Id, Account>{ acc.Id => oldAcc }
        );
        Test.stopTest();

        final List<DES_BBVA_Management_team__c> members = [
            SELECT Id FROM DES_BBVA_Management_team__c
            WHERE DES_Client__c = :acc.Id AND DES_Member_Role__c = :Label.DES_ROLE_GLOBAL_BANKER
        ];
        System.assertEquals(0, members.size(), 'The DES_BBVA_Management_team__c record should be deleted when the banker is removed');
    }

    @IsTest
    static void assignAccountTeamMember_updateBankerChanged_replacesTeamMember() {
        // assignAccountTeamMember — update context, User A → User B
        final User banker1 = [SELECT Id FROM User WHERE Username LIKE '%banker1@prospect.test%' LIMIT 1];
        final User banker2 = [SELECT Id FROM User WHERE Username LIKE '%banker2@prospect.test%' LIMIT 1];
        final Account acc = [SELECT Id, RecordTypeId FROM Account LIMIT 1];

        insert new DES_BBVA_Management_team__c(
            DES_Client__c               = acc.Id,
            DES_User__c                 = banker1.Id,
            DES_Member_Role__c          = Label.DES_ROLE_GLOBAL_BANKER,
            DES_Local_Banker_Country__c = DES_Constants.MANAGEMENT_TEAM_GLOBAL_COUNTRY
        );

        final Account oldAcc = acc.clone(true, true, false, false);
        oldAcc.DES_Global_banker__c = banker1.Id;
        acc.DES_Global_banker__c = banker2.Id;

        Test.startTest();
        DES_ProspectService.assignAccountTeamMember(
            new List<Account>{ acc },
            new Map<Id, Account>{ acc.Id => oldAcc }
        );
        Test.stopTest();

        final List<DES_BBVA_Management_team__c> members = [
            SELECT DES_User__c FROM DES_BBVA_Management_team__c
            WHERE DES_Client__c = :acc.Id AND DES_Member_Role__c = :Label.DES_ROLE_GLOBAL_BANKER
        ];
        System.assertEquals(1, members.size(),        'Exactly 1 DES_BBVA_Management_team__c record should exist after the banker is changed');
        System.assertEquals(banker2.Id, members[0].DES_User__c, 'The record should reference the new banker');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // assignAccountTeamMember — simple no-op paths
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void assignAccountTeamMember_noRelevantChange_noTeamMemberAffected() {
        // assignAccountTeamMember — banker unchanged on update, insert without banker, non-prospect RT
        final User banker1 = [SELECT Id FROM User WHERE Username LIKE '%banker1@prospect.test%' LIMIT 1];
        final Account acc = [SELECT Id, RecordTypeId, DES_Global_banker__c FROM Account LIMIT 1];
        acc.DES_Global_banker__c = banker1.Id;

        // Case 1: banker unchanged on update
        final Account oldAccSameBanker = acc.clone(true, true, false, false);

        // Case 2: insert without banker
        final Account accNoBanker = acc.clone(true, true, false, false);
        accNoBanker.DES_Global_banker__c = null;

        // Case 3: non-prospect account (null RecordTypeId)
        final Account nonProspectAcc = new Account(Id = acc.Id, DES_Global_banker__c = banker1.Id);

        Test.startTest();
        DES_ProspectService.assignAccountTeamMember(
            new List<Account>{ acc, accNoBanker, nonProspectAcc },
            new Map<Id, Account>{ acc.Id => oldAccSameBanker }
        );
        Test.stopTest();

        final List<DES_BBVA_Management_team__c> members = [
            SELECT Id FROM DES_BBVA_Management_team__c WHERE DES_Client__c = :acc.Id
        ];
        System.assertEquals(0, members.size(), 'No DES_BBVA_Management_team__c record should be created when there are no relevant changes');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // generateProspectId
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void generateProspectId_subsidiaryRecord_prospectIdSet() {
        // generateProspectId — Prospect_Subsidiary account gets prospect ID generated
        final Id subsidiaryRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY)
            .getRecordTypeId();

        final DES_UtilTestClass util = new DES_UtilTestClass();
        final Account subsidiaryAcc = util.createClient();
        subsidiaryAcc.RecordTypeId     = subsidiaryRtId;
        subsidiaryAcc.DES_ID_Fiscal__c = 'TEST001';
        insert subsidiaryAcc;

        Test.startTest();
        DES_ProspectService.generateProspectId(new Map<Id, Account>{ subsidiaryAcc.Id => subsidiaryAcc });
        Test.stopTest();

        final Account result = [SELECT gf_customer_prospect_id__c FROM Account WHERE Id = :subsidiaryAcc.Id];
        System.assertEquals(
            String.valueOf(subsidiaryAcc.Id).substring(3),
            result.gf_customer_prospect_id__c,
            'Prospect_Subsidiary account must have prospect ID set to Salesforce Id without the 3-char prefix'
        );
    }

    @IsTest
    static void generateProspectId_groupRecord_prospectIdSet() {
        // generateProspectId — Prospect_Group account is skipped, prospect ID is not set
        final Account groupAcc = [SELECT Id, RecordTypeId FROM Account LIMIT 1];

        Test.startTest();
        DES_ProspectService.generateProspectId(new Map<Id, Account>{ groupAcc.Id => groupAcc });
        Test.stopTest();

        final Account result = [SELECT gf_customer_prospect_id__c FROM Account WHERE Id = :groupAcc.Id];
        System.assertEquals(
            String.valueOf(groupAcc.Id).substring(3),
            result.gf_customer_prospect_id__c,
            'Prospect_Group accounts must have prospect ID generated'
        );
    }

    // ──────────────────────────────────────────────────────────────────────────
    // isProspectRecord
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void isProspectRecord_returnsCorrectResult() {
        // isProspectRecord
        final Account prospectAcc    = [SELECT Id, RecordTypeId FROM Account LIMIT 1];
        final Account noRtAcc        = new Account();
        final Account nonProspectAcc = new Account(RecordTypeId = UserInfo.getUserId()); // any non-prospect Id

        Test.startTest();
        final Boolean isProspect    = DES_ProspectService.isProspectRecord(prospectAcc);
        final Boolean isNullRt      = DES_ProspectService.isProspectRecord(noRtAcc);
        Test.stopTest();

        System.assertEquals(true,  isProspect, 'Una cuenta Prospect_Group debe identificarse como prospect');
        System.assertEquals(false, isNullRt,   'Una cuenta sin RecordTypeId no debe identificarse como prospect');
    }

    @IsTest
    static void isProspectRecord_withDevName_returnsCorrectResult() {
        // isProspectRecord(Account acc, String devName)
        final Account groupAcc = [SELECT Id, RecordTypeId FROM Account LIMIT 1];
        final Account noRtAcc  = new Account();

        Test.startTest();
        final Boolean isGroup      = DES_ProspectService.isProspectRecord(groupAcc, DES_Constants.ACCOUNT_RT_PROSPECT_GROUP);
        final Boolean isSubsidiary = DES_ProspectService.isProspectRecord(groupAcc, DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY);
        final Boolean isNullRt     = DES_ProspectService.isProspectRecord(noRtAcc,  DES_Constants.ACCOUNT_RT_PROSPECT_GROUP);
        Test.stopTest();

        System.assertEquals(true,  isGroup,      'Prospect_Group account must match ACCOUNT_RT_PROSPECT_GROUP devName');
        System.assertEquals(false, isSubsidiary, 'Prospect_Group account must not match ACCOUNT_RT_PROSPECT_SUBSIDIARY devName');
        System.assertEquals(false, isNullRt,     'Account with null RecordTypeId must return false regardless of devName');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // getProspectRecordTypeIds
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void getProspectRecordTypeIds_returnsExpectedIds() {
        // getProspectRecordTypeIds
        final Id prospectGroupRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        final Id prospectSubsidiaryRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        Test.startTest();
        final Set<Id> rtIds       = DES_ProspectService.getProspectRecordTypeIds();
        final Set<Id> rtIdsCached = DES_ProspectService.getProspectRecordTypeIds();
        Test.stopTest();

        System.assertEquals(true, rtIds.contains(prospectGroupRtId),      'Debe incluir el RT de Prospect_Group');
        System.assertEquals(true, rtIds.contains(prospectSubsidiaryRtId), 'Debe incluir el RT de Prospect_Subsidiary');
        System.assertEquals(rtIds, rtIdsCached,                            'La segunda llamada debe retornar los mismos IDs');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // generateProspectId — additional paths
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void generateProspectId_emptyMap_noOp() {
        // Empty map → allProspectIds empty → early return, no exception
        Test.startTest();
        DES_ProspectService.generateProspectId(new Map<Id, Account>());
        Test.stopTest();
        System.assert(true, 'Empty map should not throw an exception');
    }

    @IsTest
    static void generateProspectId_nonProspectAccount_noIdSet() {
        // Regular (non-prospect) account → skipped → gf_customer_prospect_id__c stays null
        final DES_UtilTestClass util = new DES_UtilTestClass();
        final Account regularAcc = util.createClient();
        regularAcc.DES_ID_Fiscal__c = 'TEST001';
        insert regularAcc;

        Test.startTest();
        DES_ProspectService.generateProspectId(new Map<Id, Account>{ regularAcc.Id => regularAcc });
        Test.stopTest();

        final Account result = [SELECT gf_customer_prospect_id__c FROM Account WHERE Id = :regularAcc.Id];
        System.assertEquals(null, result.gf_customer_prospect_id__c,
            'Non-prospect account should not have gf_customer_prospect_id__c set');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // createProspectAccountRelationship
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void createProspectAccountRelationship_emptyList_noOp() {
        // Empty list → no-op
        Test.startTest();
        DES_ProspectService.createProspectAccountRelationship(new List<Account>());
        Test.stopTest();
        System.assert(true, 'Empty list should not throw an exception');
    }

    @IsTest
    static void createProspectAccountRelationship_groupAccount_noRelationship() {
        // Group account (not subsidiary, no participant_id__c) → subsidiaryCandidates empty → early return
        final Account groupAcc = [SELECT Id, RecordTypeId FROM Account LIMIT 1];

        Test.startTest();
        DES_ProspectService.createProspectAccountRelationship(new List<Account>{ groupAcc });
        Test.stopTest();

        final List<AMH_GBL_Account_Relationship__c> rels = [
            SELECT Id FROM AMH_GBL_Account_Relationship__c WHERE AMH_Child_Account__c = :groupAcc.Id
        ];
        System.assertEquals(0, rels.size(), 'No relationship should be created for non-subsidiary accounts');
    }

    @IsTest
    static void createProspectAccountRelationship_subsidiaryWithGroupParent_createsRelationships() {
        // Prospect_Subsidiary with participant_id__c → Prospect_Group → 2 relationships created
        final Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        final DES_UtilTestClass util = new DES_UtilTestClass();

        Account groupAcc = util.createClient();
        groupAcc.RecordTypeId = groupRtId;
        groupAcc.DES_ID_Fiscal__c = 'TEST001';
        insert groupAcc;

        Account subsidiaryAcc = util.createClient();
        subsidiaryAcc.RecordTypeId = subsidiaryRtId;
        subsidiaryAcc.DES_ID_Fiscal__c = 'TEST002';
        subsidiaryAcc.participant_id__c = groupAcc.Id;

        // El trigger after-insert llama a createProspectAccountRelationship → crea 2 relaciones
        Test.startTest();
        insert subsidiaryAcc;
        Test.stopTest();

        final List<AMH_GBL_Account_Relationship__c> rels = [
            SELECT Id, AMH_Vision__c FROM AMH_GBL_Account_Relationship__c
            WHERE AMH_Child_Account__c = :subsidiaryAcc.Id AND AMH_Parent_Account__c = :groupAcc.Id
            ORDER BY AMH_Vision__c
        ];
        System.assertEquals(2, rels.size(), 'Two relationships (Negocio and Riesgos) should be created');
    }

    @IsTest
    static void createProspectAccountRelationship_subsidiaryWithNonGroupParent_noRelationship() {
        // Prospect_Subsidiary whose participant_id__c points to a regular account → no relationship
        final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        final DES_UtilTestClass util = new DES_UtilTestClass();

        Account regularParent = util.createClient();
        regularParent.DES_ID_Fiscal__c = 'TEST001';
        insert regularParent;

        // Insertar la subsidiaria sin participant_id__c para evitar el lookup filter
        Account subsidiaryAcc = util.createClient();
        subsidiaryAcc.RecordTypeId = subsidiaryRtId;
        subsidiaryAcc.DES_ID_Fiscal__c = 'TEST002';
        insert subsidiaryAcc;

        // Asignar en memoria (después del insert, subsidiaryAcc.Id ya está disponible)
        // El filter de lookup sólo valida en DML, no en asignaciones en memoria
        subsidiaryAcc.participant_id__c = regularParent.Id;

        // El método verá un subsidiario con Id y participant_id__c → parent no es Prospect_Group → 0 relaciones
        Test.startTest();
        DES_ProspectService.createProspectAccountRelationship(new List<Account>{ subsidiaryAcc });
        Test.stopTest();

        final List<AMH_GBL_Account_Relationship__c> rels = [
            SELECT Id FROM AMH_GBL_Account_Relationship__c WHERE AMH_Child_Account__c = :subsidiaryAcc.Id
        ];
        System.assertEquals(0, rels.size(), 'No relationship should be created when parent is not a Prospect_Group');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // populateProspectSubsidiaryCountryFromParent
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void populateProspectSubsidiaryCountryFromParent_noSubsidiary_noOp() {
        // Group account in list → parentIds empty → early return
        final Account groupAcc = [SELECT Id, RecordTypeId FROM Account LIMIT 1];

        Test.startTest();
        DES_ProspectService.populateProspectSubsidiaryCountryFromParent(new List<Account>{ groupAcc });
        Test.stopTest();

        System.assert(true, 'No exception should be thrown when there are no subsidiary accounts');
    }

    @IsTest
    static void populateProspectSubsidiaryCountryFromParent_subsidiaryBlankCountry_inheritsFromParent() {
        // Prospect_Subsidiary with blank country + parent with country → country inherited
        final Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        final DES_UtilTestClass util = new DES_UtilTestClass();

        Account parentAcc = util.createClient();
        parentAcc.RecordTypeId = groupRtId;
        parentAcc.DES_Country_of_Management_OLD__c = 'ES';
        parentAcc.DES_ID_Fiscal__c = 'TEST001';
        insert parentAcc;

        // In-memory subsidiary (simulating before-insert context): blank country, participant_id__c set
        Account subsidiaryAcc = util.createClient();
        subsidiaryAcc.RecordTypeId = subsidiaryRtId;
        subsidiaryAcc.DES_Country_of_Management_OLD__c = null;
        subsidiaryAcc.participant_id__c = parentAcc.Id;

        List<Account> newList = new List<Account>{ subsidiaryAcc };

        Test.startTest();
        DES_ProspectService.populateProspectSubsidiaryCountryFromParent(newList);
        Test.stopTest();

        System.assertEquals('ES', newList[0].DES_Country_of_Management_OLD__c,
            'Subsidiary should inherit DES_Country_of_Management_OLD__c from parent when blank');
    }

    @IsTest
    static void populateProspectSubsidiaryCountryFromParent_subsidiaryAlreadyHasCountry_notOverridden() {
        // Prospect_Subsidiary already has country → must NOT be overridden
        final Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_GROUP).getRecordTypeId();
        final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();

        final DES_UtilTestClass util = new DES_UtilTestClass();

        Account parentAcc = util.createClient();
        parentAcc.RecordTypeId = groupRtId;
        parentAcc.DES_Country_of_Management_OLD__c = 'ES';
        parentAcc.DES_ID_Fiscal__c = 'TEST001';
        insert parentAcc;

        Account subsidiaryAcc = util.createClient();
        subsidiaryAcc.RecordTypeId = subsidiaryRtId;
        subsidiaryAcc.DES_Country_of_Management_OLD__c = 'MX';
        subsidiaryAcc.participant_id__c = parentAcc.Id;

        List<Account> newList = new List<Account>{ subsidiaryAcc };

        Test.startTest();
        DES_ProspectService.populateProspectSubsidiaryCountryFromParent(newList);
        Test.stopTest();

        System.assertEquals('MX', newList[0].DES_Country_of_Management_OLD__c,
            'Subsidiary country should not be overridden when already set');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // applyProspectCountryEntificPrefix
    // ──────────────────────────────────────────────────────────────────────────

    @IsTest
    static void applyProspectCountryEntificPrefix_emptyMap_noOp() {
        // Empty entific map → outer if-block skipped → no update
        DES_ProspectService.countryToEntificMapTestOverride = new Map<String, String>();

        final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();
        final DES_UtilTestClass util = new DES_UtilTestClass();

        Account subsidiaryAcc = util.createClient();
        subsidiaryAcc.RecordTypeId = subsidiaryRtId;
        subsidiaryAcc.DES_Country_of_Management_OLD__c = 'ES';
        subsidiaryAcc.DES_ID_Fiscal__c = 'TEST001';
        insert subsidiaryAcc;

        Test.startTest();
        DES_ProspectService.applyProspectCountryEntificPrefix(new List<Account>{ subsidiaryAcc }, null);
        Test.stopTest();

        final Account result = [SELECT g_customer_id__c FROM Account WHERE Id = :subsidiaryAcc.Id];
        System.assertEquals(null, result.g_customer_id__c,
            'g_customer_id__c should not be set when entific map is empty');
    }

    @IsTest
    static void applyProspectCountryEntificPrefix_nonSubsidiaryRT_skipped() {
        // Group account → RecordTypeId != subsidiaryRtId → continue (skip)
        DES_ProspectService.countryToEntificMapTestOverride = new Map<String, String>{ 'ES' => 'ES' };

        final Account groupAcc = [SELECT Id, RecordTypeId, g_customer_id__c FROM Account LIMIT 1];

        Test.startTest();
        DES_ProspectService.applyProspectCountryEntificPrefix(new List<Account>{ groupAcc }, null);
        Test.stopTest();

        System.assertEquals(null, groupAcc.g_customer_id__c,
            'Non-subsidiary accounts should be skipped');
    }

    @IsTest
    static void applyProspectCountryEntificPrefix_blankCountryOrSequence_skipped() {
        // Accounts missing country or sequence → skipped (String.isBlank guard)
        DES_ProspectService.countryToEntificMapTestOverride = new Map<String, String>{ 'ES' => 'ES' };

        final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();
        final DES_UtilTestClass util = new DES_UtilTestClass();

        Account noCountry = util.createClient();
        noCountry.RecordTypeId = subsidiaryRtId;

        Account noSequence = util.createClient();
        noSequence.RecordTypeId = subsidiaryRtId;
        noSequence.DES_Country_of_Management_OLD__c = 'ES';

        Test.startTest();
        DES_ProspectService.applyProspectCountryEntificPrefix(
            new List<Account>{ noCountry, noSequence }, null);
        Test.stopTest();

        System.assertEquals(null, noCountry.g_customer_id__c,  'Account without country should be skipped');
        System.assertEquals(null, noSequence.g_customer_id__c, 'Account without sequence should be skipped');
    }

    @IsTest
    static void applyProspectCountryEntificPrefix_countryUnchangedOnUpdate_skipped() {
        // Old country == new country → continue (skip)
        DES_ProspectService.countryToEntificMapTestOverride = new Map<String, String>{ 'ES' => 'ES' };

        final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();
        final DES_UtilTestClass util = new DES_UtilTestClass();

        Account subsidiaryAcc = util.createClient();
        subsidiaryAcc.RecordTypeId = subsidiaryRtId;
        subsidiaryAcc.DES_Country_of_Management_OLD__c = 'ES';
        subsidiaryAcc.DES_ID_Fiscal__c = 'TEST001';
        insert subsidiaryAcc;

        Account oldAcc = subsidiaryAcc.clone(true, true, false, false);
        oldAcc.DES_Country_of_Management_OLD__c = 'ES';

        List<Account> accountList = new List<Account>{ subsidiaryAcc };

        Test.startTest();
        DES_ProspectService.applyProspectCountryEntificPrefix(
            accountList, new Map<Id, Account>{ subsidiaryAcc.Id => oldAcc });
        Test.stopTest();

        // In-memory value must not be modified when country is unchanged
        System.assertEquals(null, accountList[0].g_customer_id__c,
            'g_customer_id__c should not change when country is unchanged on update');
    }

    @IsTest
    static void applyProspectCountryEntificPrefix_withValidMapping_setsCustomerIdInMemory() {
        // El trigger before-update llama a applyProspectCountryEntificPrefix con Trigger.isAfter = false
        // → rama else → modificación en memoria → Salesforce la persiste al ser before-trigger
        final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();
        final DES_UtilTestClass util = new DES_UtilTestClass();

        // Map vacío durante el insert → after-insert no establece g_customer_id__c
        DES_ProspectService.countryToEntificMapTestOverride = new Map<String, String>();
        Account subsidiaryAcc = util.createClient();
        subsidiaryAcc.RecordTypeId = subsidiaryRtId;
        subsidiaryAcc.DES_ID_Fiscal__c = 'TEST001';
        insert subsidiaryAcc;

        // Inyectar el mapeado antes del update
        DES_ProspectService.countryToEntificMapTestOverride = new Map<String, String>{ 'ES' => 'ES' };

        Test.startTest();
        // Cambiar el país de null a 'ES' → before-update: old(null) != new('ES') → no skip → rama else
        subsidiaryAcc.DES_Country_of_Management_OLD__c = 'ES';
        update subsidiaryAcc;
        Test.stopTest();

        // El trigger before-update fijó g_customer_id__c = 'ES' + 'P' + DES_Sequence__c en memoria y Salesforce lo persiste
        final Account result = [SELECT g_customer_id__c, DES_Sequence__c FROM Account WHERE Id = :subsidiaryAcc.Id];
        // extractAlphabeticPrefix('ES') = 'ES' → 'ES' + 'P' + DES_Sequence__c
        System.assertEquals('ES' + 'P' + result.DES_Sequence__c, result.g_customer_id__c,
            'g_customer_id__c debe fijarse en la modificación en memoria del trigger before-update');
    }

    @IsTest
    static void applyProspectCountryEntificPrefix_blankPrefix_noUpdate() {
        // Entific value starts with a digit → extractAlphabeticPrefix returns blank → g_customer_id__c not set
        DES_ProspectService.countryToEntificMapTestOverride = new Map<String, String>{ 'ES' => '12345' };

        final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();
        final DES_UtilTestClass util = new DES_UtilTestClass();

        Account subsidiaryAcc = util.createClient();
        subsidiaryAcc.RecordTypeId = subsidiaryRtId;
        subsidiaryAcc.DES_Country_of_Management_OLD__c = 'ES';
        subsidiaryAcc.DES_ID_Fiscal__c = 'TEST001';
        insert subsidiaryAcc;

        // Reload to include the auto-number DES_Sequence__c so the method's blank-prefix guard is reached
        subsidiaryAcc = [SELECT Id, RecordTypeId, DES_Country_of_Management_OLD__c, DES_Sequence__c, g_customer_id__c FROM Account WHERE Id = :subsidiaryAcc.Id];

        List<Account> accountList = new List<Account>{ subsidiaryAcc };

        Test.startTest();
        DES_ProspectService.applyProspectCountryEntificPrefix(accountList, null);
        Test.stopTest();

        System.assertEquals(null, accountList[0].g_customer_id__c,
            'g_customer_id__c should not be set when the entific prefix extracted is blank');
    }

    @IsTest
    static void applyProspectCountryEntificPrefix_viaInsertTrigger_setsCustomerIdViaDML() {
        // After-insert trigger path (Trigger.isAfter = true) → DML update branch
        DES_ProspectService.countryToEntificMapTestOverride = new Map<String, String>{ 'ES' => 'ES' };

        final Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(DES_Constants.ACCOUNT_RT_PROSPECT_SUBSIDIARY).getRecordTypeId();
        final DES_UtilTestClass util = new DES_UtilTestClass();

        Account subsidiaryAcc = util.createClient();
        subsidiaryAcc.RecordTypeId = subsidiaryRtId;
        subsidiaryAcc.DES_Country_of_Management_OLD__c = 'ES';
        subsidiaryAcc.DES_ID_Fiscal__c = 'TEST001';

        Test.startTest();
        insert subsidiaryAcc;
        Test.stopTest();

        final Account result = [SELECT g_customer_id__c, DES_Sequence__c FROM Account WHERE Id = :subsidiaryAcc.Id];
        System.assertEquals('ES' + 'P' + result.DES_Sequence__c, result.g_customer_id__c,
            'g_customer_id__c should be set to prefix+P+sequence via DML update in after-insert trigger context');
    }
}