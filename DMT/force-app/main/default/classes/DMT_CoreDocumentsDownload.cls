/**-------------------------------------------------------------------------------------------
* @Name     DMT_CoreDocumentsDownload
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-06
* ------------------------------------------------------------------------------------------------
* @Description IASO Integration headers interface implementation for CoreDocuments Download service.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DMT_CoreDocumentsDownload implements iaso.GBL_Integration_Headers {

    private static final String SERVICENAME = 'DMT_CoreDocumentsDownload';
    private static final String JWT_CACHE_KEY = 'DMTExpedientFoldersJWT';

    global HttpRequest modifyRequest(HttpRequest request) {

        // get tsec from cache and add to headers
        iaso__GBL_Authentication_Service__mdt authConfig = DMT_CoreDocumentsUtils.getAuthenticationConfigFromService(SERVICENAME);

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
        String jwtToken = (String)Cache.Session.get(JWT_CACHE_KEY);

        //request.setHeader('x-tsec-token', credentials.get('tsec'));
        //request.setHeader('consumerid', authConfig.iaso__User__c);
        //request.setHeader('x-aap-tsec', consumerId);
        //request.setHeader('x-aap-tsec-env', DMT_CoreDocumentsUtils.getEnvironmentFromURL(authConfig));
        request.setHeader('Authorization', 'Bearer ' + jwtToken);
        return request;
    }

    @AuraEnabled
    public static Map<String, Object> getDownloadHeaders() {

        Map<String, Object> headers = new Map<String, Object>();

        iaso__GBL_Authentication_Service__mdt authConfig = DMT_CoreDocumentsUtils.getAuthenticationConfigFromService(SERVICENAME);

        // Check if the session is stored in the cache
        Cache.Partition partition;
        if (!authConfig.iaso__isOrgCache__c) {
            Cache.SessionPartition sessionPart = Cache.Session.getPartition(authConfig.iaso__Cache_Partition__c);
            partition = sessionPart;
        } else {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(authConfig.iaso__Cache_Partition__c);
            partition = orgPart;
        }

        // Retrieve cache value from the partition
        Map<String, String> credentials = (Map<String,String>)partition.get(authConfig.iaso__Cache_Key__c);
        String consumerId = DMT_CoreDocumentsUtils.getSimpleParamFromJSON(authConfig.iaso__Service_Parameters__c, 'consumerID');
        String jwtToken = (String)Cache.Session.get(JWT_CACHE_KEY);

        //headers.put('x-tsec-token', credentials.get('tsec'));
        //headers.put('consumerid', authConfig.iaso__User__c);
        //headers.put('x-aap-tsec', consumerId);
        //headers.put('x-aap-tsec-env', DMT_CoreDocumentsUtils.getEnvironmentFromURL(authConfig));
        headers.put('Authorization', 'Bearer ' + jwtToken);
        return headers;

    }
}