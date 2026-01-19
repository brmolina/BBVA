/**********************************************************************************
* @author       Accenture
* @date
* @description
* @Revision
**********************************************************************************/
public without sharing class DES_Batch_SaveMatrixInGroup implements Database.Batchable<Sobject>, Database.Stateful {
  //private String filterQuery = 'S';
  //private String query = 'SELECT Id, DES_Main_Parent__c, DES_Client_Matrix__c FROM Account WHERE DES_Entity_Hierarchy__c =' + filterQuery;

  public DES_Batch_SaveMatrixInGroup() {

    //system.debug('>>>>> Query: ' + query);
  }


  public Database.QueryLocator start(Database.BatchableContext bc) {

    //return Database.getQueryLocator(query);
    return Database.getQueryLocator([SELECT Id, DES_Main_Parent__c, DES_Client_Matrix__c, DES_Country_Matrix__c FROM Account WHERE DES_Entity_Hierarchy__c = 'S']);
  }

  public void execute(Database.BatchableContext bc, List<Account> listAccounts) {

    set<Id> accountSetIds = new set<Id>();
    for(Account i : listAccounts) {
      accountSetIds.add(i.Id);
    }
    map<Id,Account> accList = new map<Id,Account>([SELECT id, RecordType.DeveloperName, DES_Tier__c, DES_Country_of_Management__c, DES_Country_Client__c, DES_Segment__c, DES_Entity_Hierarchy__c,
                                                   DES_Main_Parent__c, DES_Main_Parent__r.RecordType.DeveloperName, DES_Main_Parent__r.DES_Tier__c, DES_Main_Parent__r.DES_Country_of_Management__c, DES_Main_Parent__r.DES_Country_Client__c, DES_Main_Parent__r.DES_Segment__c,
                                                   DES_Main_Parent__r.DES_Main_Parent__c, DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName, DES_Main_Parent__r.DES_Main_Parent__r.DES_Tier__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Country_of_Management__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Country_Client__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Segment__c,
                                                   DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Tier__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Country_of_Management__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Country_Client__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Segment__c,
                                                   DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Tier__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Country_of_Management__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Country_Client__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Segment__c,
                                                   DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Tier__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Country_of_Management__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Country_Client__c, DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Segment__c
                                                   FROM Account
                                                   WHERE id IN: accountSetIds]);
    system.debug('Valor de accList: ' +accList);
    Map<Id,Account> grupoMatriz = new Map<Id,Account>();
    for(Account a : accList.values()) {
      if(a.RecordType.DeveloperName == 'Group' || a.RecordType.DeveloperName == 'DES_Commercial_Client' || a.RecordType.DeveloperName == 'DES_Commercial_Client_BEC_Manually') {
        //a.DES_Client_Matrix__c =
        grupoMatriz.put(a.Id,a);
      } else if(a.DES_Main_Parent__r.RecordType.DeveloperName == 'Group' || a.DES_Main_Parent__r.RecordType.DeveloperName == 'DES_Commercial_Client' || a.DES_Main_Parent__r.RecordType.DeveloperName == 'DES_Commercial_Client_BEC_Manually') {
        grupoMatriz.put(a.DES_Main_Parent__r.Id,a);
      } else if(a.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName == 'Group' || a.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName == 'DES_Commercial_Client'
      || a.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName == 'DES_Commercial_Client_BEC_Manually') {
        grupoMatriz.put(a.DES_Main_Parent__r.DES_Main_Parent__r.Id,a);
      } else if(a.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName == 'Group' || a.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName == 'DES_Commercial_Client'
      || a.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName == 'DES_Commercial_Client_BEC_Manually') {
        grupoMatriz.put(a.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.Id,a);
      } else if(a.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName == 'Group' || a.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName == 'DES_Commercial_Client'
      || a.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.RecordType.DeveloperName == 'DES_Commercial_Client_BEC_Manually') {
        grupoMatriz.put(a.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.DES_Main_Parent__r.Id,a);
      }
    }
    system.debug('++ grupoMatriz ' + JSON.serialize(grupoMatriz));
    list<Account> acc = [SELECT id FROM Account WHERE id IN: grupoMatriz.keySet()];
    list<Account> accToUpdate = new list<Account>();
    for(Account a : acc) {
      if(a.Id != grupoMatriz.get(a.Id).Id) {
        a.DES_Client_Matrix__c = grupoMatriz.get(a.Id).Id;
        a.DES_Country_Matrix__c = grupoMatriz.get(a.Id).DES_Country_Client__c;
        accToUpdate.add(a);
      }
    }
    if(!accToUpdate.isEmpty()) {
      update accToUpdate;
    }

    system.debug('++ accToUpdate ' + JSON.serialize(accToUpdate));

  }


  public void finish(Database.BatchableContext bc) {

    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }


}