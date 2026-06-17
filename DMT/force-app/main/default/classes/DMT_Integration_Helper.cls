public with sharing class DMT_Integration_Helper {

    private static final String NAME = 'DMT_Integration_Helper';

    private static final integer OLD_CATALOG_EXPIRED_TOKEN = 403;
    private static final integer NEW_CATALOG_EXPIRED_TOKEN = 401;
    private static final integer NEW_CATALOG_EXPIRED_TOKEN_TMP = 400;

    private static final Integer MAX_LENGTH = 5000;

    @TestVisible
    private static Map<String, iaso__blockedService__mdt> mockBlockedServices = new Map<String, iaso__blockedService__mdt>();

    public static void setMockCmdtBlockedService(String name, iaso__blockedService__mdt cmdt) {
        mockBlockedServices.put(name, cmdt);
    }

    public static DMT_Integration_GenericService.CacheWrapper getCacheInfo(iaso__GBL_Rest_Services_Url__c csConfig) {
        DMT_Integration_GenericService.CacheWrapper cache = new DMT_Integration_GenericService.CacheWrapper();
        cache.timeout=10000;
        if ( csConfig != null && csConfig.iaso__Timeout__c != null ){
            cache.timeout = csConfig.iaso__Timeout__c.intValue();
        }
        cache.cacheTTL = 0;
        if ( csConfig != null && csConfig.iaso__cacheTTLInSecs__c != null ){
            cache.cacheTTL = csConfig.iaso__cacheTTLInSecs__c.intValue();
        }
        cache.partitionName = '';
        if ( csConfig != null && csConfig.iaso__Cache_Partition__c != null ){
            String partitionName = csConfig.iaso__Cache_Partition__c;
            // If the partition name starts with the namespace, remove it
            if (partitionName.startsWith('iaso.')) {
                partitionName = partitionName.substring(5); // remove 'iaso.'
            }
            cache.partitionName = partitionName;
        }
        cache.isCacheInOrg = true;
        if ( csConfig != null && csConfig.iaso__isCacheInOrg__c != null ){
            cache.isCacheInOrg = csConfig.iaso__isCacheInOrg__c;
        }
        return cache;
    }

    public static String getCacheResponse(DMT_Integration_GenericService.CacheWrapper cacheInfo, HttpRequest request) {
        Cache.Partition partition;
        if (!cacheInfo.isCacheInOrg) {
            Cache.SessionPartition sessionPart = Cache.Session.getPartition(cacheInfo.partitionName);
            partition = sessionPart;
        } else {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(cacheInfo.partitionName);
            partition = orgPart;
        }
        String cacheKey = DMT_Integration_Utils.getCacheKey(request.toString() + request.getBody());
        return (String) partition.get(cacheKey);
    }

    public static void cacheResponse(HttpRequest request, HttpResponse response, DMT_Integration_GenericService.CacheWrapper cacheInfo) {
        Cache.Partition partition;
        if (!cacheInfo.isCacheInOrg) {
            Cache.SessionPartition sessionPart = Cache.Session.getPartition(cacheInfo.partitionName);
            partition = sessionPart;
        } else {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(cacheInfo.partitionName);
            partition = orgPart;
        }
        String cacheKey = DMT_Integration_Utils.getCacheKey(request.toString() + request.getBody());
        if (response.getStatusCode() == 200 && cacheInfo.cacheTTL > 0) {
            partition.put(cacheKey, response.getBody(), cacheInfo.cacheTTL);
        }
    }

    public static HttpResponse getCacheHTTPResponse(String cacheResponseBody) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(cacheResponseBody);
        response.setStatusCode(200);
        response.setStatus('OK');
        return response;
    }

    public static DMT_Integration_GenericService.TemplateWrapper applyPlaceholders(iaso__GBL_integration_service__mdt serviceConfig,Map<String, Object> placeholderMap){
      DMT_Integration_GenericService.TemplateWrapper template = new DMT_Integration_GenericService.TemplateWrapper();
      template.jsonTemplate = serviceConfig.iaso__Json_Input_Template_LTA__c;
      template.queryStringTemplate = serviceConfig.iaso__Querystring_Input_Template_LTA__c;
      template.headerTemplate = serviceConfig.iaso__Http_Headers_LTA__c;

      for (String key : placeholderMap.keySet()) {
        Object value = placeholderMap.get(key);
        if (String.isNotBlank(template.jsonTemplate)) {
            if (template.jsonTemplate == '#' + key + '#') {
                // template is ONLY the placeholder -> safe to replace entirely
                // Only serialize if the value is not already a string
                if (value instanceof String) {
                    template.jsonTemplate = String.valueOf(value);
                } else {
                    template.jsonTemplate = JSON.serialize(value);
                }
            } else {
                // template has surrounding JSON text -> serialize non-string values
                // so arrays/objects (for example structureCodes) are injected as valid JSON.
                if (value != null) {
                    String replacement =
                        (value instanceof String)
                            ? String.valueOf(value)
                            : JSON.serialize(value);
                    template.jsonTemplate = template.jsonTemplate.replace('#' + key + '#', replacement);
                }
            }
        }

        if (String.isNotBlank(template.queryStringTemplate)) {
            String replacement = String.valueOf(value);
            if (replacement != null) {
                template.queryStringTemplate = template.queryStringTemplate.replace('#' + key + '#', replacement);
            }
        }

        if (String.isNotBlank(template.headerTemplate)) {
            String replacement = String.valueOf(value);
            if (replacement != null) {
                template.headerTemplate = template.headerTemplate.replace('#' + key + '#', replacement);
            }
        }
      }
      return template;

    }

    public static HttpRequest setRequest(iaso__GBL_integration_service__mdt serviceConfig, iaso__GBL_Rest_Services_Url__c csConfig, DMT_Integration_GenericService.CacheWrapper cacheInfo, DMT_Integration_GenericService.TemplateWrapper template){
        HttpRequest request = new HttpRequest();
        String url = csConfig.iaso__Url__c;
        if (String.isNotblank(template.queryStringTemplate)) {
            url = url + template.queryStringTemplate;
        }
        request.setEndpoint(url);
        request.setMethod(serviceConfig.iaso__Http_Method__c);
        request.setTimeout(cacheInfo.timeout);

        if (String.isNotBlank(template.headerTemplate)) {
            System.debug(template.headerTemplate);
            Map <String, Object> headerMap = (Map <String, Object>)JSON.deserializeUntyped(template.headerTemplate);
            // Add all the configured headers
            for (String headerKey : headerMap.keySet()) {
                request.setHeader(headerKey, (String)headerMap.get(headerKey));
            }
        }
        if (String.isNotBlank(template.jsonTemplate)) {
            request.setBody(template.jsonTemplate);
        }
        request = applySecurity(request, serviceConfig.DeveloperName);

        request = modifyHeaders(request, serviceConfig.DeveloperName);
        System.debug('BODY => ' + request.getBody());
        return request;
    }

    private static HttpRequest applySecurity(HttpRequest request, String serviceName) {
        // Apply security
        iaso__GBL_Authentication_Service__mdt authenticationConfig = DMT_Integration_Utils.getAuthenticationConfigFromService(serviceName);
        String iasoClassName = 'iaso_' + authenticationConfig.iaso__Apex_Class__c;
        System.Type objType = Type.forName(iasoClassName);
        if (objType == null) {
            throw new DMT_CustomException('Class not found: ' + iasoClassName);
        }
        iaso.GBL_Integration_Authentication authenticationService = (iaso.GBL_Integration_Authentication)objType.newInstance();
        request = authenticationService.applySecurity(request, authenticationConfig); //NOSONAR
        return request;
    }

    //This method will not have any effect until the field iaso__Headers_Class__c populated (not being used in great majority of iaso__GBL_integration_service__mdt records)
    private static HttpRequest modifyHeaders(HttpRequest request, String serviceName){
        iaso__GBL_integration_service__mdt serviceConfig =  DMT_Integration_Utils.getIntegrationServiceConfigFromServiceName(serviceName);
        if ( serviceConfig != null ){
            String className = serviceConfig.iaso__Headers_Class__c;
            if ( className != null && className.length() > 0 ){
                System.Type objType = Type.forName(className);
                iaso.GBL_Integration_Headers integrationHeaders = (iaso.GBL_Integration_Headers)objType.newInstance();
                request = integrationHeaders.modifyRequest(request); //NOSONAR
            }
        }
        return request;
    }

    public static iaso__GBL_Application_Log__c resetToken(String serviceName) {
        // ResetToken
        iaso__GBL_Authentication_Service__mdt authenticationConfig = DMT_Integration_Utils.getAuthenticationConfigFromService(serviceName);
        String iasoClassName = 'iaso_' + authenticationConfig.iaso__Apex_Class__c;
        System.Type objType = Type.forName(iasoClassName);
        if (objType == null) {
            throw new DMT_CustomException('Class not found: ' + iasoClassName);
        }
        iaso.GBL_Integration_Authentication authenticationService = (iaso.GBL_Integration_Authentication)objType.newInstance();
        return authenticationService.resetToken(authenticationConfig);
    }

    public static Boolean isAuthenticated(String serviceName) {
        // ResetToken
        iaso__GBL_Authentication_Service__mdt authenticationConfig = DMT_Integration_Utils.getAuthenticationConfigFromService(serviceName);
        String iasoClassName = 'iaso_' + authenticationConfig.iaso__Apex_Class__c;
        System.Type objType = Type.forName(iasoClassName);
        if (objType == null) {
            throw new DMT_CustomException('Class not found: ' + iasoClassName);
        }
        iaso.GBL_Integration_Authentication authenticationService = (iaso.GBL_Integration_Authentication)objType.newInstance();
        return authenticationService.isAuthenticated(authenticationConfig);
    }

    public static boolean isResetTokenResponse(Integer status) {
        return (status == OLD_CATALOG_EXPIRED_TOKEN || status == NEW_CATALOG_EXPIRED_TOKEN || status == NEW_CATALOG_EXPIRED_TOKEN_TMP);
    }

    public static DMT_Integration_GenericService.MockResponseWrapper getMockResponse(iaso__GBL_integration_service__mdt serviceConfig) {
        DMT_Integration_GenericService.MockResponseWrapper wrapper = new DMT_Integration_GenericService.MockResponseWrapper();
        if (DMT_Integration_Utils.isBlockedFromCustomSettings(serviceConfig.iaso__Custom_Setting__c)) {
            wrapper.isMockResponse=true;
            List<iaso__blockedService__mdt> result;
            if (mockBlockedServices.containsKey('Block_Mock_Service')) {
                result = new List<iaso__blockedService__mdt>{mockBlockedServices.get('Block_Mock_Service')};
            } else {
                result = [select Id, iaso__Blocked_Service_Response__c,iaso__Status_Code__c,iaso__Status__c from iaso__blockedService__mdt where DeveloperName = 'Block_Mock_Service' limit 1];
            }
            if (result.size()>0){
                wrapper.mockResponse = result.get(0).iaso__Blocked_Service_Response__c;
                wrapper.statusCode = (Integer)result.get(0).iaso__Status_Code__c;
                wrapper.status = result.get(0).iaso__Status__c;

            }
        } else{
            if (serviceConfig.iaso__Retrieve_Mock_LTA__c){
                wrapper.mockResponse = serviceConfig.iaso__Mock_LTA__c;
                wrapper.status = 'OK';
                if (serviceConfig.iaso__Http_Method__c == 'PUT'){
                    wrapper.statusCode = 201;
                }
                else{
                    wrapper.statusCode = 200;
                }
                wrapper.isMockResponse=true;
            }
            else{
                wrapper.mockResponse = '';
                wrapper.isMockResponse=false;
            }
        }
        return wrapper;
    }

    public static HttpResponse getMockHTTPResponse(DMT_Integration_GenericService.MockResponseWrapper mockwrapper){
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(mockWrapper.mockResponse);
        response.setStatus(mockWrapper.status);
        response.setStatusCode(mockWrapper.statusCode);
        return response;
    }

    public static iaso__GBL_Application_Log__c setLog(String serviceName, Datetime init, HttpRequest request, HttpResponse response, String headerTemplate){
        String headerStr = '';
        if (headerTemplate != null && !headerTemplate.equals('')) {
            Map <String, Object> headerMap = (Map <String, Object>)JSON.deserializeUntyped(headerTemplate);
            // Add all the configured headers
            for (String headerKey : headerMap.keySet()) {
                headerStr += '\n' + headerKey + ': ' + request.getHeader(headerKey);
            }
            if (!headerStr.containsIgnoreCase('x-channel-engine') && request.getHeader('x-channel-engine') != null){
                headerStr += '\n' + 'x-channel-engine' + ': ' + request.getHeader('x-channel-engine');
            }
            if (!headerStr.containsIgnoreCase('x-channel-cep-engine') && request.getHeader('x-channel-cep-engine') != null){
                headerStr += '\n' + 'x-channel-cep-engine' + ': ' + request.getHeader('x-channel-cep-engine');
            }
        }
        String respHeaderStr = '';
        for (String respHeader : response.getHeaderKeys()) {
            if (respHeader != 'tsec') {
                respHeaderStr += respHeader + ': ' + response.getHeader(respHeader) + '\n';
            }
        }
        string stMsg = 'REQUEST: ' + request.getEndpoint() + '\n'
                        + headerStr + '\n\n'
                        + getStringLimited(request.getBody())
                        + '\n--\n--\n\n'
                        + 'RESPONSE:\n'
                        + 'HTTP/1.1 ' + response.getStatusCode() + ' ' + response.getStatus() + '\n'
                        + respHeaderStr + getStringLimited(response.getBody());
        return new iaso__GBL_Application_Log__c(iaso__Start_Time__c = init,
                                            iaso__End_Time__c = Datetime.now(),
                                            iaso__Message_LTA__c = stMsg,
                                            Name = serviceName,
                                            iaso__Type__c = 'Integration',
                                            iaso__User__c = UserInfo.getUserId()
                                         );
    }

    private static string getStringLimited(String stBase) {
        if (stBase.length() > MAX_LENGTH) {
            return stBase.substring(0, MAX_LENGTH) + '( ' + (stBase.length() -  MAX_LENGTH) + ' more) ...';
        } else {
            return stBase;
        }
    }
}