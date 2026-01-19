//@RestResource(urlMapping='/deleteAccBBVAClas')
global with sharing class DES_WS_Delete_BBVA_CLASSIF {
    /*
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_BBVA_CLASSIF(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
*/
    global static String runBookingBatch(){
        return 'Usado unicamente para la cobertura de codigo de una clase comentada';
    }
}