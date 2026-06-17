/**
 * @description Servicio para gestionar las configuraciones de integración dinámica desde Custom Metadata
 * Lee los templates JSON y endpoints desde DMT_Dynamic_Int__mdt
 */
public with sharing class DMT_DynamicIntMetadataService {

    private static final String INTEGRATION_IASO  = 'IASO';
    private static final String INTEGRATION_IXMAS = 'IXMAS';

    /**
     * @description Wrapper con la configuración de integración resuelta (tipo + nombre de servicio)
     */
    public class IntegrationServiceConfig {
        public String integrationType  { get; set; } // IASO / IXMAS
        public String serviceName      { get; set; } // DeveloperName en el metadata de IASO/IXMAS
        public String serviceLabel     { get; set; } // MasterLabel del registro de integración

        public IntegrationServiceConfig(String integrationType, String serviceName, String serviceLabel) {
            this.integrationType = integrationType;
            this.serviceName     = serviceName;
            this.serviceLabel    = serviceLabel;
        }
    }

    /**
     * @description Obtiene la configuración completa de integración por nombre.
     * Lee también los nuevos campos DMT_Integration__c y DMT_MetadataIntegration__c.
     * @param metadataName Nombre del registro en el custom metadata (ej: 'PAWIF')
     * @return Map con jsonTemplate, developerName, integrationType y metadataIntegration
     */
    public static Map<String, Object> getIntegrationConfig(String metadataName) {
        try {
            String query = 'SELECT DeveloperName, DMT_JSON_Template__c, DMT_Integration__c, DMT_MetadataIntegration__c ' +
                           'FROM DMT_Dynamic_Int__mdt ' +
                           'WHERE DeveloperName = :metadataName ' +
                           'LIMIT 1';

            List<DMT_Dynamic_Int__mdt> configs = Database.query(query);

            if (configs.isEmpty()) {
                throw new DMT_DynamicIntException('No se encontró la configuración: ' + metadataName);
            }

            DMT_Dynamic_Int__mdt config = configs.get(0);

            Map<String, Object> result = new Map<String, Object>();
            result.put('jsonTemplate',        config.DMT_JSON_Template__c);
            result.put('developerName',        config.DeveloperName);
            result.put('integrationType',      config.DMT_Integration__c);
            result.put('metadataIntegration',  config.DMT_MetadataIntegration__c);

            return result;
        } catch (QueryException e) {
            throw new DMT_DynamicIntException('Error consultando custom metadata: ' + e.getMessage());
        }
    }

    /**
     * @description Resuelve la configuración de integración completa para un registro de DMT_Dynamic_Int__mdt.
     * Lee el tipo de integración (IASO/IXMAS) y consulta el metadata del paquete correspondiente
     * para obtener el nombre de servicio necesario en la llamada.
     *
     * @param metadataName DeveloperName del registro en DMT_Dynamic_Int__mdt
     * @return IntegrationServiceConfig con tipo, nombre y label del servicio de integración
     *
     * @example
     * IntegrationServiceConfig cfg = DMT_DynamicIntMetadataService.resolveIntegrationService('PAWIF');
     * // cfg.integrationType => 'IASO'
     * // cfg.serviceName     => 'DMT_PAWIF_Request'
     */
    public static IntegrationServiceConfig resolveIntegrationService(String metadataName) {
        Map<String, Object> config = getIntegrationConfig(metadataName);

        String integrationType     = (String) config.get('integrationType');
        String metadataIntegration = (String) config.get('metadataIntegration');

        if (String.isBlank(integrationType)) {
            throw new DMT_DynamicIntException('DMT_Integration__c no configurado en: ' + metadataName);
        }
        if (String.isBlank(metadataIntegration)) {
            throw new DMT_DynamicIntException('DMT_MetadataIntegration__c no configurado en: ' + metadataName);
        }

        if (integrationType == INTEGRATION_IASO) {
            return resolveIasoService(metadataIntegration);
        } else if (integrationType == INTEGRATION_IXMAS) {
            return resolveIxmasService(metadataIntegration);
        }

        throw new DMT_DynamicIntException('Tipo de integración no soportado: ' + integrationType);
    }

    // ─── Resolvers privados por tipo ──────────────────────────────────────────

    private static IntegrationServiceConfig resolveIasoService(String serviceDeveloperName) {
        try {
            String query = 'SELECT DeveloperName, MasterLabel ' +
                           'FROM iaso__GBL_integration_service__mdt ' +
                           'WHERE DeveloperName = :serviceDeveloperName ' +
                           'LIMIT 1';
            List<SObject> records = Database.query(query);

            if (records.isEmpty()) {
                throw new DMT_DynamicIntException('Servicio IASO no encontrado: ' + serviceDeveloperName);
            }

            SObject record = records[0];
            return new IntegrationServiceConfig(
                INTEGRATION_IASO,
                (String) record.get('DeveloperName'),
                (String) record.get('MasterLabel')
            );
        } catch (QueryException e) {
            throw new DMT_DynamicIntException('Error consultando metadata IASO: ' + e.getMessage());
        }
    }

    private static IntegrationServiceConfig resolveIxmasService(String serviceDeveloperName) {
        try {
            String query = 'SELECT DeveloperName, MasterLabel ' +
                           'FROM bbvacon__GBL_integration_service__mdt ' +
                           'WHERE DeveloperName = :serviceDeveloperName ' +
                           'LIMIT 1';
            List<SObject> records = Database.query(query);

            if (records.isEmpty()) {
                throw new DMT_DynamicIntException('Servicio IXMAS no encontrado: ' + serviceDeveloperName);
            }

            SObject record = records[0];
            return new IntegrationServiceConfig(
                INTEGRATION_IXMAS,
                (String) record.get('DeveloperName'),
                (String) record.get('MasterLabel')
            );
        } catch (QueryException e) {
            throw new DMT_DynamicIntException('Error consultando metadata IXMAS: ' + e.getMessage());
        }
    }
    
    /**
     * @description Obtiene solo el JSON template de una configuración
     * @param metadataName Nombre del registro en el custom metadata
     * @return String con el JSON template
     */
    public static String getJsonTemplate(String metadataName) {
        Map<String, Object> config = getIntegrationConfig(metadataName);
        return (String) config.get('jsonTemplate');
    }
    
    /**
     * @description Obtiene solo el endpoint destino de una configuración
     * @param metadataName Nombre del registro en el custom metadata
     * @return String con la URL del endpoint
     */
    public static String getDestino(String metadataName) {
        Map<String, Object> config = getIntegrationConfig(metadataName);
        return (String) config.get('destino');
    }
    
    /**
     * @description Obtiene todas las configuraciones disponibles
     * @return List de Maps con todas las configuraciones
     */
    public static List<Map<String, Object>> getAllIntegrations() {
        try {
            List<DMT_Dynamic_Int__mdt> configs = [
                SELECT DeveloperName, DMT_JSON_Template__c
                FROM DMT_Dynamic_Int__mdt
                ORDER BY DeveloperName ASC
            ];
            
            List<Map<String, Object>> results = new List<Map<String, Object>>();
            
            for (DMT_Dynamic_Int__mdt config : configs) {
                Map<String, Object> configMap = new Map<String, Object>();
                configMap.put('developerName', config.DeveloperName);
                configMap.put('jsonTemplate', config.DMT_JSON_Template__c);
                results.add(configMap);
            }
            
            return results;
        } catch (QueryException e) {
            throw new DMT_DynamicIntException('Error obteniendo todas las configuraciones: ' + e.getMessage());
        }
    }
    
    /**
     * @description Excepción personalizada para errores en el servicio de metadata
     */
    public class DMT_DynamicIntException extends Exception {}
}