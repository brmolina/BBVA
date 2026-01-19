@RestResource(urlMapping='/deleteTopWonDeals')
global with sharing class DES_WS_Delete_TopWonDeals {
    
    
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_TopWonDeals(), 100);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}