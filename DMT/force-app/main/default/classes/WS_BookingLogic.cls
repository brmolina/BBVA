@RestResource(urlMapping='/bookLogic')
global with sharing class WS_BookingLogic {


  @HttpGet
  global static Id runBookingBatch() {
    Id batchInstanceId = Database.executeBatch(new DES_Booking_Batch(), 2000);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
		return batchInstanceId;
  }
}