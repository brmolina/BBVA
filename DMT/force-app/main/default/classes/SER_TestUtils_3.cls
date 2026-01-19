/*
*    Company:       BBVA
*    Description:  Clase auxiliar para las clases de Test.
*/
public with sharing class SER_TestUtils_3 {

  /*
  * @Description: Constructor privado.
  */
  private SER_TestUtils_3() {
  }

  /*
  * @Description: initCustomsetting.
  * @return Void
  */
  public static Void initCustomsetting() {
    CIB_Bypass__c bypass;
    bypass = new CIB_Bypass__c();
    bypass.CIB_skip_trigger__c = false;
    insert bypass;

    CIB_User_Org__c userOrg;
    userOrg = new CIB_User_Org__c();
    userOrg.CIB_Is_Service__c = true;
    insert userOrg;
  }

}