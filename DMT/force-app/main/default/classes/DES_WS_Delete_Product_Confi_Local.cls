@RestResource(urlMapping='/deleteProductConfiLocal')
global with sharing class DES_WS_Delete_Product_Confi_Local {
	@HttpGet
    global static Id runBookingBatch(){
        Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Product_Confi_Local(), 10000);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        return batchInstanceId;
    }
}