@RestResource(urlMapping='/subsidiaryGroupRelate')
global with sharing class DES_WS_SubsidiaryGroupRelate {
    @HttpPost
    global static String run() {
        return initiateProcess();
    }

    public static String initiateProcess() {
        // Start the delete batch; it will chain the rebuild in finish()
        // Id deleteJobId = Database.executeBatch(new DES_DeleteSubsidiaryGroupRelationsBatch(), 200);
        return 'Done';
    }
}