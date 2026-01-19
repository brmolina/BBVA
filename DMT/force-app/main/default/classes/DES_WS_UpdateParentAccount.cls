@RestResource(urlMapping='/firstUpdateRevenues')
global with sharing class DES_WS_UpdateParentAccount {


  @HttpGet
  global static Id runBookingBatch() {
    Id batchInstanceId = Database.executeBatch(new DES_Batch_firstUpdateRevenues(), 2000);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
		return batchInstanceId;
  }
}