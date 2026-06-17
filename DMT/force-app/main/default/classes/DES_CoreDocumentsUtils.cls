/**-------------------------------------------------------------------------------------------
* @Name     DMT  CoreDocuments Utils
* @Author   torcuato.tejada.tech@bbva.com
* @Date     Created: 2025-11-06
* ------------------------------------------------------------------------------------------------
* @Description Util methods for CoreDocuments and IASO Authentication implementation.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class DES_CoreDocumentsUtils {
    @TestVisible private static Integer overrideMockStatusCode = null;
    @TestVisible private static String overrideMockResponseBody = null;

    public static iaso__GBL_Authentication_Service__mdt getAuthenticationConfig(String authServiceName) {
        iaso__GBL_Authentication_Service__mdt authServiceConfig = null;
        authServiceConfig = iaso__GBL_Authentication_Service__mdt.getInstance(authServiceName);
        return authServiceConfig;
    }

    public static iaso__GBL_Authentication_Service__mdt getAuthenticationConfigFromService(String serviceName) {
        iaso__GBL_integration_service__mdt serviceConfig = null;
        serviceConfig = [select iaso__Authentication_Service__c from iaso__GBL_integration_service__mdt  where DeveloperName = :serviceName WITH SYSTEM_MODE limit 1];
        System.debug('DES_CoreDocumentsUtils.getAuthenticationConfigFromService serviceConfig, '+serviceConfig);
        return getAuthenticationConfig(serviceConfig.iaso__Authentication_Service__c);
    }

    /**
    * @description Provide the url from the GBL_Rest_Services_Url__c custom settings from the specified input name
    **/
    public static String getUrlFromCustomSettings(String customSettingKey) {
        iaso__GBL_Rest_Services_Url__c urlObj = null;
        try {
            //urlObj = [select name, Url__c from GBL_Rest_Services_Url__c where name = :customSettingKey limit 1];
            urlObj = iaso__GBL_Rest_Services_Url__c.getInstance(customSettingKey);
            return urlObj.iaso__Url__c;
        } catch (Exception e) {
            return '';
        }
    }
    /**
    * @description Decode the decrypted data for subsequent use
    * @param authentication service MDT with the info about the password
    * @return Decripted password
    **/
    public static String getPassword(iaso__GBL_Authentication_Service__mdt authServiceConfig) {
        Blob cryptoKey = EncodingUtil.base64Decode(authServiceConfig.iaso__CryptoKey__c);
        Blob encryptedPassword = EncodingUtil.base64Decode(authServiceConfig.iaso__Password__c);
        Blob decryptedData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encryptedPassword); //NOSONAR
        // Decode the decrypted data for subsequent use
        return decryptedData.toString();
    }

    /**
    * @description Get the pair "key" : "value"
    **/
    public static String getSimpleParamFromJSON(String jsonInput, String param) {
        // get the pair "key" : "value"
        String tmpstr = '';
        try {
            Integer initPos = jsonInput.indexOf('"' + param + '"');
            tmpstr = jsonInput.substring(initPos);
            Integer endPos = tmpstr.indexOf(',');
            if (endPos != -1) {
                tmpstr = tmpstr.substring(0, endPos);
            }
            // remove the "key" :
            tmpstr = tmpstr.substring(tmpstr.indexOf(':') + 1);
            // get the "value", string between ""
            tmpstr = tmpstr.substring(tmpstr.indexOf('"') + 1);
            tmpstr = tmpstr.substring(0, tmpstr.indexOf('"'));
        } catch (Exception e) {
            tmpstr = '';
        }
        return tmpstr;
    }

    /**
    * @description Get environment from url
    **/
    public static String getEnvironmentFromURL(iaso__GBL_Authentication_Service__mdt authenticationConfig) {
        String url = getUrlFromCustomSettings(authenticationConfig.iaso__Custom_Setting__c);
        if (url.contains('live')) {
            return 'PROD';
        } else {
            return 'INT';
        }
    }

    /**
    * @description Get integration service info from serviceName
    **/
    public static iaso__GBL_integration_service__mdt getIntegrationServiceInfo(String serviceName) {
        List<iaso__GBL_integration_service__mdt> lResult = [SELECT DeveloperName, iaso__Authentication_Service__c, iaso__Custom_Setting__c,
                                                    iaso__Http_Headers_LTA__c, iaso__Http_Method__c, iaso__Json_Input_Template_LTA__c,
                                                    iaso__Querystring_Input_Template_LTA__c, iaso__Retrieve_Mock_LTA__c, iaso__Description__c
                                                    FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =:serviceName WITH SYSTEM_MODE LIMIT 1];

        if ( lResult.isEmpty()) {
            return null;
        } else {
            return lResult.get(0);
        }
    }

    /**
     * @description Call service and return wrapper
     */
    public static HttpResponse callService(String serviceName, Map<String, Object> request) {
        request.put('userId', getFederationIdentifier());
        final String requestStr = JSON.serialize(request);
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = getMock(serviceName);
        } else {
            response = iaso.GBL_Integration_GenericService.invoke(serviceName, requestStr);
        }
        return response;
    }

    /**
     * @description Get mock response for test classes
     */
    public static HttpResponse getMock(String serviceName) {
        final HttpResponse response = new HttpResponse();
        final iaso__GBL_integration_service__mdt serviceDetails = [SELECT iaso__Mock_LTA__c , iaso__Http_Method__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =:serviceName WITH SYSTEM_MODE LIMIT 1];
        if (overrideMockStatusCode != null) {
            response.setStatusCode(overrideMockStatusCode);
            response.setBody(overrideMockResponseBody != null ? overrideMockResponseBody : '');
            return response;
        }
        final String responseBody = (String)serviceDetails.get('iaso__Mock_LTA__c');
        final String requestMethod = (String)serviceDetails.get('iaso__Http_Method__c');
        response.setStatus('OK');
        response.setStatusCode(requestMethod == 'GET' ? 200 : 201);
        response.setBody(responseBody);
        return response;
    }

    /*@description Get Federation Identifier of the current user
    * @return Federation Identifier
    */
    public static String getFederationIdentifier() {
        final Id userId = UserInfo.getUserId();
        final String res = [SELECT FederationIdentifier FROM User WHERE Id = :userId WITH SYSTEM_MODE].FederationIdentifier;
        return res;
    }

}