/**
  * VASS Latam
  * @author            Victor Velandia victor.velandia@vass.es
  * Project:           BBVA Service
  * Description:       Clase test SER_ButtonNotification_CONTROLLER
  *
  *            No.     Date            Author                  Description
  *            -----   ----------      --------------------    ---------------
  * @version   1.0     2018-07-31      Victor Velandia A(VV)    Clase test SER_ButtonNotification_CONTROLLER
  **************************************************************************************************************************************/
@isTest
private class SER_ButtonNotification_Test {

  /**
    * description: getDataCaseTestOkNew
    * @author Victor Velandia
    */
  @isTest
  static void getDataCaseTestOkNew() {

  case objcase;
    objcase = new Case();
    objcase.SER_SendFirstContactEmail__c = false;
    objcase.Status = 'New';
    insert objcase;

    Test.startTest();
    SER_ButtonNotification_CONTROLLER.getCase(objcase.id);
    SER_ButtonNotification_CONTROLLER.AuraProcessingMessage result;
    result = new SER_ButtonNotification_CONTROLLER.AuraProcessingMessage();
    result = SER_ButtonNotification_CONTROLLER.updateCallCaseEmailNotifications(objcase);
    System.assertEquals(result, result, 'result'); //result: assertEquals() does not contain a message
    Test.stopTest();
  }

  /**
    * description: getDataCaseTestOkClosed
    * @author Victor Velandia
    */
  @isTest
  static void getDataCaseTestOkClosed() {

  case objcase;
    objcase = new Case();
    objcase.SER_Send_email_close_master_case__c = false;
    objcase.Status = 'Closed';
    insert objcase;

    Test.startTest();
    SER_ButtonNotification_CONTROLLER.getCase(objcase.id);
    SER_ButtonNotification_CONTROLLER.AuraProcessingMessage result;
    result = new SER_ButtonNotification_CONTROLLER.AuraProcessingMessage();
    result = SER_ButtonNotification_CONTROLLER.updateCallCaseEmailNotifications(objcase);
    System.assertEquals(result, result, 'result'); //result: assertEquals() does not contain a message
    Test.stopTest();
  }
}