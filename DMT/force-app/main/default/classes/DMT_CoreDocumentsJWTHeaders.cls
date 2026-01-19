/**-------------------------------------------------------------------------------------------
* @Name     DMT  CoreDocuments Integration Headers
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-06
* ------------------------------------------------------------------------------------------------
* @Description IASO Integration headers interface implementation for CoreDocuments service.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DMT_CoreDocumentsJWTHeaders implements iaso.GBL_Integration_Headers {

    global HttpRequest modifyRequest(HttpRequest request) {

        // get tsec from cache and add to headers
        iaso__GBL_Authentication_Service__mdt authConfig = DMT_CoreDocumentsUtils.getAuthenticationConfigFromService('DMT_CoreDocumentsJWT');

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
        // Map<String, String> coreDocumentsJWT = (Map<String,String>)partition.get('coreDocumentsJWT');

        request.setHeader('consumerid', authConfig.iaso__User__c);
        request.setHeader('x-tsec-token', credentials.get('tsec'));
        request.setHeader('x-aap-tsec', DMT_CoreDocumentsUtils.getSimpleParamFromJSON(authConfig.iaso__Service_Parameters__c, 'consumerID'));
        request.setHeader('x-aap-tsec-env', DMT_CoreDocumentsUtils.getEnvironmentFromURL(authConfig));

        //  request.setHeader('authorization', 'Bearer ' + coreDocumentsJWT.get('jwt'));

        return request;
    }
}