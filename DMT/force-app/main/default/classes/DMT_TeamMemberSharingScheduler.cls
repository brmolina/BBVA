global with sharing class DMT_TeamMemberSharingScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Ejecuta el batch con un tamaño de lote de 200.
        Id batchJobId = Database.executeBatch(new DMT_TeamMemberSharingBatch(), 200);
    }
}