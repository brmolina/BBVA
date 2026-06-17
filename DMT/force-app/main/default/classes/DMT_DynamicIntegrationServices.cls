/**
 * @description Conector genérico de integraciones dinámicas.
 * Responsabilidad única: construir el body via DMT_DynamicFieldMapper,
 * resolver la integración configurada en DMT_Dynamic_Int__mdt y
 * despachar la llamada a IASO o IXMAS.
 *
 * NO contiene lógica de negocio específica de ningún módulo.
 * Cada módulo (PAWIF, etc.) tiene su propio handler que llama a este conector.
 */
public class DMT_DynamicIntegrationServices {

    /**
     * @description Punto de entrada genérico. Construye el body desde el custom metadata,
     * resuelve la integración y realiza la llamada.
     * @param developerName  DeveloperName del registro en DMT_Dynamic_Int__mdt
     * @param opportunityId  Id de la Opportunity a consultar
     * @param taskId         Id de la tarea (se añade al body como parámetro adicional)
     */
    @AuraEnabled(cacheable=false)
    public static void sendRequest(String developerName, String opportunityId, String taskId) {
        Map<String, Object> additionalParams = new Map<String, Object>();
        if (String.isNotBlank(taskId)) {
            additionalParams.put('taskId', taskId);
        }

        Map<String, Object> requestBody = DMT_DynamicFieldMapper.mapFields(
            developerName,
            opportunityId,
            additionalParams.isEmpty() ? null : additionalParams
        );

        DMT_DynamicIntMetadataService.IntegrationServiceConfig integrationConfig =
            DMT_DynamicIntMetadataService.resolveIntegrationService(developerName);

        invoke(integrationConfig, requestBody);
    }

    /**
     * @description Sobrecarga que acepta parámetros adicionales arbitrarios.
     * Útil cuando el handler de negocio necesita enriquecer el body antes de enviarlo.
     * @param developerName      DeveloperName del registro en DMT_Dynamic_Int__mdt
     * @param opportunityId      Id de la Opportunity a consultar
     * @param additionalParams   Parámetros extra que se añaden al body tal cual
     */
    public static void sendRequest(String developerName, String opportunityId, Map<String, Object> additionalParams) {
        Map<String, Object> requestBody = DMT_DynamicFieldMapper.mapFields(
            developerName,
            opportunityId,
            additionalParams
        );

        DMT_DynamicIntMetadataService.IntegrationServiceConfig integrationConfig =
            DMT_DynamicIntMetadataService.resolveIntegrationService(developerName);

        invoke(integrationConfig, requestBody);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Métodos privados de routing — no deben usarse fuera de este conector
    // ─────────────────────────────────────────────────────────────────────────

    private static void invoke(
        DMT_DynamicIntMetadataService.IntegrationServiceConfig integrationConfig,
        Map<String, Object> params
    ) {
        String serializedBody = JSON.serialize(params);
        System.debug('DMT_DynamicIntegrationServices.invoke | Type: ' + integrationConfig.integrationType +
                     ' | Service: ' + integrationConfig.serviceName + ' | Body: ' + serializedBody);

        if (integrationConfig.integrationType == 'IASO') {
            invokeIaso(integrationConfig.serviceName, serializedBody);
        } else if (integrationConfig.integrationType == 'IXMAS') {
            invokeIxmas(integrationConfig.serviceName, serializedBody);
        } else {
            System.debug('DMT_DynamicIntegrationServices — tipo de integración desconocido: ' + integrationConfig.integrationType);
        }
    }

    private static void invokeIaso(String serviceName, String body) {
        try {
            Map<String, Object> requestMap = new Map<String, Object>{ 'payload' => body };
            HttpResponse response = DMT_HPG_Utils.callService(serviceName, requestMap);

            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                System.debug('DMT_DynamicIntegrationServices.invokeIaso — OK [' + response.getStatusCode() + '] Service: ' + serviceName);
            } else {
                System.debug('DMT_DynamicIntegrationServices.invokeIaso — ERROR [' + response.getStatusCode() + '] Service: ' + serviceName + ' | Body: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('DMT_DynamicIntegrationServices.invokeIaso — EXCEPTION: ' + e.getMessage());
            throw e;
        }
    }

    private static void invokeIxmas(String serviceName, String body) {
        // TODO: descomentar cuando el paquete bbvacon esté instalado en el org
        /*
        try {
            if (!Test.isRunningTest()) {
                HttpResponse response = bbvacon.GBL_Integration_GenericService.invoke(serviceName, body);
                if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
                    System.debug('IXMAS error [' + response.getStatusCode() + ']: ' + response.getBody());
                }
            }
        } catch (Exception e) {
            System.debug('IXMAS invoke error: ' + e.getMessage());
        }
        */
        System.debug('invokeIxmas — pendiente. Service: ' + serviceName + ' | Body: ' + body);
    }
}