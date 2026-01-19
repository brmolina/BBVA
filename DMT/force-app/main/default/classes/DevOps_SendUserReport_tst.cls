/**
* @author       Victor Velandia
* Project:      BBVA
* Description:  Clase test DevOps_SendUserReport_cls
*
*            No.     Date            Author                  Description
*            -----   ----------      --------------------    ---------------------------------
* @version   1.0     2020-04-16      Victor Velandia (VV)    Clase test DevOps_SendUserReport_cls
***********************************************************************************************/
@isTest
public class DevOps_SendUserReport_tst {

  /**
  * description: strCronExp
  * @author Victor Velandia
  */
  public static String strCronExp = '0 0 0 15 3 ? 2032';

  /**
  * description: getTestOne
  * @author Victor Velandia
  */
  @isTest
  public static void getTestOne() {

  Test.StartTest();
    //Execute the batch
    DevOps_SendUserReport_sch sch = new DevOps_SendUserReport_sch();
    String strJobId = System.schedule( 'Ops_SendUserReport_sch_test', strCronExp, sch );
    System.assert(true, true);
  Test.stopTest();

  }
}