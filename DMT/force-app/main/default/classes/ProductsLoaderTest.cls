/*****************************************
Name:           ProductsLoaderTest
Description:    Clase de testeo de la clase ProductsLoader

********************************************/
@isTest
private class ProductsLoaderTest {

  /*
   *  @author Global Desktop
   *  @Description  Test de la clase ProductsLoader
   *
   *
  **/
  @isTest
  static void testTrigger() {

    final DES_UtilTestClass testClass = new DES_UtilTestClass();
    final String idProfile = testClass.createProfile();
    final User userTest = testClass.createUser(idProfile);
    insert userTest;
    final Account acc = testClass.createClient();
    insert acc;
    system.runAs(userTest) {
      Test.startTest();
      final Opportunity oppInsert = testClass.createOpportunity(acc);
      insert oppInsert;
      final Opportunity oppRetr = ProductsLoader.gtData(oppInsert.Id);
      final String strRtn = ProductsLoader.uncheckStageChanged(oppInsert.Id);
      system.debug('::::: strRtn : ' + strRtn);
      system.assertNotEquals(oppRetr.Id, null);
      Test.StopTest();
    }
  }
}