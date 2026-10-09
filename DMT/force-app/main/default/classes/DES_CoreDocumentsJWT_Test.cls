@IsTest
private class DES_CoreDocumentsJWT_Test {
    private static final String CONFIG_NAME = 'DMT';
    private static final String JWT_CACHE_KEY = 'UTJWTCACHEKEY';

    @IsTest
    static void testModifyRequestUsesCachedTsecAndSetsHeaders() {
        iaso__GBL_Authentication_Service__mdt authCfg = DES_CoreDocumentsUtils.getAuthenticationConfigFromService('DES_CoreDocumentsJWT');
        Map<String, String> credentials = new Map<String, String>{ 'tsec' => 'mock-tsec-value' };
        try {
            Cache.Org.getPartition(authCfg.iaso__Cache_Partition__c).put(authCfg.iaso__Cache_Key__c, credentials);
        } catch (Exception ex) {
            System.debug('Org cache not available in test context: ' + ex.getMessage());
        }
        try {
            Cache.Session.getPartition(authCfg.iaso__Cache_Partition__c).put(authCfg.iaso__Cache_Key__c, credentials);
        } catch (Exception ex) {
            System.debug('Session cache not available in test context: ' + ex.getMessage());
        }

        DES_CoreDocumentsJWT jwtHandler = new DES_CoreDocumentsJWT();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.example.com/test');

        Test.startTest();
        HttpRequest modifiedReq = jwtHandler.modifyRequest(req);
        Test.stopTest();

        System.assertEquals(authCfg.iaso__User__c, modifiedReq.getHeader('consumerid'), 'consumerid header should come from auth config');
        System.assertEquals('mock-tsec-value', modifiedReq.getHeader('x-tsec-token'), 'x-tsec-token should come from cache');
        System.assertNotEquals('', modifiedReq.getHeader('x-aap-tsec'), 'x-aap-tsec should be informed from service parameters');
        System.assertNotEquals('', modifiedReq.getHeader('x-aap-tsec-env'), 'x-aap-tsec-env should be informed from URL environment mapping');
    }

    @IsTest
    static void testGetJWTokenReturnsSessionCachedTokenWhenValid() {
        setupTestConfig();
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.getConfig(CONFIG_NAME);

        DES_CoreDocumentsJWT.Wrapper cached = new DES_CoreDocumentsJWT.Wrapper();
        cached.accessToken = 'cached_token_ok';
        cached.expiresAt = Integer.valueOf(DateTime.now().addMinutes(20).getTime() / 1000);
        Cache.Session.put(cfg.jwtCacheKey, cached);

        Test.startTest();
        String token = DES_CoreDocumentsJWT.getJWToken(CONFIG_NAME);
        Test.stopTest();

        System.assertEquals('cached_token_ok', token, 'Should return session-cached token when still valid');
    }

    @IsTest
    static void testGetJWTokenReturnsOrgCachedTokenWhenSessionIsEmpty() {
        setupTestConfig();
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.getConfig(CONFIG_NAME);
        iaso__GBL_Authentication_Service__mdt authCfg = DES_CoreDocumentsUtils.getAuthenticationConfigFromService('DES_CoreDocumentsJWT');

        String uniqueJwtKey = 'UTORGCACHE' + String.valueOf(DateTime.now().getTime());
        cfg.jwtCacheKey = uniqueJwtKey;

        try {
            Cache.Session.remove(uniqueJwtKey);
        } catch (Exception ex) {
            System.debug('Session cache remove unavailable in test context: ' + ex.getMessage());
        }

        DES_CoreDocumentsJWT.Wrapper cached = new DES_CoreDocumentsJWT.Wrapper();
        cached.accessToken = 'org_cached_token_ok';
        cached.expiresAt = Integer.valueOf(DateTime.now().addMinutes(20).getTime() / 1000);

        if (authCfg.iaso__isOrgCache__c) {
            try {
                Cache.Org.getPartition(authCfg.iaso__Cache_Partition__c).put(cfg.jwtCacheKey, cached);
            } catch (Exception ex) {
                System.debug('Org partition unavailable in test context: ' + ex.getMessage());
            }
        } else {
            try {
                Cache.Session.getPartition(authCfg.iaso__Cache_Partition__c).put(cfg.jwtCacheKey, cached);
            } catch (Exception ex) {
                System.debug('Session partition unavailable in test context: ' + ex.getMessage());
            }
        }

        DES_CoreDocumentsJWT.mockResponseForTest = buildResponse(200, '{"accessToken": "reset_token_should_not_be_used", "expiresAt": 1999999999}');

        Test.startTest();
        String token = DES_CoreDocumentsJWT.getJWToken(CONFIG_NAME);
        Test.stopTest();

        System.assertEquals('org_cached_token_ok', token, 'Should return token from configured partition when session cache is empty');
    }

    @IsTest
    static void testGetJWTokenExpiredSessionTokenResetsToken() {
        setupTestConfig();
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.getConfig(CONFIG_NAME);

        DES_CoreDocumentsJWT.Wrapper expired = new DES_CoreDocumentsJWT.Wrapper();
        expired.accessToken = 'expired_token';
        expired.expiresAt = 1;
        Cache.Session.put(cfg.jwtCacheKey, expired);

        DES_CoreDocumentsJWT.mockResponseForTest = buildResponse(200, '{"accessToken": "fresh_token_123", "expiresAt": 1999999999}');

        Test.startTest();
        String token = DES_CoreDocumentsJWT.getJWToken(CONFIG_NAME);
        Test.stopTest();

        System.assertEquals('fresh_token_123', token, 'Should reset token when cached token is expired');
    }

    @IsTest
    static void testResetJWTokenSuccess() {
        setupTestConfig();
        DES_CoreDocumentsJWT.mockResponseForTest = buildResponse(200, '{"accessToken": "test_token_xyz", "expiresAt": 1900000000}');
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.getConfig(CONFIG_NAME);

        Test.startTest();
        DES_CoreDocumentsJWT.Wrapper result = DES_CoreDocumentsJWT.resetJWToken(new Map<String, Object>(), cfg);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Wrapper should be returned on successful response');
        System.assertEquals('test_token_xyz', result.accessToken, 'Access token should come from response body');
    }

    @IsTest
    static void testResetJWTokenErrorThrowsException() {
        setupTestConfig();
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.getConfig(CONFIG_NAME);
        DES_CoreDocumentsJWT.mockResponseForTest = buildResponse(500, 'Server Error');

        Test.startTest();
        Boolean thrown = false;
        try {
            DES_CoreDocumentsJWT.resetJWToken(new Map<String, Object>(), cfg);
        } catch (DES_CoreDocumentsJWT.DES_CoreDocumentsException e) {
            thrown = true;
            System.assert(e.getMessage().contains('Error resetting JWT Token'), 'Error should include reset token message');
        }
        Test.stopTest();

        System.assertEquals(true, thrown, 'Expected exception should be thrown for non-200 response');
    }
    
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
        cfg.jwtCacheKey = JWT_CACHE_KEY;
        cfg.expedientFoldersJwtCacheKey = 'UTEFJWTCACHE';
        cfg.serviceId = 'UT_SERVICE_ID';
        cfg.responsible = 'UT_RESP';
        cfg.coreDocEndpoint = 'https://example.com/v1';
        return cfg;
    }

    private static HttpResponse buildResponse(Integer statusCode, String body) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(statusCode);
        response.setBody(body);
        return response;
    }
}