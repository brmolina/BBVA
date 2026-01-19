@RestResource(urlMapping='/deleteSubsidiaryGroupRelation')
global with sharing class WS_DeleteSubsidiaryGroupRelation {

	@HttpGet
  	global static Id runRelationBatch() {
    	Id batchInstanceId = Database.executeBatch(new DeleteSubsidiaryGroupRelation_Batch(), 2000);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
		return batchInstanceId;
	}
	
}