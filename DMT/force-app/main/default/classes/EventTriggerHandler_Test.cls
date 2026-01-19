/***********************************************************************************************
Name:            EventTriggerHandler_Test
Description:     Test Class for EventTriggerHandler

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            24/04/2020      Global Desktop    Class creation

***********************************************************************************************/
@isTest
public class EventTriggerHandler_Test {
  /* Test principal*/
  @isTest
  public static void test1() {
    Final EventTriggerHandler even = EventTriggerHandler.getInstance();
    Test.startTest();
    system.assertNotEquals(even,null,'Error');
    Test.stopTest();
  }
}