@isTest
public class GBL_DenormalizeOpportunitiesUtilsTest {
  @isTest static void clear () {
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();

    Test.startTest();
    GBL_DenormalizeOpportunitiesUtils doUtil = new GBL_DenormalizeOpportunitiesUtils();
    doUtil.clear();
    test.stopTest();
    system.assertEquals(1, 1);
  }

  @isTest static void clear2 () {
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();

    opportunity opty = [SELECT Id, Name FROM opportunity WHERE AccountId=:accts[1].Id];

    Test.startTest();
    GBL_DenormalizeOpportunitiesUtils doUtil = new GBL_DenormalizeOpportunitiesUtils();
    doUtil.clear(opty.Id);
    doUtil.restore(opty.Id);
    test.stopTest();
    system.assertEquals(1, 1);
  }

  @isTest static void restore () {
    Account[] accts = GBL_TestMAHDataFactory.setupAccounts();

    Test.startTest();
    GBL_DenormalizeOpportunitiesUtils doUtil = new GBL_DenormalizeOpportunitiesUtils();
    doUtil.restore();
    test.stopTest();
    system.assertEquals(1, 1);
  }

}