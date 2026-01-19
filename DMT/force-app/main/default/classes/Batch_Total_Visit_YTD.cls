/**********************************************************************************
* @author
* @date
* @description  Batch para el cálculo de total de visitas este año desde Account
* @Revision
**********************************************************************************/
public without sharing class Batch_Total_Visit_YTD implements Database.Batchable<Sobject>, Database.Stateful {
  // Check on Production
  // SELECT DES_Client__c , COUNT(id) FROM DES_Denorm_AccountVisits__c WHERE DES_Start_Date__c = THIS_YEAR GROUP BY DES_Client__c ORDER BY COUNT(id) DESC
  /*
  * Query attribute
  */
  private final String query = 'SELECT id, name, DES_Main_Parent__c, visit_current_year_number__c FROM Account' + (Test.isRunningTest() ? ' LIMIT 1' : '');

  /*
  * Lanza Batch para iniciar en el cliente sus visitas totales del año actual
  */
  public Batch_Total_Visit_YTD() {
    system.debug('>>>>> Query: ' + query);
  }
  /*
  * Lanza Batch para iniciar en el cliente sus visitas totales del año actual
  */
  public Database.QueryLocator start(Database.BatchableContext bc1) {
    system.debug('>>>>> query : ' + query);
    return Database.getQueryLocator(query);
  }
  /*
  * Lanza Batch para iniciar en el cliente sus visitas totales del año actual
  */
  public void execute(Database.BatchableContext bc1, List<Account> listAccount) {
    List<String> listID;
    listID = new List<String>();
    Map<String, Integer> mapDenorm;
    mapDenorm = new Map<String, Integer>();

    for(Account acc : listAccount) {
      listID.add(acc.id);
    }

    final List<DES_Denorm_AccountVisits__c> lAccVisit = [SELECT id, DES_Client__c FROM 	DES_Denorm_AccountVisits__c WHERE DES_Start_Date__c = THIS_YEAR AND DES_Start_Date__c <= TODAY AND DES_Client__c IN :listID];

    for(DES_Denorm_AccountVisits__c vist : lAccVisit) {
        mapDenorm.put(vist.DES_Client__c, (mapDenorm.containsKey(vist.DES_Client__c)?mapDenorm.get(vist.DES_Client__c)+1 : 1) );
    }

    for(Account acc : listAccount) {
      acc.visit_current_year_number__c = mapDenorm.containsKey(acc.id)==null ? 0 : mapDenorm.get(acc.id);
    }

    Database.update(listAccount,false);
  }
  /*
  * Lanza Batch para iniciar en el cliente sus visitas totales del año actual
  */
  public void finish(Database.BatchableContext bc1) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc1.getJobId()];
    system.debug('++ job ' + job);
  }
}