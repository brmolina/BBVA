@RestResource(urlMapping='/accShareTerritory')
/*
 *  Global Desktop Account Share Territory Web Service
 *
 *
**/
@SuppressWarnings('sf:UseSingleton')
global with sharing class DES_WS_AccountShareTerritory {


  @HttpGet
  /*
   *  Global Desktop HTTPGET WS Method
   *
  **/
  global static Id runAccShareTerritory() {
    final Id batchInstanceId = Database.executeBatch(new AccountTerritoryBatch(), (Integer)[SELECT Id, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = :Label.BATCH_SIZE_ACC_SHARE_TERRITORY LIMIT 1].Batch_Size__c);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
		return batchInstanceId;
  }
}