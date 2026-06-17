/**
 * @description       : Clase controladora del conjunto de LWC de la funcionalidad "aiChatRobot2"
 * @author            : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * @group             : NEORIS
 * @last modified on  : 07-04-2026
 * @last modified by  : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   28-11-2025   Javier Setién Rivas - [javier_setien@epamneoris.com]   Initial Version
 * 1.0   15-12-2025   Matías Maquieira - [matias_maquieira@epamneoris.com]   Implementación de feedback de mensajes
 * 1.0   19-12-2025   Javier Setién Rivas - [javier_setien@epamneoris.com]   Implementación de guardado de logs de error
 **/
public with sharing class aiChatRobot2Controller {
    //#region Constantes
    final static String PARAM_USERKEY = 'userKey';
    final static String PARAM_USERFIRSTNAME = 'userFirstName';
    final static String PARAM_USERCOUNTRY = 'userCountry';
    final static String PARAM_USERGROUP = 'userGroup';
    final static String PARAM_CLIENTNAME = 'clientName';
    final static String PARAM_CLIENTGROUPID = 'clientGroupId';
    final static List<String> PARAM_CLIENTVALIDTYPES = new List<String>{'CIB Group'};
    final static String PARAM_CONVERSATIONID = 'conversationId';
    final static String PARAM_TIMEOUTS = 'timeoutS';
    final static String PARAM_TEXTINPUTCHARLIMIT = 'textInputCharLimit';
    final static String PARAM_RECORDID = 'recordId';
    final static String PARAM_ERROR = 'error';
    final static String SERVICENAME_FEEDBACK = 'feedback';
    final static String SERVICENAME_OBMESSAGE = 'obmessage';
    final static String SERVICECONFIGNAME_FEEDBACK = 'aiChatRobot2_PostMessageFeedback';
    final static String SERVICECONFIGNAME_OBMESSAGE = 'aiChatRobot2_OBMessage';
    final static String CLASSNAME = 'aiChatRobot2Controller';
    final static String PROJECTNAME = 'AI_Banker';
    final static List<String> EXCEPTION_DML_LIST = new List<String>{'DMLException','EmailException'};
    //#endregion
    //#region Métodos públicos

    /**
    * @description  Método principal gestor de la recuperación de la información del contexto del Chat
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 04-12-2025 
    * @param String recordId        ::  ID del registro de Account sobre el que se ha abierto el chat
    * @return Map<String, String>   ::  Mapa con la información recuperada del contexto del chat
    **/
    @AuraEnabled
    public static Map<String, String> getContextData(String recordId) {
        // Instanciamos el nombre del método
        String methodName = 'getContextData';
        // Instanciamos el mapa de respuesta
        Map<String, String> contextDataMap = new Map<String, String>();
        // Iniciamos el bloque de construcción del mapa
        try {
            // Recuperamos la información del usuario actual
            User currentUser = getUserInfo();
            // Validamos que el registro de usuario tenga informados todos los campos necesarios
            if (String.isBlank(currentUser.FederationIdentifier)) {
                throw new MissingParamException('El usuario actual no cuenta con el parámetro \'FederationIdentifier\'.');
            }
            // Por seguridad, inicializamos los parámetros complementarios del ususario para prevenir que se encuentren vacíos
            String userCountry = !String.isBlank(currentUser.DES_Country__c) ? currentUser.DES_Country__c : 'ESP'; // Default a ESP si no está definido, puede ajustarse según necesidades
            String userGroup = !String.isBlank(currentUser.DES_LevelUO_10__c) ? currentUser.DES_LevelUO_10__c : '';
            String userName = !String.isBlank(currentUser.FirstName) ? currentUser.FirstName : '';
            // Guardamos en el mapa la información del usuario
            contextDataMap.put(PARAM_USERKEY, currentUser.FederationIdentifier);
            contextDataMap.put(PARAM_USERFIRSTNAME, userName);
            contextDataMap.put(PARAM_USERCOUNTRY, userCountry);
            contextDataMap.put(PARAM_USERGROUP, userGroup);
            // Recuperamos la información sobre el registro de Cuenta consultado (si se obtiene Id)
            String accountName = '';
            String groupId = '';
            if (!String.isBlank(recordId)) {
                Account currentAccount = getAccountInfo(recordId);
                // Validamos que el registro de cliente tenga informados todos los campos necesarios y los valores sean válidos
                if (String.isBlank(currentAccount.DES_Group_Code__c)) {
                    throw new MissingParamException('El cliente actual no cuenta con el parámetro \'DES_Group_Code__c\'.');
                } else if (String.isBlank(currentAccount.DES_Client_Type__c) || !PARAM_CLIENTVALIDTYPES.contains(currentAccount.DES_Client_Type__c)) {
                    throw new MissingParamException('El cliente actual no pertenece al tipo de cliente válido para la consulta (\'DES_Client_Type__c\').');
                } else {
                    groupId = currentAccount.DES_Group_Code__c;
                    accountName = currentAccount.Name;
                }
            }

            // Recuperamos la información relativa al tiempo máximo de espera de respuesta del chat
            AI_ChatRobot2_Settings__mdt chatSettings = getChatSettings();
            String timeoutValue = !String.isBlank(String.valueOf(chatSettings.TimeoutS__c)) ? String.valueOf(chatSettings.TimeoutS__c) : '';
            contextDataMap.put(PARAM_TIMEOUTS, timeoutValue);

            // Recuperamos el límite de caracteres configurado para el input del chat
            String charLimitValue = chatSettings.textInputCharLimit__c != null ? String.valueOf(chatSettings.textInputCharLimit__c.intValue()) : '';
            contextDataMap.put(PARAM_TEXTINPUTCHARLIMIT, charLimitValue);

            // Almacenamos la información en el mapa
            contextDataMap.put(PARAM_CLIENTGROUPID, groupId);
            contextDataMap.put(PARAM_CLIENTNAME, accountName);
            // Generamos el Id de conversación y lo añadimos al mapa
            contextDataMap.put(PARAM_CONVERSATIONID, generateCustomId());
            // Devolvemos el mapa construido
            return contextDataMap;
        } catch (Exception ex) {
            // Guardamos un registro de traza de error en Salesforce con los detalles de la excepción
            DES_Exception_Utils.logException(ex, CLASSNAME, methodName, PROJECTNAME, '');
            // En caso de excepción, guardamos el detalle de error en el mapa
            contextDataMap.put(PARAM_ERROR, ex.getStackTraceString() + ' | ' + ex.getMessage() );
            // Devolvemos el mapa construido
            return contextDataMap;
        }
    }

    /**
    * @description  Método de invocación general de servicios externos
    * @author Matias Maquieira | 10-12-2025 
    * @param Map<String,Object> requestBody ::  Cuerpo de la petición con los datos del servicio invocado
    * @return aiChatRobot2ServiceResponse   ::  Respuesta del servicio con el resultado del envío
    **/
    @AuraEnabled
    public static aiChatRobot2ServiceResponse makeServiceRequest(String serviceName, Map<String, Object> requestBody) {
        // Instanciamos el nombre del método
        String methodName = 'makeServiceRequest';
        // Instanciamos la respuesta de feedback
        aiChatRobot2ServiceResponse response;
        try {
            // Comprobamos el servicio que se desea invocar
            if (serviceName == SERVICENAME_FEEDBACK) {
                    // Invocamos el método de publicación de feedback con su contenido y almacenamos la respuesta
                    response = aiChatRobot2Service.manageServiceResponse(SERVICECONFIGNAME_FEEDBACK, requestBody);                    
            }
            else if (serviceName == SERVICENAME_OBMESSAGE) {
                // Invocamos el método de publicación de mensaje saliente, con su contenido, y almacenamos la respuesta
                response = aiChatRobot2Service.manageServiceResponse(SERVICECONFIGNAME_OBMESSAGE, requestBody);                    
            }
        } catch (Exception e) {
            // En caso de excepción, añadimos información del contexto del error producido
            response = new aiChatRobot2ServiceResponse();
            response.isError = true;    
            response.errorMessage = e.getMessage();
            response.errorDetails = new Map<String, Object>{
                'stackTrace' => e.getStackTraceString(),
                'type' => e.getTypeName()
            };
            // Guardamos un registro de traza de error en Salesforce con los detalles de la excepción
            DES_Exception_Utils.logException(e, CLASSNAME, methodName, PROJECTNAME, '');
        }
        // Devolvemos la respuesta del servicio
        return response;
    }
    
    /**
    *
    * @description  Método de guardado / actualización del registro de información relativa a la conversación de chat
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 04-12-2025 
    * @param String recordId                ::  ID del registro de la conversación (se recibirá en el supuesto de actualización y llegará nulo en caso de inserción)
    * @param String conversationId          ::  ID interno generado para la conversación actual en las comunicaciones inbound/outbound con los servicios
    * @param String groupId                 ::  ID de grupo del Account sobre el que se realiza la consulta en el chat
    * @param String userKey                 ::  Clave de usuario que realiza la consulta
    * @param Boolean isLastMessageFromUser  ::  Indicador de si el último mensaje lo ha generado el usuario o la IA
    * @return Map<String, String>           ::  Mapa con la información sobre el registro creado/actualizado o el error ocurrido
    **/
    @AuraEnabled
    public static Map<String,String> saveConversationContext (String recordId, String conversationId, String groupId, String userKey, Boolean isLastMessageFromUser) {
        // Instanciamos el nombre del método
        String methodName = 'saveConversationContext';
        // Instanciamos el mapa de respuesta
        Map<String,String> resultMap = new Map<String,String>();
        // Instanciamos el valor del Id del registro de AI_Chat_Conversation__c a devolver
        String sfRecordId = !String.isBlank(recordId) ? recordId : null;
        // Instanciamos el registro del chat actual
        AI_Chat_Conversation__c currentConversation = new AI_Chat_Conversation__c();
        try {
            // Controlamos si se está procesando un registro nuevo (inserción) o uno ya existente (actualización)
            if (String.isBlank(recordId)) {
                // Guardamos la información recibida acerca del contexto de la conversación actual
                currentConversation.Name = 'Chat-' + conversationId;
                currentConversation.AI_ConversationId__c = conversationId;
                currentConversation.AI_GroupId__c = groupId;
                currentConversation.AI_UserKey__c = userKey;
                currentConversation.AI_LastMessageFromUser__c = isLastMessageFromUser;
                // Insertamos el registro
                Database.insert(currentConversation);
                // Almacenamos el Id del nuevo registro creado
                sfRecordId = currentConversation.Id;
            } else {
                // Recuperamos el registro desde la BBDD
                currentConversation = getConversationInfo(recordId);
                // Actualizamos la información del registro
                currentConversation.AI_LastMessageFromUser__c = isLastMessageFromUser;
                // Guardamos el registro actualizado
                Database.update(currentConversation);
            }
            // Devolvemos el Id del registro de Salesforce AI_Chat_Conversation__c relativo a la conversación actual
            resultMap.put(PARAM_RECORDID,sfRecordId);
            return resultMap;
        } catch (Exception ex) {
            // Guardamos un registro de traza de error en Salesforce con los detalles de la excepción
            DES_Exception_Utils.logException(ex, CLASSNAME, methodName, PROJECTNAME, '');
            // En caso de error, devolvemos el detalle
            resultMap.put(PARAM_ERROR, ex.getStackTraceString() + ' | ' + ex.getMessage() );
            return resultMap;
        }
    }

    //#endregion
    //#region Métodos privados

    /**
    * @description  Método generador del Código identificador único de la conversación
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 05-12-2025 
    * @return String 
    **/
    private static String generateCustomId() {
        // Devolvemos el identificador compuesto
        return UUID.randomUUID().toString();
    }

    //#region Consultas SOQL

    /**
    * @description Método de consulta de la información relativa al usuario actual
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 04-12-2025 
    * @return User 
    **/
    private static User getUserInfo() {
        return [SELECT Id, FirstName, FederationIdentifier, DES_Country__c, DES_LevelUO_10__c
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1]; 
    }

    /**
    * @description Método de consulta de la información relativa al registro de Account relativo al chat
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 04-12-2025 
    * @param String recordId    ::  ID del registro de Account a consultar
    * @return Account 
    **/
    private static Account getAccountInfo(String recordId) {
        return  [SELECT Id, Name, DES_Group_Code__c, DES_Client_Type__c
                FROM Account 
                WHERE Id = :recordId 
                LIMIT 1];
    }

    /**
    * @description Método de consulta de la información relativa al registro de Conversación relativo al chat
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 04-12-2025 
    * @param String recordId    ::  ID del registro de Conversación a recuperar
    * @return AI_Chat_Conversation__c 
    **/
    private static AI_Chat_Conversation__c getConversationInfo(String recordId) {
        return  [SELECT Id, Name, AI_ConversationId__c, AI_GroupId__c, AI_UserKey__c, AI_LastMessageFromUser__c 
                FROM AI_Chat_Conversation__c 
                WHERE Id = :recordId 
                LIMIT 1];
    }

    /**
    * @description Método de consulta de la información relativa a la configuración de timeout de respuesta del chat
    * @author José María Manzano Gómez - [jose_manzanogomez@epamneoris.com] | 30-01-2026 
    * @return AI_ChatRobot2_Settings__mdt 
    **/
    private static AI_ChatRobot2_Settings__mdt getChatSettings() {
            return  [SELECT TimeoutS__c, textInputCharLimit__c
                    FROM AI_ChatRobot2_Settings__mdt
                    WHERE DeveloperName = 'Default'
                    LIMIT 1];
    }
    //#endregion
    //#region Clases auxiliares
    public class MissingParamException extends Exception { }
    //#endregion
    //#endregion
}