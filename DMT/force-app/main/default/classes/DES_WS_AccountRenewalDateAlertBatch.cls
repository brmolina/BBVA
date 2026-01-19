@RestResource(urlMapping='/accountRenewalDateAlert')
global with sharing class DES_WS_AccountRenewalDateAlertBatch {


  @HttpGet
  global static Id runBookingBatch() {
    Id batchInstanceId = Database.executeBatch(new DES_AccountRenewalDateAlertBatch(), 10000);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
		return batchInstanceId;
  }
}