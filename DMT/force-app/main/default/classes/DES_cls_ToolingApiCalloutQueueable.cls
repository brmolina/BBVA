public class DES_cls_ToolingApiCalloutQueueable implements Queueable, Database.AllowsCallouts {

    private final Boolean skipCoverage;
private final List<String> testClassNames; 

    public DES_cls_ToolingApiCalloutQueueable(Boolean skipCoverage ) {
        this.skipCoverage = skipCoverage;
        this.testClassNames = testClassNames;
    }

    public void execute(QueueableContext context) {
       String runId = null;
    
        try {
            // 1) Intentar lanzar la ejecución de tests
            runId = DES_cls_ToolingApiClient.runAllLocalTests(this.skipCoverage); 
            System.debug('Run ID: ' + runId);
            
        } catch (Exception e) {
            // 🛑 CRÍTICO: Si falla la llamada inicial, avisamos y salimos.
            System.debug(LoggingLevel.ERROR, 'ERROR al iniciar el callout de tests: ' + e.getMessage());
            // Aquí puedes enviar un email a DES_sch_RunAllTestsScheduler.RECIPIENTS notificando el fallo inicial.
            return; // Salir de la ejecución
        }

        // 2) Si llegamos aquí, runId NO es null (el callout tuvo éxito), por lo que podemos programar el poller.
        if (runId != null) {
            DES_sch_RunAllTestsScheduler.scheduleOneTimePoll(runId, Datetime.now().addMinutes(5), 0);
        }

    }
}