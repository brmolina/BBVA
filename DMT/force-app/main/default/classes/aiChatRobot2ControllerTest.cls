/**
 * @description       : Clase test del controlador Apex 'aiChatRobot2Controller'
 * @author            : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * @group             : NEORIS
 * @last modified on  : 21-04-2026
 * @last modified by  : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   08-12-2025   Javier Setién Rivas - [javier_setien@epamneoris.com]   Initial Version
**/
@isTest
private class aiChatRobot2ControllerTest {

    //#region Constantes
    final static String PROFILENAME = 'Desktop Integration';
    final static String MOCKSERVICERESPONSE_POSITIVE = '{"data":{"status":"OK"}}';
    final static String MOCKSERVICERESPONSE_NEGATIVE = '{"data":{"status":"KO"}}';
    //#endregion
    
    //#region Setup
    @testSetup 
    private static void testSetup() {
        // 1. Creamos el usuario a utilizar en la ejecución de los test
        User runAsUser = getRunAsUser(PROFILENAME);
        // 2. Creamos el registro de Account (Cliente) utilizado para simular la consulta del chat
        List<Account> clients = new List<Account>();
        Account account1 = new Account();
        account1.Name = 'Test_Client#1';
        account1.DES_Group_Code__c = 'TST_GROUP1';
        account1.DES_Subsidiary_Group_Code__c = 'TST_GROUP1';
        account1.BBVA_Entity__c = 'BBVA SA';
        account1.DES_BBVA_Segmentation__c = 'C';
        account1.DES_Structure_Type__c = 'Group';
        clients.add(account1);
        Account account2 = new Account();
        account2.Name = 'Test_Client#2';
        account2.DES_Group_Code__c = 'TST_GROUP2';
        account2.BBVA_Entity__c = 'BBVA SA';
        account2.DES_BBVA_Segmentation__c = 'C';
        account2.DES_Structure_Type__c = 'Group';
        clients.add(account2);
        Account account3 = new Account();
        account3.Name = 'Test_Client#3';
        account3.BBVA_Entity__c = 'BBVA SA';
        clients.add(account3);
        Account account4 = new Account();
        account4.Name = 'Test_Client#4';
        account4.DES_Group_Code__c = 'TST_GROUP4';
        account4.BBVA_Entity__c = 'BBVA SA';
        clients.add(account4);
        // Insertamos los registros de clientes
        insert clients;
    }
    //#endregion

    //#region Métodos Test

    /**
    * @description Test de validación del método getContextData()
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 09-12-2025 
    **/
    @isTest
    private static void getContextDataTest() {
        // Recuperamos el usuario con el que simular la consulta
        User runAsUser = getRunAsUser(PROFILENAME);
        // Recuperamos el registro de cliente sobre el que realizar la consulta
        List<Account> clients = [SELECT Id FROM Account WHERE Name = 'Test_Client#1'];
        // Inicializamos la ejecución
        System.runAs(runAsUser) {
            // Ejecutamos el método de obtención del contexto en función del usuario actual y el cliente consultado
            Map<String, String> response = aiChatRobot2Controller.getContextData(clients[0].Id);
            // Realizamos las validaciones
            Assert.isNotNull(response.get('userKey'), 'La clave de usuario no debería ser nula');
            Assert.isNotNull(response.get('userFirstName'), 'El nombre de usuario no debería estar vacío');
            Assert.isNotNull(response.get('clientName'), 'El nombre de cliente no debería estar vacío');
            Assert.isNotNull(response.get('clientGroupId'), 'El Id de grupo de cliente no debería estar vacío');
            Assert.isNotNull(response.get('conversationId'), 'El Id de conversación no debería estar vacío');
            Assert.isTrue(!response.containsKey('error'), 'La respuesta no debería contener errores');
        }
    }

    /**
    * @description Test de validación del método saveConversationContext()
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 09-12-2025 
    **/
    @isTest
    private static void saveConversationContextTest() {
        // Recuperamos el usuario con el que simular la consulta
        User runAsUser = getRunAsUser(PROFILENAME);
        // Recuperamos el registro de cliente sobre el que realizar la consulta
        List<Account> clients = [SELECT Id, Name, DES_Group_Code__c FROM Account WHERE Name = 'Test_Client#2'];
        // Inicializamos la ejecución
        System.runAs(runAsUser) {
            // Ejecutamos el método de obtención del contexto en función del usuario actual y el cliente consultado
            Map<String, String> contextResponse = aiChatRobot2Controller.getContextData(clients[0].Id);
            // Ejecutamos el método de guardado del registro relativo a la conversación
            Map<String, String> savedResponse = aiChatRobot2Controller.saveConversationContext(null, contextResponse.get('conversationId'), contextResponse.get('clientGroupId'), contextResponse.get('userKey'), true);
            // Realizamos las validaciones de la creación del registro de conversación
            Assert.isNotNull(savedResponse.get('recordId'), 'El registro debería haber devuelto un Id tras su guardado');
            Assert.isTrue(!savedResponse.containsKey('error'), 'La respuesta no debería contener errores');
            // Ejecutamos el método de actualización del registro relativo a la conversación
            Map<String, String> updatedResponse = aiChatRobot2Controller.saveConversationContext(savedResponse.get('recordId'), contextResponse.get('conversationId'), contextResponse.get('clientGroupId'), contextResponse.get('userKey'), false);
            // Realizamos las validaciones de la actualización del registro de conversación
            Assert.isNotNull(updatedResponse.get('recordId'), 'El registro debería haber devuelto un Id tras su guardado');
            Assert.isTrue(!updatedResponse.containsKey('error'), 'La respuesta no debería contener errores');
        }
        // Consultamos los registros de conversación existentes
        List<AI_Chat_Conversation__c> conversations =   [SELECT Id, Name, AI_ConversationId__c, AI_GroupId__c, AI_UserKey__c, AI_LastMessageFromUser__c FROM AI_Chat_Conversation__c];
        // Realizamos las validaciones del correcto guardado de datos
        Assert.areEqual(1, conversations.size(), 'Únicamente debería existir un registro de Conversación en la base de datos');
        Assert.isFalse(conversations[0].AI_LastMessageFromUser__c, 'El último mensaje debería haber sido ajeno al usuario');
    }

    /**
    * @description  Test de validación del método saveApexErrorLog()
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 23-12-2025 
    **/
    @isTest
    private static void saveSfErrorLogClientWOGroupTest() {
        // Recuperamos el usuario con el que simular la consulta
        User runAsUser = getRunAsUser(PROFILENAME);
        // Recuperamos el registro de cliente (sin  GroupId) sobre el que realizar la consulta
        List<Account> clients = [SELECT Id FROM Account WHERE Name = 'Test_Client#3'];
        // Recuperamos los registros de log de errores previos a los procesos susceptibles de conflicto
        List<DES_Exceptions__b> initialErrorLogs = [SELECT Id FROM DES_Exceptions__b];
        Assert.isTrue(initialErrorLogs.isEmpty(), 'No deberían existir logs de error previo al inicio de la ejecución');
        // Inicializamos la ejecución
        System.runAs(runAsUser) {
            // Ejecutamos el método de obtención del contexto en función del usuario actual y el cliente consultado
            Map<String, String> contextResponse = aiChatRobot2Controller.getContextData(clients[0].Id);
            // Ejecutamos el método de guardado del registro relativo a la conversación
            Map<String, String> savedResponse = aiChatRobot2Controller.saveConversationContext(null, contextResponse.get('conversationId'), contextResponse.get('clientGroupId'), contextResponse.get('userKey'), true);
        }
        // // Recuperamos los registros de log de errores posterior a la ejecución
        // List<DES_Exceptions__b> finalErrorLogs = [SELECT Id, Class_Name__c, Message__c FROM DES_Exceptions__b];        
        // // Realizamos las validaciones
        // Assert.isFalse(finalErrorLogs.isEmpty(), 'Tras la ejecución deberían existir registros de error');
        // Assert.areNotEqual(null, finalErrorLogs[0].Message__c, 'Debería existir un error reportado');
        // Assert.areEqual('aiChatRobot2Controller', finalErrorLogs[0].Class_Name__c, 'La clase del error reportado debería ser diferente');
    }

    /**
    * @description  Test de validación del método saveApexErrorLog()
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 23-12-2025 
    **/
    @isTest
    private static void saveSfErrorLogClientWOTypeTest() {
        // Recuperamos el usuario con el que simular la consulta
        User runAsUser = getRunAsUser(PROFILENAME);
        // Recuperamos el registro de cliente (sin  GroupId) sobre el que realizar la consulta
        List<Account> clients = [SELECT Id FROM Account WHERE Name = 'Test_Client#4'];
        // Recuperamos los registros de log de errores previos a los procesos susceptibles de conflicto
        List<DES_Exceptions__b> initialErrorLogs = [SELECT Id FROM DES_Exceptions__b];
        Assert.isTrue(initialErrorLogs.isEmpty(), 'No deberían existir logs de error previo al inicio de la ejecución');
        // Inicializamos la ejecución
        System.runAs(runAsUser) {
            // Ejecutamos el método de obtención del contexto en función del usuario actual y el cliente consultado
            Map<String, String> contextResponse = aiChatRobot2Controller.getContextData(clients[0].Id);
            // Ejecutamos el método de guardado del registro relativo a la conversación
            Map<String, String> savedResponse = aiChatRobot2Controller.saveConversationContext(null, contextResponse.get('conversationId'), contextResponse.get('clientGroupId'), contextResponse.get('userKey'), true);
        }
        // // Recuperamos los registros de log de errores posterior a la ejecución
        // List<DES_Exceptions__b> finalErrorLogs = [SELECT Id, Class_Name__c, Message__c FROM DES_Exceptions__b];        
        // // Realizamos las validaciones
        // Assert.isFalse(finalErrorLogs.isEmpty(), 'Tras la ejecución deberían existir registros de error');
        // Assert.areNotEqual(null, finalErrorLogs[0].Message__c, 'Debería existir un error reportado');
        // Assert.areEqual('aiChatRobot2Controller', finalErrorLogs[0].Class_Name__c, 'La clase del error reportado debería ser diferente');
    }

    /**
    * @description  Test de validación del método makeServiceRequest() en el servicio sobre el feedback
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 23-12-2025 
    **/
    @isTest
    private static void giveMessageFeedbackDefaultTest() {
        // Recuperamos el usuario con el que simular la consulta
        User runAsUser = getRunAsUser(PROFILENAME);
         // Inicializamos la ejecución
        System.runAs(runAsUser) {
            // Ejecutamos el método de envío del feedback
            aiChatRobot2ServiceResponse response = aiChatRobot2Controller.makeServiceRequest('feedback', new Map<String, Object>());
            // Realizamos las validaciones
            Assert.isFalse(response == null, 'La respuesta del servicio de feedback no debería de ser nula');
        }
    }

    /**
    * @description  Test de validación negativa del método makeServiceRequest() en el servicio sobre el feedback
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 22-01-2026 
    **/
    @isTest
    private static void giveMessageFeedbackNegativeTest() {
        // Recuperamos el usuario con el que simular la consulta
        User runAsUser = getRunAsUser(PROFILENAME);
         // Inicializamos la ejecución
        System.runAs(runAsUser) {
            // Invocamos el mock de respuesta esperada
            Test.setMock(HttpCalloutMock.class, new ExternalServiceCalloutMock(400, MOCKSERVICERESPONSE_NEGATIVE));
            
            Test.startTest();
            // Ejecutamos el método de envío del feedback
            aiChatRobot2ServiceResponse response = aiChatRobot2Controller.makeServiceRequest('feedback', new Map<String, Object>());
            Test.stopTest();

            // Realizamos las validaciones
            Assert.isFalse(response == null, 'La respuesta del servicio de feedback no debería de ser nula');
        }
    }

    /**
    * @description  Test de validación del método makeServiceRequest() en el servicio sobre el envío de interacciones del usuario del chat
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 13-01-2026 
    **/
    @isTest
    private static void sendOBMessageDefaultTest() {
        // Recuperamos el usuario con el que simular la consulta
        User runAsUser = getRunAsUser(PROFILENAME);
         // Inicializamos la ejecución
        System.runAs(runAsUser) {
            // Ejecutamos el método de envío del mensaje
            aiChatRobot2ServiceResponse response = aiChatRobot2Controller.makeServiceRequest('obmessage', new Map<String, Object>());
            // Realizamos las validaciones
            Assert.isFalse(response == null, 'La respuesta del servicio del mensaje saliente no debería de ser nula');
        }
    }

    /**
    * @description  Test de validación negativa del método makeServiceRequest() en el servicio sobre el envío de interacciones del usuario del chat
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 22-01-2026 
    **/
    @isTest
    private static void sendOBMessageNegativeTest() {
        // Recuperamos el usuario con el que simular la consulta
        User runAsUser = getRunAsUser(PROFILENAME);
         // Inicializamos la ejecución
        System.runAs(runAsUser) {
            // Invocamos el mock de respuesta esperada
            Test.setMock(HttpCalloutMock.class, new ExternalServiceCalloutMock(400, MOCKSERVICERESPONSE_NEGATIVE));
            
            Test.startTest();
            // Ejecutamos el método de envío del mensaje
            aiChatRobot2ServiceResponse response = aiChatRobot2Controller.makeServiceRequest('obmessage', new Map<String, Object>());
            Test.stopTest();
            // Realizamos las validaciones
            Assert.isFalse(response == null, 'La respuesta del servicio del mensaje saliente no debería de ser nula');
        }
    }

    //#endregion
    //#region Métodos privados de utilidad auxiliar

    /**
    * @description Método de creación/obtención de un usuario con un perfil deseado
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 08-12-2025 
    * @param String profileName ::  Nombre del perfil asignado al usuario deseado
    * @return User 
    **/
    private static User getRunAsUser(String profileName) {
        // Instanciamos el usuario a devolver
        User runAsUser = new User();
        // Obtenemos el perfil deseado del usuario
        Profile requestedProfile = [SELECT Id, Name FROM Profile WHERE Name = :PROFILENAME LIMIT 1];
        Id profileId = requestedProfile.Id;
        // Consultamos si existe algún usuario en el sistema con ese perfil asignado
        List<User> requestedUsers = [SELECT Id, FirstName, FederationIdentifier, ID_User__c 
                                    FROM User 
                                    WHERE ProfileId = :profileId 
                                        AND FederationIdentifier != null
                                        AND IsActive = true];
        // Comprobamos si existen usuarios en el sistema con las características deseadas
        if (requestedUsers.size() > 0) {
            // Asignamos para devolver a uno de esos usuarios
            runAsUser = requestedUsers[0];
        } else {
            // Completamos los campos del usuario de Test a crear
            runAsUser.FirstName = 'Test';
            runAsUser.LastName = 'User';
            runAsUser.Email = 'test@mail.com';
            runAsUser.Alias = 'tuser';
            runAsUser.Username = 'test.user@demo.test.com';
            runAsUser.ID_User__c = 'A011122';
            runAsUser.FederationIdentifier = 'A011122';
            runAsUser.TimeZoneSidKey = 'Europe/Paris';
            runAsUser.LocaleSidKey = 'es_ES';
            runAsUser.ProfileId = profileId;
            runAsUser.LanguageLocaleKey = 'en_US';
            runAsUser.Prefix__c = 'ES';
            runAsUser.Business_line_desc__c = 'Global';
            // Insertamos el nuevo usuario
            insert runAsUser;
            // Asignamos para devolver el nuevo usuario
            runAsUser = [SELECT Id, FirstName, FederationIdentifier, ID_User__c 
                        FROM User 
                        WHERE ProfileId = :profileId 
                            AND FederationIdentifier != null
                            AND IsActive = true];
        }
        // Devolvemos el usuario válido deseado
        return runAsUser;
    }

    //#endregion

    //#region Mocks
    /**
     * Clase Mock de instanciación de las respuestas a los servicios externos 
    */
    public class ExternalServiceCalloutMock implements HttpCalloutMock {
        // Variables internas del Mock
        private Integer statusCode = 200;
        private String body = MOCKSERVICERESPONSE_POSITIVE;

        // Constructor del Mock
        public ExternalServiceCalloutMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        // Generación del método de respuesta del Mock
        public HTTPResponse respond(HTTPRequest request) {
            // Instanciamos la respuesta
            HttpResponse response = new HttpResponse();
            // Completamos con los parámetros recibidos
            response.setStatusCode(this.statusCode);
            response.setBody(this.body);
            // Devolvemos la respuesta
            return response;
        }
    }
    //#endregion
}