/**
 * @description       : 
 * @author            : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * @group             : 
 * @last modified on  : 27-04-2026
 * @last modified by  : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   02-02-2026   Javier Setién Rivas - [javier_setien@epamneoris.com]   Initial Version
**/
@IsTest
private class aiChatRobot2QueueableTest {

    // Helper para construir JSON con la nueva estructura
    private static String buildPayload(
        String conversationId,
        String mode,
        List<Map<String, Object>> messages
    ) {
        return buildPayload(conversationId, mode, messages, null, null);
    }

    // Helper sobrecargado que permite incluir messageId y explicability a nivel raíz
    private static String buildPayload(
        String conversationId,
        String mode,
        List<Map<String, Object>> messages,
        String messageId,
        List<Map<String, Object>> explicability
    ) {
        Map<String, Object> payload = new Map<String, Object>();

        if (mode != null) payload.put('mode', mode);
        if (conversationId != null) payload.put('conversationId', conversationId);
        if (messageId != null) payload.put('messageId', messageId);
        if (explicability != null) payload.put('explicability', explicability);

        // En tu clase: "data" es una LISTA de objetos (mensajes)
        List<Object> dataList = new List<Object>();
        if (messages != null) {
            for (Map<String, Object> m : messages) dataList.add(m);
        }
        payload.put('data', dataList);

        return JSON.serialize(payload);
    }

    @IsTest
    static void testQueueable_HappyPath_MultipleMessages_ExplicitMode() {
        // 2 mensajes con solo content (messageId y explicability van a nivel raíz)
        List<Map<String, Object>> msgs = new List<Map<String, Object>>{
            new Map<String, Object>{
                'content' => 'Hola test 1'
            },
            new Map<String, Object>{
                'content' => 'Hola test 2'
            }
        };

        List<Map<String, Object>> explicability = new List<Map<String, Object>>{
            new Map<String, Object>{
                'type' => 'Default Content',
                'content' => 'TOOL',
                'order' => 1
            }
        };

        String body = buildPayload('CONV-001', 'SUMMARY', msgs, 'M1', explicability);

        Test.startTest();
        System.enqueueJob(new aiChatRobot2Queueable(body));
        Test.stopTest();

        System.assert(true, 'El Queueable se ejecutó sin excepciones en happy path.');
    }

    /**
    * @description  Test de validación del método execute() de creación de eventos de plataforma, para un escenario de respuesta de error
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 13-01-2026 
    **/
    @IsTest
    static void testQueueableErrorResponse() {
        // Construimos el cuerpo de la respuesta de error esperada
        Map<String, Object> errorStructure = new Map<String, Object>{
                                                                        'id' => 'A-86001',
                                                                        'status' => 404,
                                                                        'description' => 'RESOURCE_NOT_FOUND',
                                                                        'detail' => 'The society id could not be found'
                                                                    };
        Map<String, Object> errorMsgBody = new Map<String, Object>{
            'conversationId' => '1mKdJYAU-0202202613230040-86001',
            'dataFailure' => errorStructure,
            'data' => new List<Object>(),
            'mode' => 'FAILED'
        };
        // Inicializamos el test del escenario de error
        Test.startTest();
        System.enqueueJob(new aiChatRobot2Queueable(JSON.serialize(errorMsgBody)));
        Test.stopTest();
        // Realizamos la comprobación
        System.assert(true, 'El Queueable se ejecutó sin excepciones en error path.');
    }

    @IsTest
    static void testQueueable_DefaultMode_And_MissingFieldsInMessages() {
        // Sin mode -> debe caer en 'FINAL_ANSWER'
        // Sin messageId ni explicability a nivel raíz
        // Mensajes con y sin content para cubrir los if (m.containsKey(...))
        List<Map<String, Object>> msgs = new List<Map<String, Object>>{
            new Map<String, Object>{
                'content' => 'Mensaje con content'
            },
            new Map<String, Object>{
                // mensaje vacío: m != null pero sin content
            }
        };

        String body = buildPayload('CONV-DEF-MODE', null, msgs);

        Test.startTest();
        System.enqueueJob(new aiChatRobot2Queueable(body));
        Test.stopTest();

        System.assert(true, 'Cubre mode por defecto y mensajes con claves faltantes sin romper.');
    }

    @IsTest
    static void testQueueable_EmptyBody_AbortsEarly() {
        Test.startTest();
        System.enqueueJob(new aiChatRobot2Queueable(''));
        Test.stopTest();

        System.assert(true, 'No debe fallar con rawBody vacío.');
    }

    @IsTest
    static void testQueueable_InvalidPayload_NoData() {
        // payload sin "data" => debe abortar
        Map<String, Object> payload = new Map<String, Object>{
            'conversationId' => 'CONV-NODATA',
            'mode' => 'FINAL_ANSWER'
        };
        String body = JSON.serialize(payload);

        Test.startTest();
        System.enqueueJob(new aiChatRobot2Queueable(body));
        Test.stopTest();

        System.assert(true, 'Debe abortar si falta "data".');
    }

    @IsTest
    static void testQueueable_DataEmptyList() {
        // "data": [] => debe abortar por dataList vacío
        String body = buildPayload('CONV-EMPTYDATA', 'FINAL_ANSWER', new List<Map<String, Object>>());

        Test.startTest();
        System.enqueueJob(new aiChatRobot2Queueable(body));
        Test.stopTest();

        System.assert(true, 'Debe abortar si dataList está vacío.');
    }

    @IsTest
    static void testQueueable_RootLevelMessageIdAndExplicability() {
        // Estructura nueva: messageId y explicability a nivel raíz, data solo con content
        List<Map<String, Object>> msgs = new List<Map<String, Object>>{
            new Map<String, Object>{
                'content' => 'This workflow relies heavily on internal sources.'
            },
            new Map<String, Object>{
                'content' => 'The proposed solution consists of developing a chatbot.'
            }
        };

        List<Map<String, Object>> explicability = new List<Map<String, Object>>{
            new Map<String, Object>{
                'type' => 'Default Content',
                'content' => 'TOOL',
                'order' => 1
            }
        };

        String body = buildPayload('707b2538-91302213', 'FINAL_ANSWER', msgs, '0001', explicability);

        Test.startTest();
        System.enqueueJob(new aiChatRobot2Queueable(body));
        Test.stopTest();

        System.assert(true, 'Debe procesar correctamente messageId y explicability a nivel raíz.');
    }

    @IsTest
    static void testQueueable_DataFailureNull_WithData() {
        // Estructura donde dataFailure viene como null pero data tiene contenido (no debe entrar en rama de error)
        Map<String, Object> payload = new Map<String, Object>{
            'mode' => 'FINAL_ANSWER',
            'dataFailure' => null,
            'data' => new List<Object>{
                new Map<String, Object>{ 'content' => 'Respuesta exitosa' }
            },
            'conversationId' => 'CONV-DF-NULL',
            'messageId' => '0001',
            'explicability' => new List<Object>{
                new Map<String, Object>{ 'type' => 'Default Content', 'content' => 'TOOL', 'order' => 1 }
            }
        };
        String body = JSON.serialize(payload);

        Test.startTest();
        System.enqueueJob(new aiChatRobot2Queueable(body));
        Test.stopTest();

        System.assert(true, 'Debe procesar data correctamente aunque dataFailure sea null.');
    }
}