@RestResource(urlMapping='/deleteLoansRepayment')
global with sharing class DES_WS_Delete_LoansRepayment {
    
    
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_LoansRepayment(), 100);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}