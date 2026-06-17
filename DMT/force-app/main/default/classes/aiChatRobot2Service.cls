/**
 * @description       : Servicio para gestionar las peticiones HTTP del chatbot Robot2
 * @author            : Matias Maquieira
 * @group             : NEORIS
 * @last modified on  : 04-03-2026
 * @last modified by  : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * Modifications Log
 * Ver   Date         Author                Modification
 * 1.0   10-12-2025   Matias Maquieira     Initial Version - Implementación de feedback de mensajes
 * 1.1   15-12-2025   Matias Maquieira     Integración con IASO usando aiChatRobot2Utils
**/
public with sharing class aiChatRobot2Service {
    
    // Constantes
    final static List<String> validResponseCodes = new List<String>{'200', '201'};

    /**
    * @description Invoca el servicio externo indicado y procesa la respuesta
    * @author Matias Maquieira | 10-12-2025 
    * @param Map<String, Object> requestBody - Cuerpo de la petición
    * @return aiChatRobot2ServiceResponse    - Respuesta del servicio
    **/
    public static aiChatRobot2ServiceResponse manageServiceResponse(String serviceName, Map<String, Object> requestBody) {
        aiChatRobot2ServiceResponse srvResponse = new aiChatRobot2ServiceResponse();
        
        try {            
            // Llamar al servicio configurado en XMAS
            HttpResponse response = aiChatRobot2Utils.callService(serviceName, requestBody);
            
            // Procesar la respuesta esperando código 201
            aiChatRobot2ServiceResponse utilsResponse = aiChatRobot2Utils.processResponse(response, new List<Integer>{200, 201});
            
            // Asignar la respuesta directamente
            srvResponse = utilsResponse;
            
            // Validar si el servicio retorna status KO
            if (!srvResponse.isError && srvResponse.data != null && srvResponse.data instanceof Map<String, Object>) {
                Map<String, Object> responseData = (Map<String, Object>) srvResponse.data;

                if (!validResponseCodes.contains( (String) responseData.get('code') ) || (String) responseData.get('status') != 'OK') {
                    srvResponse = buildDefaultServiceError(response);
                }
            }
            
        } catch (Exception e) {
            srvResponse = new aiChatRobot2ServiceResponse(e);
        }
        
        return srvResponse;
    }

    /**
    * @description Método de construcción de las respuestas erróneas generales estándar
    * @author Javier Setién Rivas - [javier_setien@epamneoris.com] | 29-01-2026 
    * @param HttpResponse response  ::  Respuesta obtenida del servicio
    * @return aiChatRobot2ServiceResponse 
    **/
    @TestVisible
    private static aiChatRobot2ServiceResponse buildDefaultServiceError(HttpResponse response) {
        // Instanciamos la estructura auxiliar de la respuesta recibida
        aiChatRobot2ServiceResponse srvErrorResponse = new aiChatRobot2ServiceResponse();
        // Completamos la respuesta
        srvErrorResponse.isError = true;
        srvErrorResponse.errorMessage = 'El servicio ha devuelto un error';
        srvErrorResponse.errorDetails = new Map<String, Object>{'responseBody' => response.getBody()};
        // Devolvemos la respuesta errónea
        return srvErrorResponse;
    }
}