/**********************************************************************************
 * @author       Global Desktop
 * @description  Clase programable para lanzar el Batch UserToTerritoryBatch
 **********************************************************************************/
global without sharing class DES_Schedulable_userTerritory implements Schedulable {//NOSONAR
	/*
	 *	Global Desktop
	 *
	**/
	global void execute(SchedulableContext scMain) {
		final Id batchInstanceId = Database.executeBatch(new UserToTerritoryBatch(), (Integer)[SELECT Id, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = :Label.BATCH_SIZE_USER_TERRITORY LIMIT 1].Batch_Size__c);
		system.debug('>>>>> id BATCH UserToTerritoryBatch: ' + batchInstanceId);
		final Id batchIdVstTerrit = Database.executeBatch(new Batch_Visit_InvolvedProducts(), (Integer)[SELECT Id, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = :Label.BATCH_SIZE_INVOLVED_PRODUCTS LIMIT 1].Batch_Size__c);
		system.debug('>>>>> id BATCH Batch_Visit_InvolvedProducts: ' + batchIdVstTerrit);
	}
}