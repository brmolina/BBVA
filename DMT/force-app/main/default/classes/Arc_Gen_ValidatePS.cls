/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidatePS
* @Author   aleksandar.dinkov.contractor@bbva.com
* @Date     Created: 06/11/2023
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Arc_Gen_ValidatePS
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |06-11-2023 aleksandar.dinkov.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_ValidatePS {
    /**
    * @description String "OK" value.
    */
    public static final String VALUE_OK = 'OK';
    /**
    * @description String "200" value.
    */
    public static final String VALUE_200 = '200';
    /**
    * @description String "Success" value.
    */
    public static final String VALUE_SUCCESS = 'Success';
    /**
    * @description String "Success" value.
    */
    public static final String VALUE_ERROR = 'Error';
    /**
    * @description String "Success" value.
    */
    public static final String VALUE_REFRESH_PS = 'RefreshPS'; 
    /**
    * @Description: subsidiary type
    */
    private static final String SUBSIDIARY = '2';
    /**
    * @Description: String with value "Client"
    */
    static final string CLIENT = 'SUBSIDIARY';
    /**
    * @Description: String with value "Core"
    */
    static final string VALUE_CORE = 'Core';
    /**
    * @Description: String with value "both"
    */
    static final string VALUE_BOTH = 'both';
    /**
    * @Description: '"identifier":' literal 
    */
    public static final String ID_VAR = '"identifier":';
    /**
    * @Description: '"id":' literal
    */
    public static final String ID_SERV = '"id":';
    /**
    * @Description: '"relationPS":' literal
    */
    public static final String REL_PS_VAR = '"relationPS":';
    /**
    * @Description: '"relationParentSubsidiary":' literal
    */
    public static final String REL_PS_SERV = '"relationParentSubsidiary":';
    /**
    * @Description: '"qualiVars":' literal
    */
    public static final String QUAL_VARS_VAR = '"qualiVars":';
    /**
    * @Description: '"qualitativeVariables":' literal
    */
    public static final String QUAL_VARS_SERV = '"qualitativeVariables":';
    /**
    * @Description: '2021RTC_EXPG'
    */
    public static final String RTC_EXPG = '2021RTC_EXPG';
    /**
    * @description Service name
    */
    public static final String SERVICE_NAME = Test.isRunningTest() ? 'parentSubsidiaryQualitativesMock' : 'parentSubsidiaryQualitatives';
    /**
    * Constructor
    **/
    @TestVisible
    private Arc_Gen_ValidatePS() {}
    /**
    * @Class: MessageResponse
    * @Description: Container that contains the message for the Lightning component as a response
    * @author BBVA
    */
    public class MessageResponse {
        /**
        * @Description: Indicates status
        */
        @AuraEnabled public String status {get;set;}
        /**
        * @Description: Indicates message
        */
        @AuraEnabled public String message {get;set;}
        /**
        * @Description: Indicates bannerMessage
        */
        @AuraEnabled public String bannerMessage {get;set;}
        /**
        * @description MessageResponse constructor
        * @author aleksandar.dinkov.contractor@bbva.com | 06-11-2023
        **/
        public MessageResponse() {
            status = VALUE_SUCCESS;
            message = VALUE_OK;
        }
    }

    /**
    * @description retrieves Parent Subsidiary data from web service
    * @author aleksandar.dinkov.contractor@bbva.com | 06-11-2023
    * @param String ahaId
    * @return MessageResponse
    **/
    @AuraEnabled
    public static MessageResponse callParentSubsidiary(String ahaId, Boolean isTest) {
        final MessageResponse msgResp = new MessageResponse();
        try {
            final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ahaId})[0];
            final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(accHasAnalysis);
            final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id> { clientId }).get(clientId);
            final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accWrapper.accNumber);
            final Map<String,String> params = new Map<String,String>{ 'participantId' => customerNumber};
            final arce__AHA_Extension__c ahaExt = (arce__AHA_Extension__c) getSObjectInfo('arce__AHA_Extension__c', accHasAnalysis.arce__AHA_Extension__c, null);
            final Boolean isRaipCorp = isRaipCorpBool(isTest);
            arce.Arc_Gen_getIASOResponse.ServiceResponse sResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
            if (accWrapper.participantType == CLIENT && ahaExt.arce__PS_Successfully_Retrieved__c && isRaipCorp) {
                sResponse = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, JSON.serialize(params));
                if (sResponse.serviceCode == VALUE_200) {
                    final Map<String,Object> data = (Map<String,Object>) sResponse.serviceResponse;
                    final ServRespWrapper respWrap = (ServRespWrapper) JSON.deserialize(JSON.serialize(data.get('data')).replaceAll(QUAL_VARS_SERV, QUAL_VARS_VAR).replaceAll(ID_SERV, ID_VAR).replaceAll(REL_PS_SERV, REL_PS_VAR), ServRespWrapper.class);
                    if (accHasAnalysis.arce__RAR_rating_tool_id__c == RTC_EXPG) {
                        validateEXPG(respWrap, ahaId, msgResp);
                    } else {
                        serviceDataValidations(respWrap, ahaId, msgResp, ahaExt);
                    }
                } else if (String.isNotBlank(sResponse.serviceMessage)) {
                    msgResp.status = VALUE_ERROR;
                    msgResp.message = sResponse.serviceCode + ': ' + sResponse.serviceMessage;
                }
            }
            } catch (Exception ex) {
            processExceptionError(msgResp, ex);
        }
        return msgResp;
    }

        /**
    * @description serviceDataValidations, validates the response from the service and sets the message response.
    * @author aleksandar.dinkov.contractor@bbva.com | 06-11-2023
    * @param ServRespWrapper respWrap
    * @param String ahaId
    * @param MessageResponse msgResp
    * @param arce__AHA_Extension__c ahaExt
    **/
    @SuppressWarnings('sf:ConfusingTernary')
    private static void serviceDataValidations(ServRespWrapper respWrap, String ahaId, MessageResponse msgResp, arce__AHA_Extension__c ahaExt) {
        if (!respWrap.relations.isEmpty()) {
            final arce__Overlay__c actualOverlay = arce.Arc_Gen_Overlays_Utils.getOverlayMapByAha(new Set<Id>{ahaId}).get(ahaId)[0];
            final Map<String,List<String>> structure = (Map<String,List<String>>) JSON.deserialize(actualOverlay.arce__Arc_Gen_ParentGroups__c, Map<String,List<String>>.class);
            final Boolean equalAlpha = structure.containsKey(respWrap.relations[0].matrix.identifier);
            if (!equalAlpha) {
                msgResp.status = VALUE_ERROR;
                msgResp.message = System.Label.Arc_Gen_Different_PS_Alpha;
            } else if (validatePsRelation(ahaExt, respWrap)) {
                msgResp.status = VALUE_ERROR;
                msgResp.message = System.Label.Arc_Gen_Different_PS_Relation;
            } else if (actualOverlay.arce__Arc_Gen_PS_Relationship_Id__c != respWrap.relations[0].identifier) {
                msgResp.status = VALUE_REFRESH_PS;
                msgResp.message = System.Label.Arc_Gen_Different_PS_Id;
            } else if (validatePsExpiration(respWrap)) {
                msgResp.status = VALUE_ERROR;
                msgResp.message = System.Label.Arc_Gen_Expired_PS_Relation;
            }
        } else {
            msgResp.status = VALUE_ERROR;
            msgResp.message = System.Label.Arc_Gen_Empty_Relations_Node;
        }
    }

    /**
    * @description validateEXPG, validates the response from the service for EXPG and sets the message response.
    * @author aleksandar.dinkov.contractor@bbva.com | 06-11-2023
    * @param ServRespWrapper respWrap
    * @param String ahaId
    * @param MessageResponse msgResp
    **/
    private static void validateEXPG(ServRespWrapper respWrap, String ahaId, MessageResponse msgResp) {
        // Se habilita o deshabilita la validacion con un metadata de configuracion.
        // Se valida si trata de una UTE con informacion desactualizada.
        final List<arce__Arce_Config__mdt> config = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Enable_Validate_EXPG');
        if (!config.isEmpty() && Boolean.ValueOf(config[0].arce__Value1__c)) {
            final arce__Overlay__c actualOverlay = arce.Arc_Gen_Overlays_Utils.getOverlayMapByAha(new Set<Id>{ahaId}).get(ahaId)[0];
            if (actualOverlay.arce__Arc_Gen_IsUTE__c == 'UNSET' || !respWrap.relations.isEmpty() && actualOverlay.arce__Arc_Gen_PS_Relationship_Id__c != respWrap.relations[0].identifier) {
                msgResp.status = VALUE_REFRESH_PS;
                msgResp.message = System.Label.Arc_Gen_Different_PS_Id;
            }
        }
    }

    /**
    * @description processExceptionError, sets the message response in case of an exception error and logs the error message and stack trace.
    * @author aleksandar.dinkov.contractor@bbva.com | 27-03-2025
    * @param MessageResponse msgResp
    * @param Exception ex
    **/
    private static void processExceptionError(MessageResponse msgResp, Exception ex) {
        if (ex.getMessage().contains('Invalid format') || ex.getMessage().contains('Unexpected character')) {
            msgResp.status = VALUE_ERROR;
            msgResp.message = System.Label.Arc_Gen_PS_Invalid_Data;
        } else {
            msgResp.status = VALUE_ERROR;
            msgResp.message = ex.getMessage();
        }
        System.debug(LoggingLevel.ERROR, ex.getMessage());
        System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
    }

    /**
    * @description validatePsRelation, returns true if actual ARCE should be bloqued based on actual criteria.
    * @author aleksandar.dinkov.contractor@bbva.com | 15-04-2024
    * @param arce__AHA_Extension__c ahaExt
    * @param String recordId
    * @return SObject
    **/
    public static Boolean validatePsRelation(arce__AHA_Extension__c ahaExt, ServRespWrapper respWrap) {
        Boolean returnValue = false;
        final List<arce__Arce_Config__mdt> config = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Enable_Validation_PS');
        // Se habilita o deshabilita la validacion con un metadata de configuracion.
        if (!config.isEmpty() && Boolean.ValueOf(config[0].arce__Value1__c)) {
            // Este metadata contiene las combinaciones bloqueantes resultantes de comparar el id de relacion del front unico
            // contra el valor del campo arce__filial_Core__c del objeto arce__AHA_Extension__c.
            // Por ejemplo: "1:false" significa que cuando el servicio devuelve id de relacion 1 y el valor del campo arce__filial_Core__c es false,
            // el resultado es bloqueante.
            final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Validation_PS_Blockers_Cases');
            Map<String, String> valdPsBlock = new Map<String, String>();
            if (!configs.isEmpty()) {
                // Se utiliza el simbolo ";" para separar cada combinacion:
                final List<String> configValuesList = configs[0].arce__Value1__c.split(';');
                for (String var : configValuesList) {
                    // Se utiliza el simbolo ":" para separar los valores de cada combinacion bloqueante.
                    valdPsBlock.put(var.substringBefore(':'), var.substringAfter(':'));
                }
            }
            final String currntPsId = respWrap.relations[0].relationPS.identifier;
            final String actualBlocker = valdPsBlock.get(currntPsId);
            // Cualquier id de relacion que no se encuentre en el metadata de configuracion sera considerado un caso bloqueante.
            returnValue = actualBlocker == null || actualBlocker.equalsIgnoreCase(VALUE_BOTH) || (actualBlocker != null && Boolean.valueOf(actualBlocker) == ahaExt.arce__filial_Core__c)  ? true : false;
        }
        return returnValue;
    }
     /**
    * @description validatePsExpiration, returns true if actual ARCE should be bloqued based on actual criteria.
    * @author aleksandar.dinkov.contractor@bbva.com | 18-03-2025
    * @param ServRespWrapper respWrap
    * @return Boolean
    **/
    public static Boolean validatePsExpiration(ServRespWrapper respWrap) {
        Boolean returnValue = false;
        // Se habilita o deshabilita la validacion con un metadata de configuracion.
        // Se valida si la relacion de front unico ha expirado.
        final List<arce__Arce_Config__mdt> config = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('Enable_Validate_PS_Expiration');
        if (!config.isEmpty() && Boolean.ValueOf(config[0].arce__Value1__c) && respWrap.relations[0].expirationDate != null && respWrap.relations[0].expirationDate < Date.today()) {
            returnValue = true;
        }
        return returnValue;
    }

    /**
    * @description getSObjectInfo
    * @author aleksandar.dinkov.contractor@bbva.com | 09-11-2023
    * @param String objectName
    * @param String recordId
    * @return SObject
    **/
    public static SObject getSObjectInfo(String objectName, String recordId, List<String> moreFields) {
        String queryString = 'SELECT ' + arce.Arc_Gen_GenericUtilities.getAllFields(objectName);
        queryString += moreFields == null ? '' : ',' + String.join(moreFields, ',');
        queryString += ' FROM '+ objectName + ' WHERE Id =: recordId';
        return Database.query(String.escapeSingleQuotes(queryString));
    }

     /**
    * --------------------------------------------------------------------------------------
    * @Description get Boolean RaipCorp
    * --------------------------------------------------------------------------------------
    * @Author adrian.caro.next@bbva.com
    * @Date 2024-16-01
    * @param Boolean isTest
    * @return Boolean
    * @example Arc_Gen_ValidatePS.isRaipCorpBool(true)
    * --------------------------------------------------------------------------------------
    **/
    public static Boolean isRaipCorpBool(Boolean isTest) {
        return isTest ? true : Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow')[0].arce__Value1__c);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Wrapper used to describe parent subsidiary service response.
    *-------------------------------------------------------------------------------
    **/
    private class ServRespWrapper {
        /**
        * @Description: List<Relations> relations
        */
        private List<Relations> relations;
    }
    /**
    * @Description: class Participant
    */
    private class Participant {
        /**
        * @Description: String name
        */
        private String name;
        /**
        * @Description: String country
        */
        private String country;
    }
    /**
    * @Description: class Matrix
    */
    private class Matrix {
        /**
        * @Description: String identifier
        */
        private String identifier;
        /**
        * @Description: String name
        */
        private String name;
        /**
        * @Description: String country
        */
        private String country;
    }
    /**
    * @Description: class Status
    */
    private class Status {
        /**
        * @Description: String identifier
        */
        private String identifier;
    }
    /**
    * @Description: class Audit
    */
    private class Audit {
        /**
        * @Description: String comments
        */
        private String comments;
    }
    /**
    * @Description: class RelationParentSubsidiary
    */
    private class RelationParentSubsidiary {
        /**
        * @Description: String identifier
        */
        private String identifier;
        /**
        * @Description: String description
        */
        private String description;
    }
    /**
    * @Description: class QualitativeVariables
    */
    private class QualitativeVariables {
        /**
        * @Description: String identifier
        */
        private String identifier;
        /**
        * @Description: String value
        */
        private String value;
        /**
        * @Description: String variableType
        */
        private String variableType;
        /**
        * @Description: String parentCode
        */
        private String parentCode;
    }
    /**
    * @Description: class BusinessAgent
    */
    private class BusinessAgent {
        /**
        * @Description: String identifier
        */
        private String identifier;
        /**
        * @Description: String fullName
        */
        private String fullName;
    }
    /**
    * @Description: class Relations
    */
    private class Relations {
        /**
        * @Description: String identifier
        */
        private String identifier;
        /**
        * @Description: String riskSegment
        */
        private String riskSegment;
        /**
        * @Description: Datetime creationDate
        */
        private Datetime creationDate;
        /**
        * @Description: Datetime evaluationDate
        */
        private Datetime evaluationDate;
        /**
        * @Description: Datetime validationDate
        */
        private Datetime validationDate;
        /**
        * @Description: Datetime expirationDate
        */
        public Datetime expirationDate;
        /**
        * @Description: Participant participant
        */
        private Participant participant;
        /**
        * @Description: Matrix matrix
        */
        private Matrix matrix;
        /**
        * @Description: Status status
        */
        private Status status;
        /**
        * @Description: BusinessAgent businessAgent
        */
        private BusinessAgent businessAgent;
        /**
        * @Description: Matrix matrix
        */
        private Audit audit;
        /**
        * @Description: Boolean insulated
        */
        private Boolean insulated;
        /**
        * @Description: Boolean relationPS
        */
        public RelationParentSubsidiary relationPS;
        /**
        * @Description: List<QualitativeVariables> qualiVars
        */
        public List<QualitativeVariables> qualiVars;
    }
}