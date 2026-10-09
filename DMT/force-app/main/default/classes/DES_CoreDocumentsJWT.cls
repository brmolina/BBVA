/**-------------------------------------------------------------------------------------------
* @Name     CoreDocuments Integration Headers and utility methods
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-06
* ------------------------------------------------------------------------------------------------
* @Description IASO Integration headers interface implementation for CoreDocuments service.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, Documentation-ApexDoc')
global class DES_CoreDocumentsJWT implements iaso.GBL_Integration_Headers {

    private static final String JWT_SERVICENAME = 'DES_CoreDocumentsJWT';
    @TestVisible private static HttpResponse mockResponseForTest;

    /**
    * @description Implement the modifyRequest method to add authentication headers based on the configuration.
    * @param request HTTP request sent to the JWT service.
    * @return HTTP request with CoreDocuments authentication headers.
    */
    global HttpRequest modifyRequest(HttpRequest request) {

        // get tsec from cache and add to headers
        iaso__GBL_Authentication_Service__mdt authConfig = DES_CoreDocumentsUtils.getAuthenticationConfigFromService(JWT_SERVICENAME);
        if (authConfig == null) {
            throw new DES_CoreDocumentsException('Authentication configuration not found for service ' + JWT_SERVICENAME);
        }

        // Check if the session is stored in the cache
        Cache.Partition partition = getPartition(authConfig);

        // Retrieve cache value from the partition
        Map<String, String> credentials = (Map<String,String>)partition.get(authConfig.iaso__Cache_Key__c);
        if (credentials == null || String.isBlank(credentials.get('tsec'))) {
            DES_CoreDocumentsAuthentication.resetToken(authConfig);
            credentials = (Map<String,String>)partition.get(authConfig.iaso__Cache_Key__c);
        }

        if (credentials == null || String.isBlank(credentials.get('tsec'))) {
            throw new DES_CoreDocumentsException('Unable to obtain CoreDocuments tsec token from cache for service ' + JWT_SERVICENAME);
        }

        String consumerId = DES_CoreDocumentsUtils.getSimpleParamFromJSON(authConfig.iaso__Service_Parameters__c, 'consumerID');

        request.setHeader('consumerid', authConfig.iaso__User__c);
        request.setHeader('x-tsec-token', credentials.get('tsec'));
        request.setHeader('x-aap-tsec', consumerId);
        request.setHeader('x-aap-tsec-env', DES_CoreDocumentsUtils.getEnvironmentFromURL(authConfig));
        return request;
    }

    /**
     * @description Get JWT token with configuration from Custom Metadata
     * @param configName Custom Metadata developer name (e.g., 'DMT', 'ABC')
     * @return JWT token string
     */
    public static String getJWToken(String configName) {

        String res;
        Boolean resetToken = true;
        DES_CoreDocuments.Config cfg = DES_CoreDocuments.getConfig(configName);
        Wrapper cachedJWT = getJwtFromSessionCache(cfg);

        // check expiration
        if (cachedJWT == null) {
            cachedJWT = getJwtFromOrgCache(cfg);
        }

        if (cachedJWT != null) {
            Long expiresAt = cachedJWT.expiresAt;
            Long currentTime = DateTime.now().getTime() / 1000;
            if (currentTime < expiresAt - 60) { // 1 min buffer
                res = cachedJWT.accessToken;
                resetToken = false;
            }
        }

        if (resetToken) {
            Wrapper resetJWT = resetJWToken(new Map<String, Object>(), cfg);
            res = resetJWT.accessToken;
        }
        return res;
    }

    /**
    * @description Call service and return wrapper with configuration from Custom Metadata
    * @param request Request parameters
    * @param cfg Custom Metadata configuration
    * @return Wrapper with JWT data
    */
    public static Wrapper resetJWToken(Map<String, Object> request, DES_CoreDocuments.Config cfg) {
        Wrapper res = new Wrapper();
        final HttpResponse response;
        if (Test.isRunningTest() && mockResponseForTest != null) {
            response = mockResponseForTest;
        } else {
            response = iaso.GBL_Integration_GenericService.invoke(cfg.jwtServiceName, request);
        }
        switch on response.getStatusCode() {
            when 200 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = (Wrapper)obj;
                putJwtInSessionCache(cfg, res);
                putJwtInOrgCache(cfg, res);
            }
            when else {
                throw new DES_CoreDocumentsException('Error resetting JWT Token: ' + response.getBody());
            }
        }
        return res;
    }

    private static Cache.Partition getPartition(iaso__GBL_Authentication_Service__mdt authConfig) {
        if (!authConfig.iaso__isOrgCache__c) {
            return Cache.Session.getPartition(authConfig.iaso__Cache_Partition__c);
        }
        return Cache.Org.getPartition(authConfig.iaso__Cache_Partition__c);
    }

    private static Wrapper getJwtFromSessionCache(DES_CoreDocuments.Config cfg) {
        try {
            if (Cache.Session.contains(cfg.jwtCacheKey)) {
                return (Wrapper)Cache.Session.get(cfg.jwtCacheKey);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN,'[DES_CoreDocumentsJWT] Session cache unavailable for key ' + cfg.jwtCacheKey + '. error=' + ex.getMessage());
        }
        return null;
    }

    private static Wrapper getJwtFromOrgCache(DES_CoreDocuments.Config cfg) {
        iaso__GBL_Authentication_Service__mdt authConfig = DES_CoreDocumentsUtils.getAuthenticationConfigFromService(JWT_SERVICENAME);
        if (authConfig == null || String.isBlank(authConfig.iaso__Cache_Partition__c)) {
            return null;
        }
        Cache.Partition partition = getPartition(authConfig);
        return (Wrapper)partition.get(cfg.jwtCacheKey);
    }

    private static void putJwtInOrgCache(DES_CoreDocuments.Config cfg, Wrapper jwtWrapper) {
        iaso__GBL_Authentication_Service__mdt authConfig = DES_CoreDocumentsUtils.getAuthenticationConfigFromService(JWT_SERVICENAME);
        if (authConfig == null || String.isBlank(authConfig.iaso__Cache_Partition__c) || jwtWrapper == null) {
            return;
        }

        Cache.Partition partition = getPartition(authConfig);
        partition.put(cfg.jwtCacheKey, jwtWrapper);
    }

    private static void putJwtInSessionCache(DES_CoreDocuments.Config cfg, Wrapper jwtWrapper) {
        if (jwtWrapper == null) {
            return;
        }

        try {
            Cache.Session.put(cfg.jwtCacheKey, jwtWrapper);
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN,'[DES_CoreDocumentsJWT] Session cache unavailable to store key ' + cfg.jwtCacheKey + '. error=' + ex.getMessage());
        }
    } 
    /**
    * @description Exception thrown when JWT token retrieval or prerequisite authentication fails.
    */
    public class DES_CoreDocumentsException extends Exception {}

    /**
    * @description Class Wrapper
    */
    public class Wrapper {
        /** @description JWT access token returned by Portunus. */
        public String accessToken {get;set;}
        /** @description Expiration time in epoch seconds. */
        public Integer expiresAt {get;set;}
    }


}