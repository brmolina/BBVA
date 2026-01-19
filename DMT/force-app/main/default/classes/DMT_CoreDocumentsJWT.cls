/**-------------------------------------------------------------------------------------------
* @Name     DMT CoreDocuments Integration Headers and utility methods
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-06
* ------------------------------------------------------------------------------------------------
* @Description IASO Integration headers interface implementation for CoreDocuments service.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DMT_CoreDocumentsJWT implements iaso.GBL_Integration_Headers {

    private static final String JWT_SERVICENAME = 'DMT_CoreDocumentsJWT';
    private static final String JWT_CACHE_KEY = 'DMTCoreDocumentsJWT';

    global HttpRequest modifyRequest(HttpRequest request) {

        // get tsec from cache and add to headers
        iaso__GBL_Authentication_Service__mdt authConfig = DMT_CoreDocumentsUtils.getAuthenticationConfigFromService(JWT_SERVICENAME);

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
        String consumerId = DMT_CoreDocumentsUtils.getSimpleParamFromJSON(authConfig.iaso__Service_Parameters__c, 'consumerID');
        // Map<String, String> coreDocumentsJWT = (Map<String,String>)partition.get('coreDocumentsJWT');

        request.setHeader('consumerid', authConfig.iaso__User__c);
        request.setHeader('x-tsec-token', credentials.get('tsec'));
        request.setHeader('x-aap-tsec', consumerId);
        request.setHeader('x-aap-tsec-env', DMT_CoreDocumentsUtils.getEnvironmentFromURL(authConfig));
        return request;
    }

    public static String getJWToken() {

        String res;
        Boolean resetToken = true;

        // check expiration
        if (Cache.Session.contains(JWT_CACHE_KEY)) {
            Wrapper cachedJWT = (Wrapper)Cache.Session.get(JWT_CACHE_KEY);
            Long expiresAt = cachedJWT.expiresAt;
            Long currentTime = DateTime.now().getTime() / 1000;
            if (currentTime < expiresAt - 60) { // 1 min buffer
                res = cachedJWT.accessToken;
                resetToken = false;
            }
        }

        if (resetToken) {
            Wrapper resetJWT = resetJWToken(new Map<String, Object>());
            res = resetJWT.accessToken;
        }
        return res;
    }

    /**
    * @description Call service and return wrapper
    */
    public static Wrapper resetJWToken(Map<String, Object> request) {
        Wrapper res = new Wrapper();
        //final HttpResponse response = DMT_HPG_Utils.callService(JWT_SERVICENAME, request);

        final HttpResponse response = iaso.GBL_Integration_GenericService.invoke(JWT_SERVICENAME, request);

        switch on response.getStatusCode() {
            when 200 {
                final Object obj = System.JSON.deserialize(response.getBody(), Wrapper.class);
                res = (Wrapper)obj;
                Cache.Session.put(JWT_CACHE_KEY, res);
            }
            when else {
                throw new DMT_CoreDocumentsException('Error resetting JWT Token: ' + response.getBody());
            }
        }
        return res;
    }

    public class DMT_CoreDocumentsException extends Exception {}

    /**
    * @description Class Wrapper
    */
    public class Wrapper {
        public String accessToken {get;set;}
        public Integer expiresAt {get;set;}
    }

}