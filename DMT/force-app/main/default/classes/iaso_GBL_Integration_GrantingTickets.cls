/**
 * @group iaso (local)
 *
 * @description Local implementation of IASO BBVA authentication method.
 * This class mirrors the managed package GBL_Integration_GrantingTickets but exists in your org (no namespace)
 * so it can be used in parallel without conflicts.
 */
public with sharing class iaso_GBL_Integration_GrantingTickets implements iaso_GBL_Integration_Authentication {

    private static final String NAME = 'iaso_GBL_Integration_GrantingTickets';

    public Boolean isAuthenticated(iaso__GBL_Authentication_Service__mdt authenticationConfig) {
        DMT_Integration_Utils.logHeapLimit(NAME + '.isAuthenticated');
        Cache.Partition partition;
        String partitionName = authenticationConfig.iaso__Cache_Partition__c;

        // If the partition name starts with the namespace, remove it
        if (partitionName.startsWith('iaso.')) {
            partitionName = partitionName.substring(5); // remove 'iaso.'
        }

        if (!authenticationConfig.iaso__isOrgCache__c) {
            Cache.SessionPartition sessionPart = Cache.Session.getPartition(partitionName);
            partition = sessionPart;
        } else {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(partitionName);
            partition = orgPart;
        }

        Map<String, String> credentials = (Map<String, String>) partition.get(authenticationConfig.iaso__Cache_Key__c);
        return credentials != null && credentials.get('tsec') != null;
    }

    @SuppressWarnings('PMD.NCSSMethodCount')
    public iaso__GBL_Application_Log__c resetToken(iaso__GBL_Authentication_Service__mdt authenticationConfig) {
        DMT_Integration_Utils.logHeapLimit(NAME + '.resetToken');
        Datetime initTime = Datetime.now();
        Http http = new Http();
        HttpRequest validationRequest = new HttpRequest();
        validationRequest.setEndpoint(DMT_Integration_GenericService.getUrlFromCustomSettings(authenticationConfig.iaso__Custom_Setting__c));
        validationRequest.setMethod('POST');
        validationRequest.setHeader('Content-Type', 'application/json;charset=UTF-8');

        String validationRequestBody = '{"authentication":{"consumerID":"' +
            DMT_Integration_Utils.getSimpleParamFromJSON(authenticationConfig.iaso__Service_Parameters__c, 'consumerID') + '",' +
            '"authenticationData":[{"authenticationData":["' +
            DMT_Integration_Utils.getPassword(authenticationConfig) +
            '"],"idAuthenticationData":"' +
            DMT_Integration_Utils.getSimpleParamFromJSON(authenticationConfig.iaso__Service_Parameters__c, 'idAuthenticationData') + '"}]' +
            ',"authenticationType":"' +
            DMT_Integration_Utils.getSimpleParamFromJSON(authenticationConfig.iaso__Service_Parameters__c, 'authenticationType') +
            '","userID":"' + authenticationConfig.iaso__User__c + '"}}';

        validationRequest.setBody(validationRequestBody);

        HttpResponse response = http.send(validationRequest);

        List<Integer> validCodes = new List<Integer>{200, 202, 204};
        if (!validCodes.contains(response.getStatusCode())) {
            System.debug(logginglevel.ERROR, 'Unexpected status code: ' + response.getStatusCode() + ' ' + response.getStatus());
        } else {
            String tsec = response.getHeader(authenticationConfig.iaso__Header_Token__c);
            Map<String, String> credentials = new Map<String, String>();
            credentials.put('tsec', tsec);

            Cache.Partition partition;
            String partitionName = authenticationConfig.iaso__Cache_Partition__c;

            // If the partition name starts with the namespace, remove it
            if (partitionName.startsWith('iaso.')) {
                partitionName = partitionName.substring(5); // remove 'iaso.'
            }

            if (!authenticationConfig.iaso__isOrgCache__c) {
                Cache.SessionPartition sessionPart = Cache.Session.getPartition(partitionName);
                partition = sessionPart;
            } else {
                Cache.OrgPartition orgPart = Cache.Org.getPartition(partitionName);
                partition = orgPart;
            }
            partition.put(authenticationConfig.iaso__Cache_Key__c, credentials);
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
            iaso__Message_LTA__c = 'REQUEST: ' + validationRequest.getEndpoint() + '\n' + validationRequest.getBody() +
                             '\n--\n--\n\nRESPONSE:\n' + response.getBody(),
            Name = authenticationConfig.iaso__Custom_Setting__c,
            iaso__Type__c = 'Integration',
            iaso__User__c = UserInfo.getUserId()
        );
    }

    public HttpRequest applySecurity(HttpRequest request, iaso__GBL_Authentication_Service__mdt authenticationConfig) {
        DMT_Integration_Utils.logHeapLimit(NAME + '.resetToken');
        Cache.Partition partition;
        String partitionName = authenticationConfig.iaso__Cache_Partition__c;

        // If the partition name starts with the namespace, remove it
        if (partitionName.startsWith('iaso.')) {
            partitionName = partitionName.substring(5); // remove 'iaso.'
        }
        if (!authenticationConfig.iaso__isOrgCache__c) {
            Cache.SessionPartition sessionPart = Cache.Session.getPartition(partitionName);
            partition = sessionPart;
        } else {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(partitionName);
            partition = orgPart;
        }

        Map<String, String> credentials = (Map<String, String>) partition.get(authenticationConfig.iaso__Cache_Key__c);
        if (credentials != null && credentials.get('tsec') != null) {
            request.setHeader(authenticationConfig.iaso__Header_Token__c, credentials.get('tsec'));
        }

        return request;
    }
}