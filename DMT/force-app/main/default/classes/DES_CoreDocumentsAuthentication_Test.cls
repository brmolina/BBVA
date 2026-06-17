@IsTest
private class DES_CoreDocumentsAuthentication_Test {

    private static final String TEST_TOKEN = 'TOKEN_TEST_123';
    private static final String TEST_CACHE_PARTITION = 'local.ServicesPartition';

    private class CoreDocumentsAuthMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('POST', req.getMethod(), 'The authentication request method must be POST');
            System.assertEquals('https://apitest.com/auth', req.getEndpoint(), 'The endpoint should match the configured URL');
            System.assertNotEquals(null, req.getBody(), 'The request body should not be null');
            System.assert(req.getBody().contains('"consumerID":"consumer-test"'), 'The body must contain the correct consumerID');
            System.assert(req.getBody().contains('"authenticationType":"BASIC"'), 'The body must specify BASIC authentication');
            System.assert(req.getBody().contains('"userID":"test.user"'), 'The body must contain the correct userID');

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setHeader('Content-Type', 'application/json');
            res.setHeader('tsec', TEST_TOKEN);
            res.setBody('{"result":"success"}');
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        insert new iaso__GBL_Rest_Services_Url__c( Name = 'DMT', iaso__Url__c = 'https://apitest.com/auth');
    }

    private static iaso__GBL_Authentication_Service__mdt buildAuthConfig() {
        iaso__GBL_Authentication_Service__mdt cfg = new iaso__GBL_Authentication_Service__mdt();

        cfg.iaso__isOrgCache__c = true;
        cfg.iaso__Cache_Partition__c = TEST_CACHE_PARTITION;
        cfg.iaso__Cache_Key__c = 'DESCoreDocumentsGrantingTicket';
        cfg.iaso__Header_Token__c = 'tsec';
        cfg.iaso__Custom_Setting__c = 'DMT';
        cfg.iaso__User__c = 'test.user';
        cfg.iaso__Service_Parameters__c = '{"consumerID":"consumer-test",' + '"idAuthenticationData":"pwd",' + '"authenticationType":"BASIC"}';

        Blob cryptoKey = Crypto.generateAesKey(256);
        Blob encryptedPassword = Crypto.encryptWithManagedIV('AES256', cryptoKey, Blob.valueOf('MySecretPassword'));

        cfg.iaso__CryptoKey__c = EncodingUtil.base64Encode(cryptoKey);
        cfg.iaso__Password__c = EncodingUtil.base64Encode(encryptedPassword);

        return cfg;
    }

    private static void seedOrgCache(iaso__GBL_Authentication_Service__mdt cfg, String token) {
        Cache.OrgPartition partition = Cache.Org.getPartition(cfg.iaso__Cache_Partition__c);
        partition.put(
            cfg.iaso__Cache_Key__c,
            new Map<String, String>{ 'tsec' => token }
        );
    }

    private static HttpRequest buildRequest() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://test.com/resource');
        req.setMethod('GET');
        return req;
    }

    @IsTest
    static void testIsAuthenticatedTrueWhenTokenExists() {
        iaso__GBL_Authentication_Service__mdt cfg = buildAuthConfig();

        Test.startTest();
            seedOrgCache(cfg, 'TOKEN_ABC');
            Boolean result = DES_CoreDocumentsAuthentication.isAuthenticated(cfg);
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true if a token exists in cache');
    }

    @IsTest
    static void testApplySecurityAddsHeaderWhenTokenExists() {
        iaso__GBL_Authentication_Service__mdt cfg = buildAuthConfig();
        seedOrgCache(cfg, 'TOKEN_456');

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://test.com');
        req.setMethod('GET');

        Test.startTest();
            HttpRequest securedReq = DES_CoreDocumentsAuthentication.applySecurity(req, cfg);
        Test.stopTest();

        System.assertEquals('TOKEN_456', securedReq.getHeader(cfg.iaso__Header_Token__c), 'Should add the security token to the request header');
    }

    @IsTest
    static void testApplySecurityDoesNotAddHeaderWhenTokenDoesNotExist() {
        iaso__GBL_Authentication_Service__mdt cfg = buildAuthConfig();

        HttpRequest req = buildRequest();

        Test.startTest();
            HttpRequest securedReq = DES_CoreDocumentsAuthentication.applySecurity(req, cfg);
        Test.stopTest();

        System.assertEquals(null, securedReq.getHeader(cfg.iaso__Header_Token__c), 'Should not add security header if no token is available');
    }

    @IsTest
    static void testResetTokenSuccess() {
        iaso__GBL_Authentication_Service__mdt cfg = buildAuthConfig();

        Test.setMock(HttpCalloutMock.class, new CoreDocumentsAuthMock());

        Test.startTest();
            iaso__GBL_Application_Log__c logRecord = DES_CoreDocumentsAuthentication.resetToken(cfg);
            Boolean authenticated = DES_CoreDocumentsAuthentication.isAuthenticated(cfg);
        Test.stopTest();

        System.assertNotEquals(null, logRecord, 'Should return an application log record');
        System.assertEquals('DMT', logRecord.Name, 'Log name should match the service name');
        System.assertEquals('Integration', logRecord.iaso__Type__c, 'Log type should be Integration');
        System.assert(logRecord.iaso__Message_LTA__c.contains('REQUEST:'), 'Log should contain the request details');
        System.assert(logRecord.iaso__Message_LTA__c.contains('RESPONSE:'), 'Log should contain the response details');

        System.assertEquals(true, authenticated, 'User should be authenticated after a successful resetToken');
    }

    @IsTest
    static void testIsAuthenticatedTrueAfterResetToken() {
        iaso__GBL_Authentication_Service__mdt cfg = buildAuthConfig();

        Test.setMock(HttpCalloutMock.class, new CoreDocumentsAuthMock());

        Test.startTest();
            DES_CoreDocumentsAuthentication.resetToken(cfg);
            Boolean result = DES_CoreDocumentsAuthentication.isAuthenticated(cfg);
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true immediately after resetToken execution');
    }
}