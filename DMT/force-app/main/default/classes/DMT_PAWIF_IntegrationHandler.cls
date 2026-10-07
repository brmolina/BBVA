/**
 * @description Handler de integraciones específico del módulo PAWIF.
 * Orquesta la lógica de negocio PAWIF y delega el envío a DMT_DynamicIntegrationServices.
 *
 * Responsabilidades:
 *  - Recibir payloads async (DMT_DynamicMapperPayload) desde DMT_AsyncDispatcher
 *  - Preparar parámetros adicionales específicos de PAWIF (stageName, taskId, etc.)
 *  - Invocar DMT_DynamicIntegrationServices.sendRequest para realizar la llamada
 *
 * NO contiene lógica de transporte ni de resolución de integraciones.
 */
public class DMT_PAWIF_IntegrationHandler {

    // ─────────────────────────────────────────────────────────────────────────
    // Handlers async — llamados desde DMT_AsyncDispatcher
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Procesa el cierre de una Opportunity de tipo DMT_Opportunity.
     * Añade el stageName como parámetro adicional al body y delega al conector.
     * @param payload DMT_DynamicMapperPayload con opportunityId, metadataName y stageName
     */
    public static void handleClosingIntegration(DMT_DynamicMapperPayload payload) {
        Map<String, Object> additionalParams = new Map<String, Object>();

        DMT_DynamicIntegrationServices.sendRequest(
            payload.metadataName,
            payload.opportunityId,
            additionalParams
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Métodos públicos invocables directamente (contexto síncrono)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Envía la solicitud inicial a PAWIF con el taskId del caso creado.
     * @param developerName  DeveloperName del registro en DMT_Dynamic_Int__mdt
     * @param opportunityId  Id de la Opportunity
     * @param taskId         Id de la tarea generada al iniciar el Case
     */
    public static void sendPawifRequest(String developerName, String opportunityId, String taskId) {
        DMT_DynamicIntegrationServices.sendRequest(developerName, opportunityId, taskId);
    }
}