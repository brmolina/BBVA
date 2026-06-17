/**
 * @description       : 
 * @author            : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * @group             : 
 * @last modified on  : 03-03-2026
 * @last modified by  : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   29-01-2026   Javier Setién Rivas - [javier_setien@epamneoris.com]   Initial Version
**/
public with sharing class aiChatRobot2Utils {
    private static bbvacon__GBL_integration_service__mdt integrationService;
    private static String serviceName;
    private static Map<String, Object> request;

    /**
    * @description Método principal de la gestión de llamada a servicios
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 24-02-2026 
    * @param String initialServiceName          ::  Nombre del servicio a invocar
    * @param Map<String,Object> initialRequest  ::  Cuerpo de la petición
    * @return HttpResponse 
    **/
    public static HttpResponse callService(String initialServiceName, Map<String, Object> initialRequest) {
        // Guardamos el valor del nombre del servicio
        serviceName = initialServiceName;
        // Por seguridad, inicializamos el cuerpo de la petición
        request = (initialRequest == null) ? new Map<String, Object>() : initialRequest;

        // Instanciamos la cadena de texto que contendrá el cuerpo de la petición convertido a texto
        String requestStr = '{';
        // Instanciamos la lista de parámetros y sus valores correspondientes que formarán el conjunto de la petición
        List<String> requestSentences = new List<String>();
        // Recorremos la lista de parámetros recibidos del cuerpo de la petición
        for (String mapKey : request.keySet()) {
            // Instanciamos la cadena de texto que contendrá cada uno de los pares clave => valor
            String sentenceChunk = '"'+mapKey+'":';
            // Casteamos como objeto genérico el valor del parámetro actual para realizar las comprobaciones para la conversión a texto correcta del valor
            Object mapValue = request.get(mapKey);
            // Validamos el tipo de valor actual para añadirlo a la cadena de texto de la manera correcta
            if (mapValue instanceof String) { // Parámetro como cadena de texto
                sentenceChunk += '"'+mapValue+'"';
            } else if (mapValue instanceof Boolean) { // Parámetro como booleano
                sentenceChunk += String.valueOf(mapValue);
            } else if (mapValue instanceof Integer) { // Parámetro como numérico
                sentenceChunk += String.valueOf(mapValue);
            } else if (mapValue instanceof Datetime) { // Parámetro como fecha
                sentenceChunk += '"'+String.valueOf(mapValue)+'"';
            } else { // Parámetro por defecto
                sentenceChunk += '""';
            }
            // Añadimos el texto compuesto con la clave => valor, a la lista de parámetros
            requestSentences.add(sentenceChunk);
        }
        // Combinamos todos los elementos de la lista en una misma cadena de texto y los separamos por comas
        String resultString = String.join(requestSentences, ',');
        // Terminamos de construir el cuerpo de la petición como cadena de texto
        requestStr += resultString + '}';
        
        // Instanciamos la respuesta del servicio 
        HttpResponse response;
        // Consultamos y guardamos la configuración XMAS del servicio
        integrationService = [SELECT bbvacon__Mock_LTA__c, bbvacon__Http_Method__c, bbvacon__Retrieve_Mock_LTA__c FROM bbvacon__GBL_integration_service__mdt WHERE DeveloperName = :serviceName WITH USER_MODE];
        // Comprobamos si nos encontramos en modo Test o si se ha marcado en configuración que debe recuperarse el Mock
        if (Test.isRunningTest() || integrationService.bbvacon__Retrieve_Mock_LTA__c) {
            response = getMock(serviceName);
        } else { // En caso de contexto normal...
            // Realizamos la invocación al servicio indicando el nombre del mismo y el cuerpo de la petición construido, y almacenamos la respuesta
            response = bbvacon.GBL_Integration_GenericService.invoke(serviceName, requestStr);
        }
        
        // Devolvemos la respuesta obtenida
        return response;
    }

    /*@TestVisible private static HttpResponse callService(String initialServiceName, Map<String, Object> initialRequest, HttpResponse customResponse) {
        HttpResponse unusedResponse = callService(initialServiceName, initialRequest);
        return customResponse;
    }*/

    public static HttpResponse getMock(String serviceName) {
        final HttpResponse response = new HttpResponse();
        final bbvacon__GBL_integration_service__mdt integrationService =   [SELECT bbvacon__Mock_LTA__c , bbvacon__Http_Method__c 
                                                                        FROM bbvacon__GBL_integration_service__mdt 
                                                                        WHERE DeveloperName =:serviceName 
                                                                        LIMIT 1];


        switch on integrationService.bbvacon__Http_Method__c {
            when 'POST' {
                response.setStatusCode(201);
                response.setStatus('Created');
            }
            when 'PUT', 'DELETE' {
                response.setStatusCode(204);
                response.setStatus('No Content');
            }
            when else {
                response.setStatusCode(200);
                response.setStatus('OK');
            }
        }
        if (integrationService.bbvacon__Mock_LTA__c != null) {
            response.setBody(integrationService.bbvacon__Mock_LTA__c);
        }

        return response;
    }
    
    public static Map<String, Object> buildRequest(Map<String, Object> queryParameters, Map<String, Object> requestBody) {
        Map<String, Object> request = new Map<String, Object>();

        // Process query parameters here, see ChatbotService.getConversations before commit 427fe93b944adf63e78695d9ad039447c0a77351

        if (requestBody != null) {
            request.put('payload', JSON.serialize(requestBody));
        }

        return request;
    }
    
    public static aiChatRobot2ServiceResponse processResponse(HttpResponse response, List<Integer> expectedStatusCodes) {
        aiChatRobot2ServiceResponse toReturn = new aiChatRobot2ServiceResponse();
        Map<String, Object> jsonResponse;

        if ((response.getBody().startsWith('{') && response.getBody().endsWith('}')) || (response.getBody().startsWith('[') && response.getBody().endsWith(']'))) {
            jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        }

        if (expectedStatusCodes.contains(response.getStatusCode())) {
            if (jsonResponse != null) {
                toReturn.isError = false;
                toReturn.data = jsonResponse.get('data');
            } else {
                toReturn.isError = false;
                toReturn.data = response.getBody();
            }
        } else {
            toReturn.isError = true;
            toReturn.errorMessage = 'The service returns an unexpected HTTP status code: ' + response.getStatusCode() + ' ' + response.getStatus();

            Map<String, Object> errorDetails = new Map<String, Object>();
            errorDetails.put('responseHttpStatusCode', response.getStatusCode());
            errorDetails.put('responseHttpStatus', response.getStatus());
            errorDetails.put('responseBody', response.getBody());
            toReturn.errorDetails = errorDetails;
        }

        return toReturn;
    }

    public static aiChatRobot2ServiceResponse treatException(Exception e) {
        aiChatRobot2ServiceResponse response = new aiChatRobot2ServiceResponse();

        response.isError = true;
        response.errorMessage = 'Apex exception: ' + e.getMessage();

        Map<String, Object> errorDetails = new Map<String, Object>();
        errorDetails.put('exception', e + '');
        if (e.getCause() != null) {
            errorDetails.put('cause', e.getCause() + '');
        }
        errorDetails.put('stackTrace', e.getStackTraceString());
        response.errorDetails = errorDetails;

        // TODO Cambiar esto por DES_Exception_Utils. ¿O mantener ambos?
        if (e.getCause() != null) {
            System.debug(e.getTypeName() + ' was caused by ' + e.getCause());
        }

        return response;
    }
}