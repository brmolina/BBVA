global class DES_cls_PollingCalloutInitiator implements Queueable, Database.AllowsCallouts {
    
    private final String runId;
    private final Integer attempt;

    global DES_cls_PollingCalloutInitiator(String runId, Integer attempt) {
        this.runId = runId;
        this.attempt = attempt;
    }

    global void execute(QueueableContext context) {
        String status = null;
        DES_cls_ToolingApiClient.RunStatusDTO runInfo;
        try {
            // Obtener el estado (CALLOUT permitido en Queueable)// 1. Obtener el estado y el ID de resultado
            runInfo = DES_cls_ToolingApiClient.getRunStatus(this.runId);
            status = runInfo.status; // Usar el estado devuelto
            System.debug('Run ' + runId + ' status: ' + status + ' (attempt ' + attempt + ')');
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ERROR en Polling Callout al obtener estado: ' + e.getMessage());
            // Si el callout falla por X razón, reintentamos por si es temporal.
            status = 'Processing'; 
        }

        if (status == 'Completed') {
            // Lógica de finalización exitosa con Callout de DES_cls_ToolingApiClient.getFailures
            List<DES_cls_ToolingApiClient.TestFailureDTO> fails = DES_cls_ToolingApiClient.getFailures(runInfo.runResultId);
            DES_cls_TestResultMailer.sendFailuresCsv(DES_sch_RunAllTestsScheduler.RECIPIENTS, runInfo.runResultId, fails);
            return;
        }
        
        if (status == 'Aborted' || status == 'Failed') {
            // Lógica de finalización fallida (no se obtiene el detalle de fallos, solo se notifica)
            DES_cls_TestResultMailer.sendFailuresCsv(DES_sch_RunAllTestsScheduler.RECIPIENTS, runId,
            new List<DES_cls_ToolingApiClient.TestFailureDTO>());
            return;
        }
        
        // Lógica de Reintento
        Integer maxAttempts = 288;
        if (attempt < maxAttempts) {
            // Reprograma el siguiente Schedulable (el ApexRunPoller original)
            DES_sch_RunAllTestsScheduler.scheduleOneTimePoll(runId, Datetime.now().addMinutes(5), attempt + 1);
        } else {
            // timeout: avisar
            Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
            m.setToAddresses(DES_sch_RunAllTestsScheduler.RECIPIENTS);
            m.setSubject('[Apex Tests] Timeout esperando ejecución ' + runId);
            m.setPlainTextBody('El run ' + runId + ' no terminó tras ' + maxAttempts + ' intentos.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{m});
        }
    }
}