public class DMT_PAWIF_IntegrationServices {

    // ─────────────────────────────────────────
    // FLUJO 1 — Solicitud a PAWIF
    // ─────────────────────────────────────────
    public static void sendRequest(String oppId, String taskId) {

        
        Map<String, Object> request = DMT_DynamicFieldMapper.mapFields('sample', oppId);

        invoke('DMT_PAWIF_Request', request);
    }

    // ─────────────────────────────────────────
    // FLUJO 3 — Notificaciones a PAWIF
    // ─────────────────────────────────────────
    public static void notifyOppClosed(String oppId, String stageName) {

        String status = stageName == 'Closed Won' 
            ? 'Opp Closed Won' 
            : 'Opp Closed Lost';

        Map<String, Object> request = new Map<String, Object>{
            'oppId'  => oppId,
            'status' => status
        };

        invoke('DMT_PAWIF_Notification', request);
    }

    public static void notifyNbcClosed(String oppId, String result) {

        String status = result == 'Approved' 
            ? 'NBC Approved' 
            : 'NBC Rejected';

        Map<String, Object> request = new Map<String, Object>{
            'oppId'  => oppId,
            'status' => status
        };

        invoke('DMT_PAWIF_Notification', request);
    }

    // ─────────────────────────────────────────
    // FLUJO — Cierre de Opportunity (async)
    // Llamado desde DMT_AsyncDispatcher con un DMT_DynamicMapperPayload
    // ─────────────────────────────────────────
    public static void handleClosingIntegration(DMT_DynamicMapperPayload payload) {
        Map<String, Object> additionalParams = new Map<String, Object>{
            'stageName' => payload.stageName
        };
        Map<String, Object> request = DMT_DynamicFieldMapper.mapFields(
            payload.metadataName,
            payload.opportunityId,
            additionalParams
        );
        invoke('DMT_PAWIF_Request', request);
    }

    // ─────────────────────────────────────────
    // Método privado común
    // ─────────────────────────────────────────
    private static void invoke(String serviceName, Map<String, Object> params) {
        // TODO: descomentar cuando el paquete iaso esté instalado en el org
        /*
        try {
            if (!Test.isRunningTest()) {
                HttpResponse response = iaso.GBL_Integration_GenericService
                    .invoke(serviceName, JSON.serialize(params));

                if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
                    System.debug('PAWIF error [' + response.getStatusCode() + ']: ' + response.getBody());
                }
            }
        } catch (Exception e) {
            System.debug('DMT_Pawif_Service error: ' + e.getMessage());
        }
        */
        System.debug('DMT_PAWIF_IntegrationServices.invoke — pendiente de iaso. Service: ' + serviceName + ' | Params: ' + JSON.serialize(params));
    }
}