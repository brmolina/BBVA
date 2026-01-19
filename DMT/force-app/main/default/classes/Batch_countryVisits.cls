/**********************************************************************************
* @author
* @date
* @description  Batch para completar el país de las visitas con el del cliente
* @Revision
**********************************************************************************/
public without sharing class Batch_countryVisits implements Database.Batchable<Sobject>, Database.Stateful {
  /*
  * String query
  */
  final private String pQuery;

  /*
  * Constructor
  */
  public Batch_countryVisits() {
    pQuery = 'SELECT Id, dwp_kitv__country_name__c, dwp_kitv__Visit__c.dwp_kitv__account_id__c from dwp_kitv__Visit__c where dwp_kitv__country_name__c = null' + (Test.isRunningTest() ? ' LIMIT 1' : '');
  }

  /*
  * queryLocator
  */
  public Database.QueryLocator start(Database.BatchableContext bch) {
    return Database.getQueryLocator(pQuery);
  }

  /*
  * @author Global Desktop
  * @Description Actualiza el campo country de las visitas al del cliente.
  */
  public void execute(Database.BatchableContext bch, List<dwp_kitv__Visit__c> scope) {
    final List<String> countryValues = retrievePickListVisitValues();
    final List <dwp_kitv__Visit__c> visitsToUpdate = new List<dwp_kitv__Visit__c>();
    final Set<Id> accountsId = new set<Id>();

    for(dwp_kitv__Visit__c vis : scope) {
      accountsId.add(vis.dwp_kitv__account_id__c);
    }

    final Map<Id,Account> accList = new Map<Id,Account>([SELECT id, DES_Country_Client__c FROM Account WHERE Id IN: accountsId]);
    for(dwp_kitv__Visit__c vis2 : scope) {
      if(vis2.dwp_kitv__account_id__c != null && vis2.dwp_kitv__country_name__c == null && countryValues.contains(accList.get(vis2.dwp_kitv__account_id__c).DES_Country_Client__c)) {
        vis2.dwp_kitv__country_name__c = accList.get(vis2.dwp_kitv__account_id__c).DES_Country_Client__c;
        visitsToUpdate.add(vis2);
      }
    }

    if(!visitsToUpdate.isEmpty()) {
      update visitsToUpdate;
    }
  }

  /*
  * @author Global Desktop
  * @Description Devuelve el nombre API de los valores de la picklist de pais del objeto visita.
  */
  private static List<String> retrievePickListVisitValues() {
    final List<String> pckValues = new List<String>();
    final Schema.DescribeFieldResult fieldResult = dwp_kitv__Visit__c.dwp_kitv__country_name__c.getDescribe();
    final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for( Schema.PicklistEntry pickListVal : ple) {
      pckValues.add(pickListVal.getValue());
    }
    return pckValues;
  }

  /*
  * @author Global Desktop
  * @Description Finish
  */
  public void finish(Database.BatchableContext bch) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bch.getJobId()];
    System.debug('>>>>> SUMMARY: ');
    System.debug('>>>>>   Batches Created: ' + job.JobItemsProcessed);
    System.debug('>>>>>   Number of Errors: ' + job.NumberOfErrors);
    System.debug('>>>>>   Status: ' + job.Status);
  }

}