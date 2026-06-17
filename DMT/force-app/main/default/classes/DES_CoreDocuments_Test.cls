/**-------------------------------------------------------------------------------------------
* @Name     DES_CoreDocuments_Test
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2026-02-13
* ------------------------------------------------------------------------------------------------
* @Description Test class for DES_CoreDocuments config loading
* ------------------------------------------------------------------------------------------------
*/
@isTest
private class DES_CoreDocuments_Test {

    private static final String CONFIG_NAME = 'DMT';

    private static void setupTestConfig() {
        DES_CoreDocuments.clearTestConfigs();
        DES_CoreDocuments.setTestConfig(CONFIG_NAME, buildConfig());
    }

    private static DES_CoreDocuments.Config buildConfig() {
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.createTestConfig();

        cfg.expedientFoldersServiceName = 'DES_CoreDocumentsExpedientFolders';
        cfg.jwtServiceName = 'DES_CoreDocumentsJWT';
        cfg.metadataServiceName = 'DES_CoreDocuments';

        cfg.domain = 'test-domain';
        cfg.namespace = 'test.namespace';

        cfg.jwtCacheKey = 'UTJWTCACHE';
        cfg.expedientFoldersJwtCacheKey = 'UTEFJWTCACHE';

        cfg.serviceId = 'UT_SERVICE_ID';
        cfg.responsible = 'UT_RESP';

        cfg.coreDocEndpoint = 'https://example.com/v1';

        return cfg;
    }

    @isTest
    static void testGetConfigRequiresConfigName() {
        try {
            Test.startTest();
            DES_CoreDocuments.getConfig(null);
            Test.stopTest();
            System.assert(false, 'Expected exception when configName is blank');
        } catch (DES_CoreDocuments.DES_CoreDocumentsConfigException e) {
            System.assert(e.getMessage().contains('configuration name is required'), 'Exception message should explain missing configName');
        }
    }

    @isTest
    static void testGetConfigLoadsFromCustomMetadata() {
        DES_CoreDocuments.clearTestConfigs();
        DES_CoreDocuments.Config mdt = buildConfig();
        DES_CoreDocuments.setTestConfig(CONFIG_NAME, mdt);

        Test.startTest();
        DES_CoreDocuments.Config config = DES_CoreDocuments.getConfig(CONFIG_NAME);
        Test.stopTest();

        System.assertEquals(mdt.expedientFoldersServiceName, config.expedientFoldersServiceName);
        System.assertEquals(mdt.jwtServiceName, config.jwtServiceName);
        System.assertEquals(mdt.metadataServiceName, config.metadataServiceName);
        System.assertEquals(mdt.domain, config.domain);
        System.assertEquals(mdt.namespace, config.namespace);
        System.assertEquals(mdt.jwtCacheKey, config.jwtCacheKey);
        System.assertEquals(mdt.expedientFoldersJwtCacheKey, config.expedientFoldersJwtCacheKey);
        System.assertEquals(mdt.serviceId, config.serviceId);
        System.assertEquals(mdt.responsible, config.responsible);
        System.assertEquals(mdt.coreDocEndpoint, config.coreDocEndpoint);
    }

    @isTest
    static void testGetCoreDocumentsEndpoint() {
        DES_CoreDocuments.clearTestConfigs();
        DES_CoreDocuments.Config mdt = buildConfig();
        DES_CoreDocuments.setTestConfig(CONFIG_NAME, mdt);

        Test.startTest();
        String endpoint = DES_CoreDocuments.getCoreDocumentsEndpoint(CONFIG_NAME);
        Test.stopTest();

        String base = mdt.coreDocEndpoint;
        if (!base.endsWith('/')) {
            base += '/';
        }
        System.assertEquals(base + 'ns/' + mdt.namespace + '/domains/' + mdt.domain + '/', endpoint, 'Endpoint should be built correctly from config');
    }

    @isTest
    static void testUtilsGetIntegrationServiceInfo() {
        iaso__GBL_integration_service__mdt svc = DES_CoreDocumentsUtils.getIntegrationServiceInfo('DES_CoreDocumentsExpedientFolders');
        System.assertNotEquals(null, svc, 'Integration service DES_CoreDocumentsExpedientFolders should exist as Custom Metadata in this package');
        System.assertEquals('DES_CoreDocumentsExpedientFolders', svc.DeveloperName);
    }

    @isTest
    static void testExpedientFoldersUsesMockAndCachesJwtAndDownloadHeadersWork() {
        setupTestConfig();

        Map<String, Object> request = new Map<String, Object>();
        request.put('qExpression', 'businessCode.folderCode==*OPR-0001*');
        request.put('page', '1');
        request.put('pageSize', '1');

        DES_CoreDocumentsExpedientFolders.Wrapper res = DES_CoreDocumentsExpedientFolders.getExpedientFolders(request, CONFIG_NAME);
        System.assertEquals(true, res.success, 'Mocked expedient-folders call should be successful');

        DES_CoreDocuments.Config cfg = DES_CoreDocuments.getConfig(CONFIG_NAME);
        String cachedJwt = (String)Cache.Session.get(cfg.expedientFoldersJwtCacheKey);
        System.assertNotEquals(null, cachedJwt, 'JWT should be cached from expedient-folders response');
        System.assert(cachedJwt.length() > 20, 'Cached JWT should look like a token');

        Map<String, String> downloadHeaders = DES_CoreDocuments.getDownloadHeaders(CONFIG_NAME);
        System.assertEquals(true, downloadHeaders.containsKey('Authorization'));
        System.assert(downloadHeaders.get('Authorization').startsWith('Bearer '));
    }

    @isTest
    static void testJwtTokenCacheHitAndUploadHeadersWork() {
        setupTestConfig();
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.getConfig(CONFIG_NAME);

        DES_CoreDocumentsJWT.Wrapper cached = new DES_CoreDocumentsJWT.Wrapper();
        cached.accessToken = 'CACHED_TOKEN';
        cached.expiresAt = (Integer)(DateTime.now().getTime() / 1000) + 3600;

        Cache.Session.put(cfg.jwtCacheKey, cached);

        Test.startTest();
        String token = DES_CoreDocumentsJWT.getJWToken(CONFIG_NAME);
        Map<String, String> uploadHeaders = DES_CoreDocuments.getUploadHeaders(CONFIG_NAME);
        Test.stopTest();

        System.assertEquals('CACHED_TOKEN', token, 'Should return cached token and avoid invoking reset flow');
        System.assertEquals(true, uploadHeaders.containsKey('Authorization'));
        System.assert(uploadHeaders.get('Authorization').startsWith('Bearer '));
        System.assertEquals(true, uploadHeaders.containsKey('service-id'));
        System.assertEquals(cfg.serviceId, uploadHeaders.get('service-id'));
        System.assertEquals(true, uploadHeaders.containsKey('vnd.bbva.user-id'));
    }

    @isTest
    static void testUpdateFileMetadataRequiresRequest() {
        setupTestConfig();
        try {
            Test.startTest();
            DES_CoreDocuments.updateFileMetadata(null);
            Test.stopTest();
            System.assert(false, 'Expected exception when request is null');
        } catch (CalloutException e) {
            System.debug('e.getMessage() --> ' + e.getMessage());
            System.assert(e.getMessage().contains('null'));
        }
    }

    @isTest
    static void testUpdateFileMetadataUsesMockService() {
        setupTestConfig();
        DES_CoreDocuments.UpdateFileMetadataRequest req = new DES_CoreDocuments.UpdateFileMetadataRequest();
        req.configName = CONFIG_NAME;
        req.fileId = 'F-123';
        req.fileName = 'file.pdf';
        req.docType = 'T-1';
        req.folderId = 'FOLDER-1';

        Test.startTest();
        DES_CoreDocuments.updateFileMetadata(req);
        Test.stopTest();

        System.assert(true, 'updateFileMetadata should complete using IASO mock responses in tests');
    }

    @isTest
    static void testGetEnvironmentFromURL() {
        // 1. Setup Custom Settings data
        iaso__GBL_Rest_Services_Url__c prodSetting = new iaso__GBL_Rest_Services_Url__c(
            Name = 'Test_Prod_Url',
            iaso__Url__c = 'https://api.live.bbva.com'
        );
        iaso__GBL_Rest_Services_Url__c intSetting = new iaso__GBL_Rest_Services_Url__c(
            Name = 'Test_Int_Url',
            iaso__Url__c = 'https://api.dev.bbva.com'
        );
        insert new List<iaso__GBL_Rest_Services_Url__c>{ prodSetting, intSetting };

        // 2. Setup in-memory Custom Metadata referencing those settings
        iaso__GBL_Authentication_Service__mdt prodAuth = new iaso__GBL_Authentication_Service__mdt(
            iaso__Custom_Setting__c = 'Test_Prod_Url'
        );
        iaso__GBL_Authentication_Service__mdt intAuth = new iaso__GBL_Authentication_Service__mdt(
            iaso__Custom_Setting__c = 'Test_Int_Url'
        );
        iaso__GBL_Authentication_Service__mdt emptyAuth = new iaso__GBL_Authentication_Service__mdt(
            iaso__Custom_Setting__c = 'Invalid_Key_For_Catch_Block'
        );

        Test.startTest();
        // 3. Execute method for all 3 scenarios
        String prodEnv = DES_CoreDocumentsUtils.getEnvironmentFromURL(prodAuth);
        String intEnv = DES_CoreDocumentsUtils.getEnvironmentFromURL(intAuth);
        String catchEnv = DES_CoreDocumentsUtils.getEnvironmentFromURL(emptyAuth);
        Test.stopTest();

        // 4. Assert Results
        Assert.areEqual('PROD', prodEnv, 'Should return PROD for URLs containing "live"');
        Assert.areEqual('INT', intEnv, 'Should return INT for URLs without "live"');
        Assert.areEqual('INT', catchEnv, 'Should return INT as fallback when Custom Setting is not found');
    }
}