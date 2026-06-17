@IsTest
private class aiChatRobot2ChatInboundServiceTest {

    @IsTest
    static void testReceiveCallback() {
        
        String body = '{ "mode": "FINAL_ANSWER", "dataFailure": null, "data": [ { "content": "Hola" } ], "conversationId": "123", "messageId": "0001", "explicability": [ { "type": "Default Content", "content": "TOOL", "order": 1 } ] }';
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/ai/callback';
        req.addHeader('Content-Type','application/json');
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        aiChatRobot2ChatInboundService.receiveCallback();
        Test.stopTest();

        System.assertEquals(202, RestContext.response.statusCode, 'Debe devolver 202 Accepted');
        
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('accepted'), 'Debe devolver JSON con accepted');
    }
    
        @IsTest
    static void testReceiveCallbackException() {

        // Forzamos un error en el body (null) para entrar al catch
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/ai/callback';
        req.httpMethod = 'POST';
        req.requestBody = null; // Forzamos null para lanzar excepción
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        aiChatRobot2ChatInboundService.receiveCallback();
        Test.stopTest();

        // Debe devolver 500 y un error
        System.assertEquals(500, RestContext.response.statusCode);
        String respBody = RestContext.response.responseBody.toString();
        System.assert(respBody.contains('"error":'), 'Debe devolver el mensaje de error');
    }

    @IsTest
    static void testReceiveCallback_FinalAnswer() {
        // Simulamos un request FINAL_ANSWER completo con explicability
        String body = '{'
            + '"conversationId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",'
            + '"message": { "id": "0001" },'
            + '"status": "DONE",'
            + '"mode": "FINAL_ANSWER",'
            + '"data": [ { "content": "## Resultado final\\nEl **margen bruto de 2023** fue de **12.5B EUR**.\\n\\n### Detalles adicionales\\n- Ingresos totales estimados: **50.0B EUR**\\n- Coste de ventas estimado: **37.5B EUR**\\n- Margen bruto sobre ingresos: **25.0%**\\n- Variacion interanual (simulada): **+1.8 p.p.**\\n- Segmento destacado: **Corporate Lending**\\n- Region con mayor aporte: **Iberia**\\n- Escenario de sensibilidad: +1.0B en costes -> margen **11.5B EUR**\\n- Nota: cifras con fines de ejemplo para pruebas locales\\n\\n" } ],'
            + '"explicability": ['
            + '  { "type": "Hover", "order": 0, "content": "Data From: MdGyC (Subsidiaries), Ratings" },'
            + '  { "type": "SQL", "order": 1, "content": "SELECT ingresos_totales FROM finanzas WHERE ano = 2023;" },'
            + '  { "type": "SQL-nat", "order": 2, "content": "### Traduccion a lenguaje natural\\n1. Buscar datos de ano = 2023.\\n2. Restar coste a ingresos: 50.0 - 37.5.\\n3. Resultado final: 12.5B EUR." },'
            + '  { "type": "Tool", "order": 3, "content": "### Tool execution\\n- Tool: sql_executor\\n- Input numerico: ingresos=50.0, coste=37.5\\n- Operacion: 50.0 - 37.5\\n- Output: 12.5" }'
            + ']'
            + '}';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/ai/callback';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        aiChatRobot2ChatInboundService.receiveCallback();
        Test.stopTest();

        System.assertEquals(202, RestContext.response.statusCode, 'FINAL_ANSWER debe devolver 202 Accepted');
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('accepted'), 'FINAL_ANSWER debe devolver JSON con accepted');
    }

    @IsTest
    static void testReceiveCallback_Summary() {
        // Simulamos un request de tipo SUMMARY con contenido de resumen financiero
        String body = '{'
            + '"conversationId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",'
            + '"message": { "id": "0001" },'
            + '"status": "DONE",'
            + '"mode": "SUMMARY",'
            + '"data": [ { "content": "# Financial Summary\\n\\n# General Information\\n- **Client Name:** Iberdrola\\n- **Segment/Subsegment:** N/A / N/A\\n- **Group Country:** N/A\\n\\n# Revenues (Engloba D+45)\\n- **Currency:** EUR\\n- **Total (2 years ago):** 1000.0\\n- **Total (previous year):** 1000.0\\n- **YTD (current year):** 1000.0\\n\\n# Ratings\\n- **Internal Rating:** N/A\\n- **Internal Rating Date:** 2023-12-31\\n\\n# Unified Consumptions\\n- **Expiration Date:** 2023-12-31\\n- **Total Group Limit:** N/A\\n" } ]'
            + '}';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/ai/callback';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        aiChatRobot2ChatInboundService.receiveCallback();
        Test.stopTest();

        System.assertEquals(202, RestContext.response.statusCode, 'SUMMARY debe devolver 202 Accepted');
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('accepted'), 'SUMMARY debe devolver JSON con accepted');
    }

    @IsTest
    static void testReceiveCallback_ErrorDataFailure() {
        // Simulamos un request con estructura de error (dataFailure)
        String body = '{'
            + '"status": "ERROR",'
            + '"conversationId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",'
            + '"dataFailure": {'
            + '  "id": "ERR-PYDANTIC-001",'
            + '  "status": 422,'
            + '  "description": "VALIDATION_ERROR",'
            + '  "detail": "Body is missing or the JSON payload cannot be parsed."'
            + '}'
            + '}';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/ai/callback';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        aiChatRobot2ChatInboundService.receiveCallback();
        Test.stopTest();

        // Aunque el payload contiene un error de servicio, el endpoint siempre responde 202
        // porque delega el procesamiento al Queueable asincrono
        System.assertEquals(202, RestContext.response.statusCode, 'ERROR dataFailure debe devolver 202 Accepted');
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('accepted'), 'ERROR dataFailure debe devolver JSON con accepted');
    }
}