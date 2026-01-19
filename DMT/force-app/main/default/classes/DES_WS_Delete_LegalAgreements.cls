@RestResource(urlMapping='/deleteLegalAgreements')
global with sharing class DES_WS_Delete_LegalAgreements {
    
    
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_LegalAgreements(), 100);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}