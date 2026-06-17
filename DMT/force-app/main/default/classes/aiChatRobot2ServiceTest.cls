/**
 * @description       : Clase de test para aiChatRobot2Service y aiChatRobot2Controller
 * @author            : Matias Maquieira
 * @group             : NEORIS
 * @last modified on  : 25-02-2026
 * @last modified by  : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * Modifications Log
 * Ver   Date         Author              Modification
 * 1.0   15-12-2025   Matias Maquieira   Initial Version - Tests para servicio de feedback
**/
@isTest
private class aiChatRobot2ServiceTest {
    
    //#region Constantes
    final static String SERVICECONFIGNAME_FEEDBACK = 'aiChatRobot2_PostMessageFeedback';
    final static String SERVICECONFIGNAME_OBMESSAGE = 'aiChatRobot2_OBMessage';
    //#endregion

    /**
     * @description Setup de datos de test
     */
    @TestSetup
    static void setupTestData() {
        // Crear conversación de test
        AI_Chat_Conversation__c conversation = new AI_Chat_Conversation__c(
            Name = 'Test Conversation',
            AI_ConversationId__c = '707b2538-98bb-41e7-95e3-1d77bf42b1',
            AI_GroupId__c = 'G12345',
            AI_UserKey__c = 'E012345'
        );
        insert conversation;
    }
    
    /**
     * @description Test de feedback POSITIVO exitoso
     */
    @isTest
    static void testPostMessageFeedback_PositiveSuccess() {
        Map<String, Object> requestBody = new Map<String, Object>{
            'conversationId' => '707b2538-98bb-41e7-95e3-1d77bf42b1',
            'user' => new Map<String, Object>{
                'id' => 'E012345',
                'country' => 'ES',
                'segment' => 'CIB'
            },
            'message' => new Map<String, Object>{
                'id' => '550e8400-e29b-41d4-a716-446655440000',
                'category' => 'POSITIVE'
            },
            'channel' => 'GLOBAL_DESKTOP',
            'creationDate' => DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS')
        };
        
        //Se envía el feedback
        Test.startTest();
        aiChatRobot2ServiceResponse response = aiChatRobot2Service.manageServiceResponse(SERVICECONFIGNAME_FEEDBACK, requestBody);
        Test.stopTest();
        
        // La respuesta debe ser exitosa
        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
        System.debug('Response isError: ' + response.isError);
        System.debug('Response errorMessage: ' + response.errorMessage);
        // En test mode, aiChatRobot2Utils.callService retorna un mock, verificar que se procesó
    }

    /**
     * @description Test de validación del método 'aiChatRobot2_OBMessage'
     */
    @isTest
    static void testPostSendUserRequest() {
        Map<String, Object> requestBody = new Map<String, Object>{
            'conversationId' => '707b2538-98bb-41e7-95e3-1d77bf42b1',
            'showSummary' => true,
            'channel' => 'GLOBAL_DESKTOP',
            'user' => new Map<String, Object>{
                'id' => 'E012345',
                'country' => 'ES',
                'segment' => 'CIB'
            },
            'isNewConversation' => false,
            'message' => new Map<String, Object>{
                'id' => '550e8400-e29b-41d4-a716-446655440000',
                'content' => 'Mensaje de prueba'
            },
            'company' => new Map<String, Object>{
                'id' => 'G0012',
                'name' => 'Empresa de pruebas'
            },
            'language' => 'es'
        };
        
        //Se envía la petición
        Test.startTest();
        aiChatRobot2ServiceResponse response = aiChatRobot2Service.manageServiceResponse(SERVICECONFIGNAME_OBMESSAGE, requestBody);
        Test.stopTest();
        
        // La respuesta debe ser exitosa
        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
        System.debug('Response isError: ' + response.isError);
        System.debug('Response errorMessage: ' + response.errorMessage);
    }
    
    /**
     * @description Test de feedback NEGATIVO exitoso con razón específica
     */
    @isTest
    static void testPostMessageFeedback_NegativeWithReason() {
        // Request body para feedback negativo con razón
        Map<String, Object> requestBody = new Map<String, Object>{
            'conversationId' => '707b2538-98bb-41e7-95e3-1d77bf42b1',
            'user' => new Map<String, Object>{
                'id' => 'E012345',
                'country' => 'ES',
                'segment' => 'CIB'
            },
            'message' => new Map<String, Object>{
                'id' => '550e8400-e29b-41d4-a716-446655440001',
                'category' => 'NEGATIVE',
                'reason' => new List<String>{'INCORRECT_INFORMATION'},
                'otherReasonDetail' => null,
                'additionalComments' => null
            },
            'channel' => 'GLOBAL_DESKTOP',
            'creationDate' => DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS')
        };
        
        // Se envía el feedback
        Test.startTest();
        aiChatRobot2ServiceResponse response = aiChatRobot2Service.manageServiceResponse(SERVICECONFIGNAME_FEEDBACK, requestBody);
        Test.stopTest();
        
        // La respuesta debe ser exitosa
        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
    }
    
    /**
     * @description Test de feedback NEGATIVO con razón OTHER y detalles
     */
    @isTest
    static void testPostMessageFeedback_NegativeWithOtherReason() {
        // Request body para feedback negativo con OTHER
        Map<String, Object> requestBody = new Map<String, Object>{
            'conversationId' => '707b2538-98bb-41e7-95e3-1d77bf42b1',
            'user' => new Map<String, Object>{
                'id' => 'E012345',
                'country' => 'ES',
                'segment' => 'CIB'
            },
            'message' => new Map<String, Object>{
                'id' => '550e8400-e29b-41d4-a716-446655440002',
                'category' => 'NEGATIVE',
                'reason' => new List<String>{'OTHER'},
                'otherReasonDetail' => 'La respuesta fue confusa',
                'additionalComments' => 'La respuesta fue confusa'
            },
            'channel' => 'GLOBAL_DESKTOP',
            'creationDate' => DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS')
        };
        
        // Se envía el feedback
        Test.startTest();
        aiChatRobot2ServiceResponse response = aiChatRobot2Service.manageServiceResponse(SERVICECONFIGNAME_FEEDBACK, requestBody);
        Test.stopTest();
        
        // La respuesta debe ser exitosa
        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
    }
    
    /**
     * @description Test con request body vacío (manejo de error)
     */
    @isTest
    static void testPostMessageFeedback_EmptyRequest() {
        // Request body vacío
        Map<String, Object> requestBody = new Map<String, Object>();
        
        // Se envía el feedback
        Test.startTest();
        aiChatRobot2ServiceResponse response = aiChatRobot2Service.manageServiceResponse(SERVICECONFIGNAME_FEEDBACK, requestBody);
        Test.stopTest();
        
        // Debe manejar el caso sin lanzar excepción
        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
    }

    /**
     * @description Test de validación del método 'aiChatRobot2_OBMessage' con cuerpo vacío
     */
    @isTest
    static void testPostSendUserRequestEmptyRequest() {
        // Request body vacío
        Map<String, Object> requestBody = new Map<String, Object>();
        
        // Se envía la petición
        Test.startTest();
        aiChatRobot2ServiceResponse response = aiChatRobot2Service.manageServiceResponse(SERVICECONFIGNAME_OBMESSAGE, requestBody);
        Test.stopTest();
        
        // Debe manejar el caso sin lanzar excepción
        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
    }
    
    /**
     * @description Test con request body null (manejo de error)
     */
    @isTest
    static void testPostMessageFeedback_NullRequest() {
        // Request body null
        Map<String, Object> requestBody = null;
        
        // Se envía el feedback
        Test.startTest();
        aiChatRobot2ServiceResponse response = aiChatRobot2Service.manageServiceResponse(SERVICECONFIGNAME_FEEDBACK, requestBody);
        Test.stopTest();
        
        // Debe manejar el caso sin lanzar excepción
        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
    }

    /**
     * @description Test de validación del método 'aiChatRobot2_OBMessage' con cuerpo a null
     */
    @isTest
    static void testPostSendUserRequestNullRequest() {
        // Request body null
        Map<String, Object> requestBody = null;
        
        // Se envía la petición
        Test.startTest();
        aiChatRobot2ServiceResponse response = aiChatRobot2Service.manageServiceResponse(SERVICECONFIGNAME_OBMESSAGE, requestBody);
        Test.stopTest();
        
        // Debe manejar el caso sin lanzar excepción
        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
    }
    
    /**
     * @description Test del controller - feedback positivo
     */
    @isTest
    static void testController_GiveMessageFeedback_Positive() {
        // Request body para feedback positivo
        Map<String, Object> requestBody = new Map<String, Object>{
            'conversationId' => '707b2538-98bb-41e7-95e3-1d77bf42b1',
            'user' => new Map<String, Object>{
                'id' => 'E012345',
                'country' => 'ES',
                'segment' => 'CIB'
            },
            'message' => new Map<String, Object>{
                'id' => '550e8400-e29b-41d4-a716-446655440004',
                'category' => 'POSITIVE'
            },
            'channel' => 'GLOBAL_DESKTOP',
            'creationDate' => DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS')
        };
        
        // Se llama al método del controller
        Test.startTest();
        aiChatRobot2ServiceResponse response = aiChatRobot2Controller.makeServiceRequest('feedback', requestBody);
        Test.stopTest();
        
        // La respuesta debe ser exitosa
        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
    }
    
    /**
     * @description Test del controller - feedback negativo
     */
    @isTest
    static void testController_GiveMessageFeedback_Negative() {
        // Request body para feedback negativo
        Map<String, Object> requestBody = new Map<String, Object>{
            'conversationId' => '707b2538-98bb-41e7-95e3-1d77bf42b1',
            'user' => new Map<String, Object>{
                'id' => 'E012345',
                'country' => 'ES',
                'segment' => 'CIB'
            },
            'message' => new Map<String, Object>{
                'id' => '550e8400-e29b-41d4-a716-446655440005',
                'category' => 'NEGATIVE',
                'reason' => new List<String>{'UNCLEAR_RESPONSE'},
                'otherReasonDetail' => null,
                'additionalComments' => 'Necesita más claridad'
            },
            'channel' => 'GLOBAL_DESKTOP',
            'creationDate' => DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS')
        };
        
        // Se llama al método del controller
        Test.startTest();
        aiChatRobot2ServiceResponse response = aiChatRobot2Controller.makeServiceRequest('feedback', requestBody);
        Test.stopTest();
        
        // La respuesta debe ser exitosa
        System.assertNotEquals(null, response, 'La respuesta no debe ser null');
    }
    
    /**
     * @description Test del controller - getContextData con recordId
     */
    @isTest
    static void testController_GetContextData_WithRecordId() {
        // Given: Crear una cuenta de test
        Account testAccount = new Account(
            Name = 'Test Account',
            DES_Group_Code__c = 'GRP001',
            DES_BBVA_Segmentation__c = 'C',
            DES_Structure_Type__c = 'Group'
        );
        insert testAccount;
        
        // When: Se llama al método con recordId
        Test.startTest();
        Map<String, String> contextData = aiChatRobot2Controller.getContextData(testAccount.Id);
        Test.stopTest();
        
        // Then: Debe retornar los datos del contexto
        System.assertNotEquals(null, contextData, 'El contexto no debe ser null');
        System.assert(contextData.containsKey('userKey'), 'Debe contener userKey');
        System.assert(contextData.containsKey('userFirstName'), 'Debe contener userFirstName');
        System.assert(contextData.containsKey('userCountry'), 'Debe contener userCountry');
        System.assert(contextData.containsKey('conversationId'), 'Debe contener conversationId');
    }
    
    /**
     * @description Test del controller - getContextData sin recordId
     */
    @isTest
    static void testController_GetContextData_WithoutRecordId() {
        // When: Se llama al método sin recordId
        Test.startTest();
        Map<String, String> contextData = aiChatRobot2Controller.getContextData(null);
        Test.stopTest();
        
        // Then: Debe retornar los datos del contexto
        System.assertNotEquals(null, contextData, 'El contexto no debe ser null');
        System.assert(contextData.containsKey('userKey'), 'Debe contener userKey');
        System.assert(contextData.containsKey('conversationId'), 'Debe contener conversationId');
    }

    /**
    * @description Método de validación de tratamiento de la excepción aiChatRobot2Utils.treatException()
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 28-01-2026 
    **/
    @isTest
    static void utilsTreatExceptionServiceResponse() {
        Exception e = new DmlException('Sample error');
        aiChatRobot2ServiceResponse sr = aiChatRobot2Utils.treatException(e);
        Assert.areEqual(true, sr.isError, 'ServiceResponse should be marked as error');
        Assert.isTrue(sr.errorMessage.startsWith('Apex exception:'), 'Error message should start with "Apex exception:"');
        Assert.isTrue(sr.errorDetails.containsKey('stackTrace'), 'Error details should contain stackTrace');
        Assert.isTrue(sr.errorDetails.containsKey('exception'), 'Error details should contain exception');
    }

    /**
    * @description Método de validación de tratamiento del procesamiento de respuestas de error aiChatRobot2Utils.processResponse()
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 27-01-2026 
    **/
    @isTest
    static void utilsProcessResponse() {
        // Construimos una respuesta simulada de error en servicio
        HttpResponse response = new HttpResponse();
        response.setBody('{"data":{"status":"KO"}}');
        response.setStatus('ERROR');
        response.setStatusCode(404);
        // Realizamos el procesamiento de la respuesta simulada
        aiChatRobot2ServiceResponse processedResponse = aiChatRobot2Utils.processResponse(response, new List<Integer>{201});
        // Realizamos la comprobación de la respuesta recibida
        Assert.areEqual(true, processedResponse.isError, 'La respuesta del servicio debería haberse marcado como errónea');
        Assert.areNotEqual(null, processedResponse.errorDetails, 'Deberían haberse indicado detalles del error producido');
        Assert.isTrue(processedResponse.errorMessage.startsWith('The service returns an unexpected HTTP status code:'), 'El detalle del error no contiene la estructura esperada');
    }

    /**
    * @description Método de validación de tratamiento del procesamiento de excepción en el procesamientod de respuestas a servicios aiChatRobot2ServiceResponse()
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 28-01-2026 
    **/
    @isTest
    static void exceptionServiceResponse() {
        // Instanciamos la excepción simulada        
        Exception ex = new CalloutException('Sample error');
        // Guardamos el objeto auxiliar resultado de enviar la excepción al constructor de respuestas de servicios auxiliar
        aiChatRobot2ServiceResponse errorSrvResponse = new aiChatRobot2ServiceResponse(ex);
        // Realizamos la comprobación de la respuesta recibida

        Assert.areEqual(true, errorSrvResponse.isError, 'La respuesta debería haberse marcado como errónea');
        Assert.isTrue(errorSrvResponse.data == null, 'El cuerpo de la respuesta debería estar vacío');
        Assert.isTrue(!String.IsBlank(errorSrvResponse.errorMessage), 'Debería haberse informado el mensaje de error de la excepción');
        Assert.isTrue(errorSrvResponse.errorDetails.containsKey('stackTrace'), 'El detalle de la respuesta a la excepción, debería contener la traza de error');
    }

    /**
    * @description Método de validación del método buildDefaultServiceError() de creación de respuestas de error genéricas en llamadas a Servicios
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 28-01-2026 
    **/
    @isTest
    static void buildDefaultServiceErrorTest() {
        // Construimos una respuesta simulada de error en servicio
        HttpResponse response = new HttpResponse();
        response.setBody('{"data":{"status":"KO"}}');
        response.setStatus('ERROR');
        response.setStatusCode(404);
        // Realizamos el procesamiento de la respuesta simulada para la obtención del error genérico
        aiChatRobot2ServiceResponse errorResponse = aiChatRobot2Service.buildDefaultServiceError(response);
        // Realizamos la comprobación de la respuesta recibida
        Assert.areEqual(true, errorResponse.isError, 'La respuesta debería haberse marcado como errónea');
        Assert.isTrue(errorResponse.data == null, 'El cuerpo de la respuesta debería estar vacío');
        Assert.isTrue(!String.IsBlank(errorResponse.errorMessage), 'Debería haberse informado el mensaje de error de la excepción');
        Assert.isTrue(errorResponse.errorDetails.containsKey('responseBody'), 'El detalle de la respuesta a la excepción, debería contener la traza de error');
    }
}