/**********************************************************************************
* @author
* @date
* @description  Batch para para eliminar DES_BBVA_Management_team__c
* @Revision
**********************************************************************************/
public without sharing class DES_Batch_EliminarBBVAMember implements Database.Batchable<Sobject>, Database.Stateful {

  private DateTime lastUpdateDate;//NOSONAR
  /*
  * Query attribute
  */
  private String query = 'SELECT id, Name, CreatedBy.Profile.Name, DES_Client__c,LastModifiedDate,DES_User__c from DES_BBVA_Management_team__c  '+ (Test.isRunningTest() ? ' LIMIT 1' : '')+ (!Test.isRunningTest() ? 'WHERE CreatedBy.Profile.Name = \'Desktop Integration\' AND LastModifiedDate <: lastUpdateDate' : '');//NOSONAR

  /*
  * Mapa para almacenar valores del batch
  */
  private Map<Id, List<Id>> memberMap = new Map<Id, List<Id>>();//NOSONAR
  /*
  * Lanza Batch para eliminar DES_BBVA_Management_team__c
  */
  public DES_Batch_EliminarBBVAMember() {
    string querys='SELECT id, Name, CreatedBy.Profile.Name, DES_Client__c, LastModifiedDate from DES_BBVA_Management_team__c '+ (Test.isRunningTest() ? 'LIMIT 1':'')+ (!Test.isRunningTest() ? ' WHERE CreatedBy.Profile.Name = \'Desktop Integration\'  ORDER BY LastModifiedDate  desc limit 1':'');//NOSONAR
    
    final List<DES_BBVA_Management_team__c> membersBBVA = Database.query(querys);
    if(!membersBBVA.isEmpty()) {
		  lastUpdateDate = membersBBVA.get(0).LastModifiedDate.addDays(-2);
      //lastUpdateDate = membersBBVA.get(0).LastModifiedDate.addMinutes(-10);
    }
    //lastUpdateDate.addDays(-2);
    system.debug('>>>>> Query: ' + query);
  }
  /*
  * Lanza Batch para eliminar DES_BBVA_Management_team__c
  */
  public Database.QueryLocator start(Database.BatchableContext bc1) {
    system.debug('>>>>> query : ' + query);
    return Database.getQueryLocator(query);
  }
  /*
  * Lanza Batch para eliminar DES_BBVA_Management_team__c
  */
  public void execute(Database.BatchableContext bc1, List<DES_BBVA_Management_team__c> membersBBVA) {
    for(DES_BBVA_Management_team__c member : membersBBVA) {
        if(!memberMap.isEmpty() && memberMap.containsKey(member.DES_Client__c) &&  member.LastModifiedDate!=lastUpdateDate) {
            memberMap.get(member.DES_Client__c).add(member.DES_User__c);
        } else {
            memberMap.put(member.DES_Client__c, new List<Id> {member.DES_User__c});
        }
    }
      system.debug(memberMap);
      Database.delete(membersBBVA);
      Database.emptyRecycleBin(membersBBVA);
  }
  /*
  * Lanza Batch para eliminar DES_BBVA_Management_team__c
  */
  public void finish(Database.BatchableContext bc1) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc1.getJobId()];
    system.debug('++ job ' + job);
    System.debug('memberMap--------------->'+memberMap);
    System.debug('ACCOUNT memberMap--------------->'+memberMap);
    if(job.TotalJobItems > 0) {

      Batch_DeleteOppShare.runJobForParticularRecords(memberMap);
    }
  }
}