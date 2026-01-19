@RestResource(urlMapping='/deleteAccRenewals')
global with sharing class DES_WS_Delete_Renewals {
    
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Renewals(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}