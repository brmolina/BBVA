//@RestResource(urlMapping='/deleteAccSBSInfo')
global with sharing class DES_WS_Delete_SBS_INFORM {
    /*
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_SBS_INFORM(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
*/
    global static String runBookingBatch(){
        return 'Usado unicamente para la cobertura de codigo de una clase comentada';
    }
}