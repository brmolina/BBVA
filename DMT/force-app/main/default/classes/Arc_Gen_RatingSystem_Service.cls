/**
* -----------------------------------------------------------------------------------------------
* @name        Arc_Gen_RatingSystem_Service
* @author      marcos.gimeno.next@bbva.com
* @date        05-02-2024
*
* @group       ARCE
* -----------------------------------------------------------------------------------------------
* Rating System class (Service layer)
* -----------------------------------------------------------------------------------------------
* @changes
* v1.0         marcos.gimeno.next@bbva.com
* 05-02-2024   Class creation.
* -----------------------------------------------------------------------------------------------
**/
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.ExcessivePublicCount,sf:OnlyOneReturn')
public with sharing class Arc_Gen_RatingSystem_Service {
    /** Map of rating system services by country */
    private static final Map<String, String> SERV_BY_CNTRY = new Map<String, String>{
        'ES' => 'ratingSystem_ES',
        'MX' => 'ratingSystem_MX'
    };
    /** Two constant */
    private static final Integer TWO = 2;
    /** Flow type for Corporates */
    private static final String FLOW_CORPORATES = 'corporates';
    /** Flow type for IFIS */
    private static final String FLOW_IFIS = 'ifis';
    /** Validation result for success */
    private static final String VAL_SUCCESS = 'SUCCESS';
    /** Validation result for error */
    private static final String VAL_ERROR = 'ERROR';
    /** Validation result for block */
    private static final String VAL_BLOCK = 'BLOCK';
    /** Validation result for warning */
    private static final String VAL_WARNING = 'WARNING';
    /** List of countries requiring encryption */
    private static final Set<String> ENCRYPT_CNTRIES = new Set<String>{ 'MX' };
    /** Validation result for info */
    private static final String VAL_INFO = 'INFO';
    /** Default value one */
    private static final String DEF_ONE = '1';
    /** Arce config custom metadata names */
    private static final Set<String> ARCE_CONFIGS = new Set<String>{
        'IRPModelsAvailable',
        'IFIS_AvailableModels',
        'ProspectModelsAvailable',
        'IFIS_ModelOptions',
        'UnitBookingOptions',
        'UnitBookingRS',
        'EnableRatingSystem'
    };
    /** Mock Arce config custom metadata name */
    private static final String ARCE_CONF_MOCK = 'AvailableModelsMock';
    /** Arce Map to avoid SonarQube issue */
    private static final Map<String, List<PickVal>> MAP_ARCE_CONFIG = new Map<String, List<PickVal>>();

    /*
    * Private constructor to avoid instantiation.
    */
    private Arc_Gen_RatingSystem_Service() {
        System.debug('Arc_Gen_RatingSystem_Service');
    }

    /**
    * Query the ArceConfig metadata record
    */
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
    * Query the persistence metadata records
    */
    public static Map<String, String> queryPersistenceMdt(Set<String> configNames) {
        final List<arce__Service_persistence__mdt> persRecords = [
            SELECT DeveloperName, arce__JSON_input__c
            FROM arce__Service_persistence__mdt
            WHERE DeveloperName IN :configNames
            WITH USER_MODE
        ];

        if (persRecords.isEmpty()) {
            throw new RatingSystemException('No persistence metadata records found');
        }

        final Map<String, String> persistenceMap = new Map<String, String>();
        for (arce__Service_persistence__mdt record : persRecords) {
            persistenceMap.put(record.DeveloperName, record.arce__JSON_input__c);
        }

        return persistenceMap;
    }

    /**
    * Call the rating system service.
    */
    public static ValidationResult callService(Id clientId, String selectedFlow, String bookingCountry) {
        final Map<String, String> serviceParams = setServiceParams(clientId, bookingCountry);
        final arce.Arc_Gen_getIASOResponse.ServiceResponse iasoResponse = calloutIASO(serviceParams, bookingCountry);
        final String ratingSystem = processResponse(iasoResponse);

        return validateRatingSystem(selectedFlow, ratingSystem, bookingCountry);
    }

    /**
    * Set the service parameters
    */
    private static Map<String, String> setServiceParams(Id clientId, String bookingCountry) {
        final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(
                new List<Id>{ clientId }
            )
            .get(clientId);

        if (accWrapper == null) {
            throw new RatingSystemException('Get account info failed');
        }

        final arce.Arc_Gen_User_Wrapper uInfo = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());

        if (uInfo == null) {
            throw new RatingSystemException('Get user info failed');
        }

        String customerNumber;
        if (ENCRYPT_CNTRIES.contains(bookingCountry)) {
            customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClientListRS(new List<String>{accWrapper.accNumber})[0];
        } else {
            customerNumber = accWrapper.accNumber;
        }

        if (String.isBlank(customerNumber)) {
            throw new RatingSystemException('Get encrypted client number failed');
        }

        // PENDING: Get parent subsidiary service to get economic group id and parent subsidiary id
        final Map<String, String> serviceParams = new Map<String, String>{
            Arc_Gen_ArceCore_Constants.PARTICIPANT_ID => customerNumber,
            Arc_Gen_ArceCore_Constants.ECONOMIC_GROUP_ID => '',
            Arc_Gen_ArceCore_Constants.BUSINESS_AGENT_ID => uInfo.businessAgentId,
            Arc_Gen_ArceCore_Constants.BANK_ID => accWrapper.bankId,
            Arc_Gen_ArceCore_Constants.BANK_BRANCH_ID => uInfo.branchId,
            Arc_Gen_ArceCore_Constants.BANK_BRANCH_L_ID => uInfo.branchlevel,
            Arc_Gen_ArceCore_Constants.REL_PARENT_SUBS => DEF_ONE
        };

        if (serviceParams.isEmpty()) {
            throw new RatingSystemException('Get service parameters failed');
        }

        return serviceParams;
    }

    /**
    * Call the IASO service
    */
    private static arce.Arc_Gen_getIASOResponse.ServiceResponse calloutIASO(Map<String, String> serviceParams, String bookingCountry) {
        return arce.Arc_Gen_getIASOResponse.calloutIASO(SERV_BY_CNTRY.get(bookingCountry), JSON.serialize(serviceParams));
    }

    /**
    * Process real service response
    */
    private static String processResponse(arce.Arc_Gen_getIASOResponse.ServiceResponse iasoResponse) {
        if (!iasoResponse.serviceCode.startsWith('20')) {
            throw new RatingSystemException(System.Label.Arc_Gen_RatingSystem_Error);
        }

        final ResponseWrapper response = (ResponseWrapper) JSON.deserialize(JSON.serialize(iasoResponse.serviceResponse).replaceAll('"id":', '"identifier":'),ResponseWrapper.class);

        // Check for error messages first
        if (response?.messages != null && !response.messages.isEmpty()) {
            throw new RatingSystemException(System.Label.Arc_Gen_RatingSystem_Error);
        }

        // Check if control validation failed
        if (response?.data?.controls != null && !response.data.controls.isEmpty()) {
            final ControlWrapper control = response.data.controls[0];
            if (control != null && control.isValid != null && !control.isValid) {
                return 'N/A';
            }
        }

        // Extract rating system ID from success response
        return response?.data?.ratingSystem?.identifier;
    }

    /**
    * Parse the configuration value
    */
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

    /**
    * Validate selected flow against Rating System result using JSON logic from metadata.
    */
    @SuppressWarnings('PMD.NcssMethodCount, sf:NPathComplexity, sf:DUDataflowAnomalyAnalysis')
    private static ValidationResult validateRatingSystem(String selectedFlow, String ratingSystem, String bookingCountry) {
        final Map<String, String> rsPicklistMap = arce.Arc_Gen_GenericUtilities.getMapPicklistValuesLabels('arce__AHA_Extension__c', 'arce__rating_system__c');
        final Map<String, String> taxoCodesJson = queryPersistenceMdt(new Set<String>{ 'Taxonomy_RS_Conditions' });
        final String rsValue = String.isBlank(ratingSystem) ? '' : ratingSystem;
        final String rsLabel = rsPicklistMap.isEmpty() ? '' : rsPicklistMap.get(ratingSystem);
        final TaxoRSCondWrapper taxoCodes = (TaxoRSCondWrapper) JSON.deserialize(taxoCodesJson.get('Taxonomy_RS_Conditions'), TaxoRSCondWrapper.class);
        final GeoRSCondWrapper geoCodes = taxoCodes.geographies.get(bookingCountry);

        // Handle special Rating System scenarios
        if (taxoCodes.special.contains(rsValue) || String.isBlank(rsValue)) {
            return createValidationResult(
                rsValue,
                VAL_INFO,
                VAL_INFO,
                System.Label.Arc_Gen_RatingSystem_NoAssignment,
                false
            );
        }

        // Handle success Rating System scenarios
        if ((geoCodes.corporates.contains(rsValue) && selectedFlow.equals(FLOW_CORPORATES)) || (geoCodes.ifis.contains(rsValue) && selectedFlow.equals(FLOW_IFIS))) {
            return createValidationResult(
                rsValue,
                VAL_SUCCESS,
                VAL_SUCCESS,
                String.format(System.Label.Arc_Gen_RatingSystem_Success, new List<String>{ rsLabel }),
                false
            );
        }

        // Handle Rating System mismatched scenarios - Corporates rating system but IFIS flow selected
        if (geoCodes.corporates.contains(rsValue) && selectedFlow.equals(FLOW_IFIS)) {
            return createValidationResult(
                rsValue,
                VAL_WARNING,
                VAL_WARNING,
                System.Label.Arc_Gen_RatingSystem_Corporate_Required,
                true
            );
        }

        // Handle Rating System mismatched scenarios - IFIS rating system but Corporates flow selected
        if (geoCodes.ifis.contains(rsValue) && selectedFlow.equals(FLOW_CORPORATES)) {
            return createValidationResult(
                rsValue,
                VAL_WARNING,
                VAL_WARNING,
                System.Label.Arc_Gen_RatingSystem_IFIS_Required,
                true
            );
        }

        // Handle default case for the remaining scenarios - Block scenario
        return createValidationResult(
            rsValue,
            VAL_BLOCK,
            VAL_ERROR,
            String.format(System.Label.Arc_Gen_RatingSystem_Blocked, new List<String>{ rsLabel }),
            true
        );
    }

    /**
    * Create validation result helper method.
    */
    @SuppressWarnings('PMD.ExcessiveParameterList, sf:UseObjectForClearerAPI')
    private static ValidationResult createValidationResult(String ratingSystem, String variant, String title, String message, Boolean isBlocked) {
        return new ValidationResult(ratingSystem, variant, title, message, isBlocked);
    }

    /**
    * Custom exception class for the Rating System service.
    */
    private class RatingSystemException extends Exception {
    }

    /**
    * Class to represent a picklist value.
    */
    public class PickVal {
        /** Value for picklist */
        @AuraEnabled
        public String value { get; set; }
        /** Label for Workflow picklist */
        @AuraEnabled
        public String label { get; set; }

        /**
        * Constructor for PickVal class
        */
        public PickVal(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    /**
    * Wrapper class for validation results
    */
    public class ValidationResult {
        /** The Rating System returned by the service */
        @AuraEnabled
        public String ratingSystem { get; set; }
        /** Validation title explaining the result */
        @AuraEnabled
        public String title { get; set; }
        /** Validation variant (SUCCESS, ERROR, WARNING) */
        @AuraEnabled
        public String variant { get; set; }
        /** Validation message explaining the result */
        @AuraEnabled
        public String message { get; set; }
        /** Flag indicating if the process is blocked due to rating system */
        @AuraEnabled
        public Boolean isBlocked { get; set; }

        /**
        * Constructor for ValidationResult
        */
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public ValidationResult(String ratingSystem, String title, String variant, String message, Boolean isBlocked) {
            this.ratingSystem = ratingSystem;
            this.title = title;
            this.variant = variant;
            this.message = message;
            this.isBlocked = isBlocked;
        }
    }

    /**
    * Wrapper class for the complete service response.
    */
    public class ResponseWrapper {
        /** Success data object containing rating system information */
        @AuraEnabled
        public DataWrapper data { get; set; }
        /** Error messages array */
        @AuraEnabled
        public List<ServiceMessage> messages { get; set; }
    }

    /**
    * Wrapper class for the data section of the response.
    */
    public class DataWrapper {
        /** Rating system information */
        @AuraEnabled
        public RatingSystemWrapper ratingSystem { get; set; }
        /** Controls array for validation responses */
        @AuraEnabled
        public List<ControlWrapper> controls { get; set; }        
    }

    /**
    * Wrapper class for rating system information.
    */
    public class RatingSystemWrapper {
        /** Rating system identifier */
        @AuraEnabled
        public String identifier { get; set; }
    }

    /**
    * Wrapper class for control validation information.
    */
    public class ControlWrapper {
        /** Control identifier */
        @AuraEnabled
        public String identifier { get; set; }
        /** Control description */
        @AuraEnabled
        public String description { get; set; }
        /** Validation flag */
        @AuraEnabled
        public Boolean isValid { get; set; }
    }

    /**
    * Wrapper class for service error messages.
    */
    public class ServiceMessage {
        /** Error code */
        @AuraEnabled
        public String code { get; set; }
        /** Error message */
        @AuraEnabled
        public String message { get; set; }
        /** Message parameters */
        @AuraEnabled
        public List<String> parameters { get; set; }
        /** Message type (FATAL, ERROR, WARNING, INFO) */
        @AuraEnabled
        public String type { get; set; }
    }


    /**
    * Wrapper class for rating system logic from JSON metadata.
    */
    private class TaxoRSCondWrapper {
        /** Map of geographies to their rating system conditions */
        @AuraEnabled
        public Map<String, GeoRSCondWrapper> geographies { get; set; }
        /** List of special rating systems (global across all geographies) */
        @AuraEnabled
        public List<String> special { get; set; }
    }

    /**
    * Wrapper class for geography-specific rating system conditions.
    */
    private class GeoRSCondWrapper {
        /** List of rating systems for corporates in this geography */
        @AuraEnabled
        public List<String> corporates { get; set; }
        /** List of rating systems for IFIS in this geography */
        @AuraEnabled
        public List<String> ifis { get; set; }
    }
}