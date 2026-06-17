global with sharing class DES_cls_ApexRunPoller implements Schedulable {
    global String runId { get; private set; }
    global Integer attempt { get; private set; }
    
    global DES_cls_ApexRunPoller(String runId, Integer attempt) {
        this.runId = runId; 
        this.attempt = attempt;
    }
    
    global void execute(SchedulableContext sc) {
        // 🛑 ÚNICO CAMBIO: El Schedulable ahora lanza el Queueable.
        // Esto previene el error 'Callout Not Supported'.
        System.enqueueJob(new DES_cls_PollingCalloutInitiator(this.runId, this.attempt));
    }
    
}