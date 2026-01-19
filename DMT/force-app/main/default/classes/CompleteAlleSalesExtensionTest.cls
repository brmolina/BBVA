/**********************************************************************************
* @author       Global Desktop
* @date         25/01/2021
* @description  Test class for CompleteAlleSalesExtension
**********************************************************************************/
@isTest
public class CompleteAlleSalesExtensionTest {
  /**
  * @author Global Desktop
  * @description Method for test
  */
  public static testMethod void testExtension() {
    Asset_Template__c temp;
    temp = SetUpOnBoarding.createAssetTemplate();
    List<Asset_Template__c> temps;
    temps = new List<Asset_Template__c>();
    temps.add(temp);
    final ApexPages.StandardSetController controller = new ApexPages.StandardSetController(temps);
    controller.setSelected(temps);
    final CompleteAlleSalesExtension extension = new CompleteAlleSalesExtension(controller);
    system.assertNotEquals(extension, null, 'extensionNull');
  }
}