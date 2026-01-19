/**********************************************************************************
* @author       Global Desktop
* @date         22/12/2020
* @description  Test class for LocalClientSelectCont
**********************************************************************************/
@isTest
public with sharing class LocalClientProxy_vf_ctrl_tst {
  /**
  * Test one
  */
  @isTest
  static void testMethodOne() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = 'test1';
    acc.Name = 'test1';
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.unique_id__c = '099999909';
    lclient1.country_id__c = 'ES';
    lclient1.entity_id__c = '0182';
    insert lclient1;

    final Local_Client__c lclientquery = [SELECT Id, Alpha_Code__c from Local_Client__c LIMIT 1];
    system.debug(lclientquery.Alpha_Code__c);

    final PageReference pageRef = Page.LocalClientProxy;
    Test.setCurrentPage(pageRef);

    ApexPages.currentPage().getParameters().put('customerId', lclientquery.Alpha_Code__c);

    final LocalClientProxy_vf_ctrl controller = new LocalClientProxy_vf_ctrl();
    final String cust = controller.getCustomerId();
    controller.setCustomerId(cust);
    final String clientId = controller.getClientId();
    controller.setCustomerId('ES0182099999909');
    final String clientId1 = controller.getClientId();
    system.debug(clientId);
    system.debug(clientId1);
    controller.setCustomerId('');
    final String clientId2 = controller.getClientId();
    system.debug(clientId2);
    system.assertEquals(clientId, lclientquery.Id, 'not-alpha');
  }
}