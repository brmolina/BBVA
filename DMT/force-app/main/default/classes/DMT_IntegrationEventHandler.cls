/**-------------------------------------------------------------------------------------------
* @Name     DMT_IntegrationEventHandler
* @Author   Javier Portilla <javieralberto.portilla.contractor@bbva.com>
* @Date     Created: 2025-09-02
* --------------------------------------------------------------------------------------------
* @Description Publica Integration_Event__e con chunking y metadatos comunes
* --------------------------------------------------------------------------------------------
*/
public with sharing class DMT_IntegrationEventHandler {

    private static final Integer CHUNK_SIZE = 150;
    private static final String DEFAULT_VERSION = 'v1';

    /**
     * Publica eventos a partir de registros del trigger (after insert/update).
     * Mantiene el trigger delgado y bulkificado.
     * * Simplified: Publishes only resolved valid line Ids as 'DMT_Line__c' to minimize empties.
     */
    public static void publishFromRecords(List<SObject> records, String operation, String payloadVersion) {
        System.debug('publishFromRecords operation, '+ operation);
        System.debug('publishFromRecords payloadVersion, '+ payloadVersion);
        System.debug('publishFromRecords records, '+ records);
        if (records == null || records.isEmpty()) return;

        Set<Id> idSet = new Set<Id>();
        for (SObject s : records) {
            if (s != null) idSet.add((Id)s.get('Id'));
        }
        if (idSet.isEmpty()) return;

        List<String> validObjectNames = new List<String>{'DMT_Line__c', 'DMT_Consolidated_Line__c', 'Custom_Association__c', 'Custom_Association_Client__c', 'DMT_Warranty__c', 'DMT_Currency_Provision__c'};
        String objectName = records[0].getSObjectType().getDescribe().getName();

        System.debug('publishFromRecords objectName: '+ objectName);

        /* List<String> ignoreInsertList = new List<String>{'Custom_Association__c', 'Custom_Association_Client__c', 'DMT_Warranty__c'}; //there is an automation that will update the record after insert, therefor, will trigger the update. ignoring insert to avoid publishing the same Platform event twice.
        if(operation == 'Insert' && ignoreInsertList.contains(objectName)){
            return;
        } */

        if(!validObjectNames.contains(objectName)) return;

        System.debug('object name is valid. proceed');
        // Shortcut: For direct lines, skip resolution and use originals as lineIds
        List<Id> listLineId = (objectName == 'DMT_Line__c') ? new List<Id>(idSet) : DMT_RiskPositionLine_Helper.getLineIds(objectName, idSet);
        System.debug('listLineId: '+ JSON.serialize(listLineId));
        if (listLineId.isEmpty()) return;

        List<DMT_Line__c> lineList = DMT_RiskPositionLine_Helper.getLineInfo(listLineId);

        System.debug('lineList: '+ JSON.serialize(lineList));

        if(lineList.isEmpty()) return;
        System.debug('line list is not empty.proceed');
        List<Id> validIds = new List<Id>();
        for(DMT_Line__c line : lineList){
            validIds.add(line.Id);
        }
        publish('DMT_Line__c', operation, validIds, payloadVersion);    
    }

    /**
     * Publica eventos a partir de una lista de Ids ya conocida.
     */
    public static void publish(String objectApi, String operation, List<Id> ids, String payloadVersion) {
        System.debug('entered publish');
        if (ids == null || ids.isEmpty()) return;

        String version = String.isBlank(payloadVersion) ? DEFAULT_VERSION : payloadVersion;

        // Un mismo seed para todos los eventos generados en esta invocación (correlación/idempotencia)
        String seed = String.valueOf(System.currentTimeMillis());

        List<List<Id>> chunks = chunk(ids, CHUNK_SIZE);
        List<DMT_Integration_Event__e> events = new List<DMT_Integration_Event__e>();

        for (List<Id> c : chunks) {
            DMT_Integration_Event__e evt = new DMT_Integration_Event__e();
            evt.Object__c          = objectApi;System.debug('entered object '+ objectApi);
            evt.Operation__c       = String.isBlank(operation) ? 'Update' : operation;
            evt.PayloadVersion__c  = version;
            evt.Seed__c            = seed;
            evt.RecordIds__c       = joinIds(c);
            events.add(evt);
        }

        DMT_IntegrationContext.setInbound(true);
        
        try {
            // Publicación bulk
            EventBus.publish(events);
        } finally {
            DMT_IntegrationContext.setInbound(false);
        }
    }

    // -------------------- helpers --------------------

     // Chunking sin subList()
    private static List<List<Id>> chunk(List<Id> src, Integer size) {
        List<List<Id>> out = new List<List<Id>>();
        if (src == null || src.isEmpty()) return out;
        Integer s = (size == null || size <= 0) ? 150 : size;

        List<Id> current = new List<Id>();
        for (Id v : src) {
            current.add(v);
            if (current.size() == s) {
                out.add(current);
                current = new List<Id>();
            }
        }
        if (!current.isEmpty()) out.add(current);
        return out;
    }

    private static String joinIds(List<Id> ids) {
        List<String> ss = new List<String>();
        for (Id i : ids) ss.add((String)i);
        return String.join(ss, ',');
    }
}