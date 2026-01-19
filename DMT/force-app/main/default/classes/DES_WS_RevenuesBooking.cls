@RestResource(urlMapping='/yoyByFamProducts')
global with sharing class DES_WS_RevenuesBooking {


  @HttpGet
  global static Id runBookingBatch() {
    Id batchInstanceId = Database.executeBatch(new Batch_Calcular_YOY_Revenues(), 200);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
		return batchInstanceId;
  }
}