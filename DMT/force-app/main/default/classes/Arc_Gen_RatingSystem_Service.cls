/**
* -----------------------------------------------------------------------------------------------
* @name        Arc_Gen_RatingSystem_Service
* @author      marcos.gimeno.next@bbva.com
* @date        05-02-2024
*
* @group       ARCE
* -----------------------------------------------------------------------------------------------
* @description Rating System class (Service layer)
* -----------------------------------------------------------------------------------------------
* @changes
* v1.0         marcos.gimeno.next@bbva.com
* 05-02-2024   Class creation.
* -----------------------------------------------------------------------------------------------
**/
public with sharing class Arc_Gen_RatingSystem_Service {
    /**
    * @description Rating system service name.
    */
    private static final String SERVICE_NAME = 'ratingSystems';
    /**
    * @description Two constant.
    */
    private static final Integer TWO = 2;
    /**
    * @description Persistence custom metadata names.
    */
    private static final Set<String> PERS_CONFIGS = new Set<String>{
        'Model_RS_Conditions',
        'IFIS_InstitutionTypes'
    };
    /**
    * @description  Arce config custom metadata names.
    */
    private static final Set<String> ARCE_CONFIGS = new Set<String>{
        'IRPModelsAvailable',
        'IFIS_AvailableModels',
        'IFIS_ModelOptions',
        'UnitBookingOptions',
        'UnitBookingRS',
        'EnableRatingSystem'
    };
    /**
    * @description Mock Arce config custom metadata name.
    */
    private static final String ARCE_CONF_MOCK = 'AvailableModelsMock';
    /**
    * @description Arce Map to avoid SonarQube issue.
    */
    private static final Map<String, List<PickVal>> MAP_ARCE_CONFIG = new Map<String, List<PickVal>>();
    /*
    * @description Private constructor to avoid instantiation.
    */
    private Arc_Gen_RatingSystem_Service() {
    }
    /**
    * @description Mock value for rating system.
    */
    private static String ratingSystemMockVal;

    /**
    * @description Custom exception class for the Rating System service.
    */
    private class RatingSystemException extends Exception {
    }

    /**
    * @description Class to represent a picklist value.
    */
    public class PickVal {
        /**
        * @description value for picklist.
        */
        @AuraEnabled
        public String value { get; set; }

    /**
        * @description Label for Workflow picklist.
        */
        @AuraEnabled
        public String label { get; set; }

        /**
        * @description Constructor for PickVal class.
        * @param value The value for picklist.
        * @param label The label for Workflow picklist.
        */
        public PickVal(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Query the ArceConfig metadata record.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        26-04-2024
    * @return      Json string with the ArceConfig metadata record.
    * @example     queryArceConfigMdt();
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('sf:AvoidUsingTestIsRunningTest')
    public static String queryArceConfigMdt() {
        final Boolean isMock = Test.isRunningTest();
        final Set<String> selConfigNames = isMock ? new Set<String>{ ARCE_CONF_MOCK } : ARCE_CONFIGS;

        final List<arce__Arce_Config__mdt> listArceConfig = [
            SELECT
                Id,
                arce__Value1__c,
                arce__Custom_Permissions__c,
                arce__Config_Name__c,
                DeveloperName,
                NamespacePrefix
            FROM arce__Arce_Config__mdt
            WHERE arce__Config_Name__c IN :selConfigNames
            WITH USER_MODE
        ];

        if (listArceConfig.isEmpty()) {
            throw new RatingSystemException('No ArceConfig metadata records found');
        }

        for (arce__Arce_Config__mdt config : listArceConfig) {
            MAP_ARCE_CONFIG.put(config.arce__Config_Name__c, parseConfigValue(config.arce__Value1__c));
        }

        return JSON.serialize(MAP_ARCE_CONFIG);
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Query the persistence metadata record.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.next@bbva.com
    * @date        05-02-2024
    * @return      Json string with the persistence metadata record.
    * @throws      RatingSystemException if no access to the metadata type or no records found.
    * -----------------------------------------------------------------------------------------------
    **/
    public static String queryPersistenceMdt() {
        final List<arce__Service_persistence__mdt> persRecords = [
            SELECT DeveloperName, arce__JSON_input__c
            FROM arce__Service_persistence__mdt
            WHERE DeveloperName IN :PERS_CONFIGS
            WITH USER_MODE
        ];

        if (persRecords.isEmpty()) {
            throw new RatingSystemException('No persistence metadata records found');
        }

        final Map<String, String> persistenceMap = new Map<String, String>();
        for (arce__Service_persistence__mdt record : persRecords) {
            persistenceMap.put(record.DeveloperName, record.arce__JSON_input__c);
        }

        return JSON.serialize(persistenceMap);
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Check if the object is readable.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        26-04-2024
    * @param       objType The object type.
    * @return      void
    * @example     checkObjectIsReadable(Schema.SObjectType objType);
    * -----------------------------------------------------------------------------------------------
    **/
    public static void checkObjectIsReadable(Schema.SObjectType objType) {
        if (!objType.getDescribe().isAccessible()) {
            throw new RatingSystemException('No access to the Sobject type');
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Call the rating system service.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        26-04-2024
    * @param       clientId The client ID.
    * @return      String with the rating system.
    * @example     callService(Id clientId);
    * -----------------------------------------------------------------------------------------------
    **/
    // public static String callService(Id clientId) {
    //     if (String.isBlank(clientId)) {
    //         throw new RatingSystemException('Record ID cannot be null or empty');
    //     }
    //    }

    //     final Map<String, String> serviceParams = setServiceParams(clientId);
    //     final arce.Arc_Gen_getIASOResponse.ServiceResponse iasoResponse = calloutIASO(serviceParams);
    //     final String iasoRSResponse = processResponse(iasoResponse);

    //     return getRatingSystemFromResponse(iasoRSResponse);
    // }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Set the service parameters.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        26-04-2024
    * @param       clientId The client ID.
    * @return      Map with the service parameters.
    * @example     setServiceParams(Id clientId);
    * -----------------------------------------------------------------------------------------------
    **/
    // private static Map<String, String> setServiceParams(Id clientId) {
    //     final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(
    //             new List<Id>{ clientId }
    //         )
    //         .get(clientId);

     //     if (accWrapper == null) {
    //         throw new RatingSystemException('Get account info failed');
    //     }

    //     final arce.Arc_Gen_User_Wrapper uInfo = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());

    //     if (uInfo == null) {
    //         throw new RatingSystemException('Get user info failed');
    //     }

    //     final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accWrapper.accNumber);

    //     if (String.isBlank(customerNumber)) {
    //         throw new RatingSystemException('Get encrypted client number failed');
    //     }

    //     // TODO: Get parent subsidiary service to get economic group id and parent subsidiary id

    //     final Map<String, String> serviceParams = new Map<String, String>{
    //         Arc_Gen_ArceCore_Constants.PARTICIPANT_ID => customerNumber,
    //         Arc_Gen_ArceCore_Constants.ECONOMIC_GROUP_ID => '',
    //         Arc_Gen_ArceCore_Constants.BUSINESS_AGENT_ID => uInfo.businessAgentId,
    //         Arc_Gen_ArceCore_Constants.BANK_ID => accWrapper.bankId,
    //         Arc_Gen_ArceCore_Constants.BANK_BRANCH_ID => uInfo.branchId,
    //         Arc_Gen_ArceCore_Constants.BANK_BRANCH_L_ID => uInfo.branchlevel,
    //         Arc_Gen_ArceCore_Constants.REL_PARENT_SUBS => ''
    //     };

    //     if (serviceParams.isEmpty()) {
    //         throw new RatingSystemException('Service parameters are invalid');
    //     }

    //     return serviceParams;
    // }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Call the IASO service.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        26-04-2024
    * @param       serviceParams The service parameters.
    * @return      The iaso response.
    * @example     calloutIASO(Map<String, String> serviceParams);
    * -----------------------------------------------------------------------------------------------
    **/
    // private static arce.Arc_Gen_getIASOResponse.ServiceResponse calloutIASO(Map<String, String> serviceParams) {
    //     try {
    //         return arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, JSON.serialize(serviceParams));
    //     } catch (Exception e) {
    //         throw new RatingSystemException('Unexpected error calling the IASO service');
    //     }
    // }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Process the IASO response.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        26-04-2024
    * @param       iasoResponse The IASO response.
    * @return      The rating system.
    * @example     processResponse(arce.Arc_Gen_getIASOResponse.ServiceResponse iasoResponse);
    * @throws      RatingSystemException if the service code is not 200 or 201.
    * @throws      RatingSystemException if the rating system service response is invalid or empty.
    * -----------------------------------------------------------------------------------------------
    **/
    // private static String processResponse(arce.Arc_Gen_getIASOResponse.ServiceResponse iasoResponse) {
    //     final arce.Arc_Gen_ServiceAndSaveResponse servSaveResponse = new arce.Arc_Gen_ServiceAndSaveResponse();
    //     final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
    //     String iasoRSResponse;

    //        if (
    //         iasoResponse.serviceCode != String.valueOf(serviceMessage.CODE_200) &&
    //         iasoResponse.serviceCode != String.valueOf(serviceMessage.CODE_201)
    //     ) {
    //         throw new RatingSystemException(iasoResponse.serviceCode + ' - ' + iasoResponse.serviceMessage);
    //     }

            //     final iaso__GBL_integration_service__mdt integServ = arce.Arc_Gen_getIASOResponse.getIntegrationServiceConfigFromServiceName(
    //         SERVICE_NAME
    //     );
    //     final Boolean isMock = Test.isRunningTest() || (integServ != null && integServ.iaso__Retrieve_Mock_LTA__c);

    //     Map<String, Object> data = new Map<String, Object>();
    //     if (isMock) {
    //         ResponseWrapper response = (ResponseWrapper) JSON.deserialize(
    //             integServ.iaso__Mock_LTA__c,
    //             ResponseWrapper.class
    //         );
    //         data.put('controls', response.data.controls);
    //         data.put('ratingSystem', response.data.ratingSystem);

    //         // Store mock value in a static variable
    //         ratingSystemMockVal = response.data.ratingSystem[0].id;
    //     } else {
    //         final String jsonString = JSON.serialize(iasoResponse.serviceResponse);
    //         ResponseWrapper response = (ResponseWrapper) JSON.deserialize(jsonString, ResponseWrapper.class);
    //         data.put('controls', response.data.controls);
    //         data.put('ratingSystem', response.data.ratingSystem);
    //     }

    //     List<RatingSystemWrapper> ratingSystems = (List<RatingSystemWrapper>) data.get('ratingSystem');
    //     if (ratingSystems != null && !ratingSystems.isEmpty()) {
    //         iasoRSResponse = ratingSystems[0].id;
    //     } else {
    //         throw new RatingSystemException('Rating system service response is invalid or empty');
    //     }

    //     return iasoRSResponse;
    // }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Get the rating system from the response.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        26-04-2024
    * @param       calloutResponse The callout response.
    * @return      The rating system.
    * @example     getRatingSystemFromResponse(String calloutResponse);
    * @throws      RatingSystemException if the rating system picklist is not found.
    * @throws      RatingSystemException if the selected rating system is not found in the picklist.
    * -----------------------------------------------------------------------------------------------
    **/
    // private static String getRatingSystemFromResponse(String calloutResponse) {
    //     final String sObjectName = Schema.SObjectType.arce__Analysis__c.getName();
    //     final String customFieldName = Schema.SObjectType.arce__Analysis__c.fields.arce__rating_system_type__c.getName();
    //     final List<Map<String, String>> rsPickValueLabel = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels(
    //         sObjectName,
    //         customFieldName
    //     );

    //     if (rsPickValueLabel.isEmpty()) {
    //         throw new RatingSystemException('Rating system picklist not found');
    //     }

    //     final String selectedRatingSystem;

    //     if (String.isBlank(ratingSystemMockVal)) {
    //         for (Map<String, String> rsValueLabel : rsPickValueLabel) {
    //             if (rsValueLabel.get('label').equals(calloutResponse)) {
    //                 selectedRatingSystem = rsValueLabel.get('label');
    //                 break;
    //             }
    //         }
    //     } else {
    //         selectedRatingSystem = ratingSystemMockVal;
    //     }

    //     if (String.isBlank(selectedRatingSystem)) {
    //         throw new RatingSystemException('Selected rating system is not found in the picklist');
    //     }

    //     return selectedRatingSystem;
    // }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Parse the configuration value.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.next@bbva.com
    * @date        05-02-2024
    * @param       configValue String with the configuration value.
    * @return      List of PickVal objects.
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<PickVal> parseConfigValue(String configValue) {
        final List<PickVal> modelOptions = new List<PickVal>();
        final List<String> options = configValue.split(';');
        for (String option : options) {
            final List<String> keyValue = option.split(':');
            if (keyValue.size() == TWO) {
                modelOptions.add(new PickVal(keyValue[0], keyValue[1]));
            } else {
                modelOptions.add(new PickVal(keyValue[0], keyValue[0])); 
            }
        }
        return modelOptions;
    }
}