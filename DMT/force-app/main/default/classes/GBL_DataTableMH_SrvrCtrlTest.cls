@isTest
public class GBL_DataTableMH_SrvrCtrlTest {
  @isTest static void getColumns () {
    String results = GBL_DataTableMH_SrvrCtrl.getColumns(true);
    system.assertEquals(String.isEmpty(results), false);
  }

  @isTest static void fetchStandardData () {
    Test.startTest();
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();
    String[] types = new List<String>();
    types.add('01 - Grupo');
    types.add('02 - Subgrupo');
    types.add('03 - Filial');

    String results = GBL_DataTableMH_SrvrCtrl.fetchData(true, Accts[0].Id, 'Negocio', types, null, null, false, 'START');
    test.stopTest();

    system.assertEquals(results.countMatches('Name'), 4);
  }

  @isTest static void fetchCustomData () {
    Test.startTest();
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();
    String[] types = new List<String>();
    types.add('01 - Grupo');
    types.add('02 - Subgrupo');
    types.add('03 - Filial');

    String results = GBL_DataTableMH_SrvrCtrl.fetchData(false, Accts[0].Id, 'Negocio', types, null, null, false, 'START');
    test.stopTest();

    system.assertEquals(results.countMatches('ChildName__c'), 1);
  }
}