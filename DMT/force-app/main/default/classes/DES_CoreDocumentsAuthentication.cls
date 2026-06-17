/**-------------------------------------------------------------------------------------------
* @Name     CoreDocuments Authentication
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-06
* ------------------------------------------------------------------------------------------------
* @Description Class implementing IASO authentication interface for CoreDocuments service.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.NCSSMethodCount, PMD.AvoidGlobalModifier')
global with sharing class DES_CoreDocumentsAuthentication implements iaso.GBL_Integration_Authentication {

    /**
    * @description Check if the current session is authenticated based on the presence of credentials in the cache
    * @param authenticationConfig Authentication configuration from Custom Metadata
    * @return Boolean indicating whether the session is authenticated
    */
    global static Boolean isAuthenticated(iaso__GBL_Authentication_Service__mdt authenticationConfig) {
        // Check if the session is stored in the cache
        Cache.Partition partition;
        if (!authenticationConfig.iaso__isOrgCache__c) {
            Cache.SessionPartition sessionPart = Cache.Session.getPartition(authenticationConfig.iaso__Cache_Partition__c);
            partition = sessionPart;
        } else {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(authenticationConfig.iaso__Cache_Partition__c);
            partition = orgPart;
        }
        // Retrieve cache value from the partition
        Map < String, String > credentials = (Map < String, String > ) partition.get(authenticationConfig.iaso__Cache_Key__c);
        // if credentials are not set in the cache, reset
        if (credentials != null && credentials.get('tsec') != null) {
            return true;
        }
        return false;
    }

     /**
     * @description Reset token by calling the authentication service and updating the cache
     * @param authenticationConfig Authentication configuration from Custom Metadata
     * @return Log record with request and response details
     */
    global static iaso__GBL_Application_Log__c resetToken(iaso__GBL_Authentication_Service__mdt authenticationConfig) {
        Datetime initTime = Datetime.now();
        Http http = new Http();
        HttpRequest validationRequest = new HttpRequest();
        validationRequest.setEndpoint(DES_CoreDocumentsUtils.getUrlFromCustomSettings(authenticationConfig.iaso__Custom_Setting__c));
        validationRequest.setMethod('POST');
        validationRequest.setHeader('Content-Type', 'application/json;charset=UTF-8');

        // CSF Enviar siempre el FederartionId del invocante;
        // String reqHeaderUserKey = App_Header_Key__mdt.getInstance(iaso.GBL_Integration_Helper.HEADER_SEP_USERCODE_AUTH).iaso__Key__c;
        // String fedIdValue = iaso.GBL_Integration_Helper.setGetRunningUserFederationId();
        // validationRequest.setHeader(reqHeaderUserKey, fedIdValue);
        // String headerStr = 'Content-Type: application/json;charset=UTF-8' + '\n' + reqHeaderUserKey + ':' + fedIdValue;

        String headerStr = 'Content-Type: application/json;charset=UTF-8' + '\n';
        String validationRequestBody = '{"authentication":{"consumerID":"' + DES_CoreDocumentsUtils.getSimpleParamFromJSON(authenticationConfig.iaso__Service_Parameters__c, 'consumerID') + '",' +
            '"authenticationData":[{"authenticationData":["' +  DES_CoreDocumentsUtils.getPassword(authenticationConfig) + '"],' +
            '"idAuthenticationData":"' + DES_CoreDocumentsUtils.getSimpleParamFromJSON(authenticationConfig.iaso__Service_Parameters__c, 'idAuthenticationData') + '"}],' +
            '"authenticationType":"' +  DES_CoreDocumentsUtils.getSimpleParamFromJSON(authenticationConfig.iaso__Service_Parameters__c, 'authenticationType') + '",' +
            '"userID":"' + authenticationConfig.iaso__User__c + '"}}';

        // System.debug('validationRequestBody: ' + validationRequestBody);

        validationRequest.setBody(validationRequestBody);

        HttpResponse response = http.send(validationRequest);
        // Parse the JSON response
        list<integer> validCodes = new List<integer>{200,202,204};
        if ( !validCodes.contains(response.getStatusCode())) {
            System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
        } else {
            //String jsonResponse = response.getBody();
            String tsec = response.getHeader(authenticationConfig.iaso__Header_Token__c);
            //Map < String, Object > m = (Map < String, Object > ) JSON.deserializeUntyped(jsonResponse);
            //Map < String, Object > user = (Map < String, Object > ) m.get('user');
            Map < String, String > credentials = new Map < String, String > ();
            // Add cache value to the partition

            credentials.put('tsec', tsec);

            Cache.Partition partition;
            if (!authenticationConfig.iaso__isOrgCache__c) {
                Cache.SessionPartition sessionPart = Cache.Session.getPartition(authenticationConfig.iaso__Cache_Partition__c);
                partition = sessionPart;
            } else {
                Cache.OrgPartition orgPart = Cache.Org.getPartition(authenticationConfig.iaso__Cache_Partition__c);
                partition = orgPart;
            }
            partition.put(authenticationConfig.iaso__Cache_Key__c, credentials);
            Cache.Session.put('CoreDocumentsCredentials', credentials);

            //System.debug('credenctials guardadas en cache: ' + credentials);
        }

        String respHeaderStr = '';
        for (String respHeader : response.getHeaderKeys()) {
            if (respHeader != 'tsec') {
                respHeaderStr += respHeader + ': ' + response.getHeader(respHeader) + '\n';
            }
        }

        return new iaso__GBL_Application_Log__c(
            iaso__Start_Time__c = initTime,
            iaso__End_Time__c = Datetime.now(),
            iaso__Message_LTA__c = 'REQUEST: ' + validationRequest.getEndpoint() + '\n' + validationRequest.getBody() + '\n--\n--\n\nRESPONSE:\n' + response.getBody(),
            Name = authenticationConfig.iaso__Custom_Setting__c,
            iaso__Type__c = 'Integration',
            iaso__User__c = UserInfo.getUserId());

            //NO disponibles en iaso 1.11
            //iaso__XRhoTraceid__c = validationRequest.getHeader('X-Rho-Traceid'),
            //iaso__XRhoParentSpanid__c = validationRequest.getHeader('X-Rho-ParentSpanid'),
            //iaso__Response_StatusCode__c = String.valueOf(response.getStatusCode()),
            //iaso__Response_Status__c = response.getStatus(),
            //iaso__Request_EndPoint__c = validationRequest.getEndPoint(),
            //iaso__Request_Method__c = validationRequest.getMethod(),
            //iaso__Request_Body__c = validationRequest.getBody(),
            //iaso__Response_Body__c = response.getBody(),
            //iaso__Request_Headers__c = headerStr,
            //iaso__Response_Headers__c = respHeaderStr,
            //iaso__IsAuthRequest__c = true
    }

    /**
    * @description Apply authentication headers to the request based on the configuration
    * @param request HTTP request to apply headers to
    * @param authenticationConfig Authentication configuration from Custom Metadata
    * @return HTTP request with authentication headers applied
    */
    global static HttpRequest applySecurity(HttpRequest request, iaso__GBL_Authentication_Service__mdt authenticationConfig) {
        // Check if the session is stored in the cache
        Cache.Partition partition;
        if (!authenticationConfig.iaso__isOrgCache__c) {
            Cache.SessionPartition sessionPart = Cache.Session.getPartition(authenticationConfig.iaso__Cache_Partition__c);
            partition = sessionPart;
        } else {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(authenticationConfig.iaso__Cache_Partition__c);
            partition = orgPart;
        }
        // Retrieve cache value from the partition
        Map < String, String > credentials = (Map < String, String > ) partition.get(authenticationConfig.iaso__Cache_Key__c);

        // if credentials are not set in the cache, reset
        if (credentials != null && credentials.get('tsec') != null) {
            //resetToken(authenticationConfig);
            //credentials = (Map <String, String>) sessionPart.get(authenticationConfig.Cache_Key__c);
            request.setHeader(authenticationConfig.iaso__Header_Token__c, credentials.get('tsec'));
        }
        return request;
    }

}