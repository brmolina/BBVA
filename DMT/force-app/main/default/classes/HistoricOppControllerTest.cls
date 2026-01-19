/**
* @author Global Desktop
*/
@isTest
public class HistoricOppControllerTest {
  @isTest
  /*
  * Test method
  */
	public static void test01() {
    final HistoricOppController instance = HistoricOppController.getInstance();
    system.debug(instance);
    final String dataOpp = HistoricOppController.getDataOpp('1','1');
    system.debug(dataOpp);
    final String dataProduct = HistoricOppController.getProduct('1','1');
    system.debug(dataProduct);
    System.assertNotEquals(null, true);
  }
}