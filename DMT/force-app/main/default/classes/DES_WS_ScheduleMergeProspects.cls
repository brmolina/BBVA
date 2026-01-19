@RestResource(urlMapping='/mergeProspects')
global with sharing class DES_WS_ScheduleMergeProspects {


  @HttpGet
  global static Id runBookingBatch() {
    Id batchInstanceId = Database.executeBatch(new Batch_MergeProspects(), 1);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
		return batchInstanceId;
  }
}