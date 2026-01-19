/**-------------------------------------------------------------------------------------------
* @Name     DMT_IntegrationEventProcessor
* @Author   Javier Portilla <javieralberto.portilla.contractor@bbva.com>
* @Date     Created: 2025-09-02
* --------------------------------------------------------------------------------------------
* @Description Esta clase procesa los eventos publicados por DMT_Integration_Event
* --------------------------------------------------------------------------------------------
*/
public with sharing class DMT_IntegrationEventProcessor implements Queueable, Database.AllowsCallouts {

 private static final Integer MAX_ATTEMPTS = 3;

    private final String objectApi;
    private final String operation;
    private final String version;
    private final String seed;
    private final List<Id> recordIds;
    private final Integer attempt;

    public DMT_IntegrationEventProcessor(String objectApi, String operation, String version, String seed, List<Id> recordIds, Integer attempt){
        this.objectApi = objectApi;
        this.operation = String.isBlank(operation) ? 'Update' : operation;
        this.version   = String.isBlank(version) ? 'v1' : version;
        this.seed      = String.isBlank(seed) ? String.valueOf(System.currentTimeMillis()) : seed;
        this.recordIds = (recordIds == null) ? new List<Id>() : recordIds.clone();
        this.attempt   = (attempt == null) ? 0 : attempt;
    }

    public void execute(QueueableContext qc){
        System.debug('Inicio encolamiento');
        if (recordIds.isEmpty()) return;

        // Marca inbound para evitar rebotes en triggers
        DMT_IntegrationContext.setInbound(true);
        // Procesa en bulk: construir y enviar uno a uno
        List<Id> failed = new List<Id>();

        for (Id recId : recordIds){
            try {
                // Construye payload exacto
                List<String> listPayloads = DMT_RiskPositionLine_Helper.buildPayloads(recId, operation, version);
                // Si no hay nada que enviar, NO re-encolar
                if (listPayloads.isEmpty()) return;

                // Envía
                Map<String,Object> res = DMT_RiskPositionLine_Helper.send(listPayloads);
                Integer http = (Integer)res.get('statusCode');
                Boolean ok   = (Boolean)res.get('result');

                if (!(ok == true && http != null && http >= 200 && http < 300)) failed.add(recId);

            } catch (Exception e) {
                failed.add(recId);
                System.enqueueJob(new DMT_LogExceptionQueueable(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(),'DMT_IntegrationEventProcessor','execute','DMT',''));
            } finally {
                //Restaurar el estado aunque haya excepciones
                DMT_IntegrationContext.setInbound(false);
            }
        }

        // Si hubo fallos y quedan intentos, re-encola sólo los fallidos
        if (!failed.isEmpty() && attempt + 1 < MAX_ATTEMPTS){
            System.enqueueJob(new DMT_IntegrationEventProcessor(objectApi, operation, version, seed, failed, attempt + 1));
        }
    }

    // Helper para encolarla desde tu trigger del Platform Event
    public static void enqueueFromEvent(DMT_Integration_Event__e evt){
        if (evt == null || String.isBlank(evt.Object__c) || String.isBlank(evt.RecordIds__c)) return;
        List<Id> ids = new List<Id>();
        for (String s : evt.RecordIds__c.split(',')) { if (String.isNotBlank(s)) ids.add((Id)s.trim()); }
        if (!ids.isEmpty()){
            System.enqueueJob(new DMT_IntegrationEventProcessor(evt.Object__c, evt.Operation__c, evt.PayloadVersion__c, evt.Seed__c, ids, 0));
        }
    }

}