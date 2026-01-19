@RestResource(urlMapping='/deleteRCFExpiration')
global with sharing class DES_WS_Delete_RCFExpiration {
    
    
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_RCFExpiration(), 100);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}