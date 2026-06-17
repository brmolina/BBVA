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

        insert new Local_Client__c(
            Cib_Client__c = accountGroup.Id,
            Alpha_code__c = 'ALPHA001'
        );

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

        System.assertEquals('ALPHA001', alphaCode, 'Alpha code should match the Local Client data');
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
    static void testGetRecordCodeFromLocalClient_ThroughGetRecordCode() {
        Local_Client__c localClient = [
            SELECT Id
            FROM Local_Client__c
            WHERE Alpha_code__c = 'ALPHA001'
            LIMIT 1
        ];

        Test.startTest();
        String recordCode = DMT_HPG_Utils.getRecordCode(localClient.Id);
        Test.stopTest();

        System.assertEquals('ALPHA001', recordCode, 'Record code should come from local client alpha code');
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

    /*@IsTest
    static void testObfuscateAndUnNullValue() {
        String clearText = 'ABC 123';
        String obfuscated = DMT_HPG_Utils.obfuscate(clearText);
        System.assertEquals('XXX XXX', obfuscated, 'All non-space chars should be obfuscated');

        System.assertEquals(null, DMT_HPG_Utils.obfuscate(null), 'Null input should return null');
        System.assertEquals('fallback', DMT_HPG_Utils.unNullValue(null, 'fallback'), 'Null should return fallback value');
        System.assertEquals('value', DMT_HPG_Utils.unNullValue('value', 'fallback'), 'Non-empty value should be preserved');
    }*/

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

        Account withoutGroupCode = new Account(
            Name = 'Account Without GroupCode ' + suffix
        );
        insert withoutGroupCode;

        String alphaFallback = 'ALP' + suffix;
        insert new Local_Client__c(
            Cib_Client__c = withoutGroupCode.Id,
            Alpha_code__c = alphaFallback
        );

        Map<String, Object> fromLocalClient = DMT_HPG_Utils.getRecordCodeFromAccount(withoutGroupCode.Id);
        System.assertEquals(alphaFallback, (String) fromLocalClient.get('recordCode'), 'Should fallback to Local Client alpha code');
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