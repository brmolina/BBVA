/*
* @author       Global Desktop
* @date         23/07/2020
* @description  Util class to denormalize opps
*/
public without sharing class GBL_DenormalizeOppUtilsLocal {


  /*
  * Restore method to delete and denormalize
  */
  public void restore() { //NOSONAR
    Integer deleteBatchSize = 0;
    final List<AMH_GBL_Account_Multi_Hierarchy_denorm__mdt> lmdt = [SELECT Label, NamespacePrefix, DeveloperName, AMH_Delete_Batch_Size__c, AMH_Execute_Batch_Size__c, AMH_Lead_Lookup_Field_To_Account__c, AMH_Opportunity_Filter__c, AMH_Opportunity_Lookup_Field_To_Lead__c, AMH_Active__c FROM AMH_GBL_Account_Multi_Hierarchy_denorm__mdt WHERE AMH_Active__c = true LIMIT 1];
    if (!lmdt.isEmpty()) {
      deleteBatchSize = Integer.valueOf(lmdt[0].AMH_Delete_Batch_Size__c);
      system.debug('deleteBatchSize: ' + deleteBatchSize);
    }
    if (deleteBatchSize > 0) {
      final Id batchInstanceId = Database.executeBatch(new GBL_DenormalizeOppDeleteLocal(true), deleteBatchSize);
      system.debug('batchInstanceId -> ' + batchInstanceId);
    }
  }
}