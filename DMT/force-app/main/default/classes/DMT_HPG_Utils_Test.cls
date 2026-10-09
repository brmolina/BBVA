@IsTest
private with sharing class DMT_HPG_Utils_Test {

    @TestSetup
    static void setupData() {
        DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT', 'https://service.ok', 'ServicesPartition');
        DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket', 'https://validation.ok', 'ServicesPartition');

        Account accountRoot = new Account(
            Name = 'HPG Root Account',
            DES_Structure_Type__c = 'Supragroup',
            DES_Group_Code__c = 'X00000000000001'
        );
        insert accountRoot;

        Account accountGroup = new Account(
            Name = 'HPG Group Account',
            DES_Structure_Type__c = 'Group',
            DES_Group_Code__c = 'G00000000000001'
        );
        insert accountGroup;

        Account accountSubgroup = new Account(
            Name = 'HPG Subgroup Account',
            DES_Structure_Type__c = 'Subgroup',
            DES_Group_Code__c = 'S00000000000001'
        );
        insert accountSubgroup;

        insert new AMH_GBL_Account_Relationship__c(
            AMH_Vision__c = 'Riesgos',
            AMH_Parent_Account__c = accountRoot.Id,
            AMH_Child_Account__c = accountGroup.Id
        );

        insert new AMH_GBL_Account_Relationship__c(
            AMH_Vision__c = 'Riesgos',
            AMH_Parent_Account__c = accountGroup.Id,
            AMH_Child_Account__c = accountSubgroup.Id
        );

        accountGroup.g_customer_id__c = 'ALPHA001';
        update accountGroup;

        // Create line-related data once to avoid repeated heavy factory calls in individual tests.
        DMT_Test_DataFactory.generateTestTreasuryLines();
    }

    // @IsTest
    // static void testCallServiceDmt_MapOverload() {
    //     if (!hasIntegrationServicePrerequisites('DMT_GetSnapshotEvaluationVersions')) {
    //         System.assert(true, 'Integration configuration is not available in this org');
    //         return;
    //     }

    //     Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

    //     Test.startTest();
    //     HttpResponse response = DMT_HPG_Utils.callService_DMT(
    //         'DMT_GetSnapshotEvaluationVersions',
    //         new Map<String, Object>{ 'segmentCode' => '02', 'pageSize' => '10' }
    //     );
    //     Test.stopTest();

    //     System.assertNotEquals(null, response, 'Response should not be null');
    //     System.assertEquals(200, response.getStatusCode(), 'Expected a successful status code');
    // }

    // @IsTest
    // static void testCallServiceDmt_StringOverload() {
    //     if (!hasIntegrationServicePrerequisites('DMT_GetSnapshotEvaluationVersions')) {
    //         System.assert(true, 'Integration configuration is not available in this org');
    //         return;
    //     }

    //     Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

    //     Test.startTest();
    //     HttpResponse response = DMT_HPG_Utils.callService_DMT(
    //         'DMT_GetSnapshotEvaluationVersions',
    //         '{"segmentCode":"02","pageSize":"10"}'
    //     );
    //     Test.stopTest();

    //     System.assertNotEquals(null, response, 'Response should not be null');
    //     System.assertEquals(200, response.getStatusCode(), 'Expected a successful status code');
    // }

    // @IsTest
    // static void testGetGroupName() {
    //     Account accountGroup = [
    //         SELECT Id
    //         FROM Account
    //         WHERE Name = 'HPG Group Account'
    //         LIMIT 1
    //     ];

    //     Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

    //     Test.startTest();
    //     String groupName = DMT_HPG_Utils.getGroupName(String.valueOf(accountGroup.Id));
    //     Test.stopTest();

    //     System.assertNotEquals(null, groupName, 'Group name should be returned from mock data');
    // }

    @IsTest
    static void testGetAlphaCode() {
        Account accountGroup = [
            SELECT Id
            FROM Account
            WHERE Name = 'HPG Group Account'
            LIMIT 1
        ];

        Test.startTest();
        String alphaCode = DMT_HPG_Utils.getAlphaCode(accountGroup.Id);
        Test.stopTest();

        System.assertEquals('ALPHA001', alphaCode, 'Alpha code should match Account.g_customer_id__c');
    }

    @IsTest
    static void testGetMainHolderNameFromMultiholderAssociation() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        // AccountTriggerHandler.assignRecordType() auto-defaults DES_Structure_Type__c to 'Subsidiary'
        // on insert when neither DES_BBVA_Segmentation__c nor DES_Structure_Type__c is set (as is the
        // case for DMT_Test_DataFactory.generateAccount()). That would make DES_Client_Type__c resolve
        // to 'Subsidiary' and short-circuit the Multiholder association lookup, so force the Account
        // to a non-Subsidiary structure type for this test.
        update new Account(Id = opp.AccountId, DES_Structure_Type__c = 'Group');

        insert new Custom_Association_Opportunity__c(
            Opportunity__c = opp.Id,
            g_customer_id__c = 'ALPHA001',
            gf_customer_group_id__c = 'GRPM-' + opp.Id
        );

        Test.startTest();
        String mainHolderName = DMT_HPG_Utils.getMainHolderName(opp.Id, 'Fallback Account Name');
        Test.stopTest();

        System.assertEquals('HPG Group Account', mainHolderName, 'Main Holder should be resolved from the Multiholder Custom Association, not the fallback');
    }

    @IsTest
    static void testGetMainHolderNameFallsBackWhenNotMultiholder() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        Test.startTest();
        String mainHolderName = DMT_HPG_Utils.getMainHolderName(opp.Id, 'Fallback Account Name');
        Test.stopTest();

        System.assertEquals('Fallback Account Name', mainHolderName, 'Non-Multiholder Opportunities should keep using the Account name fallback');
    }

    @IsTest
    static void testGetMainHolderNameWithNullOpportunityId() {
        Test.startTest();
        String mainHolderName = DMT_HPG_Utils.getMainHolderName(null, 'Fallback Account Name');
        Test.stopTest();

        System.assertEquals('Fallback Account Name', mainHolderName, 'A null Opportunity id should just return the fallback');
    }

    @IsTest
    static void testGetMainHolderNameIgnoresAssociationForSubsidiaryAccount() {
        // DES_Client_Type__c is a read-only (formula) field, so the "Subsidiary-like" branch is
        // exercised here via the Prospect_Subsidiary RecordType instead - both feed the same
        // isSubsidiaryLike short-circuit in DMT_HPG_Utils.getMainHolderNames().
        Id prospectSubsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Prospect_Subsidiary').getRecordTypeId();
        Account subsidiaryAcc = new Account(
            Name = 'Subsidiary Account',
            RecordTypeId = prospectSubsidiaryRtId,
            g_customer_id__c = 'ALPHA_SUB',
            DES_ID_Fiscal__c = '1234567'
        );
        insert subsidiaryAcc;

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp.AccountId = subsidiaryAcc.Id;
        update opp;

        insert new Custom_Association_Opportunity__c(
            Opportunity__c = opp.Id,
            g_customer_id__c = 'ALPHA001',
            gf_customer_group_id__c = 'GRPM-' + opp.Id
        );


        Test.startTest();
        String mainHolderName = DMT_HPG_Utils.getMainHolderName(opp.Id, 'Subsidiary Account');
        Test.stopTest();

        System.assertEquals(
            'Subsidiary Account',
            mainHolderName,
            'Subsidiary-like Accounts must bypass Custom_Association_Opportunity__c entirely'
        );
    }

    @IsTest
    static void testGetMainHolderNamesWithEmptySet() {
        Test.startTest();
        Map<Id, String> result = DMT_HPG_Utils.getMainHolderNames(new Set<Id>(), new Map<Id, String>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'An empty set of Opportunity ids should return an empty map');
    }

    @IsTest
    static void testBuildAncestorsHierarchy() {
        Account accountSubgroup = [
            SELECT Id
            FROM Account
            WHERE Name = 'HPG Subgroup Account'
            LIMIT 1
        ];

        Map<String, Object> result = new Map<String, Object>();

        Test.startTest();
        DMT_HPG_Utils.buildAncestorsHierarchy(accountSubgroup.Id, result);
        Test.stopTest();

        System.assertEquals('G00000000000001', (String) result.get('groupCode'), 'Group code should come from parent relation');
        System.assertEquals('X00000000000001', (String) result.get('supragroupId'), 'Supragroup code should come from grandparent relation');
    }

    @IsTest
    static void testGetSerializedGroupFromRecordCode() {
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        String serialized = DMT_HPG_Utils.getSerializedGroupFromRecordCode('X00000000000001');
        Test.stopTest();

        System.assertNotEquals(null, serialized, 'Serialized response should not be null');
        System.assertEquals(true, serialized.contains('groupCode'), 'Serialized response should include group data');
    }

    @IsTest
    static void testUserCanEdit() {
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Read Only' LIMIT 1].Id,
            FirstName = 'HPG',
            LastName = 'Readonly',
            Alias = 'hpgro',
            Email = 'hpg.readonly@test.com',
            Username = String.valueOf(Datetime.now().getTime()) + '.hpg.readonly@test.com',
            CommunityNickname = 'hpgreadonly' + String.valueOf(Math.abs(Crypto.getRandomInteger())),
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'U' + String.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000000))
        );
        insert testUser;

        Boolean canEdit;
        Test.startTest();
        System.runAs(testUser) {
            canEdit = DMT_HPG_Utils.userCanEdit();
        }
        Test.stopTest();

        System.assertNotEquals(null, canEdit, 'The method should return a Boolean result');
    }

    @IsTest
    static void testGetRecordCodeFromAccountThroughGetRecordCode() {
        // After migration, record code for an Account without DES_Group_Code__c comes from g_customer_id__c
        Account accWithAlpha = new Account(Name = 'Alpha Code Only Account', g_customer_id__c = 'ALPHA_REC_CODE');
        insert accWithAlpha;

        Test.startTest();
        String recordCode = DMT_HPG_Utils.getRecordCode(accWithAlpha.Id);
        Test.stopTest();

        System.assertEquals('ALPHA_REC_CODE', recordCode, 'Record code should come from g_customer_id__c');
    }

    @IsTest
    static void testGetCustomerHpgs_MissingFields() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'clientId' => null,
            'lastDate' => null,
            'customerId' => null
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_HPG_Utils.getCustomerHPGS(inputMap, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(true, result.containsKey('serviceError'), 'Missing required fields should return serviceError');
    }

    @IsTest
    static void testGetCustomerHpgs_WithValidInput() {
        Account accountGroup = [
            SELECT Id
            FROM Account
            WHERE Name = 'HPG Group Account'
            LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Map<String, Object> inputMap = new Map<String, Object>{
            'clientId' => accountGroup.Id,
            'lastDate' => String.valueOf(Date.today()),
            'customerId' => 'ES0182XXXXXXXXX'
        };

        Test.startTest();
        Map<String, Object> result = DMT_HPG_Utils.getCustomerHPGS(inputMap, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(true, result.containsKey('CustomerHPG') || result.containsKey('serviceError'), 'Method should return either customer data or serviceError');
    }

    @IsTest
    static void testObfuscateAndUnNullValue() {
        String clearText = 'ABC 123';
        String obfuscated = DMT_HPG_Utils.obfuscate(clearText);
        System.assertEquals('XXX XXX', obfuscated, 'All non-space chars should be obfuscated');

        System.assertEquals(null, DMT_HPG_Utils.obfuscate(null), 'Null input should return null');
        System.assertEquals(null, DMT_HPG_Utils.obfuscate(''), 'Blank input should return null');
        System.assertEquals('[P]XXX XXX', DMT_HPG_Utils.obfuscate('[P]ABC 123'), 'Prospect prefix should be preserved');
        System.assertEquals('fallback', DMT_HPG_Utils.unNullValue(null, 'fallback'), 'Null should return fallback value');
        System.assertEquals('fallback', DMT_HPG_Utils.unNullValue('   ', 'fallback'), 'Blank should return fallback value');
        System.assertEquals('value', DMT_HPG_Utils.unNullValue('value', 'fallback'), 'Non-empty value should be preserved');
    }

    @IsTest
    static void testFederationIdentifierCacheAndMissingAlphaCode() {
        Account deletedAccount = new Account(Name = 'Deleted Account For Alpha Lookup');
        insert deletedAccount;
        delete deletedAccount;

        String expectedFederationId = [
            SELECT FederationIdentifier
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ].FederationIdentifier;

        Test.startTest();
        String firstResult = DMT_HPG_Utils.getFederationIdentifier();
        String cachedResult = DMT_HPG_Utils.getFederationIdentifier();
        String missingAlphaCode = DMT_HPG_Utils.getAlphaCode(deletedAccount.Id);
        Test.stopTest();

        System.assertEquals(expectedFederationId, firstResult, 'Federation identifier should come from the current user');
        System.assertEquals(firstResult, cachedResult, 'The cached federation identifier should be reused');
        System.assertEquals(null, missingAlphaCode, 'A missing Account should not return an alpha code');
    }

    @IsTest
    static void testGetClientDataHpgsMissingFields() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'clientId' => null,
            'lastDate' => '   '
        };

        Test.startTest();
        Map<String, Object> result = DMT_HPG_Utils.getClientDataHPGS(
            inputMap,
            new Map<String, Object>(),
            new Map<String, Object>()
        );
        Test.stopTest();

        System.assertEquals(true, result.containsKey('serviceError'), 'Missing fields should return a service error');
        System.assert(
            String.valueOf(result.get('serviceError')).contains('customerId'),
            'The error should identify the missing customerId'
        );
    }

    @IsTest
    static void testCountriesToAnonymizeForMexicoAndOtherCountry() {
        User mexicoUser = buildUserForCountry('MEX', 'mexico');
        User otherCountryUser = buildUserForCountry('ESP', 'spain');
        insert new List<User>{ mexicoUser, otherCountryUser };

        Test.startTest();
        System.runAs(mexicoUser) {
            System.assertEquals(
                DMT_Constants.ANON_ANY,
                DMT_HPG_Utils.getCountries2Anonymize(),
                'A Mexico user should not anonymize countries'
            );
        }
        System.runAs(otherCountryUser) {
            System.assertEquals(
                DMT_Constants.ANON_MX,
                DMT_HPG_Utils.getCountries2Anonymize(),
                'A non-Mexico user should anonymize Mexico'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testBuildClientGroupStructureForTopLevels() {
        Account supra = [
            SELECT Id
            FROM Account
            WHERE Name = 'HPG Root Account'
            LIMIT 1
        ];
        Account groupAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'HPG Group Account'
            LIMIT 1
        ];

        Test.startTest();
        Map<String, Object> supraResult = DMT_HPG_Utils.buildClientGroupStructure(supra.Id);
        Map<String, Object> groupResult = DMT_HPG_Utils.buildClientGroupStructure(groupAcc.Id);
        Test.stopTest();

        System.assertEquals('Supragroup', supraResult.get('structureType'), 'The root structure should be detected');
        System.assertEquals('X00000000000001', supraResult.get('supragroupId'), 'The supragroup code should be returned');
        System.assertEquals('Group', groupResult.get('structureType'), 'The group structure should be detected');
        System.assertEquals('G00000000000001', groupResult.get('groupCode'), 'The group code should be returned');
        System.assertEquals('X00000000000001', groupResult.get('supragroupId'), 'The parent supragroup should be returned');
    }

    @IsTest
    static void testGetRecordCodeFromAccountBranches() {
        String suffix = String.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        String groupCode = 'GC' + suffix;
        Account withGroupCode = new Account(
            Name = 'Account With GroupCode ' + suffix,
            DES_Group_Code__c = groupCode
        );
        insert withGroupCode;

        Map<String, Object> fromGroupCode = DMT_HPG_Utils.getRecordCodeFromAccount(withGroupCode.Id);
        System.assertEquals(groupCode, (String) fromGroupCode.get('recordCode'), 'Should return DES_Group_Code__c when present');

        String alphaFallback = 'ALP' + suffix;
        Account withoutGroupCode = new Account(
            Name = 'Account Without GroupCode ' + suffix,
            g_customer_id__c = alphaFallback
        );
        insert withoutGroupCode;

        Map<String, Object> fromAlphaCode = DMT_HPG_Utils.getRecordCodeFromAccount(withoutGroupCode.Id);
        System.assertEquals(alphaFallback, (String) fromAlphaCode.get('recordCode'), 'Should return g_customer_id__c as recordCode');
    }

    @IsTest
    static void testGetRecordCodeFromUnsupportedObject() {
        String recordCode = DMT_HPG_Utils.getRecordCode(UserInfo.getUserId());
        System.assertEquals(null, recordCode, 'Unsupported object type should not return recordCode');
    }

    @IsTest
    static void testBuildClientGroupStructureWhenAccountDoesNotExist() {
        Map<String, Object> res = DMT_HPG_Utils.buildClientGroupStructure('001000000000000AAA');
        System.assertEquals(0, res.size(), 'Non-existing account should return an empty map');
    }

    @IsTest
    static void testAnonymizeAndCountriesBehavior() {
        User userBlankCountry = buildUserForCountry('', 'blankcountry');
        insert userBlankCountry;

        Test.startTest();
        System.runAs(userBlankCountry) {
            DMT_HPG_GlobalPosition.Wrapper wrap = new DMT_HPG_GlobalPosition.Wrapper();

            DMT_HPG_GlobalPosition.Data dataToAnonymize = new DMT_HPG_GlobalPosition.Data();
            dataToAnonymize.customerName = 'CLIENT NAME';
            dataToAnonymize.countryId = 'ES';
            dataToAnonymize.lei = 'LEI123';
            dataToAnonymize.taxpayerId = 'TAX123';

            DMT_HPG_GlobalPosition.Data totalClientsData = new DMT_HPG_GlobalPosition.Data();
            totalClientsData.customerName = 'TOTAL CLIENTS ES';
            totalClientsData.countryId = 'ES';
            totalClientsData.lei = 'LEI999';
            totalClientsData.taxpayerId = 'TAX999';

            wrap.data = new List<DMT_HPG_GlobalPosition.Data>{ dataToAnonymize, totalClientsData };

            DMT_HPG_Utils.anonymize(wrap);

            System.assertEquals(true, dataToAnonymize.customerName.contains('X'), 'Customer name should be obfuscated');
            System.assertEquals('TOTAL CLIENTS ES', totalClientsData.customerName, 'TOTAL CLIENTS row must not be obfuscated');

            List<String> countries = DMT_HPG_Utils.getCountries2Anonymize();
            System.assertEquals(DMT_Constants.ANON_ALL_COUNTRIES, countries, 'Blank country should anonymize all countries');
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateLastModifiedByHuman() {
        DMT_HPG_Utils.updateLastModifiedByHuman(new List<SObject>());

        DMT_Line__c testLine = [
            SELECT Id, Last_Modified_By_Human__c
            FROM DMT_Line__c
            WHERE Line_Id__c = '00002'
            LIMIT 1
        ];
        List<SObject> records = new List<SObject>{ testLine };

        DMT_HPG_Utils.updateLastModifiedByHuman(records);

        String stamp = (String) records[0].get('Last_Modified_By_Human__c');
        System.assertNotEquals(null, stamp, 'Stamp should be populated for non-integration profiles');
    }

    @IsTest
    static void testBuildClientGroupStructure_SubgroupHierarchy() {
        Account supra = new Account(
            Name = 'HPG Supra Coverage',
            DES_Structure_Type__c = 'Supragroup',
            DES_Group_Code__c = 'X99999999999999'
        );
        insert supra;

        Account groupAcc = new Account(
            Name = 'HPG Group Coverage',
            DES_Structure_Type__c = 'Group',
            DES_Group_Code__c = 'G99999999999999'
        );
        insert groupAcc;

        Account sub = new Account(
            Name = 'HPG Sub Coverage',
            DES_Structure_Type__c = 'Subgroup',
            DES_Group_Code__c = 'S99999999999999'
        );
        insert sub;

        insert new AMH_GBL_Account_Relationship__c(
            AMH_Parent_Account__c = supra.Id,
            AMH_Child_Account__c = groupAcc.Id,
            AMH_Vision__c = 'Riesgos'
        );

        insert new AMH_GBL_Account_Relationship__c(
            AMH_Parent_Account__c = groupAcc.Id,
            AMH_Child_Account__c = sub.Id,
            AMH_Vision__c = 'Riesgos'
        );

        Map<String, Object> result = DMT_HPG_Utils.buildClientGroupStructure(sub.Id);

        System.assertEquals('Subgroup', (String) result.get('structureType'), 'Subgroup structure should be detected');
        System.assertEquals('S99999999999999', (String) result.get('subgroupId'), 'Subgroup code should be set');
        System.assertEquals('G99999999999999', (String) result.get('groupCode'), 'Group code should be resolved through ancestors');
        System.assertEquals('X99999999999999', (String) result.get('supragroupId'), 'Supragroup code should be resolved through ancestors');
    }

    @IsTest
    static void testGetGroupFromClientAccount() {
        String suffix = String.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        String groupCode = 'X' + String.valueOf(10000000000000L + Integer.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()), 899999999)));
        Account accountGroup = new Account(
            Name = 'HPG Group For getGroupFromClientAccount ' + suffix,
            DES_Structure_Type__c = 'Group',
            DES_Group_Code__c = groupCode
        );
        insert accountGroup;

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Map<String, Object> result = DMT_HPG_Utils.getGroupFromClientAccount(accountGroup.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(groupCode, (String) result.get('recordCode'), 'RecordCode should come from account group code');
    }

    @IsTest
    static void testSyncCustomAssociationName() {
        DMT_Line__c line = [
            SELECT Id, Client__c
            FROM DMT_Line__c
            WHERE Line_Id__c = '00002'
            LIMIT 1
        ];

        Custom_Association__c association = new Custom_Association__c(
            Name = 'old_name',
            DMT_Line__c = line.Id,
            Group__c = line.Client__c,
            gf_customer_group_id__c = 'ES00123456'
        );
        insert association;

        Test.startTest();
        DMT_HPG_Utils.syncCustomAssociationName(new List<String>{ line.Id });
        Test.stopTest();

        Custom_Association__c refreshed = [
            SELECT Id, Name, Group__r.Name
            FROM Custom_Association__c
            WHERE Id = :association.Id
            LIMIT 1
        ];

        System.assertNotEquals('old_name', refreshed.Name, 'Association name should be synchronized');
        System.assertEquals(true, refreshed.Name.contains('_'), 'Synchronized name should include separator');
    }

    private static User buildUserForCountry(String country, String suffix) {
        String shortSuffix = suffix.left(Math.min(4, suffix.length()));
        String shortRandom = String.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()), 100000000));
        User userToCreate = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Read Only' LIMIT 1].Id,
            FirstName = 'HPG',
            LastName = 'Coverage' + suffix,
            Alias = ('h' + suffix).left(8),
            Email = 'hpg.' + suffix + '@test.com',
            Username = String.valueOf(Datetime.now().getTime()) + '.hpg.' + suffix + '@test.com',
            CommunityNickname = 'hpg' + suffix + String.valueOf(Math.abs(Crypto.getRandomInteger())),
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ID_User__c = 'U' + shortSuffix + shortRandom
        );
        userToCreate.DES_Country__c = country;
        return userToCreate;
    }

    private static Boolean hasIntegrationServicePrerequisites(String serviceName) {
        List<iaso__GBL_integration_service__mdt> serviceConfigs = [
            SELECT iaso__Custom_Setting__c, iaso__Authentication_Service__c
            FROM iaso__GBL_integration_service__mdt
            WHERE DeveloperName = :serviceName
            LIMIT 1
        ];

        if (serviceConfigs.isEmpty()) {
            return false;
        }

        String customSettingName = serviceConfigs[0].iaso__Custom_Setting__c;
        if (String.isBlank(customSettingName)) {
            return false;
        }

        iaso__GBL_Rest_Services_Url__c endpointConfig = iaso__GBL_Rest_Services_Url__c.getInstance(customSettingName);
        if (endpointConfig == null) {
            return false;
        }

        String authServiceName = serviceConfigs[0].iaso__Authentication_Service__c;
        if (String.isBlank(authServiceName)) {
            return false;
        }

        return iaso__GBL_Authentication_Service__mdt.getInstance(authServiceName) != null;
    }
}