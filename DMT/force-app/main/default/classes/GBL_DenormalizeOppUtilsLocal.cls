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
    final List<dwp_acmh__GBL_Account_Multi_Hierarchy_denorm__mdt> lmdt = [SELECT Label, NamespacePrefix, DeveloperName, dwp_acmh__Delete_Batch_Size__c, dwp_acmh__Execute_Batch_Size__c, dwp_acmh__Lead_Lookup_Field_To_Account__c, dwp_acmh__Opportunity_Filter__c, dwp_acmh__Opportunity_Lookup_Field_To_Lead__c, dwp_acmh__Active__c FROM dwp_acmh__GBL_Account_Multi_Hierarchy_denorm__mdt WHERE dwp_acmh__Active__c = true LIMIT 1];
    if (!lmdt.isEmpty()) {
      deleteBatchSize = Integer.valueOf(lmdt[0].dwp_acmh__Delete_Batch_Size__c);
      system.debug('deleteBatchSize: ' + deleteBatchSize);
    }
    if (deleteBatchSize > 0) {
      final Id batchInstanceId = Database.executeBatch(new GBL_DenormalizeOppDeleteLocal(true), deleteBatchSize);
      system.debug('batchInstanceId -> ' + batchInstanceId);
    }
  }
}