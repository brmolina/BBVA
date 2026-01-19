@RestResource(urlMapping='/deleteCommitInterGarant')
global with sharing class DES_WS_Delete_Commit_Inter_Garant {
	@HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Commit_Inter_Garant(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}