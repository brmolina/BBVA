@RestResource(urlMapping='/deleteAccBBVAInfo')
global with sharing class DES_WS_Delete_ACCOUNT_BBVA_INFOR {
    
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_ACCOUNT_BBVA_INFOR(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}