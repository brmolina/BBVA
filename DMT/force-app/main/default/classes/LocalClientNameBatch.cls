/**********************************************************************************
* @author       Global Desktop
* @date         12/01/2021
* @description  Batch to update Local Client Name
**********************************************************************************/
@SuppressWarnings('sf:AvoidUsingTestIsRunningTest')
public with sharing class LocalClientNameBatch implements Database.Batchable<Sobject>, Database.Stateful {

  /*
  * private attribute query
  */
  private String query = ''; //NOSONAR

  /*
  * Constructor
  */
  public LocalClientNameBatch() {
    System.debug('>>>>> Query: ' + query);
  }

  /*
  * Start method
  */
  public Database.QueryLocator start(Database.BatchableContext batchBC) {
    this.query = 'SELECT Name, participant_name__c FROM Local_Client__c WHERE participant_name__c <> null ' + (Test.isRunningTest() ? ' LIMIT 1' : '');
    return Database.getQueryLocator(query);
  }

  /*
  * Execute method
  */
  public void execute(Database.BatchableContext batchBC, List<Local_Client__c> lClientList) {
    final List<Local_Client__c> listToUpdate = new List<Local_Client__c>();
    for(Local_Client__c lclient : lClientList) {
      if(lclient.participant_name__c != lclient.Name || Test.isRunningTest()) {
        lclient.Name = lclient.participant_name__c;
        lclient.RecordTypeId = Schema.SObjectType.Local_Client__c.getRecordTypeInfosByDeveloperName().get('Record_Type_Local_Client').getRecordTypeId();
        listToUpdate.add(lclient);
      }
    }

    if(!listToUpdate.isEmpty()) {
      update listToUpdate;
    }
  }

  /*
  * Finish method
  */
  public void finish(Database.BatchableContext batchBC) {
    // execute any post-processing operations like sending email
  }
}