/**
 * @description       : Clase encargada de transformar el cuerpo de la llamada al servicio recibido en 
 *                      la estructura del Evento de plataforma para su publicación y escucha desde los LWC
 * @author            : José María Manzano Gómez - [jose_manzanogomez@epamneoris.com]
 * @group             : EPAM NEORIS
 * @last modified on  : 24-04-2026
 * @last modified by  : Javier Setién Rivas - [javier_setien@epamneoris.com]
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   29-01-2026   Javier Setién Rivas - [javier_setien@epamneoris.com]   Initial Version
**/
public with sharing class aiChatRobot2Queueable implements Queueable, Database.AllowsCallouts{
    // Constantes
    final static List<String> errorModes = new List<String>{'FAILED'};
    // Variables globales privadas
    private String rawBody;

    public aiChatRobot2Queueable(String body){
        this.rawBody = body == null ? '' : body;
    }

    public void execute(QueueableContext ctx){
        if (String.isBlank(rawBody)){
            System.debug('rawBody vacío. Abortando.');
            return;
        }

        try{
            // Parseo seguro del JSON
            Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(rawBody);

            if (payload == null || (!payload.containsKey('data') 
                                        && !(payload.containsKey('dataFailure') && payload.get('dataFailure') != null) 
                                        && (!payload.containsKey('mode')))){
                System.debug('### ERROR: payload inválido o sin "data".');
                return;
            }

            // Comprobar que existe el Platform Event (API name exacto)
            String eventApiName = 'Chatbot_AI_Banker__e';
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            if (!globalDescribe.containsKey(eventApiName)){
                System.debug('Platform Event "' + eventApiName + '" no encontrado en este org. Comprueba el API name.');
                return;
            }

            Schema.SObjectType eventType = globalDescribe.get(eventApiName);
            List<SObject> eventsToPublish = new List<SObject>();

            // Extraer el modo (SUMMARY o FINAL_ANSWER por defecto)
            String mode = payload.containsKey('mode') ? (String) payload.get('mode') : 'FINAL_ANSWER';

            // Procesar siempre como array de mensajes (estructura nueva)
            String convId = payload.containsKey('conversationId') ? (String) payload.get('conversationId') : null;

            // Extraer messageId del nivel raíz del payload
            String messageId = payload.containsKey('messageId') ? String.valueOf(payload.get('messageId')) : null;

            // Extraer explicability del nivel raíz del payload y serializarlo a JSON string
            String explicability = null;
            if (payload.containsKey('explicability') && payload.get('explicability') != null) {
                explicability = JSON.serialize(payload.get('explicability'));
            }

            // Instanciamos el listado donde guardar el valor recibido del parámetro 'data' si se recibe
            List<Object> dataList = new List<Object>();
            // Comprobamos que se recibe el parámetro 'data' y no llega nulo
            if (payload.containsKey('data') && payload.get('data') != null) {
                // "data" es una LISTA de objetos, cada uno con un campo "content"
                dataList = (List<Object>)payload.get('data');
            }
            // Controlamos si la estructura del mensaje recibido es una estructura de éxito con el parámetro "data" presente y el parámetro "mode" no indique error
            if ( !dataList.isEmpty() && (payload.containsKey('mode') && !errorModes.contains((String) payload.get('mode'))) ) {

                for (Object oMsg : dataList){
                    Map<String, Object> m = (Map<String, Object>)oMsg;
                    SObject ev = eventType.newSObject();
                    if (convId != null)
                        ev.put('ConversationId__c', convId);
                    if (messageId != null)
                        ev.put('MessageId__c', messageId);
                    if (m != null && m.containsKey('content'))
                        ev.put('Content__c', String.valueOf(m.get('content')));
                    if (explicability != null)
                        ev.put('Explicability__c', explicability);
                    ev.put('Mode__c', mode);
                    ev.put('Sender__c', 'bot');
                    ev.put('Timestamp__c', System.now());
                    eventsToPublish.add(ev);
                }
            }
            // Controlamos si la estructura del mensaje recibido es una estructura de error con el parámetro "dataFailure" presente
            else if ( (payload.containsKey('dataFailure') && payload.get('dataFailure') != null) && (payload.containsKey('mode') && errorModes.contains((String) payload.get('mode'))) ) {
                // Instanciamos el evento de plataforma a publicar
                SObject ev = eventType.newSObject();
                // Añadimos el ID de Conversación
                ev.put('ConversationId__c', convId);
                // Casteamos el Objeto con los detalles del error recibido
                Map<String, Object> errorData = (Map<String, Object>) payload.get('dataFailure');
                // Validamos los diversos parámetros con información del error para añadirlos al evento de plataforma
                if (errorData.containsKey('status')) {
                    ev.put('ErrorStatus__c', Integer.valueOf(errorData.get('status')));
                }
                if (errorData.containsKey('description')) {
                    ev.put('ErrorDescription__c', String.valueOf(errorData.get('description')));
                }
                if (errorData.containsKey('detail')) {
                    ev.put('ErrorDetail__c', String.valueOf(errorData.get('detail')));
                }
                // Incluimos el evento construido en el listado de eventos a publicar
                eventsToPublish.add(ev);
            } else{
                System.debug('El payload no ha cumplido ninguna condición de contenido o error');
                return;
            }

            if (eventsToPublish.isEmpty()){
                System.debug('No hay eventos a publicar.');
                return;
            }

            // Publicar los eventos (usando API dinámica)
            // EventBus.publish acepta lista de SObjects en API recientes; si falla,
            // se puede publicar de uno en uno.
            try{
                Database.SaveResult[] results = EventBus.publish(eventsToPublish);
                Integer successCount = 0;
                for (Database.SaveResult r : results){
                    if (r.isSuccess())
                        successCount++;
                    else
                        System.debug('Publish error: ' + r.getErrors()[0].getMessage());
                }
            } catch (Exception ePublish){
                // Fallback: intentar publicar uno a uno y loguear qué falla
                System.debug('publish(events) falló: ' + ePublish.getMessage() + '. Intentando publicar individualmente.');
                Integer success = 0;
                for (SObject oneEv : eventsToPublish){
                    try{
                        Database.SaveResult rSingle = EventBus.publish(oneEv);
                        if (rSingle != null && rSingle.isSuccess())
                            success++;
                        else if (rSingle != null){
                            for (Database.Error err : rSingle.getErrors()){
                                System.debug('Publish single error: ' + err.getMessage());
                            }
                        }
                    } catch (Exception eSingle){
                        System.debug('Error publicando evento individual: ' + eSingle.getMessage());
                    }
                }
            }
        } catch (Exception e){
            System.debug('Error en AIChatQueueable.execute: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
    } 

}