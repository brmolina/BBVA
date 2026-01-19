@RestResource(urlMapping='/deleteEVARAR')
global with sharing class DES_WS_Delete_EVA_RAR {
    
    
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_EVA_RAR(), 5000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}