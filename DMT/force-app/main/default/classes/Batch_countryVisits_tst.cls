/**********************************************************************************
* @author
* @date
* @description  Test del batch Batch Batch_countryVisits
* @Revision
**********************************************************************************/
@isTest
public with sharing class Batch_countryVisits_tst {
  /**
   * @author Global Desktop
   * @description Test de la clase RecalculateAccountFieldsBatch
   */
  @isTest
  public static void batchRecalculateAccountFields() {
    final DES_UtilTestClass testClass = new DES_UtilTestClass();
    final Account acc = testClass.createClient();
    insert acc;

    final dwp_kitv__Visit__c visit = testClass.createVisit(acc, null);
    insert visit;
    visit.dwp_kitv__country_name__c = '';
    update visit;

    final Id batchInstanceId2 = Database.executeBatch(new Batch_countryVisits(), 100);
    System.assertNotEquals(batchInstanceId2, null, 'notEquals');
  }
}