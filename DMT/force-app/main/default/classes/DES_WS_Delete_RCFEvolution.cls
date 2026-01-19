@RestResource(urlMapping='/deleteRCFEvolution')
global with sharing class DES_WS_Delete_RCFEvolution {
    
    
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_RCFEvolution(), 100);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}