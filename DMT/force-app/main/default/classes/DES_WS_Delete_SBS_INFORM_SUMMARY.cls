@RestResource(urlMapping='/deleteAccSBSInfoSumm')
global with sharing class DES_WS_Delete_SBS_INFORM_SUMMARY {
    
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_SBS_INFORM_SUMMARY(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}