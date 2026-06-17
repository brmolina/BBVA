@isTest
public class GBL_AccountMultiHierarchy_SrvrCtrlTest {
  @isTest static void mdtOptions () {
    String results = GBL_AccountMultiHierarchy_SrvrCtrl.getOptions();
    system.assertEquals(String.isEmpty(results), false);
  }

  @isTest static void mdtVisions () {
    String results = GBL_AccountMultiHierarchy_SrvrCtrl.getVisions();
    system.assertEquals(String.isEmpty(results), false);
  }

  @isTest static void fetchStandardChilds () {
    Test.startTest();
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();
    list<String> types = new list<String>{'01 - Grupo','02 - Subgrupo','03 - Filial'};

    String results = GBL_AccountMultiHierarchy_SrvrCtrl.fetchChildData(true, false, Accts[0].Id, 'Negocio', types, '', null, null);
    test.stopTest();

    Boolean result = results.indexOf('Child Account') > 0;
    system.assertEquals(result, true);
  }

  @isTest static void fetchStandardChildsWithRoot () {
    Test.startTest();
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();
    list<String> types = new list<String>{'01 - Grupo','02 - Subgrupo','03 - Filial'};

    String results = GBL_AccountMultiHierarchy_SrvrCtrl.fetchChildData(true, true, Accts[0].Id, 'Negocio', types, '', null, null);
    test.stopTest();

    Boolean result = results.indexOf('Child Account') > 0;
    system.assertEquals(result, true);
  }

  @isTest static void fetchCustomChilds () {
    Test.startTest();
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();
    list<String> types = new list<String>{'01 - Grupo','02 - Subgrupo','03 - Filial'};

    String results = GBL_AccountMultiHierarchy_SrvrCtrl.fetchChildData(false, false, Accts[0].Id, 'Negocio', types, '', null, null);
    test.stopTest();

    Boolean result = results.indexOf('Child Account') > 0;
    system.assertEquals(result, true);
  }

  @isTest static void fetchCustomChildsWithRoot () {
    Test.startTest();
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();
    list<String> types = new list<String>{'01 - Grupo','02 - Subgrupo','03 - Filial'};

    String results = GBL_AccountMultiHierarchy_SrvrCtrl.fetchChildData(false, true, Accts[0].Id, 'Negocio', types, '', null, null);
    test.stopTest();

    Boolean result = results.indexOf('Child Account') > 0;
    system.assertEquals(result, true);
  }

  @isTest static void fetchStandardParents () {
    Test.startTest();
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();

    String results = GBL_AccountMultiHierarchy_SrvrCtrl.fetchParentData(true, Accts[1].Id, 'Negocio', null);
    test.stopTest();

    Boolean result = results.indexOf('Parent Account') > 0;
    system.assertEquals(result, true);
  }

  @isTest static void fetchCustomParents () {
    Test.startTest();
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();

    String results = GBL_AccountMultiHierarchy_SrvrCtrl.fetchParentData(false, Accts[1].Id, 'Negocio', null);
    test.stopTest();

    Boolean result = results.indexOf('Parent Account') > 0;
    system.assertEquals(result, true);
  }
}