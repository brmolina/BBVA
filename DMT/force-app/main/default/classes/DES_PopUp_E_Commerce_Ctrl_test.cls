/*
* test 1
*/
@isTest
public with sharing class DES_PopUp_E_Commerce_Ctrl_test {
  /*
  * test 1
  */
  @isTest
  public static void getPrimarySalesTest() {
      Asset_Template__c template;
      template = SetUpOnBoarding.createAssetTemplate();
      insert template;
      Asset_Product__c tempProd;
      tempProd = SetUpOnBoarding.createAssetProduct(template.id);
      tempProd.Product__c = 'Mbono';
      insert tempProd;
      final String resultado = DES_PopUp_E_Commerce_Ctrl.checkError(template.id, 'E_Commerce_prod_alert::E_Commerce_murex_alert::E_Commerce_ddff_alert::E_Commerce_designation');
      System.assert(resultado != 'none', 'Error');
  }
}