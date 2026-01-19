@RestResource(urlMapping='/deleteAccRel')
global with sharing class DES_WS_Delete_AccRel {
    
    
    @HttpGet
    global static Id runBookingBatch(){
    	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_AccRel(), 10000);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
		return batchInstanceId;
    }
}