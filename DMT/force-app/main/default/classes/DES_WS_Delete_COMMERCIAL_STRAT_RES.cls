//@RestResource(urlMapping='/deleteAccCommStraRes')
global with sharing class DES_WS_Delete_COMMERCIAL_STRAT_RES {
    /*
    @HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_COMMERCIAL_STRAT_RES(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
*/
    global static String runBookingBatch(){
        return 'Usado unicamente para la cobertura de codigo de una clase comentada';
    }
}