global class DMT_Integration_GenericService implements Database.AllowsCallouts {

    // Static collector for log payloads across the transaction
    private static List<DMT_LogApplicationPayload> transactionLogPayloads = new List<DMT_LogApplicationPayload>();

    private static final String NAME = 'DMT_Integration_GenericService';

    public static GBL_Integration_Response callout(String serviceName, Map<String, Object> placeholderMap) {
        DMT_Integration_Utils.logHeapLimit(NAME + '.callout');
        iaso__GBL_integration_service__mdt serviceConfig = DMT_Integration_Utils.getFromCustomMetadata(serviceName);
        iaso__GBL_Rest_Services_Url__c csConfig = DMT_Integration_Utils.getFromCustomSettings(serviceConfig.iaso__Custom_Setting__c);

        CacheWrapper cacheInfo = DMT_Integration_Helper.getCacheInfo(csConfig);
        TemplateWrapper template = DMT_Integration_Helper.applyPlaceholders(serviceConfig,placeholderMap);

        Http http = new Http();
        HttpRequest request = DMT_Integration_Helper.setRequest(serviceConfig, csConfig, cacheInfo, template);
        Datetime init = Datetime.now();

        HttpResponse response = null;
        // Return the response from the service configuration Mock
        MockResponseWrapper mockWrapper = DMT_Integration_Helper.getMockResponse(serviceConfig);
        if (mockWrapper.isMockResponse) {
            response = DMT_Integration_Helper.getMockHTTPResponse(mockWrapper);
        } else {
            // Check cache if applicable
            if (serviceConfig.iaso__IsCacheable__c) {
                String cacheResponseBody = DMT_Integration_Helper.getCacheResponse(cacheInfo, request);
                if (cacheResponseBody != null) {
                    response = DMT_Integration_Helper.getCacheHTTPResponse(cacheResponseBody);
                }
            }
            if (response == null) {
                response = http.send(request);
                // Cache the response if applicable
                if (serviceConfig.iaso__IsCacheable__c) {
                    DMT_Integration_Helper.cacheResponse(request, response, cacheInfo);
                }
            }
        }

        System.debug('response ' + response.getBody());
        System.debug('response code ' + response.getStatusCode());

        GBL_Integration_Response intResponse = new GBL_Integration_Response();
        if (csConfig.iaso__Enable_Log__c) {
            intResponse.log = DMT_Integration_Helper.setLog(serviceName, init, request, response,template.headerTemplate);
        }
        intResponse.response = response;
        return intResponse ;
    }

    global static HttpResponse invoke(String serviceName, Map<String, Object> placeholderMap) {
        DMT_Integration_Utils.logHeapLimit(NAME + '.invoke');
        List<iaso__GBL_Application_Log__c> logList = new List<iaso__GBL_Application_Log__c>();

        iaso__GBL_integration_service__mdt serviceConfig = DMT_Integration_Utils.getFromCustomMetadata(serviceName);
        iaso__GBL_Rest_Services_Url__c csConfig = DMT_Integration_Utils.getFromCustomSettings(serviceConfig.iaso__Custom_Setting__c);
        Boolean bLogActive = csConfig.iaso__Enable_Log__c;

        if (!DMT_Integration_Helper.isAuthenticated(serviceName) && !serviceConfig.iaso__Retrieve_Mock_LTA__c && bLogActive) {
            logList.add(DMT_Integration_Helper.resetToken(serviceName));
        }

        GBL_Integration_Response intResponse = callout(serviceName, placeholderMap);

        HttpResponse response = intResponse.response;
        if (bLogActive) {
            logList.add(intResponse.log);
        }

        if (DMT_Integration_Helper.isResetTokenResponse(response.getStatusCode())) {
            iaso__GBL_Application_Log__c resetTokenLog = DMT_Integration_Helper.resetToken(serviceName);

            intResponse = callout(serviceName, placeholderMap);

            response = intResponse.response;
            if (bLogActive) {
                logList.add(intResponse.log);
            }

            if (DMT_Integration_Helper.isResetTokenResponse(response.getStatusCode())) {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
            }
        }

        if (bLogActive) {
            // Add to static collector instead of flushing immediately
            transactionLogPayloads.add(new DMT_LogApplicationPayload(logList));
        //    Database.executeBatch(new DMT_AsyncBatchJob(transactionLogPayloads), 1);  // Adjust batch size as needed
         //   transactionLogPayloads.clear();  // Reset
            /* DMT_Logger_Service.useQueueableMethod = System.isBatch()? true : iaso__GBL_Rest_Services_Url__c.getValues(serviceConfig.iaso__Custom_Setting__c).iaso__useEnqueueMethod__c;
            DMT_Logger_Service.flushLogList(logList); */
        }

        return response;
    }

    // New method to enqueue the batch once at transaction end
    public static void commitAllLogsViaBatch() {
        if (transactionLogPayloads.isEmpty()) {
            return;
        }

        if (System.isBatch() || System.isQueueable()) {
            // We’re already in an async context — process directly
            for (DMT_AsyncPayload payload : transactionLogPayloads) {
                try {
                    DMT_AsyncDispatcher.dispatch(payload);
                } catch (Exception e) {
                    System.debug('Error processing payload: ' + e.getMessage());
                }
            }
        } else {
            // Safe to enqueue a batch from sync or trigger context
            Database.executeBatch(new DMT_AsyncBatchJob(transactionLogPayloads), 200);
        }

        transactionLogPayloads.clear();
    }

    global static HttpResponse invoke(String serviceName, String jsonInput) {
        Map <String, Object> plmap = (Map <String, Object>)JSON.deserializeUntyped(jsonInput);
        return invoke(serviceName, plmap);
    }

    public static String getUrlFromCustomSettings(String customSettingKey) {
        iaso__GBL_Rest_Services_Url__c urlObj = null;
        try {
            urlObj = iaso__GBL_Rest_Services_Url__c.getInstance(customSettingKey);
            return urlObj.iaso__Url__c;
        } catch (Exception e) {
            return '';
        }
    }

    public class GBL_Integration_Response {
      public iaso__GBL_Application_Log__c log {get;set;}
      public HttpResponse response {get;set;}
    }

    public class MockResponseWrapper{
        public String mockResponse{get; set;}
        public String status{get; set;}
        public integer statusCode{get; set;}
        public boolean isMockResponse{get; set;}
    }

    public class CacheWrapper{
        public Integer timeout{get; set;}
        public Integer cacheTTL{get; set;}
        public String partitionName{get; set;}
        public boolean isCacheInOrg{get; set;}
    }

    public class TemplateWrapper{
        public String jsonTemplate{get; set;}
        public String queryStringTemplate{get; set;}
        public String headerTemplate{get; set;}
    }
}