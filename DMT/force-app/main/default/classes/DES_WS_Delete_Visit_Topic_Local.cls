@RestResource(urlMapping='/deleteVisitTopicLocal')
global with sharing class DES_WS_Delete_Visit_Topic_Local {
	@HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Visit_Topic_Local(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}