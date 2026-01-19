/**
  * @File Name          : Arc_Gen_Notifications_Test.cls
  * @Description        : Test class for Notifications class
  * @Author             : juanmanuel.perez.ortiz.contractor@bbva.com
  * @Group              : ARCE
  * @Last Modified By   : juanmanuel.perez.ortiz.contractor@bbva.com
  * @Last Modified On   : 6/1/2020 18:21:09
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                 Modification
  *==============================================================================
  * 1.0    6/1/2020 18:21:09  juanmanuel.perez.ortiz.contractor@bbva.com   Initial Version
  * 1.1    8/1/2020 18:21:09  javier.soto.carrascosa@bbva.com              Adapt test classess with account wrapper and setupaccounts
  * 1.2    23/09/2020     saimassimilianno.jordana.contractor@bbva.com     Added arce. namespace to all
  *                                                classes that are now in the arce-dependencies package
  **/
@isTest
public class Arc_Gen_Notifications_Test {
  @testSetup
  static void insertData() {
      Arc_UtilitysDataTest_tst.setupAcccounts();
      final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
      final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

      arce__Analysis__c newAnalysis = new arce__Analysis__c();
      newAnalysis.Name = 'Analysis';
      insert newAnalysis;

      arce__Account_has_Analysis__c children = new arce__Account_has_Analysis__c();
      children.arce__Analysis__c = newAnalysis.Id;
      children.arce__InReview__c = true;
      children.arce__Customer__c = groupAccount.accId;
      insert children;
  }
  @isTest
  public static void getUsersIdsTest() {
    final arce__Analysis__c arceVar = [Select Id from arce__Analysis__c limit 1];
    Test.startTest();
    final List<User> lstUsers = Arc_Gen_Notifications_Service.getUsersIds(arceVar.Id);
    system.assertEquals(1,lstUsers.size(),'The result was as expected');
    Test.stopTest();
  }
}