/**
  * Name:      InsertShareTerritoryBatchTest
  * Description:   Class to test class InsertShareTerritoryBatch
  *
***/
@isTest
public class InsertShareTerritoryBatchTest {

  @isTest
  static void methodTest() {

    //start test
    Test.startTest();
    final DES_UtilTestClass testClass = new DES_UtilTestClass();
    final List<SObject> listaAcc = new List<SObject>();
    final Account padre = testClass.createClient();
    padre.DES_Country_Client__c = 'ES';
    padre.DES_Segment__c = '00005'; // Corporate
    listaAcc.add(padre);
    final Account hijo = testClass.createClient();
    hijo.DES_Country_Client__c = 'ES';
    hijo.DES_Segment__c = '00005'; // Corporate
    listaAcc.add(hijo);
    insert listaAcc;
    Map<Id, Territory2> mapTerrit = new Map<Id, Territory2>([SELECT Id FROM Territory2 WHERE segment_name__c = 'Corporate' AND country_name__c	 = 'ES' LIMIT 1]);
    List<AccountShare> listAccShareToInsert = new List<AccountShare>();
    final Group groupAux = new Group(
      DeveloperName = 'groupName',
      Name = 'groupName'
      );
    insert groupAux;
    AccountShare accShare1 = new AccountShare();
    accShare1.UserOrGroupId = groupAux.Id;
    accShare1.AccountId = listaAcc.get(0).Id;
    accShare1.AccountAccessLevel = 'Edit';
    accShare1.OpportunityAccessLevel = 'Edit';
    accShare1.RowCause = Schema.AccountShare.RowCause.Manual;
    listAccShareToInsert.add(accShare1);
    system.debug('::::: listAccShareToInsert: ' + listAccShareToInsert);
    final Id batchInstanceId = Database.executeBatch(new InsertShareTerritoryBatch(listAccShareToInsert), 10);
    System.assertNotEquals(batchInstanceId, null, 'FAILED');
    Test.stopTest();

  }


}