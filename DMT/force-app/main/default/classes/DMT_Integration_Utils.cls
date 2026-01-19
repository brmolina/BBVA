public with sharing class DMT_Integration_Utils {

    private static final String NAME = 'DMT_Integration_Utils';

    @TestVisible
    private static Map<String, iaso__GBL_integration_service__mdt> mockCmdtByName = new Map<String, iaso__GBL_integration_service__mdt>();

    public static void setMockCmdt(String name, iaso__GBL_integration_service__mdt cmdt) {
        mockCmdtByName.put(name, cmdt);
    }

    public static iaso__GBL_integration_service__mdt getFromCustomMetadata(String serviceName) {
        iaso__GBL_integration_service__mdt metObj = null;
        try {
            if (mockCmdtByName.containsKey(serviceName)) return mockCmdtByName.get(serviceName);
            System.debug(serviceName);
            metObj = [select iaso__Retrieve_Mock_LTA__c, iaso__Mock_LTA__c, iaso__Http_Headers_LTA__c, iaso__Querystring_Input_Template_LTA__c, iaso__Http_Method__c, iaso__Custom_Setting__c,
                        DeveloperName, iaso__Json_Input_Template_LTA__c, iaso__Authentication_Service__c, iaso__IsCacheable__c from iaso__GBL_integration_service__mdt
                        where DeveloperName = :serviceName WITH SYSTEM_MODE limit 1];
            return metObj;
        } catch (Exception e) {
            return null;
        }
    }

    public static iaso__GBL_Rest_Services_Url__c getFromCustomSettings(String customSettingKey) {
        System.debug('Custom Setting Key: ' + customSettingKey);
        iaso__GBL_Rest_Services_Url__c urlObj = null;
        try {
            urlObj = iaso__GBL_Rest_Services_Url__c.getInstance(customSettingKey);
            return urlObj;
        } catch (Exception e) {
            return null;
        }
    }

    public static iaso__GBL_Authentication_Service__mdt getAuthenticationConfigFromService(String serviceName) {
        iaso__GBL_integration_service__mdt serviceConfig = null;
        // query instead of getInstance to avoid 355 chars limitation in fields
        serviceConfig = [select iaso__Authentication_Service__c from iaso__GBL_integration_service__mdt
                        where DeveloperName = :serviceName WITH SYSTEM_MODE limit 1];
        return getAuthenticationConfig(serviceConfig.iaso__Authentication_Service__c);
    }

    public static iaso__GBL_Authentication_Service__mdt getAuthenticationConfig(String authServiceName) {
        iaso__GBL_Authentication_Service__mdt authServiceConfig = null;
        authServiceConfig = iaso__GBL_Authentication_Service__mdt.getInstance(authServiceName);
        return authServiceConfig;
    }

    public static String getSimpleParamFromJSON(String jsonInput, String param) {
        // get the pair "key" : "value"
        logHeapLimit(NAME + '.getSimpleParamFromJSON');
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
        logHeapLimit(NAME + '.getSimpleParamFromJSON');
        return tmpstr;
    }

    public static void logHeapLimit(string stPhase) {
        System.debug(logginglevel.FINE, stPhase + ': ' + Limits.getHeapSize() + '/'+ Limits.getLimitHeapSize());
    }

    public static String getPassword(iaso__GBL_Authentication_Service__mdt authServiceConfig) {
        Blob cryptoKey = EncodingUtil.base64Decode(authServiceConfig.iaso__CryptoKey__c);
        Blob encryptedPassword = EncodingUtil.base64Decode(authServiceConfig.iaso__Password__c);
        Blob decryptedData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encryptedPassword); //NOSONAR
        // Decode the decrypted data for subsequent use
        return decryptedData.toString();
    }

    public static Boolean isBlockedFromCustomSettings(String customSettingKey) {
        iaso__GBL_Rest_Services_Url__c urlObj = null;
        try {
            urlObj = iaso__GBL_Rest_Services_Url__c.getValues(customSettingKey);
            return urlObj.iaso__Blocked_Service__c;
        } catch (Exception e) {
            return false;
        }
    }

    public static iaso__GBL_integration_service__mdt getIntegrationServiceConfigFromServiceName(String serviceName){
        List<iaso__GBL_integration_service__mdt> lResult = [select iaso__Headers_Class__c,iaso__Authentication_Service__c, iaso__Custom_Setting__c, iaso__Http_Method__c, Id
            from iaso__GBL_integration_service__mdt where DeveloperName = :serviceName WITH SYSTEM_MODE limit 1];
        // query instead of getInstance to avoid 355 chars limitation in fields
        if ( lResult.isEmpty() ){
            return null;
        }
        else{
            return lResult.get(0);
        }
    }

    public static String getCacheKey(String key) {
        Blob myBlob = Blob.valueOf(key);
        Integer toReturn = EncodingUtil.base64Encode(myBlob).hashCode();
        if (toReturn < 0) {
            toReturn = toReturn * -1;
        }
        return String.valueOf(toReturn);
    }
}