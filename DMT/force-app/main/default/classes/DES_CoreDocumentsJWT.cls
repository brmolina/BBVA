/**-------------------------------------------------------------------------------------------
* @Name     CoreDocuments Integration Headers and utility methods
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-06
* ------------------------------------------------------------------------------------------------
* @Description IASO Integration headers interface implementation for CoreDocuments service.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DES_CoreDocumentsJWT implements iaso.GBL_Integration_Headers {

    private static final String JWT_SERVICENAME = 'DES_CoreDocumentsJWT';
    @TestVisible 
    private static HttpResponse mockResponseForTest;

    /**
    * @description Implement the modifyRequest method to add authentication headers based on the configuration
    */
    global HttpRequest modifyRequest(HttpRequest request) {

        // get tsec from cache and add to headers
        iaso__GBL_Authentication_Service__mdt authConfig = DES_CoreDocumentsUtils.getAuthenticationConfigFromService(JWT_SERVICENAME);

        // Check if the session is stored in the cache
        Cache.Partition partition;
        if (!authConfig.iaso__isOrgCache__c) {
            Cache.SessionPartition sessionPart = Cache.Session.getPartition(authConfig.iaso__Cache_Partition__c);
            partition = sessionPart;
        } else {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(authConfig.iaso__Cache_Partition__c);
            partition = orgPart;
        }

        System.debug('cache partition: ' + authConfig.iaso__Cache_Partition__c);
        System.debug('Retrieving tsec from cache with key: ' + authConfig.iaso__Cache_Key__c);

        // Retrieve cache value from the partition
        Map<String, String> credentials = (Map<String,String>)partition.get(authConfig.iaso__Cache_Key__c);
        String consumerId = DES_CoreDocumentsUtils.getSimpleParamFromJSON(authConfig.iaso__Service_Parameters__c, 'consumerID');
        // Map<String, String> coreDocumentsJWT = (Map<String,String>)partition.get('coreDocumentsJWT');

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

        // check expiration
        if (Cache.Session.contains(cfg.jwtCacheKey)) {
            Wrapper cachedJWT = (Wrapper)Cache.Session.get(cfg.jwtCacheKey);
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
        HttpResponse response;
        if (Test.isRunningTest() && mockResponseForTest != null) {
            response = mockResponseForTest;
        } else {
            response = iaso.GBL_Integration_GenericService.invoke(cfg.jwtServiceName, request);
        }
        switch on response.getStatusCode() {
            when 200 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = (Wrapper)obj;
                Cache.Session.put(cfg.jwtCacheKey, res);
            }
            when else {
                throw new DES_CoreDocumentsException('Error resetting JWT Token: ' + response.getBody());
            }
        }
        return res;
    }

    public class DES_CoreDocumentsException extends Exception {}

    /**
    * @description Class Wrapper
    */
    public class Wrapper {
        public String accessToken {get;set;}
        public Integer expiresAt {get;set;}
    }

}